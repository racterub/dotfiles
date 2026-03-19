# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a **Claude Code development environment setup** repository. It configures Claude Code to operate with:
- Enforced development workflow (Brainstorm → Plan → Approve → Implement → Verify)
- Anti-hallucination guardrails requiring verification before claims
- Rules files for operational procedures (auto-loaded from `~/.claude/rules/`)
- Hooks for session-start context, compaction control, command guarding, auto-formatting, commit validation, and audit logging
- User-scoped memory for cross-project learning
- Context7 MCP integration for documentation lookup

## Prerequisites

- `jq` - Required for MCP config merging, settings merge, statusline, and hooks
- `bc` - Required for statusline arithmetic
- `npx` (Node.js) - Required for Context7 MCP server

## Installation

```bash
./install.sh
```

This script:
1. Backs up existing `~/.claude/` contents to `~/.claude-backup-TIMESTAMP/`
2. Symlinks `claude/CLAUDE.md` → `~/.claude/CLAUDE.md`
3. Symlinks `claude/rules/` → `~/.claude/rules/`
4. Symlinks `claude/hooks/` → `~/.claude/hooks/`
5. Symlinks `claude/statusline.sh` → `~/.claude/statusline.sh`
6. Merges `claude/settings.json` into `~/.claude/settings.json` (preserves existing keys like `enabledPlugins`)
7. Merges Context7 MCP config into `~/.mcp.json`
8. Symlinks `claude/memory/` → `~/.claude/memory/`
9. Symlinks `claude/skills/` → `~/.claude/skills/`

### Verify Installation

```bash
# Check symlinks are correct
ls -la ~/.claude/

# Test statusline script (requires jq, bc)
echo '{"model":{"display_name":"Test"},"context_window":{"used_percentage":25},"cost":{"total_cost_usd":0.01,"total_lines_added":10,"total_lines_removed":5}}' | ~/.claude/statusline.sh

# Restart Claude Code to apply changes
```

## Repository Structure

```
claude/                 # Claude Code configuration (installed to ~/.claude/)
├── CLAUDE.md          # Personal dev guidelines (core principles, decision framework)
├── .mcp.json          # Context7 MCP server configuration
├── settings.json      # Statusline + hooks template (merged, not symlinked)
├── statusline.sh      # Statusline script (model, context %, cost, lines)
├── hooks/
│   ├── session-start.sh       # Injects codebase context on new sessions
│   ├── compact-guard.sh       # Blocks auto-compaction, prompts user
│   ├── pre-bash-guard.sh      # Defense-in-depth: blocks dangerous command patterns
│   ├── pre-commit-validate.sh # Enforces commit quality gates (no --no-verify)
│   ├── post-edit-format.sh    # Auto-formats files by language after edits
│   └── post-bash-audit.sh     # Logs all bash commands to ~/.claude/audit.log
├── memory/
│   ├── MEMORY.md          # User memory index (injected at session start)
│   ├── mistakes/          # Errors to avoid repeating
│   ├── patterns/          # Approaches that work well
│   ├── skill-gaps/        # Areas to proactively compensate for
│   ├── prompt-quality/    # What makes prompts effective
│   └── design-outcomes/   # Post-hoc design evaluation
├── skills/
│   └── retro/             # /retro skill for end-of-cycle reflection
└── rules/
    ├── anti-hallucination.md  # Say "I don't know", use Context7, cite sources
    ├── quality-gates.md       # Definition of done, commit requirements
    ├── when-stuck.md          # 3-attempts-max escalation
    └── github.md              # Use gh CLI for all GitHub operations

# Traditional dotfiles (not auto-installed)
.vimrc                 # Vim with Plug manager, ALE linting, NERDTree
.zshrc                 # Oh-My-Zsh with powerlevel9k theme
.bashrc                # Bash with powerline, virtualenvwrapper
.tmux.conf             # Tmux with solarized theme, vim keybindings
.editorconfig          # Cross-editor formatting (Python/Vim/Ruby/YAML)
.gdbinit               # GDB with PEDA/PwnGDB for debugging
```

## Key Files

- **`claude/CLAUDE.md`**: Personal development guidelines installed to `~/.claude/CLAUDE.md`. Contains edit-approval gate, core principles, tidy first, architecture principles, and decision framework.
- **`claude/rules/`**: Operational procedure rules auto-loaded by Claude Code from `~/.claude/rules/`. Covers anti-hallucination, quality gates, when-stuck escalation, and GitHub CLI preference.
- **`claude/hooks/`**: Shell hooks for Claude Code events. Includes session-start context injection, auto-compaction guard, dangerous command guard, auto-formatting by language, commit quality gate enforcement, and bash command audit logging.
- **`claude/settings.json`**: Template with `permissions`, `statusLine`, and `hooks` config. Merged (not symlinked) into `~/.claude/settings.json` to preserve existing keys like `enabledPlugins`. Permissions auto-allow read-only commands and prompt for dangerous ones.
- **`claude/.mcp.json`**: Context7 MCP server config using `@upstash/context7-mcp`.
- **`claude/statusline.sh`**: Statusline script displaying model name, context usage %, session cost, and lines changed. Requires `jq`.
- **`install.sh`**: Safe installation with automatic backups, symlink detection, JSON merging, and memory/skills symlinks.
- **`claude/memory/`**: User-scoped cross-project memory. Stores mistakes, patterns, skill gaps, prompt quality insights, and design outcomes. Index (`MEMORY.md`) injected at session start. See `claude/rules/memory.md` for read/write policy.
- **`claude/skills/retro/`**: Structured end-of-cycle retrospective skill. Captures session learnings into memory and surfaces feedback to user.

## Making Changes

When modifying Claude Code configuration:
1. Edit files in `claude/` directory
2. Re-run `./install.sh` to update symlinks and merge settings
3. Changes take effect in next Claude Code session

When adding new rules:
1. Create `claude/rules/<rule-name>.md`
2. Write the rule as plain markdown (auto-loaded by Claude Code)
3. Re-run `./install.sh` to update symlinks (rules directory is symlinked as a whole)
