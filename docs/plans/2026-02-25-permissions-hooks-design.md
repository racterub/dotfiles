# Permissions & Hooks Enhancement Design

**Date:** 2026-02-25
**Scope:** Global Claude Code configuration (`~/.claude/settings.json`)

## Goal

Enhance the Claude Code setup with:
1. Permission rules to auto-approve read-only commands and prompt for dangerous ones
2. Four new hooks for command guarding, auto-formatting, commit validation, and audit logging

## Permissions

### Allow (auto-approved, no prompt)

Read-only system commands:
- `ls`, `cat`, `head`, `tail`, `wc`, `file`, `tree`, `stat`, `find`, `which`
- `pwd`, `echo`, `env`, `printenv`, `whoami`, `id`, `uname`, `date`

Read-only git commands:
- `git log`, `git status`, `git diff`, `git branch`, `git show`
- `git remote`, `git tag`, `git rev-parse`, `git ls-files`

GitHub CLI:
- `gh` (all subcommands)

### Ask (always prompts user)

Destructive commands:
- `rm`, `rmdir`, `shred`, `truncate`, `dd`, `mkfs`
- `mv /*` (moving from root)

Privilege escalation:
- `sudo`, `su`, `chmod`, `chown`, `pkexec`

Dangerous git operations:
- `git push --force`, `git reset --hard`, `git clean`

### Settings format

```json
{
  "permissions": {
    "allow": [
      "Bash(ls *)", "Bash(cat *)", "Bash(head *)", "Bash(tail *)",
      "Bash(wc *)", "Bash(file *)", "Bash(tree *)", "Bash(stat *)",
      "Bash(find *)", "Bash(which *)", "Bash(pwd)", "Bash(echo *)",
      "Bash(env)", "Bash(printenv *)", "Bash(whoami)", "Bash(id)",
      "Bash(uname *)", "Bash(date *)",
      "Bash(git log *)", "Bash(git status *)", "Bash(git diff *)",
      "Bash(git branch *)", "Bash(git show *)", "Bash(git remote *)",
      "Bash(git tag *)", "Bash(git rev-parse *)", "Bash(git ls-files *)",
      "Bash(gh *)"
    ],
    "ask": [
      "Bash(rm *)", "Bash(rmdir *)", "Bash(shred *)", "Bash(truncate *)",
      "Bash(sudo *)", "Bash(su *)", "Bash(chmod *)", "Bash(chown *)",
      "Bash(pkexec *)", "Bash(dd *)", "Bash(mkfs *)", "Bash(mv /*)",
      "Bash(git push --force *)", "Bash(git reset --hard *)",
      "Bash(git clean *)"
    ]
  }
}
```

## Hooks

### Hook 1: pre-bash-guard.sh

- **Event:** PreToolUse
- **Matcher:** Bash
- **Purpose:** Defense-in-depth against dangerous commands that bypass permission glob patterns (e.g., chained commands like `ls && rm -rf /`)
- **Logic:** Regex check against blocklist patterns (rm -rf /, sudo su, chmod 777, dd if=, fork bombs, etc.)
- **Exit:** 0 = pass, 2 = block with stderr message

### Hook 2: post-edit-format.sh

- **Event:** PostToolUse
- **Matcher:** Edit|Write
- **Purpose:** Auto-format files after Claude edits them, language-aware
- **Logic:** Detect language from file extension, run appropriate formatter if installed:
  - `.go` → `gofmt -w`
  - `.py` → `ruff format` (fallback: `black`)
  - `.rs` → `rustfmt`
  - `.js/.ts/.jsx/.tsx/.json/.md/.yaml/.yml` → `prettier --write`
  - `.sh` → `shfmt -w`
  - Other → skip
- **Exit:** Always 0 (formatting failure must not block work)

### Hook 3: pre-commit-validate.sh

- **Event:** PreToolUse
- **Matcher:** Bash
- **Purpose:** Enforce commit quality gates
- **Logic:**
  - Block `--no-verify` flag (matches CLAUDE.md hard rule)
  - Block `--amend` on main/master branch
  - Warn on empty commit message
- **Exit:** 0 = pass, 2 = block with stderr message

### Hook 4: post-bash-audit.sh

- **Event:** PostToolUse
- **Matcher:** Bash
- **Purpose:** Log all executed bash commands for review
- **Output:** Append to `~/.claude/audit.log`
- **Format:** `[ISO-8601] CMD: <command> | EXIT: <code> | CWD: <dir>`
- **Rotation:** Keep last 1000 lines to prevent unbounded growth

### Updated settings.json hooks section

```
SessionStart  → session-start.sh        (existing)
PreCompact    → compact-guard.sh         (existing)
PreToolUse    → pre-bash-guard.sh        (new, matcher: Bash)
PreToolUse    → pre-commit-validate.sh   (new, matcher: Bash)
PostToolUse   → post-edit-format.sh      (new, matcher: Edit|Write)
PostToolUse   → post-bash-audit.sh       (new, matcher: Bash)
```

## Install changes

- `claude/settings.json` template updated with permissions block and new hooks
- No install.sh changes needed — hooks dir is already symlinked, settings are merged
- New hook scripts added to `claude/hooks/`

## Files to create/modify

- **Create:** `claude/hooks/pre-bash-guard.sh`
- **Create:** `claude/hooks/post-edit-format.sh`
- **Create:** `claude/hooks/pre-commit-validate.sh`
- **Create:** `claude/hooks/post-bash-audit.sh`
- **Modify:** `claude/settings.json` (add permissions + new hooks)
- **Modify:** `CLAUDE.md` (update repository structure docs)
