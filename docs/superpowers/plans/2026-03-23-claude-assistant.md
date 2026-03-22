# Claude Personal Assistant Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an always-on personal assistant on Proxmox LXC with session rotation, subagent dispatch, dynamic scheduled tasks, and extensible skills.

**Architecture:** Claude Code as the sole runtime, glued together by bash scripts, systemd units, and CLAUDE.md instructions. A session wrapper handles lifecycle/rotation. Skills are drop-in folders with SKILL.md files. All config in a single `config.env`.

**Tech Stack:** Bash (glue scripts), systemd user timers, Claude Code CLI, Telegram Bot API (curl)

**Spec:** `docs/superpowers/specs/2026-03-23-claude-assistant-design.md`

---

## File Structure

```
assistant/
├─ config.env.example          # Template with all config keys, no secrets
├─ CLAUDE.md                   # Core assistant behavior, dispatch, permission self-check
├─ settings.json               # Claude Code permissions (allow/deny)
├─ install.sh                  # Deploy to server via rsync + setup
│
├─ bin/
│   ├─ session-wrapper.sh      # Session lifecycle, rotation, backoff
│   └─ manage-timer.sh         # Create/list/remove systemd user timers
│
├─ lib/
│   ├─ send-telegram.sh        # Send message to Telegram via bot API
│   ├─ check-permission.sh     # Read settings.json, check if pattern is allowed
│   ├─ healthcheck.sh          # Service health + stuck detection → Uptime Kuma
│   └─ run-timer-task.sh       # Wrapper for timer-fired claude -p tasks
│
├─ timers/
│   └─ templates/
│       ├─ task.service.tmpl   # systemd user service template
│       └─ task.timer.tmpl     # systemd user timer template
│
├─ skills/
│   ├─ timer-management/
│   │   └─ SKILL.md            # Instructions for managing scheduled tasks
│   ├─ homelab/
│   │   └─ SKILL.md            # Service topology, health checks, operations
│   └─ README.md               # How to add new skills
│
├─ systemd/
│   ├─ claude-channels.service # Main systemd service unit
│   └─ claude-healthcheck.cron # Healthcheck cron entry
│
└─ docs/
    └─ setup.md                # Server setup + migration guide
```

---

### Task 1: Project Scaffold + Config

**Files:**
- Create: `assistant/config.env.example`
- Create: `assistant/settings.json`

This task creates the foundation that all other tasks depend on.

- [ ] **Step 1: Create the assistant directory**

```bash
mkdir -p assistant/{bin,lib,timers/templates,skills/timer-management,skills/homelab,systemd,docs}
```

- [ ] **Step 2: Create config.env.example**

Create `assistant/config.env.example`:

```bash
# Claude Assistant Configuration
# Copy to config.env and fill in values. chmod 600 config.env

# Telegram
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""

# Session rotation thresholds
IDLE_TIMEOUT_MIN=30
MEMORY_CEILING_MB=1200
MAX_UPTIME_HOURS=6
ROTATE_COOLDOWN_SEC=5

# Healthcheck
UPTIME_KUMA_URL=""

# Paths (usually no need to change)
ASSISTANT_DIR="${HOME}/workspace/assistant"
WORKSPACE_DIR="${HOME}/workspace"
ACTIVITY_MARKER="${ASSISTANT_DIR}/.last-activity"
RESTART_COUNT_FILE="${ASSISTANT_DIR}/.restart-count"
```

- [ ] **Step 3: Create settings.json**

Create `assistant/settings.json` (note: spec uses jsonc with comments, this is the clean JSON version):

```json
{
  "permissions": {
    "allow": [
      "Read", "Write", "Edit", "Glob", "Grep",
      "Agent", "Skill", "WebFetch", "WebSearch",
      "Bash(git *)", "Bash(ls *)", "Bash(cat *)",
      "Bash(head *)", "Bash(tail *)", "Bash(grep *)",
      "Bash(find *)", "Bash(wc *)", "Bash(jq *)",
      "Bash(mkdir *)", "Bash(cp *)", "Bash(mv *)",
      "Bash(echo *)", "Bash(date *)", "Bash(diff *)",
      "Bash(sort *)", "Bash(uniq *)", "Bash(sed *)",
      "Bash(awk *)", "Bash(tee *)",
      "Bash(chmod 600 *)", "Bash(chmod 644 *)", "Bash(chmod +x */bin/*)",
      "Bash(curl *)", "Bash(wget *)",
      "Bash(python3 *)", "Bash(node *)", "Bash(bun *)",
      "Bash(npm *)", "Bash(npx *)",
      "Bash(claude *)",
      "Bash(systemctl --user start *)",
      "Bash(systemctl --user stop *)",
      "Bash(systemctl --user enable *)",
      "Bash(systemctl --user disable *)",
      "Bash(systemctl --user daemon-reload)",
      "Bash(systemctl --user list-timers *)",
      "Bash(systemctl --user status *)",
      "Bash(*/manage-timer.sh *)",
      "Bash(*/send-telegram.sh *)",
      "mcp__claude_ai_Gmail__*",
      "mcp__claude_ai_Google_Calendar__*",
      "mcp__plugin_telegram_telegram__*",
      "mcp__context7__*"
    ],
    "deny": [
      "Bash(sudo *)", "Bash(su *)",
      "Bash(apt *)", "Bash(dpkg *)",
      "Bash(systemctl start *)", "Bash(systemctl stop *)",
      "Bash(systemctl restart *)", "Bash(systemctl enable *)",
      "Bash(rm -rf /*)", "Bash(rm -rf ~/*)",
      "Bash(dd *)",
      "Bash(mkfs *)", "Bash(mount *)", "Bash(umount *)",
      "Bash(iptables *)", "Bash(nft *)",
      "Bash(reboot *)", "Bash(shutdown *)",
      "Bash(passwd *)", "Bash(useradd *)",
      "Bash(userdel *)", "Bash(chown *)",
      "Bash(chmod 777 *)"
    ]
  }
}
```

