# Permissions & Hooks Enhancement Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add global permission rules (allow read-only, ask for dangerous) and four new hooks (bash guard, auto-format, commit validation, audit log) to the Claude Code dotfiles.

**Architecture:** All changes go into `claude/settings.json` (permissions + hook config) and `claude/hooks/` (new scripts). The hooks dir is already symlinked so new scripts are picked up automatically. Settings are merged via `install.sh`.

**Tech Stack:** Bash scripts, jq for JSON parsing, standard Unix tools.

---

### Task 1: Add pre-bash-guard.sh hook

**Files:**
- Create: `claude/hooks/pre-bash-guard.sh`

**Step 1: Create the hook script**

```bash
#!/bin/bash
# PreToolUse hook: defense-in-depth guard against dangerous bash commands
# Matcher: Bash
# Catches dangerous patterns in chained commands that permission globs miss

INPUT=$(cat /dev/stdin)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Exit early if no command
[[ -z "$COMMAND" ]] && exit 0

# Dangerous patterns (checked against full command string to catch chaining)
PATTERNS=(
    'rm\s+-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*\s+/'    # rm -rf /
    'rm\s+-[a-zA-Z]*f[a-zA-Z]*r[a-zA-Z]*\s+/'    # rm -fr /
    'rm\s+-rf\s+~'                                  # rm -rf ~
    'rm\s+-rf\s+\$HOME'                             # rm -rf $HOME
    'rm\s+-rf\s+\.\s'                               # rm -rf . (with trailing space/end)
    'rm\s+-rf\s+\.$'                                # rm -rf . (at end of string)
    'chmod\s+777\s'                                  # chmod 777
    'chmod\s+-R\s+777'                               # chmod -R 777
    ':\(\)\s*\{\s*:\|:\s*&\s*\}\s*;'               # fork bomb :(){ :|:& };
    'mkfs\.'                                         # mkfs.ext4 etc
    '>\s*/dev/sd'                                    # write to disk device
    'dd\s+.*of=/dev/'                                # dd to device
)

for pattern in "${PATTERNS[@]}"; do
    if echo "$COMMAND" | grep -qP "$pattern"; then
        echo "Blocked by pre-bash-guard: command matches dangerous pattern '$pattern'" >&2
        exit 2
    fi
done

exit 0
```

**Step 2: Make executable**

Run: `chmod +x claude/hooks/pre-bash-guard.sh`

**Step 3: Test the hook locally**

Run: `echo '{"tool_input":{"command":"ls -la"}}' | ./claude/hooks/pre-bash-guard.sh; echo "exit: $?"`
Expected: `exit: 0`

Run: `echo '{"tool_input":{"command":"rm -rf /"}}' | ./claude/hooks/pre-bash-guard.sh 2>&1; echo "exit: $?"`
Expected: stderr message + `exit: 2`

Run: `echo '{"tool_input":{"command":"ls && rm -rf /"}}' | ./claude/hooks/pre-bash-guard.sh 2>&1; echo "exit: $?"`
Expected: stderr message + `exit: 2` (chained command caught)

**Step 4: Commit**

```bash
git add claude/hooks/pre-bash-guard.sh
git commit -m "feat: add pre-bash-guard hook for dangerous command detection"
```

---

### Task 2: Add post-edit-format.sh hook

**Files:**
- Create: `claude/hooks/post-edit-format.sh`

**Step 1: Create the hook script**

```bash
#!/bin/bash
# PostToolUse hook: auto-format files after Edit/Write
# Matcher: Edit|Write
# Detects language from extension, runs formatter if installed
# Always exits 0 — formatting failure must not block work

INPUT=$(cat /dev/stdin)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Exit early if no file path
[[ -z "$FILE_PATH" ]] && exit 0

# Exit if file doesn't exist (e.g., Write failed)
[[ ! -f "$FILE_PATH" ]] && exit 0

# Get file extension (lowercase)
EXT="${FILE_PATH##*.}"
EXT=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')

case "$EXT" in
    go)
        command -v gofmt &>/dev/null && gofmt -w "$FILE_PATH" 2>/dev/null
        ;;
    py)
        if command -v ruff &>/dev/null; then
            ruff format "$FILE_PATH" 2>/dev/null
        elif command -v black &>/dev/null; then
            black --quiet "$FILE_PATH" 2>/dev/null
        fi
        ;;
    rs)
        command -v rustfmt &>/dev/null && rustfmt "$FILE_PATH" 2>/dev/null
        ;;
    js|ts|jsx|tsx|json|md|yaml|yml)
        command -v prettier &>/dev/null && prettier --write "$FILE_PATH" 2>/dev/null
        ;;
    sh|bash)
        command -v shfmt &>/dev/null && shfmt -w "$FILE_PATH" 2>/dev/null
        ;;
esac

# Always succeed — formatting is best-effort
exit 0
```

**Step 2: Make executable**

Run: `chmod +x claude/hooks/post-edit-format.sh`

**Step 3: Test the hook locally**

