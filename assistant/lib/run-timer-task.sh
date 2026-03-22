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
