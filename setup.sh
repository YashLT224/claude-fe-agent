#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════
# Claude FE Agent - Setup Script
# ═══════════════════════════════════════════════════════════════════════════════
# This script sets up the Claude FE Agent by creating symlinks from ~/.claude/
# to this repository. This allows you to version control your agent config
# while Claude Code uses it from the expected location.
# ═══════════════════════════════════════════════════════════════════════════════

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}           Claude FE Agent - Installation Script                    ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

# Check if Claude Code is installed
if ! command -v claude &> /dev/null; then
    echo -e "${YELLOW}Warning: Claude Code CLI not found. Install it first:${NC}"
    echo "  curl -fsSL https://claude.ai/install.sh | bash"
    echo ""
fi

# Create ~/.claude if it doesn't exist
if [ ! -d "$CLAUDE_DIR" ]; then
    echo -e "${YELLOW}Creating $CLAUDE_DIR directory...${NC}"
    mkdir -p "$CLAUDE_DIR"
fi

# Function to backup and create symlink
create_symlink() {
    local source="$1"
    local target="$2"
    local name="$3"

    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ -L "$target" ]; then
            # It's already a symlink
            current_target=$(readlink "$target")
            if [ "$current_target" = "$source" ]; then
                echo -e "  ${GREEN}✓${NC} $name (already linked)"
                return
            fi
        fi
        # Backup existing
        backup_name="${target}.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "  ${YELLOW}→${NC} Backing up existing $name to $(basename $backup_name)"
        mv "$target" "$backup_name"
    fi

    ln -s "$source" "$target"
    echo -e "  ${GREEN}✓${NC} $name"
}

echo -e "${GREEN}Setting up  inks...${NC}"
echo ""

# Symlink main config files
create_symlink "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md" "CLAUDE.md"
create_symlink "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json" "settings.json"
create_symlink "$SCRIPT_DIR/workflow-config.json" "$CLAUDE_DIR/workflow-config.json" "workflow-config.json"

# Symlink skills directory
create_symlink "$SCRIPT_DIR/skills" "$CLAUDE_DIR/skills" "skills/"

# Symlink agents directory
create_symlink "$SCRIPT_DIR/agents" "$CLAUDE_DIR/agents" "agents/"

# Symlink memory directory (for shared memory across machines if desired)
# Note: Memory contains cached project data, you might want to keep this local
if [ ! -d "$CLAUDE_DIR/memory" ]; then
    create_symlink "$SCRIPT_DIR/memory" "$CLAUDE_DIR/memory" "memory/"
else
    echo -e "  ${YELLOW}⊘${NC} memory/ (keeping local - contains machine-specific caches)"
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}                    Installation Complete!                          ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Your Claude FE Agent is now set up. The following are linked:"
echo ""
echo -e "  ${BLUE}~/.claude/CLAUDE.md${NC}         → Personal context"
echo -e "  ${BLUE}~/.claude/settings.json${NC}     → Permissions & plugins"
echo -e "  ${BLUE}~/.claude/workflow-config.json${NC} → Workflow config"
echo -e "  ${BLUE}~/.claude/skills/${NC}           → All skills"
echo -e "  ${BLUE}~/.claude/agents/${NC}           → All agents"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "1. Update your Jira Cloud ID in workflow-config.json:"
echo "   - Run: claude"
echo "   - Run: /mcp"
echo "   - Use getAccessibleAtlassianResources to find your cloudId"
echo ""
echo "2. Authenticate MCP servers:"
echo "   - Run: claude"
echo "   - Run: /mcp"
echo "   - Follow OAuth for Atlassian, Figma, GitHub"
echo ""
echo "3. Remember your first project:"
echo "   - cd your-project"
echo "   - claude"
echo "   - /remember"
echo ""
echo -e "${GREEN}Enjoy your AI-powered development workflow!${NC}"
