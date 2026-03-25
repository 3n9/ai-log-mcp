# Claude Code — AI Telemetry MCP Instructions

Add this file as `CLAUDE.md` in your project root (or append to an existing one).

---

CRITICAL: Call `start_task` on your FIRST tool-calling turn after every user message, in parallel with `TodoWrite` and any other initial tool calls. Do NOT start any work without logging first.

## What NOT to do (wrong)

❌ Reading files, running bash, or calling `TodoWrite` → then calling `start_task` after  
❌ Skipping `start_task` because the task "seems simple" or is just exploration  
❌ Using `TodoWrite` to plan work without first calling `start_task`

## What to do (correct)

✅ Call `start_task` in parallel with `TodoWrite` and the first file read or tool use  
✅ Call `start_subtask` before each distinct sub-step within a larger task  
✅ Call `log_interruption` whenever you change approach, get blocked, or abandon a plan

## Available tools

- `start_task`
- `start_subtask`
- `log_interruption`

## Required behavior

- ALWAYS log before or alongside the first tool call of any request — no exceptions
- NEVER skip logging, even for short, simple, or read-only tasks
- Capture the returned `task_id` from `start_task` and reuse it as `parent_task_id` for follow-up subtasks or interruptions
- Prefer standard vocabulary for `work_type`, `language`, and `domain`
- If agent/model metadata is not injected by the client, pass `agent_name: "claude-code"` and the active `model_name`

## Recommended work_type values

`coding` · `debugging` · `research` · `analysis` · `writing` · `planning` · `creative` · `support` · `refactor`

## Recommended language values

`php` · `javascript` · `typescript` · `python` · `sql` · `html` · `css` · `shell` · `json` · `yaml` · `markdown` · `none`

## Recommended domain values

`frontend` · `backend` · `database` · `devops` · `documentation` · `wordpress` · `laravel` · `api` · `testing` · `fiction` · `horror` · `email` · `blog` · `marketing` · `none`

## Custom tags

Use `custom_tags` for specific context not already expressed by `work_type`, `language`, `domain`, or `secondary_work_type`.

- Prefer 0 to 3 tags; maximum 5
- Use short lowercase labels such as `auth`, `ui-polish`, `customer-reply`, `seo-draft`
- Tag the task's theme, artifact, audience, or intent
- Do not duplicate existing structured fields
- Do not include file paths, source code, prompts, or user messages

## Example — task + subtask

Call `start_task` in parallel with your first tool use:

```json
{
  "agent_name": "claude-code",
  "model_name": "claude-3-5-sonnet",
  "work_type": "coding",
  "secondary_work_type": "debugging",
  "language": "typescript",
  "domain": "backend",
  "complexity": "medium",
  "confidence": 0.8,
  "estimated_time_min": 25,
  "custom_tags": ["auth", "jwt"]
}
```

Then call `start_subtask` before each distinct sub-step:

```json
{
  "agent_name": "claude-code",
  "model_name": "claude-3-5-sonnet",
  "parent_task_id": "<task_id-from-start_task>",
  "work_type": "debugging",
  "language": "typescript",
  "domain": "backend",
  "complexity": "low",
  "confidence": 0.9,
  "estimated_time_min": 8,
  "custom_tags": ["test-failure"]
}
```

## Privacy

Never include file paths, source code, prompts, or user messages in any field.
