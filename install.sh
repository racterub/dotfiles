#!/bin/bash
set -euo pipefail

# Claude Code dotfiles installer
# Symlinks claude/ contents to ~/.claude/

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$HOME/.claude-backup-$(date +%Y%m%d-%H%M%S)"

echo "Claude Code dotfiles installer"
echo "=============================="
echo ""

# Check if claude directory exists in dotfiles
if [[ ! -d "$SCRIPT_DIR/claude" ]]; then
    echo "Error: claude/ directory not found in $SCRIPT_DIR"
    exit 1
fi

# Create .claude directory if it doesn't exist
mkdir -p "$CLAUDE_DIR"

# Function to backup and symlink
backup_and_link() {
    local src="$1"
    local dest="$2"
    local name="$(basename "$dest")"

    if [[ -e "$dest" || -L "$dest" ]]; then
        if [[ -L "$dest" ]]; then
            local current_target="$(readlink "$dest")"
            if [[ "$current_target" == "$src" ]]; then
                echo "  [skip] $name already linked correctly"
                return
            fi
        fi
        mkdir -p "$BACKUP_DIR"
        echo "  [backup] $name -> $BACKUP_DIR/"
        mv "$dest" "$BACKUP_DIR/"
    fi

    ln -s "$src" "$dest"
    echo "  [link] $name -> $src"
}

# Handle CLAUDE.md
echo ""
echo "Setting up CLAUDE.md..."
backup_and_link "$SCRIPT_DIR/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

# Handle skills directory
echo ""
echo "Setting up skills/..."
backup_and_link "$SCRIPT_DIR/claude/skills" "$CLAUDE_DIR/skills"

# Handle .mcp.json (MCP servers config)
echo ""
echo "Setting up MCP servers..."
MCP_FILE="$HOME/.mcp.json"

if [[ -f "$MCP_FILE" ]]; then
    # Check if jq is available
    if command -v jq &> /dev/null; then
        # Check if context7 is already configured
        if jq -e '.mcpServers.context7' "$MCP_FILE" &> /dev/null; then
            echo "  [skip] context7 MCP already configured"
        else
            echo "  [merge] Adding context7 MCP to existing .mcp.json"
            mkdir -p "$BACKUP_DIR"
            cp "$MCP_FILE" "$BACKUP_DIR/.mcp.json"

            # Merge the mcpServers
            jq -s '{"mcpServers": (.[0].mcpServers // {} | . * .[1].mcpServers)}' \
                "$MCP_FILE" \
                "$SCRIPT_DIR/claude/.mcp.json" \
                > "$MCP_FILE.tmp"
            mv "$MCP_FILE.tmp" "$MCP_FILE"
            echo "  [done] context7 MCP added"
        fi
    else
        echo "  [warn] jq not installed, cannot merge .mcp.json"
        echo "         Please manually add context7 MCP to ~/.mcp.json:"
        echo ""
        cat "$SCRIPT_DIR/claude/.mcp.json"
        echo ""
    fi
else
    cp "$SCRIPT_DIR/claude/.mcp.json" "$MCP_FILE"
    echo "  [copy] .mcp.json created at ~/.mcp.json"
fi

echo ""
echo "=============================="
echo "Installation complete!"
echo ""
echo "Installed:"
echo "  - CLAUDE.md (workflow + guardrails)"
echo "  - skills/ (qa, sre, infra, backend, frontend, dba, data, security, integration-check)"
echo "  - context7 MCP server (~/.mcp.json)"
echo ""
if [[ -d "$BACKUP_DIR" ]]; then
    echo "Backups saved to: $BACKUP_DIR"
    echo ""
fi
echo "Restart Claude Code to apply changes."
