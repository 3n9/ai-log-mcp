#!/usr/bin/env sh
# One-stop uninstall: removes ai-log, ai-log-report, and ai-log-mcp binaries,
# unregisters the MCP server from all detected AI agent CLIs, and removes
# injected MCP prompt blocks from global agent config files.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/3n9/ai-log-mcp/main/scripts/uninstall.sh | sh
#
# Environment variables:
#   INSTALL_DIR    — directory where binaries were installed (default: ~/.local/bin)
#
# Note: The telemetry database is NOT removed. To delete it manually:
#   rm -f ~/.local/share/ai-agent-telemetry/telemetry.db
#   (or wherever $AI_LOG_DB points)

set -e

MCP_REPO="3n9/ai-log-mcp"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"

# ── Remove binaries ──────────────────────────────────────────────────────────

echo "🗑️  Removing binaries from $INSTALL_DIR..."

for bin in ai-log ai-log-report ai-log-mcp; do
    if [ -f "$INSTALL_DIR/$bin" ]; then
        rm -f "$INSTALL_DIR/$bin"
        echo "  Removed $bin"
    else
        echo "  $bin not found in $INSTALL_DIR, skipping"
    fi
done

echo "✅ Binaries removed"

# ── Unregister MCP server from agent CLIs ───────────────────────────────────

echo ""
echo "🔧 Unregistering MCP server from agent CLIs..."

_SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd || echo "")"
UNREGISTER_SCRIPT="$_SCRIPT_DIR/uninstall-mcp-servers.sh"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

if [ -f "$UNREGISTER_SCRIPT" ]; then
    bash "$UNREGISTER_SCRIPT"
else
    curl -fsSL \
        "https://raw.githubusercontent.com/$MCP_REPO/main/scripts/uninstall-mcp-servers.sh" \
        -o "$TMP_DIR/uninstall-mcp-servers.sh"
    bash "$TMP_DIR/uninstall-mcp-servers.sh"
fi

# ── Remove injected prompt blocks ────────────────────────────────────────────

echo ""
echo "📝 Removing MCP prompt blocks from agent config files..."

PROMPTS_SCRIPT="$_SCRIPT_DIR/uninstall-prompts.sh"

if [ -f "$PROMPTS_SCRIPT" ]; then
    bash "$PROMPTS_SCRIPT"
else
    curl -fsSL \
        "https://raw.githubusercontent.com/$MCP_REPO/main/scripts/uninstall-prompts.sh" \
        -o "$TMP_DIR/uninstall-prompts.sh"
    bash "$TMP_DIR/uninstall-prompts.sh"
fi

# ── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo "✨ Uninstall complete!"
echo ""
echo "💡 The telemetry database was NOT removed (it contains your data)."
echo "   To delete it manually, remove the file pointed to by \$AI_LOG_DB"
echo "   (default: \$XDG_DATA_HOME/ai-agent-telemetry/telemetry.db)"
