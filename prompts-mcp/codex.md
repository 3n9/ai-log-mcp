# OpenAI Codex CLI — AI Telemetry MCP Instructions

Add this file as `AGENTS.md` in your project root (or append to an existing one).

---

CRITICAL: Call `start_task` on your FIRST tool-calling turn after every user message, in parallel with any shell commands or file operations. Do NOT start any work without logging first.

## What NOT to do (wrong)

❌ Running shell commands or writing files → then calling `start_task` after  
❌ Skipping `start_task` because the task "seems simple" or is just exploration  
❌ Beginning execution of any step without a corresponding telemetry log

## What to do (correct)

✅ Call `start_task` in parallel with the first shell command or file operation  
✅ Call `start_subtask` before each distinct sub-step within a larger task  
✅ Call `log_interruption` whenever you change approach, get blocked, or abandon a plan

## Available tools

- `start_task`
- `start_subtask`
- `log_interruption`

## Required behavior

- ALWAYS log before or alongside the first tool call of any request — no exceptions
- NEVER skip logging, even for short, simple, or read-only tasks
- Capture the returned `task_id` from `start_task` and reuse it as `parent_task_id` for subtasks and interruptions
- Prefer standard vocabulary for `work_type`, `language`, and `domain`
- If Codex does not inject agent/model metadata through MCP, pass `agent_name: "codex-cli"` and the active `model_name`

## Model notes for Codex

- Use the exact active model identifier when Codex exposes it
- If the active model is not visible through MCP metadata, use a stable fallback such as `codex` rather than omitting `model_name`
- Do not infer or invent a more specific model version than the runtime provides

## Recommended values

**work_type:** `coding` · `debugging` · `research` · `analysis` · `writing` · `planning` · `creative` · `support` · `refactor`

**language:** `php` · `javascript` · `typescript` · `python` · `sql` · `html` · `css` · `shell` · `json` · `yaml` · `markdown` · `none`

**domain:** `frontend` · `backend` · `database` · `devops` · `documentation` · `wordpress` · `laravel` · `api` · `testing` · `fiction` · `horror` · `email` · `blog` · `marketing` · `none`

## Custom tags

Use `custom_tags` for task-specific detail not already represented by `work_type`, `language`, `domain`, or `secondary_work_type`.

- Prefer 0 to 3 tags; maximum 5
- Use short lowercase labels such as `auth`, `ui-polish`, `customer-reply`, `seo-draft`
- Favor themes, artifacts, audience, or intent over generic words
- Do not duplicate existing structured fields
- Do not include file paths, source code, prompts, or user messages

## Example — task + subtask + interruption

Call `start_task` in parallel with your first tool use:

```json
{
  "work_type": "coding",
  "language": "javascript",
  "domain": "frontend",
  "complexity": "medium",
  "confidence": 0.82,
  "estimated_time_min": 18,
  "custom_tags": ["ui-polish"]
}
```

Then call `start_subtask` before each distinct sub-step:

```json
{
  "parent_task_id": "<task_id-from-start_task>",
  "work_type": "debugging",
  "language": "javascript",
  "domain": "frontend",
  "complexity": "low",
  "confidence": 0.9,
  "estimated_time_min": 5
}
```

When blocked or abandoning an approach, call `log_interruption`:

```json
{
  "parent_task_id": "<task_id-from-start_task>",
  "work_type": "analysis",
  "complexity": "medium",
  "confidence": 0.35,
  "estimated_time_min": 7,
  "custom_tags": ["dependency-failure"]
}
```

## Privacy

Never include file paths, source code, prompts, or user messages in any field.
