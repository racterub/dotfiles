# Claude Code Setup Restructure — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restructure Claude Code dotfiles to remove dead skills, slim CLAUDE.md, add rules/hooks, and fix settings.json merge.

**Architecture:** Replace skills/ with rules/ and hooks/ directories. CLAUDE.md becomes personal values only. install.sh switches settings.json from symlink to jq merge. Two shell hooks handle session-start context and auto-compaction blocking.

**Tech Stack:** Bash, jq, Claude Code hooks API (JSON stdin/stdout)

---

### Task 1: Delete skills directory

**Files:**
- Delete: `claude/skills/backend/SKILL.md`
- Delete: `claude/skills/frontend/SKILL.md`
- Delete: `claude/skills/qa/SKILL.md`
- Delete: `claude/skills/sre/SKILL.md`
- Delete: `claude/skills/infra/SKILL.md`
- Delete: `claude/skills/dba/SKILL.md`
- Delete: `claude/skills/data/SKILL.md`
- Delete: `claude/skills/security/SKILL.md`
- Delete: `claude/skills/integration-check/SKILL.md`

**Step 1: Remove skills directory**

```bash
rm -rf claude/skills/
```

**Step 2: Verify deletion**

```bash
ls claude/skills/ 2>&1
```
Expected: `No such file or directory`

**Step 3: Commit**

```bash
git add -A claude/skills/
git commit -m "chore: remove unused role skills

Skills (backend, frontend, qa, sre, infra, dba, data, security,
integration-check) were never invoked by Claude. Workflow is now
handled entirely by the superpowers plugin."
```

---

### Task 2: Create rules files

**Files:**
- Create: `claude/rules/anti-hallucination.md`
- Create: `claude/rules/quality-gates.md`
- Create: `claude/rules/when-stuck.md`
- Create: `claude/rules/github.md`

**Step 1: Create rules directory**

```bash
mkdir -p claude/rules
```

**Step 2: Create `claude/rules/anti-hallucination.md`**

```markdown
# Anti-Hallucination

When uncertain, say "I don't know."

- Never fabricate APIs, library methods, or configuration options
- Never guess at syntax or behavior - look it up first
- Use Context7 MCP to fetch current documentation for libraries/frameworks
- Cite sources when referencing external docs
- If documentation is unavailable, explicitly state uncertainty

Red flags that require verification:
- "I believe this API..."
- "This should work..."
- "Typically this is done by..."

Replace with actual lookup or explicit "I don't know."
```

**Step 3: Create `claude/rules/quality-gates.md`**

```markdown
# Quality Gates

## Definition of Done

- [ ] Tests written and passing
- [ ] Code follows project conventions
- [ ] No linter/formatter warnings
- [ ] Commit messages are clear
- [ ] Implementation matches plan
- [ ] Integration verified (components wired up)
- [ ] No TODOs without issue numbers

## Every Commit Must

- Compile successfully
- Pass all existing tests
- Include tests for new functionality
- Follow project formatting/linting
```

**Step 4: Create `claude/rules/when-stuck.md`**

```markdown
# When Stuck (3 Attempts Max)

Maximum 3 attempts per issue, then STOP.

1. **Document what failed**: What you tried, specific errors, why it failed
2. **Research alternatives**: Find 2-3 similar implementations, note approaches
3. **Question fundamentals**: Right abstraction? Can it split smaller? Simpler approach?
4. **Try different angle**: Different library feature? Different pattern? Remove abstraction?
```

**Step 5: Create `claude/rules/github.md`**

```markdown
# GitHub

Use the `gh` CLI for all GitHub operations (issues, PRs, checks, releases).
Do not use WebFetch, curl, or MCP tools for GitHub URLs.
If given a GitHub URL, use `gh` to get the information needed.
```

**Step 6: Verify all files exist**

```bash
ls claude/rules/
```
Expected: `anti-hallucination.md  github.md  quality-gates.md  when-stuck.md`

