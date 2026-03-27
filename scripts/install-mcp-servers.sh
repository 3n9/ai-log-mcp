#!/usr/bin/env bash
set -e

MCP_SERVER_NAME="ai-log-telemetry"
MCP_SERVER_CMD="ai-log-mcp"

CONFIGURED=()
SKIPPED=()
FAILED=()

echo "🚀 Installing AI Telemetry MCP Server for all supported agents..."

# ── CLAUDE CODE ────────────────────────────────────────────────────────────────
echo ""
if command -v claude &>/dev/null; then
    echo "🤖 Configuring Claude Code..."
    if (
        set -e

        # Re-running 'claude mcp add' with the same name replaces the existing entry
        claude mcp add "$MCP_SERVER_NAME" --scope user --env AI_LOG_AGENT_NAME=claude-code -- "$MCP_SERVER_CMD"
        echo "  MCP server registered"

        # Patch ~/.claude/settings.json to add three tools to permissions.allow
        CLAUDE_SETTINGS="$HOME/.claude/settings.json"
        mkdir -p "$(dirname "$CLAUDE_SETTINGS")"
        [ ! -f "$CLAUDE_SETTINGS" ] && echo '{}' > "$CLAUDE_SETTINGS"

        python3 - "$CLAUDE_SETTINGS" <<'PY'
import json, sys, pathlib

path = pathlib.Path(sys.argv[1]).expanduser()
data = json.loads(path.read_text()) if path.exists() else {}

tools = [
    "mcp__ai-log-telemetry__start_task",
    "mcp__ai-log-telemetry__start_subtask",
    "mcp__ai-log-telemetry__log_interruption",
]

allow = data.setdefault("permissions", {}).setdefault("allow", [])
added = [t for t in tools if t not in allow]
allow.extend(added)

path.write_text(json.dumps(data, indent=2) + "\n")
if added:
    print(f"  Added {len(added)} tool(s) to permissions.allow")
else:
    print("  permissions.allow already up to date")
PY
    ); then
        echo "✅ Claude Code: registered + auto-accept configured"
        CONFIGURED+=("Claude Code")
    else
        echo "❌ Claude Code: configuration failed"
        echo "   Manual setup: see https://docs.anthropic.com/en/docs/claude-code/mcp"
        echo "   Run: claude mcp add ai-log-telemetry --scope user --env AI_LOG_AGENT_NAME=claude-code -- ai-log-mcp"
        FAILED+=("Claude Code")
    fi
else
    echo "⚠️  Skipping Claude Code (claude not found in PATH)"
    SKIPPED+=("Claude Code")
fi

# ── GEMINI CLI ─────────────────────────────────────────────────────────────────
echo ""
if command -v gemini &>/dev/null; then
    echo "🤖 Configuring Gemini CLI..."
    if (
        set -e

        # Skip registration if already present
        if gemini mcp list 2>/dev/null | grep -q "$MCP_SERVER_NAME"; then
            echo "  Server already registered, skipping"
        else
            # Use --env (long form) to avoid conflict with the top-level -e/--extensions flag.
            # Try --trust for auto-accept; fall back silently if the flag is unknown.
            if gemini mcp add -s user --trust --env AI_LOG_AGENT_NAME=gemini-cli \
                   "$MCP_SERVER_NAME" "$MCP_SERVER_CMD" 2>/dev/null; then
                echo "  MCP server registered with --trust (auto-accept enabled)"
            else
                gemini mcp add -s user --env AI_LOG_AGENT_NAME=gemini-cli \
                    "$MCP_SERVER_NAME" "$MCP_SERVER_CMD"
                echo "  MCP server registered"
                echo "  💡 Note: --trust flag not supported by this Gemini version."
                echo "     Tool confirmation prompts will appear; check 'gemini mcp add --help' for trust options."
            fi
        fi
    ); then
        echo "✅ Gemini CLI: registered"
        CONFIGURED+=("Gemini CLI")
    else
        echo "❌ Gemini CLI: configuration failed"
        echo "   Manual setup: gemini mcp add -s user --env AI_LOG_AGENT_NAME=gemini-cli ai-log-telemetry ai-log-mcp"
        FAILED+=("Gemini CLI")
    fi
else
    echo "⚠️  Skipping Gemini CLI (gemini not found in PATH)"
    SKIPPED+=("Gemini CLI")
fi

