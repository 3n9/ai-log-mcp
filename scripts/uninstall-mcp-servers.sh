#!/usr/bin/env bash
set -e

MCP_SERVER_NAME="ai-log-telemetry"

REMOVED=()
SKIPPED=()
FAILED=()

echo "🗑️  Unregistering AI Telemetry MCP Server from all supported agents..."

# ── CLAUDE CODE ────────────────────────────────────────────────────────────────
echo ""
if command -v claude &>/dev/null; then
    echo "🤖 Removing from Claude Code..."
    if (
        set -e

        if claude mcp list 2>/dev/null | grep -q "$MCP_SERVER_NAME"; then
            claude mcp remove "$MCP_SERVER_NAME" --scope user
            echo "  MCP server removed"
        else
            echo "  Server not registered, skipping"
        fi

        # Remove tools from permissions.allow in ~/.claude/settings.json
        CLAUDE_SETTINGS="$HOME/.claude/settings.json"
        if [ -f "$CLAUDE_SETTINGS" ]; then
            python3 - "$CLAUDE_SETTINGS" <<'PY'
import json, sys, pathlib

path = pathlib.Path(sys.argv[1]).expanduser()
data = json.loads(path.read_text()) if path.exists() else {}

tools = {
    "mcp__ai-log-telemetry__start_task",
    "mcp__ai-log-telemetry__start_subtask",
    "mcp__ai-log-telemetry__log_interruption",
}

allow = data.get("permissions", {}).get("allow", [])
before = len(allow)
allow[:] = [t for t in allow if t not in tools]
removed = before - len(allow)

path.write_text(json.dumps(data, indent=2) + "\n")
if removed:
    print(f"  Removed {removed} tool(s) from permissions.allow")
else:
    print("  No matching tools in permissions.allow")
PY
        fi
    ); then
        echo "✅ Claude Code: unregistered"
        REMOVED+=("Claude Code")
    else
        echo "❌ Claude Code: removal failed"
        echo "   Manual removal: claude mcp remove ai-log-telemetry --scope user"
        FAILED+=("Claude Code")
    fi
else
    echo "⚠️  Skipping Claude Code (claude not found in PATH)"
    SKIPPED+=("Claude Code")
fi

# ── GEMINI CLI ─────────────────────────────────────────────────────────────────
echo ""
if command -v gemini &>/dev/null; then
    echo "🤖 Removing from Gemini CLI..."
    if (
        set -e

        if gemini mcp list 2>/dev/null | grep -q "$MCP_SERVER_NAME"; then
            gemini mcp remove "$MCP_SERVER_NAME" -s user
            echo "  MCP server removed"
        else
            echo "  Server not registered, skipping"
        fi
    ); then
        echo "✅ Gemini CLI: unregistered"
        REMOVED+=("Gemini CLI")
    else
        echo "❌ Gemini CLI: removal failed"
        echo "   Manual removal: gemini mcp remove ai-log-telemetry -s user"
        FAILED+=("Gemini CLI")
    fi
else
    echo "⚠️  Skipping Gemini CLI (gemini not found in PATH)"
    SKIPPED+=("Gemini CLI")
fi

# ── OPENAI CODEX CLI ───────────────────────────────────────────────────────────
echo ""
if command -v codex &>/dev/null; then
    echo "🤖 Removing from OpenAI Codex CLI..."
    if (
        set -e

        if codex mcp list 2>/dev/null | grep -q "$MCP_SERVER_NAME"; then
            codex mcp remove "$MCP_SERVER_NAME" 2>/dev/null || true
            echo "  MCP server removed"
        else
            echo "  Server not registered, skipping"
        fi

        # Remove entry from ~/.codex/settings.json if present
        CODEX_CONFIG_JSON="$HOME/.codex/settings.json"
        if [ -f "$CODEX_CONFIG_JSON" ]; then
            python3 - "$CODEX_CONFIG_JSON" <<'PY'
import json, sys, pathlib

path = pathlib.Path(sys.argv[1]).expanduser()
data = json.loads(path.read_text()) if path.exists() else {}

servers = data.get("mcpServers", {})
if "ai-log-telemetry" in servers:
    del servers["ai-log-telemetry"]
    path.write_text(json.dumps(data, indent=2) + "\n")
    print("  Removed ai-log-telemetry from settings.json")
else:
    print("  No entry in settings.json")
PY
        fi
    ); then
        echo "✅ Codex CLI: unregistered"
        REMOVED+=("Codex CLI")
    else
        echo "❌ Codex CLI: removal failed"
        echo "   Manual removal: codex mcp remove ai-log-telemetry"
        FAILED+=("Codex CLI")
    fi
else
    echo "⚠️  Skipping OpenAI Codex CLI (codex not found in PATH)"
    SKIPPED+=("Codex CLI")
fi

# ── GITHUB COPILOT CLI ─────────────────────────────────────────────────────────
echo ""
echo "🤖 Removing from GitHub Copilot CLI..."
if (
    set -e

    COPILOT_MCP="$HOME/.copilot/mcp-config.json"
    if [ -f "$COPILOT_MCP" ]; then
        python3 - "$COPILOT_MCP" <<'PY'
import json, sys, pathlib

path = pathlib.Path(sys.argv[1]).expanduser()
data = json.loads(path.read_text())

servers = data.get("mcpServers", {})
if "ai-log-telemetry" in servers:
    del servers["ai-log-telemetry"]
    path.write_text(json.dumps(data, indent=2) + "\n")
    print("  Removed ai-log-telemetry from mcp-config.json")
else:
    print("  No entry in mcp-config.json")
PY
    else
        echo "  $HOME/.copilot/mcp-config.json not found, nothing to remove"
    fi
); then
    echo "✅ GitHub Copilot CLI: done"
    REMOVED+=("GitHub Copilot CLI")
else
    echo "❌ GitHub Copilot CLI: removal failed"
    echo "   Manual removal: delete the \"ai-log-telemetry\" key from ~/.copilot/mcp-config.json"
    FAILED+=("GitHub Copilot CLI")
fi

# ── SUMMARY ───────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════"
echo "✨ MCP server unregistration complete!"
echo ""

if [ ${#REMOVED[@]} -gt 0 ]; then
    echo "✅ Processed:"
    for agent in "${REMOVED[@]}"; do
        echo "   • $agent"
    done
fi

if [ ${#SKIPPED[@]} -gt 0 ]; then
    echo ""
    echo "⚠️  Skipped (CLI not found):"
    for agent in "${SKIPPED[@]}"; do
        echo "   • $agent"
    done
fi

if [ ${#FAILED[@]} -gt 0 ]; then
    echo ""
    echo "❌ Failed (see messages above for manual removal):"
    for agent in "${FAILED[@]}"; do
        echo "   • $agent"
    done
fi

echo "═══════════════════════════════════════════════════"

