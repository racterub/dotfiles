#!/bin/bash
# Check if a bash command pattern is in the settings.json allowlist
# Usage: check-permission.sh "docker *"
# Exit 0 if allowed, 1 if not, 2 if denied
set -euo pipefail

PATTERN="$1"
SETTINGS="${HOME}/.claude/settings.json"

if [ ! -f "$SETTINGS" ]; then
    echo "ERROR: settings.json not found at $SETTINGS" >&2
    exit 1
fi

# Check deny list first
DENIED=$(jq -r '.permissions.deny[]' "$SETTINGS" 2>/dev/null | while read -r rule; do
    # Strip "Bash(" prefix and ")" suffix
    rule_pattern="${rule#Bash(}"
    rule_pattern="${rule_pattern%)}"
    # Use bash pattern matching
    if [[ "Bash($PATTERN)" == $rule ]]; then
        echo "denied"
        break
    fi
done)

if [ "$DENIED" = "denied" ]; then
    echo "DENIED: Bash($PATTERN) matches deny list"
    exit 2
fi

# Check allow list
ALLOWED=$(jq -r '.permissions.allow[]' "$SETTINGS" 2>/dev/null | while read -r rule; do
    if [[ "Bash($PATTERN)" == $rule ]]; then
        echo "allowed"
        break
    fi
done)

if [ "$ALLOWED" = "allowed" ]; then
    echo "ALLOWED: Bash($PATTERN) matches allow list"
    exit 0
fi

echo "NOT FOUND: Bash($PATTERN) not in allow or deny list"
exit 1
