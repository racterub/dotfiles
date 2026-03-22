# Claude Code Setup Restructure

## Overview

Restructure the Claude Code dotfiles to remove unused role skills, slim down CLAUDE.md to personal values only, add rules files for operational procedures, and introduce hooks for session-start context and manual compaction control.

## Problem Statement

1. **CLAUDE.md is bloated** (187 lines) — most workflow/TDD content duplicates superpowers plugin
2. **Role skills are never invoked** — 9 skill directories (backend, frontend, qa, etc.) are dead weight
3. **No automatic codebase context** — every new session requires manually asking Claude to explore
4. **Auto-compaction is uncontrolled** — user prefers manual compaction with a warning
5. **No GitHub CLI preference** — Claude defaults to WebFetch/curl for GitHub instead of `gh`
6. **settings.json conflict** — install.sh symlinks it, overwriting live plugin config

## Design

### Directory Structure

**Before:**
```
claude/
├── CLAUDE.md          (187 lines, bloated)
├── .mcp.json
├── settings.json      (statusline only, symlinked)
├── statusline.sh
└── skills/            (9 role skills, never invoked)
    ├── backend/SKILL.md
    ├── frontend/SKILL.md
    ├── qa/SKILL.md
    ├── sre/SKILL.md
    ├── infra/SKILL.md
    ├── dba/SKILL.md
    ├── data/SKILL.md
    ├── security/SKILL.md
    └── integration-check/SKILL.md
```

**After:**
```
claude/
├── CLAUDE.md          (~50 lines, personal values only)
├── .mcp.json
├── settings.json      (statusline + hooks template, merged not symlinked)
├── statusline.sh
├── hooks/
│   ├── session-start.sh
│   └── compact-guard.sh
└── rules/
    ├── anti-hallucination.md
    ├── quality-gates.md
    ├── when-stuck.md
    └── github.md
```

**Deleted:** entire `skills/` directory

### CLAUDE.md (~50 lines)

Contains only personal values and the edit-approval gate. All process/workflow deferred to superpowers plugin. All operational procedures moved to `rules/`.

Sections kept:
- **STOP - Before Code Changes** — approval gate requiring plan before edits
- **Core Principles** — boring > clever, incremental, pragmatic, learn from existing code
- **Tidy First** — structural vs behavioral commit separation
- **Before Committing** — run formatters, self-review, explain "why"
- **Architecture Principles** — composition, interfaces, explicit > implicit
- **Decision Framework** — testability > readability > consistency > simplicity > reversibility
- **Hard Rules** — never `--no-verify`, always learn from existing implementations

Sections removed (covered by superpowers):
- Mandatory Workflow (brainstorming + writing-plans + TDD + verification skills)
- Role Skills table (skills deleted)
- Implementation Flow (TDD skill)
- TDD Methodology (TDD skill)
- When Stuck (moved to rules/when-stuck.md)
- Quality Gates (moved to rules/quality-gates.md)
- Anti-Hallucination (moved to rules/anti-hallucination.md)
- NEVER/ALWAYS list (unique items kept in Hard Rules, rest redundant with superpowers)

### Rules (auto-loaded from `~/.claude/rules/`)

**`rules/anti-hallucination.md`** — say "I don't know," never fabricate APIs, use Context7 MCP, cite sources, red flag phrases

**`rules/quality-gates.md`** — Definition of Done checklist, commit requirements

**`rules/when-stuck.md`** — 3-attempts-max rule, escalation steps

**`rules/github.md`** — use `gh` CLI for all GitHub operations

### Hooks

**`hooks/session-start.sh`**
- Event: `SessionStart` (matcher: `startup`)
- Purpose: Lightweight codebase context on new sessions
- Reads project README.md or CLAUDE.md (first found)
- Lists top-level directory structure
- Shows last 5 git commits
- Returns as `additionalContext` JSON
- Timeout: 10s
- Does NOT run on resume/clear/compact

**`hooks/compact-guard.sh`**
- Event: `PreCompact` (matcher: `auto`)
- Purpose: Block auto-compaction, let user decide
- Exits with code 2, stderr message tells Claude to ask the user
- Manual `/compact` unaffected (matcher is `auto` only)
- Timeout: 5s

### settings.json Handling

**Changed from symlink to merge.** The repo stores a template with `statusLine` and `hooks` keys. `install.sh` merges these into the existing `~/.claude/settings.json` using jq, preserving `enabledPlugins` and other live state.

### install.sh Changes

| Target | Method | Change |
|--------|--------|--------|
| `~/.claude/CLAUDE.md` | symlink | No change |
| `~/.claude/rules/` | symlink | **New** |
| `~/.claude/hooks/` | symlink | **New** |
| `~/.claude/statusline.sh` | symlink | No change |
| `~/.claude/settings.json` | merge | **Changed** from symlink to merge |
| `~/.mcp.json` | merge | No change |
| `~/.claude/skills/` | remove | **Cleanup** of old symlink |

## Migration

- Old `skills/` symlink is removed during install
- Old `settings.json` symlink (if present) is backed up and replaced with merge behavior
- Existing `~/.claude/settings.json` content (enabledPlugins, etc.) is preserved
- No manual steps required beyond re-running `./install.sh`

## Dependencies

- `jq` — required for settings.json merge and hooks
- `git` — required for session-start.sh (git log)
- superpowers plugin — must be enabled (handles workflow, TDD, debugging, verification)
