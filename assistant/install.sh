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