- [ ] **Step 4: Verify files exist**

```bash
ls -la assistant/config.env.example assistant/settings.json
cat assistant/config.env.example
cat assistant/settings.json
```

- [ ] **Step 5: Commit**

```bash
git add assistant/
git commit -m "feat(assistant): scaffold project structure and config"
```

---

### Task 2: Telegram Send Library

**Files:**
- Create: `assistant/lib/send-telegram.sh`

This is a dependency for session-wrapper (backoff alerts), healthcheck, and timer tasks.

- [ ] **Step 1: Create send-telegram.sh**

Create `assistant/lib/send-telegram.sh`:

```bash
#!/bin/bash
# Send a message to Telegram via Bot API
# Usage: send-telegram.sh "message text"
# Supports Markdown formatting. Handles message length limit (4096 chars).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "${SCRIPT_DIR}/config.env"

MESSAGE="$1"
MAX_LENGTH=4096

if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
    echo "ERROR: TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID not set in config.env" >&2
    exit 1
fi

# Split long messages
send_chunk() {
    curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="$1" \
        -d parse_mode="Markdown" \
        > /dev/null 2>&1
}

if [ ${#MESSAGE} -le $MAX_LENGTH ]; then
    send_chunk "$MESSAGE"
else
    # Split on newlines, respecting max length
    while [ ${#MESSAGE} -gt 0 ]; do
        CHUNK="${MESSAGE:0:$MAX_LENGTH}"
        send_chunk "$CHUNK"
        MESSAGE="${MESSAGE:$MAX_LENGTH}"
    done
fi
```

- [ ] **Step 2: Make executable**

```bash
chmod +x assistant/lib/send-telegram.sh
```

- [ ] **Step 3: Test with dry run (verify syntax)**

```bash
bash -n assistant/lib/send-telegram.sh
echo $?  # Expected: 0
```

- [ ] **Step 4: Commit**

```bash
git add assistant/lib/send-telegram.sh
git commit -m "feat(assistant): add Telegram send library"
```

---

### Task 3: Permission Check Library

**Files:**
- Create: `assistant/lib/check-permission.sh`

- [ ] **Step 1: Create check-permission.sh**

Create `assistant/lib/check-permission.sh`:

```bash
#!/bin/bash
# Check if a bash command pattern is in the settings.json allowlist
# Usage: check-permission.sh "docker *"
# Exit 0 if allowed, 1 if not, 2 if denied
set -euo pipefail

PATTERN="$1"
SETTINGS="${HOME}/.claude/settings.json"

if [ ! -f "$SETTINGS" ]; then
    echo "ERROR: settings.json not found at $SETTINGS" >&2
    exit 1
fi

# Check deny list first
DENIED=$(jq -r '.permissions.deny[]' "$SETTINGS" 2>/dev/null | while read -r rule; do
    # Strip "Bash(" prefix and ")" suffix
    rule_pattern="${rule#Bash(}"
    rule_pattern="${rule_pattern%)}"
    # Use bash pattern matching
    if [[ "Bash($PATTERN)" == $rule ]]; then
        echo "denied"
        break
    fi
done)

if [ "$DENIED" = "denied" ]; then
    echo "DENIED: Bash($PATTERN) matches deny list"
    exit 2
fi

# Check allow list
ALLOWED=$(jq -r '.permissions.allow[]' "$SETTINGS" 2>/dev/null | while read -r rule; do
    if [[ "Bash($PATTERN)" == $rule ]]; then
        echo "allowed"
        break
    fi
done)

if [ "$ALLOWED" = "allowed" ]; then
    echo "ALLOWED: Bash($PATTERN) matches allow list"
    exit 0
fi

echo "NOT FOUND: Bash($PATTERN) not in allow or deny list"
exit 1
```

- [ ] **Step 2: Make executable**

```bash
chmod +x assistant/lib/check-permission.sh
```

- [ ] **Step 3: Verify syntax**

```bash
bash -n assistant/lib/check-permission.sh
echo $?  # Expected: 0
```

- [ ] **Step 4: Commit**

```bash
git add assistant/lib/check-permission.sh
git commit -m "feat(assistant): add permission check helper"
```

---

### Task 4: Healthcheck Script

