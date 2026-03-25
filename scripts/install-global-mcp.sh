#!/usr/bin/env bash
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GLOBAL_DIR="$HOME/.ai-telemetry"
PROMPTS_DEST="$GLOBAL_DIR/prompts-mcp"
BLOCK_NAME="AI TELEMETRY MCP SYSTEM (AUTO-GENERATED)"
BEGIN_MARKER="### BEGIN $BLOCK_NAME"
END_MARKER="### END $BLOCK_NAME"

echo "🚀 Installing AI Telemetry MCP Prompts Globally..."

mkdir -p "$PROMPTS_DEST"
cp "$PROJECT_ROOT/prompts-mcp/"*.md "$PROMPTS_DEST/"
echo "✅ MCP prompts synced to $PROMPTS_DEST"

safe_inject() {
    local target="$1"
    local source="$2"
    local name="$3"

    mkdir -p "$(dirname "$target")"
    echo "🔧 Syncing $name instructions in $target..."
    python3 - "$target" "$source" "$BEGIN_MARKER" "$END_MARKER" <<'PY'
import pathlib
import sys

target_path = pathlib.Path(sys.argv[1]).expanduser()
source_path = pathlib.Path(sys.argv[2]).expanduser()
begin_marker = sys.argv[3]
end_marker = sys.argv[4]

existing = target_path.read_text() if target_path.exists() else ""
source = source_path.read_text().rstrip("\n")
block = f"{begin_marker}\n{source}\n{end_marker}"

start = existing.find(begin_marker)
end = existing.find(end_marker)
if start != -1 and end != -1 and end >= start:
    end += len(end_marker)
    updated = existing[:start].rstrip("\n") + "\n\n" + block + existing[end:]
else:
    if existing and not existing.endswith("\n"):
        existing += "\n"
    separator = "\n" if existing.strip() else ""
    updated = existing + separator + block + "\n"

target_path.write_text(updated)
PY
    echo "✅ $name instructions synced."
}

safe_inject "$HOME/.claude/CLAUDE.md" "$PROMPTS_DEST/claude-code.md" "Claude Code"
safe_inject "$HOME/.codex/AGENTS.md" "$PROMPTS_DEST/codex.md" "Codex"
safe_inject "$HOME/.copilot/copilot-instructions.md" "$PROMPTS_DEST/copilot.md" "Copilot CLI"
safe_inject "$HOME/.gemini/GEMINI.md" "$PROMPTS_DEST/gemini.md" "Gemini CLI"

echo -e "\n✨ MCP prompt installation complete!"
echo "💡 Next: configure your CLI agent to launch the MCP server command:"
echo "   ai-log-mcp"
echo "💡 Optional defaults:"
echo "   export AI_LOG_AGENT_NAME=\"<agent-name>\""
echo "   export AI_LOG_MODEL_NAME=\"<model-name>\""