# ── OPENAI CODEX CLI ───────────────────────────────────────────────────────────
echo ""
if command -v codex &>/dev/null; then
    echo "🤖 Configuring OpenAI Codex CLI..."
    if (
        set -e

        # Skip registration if already present
        if codex mcp list 2>/dev/null | grep -q "$MCP_SERVER_NAME"; then
            echo "  Server already registered, skipping"
        else
            codex mcp add "$MCP_SERVER_NAME" --env AI_LOG_AGENT_NAME=codex-cli -- "$MCP_SERVER_CMD" || true
            echo "  MCP server registered"
        fi

        # Patch auto-trust in whichever config file Codex uses
        CODEX_CONFIG_TOML="$HOME/.codex/config.toml"
        CODEX_CONFIG_JSON="$HOME/.codex/settings.json"

        if [ -f "$CODEX_CONFIG_JSON" ]; then
            python3 - "$CODEX_CONFIG_JSON" <<'PY'
import json, sys, pathlib

path = pathlib.Path(sys.argv[1]).expanduser()
data = json.loads(path.read_text()) if path.exists() else {}

servers = data.setdefault("mcpServers", {})
entry = servers.setdefault("ai-log-telemetry", {})
entry["type"] = "stdio"
entry["command"] = "ai-log-mcp"
entry.setdefault("env", {})["AI_LOG_AGENT_NAME"] = "codex-cli"
allow = entry.setdefault("alwaysAllow", [])
for t in ["start_task", "start_subtask", "log_interruption"]:
    if t not in allow:
        allow.append(t)

path.write_text(json.dumps(data, indent=2) + "\n")
print("  settings.json patched with auto-trust")
PY
        elif [ -f "$CODEX_CONFIG_TOML" ]; then
            echo "  💡 Note: Codex uses $CODEX_CONFIG_TOML — manual trust configuration may be needed."
        else
            echo "  💡 Note: No Codex config file found. MCP server registered via CLI;"
            echo "     manual trust configuration may be needed."
        fi
    ); then
        echo "✅ Codex CLI: registered"
        CONFIGURED+=("Codex CLI")
    else
        echo "❌ Codex CLI: configuration failed"
        echo "   Manual setup: codex mcp add ai-log-telemetry --env AI_LOG_AGENT_NAME=codex-cli -- ai-log-mcp"
        FAILED+=("Codex CLI")
    fi
else
    echo "⚠️  Skipping OpenAI Codex CLI (codex not found in PATH)"
    SKIPPED+=("Codex CLI")
fi

# ── GITHUB COPILOT CLI ─────────────────────────────────────────────────────────
# Copilot CLI has no non-interactive 'mcp add' command; patch config file directly.
echo ""
echo "🤖 Configuring GitHub Copilot CLI..."
if (
    set -e

    COPILOT_MCP="$HOME/.copilot/mcp-config.json"
    mkdir -p "$(dirname "$COPILOT_MCP")"
    [ ! -f "$COPILOT_MCP" ] && echo '{"mcpServers": {}}' > "$COPILOT_MCP"

    python3 - "$COPILOT_MCP" <<'PY'
import json, sys, pathlib

path = pathlib.Path(sys.argv[1]).expanduser()
data = json.loads(path.read_text())

servers = data.setdefault("mcpServers", {})
key = "ai-log-telemetry"

if key not in servers:
    servers[key] = {
        "type": "stdio",
        "command": "ai-log-mcp",
        "env": {"AI_LOG_AGENT_NAME": "copilot-cli"},
        "alwaysAllow": ["start_task", "start_subtask", "log_interruption"],
    }
    print("  Added ai-log-telemetry server entry")
else:
    entry = servers[key]
    entry.setdefault("env", {})["AI_LOG_AGENT_NAME"] = "copilot-cli"
    allow = entry.setdefault("alwaysAllow", [])
    added = [t for t in ["start_task", "start_subtask", "log_interruption"] if t not in allow]
    allow.extend(added)
    if added:
        print(f"  Updated existing entry: added {len(added)} tool(s) to alwaysAllow")
    else:
        print("  Existing entry already up to date")

path.write_text(json.dumps(data, indent=2) + "\n")
PY
); then
    echo "✅ GitHub Copilot CLI: configured in $HOME/.copilot/mcp-config.json"
    CONFIGURED+=("GitHub Copilot CLI")
else
    echo "❌ GitHub Copilot CLI: configuration failed"
    echo "   Manual setup: add the following to ~/.copilot/mcp-config.json under \"mcpServers\":"
    echo '   "ai-log-telemetry": {"type":"stdio","command":"ai-log-mcp","env":{"AI_LOG_AGENT_NAME":"copilot-cli"}}'
    FAILED+=("GitHub Copilot CLI")
fi

# ── SUMMARY ───────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════"
echo "✨ MCP server installation complete!"
echo ""

if [ ${#CONFIGURED[@]} -gt 0 ]; then
    echo "✅ Configured:"
    for agent in "${CONFIGURED[@]}"; do
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
    echo "❌ Failed (see messages above for manual setup):"
    for agent in "${FAILED[@]}"; do
        echo "   • $agent"
    done
fi

echo "═══════════════════════════════════════════════════"