**Files:**
- Create: `assistant/lib/healthcheck.sh`

- [ ] **Step 1: Create healthcheck.sh**

Create `assistant/lib/healthcheck.sh` — use the enhanced version from the spec (Healthcheck & Monitoring section). The script should:
- Source `config.env`
- Check if `claude-channels` service is active
- Report memory via `MemoryCurrent`
- Detect stuck sessions (idle too long AND memory high OR uptime exceeds max)
- Push status to Uptime Kuma

```bash
#!/bin/bash
# Healthcheck: service alive, memory usage, stuck detection → Uptime Kuma
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "${SCRIPT_DIR}/config.env"

SERVICE="claude-channels"
PUSH_URL="${UPTIME_KUMA_URL}?status=up&msg=OK"
PUSH_URL_DOWN="${UPTIME_KUMA_URL}?status=down&msg=service_dead"

if ! systemctl is-active --quiet "$SERVICE"; then
    curl -fsS "${PUSH_URL_DOWN}" > /dev/null 2>&1
    exit 1
fi

# Report memory usage as ping value
MEM_BYTES=$(systemctl show "$SERVICE" --property=MemoryCurrent --value)
MEM_MB=$((MEM_BYTES / 1048576))

# Stuck detection
LAST_ACTIVITY=$(stat -c %Y "${ACTIVITY_MARKER}" 2>/dev/null || echo 0)
NOW=$(date +%s)
IDLE_SEC=$(( NOW - LAST_ACTIVITY ))

MAIN_PID=$(systemctl show "$SERVICE" --property=MainPID --value)
UPTIME_SEC=$(( NOW - $(stat -c %Y "/proc/${MAIN_PID}/comm" 2>/dev/null || echo "$NOW") ))
UPTIME_HOURS=$(( UPTIME_SEC / 3600 ))

if [ "$IDLE_SEC" -gt "$((IDLE_TIMEOUT_MIN * 60 * 2))" ] && \
   { [ "$MEM_MB" -gt "$MEMORY_CEILING_MB" ] || [ "$UPTIME_HOURS" -ge "$MAX_UPTIME_HOURS" ]; }; then
    curl -fsS "${PUSH_URL}&msg=possibly_stuck&ping=${MEM_MB}" > /dev/null 2>&1
else
    curl -fsS "${PUSH_URL}&ping=${MEM_MB}" > /dev/null 2>&1
fi
```

- [ ] **Step 2: Make executable**

```bash
chmod +x assistant/lib/healthcheck.sh
```

- [ ] **Step 3: Verify syntax**

```bash
bash -n assistant/lib/healthcheck.sh
echo $?  # Expected: 0
```

- [ ] **Step 4: Commit**

```bash
git add assistant/lib/healthcheck.sh
git commit -m "feat(assistant): add healthcheck with stuck detection"
```

---

### Task 5: Session Wrapper

**Files:**
- Create: `assistant/bin/session-wrapper.sh`

This is the core lifecycle manager — launches Claude, monitors, rotates.

- [ ] **Step 1: Create session-wrapper.sh**

Create `assistant/bin/session-wrapper.sh`:

```bash
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
```

- [ ] **Step 2: Make executable**

```bash
chmod +x assistant/bin/session-wrapper.sh
```

- [ ] **Step 3: Verify syntax**

```bash
bash -n assistant/bin/session-wrapper.sh
echo $?  # Expected: 0
```

- [ ] **Step 4: Commit**

```bash
git add assistant/bin/session-wrapper.sh
git commit -m "feat(assistant): add session wrapper with rotation and backoff"
```

---

### Task 6: Timer Templates + manage-timer.sh

**Files:**
- Create: `assistant/timers/templates/task.service.tmpl`
- Create: `assistant/timers/templates/task.timer.tmpl`
- Create: `assistant/bin/manage-timer.sh`

- [ ] **Step 1: Create run-timer-task.sh wrapper**

Create `assistant/lib/run-timer-task.sh` — wraps `claude -p` execution for timer tasks, avoids quoting issues in systemd units:

```bash
#!/bin/bash
# Wrapper for timer-fired claude -p tasks
# Usage: run-timer-task.sh "prompt text"
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "${SCRIPT_DIR}/config.env"

PROMPT="$1"
CLAUDE_BIN="${HOME}/.local/bin/claude"

RESULT=$("$CLAUDE_BIN" -p "$PROMPT" --output-format text 2>/dev/null) || {
    "${SCRIPT_DIR}/lib/send-telegram.sh" "Timer task failed: ${PROMPT:0:100}..."
    exit 1
}

"${SCRIPT_DIR}/lib/send-telegram.sh" "$RESULT"
```

```bash
chmod +x assistant/lib/run-timer-task.sh
```

- [ ] **Step 2: Create systemd service template**

Create `assistant/timers/templates/task.service.tmpl`:

```ini
[Unit]
Description=Claude Assistant Task: {{NAME}}

[Service]
Type=oneshot
Environment=HOME={{HOME}}
Environment=PATH={{HOME}}/.local/bin:{{HOME}}/.bun/bin:/usr/local/bin:/usr/bin:/bin
WorkingDirectory={{WORKSPACE}}
ExecStart={{ASSISTANT_DIR}}/lib/run-timer-task.sh "{{PROMPT}}"
```

