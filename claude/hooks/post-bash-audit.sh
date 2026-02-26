#!/bin/bash
# PostToolUse hook: audit log for all bash commands
# Matcher: Bash
# Appends to ~/.claude/audit.log with rotation

INPUT=$(cat /dev/stdin)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Exit early if no command
[[ -z "$COMMAND" ]] && exit 0

LOG_FILE="$HOME/.claude/audit.log"
TIMESTAMP=$(date -Iseconds)

# Append log entry
echo "[$TIMESTAMP] CWD: $CWD | CMD: $COMMAND" >> "$LOG_FILE"

# Rotate: keep last 1000 lines
if [[ -f "$LOG_FILE" ]]; then
    LINE_COUNT=$(wc -l < "$LOG_FILE")
    if (( LINE_COUNT > 1000 )); then
        tail -n 1000 "$LOG_FILE" > "$LOG_FILE.tmp"
        mv "$LOG_FILE.tmp" "$LOG_FILE"
    fi
fi

exit 0
