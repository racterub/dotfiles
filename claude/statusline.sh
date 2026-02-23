#!/bin/bash
# Claude Code statusline script
# Displays: Model | Context Usage | Cost | Lines Changed

# Read JSON from stdin
input=$(cat)

# Extract values using jq (fallback to defaults if missing)
if command -v jq &> /dev/null; then
    model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
    context_used=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
    cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
    lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
    lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
else
    # Fallback if jq not available
    echo "Claude Code"
    exit 0
fi

# Format context percentage (round to 1 decimal)
context_pct=$(printf "%.1f" "$context_used")

# Format cost
cost_fmt=$(printf "$%.4f" "$cost")

# ANSI colors
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
DIM='\033[2m'
RESET='\033[0m'

# Color context based on usage
if (( $(echo "$context_used > 80" | bc -l) )); then
    ctx_color=$RED
elif (( $(echo "$context_used > 50" | bc -l) )); then
    ctx_color=$YELLOW
else
    ctx_color=$GREEN
fi

# Build status line
echo -e "${CYAN}${model}${RESET} ${DIM}|${RESET} ${ctx_color}${context_pct}%${RESET} ctx ${DIM}|${RESET} ${cost_fmt} ${DIM}|${RESET} ${GREEN}+${lines_added}${RESET}/${RED}-${lines_removed}${RESET}"
