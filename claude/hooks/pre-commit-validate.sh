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