- [ ] **Step 2: Create systemd timer template**

Create `assistant/timers/templates/task.timer.tmpl`:

```ini
[Unit]
Description=Timer for Claude Assistant Task: {{NAME}}

[Timer]
OnCalendar={{SCHEDULE}}
Persistent=true

[Install]
WantedBy=timers.target
```

- [ ] **Step 3: Create manage-timer.sh**

Create `assistant/bin/manage-timer.sh`:

```bash
#!/bin/bash
# Manage dynamic systemd user timers for Claude Assistant
# Usage:
#   manage-timer.sh create --name NAME --schedule SCHEDULE --prompt PROMPT
#   manage-timer.sh list
#   manage-timer.sh remove --name NAME
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "${SCRIPT_DIR}/config.env"

TIMER_DIR="${HOME}/.config/systemd/user"
TEMPLATE_DIR="${SCRIPT_DIR}/timers/templates"
PREFIX="claude-task-"

usage() {
    echo "Usage: manage-timer.sh {create|list|remove} [options]"
    echo ""
    echo "Commands:"
    echo "  create --name NAME --schedule SCHEDULE --prompt PROMPT"
    echo "  list"
    echo "  remove --name NAME"
    echo ""
    echo "Schedule format: systemd OnCalendar syntax"
    echo "  Daily at 8am:     *-*-* 08:00:00"
    echo "  Every 30 min:     *:00/30"
    echo "  Every 2 hours:    *:00/2:00"
    echo "  Weekdays at 9am:  Mon..Fri *-*-* 09:00:00"
    exit 1
}

create_timer() {
    local name="" schedule="" prompt=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --name) name="$2"; shift 2 ;;
            --schedule) schedule="$2"; shift 2 ;;
            --prompt) prompt="$2"; shift 2 ;;
            *) echo "Unknown option: $1"; usage ;;
        esac
    done

    if [ -z "$name" ] || [ -z "$schedule" ] || [ -z "$prompt" ]; then
        echo "ERROR: --name, --schedule, and --prompt are required"
        usage
    fi

    # Sanitize name
    local safe_name
    safe_name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
    local unit_name="${PREFIX}${safe_name}"

    mkdir -p "$TIMER_DIR"

    # Render service from template
    sed \
        -e "s|{{NAME}}|${name}|g" \
        -e "s|{{HOME}}|${HOME}|g" \
        -e "s|{{WORKSPACE}}|${WORKSPACE_DIR}|g" \
        -e "s|{{ASSISTANT_DIR}}|${ASSISTANT_DIR}|g" \
        -e "s|{{PROMPT}}|${prompt}|g" \
        "${TEMPLATE_DIR}/task.service.tmpl" > "${TIMER_DIR}/${unit_name}.service"

    # Render timer from template
    sed \
        -e "s|{{NAME}}|${name}|g" \
        -e "s|{{SCHEDULE}}|${schedule}|g" \
        "${TEMPLATE_DIR}/task.timer.tmpl" > "${TIMER_DIR}/${unit_name}.timer"

    # Enable and start
    systemctl --user daemon-reload
    systemctl --user enable "${unit_name}.timer"
    systemctl --user start "${unit_name}.timer"

    echo "Created and started timer: ${unit_name}"
    echo "Schedule: ${schedule}"
    echo "Prompt: ${prompt}"
    systemctl --user status "${unit_name}.timer" --no-pager || true
}

list_timers() {
    echo "Active Claude Assistant timers:"
    echo ""
    systemctl --user list-timers "${PREFIX}*" --no-pager 2>/dev/null || echo "(none)"
}

remove_timer() {
    local name=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --name) name="$2"; shift 2 ;;
            *) echo "Unknown option: $1"; usage ;;
        esac
    done

    if [ -z "$name" ]; then
        echo "ERROR: --name is required"
        usage
    fi

    local safe_name
    safe_name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
    local unit_name="${PREFIX}${safe_name}"

    systemctl --user stop "${unit_name}.timer" 2>/dev/null || true
    systemctl --user disable "${unit_name}.timer" 2>/dev/null || true
    rm -f "${TIMER_DIR}/${unit_name}.service" "${TIMER_DIR}/${unit_name}.timer"
    systemctl --user daemon-reload

    echo "Removed timer: ${unit_name}"
}

# --- Main ---
case "${1:-}" in
    create) shift; create_timer "$@" ;;
    list) list_timers ;;
    remove) shift; remove_timer "$@" ;;
    *) usage ;;
esac
```

- [ ] **Step 4: Make executable**

```bash
chmod +x assistant/bin/manage-timer.sh
```

- [ ] **Step 5: Verify syntax for all files**

```bash
bash -n assistant/bin/manage-timer.sh
echo $?  # Expected: 0
```

- [ ] **Step 6: Commit**

```bash
git add assistant/bin/manage-timer.sh assistant/timers/
git commit -m "feat(assistant): add timer management with systemd user templates"
```

