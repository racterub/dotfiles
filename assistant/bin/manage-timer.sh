#!/bin/bash
# Manage dynamic systemd user timers for Claude Assistant
# Usage:
#   manage-timer.sh create --name NAME --schedule SCHEDULE --prompt PROMPT
#   manage-timer.sh list
#   manage-timer.sh remove --name NAME
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "${SCRIPT_DIR}/config.env"

TIMER_DIR="${HOME}/.config/systemd/user"
TEMPLATE_DIR="${SCRIPT_DIR}/timers/templates"
PREFIX="claude-task-"

usage() {
    echo "Usage: manage-timer.sh {create|list|remove} [options]"
    echo ""
    echo "Commands:"
    echo "  create --name NAME --schedule SCHEDULE --prompt PROMPT"
    echo "  list"
    echo "  remove --name NAME"
    echo ""
    echo "Schedule format: systemd OnCalendar syntax"
    echo "  Daily at 8am:     *-*-* 08:00:00"
    echo "  Every 30 min:     *:00/30"
    echo "  Every 2 hours:    *:00/2:00"
    echo "  Weekdays at 9am:  Mon..Fri *-*-* 09:00:00"
    exit 1
}

create_timer() {
    local name="" schedule="" prompt=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --name) name="$2"; shift 2 ;;
            --schedule) schedule="$2"; shift 2 ;;
            --prompt) prompt="$2"; shift 2 ;;
            *) echo "Unknown option: $1"; usage ;;
        esac
    done

    if [ -z "$name" ] || [ -z "$schedule" ] || [ -z "$prompt" ]; then
        echo "ERROR: --name, --schedule, and --prompt are required"
        usage
    fi

    # Sanitize name
    local safe_name
    safe_name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
    local unit_name="${PREFIX}${safe_name}"

    mkdir -p "$TIMER_DIR"

    # Escape prompt for sed (handle |, &, /, \ in user input)
    local escaped_prompt
    escaped_prompt=$(printf '%s' "$prompt" | sed 's/[|&/\]/\\&/g')

    # Render service from template
    sed \
        -e "s|{{NAME}}|${name}|g" \
        -e "s|{{HOME}}|${HOME}|g" \
        -e "s|{{WORKSPACE}}|${WORKSPACE_DIR}|g" \
        -e "s|{{ASSISTANT_DIR}}|${ASSISTANT_DIR}|g" \
        -e "s|{{PROMPT}}|${escaped_prompt}|g" \
        "${TEMPLATE_DIR}/task.service.tmpl" > "${TIMER_DIR}/${unit_name}.service"

    # Render timer from template
    sed \
        -e "s|{{NAME}}|${name}|g" \
        -e "s|{{SCHEDULE}}|${schedule}|g" \
        "${TEMPLATE_DIR}/task.timer.tmpl" > "${TIMER_DIR}/${unit_name}.timer"

    # Enable and start
    systemctl --user daemon-reload
    systemctl --user enable "${unit_name}.timer"
    systemctl --user start "${unit_name}.timer"

    echo "Created and started timer: ${unit_name}"
    echo "Schedule: ${schedule}"
    echo "Prompt: ${prompt}"
    systemctl --user status "${unit_name}.timer" --no-pager || true
}

list_timers() {
    echo "Active Claude Assistant timers:"
    echo ""
    systemctl --user list-timers "${PREFIX}*" --no-pager 2>/dev/null || echo "(none)"
}

remove_timer() {
    local name=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --name) name="$2"; shift 2 ;;
            *) echo "Unknown option: $1"; usage ;;
        esac
    done

    if [ -z "$name" ]; then
        echo "ERROR: --name is required"
        usage
    fi

    local safe_name
    safe_name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
    local unit_name="${PREFIX}${safe_name}"

    systemctl --user stop "${unit_name}.timer" 2>/dev/null || true
    systemctl --user disable "${unit_name}.timer" 2>/dev/null || true
    rm -f "${TIMER_DIR}/${unit_name}.service" "${TIMER_DIR}/${unit_name}.timer"
    systemctl --user daemon-reload

    echo "Removed timer: ${unit_name}"
}

# --- Main ---
case "${1:-}" in
    create) shift; create_timer "$@" ;;
    list) list_timers ;;
    remove) shift; remove_timer "$@" ;;
    *) usage ;;
esac
