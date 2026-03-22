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

---

Then commit:
```bash
git add assistant/docs/setup.md
git commit -m "docs(assistant): add server setup and migration guide"
```