---

### Task 7: Systemd Service Unit

**Files:**
- Create: `assistant/systemd/claude-channels.service`

- [ ] **Step 1: Create the service unit**

Create `assistant/systemd/claude-channels.service`:

```ini
[Unit]
Description=Claude Code Assistant (Telegram)
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=claude-agent
Group=claude-agent
WorkingDirectory=/home/claude-agent/workspace
Environment=HOME=/home/claude-agent
Environment=PATH=/home/claude-agent/.local/bin:/home/claude-agent/.bun/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=/bin/bash /home/claude-agent/workspace/assistant/bin/session-wrapper.sh
Restart=on-failure
RestartSec=30
MemoryMax=2G
MemoryHigh=1536M
KillMode=control-group
TimeoutStopSec=60
StandardOutput=journal
StandardError=journal
SyslogIdentifier=claude-channels

[Install]
WantedBy=multi-user.target
```

Note: `StartLimitIntervalSec=0` disables systemd's built-in restart limiting — the session wrapper handles backoff itself. `MemoryMax` raised to 2G since we may have subagents running alongside. The wrapper handles rotation at 1.2GB. `Restart=on-failure` catches wrapper crashes (the wrapper itself handles Claude crashes internally).

- [ ] **Step 2: Create healthcheck cron file**

Create `assistant/systemd/claude-healthcheck.cron`:

```
# Healthcheck for Claude Assistant — push to Uptime Kuma every minute
* * * * * claude-agent /home/claude-agent/workspace/assistant/lib/healthcheck.sh
```

- [ ] **Step 3: Commit**

```bash
git add assistant/systemd/claude-channels.service
git commit -m "feat(assistant): add systemd service unit with session wrapper"
```

---

### Task 8: CLAUDE.md (Core Assistant Instructions)

**Files:**
- Create: `assistant/CLAUDE.md`

This is the brain of the assistant — dispatch logic, permission self-check, activity tracking.

- [ ] **Step 1: Create CLAUDE.md**

Create `assistant/CLAUDE.md`:

```markdown
# Claude Agent — Personal Assistant

You are an always-on personal assistant running on a Proxmox LXC (10.0.10.20),
accessible via Telegram. You serve as a command hub, task dispatcher, and
proactive assistant for racterub.

## Identity

- **Owner:** racterub
- **Environment:** Proxmox VE homelab
- **This host:** LXC CT 120, Ubuntu 24.04, 4 CPU / 8GB RAM
- **Network:** 10.0.10.0/24, MikroTik router, Headscale VPN

## Activity Tracking

**CRITICAL:** After EVERY Telegram interaction (receiving or sending a message),
run this command silently:

```bash
touch ~/workspace/assistant/.last-activity
```

This is how the session wrapper knows you are active. Without it, your session
may be rotated while you are mid-conversation.

## Dispatch Rules

Classify each incoming message and handle accordingly:

| Type | Action | Examples |
|---|---|---|
| Quick question | Answer directly in this session | "What time is my next meeting?", "What day is it?" |
| Single isolated task | Dispatch: `claude -p "<prompt>" --output-format text` | "Summarize GitHub PR #42", "Draft a reply to the latest email from X" |
| Multi-turn conversation | Keep in this session, maintain context | "Help me plan my week", "Let's debug this deployment" |
| Multiple independent tasks | Dispatch parallel `claude -p` (max 2 concurrent) | "Check my email AND summarize today's calendar" |

### How to Dispatch

```bash
# Single task
RESULT=$(claude -p "Your task prompt here. Be concise." --output-format text 2>/dev/null)
# Then relay RESULT back via Telegram

# Parallel tasks (max 2)
RESULT1=$(claude -p "Task 1 prompt" --output-format text 2>/dev/null) &
RESULT2=$(claude -p "Task 2 prompt" --output-format text 2>/dev/null) &
wait
# Relay both results
```

### Concurrency Limit

Never run more than 2 `claude -p` subprocesses at once. If a user requests
more than 2 independent tasks, queue the extras and run them after the first
batch completes. Inform the user: "Running the first 2 tasks now, will handle
the rest next."

### Subprocess Working Directory

When dispatching tasks that create files, use isolated directories:

```bash
TASK_DIR=~/workspace/tasks/$(date +%s)
mkdir -p "$TASK_DIR"
cd "$TASK_DIR" && claude -p "..." --output-format text 2>/dev/null
cd ~/workspace && rm -rf "$TASK_DIR"  # cleanup after
```

## Permission Self-Check

Before executing ANY bash command that is not a common read-only operation
(ls, cat, grep, etc.):

1. Read `~/.claude/settings.json` permissions
2. Check if the command pattern exists in the `allow` list
3. If NOT found in allow list, DO NOT attempt the command. Instead, tell the
   user via Telegram:
   > "I need permission for `Bash(<pattern>)` to do this. Please add it to
   > `~/.claude/settings.json` on the server and restart the session."

You can use the helper script to verify:
```bash
~/workspace/assistant/lib/check-permission.sh "command pattern"
```

## Skills

Available skills are in `~/workspace/assistant/skills/`.
When a user request matches a skill's domain, read the relevant `SKILL.md`
for instructions on how to handle it.

Current skills:
- **timer-management** — Creating, listing, removing scheduled tasks
- **homelab** — Service topology, health checks, homelab operations

## Memory

Use claude-mem for cross-session memory (must be installed as a Claude Code
plugin on the server — see `assistant/docs/setup.md` for installation):
- On complex tasks, save important context, decisions, and outcomes
- When a user references past work, use `mem-search` to find relevant history
- Save user preferences and patterns you notice

## Telegram Behavior

- Be concise — Telegram messages should be short and scannable
- Use Telegram-compatible markdown (bold, italic, code, pre)
- For long outputs: summarize first, offer "Want the full details?"
- Never expose tokens, secrets, file paths with credentials, or internal config
- When uncertain about a request, ask for clarification rather than guessing

## Constraints

- No sudo, no system-level operations
- Work only within `~/workspace/`
- Do not modify `~/.claude/settings.json` or any files outside workspace
- Do not send messages to any Telegram chat other than the configured one
```