Run: `echo '{"tool_input":{"file_path":"/tmp/nonexistent.go"}}' | ./claude/hooks/post-edit-format.sh; echo "exit: $?"`
Expected: `exit: 0` (file doesn't exist, exits early)

Run: `echo '{}' | ./claude/hooks/post-edit-format.sh; echo "exit: $?"`
Expected: `exit: 0` (no file_path, exits early)

**Step 4: Commit**

```bash
git add claude/hooks/post-edit-format.sh
git commit -m "feat: add post-edit-format hook for auto-formatting"
```

---

### Task 3: Add pre-commit-validate.sh hook

**Files:**
- Create: `claude/hooks/pre-commit-validate.sh`

**Step 1: Create the hook script**

```bash
#!/bin/bash
# PreToolUse hook: enforce commit quality gates
# Matcher: Bash
# Blocks --no-verify and --amend on main/master

INPUT=$(cat /dev/stdin)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Exit early if not a git commit command
echo "$COMMAND" | grep -q 'git commit' || exit 0

# Block --no-verify (matches CLAUDE.md hard rule)
if echo "$COMMAND" | grep -qP '\-\-no-verify'; then
    echo "Blocked by pre-commit-validate: --no-verify is not allowed. Fix the issue instead of bypassing hooks." >&2
    exit 2
fi

# Block --amend on main/master
if echo "$COMMAND" | grep -qP '\-\-amend'; then
    BRANCH=""
    if [[ -n "$CWD" ]]; then
        BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
    else
        BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    fi
    if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
        echo "Blocked by pre-commit-validate: --amend on $BRANCH is dangerous. Create a new commit instead." >&2
        exit 2
    fi
fi

exit 0
```

**Step 2: Make executable**

Run: `chmod +x claude/hooks/pre-commit-validate.sh`

**Step 3: Test the hook locally**

Run: `echo '{"tool_input":{"command":"git commit -m \"test\""},"cwd":"/tmp"}' | ./claude/hooks/pre-commit-validate.sh; echo "exit: $?"`
Expected: `exit: 0`

Run: `echo '{"tool_input":{"command":"git commit --no-verify -m \"test\""},"cwd":"/tmp"}' | ./claude/hooks/pre-commit-validate.sh 2>&1; echo "exit: $?"`
Expected: stderr message + `exit: 2`

Run: `echo '{"tool_input":{"command":"ls -la"},"cwd":"/tmp"}' | ./claude/hooks/pre-commit-validate.sh; echo "exit: $?"`
Expected: `exit: 0` (not a git commit, skipped)

**Step 4: Commit**

```bash
git add claude/hooks/pre-commit-validate.sh
git commit -m "feat: add pre-commit-validate hook for commit quality gates"
```

---

### Task 4: Add post-bash-audit.sh hook

**Files:**
- Create: `claude/hooks/post-bash-audit.sh`

**Step 1: Create the hook script**

```bash
#!/bin/bash
# PostToolUse hook: audit log for all bash commands
# Matcher: Bash
# Appends to ~/.claude/audit.log with rotation

INPUT=$(cat /dev/stdin)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Exit early if no command
[[ -z "$COMMAND" ]] && exit 0

LOG_FILE="$HOME/.claude/audit.log"
TIMESTAMP=$(date -Iseconds)

# Append log entry
echo "[$TIMESTAMP] CWD: $CWD | CMD: $COMMAND" >> "$LOG_FILE"

# Rotate: keep last 1000 lines
if [[ -f "$LOG_FILE" ]]; then
    LINE_COUNT=$(wc -l < "$LOG_FILE")
    if (( LINE_COUNT > 1000 )); then
        tail -n 1000 "$LOG_FILE" > "$LOG_FILE.tmp"
        mv "$LOG_FILE.tmp" "$LOG_FILE"
    fi
fi

exit 0
```

**Step 2: Make executable**

Run: `chmod +x claude/hooks/post-bash-audit.sh`

**Step 3: Test the hook locally**

Run: `echo '{"tool_input":{"command":"ls -la"},"cwd":"/tmp"}' | ./claude/hooks/post-bash-audit.sh; echo "exit: $?"`
Expected: `exit: 0`

Run: `tail -1 ~/.claude/audit.log`
Expected: line like `[2026-02-25T...] CWD: /tmp | CMD: ls -la`

**Step 4: Commit**

```bash
git add claude/hooks/post-bash-audit.sh
git commit -m "feat: add post-bash-audit hook for command logging"
```

---

### Task 5: Update settings.json with permissions and new hooks

**Files:**
- Modify: `claude/settings.json`

**Step 1: Replace settings.json with full config**

```json
{
  "permissions": {
    "allow": [
      "Bash(ls *)",
      "Bash(cat *)",
      "Bash(head *)",
      "Bash(tail *)",
      "Bash(wc *)",
      "Bash(file *)",
      "Bash(tree *)",
      "Bash(stat *)",
      "Bash(find *)",
      "Bash(which *)",
      "Bash(pwd)",
      "Bash(echo *)",
      "Bash(env)",
      "Bash(printenv *)",
      "Bash(whoami)",
      "Bash(id)",
      "Bash(uname *)",
      "Bash(date *)",
      "Bash(git log *)",
      "Bash(git status *)",
      "Bash(git diff *)",
      "Bash(git branch *)",
      "Bash(git show *)",
      "Bash(git remote *)",
      "Bash(git tag *)",
      "Bash(git rev-parse *)",
      "Bash(git ls-files *)",
      "Bash(gh *)"
    ],
    "ask": [
      "Bash(rm *)",
      "Bash(rmdir *)",
      "Bash(shred *)",
      "Bash(truncate *)",
      "Bash(sudo *)",
      "Bash(su *)",
      "Bash(chmod *)",
      "Bash(chown *)",
      "Bash(pkexec *)",
      "Bash(dd *)",
      "Bash(mkfs *)",
      "Bash(mv /*)",
      "Bash(git push --force *)",
      "Bash(git reset --hard *)",
      "Bash(git clean *)"
    ]
  },
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
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/pre-bash-guard.sh",
            "timeout": 5
          },
          {
            "type": "command",
            "command": "~/.claude/hooks/pre-commit-validate.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/post-edit-format.sh",
            "timeout": 10
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/post-bash-audit.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

**Step 2: Validate JSON**

Run: `jq . claude/settings.json`
Expected: Pretty-printed JSON, no errors

**Step 3: Commit**

```bash
git add claude/settings.json
git commit -m "feat: add permissions and hook config to settings template"
```

---

### Task 6: Update CLAUDE.md repository docs

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Update the Repository Structure section**

Replace the hooks section in the tree with:

```
├── hooks/
│   ├── session-start.sh       # Injects codebase context on new sessions
│   ├── compact-guard.sh       # Blocks auto-compaction, prompts user
│   ├── pre-bash-guard.sh      # Defense-in-depth: blocks dangerous command patterns
│   ├── pre-commit-validate.sh # Enforces commit quality gates (no --no-verify)
│   ├── post-edit-format.sh    # Auto-formats files by language after edits
│   └── post-bash-audit.sh     # Logs all bash commands to ~/.claude/audit.log
```

**Step 2: Update the Repository Purpose bullet**

Change the hooks bullet from:
```
- Hooks for session-start context injection and manual compaction control
```
To:
```
- Hooks for session-start context, compaction control, command guarding, auto-formatting, commit validation, and audit logging
```

**Step 3: Update the Key Files section**

Change the hooks description from:
```
- **`claude/hooks/`**: Shell hooks for Claude Code events. `session-start.sh` injects codebase context on new sessions. `compact-guard.sh` blocks auto-compaction so user can decide.
```
To:
```
- **`claude/hooks/`**: Shell hooks for Claude Code events. Includes session-start context injection, auto-compaction guard, dangerous command guard, auto-formatting by language, commit quality gate enforcement, and bash command audit logging.
```

**Step 4: Add note about permissions to settings.json description**

Change:
```
- **`claude/settings.json`**: Template with `statusLine` and `hooks` config. Merged (not symlinked) into `~/.claude/settings.json` to preserve existing keys like `enabledPlugins`.
```
To:
```
- **`claude/settings.json`**: Template with `permissions`, `statusLine`, and `hooks` config. Merged (not symlinked) into `~/.claude/settings.json` to preserve existing keys like `enabledPlugins`. Permissions auto-allow read-only commands and prompt for dangerous ones.
```

**Step 5: Update "Installed" list in install.sh echo section**

Change the hooks echo line from:
```
echo "  - hooks/ (session-start, compact-guard)"
```
To:
```
echo "  - hooks/ (session-start, compact-guard, bash-guard, edit-format, commit-validate, audit)"
```

And add:
```
echo "  - permissions (allow read-only, ask for dangerous commands)"
```

**Step 6: Commit**

```bash
git add CLAUDE.md install.sh
git commit -m "docs: update CLAUDE.md and install.sh for new hooks and permissions"
```

---

### Task 7: Run install.sh and verify

**Step 1: Run installer**

Run: `./install.sh`
Expected: Settings merged, hooks symlink already correct

**Step 2: Verify settings merged**

Run: `jq '.permissions' ~/.claude/settings.json`
Expected: Shows the allow/ask arrays

Run: `jq '.hooks.PreToolUse' ~/.claude/settings.json`
Expected: Shows pre-bash-guard and pre-commit-validate hooks

**Step 3: Verify hook scripts are accessible**

Run: `ls -la ~/.claude/hooks/`
Expected: All 6 hook scripts listed (symlink to claude/hooks/)

**Step 4: Run quick smoke tests on hooks**

Run: `echo '{"tool_input":{"command":"ls -la"}}' | ~/.claude/hooks/pre-bash-guard.sh; echo "exit: $?"`
Expected: `exit: 0`

Run: `echo '{"tool_input":{"command":"rm -rf /"}}' | ~/.claude/hooks/pre-bash-guard.sh 2>&1; echo "exit: $?"`
Expected: Block message + `exit: 2`

**Step 5: Commit (no changes expected — verification only)**

No commit needed unless fixes are required.
