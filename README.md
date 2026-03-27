# ai-log-mcp

MCP server that exposes [AI Agent Telemetry](https://github.com/3n9/ai-agent-telemetry) as MCP tools — the preferred way to instrument AI coding agents.

Agents call three tools directly, with no shell commands or JSON formatting required:

| Tool | Purpose |
|---|---|
| `start_task` | Log a new top-level task |
| `start_subtask` | Log a sub-step within a task |
| `log_interruption` | Record when an approach is abandoned or blocked |

## Install (one command)

```sh
curl -fsSL https://raw.githubusercontent.com/3n9/ai-log-mcp/main/scripts/install.sh | sh
```

This installs `ai-log`, `ai-log-report`, and `ai-log-mcp` to `~/.local/bin`, initialises the database, registers the MCP server with every detected agent CLI (Claude Code, Gemini CLI, OpenAI Codex, GitHub Copilot CLI), and injects the MCP prompts into each agent's global config file.

Override install directory: `INSTALL_DIR=/usr/local/bin sh`

## Uninstall

```sh
curl -fsSL https://raw.githubusercontent.com/3n9/ai-log-mcp/main/scripts/uninstall.sh | sh
```

This removes the binaries, unregisters the MCP server from all detected agent CLIs, and removes the injected prompt blocks. The telemetry database is left intact.

## What gets installed

| Binary | Source | Purpose |
|---|---|---|
| `ai-log` | [ai-agent-telemetry](https://github.com/3n9/ai-agent-telemetry) | Storage backend |
| `ai-log-report` | [ai-agent-telemetry](https://github.com/3n9/ai-agent-telemetry) | Query, chart, export |
| `ai-log-mcp` | this repo | MCP server for agents |

## Reporting

```sh
ai-log-report summary                 # overall counts
ai-log-report summary --by work_type  # breakdown by dimension
ai-log-report chart bar               # terminal bar chart
ai-log-report dashboard               # HTML dashboard (last 30 days)
ai-log-report export csv              # export to stdout
```

## MCP prompts

Copy the appropriate prompt into your agent's config file:

| Agent | File | Config location |
|---|---|---|
| Claude Code | `prompts-mcp/claude-code.md` | `~/.claude/CLAUDE.md` |
| GitHub Copilot CLI | `prompts-mcp/copilot.md` | `~/.copilot/copilot-instructions.md` |
| Gemini CLI | `prompts-mcp/gemini.md` | `~/.gemini/GEMINI.md` |
| OpenAI Codex CLI | `prompts-mcp/codex.md` | `~/.codex/AGENTS.md` |

Or install all prompts globally:

```sh
curl -fsSL https://raw.githubusercontent.com/3n9/ai-log-mcp/main/scripts/install-prompts.sh | sh
```

## Full setup guide

See [MCP_SETUP.md](./MCP_SETUP.md) for manual configuration, per-agent details, and troubleshooting.

## Privacy

Only task metadata is stored. No file paths, source code, prompts, or user messages are ever recorded.

## Payload reference

Full field reference: see the [technical spec](https://github.com/3n9/ai-agent-telemetry/blob/main/specs/05_technical_spec.md)

---

## Dashboard

![AI Agent Telemetry Dashboard](https://raw.githubusercontent.com/3n9/ai-agent-telemetry/main/docs/screenshots/dashboard.png)
