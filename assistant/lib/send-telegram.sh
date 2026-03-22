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