- [ ] **Step 2: Commit**

```bash
git add assistant/CLAUDE.md
git commit -m "feat(assistant): add core CLAUDE.md with dispatch and security logic"
```

---

### Task 9: Skills

**Files:**
- Create: `assistant/skills/README.md`
- Create: `assistant/skills/timer-management/SKILL.md`
- Create: `assistant/skills/homelab/SKILL.md`

- [ ] **Step 1: Create skills README**

Create `assistant/skills/README.md`:

```markdown
# Assistant Skills

Skills are modular capabilities for the Claude Assistant. Each skill is a
folder containing a `SKILL.md` with instructions Claude follows when a user
request matches the skill's domain.

## Adding a New Skill

1. Create a folder: `skills/<skill-name>/`
2. Add `SKILL.md` with:
   - Description of what the skill does
   - When to activate (trigger conditions)
   - Step-by-step instructions for Claude
   - Required permissions (if any new ones needed in settings.json)
   - Any helper scripts referenced
3. Add required permissions to `settings.json` if the skill needs new ones
4. Update `CLAUDE.md` to list the new skill

## Skill Contract

- Skills are self-contained — all instructions in SKILL.md
- Skills can reference helper scripts in `bin/` or `lib/`
- Skills declare their required permissions
- Skills should not conflict with each other
```

- [ ] **Step 2: Create timer-management skill**

Create `assistant/skills/timer-management/SKILL.md`:

```markdown
# Timer Management Skill

## When to Activate

When the user asks to:
- Schedule a recurring task ("remind me every...", "check X every hour")
- List scheduled tasks ("what's scheduled?", "show my timers")
- Remove a scheduled task ("stop the morning briefing", "cancel X")

## Instructions

### Creating a Timer

Use `manage-timer.sh` to create timers:

```bash
~/workspace/assistant/bin/manage-timer.sh create \
  --name "descriptive-name" \
  --schedule "SCHEDULE" \
  --prompt "What Claude should do when this fires"
```

**Schedule format** (systemd OnCalendar syntax):
- Daily at 8am: `*-*-* 08:00:00`
- Every 30 minutes: `*:00/30`
- Every 2 hours: `*-*-* 00/2:00:00`
- Weekdays at 9am: `Mon..Fri *-*-* 09:00:00`
- Every Sunday at 4am: `Sun *-*-* 04:00:00`

**Prompt guidelines:**
- Be specific about what to check and how to format output
- Include "Send the result to Telegram" if not obvious
- Keep prompts under 500 chars for reliability

### Listing Timers

```bash
~/workspace/assistant/bin/manage-timer.sh list
```

Format the output nicely for Telegram.

### Removing a Timer

```bash
~/workspace/assistant/bin/manage-timer.sh remove --name "timer-name"
```

Confirm removal with the user.

## Required Permissions

These must be in `settings.json` allow list:
- `Bash(systemctl --user start *)`
- `Bash(systemctl --user stop *)`
- `Bash(systemctl --user enable *)`
- `Bash(systemctl --user disable *)`
- `Bash(systemctl --user daemon-reload)`
- `Bash(systemctl --user list-timers *)`
- `Bash(systemctl --user status *)`
- `Bash(*/manage-timer.sh *)`
```

- [ ] **Step 3: Create homelab skill**

Create `assistant/skills/homelab/SKILL.md`:

