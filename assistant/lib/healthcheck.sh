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
