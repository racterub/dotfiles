#!/bin/bash
# Session wrapper: launches Claude Code, monitors, rotates on thresholds
# Handles: idle timeout, memory ceiling, max uptime, exponential backoff
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "${SCRIPT_DIR}/config.env"

CLAUDE_BIN="${HOME}/.local/bin/claude"
SEND_TELEGRAM="${SCRIPT_DIR}/lib/send-telegram.sh"
CHECK_INTERVAL=60  # seconds between health checks

# --- Backoff state ---
load_restart_count() {
    if [ -f "$RESTART_COUNT_FILE" ]; then
        cat "$RESTART_COUNT_FILE"
    else
        echo 0
    fi
}

save_restart_count() {
    echo "$1" > "$RESTART_COUNT_FILE"
}

reset_restart_count() {
    echo 0 > "$RESTART_COUNT_FILE"
}

get_backoff_sec() {
    local count=$1
    case $count in
        0|1) echo 30 ;;
        2) echo 60 ;;
        3) echo 120 ;;
        4|5) echo 300 ;;
        *) echo -1 ;;  # -1 means stop retrying
    esac
}

# --- Activity tracking ---
touch_activity() {
    touch "${ACTIVITY_MARKER}"
}

get_idle_sec() {
    local last_activity
    last_activity=$(stat -c %Y "${ACTIVITY_MARKER}" 2>/dev/null || echo 0)
    local now
    now=$(date +%s)
    echo $(( now - last_activity ))
}

# --- Memory check ---
get_memory_mb() {
    local mem_bytes
    mem_bytes=$(systemctl show claude-channels --property=MemoryCurrent --value 2>/dev/null || echo 0)
    echo $(( mem_bytes / 1048576 ))
}

# --- Main loop ---
main() {
    local restart_count
    restart_count=$(load_restart_count)

    while true; do
        local session_start
        session_start=$(date +%s)

        echo "[$(date)] Starting Claude Code session (restart count: $restart_count)"
        touch_activity

        # Launch Claude Code with Telegram channel
        $CLAUDE_BIN \
            --channels plugin:telegram@claude-plugins-official \
            &

        local claude_pid=$!
        echo "[$(date)] Claude PID: $claude_pid"

        # Monitor loop
        local should_rotate=false
        while kill -0 "$claude_pid" 2>/dev/null; do
            sleep "$CHECK_INTERVAL"

            # Check idle timeout
            local idle_sec
            idle_sec=$(get_idle_sec)
            if [ "$idle_sec" -gt "$((IDLE_TIMEOUT_MIN * 60))" ]; then
                echo "[$(date)] Idle timeout reached (${idle_sec}s idle)"
                should_rotate=true
                break
            fi

            # Check memory
            local mem_mb
            mem_mb=$(get_memory_mb)
            if [ "$mem_mb" -gt "$MEMORY_CEILING_MB" ]; then
                echo "[$(date)] Memory ceiling reached (${mem_mb}MB)"
                should_rotate=true
                break
            fi

            # Check max uptime
            local uptime_sec
            uptime_sec=$(( $(date +%s) - session_start ))
            local uptime_hours=$(( uptime_sec / 3600 ))
            if [ "$uptime_hours" -ge "$MAX_UPTIME_HOURS" ]; then
                # Defer if active (recent activity within idle timeout)
                if [ "$idle_sec" -lt "$((IDLE_TIMEOUT_MIN * 60))" ]; then
                    echo "[$(date)] Max uptime reached but session active, deferring rotation"
                    continue
                fi
                echo "[$(date)] Max uptime reached (${uptime_hours}h)"
                should_rotate=true
                break
            fi
        done

        if $should_rotate; then
            # Graceful rotation
            echo "[$(date)] Rotating session..."
            kill -TERM "$claude_pid" 2>/dev/null || true
            local waited=0
            while kill -0 "$claude_pid" 2>/dev/null && [ $waited -lt 30 ]; do
                sleep 1
                waited=$((waited + 1))
            done
            kill -KILL "$claude_pid" 2>/dev/null || true
            wait "$claude_pid" 2>/dev/null || true

            sleep "$ROTATE_COOLDOWN_SEC"
            reset_restart_count
            restart_count=0
            continue
        fi

        # Claude exited on its own — possible crash
        wait "$claude_pid" 2>/dev/null
        local exit_code=$?
        echo "[$(date)] Claude exited with code $exit_code"

        # Check if session was long enough to reset backoff
        local session_duration=$(( $(date +%s) - session_start ))
        if [ "$session_duration" -gt 300 ]; then
            # Session lasted >5 min — reset backoff
            reset_restart_count
            restart_count=0
        else
            restart_count=$((restart_count + 1))
            save_restart_count "$restart_count"
        fi

        # Calculate backoff
        local backoff
        backoff=$(get_backoff_sec "$restart_count")

        if [ "$backoff" -eq -1 ]; then
            echo "[$(date)] Too many restarts ($restart_count). Stopping."
            $SEND_TELEGRAM "Claude Assistant stopped after $restart_count consecutive failures. Manual intervention needed." || true
            exit 1
        fi

        if [ "$restart_count" -ge 4 ]; then
            $SEND_TELEGRAM "Claude Assistant restarting (attempt $restart_count). Backing off ${backoff}s." || true
        fi

        echo "[$(date)] Backing off ${backoff}s before restart"
        sleep "$backoff"
    done
}

main "$@"