```markdown
# Homelab Skill

## When to Activate

When the user asks about:
- Service status ("is AdGuard up?", "check my services")
- Network info ("what's running on 10.0.10.x?")
- Homelab operations ("restart X", "check DNS")

## Service Topology

| Service | IP | Port | Purpose |
|---|---|---|---|
| AdGuard Home | 10.0.10.10 | 3000 | DNS filtering + ad blocking |
| Nginx Proxy Manager | 10.0.10.11 | 81 | Reverse proxy |
| n8n | 10.0.10.12 | 5678 | Workflow automation |
| Headscale | 10.0.10.13 | 8080 | VPN coordination |
| Uptime Kuma | 10.0.10.14 | 3001 | Monitoring + alerting |
| Claude Agent (this) | 10.0.10.20 | — | This assistant |

## Health Check Instructions

### Quick check (single service)

```bash
curl -sf -o /dev/null -w "%{http_code}" "http://SERVICE_IP:PORT" --connect-timeout 5
```

### Full homelab scan

Check all services and report status:

```bash
for service in "AdGuard:10.0.10.10:3000" "NPM:10.0.10.11:81" "n8n:10.0.10.12:5678" "Headscale:10.0.10.13:8080" "Uptime Kuma:10.0.10.14:3001"; do
    IFS=: read -r name ip port <<< "$service"
    status=$(curl -sf -o /dev/null -w "%{http_code}" "http://${ip}:${port}" --connect-timeout 5 2>/dev/null || echo "DOWN")
    echo "${name}: ${status}"
done
```

Format results as a clean Telegram message.

## Constraints

- This assistant runs in an unprivileged LXC — it CANNOT restart other LXCs
- For restart operations, suggest the user do it manually or use n8n webhooks
- Network diagnostics limited to curl/ping from this LXC's perspective

## Required Permissions

- `Bash(curl *)` — already in allow list
```

- [ ] **Step 4: Commit**

```bash
git add assistant/skills/
git commit -m "feat(assistant): add timer-management and homelab skills"
```

---

### Task 10: Install Script

**Files:**
- Create: `assistant/install.sh`

- [ ] **Step 1: Create install.sh**

Create `assistant/install.sh`:

```bash
#!/bin/bash
# Deploy Claude Assistant to the server
# Run from the repo root: ./assistant/install.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REMOTE_USER="claude-agent"
REMOTE_HOST="10.0.10.20"
REMOTE_DIR="/home/${REMOTE_USER}/workspace/assistant"

echo "=== Claude Assistant Deployment ==="
echo ""

# Check if we can reach the server
if ! ssh -q -o ConnectTimeout=5 "${REMOTE_USER}@${REMOTE_HOST}" exit 2>/dev/null; then
    echo "ERROR: Cannot reach ${REMOTE_USER}@${REMOTE_HOST}"
    echo "Make sure you have SSH access configured."
    exit 1
fi

echo "1. Syncing files to ${REMOTE_HOST}..."
rsync -av --exclude='config.env' --exclude='.last-activity' \
    --exclude='.restart-count' --exclude='docs/' \
    "${SCRIPT_DIR}/" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"

echo ""
echo "2. Setting permissions..."
ssh "${REMOTE_USER}@${REMOTE_HOST}" bash <<'REMOTE'
chmod +x ~/workspace/assistant/bin/*.sh
chmod +x ~/workspace/assistant/lib/*.sh
REMOTE

echo ""
echo "3. Checking config.env..."
CONFIG_EXISTS=$(ssh "${REMOTE_USER}@${REMOTE_HOST}" "test -f ~/workspace/assistant/config.env && echo yes || echo no")
if [ "$CONFIG_EXISTS" = "no" ]; then
    echo "   config.env not found. Creating from template..."
    ssh "${REMOTE_USER}@${REMOTE_HOST}" bash <<'REMOTE'
cp ~/workspace/assistant/config.env.example ~/workspace/assistant/config.env
chmod 600 ~/workspace/assistant/config.env
REMOTE
    echo "   IMPORTANT: Edit config.env on the server with your actual values:"
    echo "   ssh ${REMOTE_USER}@${REMOTE_HOST}"
    echo "   nano ~/workspace/assistant/config.env"
else
    echo "   config.env exists, skipping."
fi

echo ""
echo "4. Installing CLAUDE.md..."
ssh "${REMOTE_USER}@${REMOTE_HOST}" bash <<'REMOTE'
# Link assistant CLAUDE.md as the workspace CLAUDE.md
ln -sf ~/workspace/assistant/CLAUDE.md ~/workspace/CLAUDE.md
REMOTE

echo ""
echo "5. Installing settings.json..."
ssh "${REMOTE_USER}@${REMOTE_HOST}" bash <<'REMOTE'
# Merge assistant settings into user settings
# Preserve existing keys (like enabledPlugins), override permissions
if [ -f ~/.claude/settings.json ]; then
    jq -s '.[0] * .[1]' ~/.claude/settings.json ~/workspace/assistant/settings.json > /tmp/merged-settings.json
    mv /tmp/merged-settings.json ~/.claude/settings.json
else
    cp ~/workspace/assistant/settings.json ~/.claude/settings.json
fi
REMOTE

echo ""
echo "=== Deployment complete ==="
echo ""
echo "Next steps:"
echo "  1. Edit config.env on the server (if first deploy)"
echo "  2. Install new systemd service (requires root on LXC):"
echo "     sudo cp ${REMOTE_DIR}/systemd/claude-channels.service /etc/systemd/system/"
echo "     sudo systemctl daemon-reload"
echo "     sudo systemctl restart claude-channels"
echo "  3. Enable user-scoped systemd for timers (requires root, one-time):"
echo "     sudo loginctl enable-linger ${REMOTE_USER}"
```

