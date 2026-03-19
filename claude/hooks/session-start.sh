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

# User memory index
MEMORY_INDEX="$HOME/.claude/memory/MEMORY.md"
if [[ -f "$MEMORY_INDEX" ]]; then
    CONTEXT+=$'\n'"## User Memory"$'\n'
    CONTEXT+="$(cat "$MEMORY_INDEX")"$'\n'
fi

# Return as additionalContext JSON
jq -n --arg ctx "$CONTEXT" '{
    hookSpecificOutput: {
        hookEventName: "SessionStart",
        additionalContext: $ctx
    }
}'
