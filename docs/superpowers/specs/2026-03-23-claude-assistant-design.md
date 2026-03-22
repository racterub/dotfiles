# Claude Personal Assistant — Design Spec

**Date:** 2026-03-23
**Status:** Draft
**Author:** racterub + Claude

## Overview

An always-on personal assistant running on Proxmox LXC, accessible via Telegram. Built on Claude Code with session rotation to prevent context pollution, subagent dispatch for parallel tasks, dynamic scheduled tasks, and a skill-based plugin architecture for extensibility.

## Goals

- **Session isolation** — prevent context window pollution from long-lived sessions
- **Subagent dispatch** — parallel `claude -p` subprocesses for independent tasks
- **Google services** — Gmail, Calendar (connected), Drive (deferred)
- **Security** — replace `--dangerously-skip-permissions` with layered security
- **Memory** — cross-session persistence via claude-mem
- **Scheduled tasks** — dynamic systemd user timers, created at runtime
- **Extensible** — skill-based plugin architecture for adding capabilities
- **Resource efficient** — runs on 4 CPU / 8GB LXC

## Constraints

- Open source tooling where possible (gh CLI, systemd, etc.)
- Ubuntu-native tooling preferred
- Minimal custom code — glue is bash scripts, systemd units, CLAUDE.md
- No custom services or daemons beyond Claude Code itself

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  LXC (CT 120) — 4 CPU / 8GB — 10.0.10.20           │
│                                                     │
│  session-wrapper.sh (bash)                          │
│  ├─ Launches claude with channel MCP                │
│  ├─ Monitors idle time + context usage              │
│  ├─ Rotates session when threshold hit              │
│  └─ claude-mem persists across rotations            │
│                                                     │
│  Claude Code (main session)                         │
│  ├─ Telegram Channel MCP (user interface)           │
│  ├─ Gmail / Calendar MCP (already connected)        │
│  ├─ Context7 CLI + skill (docs lookup)              │
│  ├─ claude-mem (cross-session memory + search)      │
│  ├─ CLAUDE.md (router + dispatch logic)             │
│  ├─ Skills (modular capabilities)                   │
│  └─ Dispatches: claude -p "..." (isolated subtasks) │
│                                                     │
│  systemd user timers (dynamic scheduled tasks)      │
│  ├─ Created/removed at runtime via manage-timer.sh  │
│  ├─ Each invokes: claude -p "<prompt>"              │
│  └─ Results sent to Telegram via bot API            │
│                                                     │
│  Security layers                                    │
│  ├─ settings.json allow/deny (Claude Code enforced) │
│  ├─ CLAUDE.md permission self-check (reasoning)     │
│  ├─ check-permission.sh (lookup helper)             │
│  ├─ OS-level: no sudo, scoped to ~/workspace/       │
│  └─ config.env: chmod 600 (secrets)                 │
└─────────────────────────────────────────────────────┘
```

**Key principle:** Claude Code is the only runtime. Glue is bash scripts, systemd units, and CLAUDE.md instructions.

---

## Session Rotation

The wrapper script manages Claude Code's lifecycle to prevent context pollution.

### Rotation Triggers

| Trigger | Threshold | Configurable |
|---|---|---|
| Idle timeout | 30 minutes no Telegram activity | `IDLE_TIMEOUT_MIN` |
| Memory usage | >1.2GB (approaching ceiling) | `MEMORY_CEILING_MB` |
| Max uptime | 6 hours (hard cap) | `MAX_UPTIME_HOURS` |

### Rotation Sequence

1. Send SIGTERM to claude process
2. Wait for graceful shutdown (30s)
3. SIGKILL if still alive
4. Sleep 5s (cleanup)
5. Relaunch claude (claude-mem persists context)

### Edge Cases

- **Active conversation:** Defer rotation until idle (detect via recent Telegram activity or CPU usage)
- **Crash:** systemd restarts wrapper, which relaunches claude
- **Stuck:** Max uptime cap ensures eventual rotation

### User Experience

- Short tasks (already replied): no impact, next message starts fresh
- Mid-conversation: brief ~5s interruption, claude-mem provides context continuity
- User doesn't need to do anything special

### Configuration

All thresholds in `config.env`:

```bash
IDLE_TIMEOUT_MIN=30
MEMORY_CEILING_MB=1200
MAX_UPTIME_HOURS=6
ROTATE_COOLDOWN_SEC=5
```

---

## Dispatch & Subagents

The main session acts as a lightweight router. Heavy/independent tasks get dispatched to isolated subprocesses.

### Dispatch Rules (encoded in CLAUDE.md)

| Message type | Handling | Example |
|---|---|---|
| Quick question | Main session answers directly | "What time is my next meeting?" |
| Single task | `claude -p` subprocess | "Summarize this GitHub PR" |
| Multi-turn conversation | Main session keeps context | "Help me debug this deployment" |
| Multiple independent tasks | Parallel `claude -p` subprocesses | "Check my email AND review this PR" |
| Scheduled task output | `claude -p` → send result to Telegram | Morning briefing |

### Subprocess Isolation

- Each `claude -p` gets a clean context
- Inherits `settings.json` permissions (same security boundary)
- Has access to claude-mem for memory reads
- Does NOT have Telegram MCP — only main session talks to Telegram
- Working directory: `~/workspace/tasks/<task-id>/` (auto-cleaned)

### Concurrency

- Max 2 concurrent subprocesses (4 CPU / 8GB budget)
- CLAUDE.md instructs main session to queue if limit hit

---

## Scheduled Tasks

Dynamic systemd user timers, created and managed at runtime.

### Management Interface

```bash
# Create
manage-timer.sh create --name "morning-briefing" --schedule "08:00" \
  --prompt "Check calendar and email, send morning briefing"

