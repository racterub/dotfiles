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
    'chmod\s+777(\s|$)'                               # chmod 777
    'chmod\s+-R\s+777'                               # chmod -R 777
    ':\(\)\s*\{\s*:\|:\s*&\s*\}\s*;'               # fork bomb :(){ :|:& };
    'mkfs\.'                                         # mkfs.ext4 etc
    '>\s*/dev/(sd|nvme|vd|xvd)'                       # write to disk device
    'dd\s+.*of=/dev/'                                # dd to device
)

for pattern in "${PATTERNS[@]}"; do
    if echo "$COMMAND" | grep -qP "$pattern"; then
        echo "Blocked by pre-bash-guard: command matches dangerous pattern '$pattern'" >&2
        exit 2
    fi
done

exit 0
