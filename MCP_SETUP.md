# MCP Setup Guide

This guide explains how to connect `ai-log-mcp` to supported CLI agents and pair it with the MCP-first prompts in [`prompts-mcp/`](./prompts-mcp).

Validated against current docs and local CLI help on March 11, 2026.

## Quick Setup (one command)

```sh
curl -fsSL https://raw.githubusercontent.com/3n9/ai-log-mcp/main/scripts/install.sh | sh
```

This downloads and installs `ai-log`, `ai-log-report`, and `ai-log-mcp`, initialises the database, and registers the MCP server with every detected AI agent CLI. Agents whose CLI is not installed are skipped automatically.

**From a local clone:**

```sh
make install-mcp-servers
```

## Prerequisites

1. Build and install the binaries:

```sh
make install
```

This installs:

- `ai-log`
- `ai-log-report`
- `ai-log-mcp`

2. Initialize the telemetry database once:

```sh
ai-log init
```

3. Confirm `ai-log-mcp` is on your `PATH`:

```sh
command -v ai-log-mcp
```

4. Optional: set a default agent name in your shell profile.

Examples:

```sh
export AI_LOG_AGENT_NAME="codex-cli"
export AI_LOG_MODEL_NAME="gpt-5"
```

`AI_LOG_AGENT_NAME` is usually safe to set globally for a single CLI. `AI_LOG_MODEL_NAME` is optional and may go stale if you switch models often.

## Install the MCP prompts

If you want the global prompt files installed automatically, run:

```sh
make install-global-mcp
```

This installs the MCP-first prompt files, but it does not register the MCP server itself. You still need to configure each AI agent to launch `ai-log-mcp`.

If you prefer per-project setup, copy the relevant file from [`prompts-mcp/`](./prompts-mcp) into the agent's instruction file for that repository.

## Common MCP server command

All local integrations in this guide use the same stdio server command:

```sh
ai-log-mcp
```

The server exposes these tools:

- `start_task`
- `start_subtask`
- `log_interruption`

## Claude Code

Register the MCP server at user scope:

```sh
claude mcp add ai-log-telemetry --scope user --env AI_LOG_AGENT_NAME=claude-code -- ai-log-mcp
```

Verify:

```sh
claude mcp list
claude mcp get ai-log-telemetry
```

Prompt file:

- Per project: copy [`prompts-mcp/claude-code.md`](./prompts-mcp/claude-code.md) into `CLAUDE.md`
- Global: run `make install-global-mcp`

Notes:

- Claude Code uses `--` to separate Claude CLI flags from the MCP server command
- If you want the configuration shared with the repository, use `--scope project`

## Gemini CLI

Register the MCP server at user scope:

```sh
gemini mcp add -s user -e AI_LOG_AGENT_NAME=gemini-cli ai-log-telemetry ai-log-mcp
```

Verify:

```sh
gemini mcp list
gemini mcp get ai-log-telemetry
```

Prompt file:

- Per project: copy [`prompts-mcp/gemini.md`](./prompts-mcp/gemini.md) into `GEMINI.md`
- Global: run `make install-global-mcp`

Notes:

- Gemini also supports project scope via `-s project`
- Do not use `--trust` unless you intentionally want to suppress tool confirmation prompts

## OpenAI Codex CLI

Register the MCP server at user scope:

```sh
codex mcp add ai-log-telemetry --env AI_LOG_AGENT_NAME=codex-cli -- ai-log-mcp
```

Verify:

```sh
codex mcp list
codex mcp get ai-log-telemetry
```

Prompt file:

- Per project: copy [`prompts-mcp/codex.md`](./prompts-mcp/codex.md) into `AGENTS.md`
- Global: run `make install-global-mcp`

Notes:

- Codex stores MCP configuration in `~/.codex/config.toml`
- If your installed Codex version differs, check `codex mcp add --help`

## GitHub Copilot CLI

Copilot CLI currently documents MCP setup through the interactive `/mcp add` flow.

1. Start Copilot CLI:

```sh
copilot
```

2. Run:

```text
/mcp add
```

3. Fill the form with these values:

- Server Name: `ai-log-telemetry`
- Server Type: `STDIO` or `Local`
- Command: `ai-log-mcp`
- Environment variables: `AI_LOG_AGENT_NAME=copilot-cli`

4. Save the form with `Ctrl`+`S`

Copilot stores MCP server definitions in `~/.copilot/mcp-config.json`.

Prompt file:

- Per project: copy [`prompts-mcp/copilot.md`](./prompts-mcp/copilot.md) into `.github/copilot-instructions.md`
- Global: run `make install-global-mcp`

Notes:

- Copilot CLI can also load extra MCP config for one session with `--additional-mcp-config`
- If you rely on personal instructions, this repo currently keeps them at `~/.copilot/copilot-instructions.md`

## Recommended first test

After registering the MCP server and installing the prompt file for your agent:

1. Start the agent in a small test repository
2. Ask it to make a trivial change
3. Confirm it calls `start_task` before doing meaningful work
4. Check that a row was written:

```sh
ai-log-report summary
```

## Troubleshooting

If the agent cannot find the MCP server:

- Confirm `ai-log-mcp` is on `PATH`
- Restart the CLI after changing shell profile or config
- Run the agent's MCP list command and verify `ai-log-telemetry` exists

If telemetry writes fail:

- Run `ai-log init`
- Check `AI_LOG_DB` if you use a custom database location
- Run a direct smoke test:

```sh
ai-log emit '{"schema_version":1,"agent_name":"smoke-test","model_name":"manual","work_type":"analysis","complexity":"low","confidence":1,"estimated_time_min":1,"task_type":"task"}'
```

## References

- Claude Code MCP docs: https://docs.anthropic.com/en/docs/claude-code/mcp
- Gemini CLI MCP docs: https://geminicli.com/docs/tools/mcp-server
- GitHub Copilot CLI MCP docs: https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-mcp-servers
- OpenAI Codex MCP help: run `codex mcp --help` and `codex mcp add --help`