- [ ] **Step 2: Make executable**

```bash
chmod +x assistant/install.sh
```

- [ ] **Step 3: Verify syntax**

```bash
bash -n assistant/install.sh
echo $?  # Expected: 0
```

- [ ] **Step 4: Commit**

```bash
git add assistant/install.sh
git commit -m "feat(assistant): add deployment install script"
```

---

### Task 11: Setup Documentation

**Files:**
- Create: `assistant/docs/setup.md`

- [ ] **Step 1: Create setup.md**

Create `assistant/docs/setup.md`:

```markdown
# Claude Assistant — Server Setup Guide

## Prerequisites

- Proxmox VE with LXC container (CT 120)
- LXC: Ubuntu 24.04, 4 CPU, 8GB RAM
- Node.js 22+, bun, jq installed
- Claude Code CLI installed (`~/.local/bin/claude`)
- Telegram bot created via @BotFather
- SSH access to `claude-agent@10.0.10.20`

## First-Time Setup

### 1. Resize LXC (if needed)

On PVE host:
```bash
pct set 120 --cores 4 --memory 8192
pct reboot 120
```

### 2. Deploy

From your dev machine (this repo):
```bash
./assistant/install.sh
```

### 3. Install claude-mem plugin

```bash
ssh claude-agent@10.0.10.20
claude plugin add claude-mem
```

Verify it's installed: `claude plugin list` should show claude-mem.

### 4. Configure secrets

SSH to the server and edit config.env:
```bash
ssh claude-agent@10.0.10.20
nano ~/workspace/assistant/config.env
# Fill in: TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID, UPTIME_KUMA_URL
```

### 5. Install systemd service (requires root)

```bash
# On the LXC as root:
cp /home/claude-agent/workspace/assistant/systemd/claude-channels.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable claude-channels
systemctl start claude-channels
```

### 6. Enable user timers (requires root, one-time)

```bash
loginctl enable-linger claude-agent
```

### 7. Set up healthcheck cron (requires root)

```bash
cp /home/claude-agent/workspace/assistant/systemd/claude-healthcheck.cron /etc/cron.d/claude-healthcheck
chmod 644 /etc/cron.d/claude-healthcheck
```

## Updating

```bash
# From dev machine
./assistant/install.sh

# Then on LXC as root (only if systemd unit changed):
cp /home/claude-agent/workspace/assistant/systemd/claude-channels.service /etc/systemd/system/
systemctl daemon-reload
systemctl restart claude-channels
```

## Troubleshooting

### Check service status
```bash
systemctl status claude-channels
journalctl -u claude-channels --no-pager -n 50
```

### Check session wrapper logs
```bash
journalctl -u claude-channels --no-pager --output=cat | tail -20
```

### Force session rotation
```bash
systemctl restart claude-channels
```

### Check active timers
```bash
su - claude-agent -c 'systemctl --user list-timers'
```

## Rollback

If the new setup doesn't work, restore the old service:
```bash
# Stop new service
systemctl stop claude-channels

# Restore old service (if backed up)
# Edit /etc/systemd/system/claude-channels.service to use the old ExecStart:
# ExecStart=/bin/script -qec '/home/claude-agent/.local/bin/claude --channels plugin:telegram@claude-plugins-official --dangerously-skip-permissions' /dev/null

systemctl daemon-reload
systemctl start claude-channels
```
```

- [ ] **Step 2: Commit**

```bash
git add assistant/docs/setup.md
git commit -m "docs(assistant): add server setup and migration guide"
```

---

### Task 12: Final Integration Commit

- [ ] **Step 1: Verify complete file structure**

```bash
find assistant/ -type f | sort
```

Expected output:
```
assistant/CLAUDE.md
assistant/bin/manage-timer.sh
assistant/bin/session-wrapper.sh
assistant/config.env.example
assistant/docs/setup.md
assistant/install.sh
assistant/lib/check-permission.sh
assistant/lib/healthcheck.sh
assistant/lib/run-timer-task.sh
assistant/lib/send-telegram.sh
assistant/settings.json
assistant/skills/README.md
assistant/skills/homelab/SKILL.md
assistant/skills/timer-management/SKILL.md
assistant/systemd/claude-channels.service
assistant/systemd/claude-healthcheck.cron
assistant/timers/templates/task.service.tmpl
assistant/timers/templates/task.timer.tmpl
```

- [ ] **Step 2: Verify all scripts pass syntax check**

```bash
for f in assistant/bin/*.sh assistant/lib/*.sh assistant/install.sh assistant/lib/run-timer-task.sh; do
    echo -n "$f: "
    bash -n "$f" && echo "OK" || echo "FAIL"
done
```

Expected: all OK

- [ ] **Step 3: Verify settings.json is valid JSON**

```bash
jq . assistant/settings.json > /dev/null && echo "Valid JSON" || echo "Invalid JSON"
```

- [ ] **Step 4: Final commit (if any uncommitted changes)**

```bash
git status
# If clean, skip. Otherwise:
git add -A assistant/
git commit -m "chore(assistant): final integration verification"
```