# List
manage-timer.sh list

# Remove
manage-timer.sh remove --name "morning-briefing"
```

### How It Works

1. `create` renders `.service` + `.timer` from templates, installs to `~/.config/systemd/user/`, enables + starts
2. `list` reads `systemctl --user list-timers`
3. `remove` stops, disables, and deletes unit files

### Key Details

- User-scoped systemd (`systemctl --user`) — no root/sudo needed
- Requires `loginctl enable-linger claude-agent` (one-time setup)
- Each timer invokes `claude -p "<prompt>"` and sends result via `send-telegram.sh`
- CLAUDE.md instructs the session to use `manage-timer.sh` when user requests scheduling

### Use Cases

- Morning briefing (calendar + email + GitHub summary)
- Periodic inbox triage
- Calendar reminders
- Homelab health monitoring
- Any user-defined recurring task

---

## Security Model

Layered security replacing `--dangerously-skip-permissions`.

### Layer 1: settings.json Permissions (Claude Code enforced)

```jsonc
{
  "permissions": {
    "allow": [
      // Tools
      "Read", "Write", "Edit", "Glob", "Grep",
      "Agent", "Skill", "WebFetch", "WebSearch",

      // Safe bash
      "Bash(git *)", "Bash(ls *)", "Bash(cat *)",
      "Bash(head *)", "Bash(tail *)", "Bash(grep *)",
      "Bash(find *)", "Bash(wc *)", "Bash(jq *)",
      "Bash(mkdir *)", "Bash(cp *)", "Bash(mv *)",
      "Bash(echo *)", "Bash(date *)", "Bash(diff *)",
      "Bash(sort *)", "Bash(uniq *)", "Bash(sed *)",
      "Bash(awk *)", "Bash(tee *)", "Bash(chmod *)",

      // Runtime tools
      "Bash(curl *)", "Bash(wget *)",
      "Bash(python3 *)", "Bash(node *)", "Bash(bun *)",
      "Bash(npm *)", "Bash(npx *)",

      // Claude subprocesses
      "Bash(claude *)",

      // Timer management
      "Bash(systemctl --user *)",
      "Bash(*/manage-timer.sh *)",

      // Telegram send
      "Bash(*/send-telegram.sh *)",

      // MCP tools
      "mcp__*"
    ],
    "deny": [
      "Bash(sudo *)", "Bash(su *)",
      "Bash(apt *)", "Bash(dpkg *)",
      "Bash(systemctl start *)", "Bash(systemctl stop *)",
      "Bash(systemctl restart *)", "Bash(systemctl enable *)",
      "Bash(rm -rf /)", "Bash(dd *)",
      "Bash(mkfs *)", "Bash(mount *)", "Bash(umount *)",
      "Bash(iptables *)", "Bash(nft *)",
      "Bash(reboot *)", "Bash(shutdown *)",
      "Bash(passwd *)", "Bash(useradd *)",
      "Bash(userdel *)", "Bash(chown *)"
    ]
  }
}
```

### Layer 2: CLAUDE.md Permission Self-Check (reasoning layer)

Before executing any bash command, Claude:
1. Reads `~/.claude/settings.json` permissions
2. Verifies the command matches an allow pattern
3. If NOT matched → does not attempt, tells user via Telegram:
   > "I need permission for `Bash(<pattern>)`. Please add it to settings.json."

### Layer 3: check-permission.sh (helper)

```bash
check-permission.sh "docker *"
# exits 0 if allowed, 1 if not
```

### Layer 4: OS-level Isolation

- `claude-agent` user has no sudo
- Working directory scoped to `~/workspace/`
- SSH key scoped to specific GitHub repos

### Layer 5: Secrets Protection

- `config.env` is `chmod 600` (readable only by claude-agent)
- Contains `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`
- CLAUDE.md instructs never to expose secrets in Telegram messages

### Known Limitation: Headless Permission Prompt

If a command falls through both the CLAUDE.md self-check AND the settings.json allowlist, Claude Code prompts for approval — which hangs in headless mode.

**Mitigations:**
- Two independent guards must both fail (low probability)
- Session rotation max uptime cap (6h) recovers hung sessions
- Healthcheck detects no-activity + high-uptime → alerts via Uptime Kuma
- Review logs, expand allowlist as needed

---

## Skills Architecture

Modular plugin system for extending assistant capabilities.

### Skill Contract

Each skill is a folder with a `SKILL.md`:

```
skills/
├─ timer-management/
│   └─ SKILL.md
├─ homelab/
│   └─ SKILL.md
└─ README.md          # How to add new skills
```

- Self-contained instructions Claude can invoke
- Can reference helper scripts in `bin/` or `lib/`
- Can declare required permissions (for settings.json)
- Adding a skill = drop a folder, no code changes to core

### Built-in Skills

**timer-management** — Create, list, remove scheduled tasks via `manage-timer.sh`

**homelab** — Service topology (IPs, ports, purpose), health check patterns, common operations (check AdGuard stats, Uptime Kuma status, etc.)

### Adding Future Skills

1. Create `skills/<skill-name>/SKILL.md`
2. Add any helper scripts to `bin/` or `lib/`
3. Document required permissions in `SKILL.md`
4. Add permissions to `settings.json` if needed

Examples of future skills: travel booking, blockchain interaction, image generation, skills from [awesome-openclaw-skills](https://github.com/VoltAgent/awesome-openclaw-skills).

### CLAUDE.md Integration

```markdown
## Skills
Available skills are in ~/workspace/assistant/skills/.
Read the relevant SKILL.md when a user request matches a skill's domain.
```

---

## Google Services Integration

### Connected (via MCP)

- **Gmail** — Read, search, draft emails
- **Google Calendar** — List, create, update events, find free time

### Deferred

- **Google Drive** — Read+write access. No mature open-source MCP server available yet. Architecture supports plugging one in when available.

---

## File Structure

```
assistant/
├─ config.env.example          # Template (no secrets)
├─ CLAUDE.md                   # Core assistant behavior + dispatch logic
├─ settings.json               # Permissions (allow/deny)
├─ install.sh                  # Deploys to server
│
├─ bin/
│   ├─ session-wrapper.sh      # Session lifecycle + rotation
│   └─ manage-timer.sh         # Create/list/remove systemd timers
│
├─ lib/
│   ├─ send-telegram.sh        # Send message via bot API
│   └─ check-permission.sh     # Permission self-check helper
│
├─ timers/
│   └─ templates/
│       ├─ task.service.tmpl   # systemd user service template
│       └─ task.timer.tmpl     # systemd user timer template
│
├─ skills/
│   ├─ timer-management/
│   │   └─ SKILL.md
│   ├─ homelab/
│   │   └─ SKILL.md
│   └─ README.md               # How to add new skills
│
├─ systemd/
│   └─ claude-channels.service # Main service unit
│
└─ docs/
    └─ setup.md                # Server setup / migration guide
```

---

## Migration Plan

### Step 1: Prepare (on dev machine)

Build everything in `assistant/` folder in this repo. Test scripts locally where possible.

### Step 2: Resize LXC

```bash
# On PVE host
pct set 120 --cores 4 --memory 8192
pct reboot 120
```

### Step 3: Deploy alongside current setup

```bash
# rsync to server
rsync -av assistant/ claude-agent@10.0.10.20:~/workspace/assistant/

# On server: install config.env with secrets (manual, one-time)
cp config.env.example config.env
# Edit with actual TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID
chmod 600 config.env

# Enable user-scoped systemd
sudo loginctl enable-linger claude-agent
```

### Step 4: Test new service

- Start new service manually, verify Telegram works
- Test dispatch scenarios
- Test timer creation/removal
- Verify permission self-check works

### Step 5: Swap

- Stop old `claude-channels.service`
- Enable + start new service
- Verify healthcheck still works

### Step 6: Cleanup

- Remove old service unit
- Confirm `--dangerously-skip-permissions` is gone

### Rollback

If anything fails at Step 5: stop new service, restart old one. Old service unit preserved until confirmed.