**Step 7: Commit**

```bash
git add claude/rules/
git commit -m "feat: add rules files for operational procedures

Moved anti-hallucination, quality gates, when-stuck, and GitHub CLI
preference out of CLAUDE.md into separate rules files. These are
auto-loaded by Claude Code from ~/.claude/rules/."
```

---

### Task 3: Create hook scripts

**Files:**
- Create: `claude/hooks/session-start.sh`
- Create: `claude/hooks/compact-guard.sh`

**Step 1: Create hooks directory**

```bash
mkdir -p claude/hooks
```

**Step 2: Create `claude/hooks/session-start.sh`**

```bash
#!/bin/bash
# SessionStart hook: lightweight codebase context injection
# Matcher: startup (new sessions only, not resume/clear/compact)

CWD=$(jq -r '.cwd' < /dev/stdin)

CONTEXT=""

# Read project README or CLAUDE.md (first found)
for f in "$CWD/README.md" "$CWD/CLAUDE.md"; do
    if [[ -f "$f" ]]; then
        CONTEXT+="## $(basename "$f")"$'\n'
        CONTEXT+="$(head -50 "$f")"$'\n\n'
        break
    fi
done

# Top-level directory structure
if [[ -d "$CWD" ]]; then
    CONTEXT+="## Structure"$'\n'
    CONTEXT+="$(ls -1 "$CWD" | head -30)"$'\n\n'
fi

# Recent git commits
if git -C "$CWD" rev-parse --git-dir > /dev/null 2>&1; then
    CONTEXT+="## Recent commits"$'\n'
    CONTEXT+="$(git -C "$CWD" log --oneline -5 2>/dev/null)"$'\n'
fi

# Return as additionalContext JSON
jq -n --arg ctx "$CONTEXT" '{
    hookSpecificOutput: {
        hookEventName: "SessionStart",
        additionalContext: $ctx
    }
}'
```

**Step 3: Make executable**

```bash
chmod +x claude/hooks/session-start.sh
```

**Step 4: Create `claude/hooks/compact-guard.sh`**

```bash
#!/bin/bash
# PreCompact hook: block auto-compaction, let user decide
# Matcher: auto (manual /compact passes through)

echo "Auto-compaction blocked by hook. Ask the user if they want to run /compact manually." >&2
exit 2
```

**Step 5: Make executable**

```bash
chmod +x claude/hooks/compact-guard.sh
```

**Step 6: Verify**

```bash
ls -la claude/hooks/
```
Expected: Both files listed with execute permission

**Step 7: Commit**

```bash
git add claude/hooks/
git commit -m "feat: add session-start and compact-guard hooks

session-start.sh injects lightweight codebase context (README, dir
structure, recent commits) on new sessions.

compact-guard.sh blocks auto-compaction so user can manually decide
when to run /compact."
```

---

### Task 4: Rewrite CLAUDE.md

**Files:**
- Modify: `claude/CLAUDE.md`

**Step 1: Replace `claude/CLAUDE.md` with slimmed version**

