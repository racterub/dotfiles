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
