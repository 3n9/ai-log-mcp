# AI Agent Telemetry — MCP Prompts

This directory contains MCP-first prompt variants for CLI agents.

These prompts assume the `ai-log-mcp` server is already configured for the agent and available as an MCP tool provider over stdio.

Human setup guide: see [`../MCP_SETUP.md`](../MCP_SETUP.md)

## Recommended MCP server command

```sh
ai-log-mcp
```

Optional environment variables for default metadata:

```sh
AI_LOG_AGENT_NAME=<agent-name>
AI_LOG_MODEL_NAME=<model-name>
```

If the client cannot provide agent/model metadata automatically, the prompts tell the agent to pass `agent_name` and `model_name` tool arguments explicitly.

## Per-Project Usage

> **Note:** If you used the one-line install from the root README, prompts were already injected into your global agent config files. The table below is for per-project setup or if you are applying prompts manually.

| File | Agent | How to apply |
|---|---|---|
| `claude-code.md` | Claude Code | Add to `CLAUDE.md` in your project root |
| `copilot.md` | GitHub Copilot CLI | Add to `.github/copilot-instructions.md` |
| `gemini.md` | Gemini CLI | Add to `GEMINI.md` in your project root |
| `codex.md` | OpenAI Codex CLI | Add to `AGENTS.md` in your project root |

## Available MCP tools

- `start_task`
- `start_subtask`
- `log_interruption`

## Vocabulary

**work_type:** `coding` · `debugging` · `research` · `analysis` · `writing` · `planning` · `creative` · `support` · `refactor`

**language:** `php` · `javascript` · `typescript` · `python` · `sql` · `html` · `css` · `shell` · `json` · `yaml` · `markdown` · `none`

**domain:** `frontend` · `backend` · `database` · `devops` · `documentation` · `wordpress` · `laravel` · `api` · `testing` · `fiction` · `horror` · `email` · `blog` · `marketing` · `none`

Full field reference: see the [technical spec](https://github.com/3n9/ai-agent-telemetry/blob/main/specs/05_technical_spec.md)