```markdown
# Development Guidelines

## STOP - Before Code Changes

Before using **Edit**, **Write**, or **NotebookEdit**:

1. Has the user approved a plan for this change? → If NO, propose the plan first
2. For trivial fixes (typos, obvious bugs): ask "Should I fix this?" before editing

**Does NOT require approval:** Reading/searching code, exploring codebase, running read-only commands, answering questions
**Requires approval:** Any file modification, any new file creation

## Core Principles

- **Clear intent over clever code** - Be boring and obvious
- **Incremental progress over big bangs** - Small changes that compile and pass tests
- **Learning from existing code** - Study and plan before implementing
- **Pragmatic over dogmatic** - Adapt to project reality
- If you need to explain it, it's too complex
- Avoid premature abstractions

## Tidy First

Separate all changes into two distinct types:
1. **STRUCTURAL CHANGES**: Rearranging code without changing behavior
2. **BEHAVIORAL CHANGES**: Adding or modifying actual functionality

- Never mix structural and behavioral changes in the same commit
- Always make structural changes first when both are needed
- Every commit must clearly state whether it contains structural or behavioral changes

## Before Committing

- Run formatters/linters
- Self-review changes
- Ensure commit message explains "why"

## Architecture Principles

- **Composition over inheritance** - Use dependency injection
- **Interfaces over singletons** - Enable testing and flexibility
- **Explicit over implicit** - Clear data flow and dependencies

## Decision Framework

When multiple valid approaches exist, choose based on:
1. **Testability** - Can I easily test this?
2. **Readability** - Will someone understand this in 6 months?
3. **Consistency** - Does this match project patterns?
4. **Simplicity** - Is this the simplest solution that works?
5. **Reversibility** - How hard to change later?

## Hard Rules

- NEVER use `--no-verify` to bypass commit hooks
- ALWAYS learn from existing implementations before writing new code
```

**Step 2: Verify line count**

```bash
wc -l claude/CLAUDE.md
```
Expected: ~50 lines

**Step 3: Commit**

```bash
git add claude/CLAUDE.md
git commit -m "refactor: slim CLAUDE.md to personal values only

Removed workflow, TDD, quality gates, and anti-hallucination sections
that duplicate superpowers plugin. Moved operational procedures to
rules/*.md files. CLAUDE.md now contains only the edit-approval gate,
core principles, tidy first, architecture, and decision framework."
```

---

### Task 5: Update settings.json template

**Files:**
- Modify: `claude/settings.json`

**Step 1: Replace `claude/settings.json` with full template**

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 0
  },
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/session-start.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "matcher": "auto",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/compact-guard.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

**Step 2: Validate JSON**

```bash
jq . claude/settings.json
```
Expected: Valid JSON output, no errors

**Step 3: Commit**

```bash
git add claude/settings.json
git commit -m "feat: add hooks config to settings.json template

Added SessionStart hook (session-start.sh) and PreCompact hook
(compact-guard.sh). This file is now merged into ~/.claude/settings.json
by install.sh instead of symlinked."
```

---

### Task 6: Rewrite install.sh

**Files:**
- Modify: `install.sh`

**Step 1: Replace `install.sh` with updated version**

The new install.sh must:
1. Keep `backup_and_link` function unchanged
2. Keep CLAUDE.md symlink unchanged
3. **Remove** skills symlink section
4. **Add** rules/ symlink
5. **Add** hooks/ symlink
6. Keep statusline.sh symlink unchanged
7. **Replace** settings.json symlink with jq merge (merge `statusLine` and `hooks` keys)
8. **Add** cleanup: remove old skills/ symlink if present
9. Keep .mcp.json merge unchanged
10. Update summary output

Key change for settings.json merge:

```bash
# Merge settings.json (statusLine + hooks into existing settings)
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
TEMPLATE="$SCRIPT_DIR/claude/settings.json"

if [[ -f "$SETTINGS_FILE" ]]; then
    if command -v jq &> /dev/null; then
        # Check if it's a symlink (from old install) — remove it first
        if [[ -L "$SETTINGS_FILE" ]]; then
            echo "  [migrate] Removing old settings.json symlink"
            mkdir -p "$BACKUP_DIR"
            cp "$(readlink "$SETTINGS_FILE")" "$BACKUP_DIR/settings.json"
            rm "$SETTINGS_FILE"
            # Start fresh with template
            cp "$TEMPLATE" "$SETTINGS_FILE"
            echo "  [copy] settings.json created from template"
        else
            echo "  [merge] Merging statusLine and hooks into existing settings.json"
            mkdir -p "$BACKUP_DIR"
            cp "$SETTINGS_FILE" "$BACKUP_DIR/settings.json"
            # Merge template keys into existing settings
            jq -s '.[0] * .[1]' "$SETTINGS_FILE" "$TEMPLATE" > "$SETTINGS_FILE.tmp"
            mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
            echo "  [done] statusLine and hooks merged"
        fi
    else
        echo "  [warn] jq not installed, cannot merge settings.json"
        echo "         Please manually add hooks config from:"
        cat "$TEMPLATE"
    fi
else
    cp "$TEMPLATE" "$SETTINGS_FILE"
    echo "  [copy] settings.json created from template"
fi
```

