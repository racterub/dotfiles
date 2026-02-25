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
