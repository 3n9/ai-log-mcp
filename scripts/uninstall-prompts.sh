#!/usr/bin/env bash
set -e

GLOBAL_DIR="$HOME/.ai-telemetry"
PROMPTS_DEST="$GLOBAL_DIR/prompts-mcp"
BLOCK_NAME="AI TELEMETRY MCP SYSTEM (AUTO-GENERATED)"
BEGIN_MARKER="### BEGIN $BLOCK_NAME"
END_MARKER="### END $BLOCK_NAME"

echo "🗑️  Uninstalling AI Telemetry MCP Prompts..."

# 1. CLEAN UP INJECTED CONFIGURATIONS
# Function to remove the injected block between markers (inclusive)
safe_cleanup() {
    local target="$1"
    local name="$2"

    if [ -f "$target" ] && grep -q "$BEGIN_MARKER" "$target"; then
        echo "🔧 Removing AI Telemetry configuration from $name ($target)..."
        python3 - "$target" "$BEGIN_MARKER" "$END_MARKER" <<'PY'
import pathlib
import sys

target_path = pathlib.Path(sys.argv[1]).expanduser()
begin_marker = sys.argv[2]
end_marker = sys.argv[3]

if target_path.exists():
    content = target_path.read_text()
    start = content.find(begin_marker)
    end = content.find(end_marker, start if start != -1 else 0)
    if start != -1 and end != -1:
        end += len(end_marker)
        content = content[:start] + content[end:]
        content = content.strip("\n")
        if content:
            content += "\n"
        target_path.write_text(content)
PY
        echo "✅ $name configuration cleaned."
    fi
}

safe_cleanup "$HOME/.claude/CLAUDE.md" "Claude Code"
safe_cleanup "$HOME/.codex/AGENTS.md" "Codex"
safe_cleanup "$HOME/.copilot/copilot-instructions.md" "Copilot CLI"
safe_cleanup "$HOME/.gemini/GEMINI.md" "Gemini CLI"

# 2. Legacy installs for Copilot/Gemini were copied as whole files and cannot
# be safely separated from user-managed content. Leave them untouched.

# 3. SYNC GLOBAL DIRECTORY
if [ -d "$PROMPTS_DEST" ]; then
    rm -rf "$PROMPTS_DEST"
    echo "✅ Global MCP prompts directory removed: $PROMPTS_DEST"
fi

# 4. FINAL CLEANUP
# Remove global dir if empty
if [ -d "$GLOBAL_DIR" ] && [ -z "$(ls -A "$GLOBAL_DIR")" ]; then
    rmdir "$GLOBAL_DIR"
    echo "✅ Removed empty global directory: $GLOBAL_DIR"
fi

echo -e "\n✨ AI Telemetry MCP uninstallation complete!"
echo "💡 Remember to manually revert any agent-specific server configurations if needed."