Key change for skills cleanup:

```bash
# Cleanup old skills symlink if present
if [[ -L "$CLAUDE_DIR/skills" ]]; then
    echo ""
    echo "Cleaning up old skills/..."
    rm "$CLAUDE_DIR/skills"
    echo "  [remove] old skills/ symlink removed"
fi
```

**Step 2: Verify script syntax**

```bash
bash -n install.sh
```
Expected: No output (clean syntax)

**Step 3: Commit**

```bash
git add install.sh
git commit -m "feat: update install.sh for rules, hooks, and settings merge

- Added rules/ and hooks/ symlinks
- Changed settings.json from symlink to jq merge (preserves enabledPlugins)
- Added cleanup of old skills/ symlink
- Removed skills/ symlink setup
- Updated summary output"
```

---

### Task 7: Update project CLAUDE.md

**Files:**
- Modify: `CLAUDE.md` (repo root)

**Step 1: Update `CLAUDE.md` to reflect new structure**

Update these sections:
- Repository Purpose: remove "Role-specific expertise skills" mention
- Installation script steps: replace skills symlink with rules/hooks symlinks, note settings.json merge
- Repository Structure: replace skills/ tree with rules/ and hooks/ tree
- Key Files: update descriptions, add rules and hooks entries
- Making Changes: replace "adding new skills" with "adding new rules"

**Step 2: Verify content is accurate**

Read through and confirm all paths/descriptions match the new structure.

**Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update project CLAUDE.md for restructured layout

Updated repository structure, installation steps, and key file
descriptions to reflect rules/, hooks/, and settings merge changes."
```

---

### Task 8: Test installation

**Step 1: Run install.sh in dry-run fashion**

```bash
bash -n install.sh
```
Expected: No syntax errors

**Step 2: Verify all source files exist**

```bash
ls claude/CLAUDE.md claude/settings.json claude/statusline.sh claude/.mcp.json
ls claude/rules/anti-hallucination.md claude/rules/quality-gates.md claude/rules/when-stuck.md claude/rules/github.md
ls claude/hooks/session-start.sh claude/hooks/compact-guard.sh
```
Expected: All files listed

**Step 3: Verify hooks are executable**

```bash
test -x claude/hooks/session-start.sh && echo "OK" || echo "FAIL"
test -x claude/hooks/compact-guard.sh && echo "OK" || echo "FAIL"
```
Expected: Both OK

**Step 4: Test session-start.sh locally**

```bash
echo '{"cwd":"/home/racterub/github/dotfiles"}' | claude/hooks/session-start.sh
```
Expected: JSON with `hookSpecificOutput.additionalContext` containing README content, directory listing, and recent commits

**Step 5: Test compact-guard.sh locally**

```bash
echo '{}' | claude/hooks/compact-guard.sh 2>&1; echo "exit: $?"
```
Expected: stderr message about auto-compaction blocked, exit code 2

**Step 6: Test settings.json merge logic**

```bash
# Simulate merge with a temp file
echo '{"enabledPlugins":{"superpowers":true},"statusLine":{"old":true}}' > /tmp/test-settings.json
jq -s '.[0] * .[1]' /tmp/test-settings.json claude/settings.json
rm /tmp/test-settings.json
```
Expected: JSON with both `enabledPlugins` preserved and new `statusLine`+`hooks` merged in

**Step 7: Commit any fixes if needed, then final commit**

```bash
git add -A
git status
```
Expected: Clean working tree (everything committed in previous tasks)
