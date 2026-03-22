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
