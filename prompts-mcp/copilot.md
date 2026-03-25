# GitHub Copilot CLI — AI Telemetry MCP Instructions

Add this content to `.github/copilot-instructions.md` in your repository.

---

CRITICAL: Call `start_task` on your FIRST tool-calling turn after every user message, in parallel with `report_intent` and any other initial tool calls. Do NOT start any work without logging first.

## What NOT to do (wrong)

❌ Reading files or running tools → then calling `start_task` after  
❌ Skipping `start_task` because the task "seems simple" or is just exploration  
❌ Calling `report_intent` without also calling `start_task`

## What to do (correct)

✅ Call `start_task` in parallel with `report_intent` and the first file read or tool use  
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
- If Copilot does not inject agent/model metadata through MCP, pass `agent_name: "copilot-cli"` and the active `model_name`

## Recommended values

**work_type:** `coding` · `debugging` · `research` · `analysis` · `writing` · `planning` · `creative` · `support` · `refactor`

**language:** `php` · `javascript` · `typescript` · `python` · `sql` · `html` · `css` · `shell` · `json` · `yaml` · `markdown` · `none`

**domain:** `frontend` · `backend` · `database` · `devops` · `documentation` · `wordpress` · `laravel` · `api` · `testing` · `fiction` · `horror` · `email` · `blog` · `marketing` · `none`

## Custom tags

Use `custom_tags` for concise task details that are not already covered by `work_type`, `language`, `domain`, or `secondary_work_type`.

- Prefer 0 to 3 tags; maximum 5
- Use short lowercase labels such as `auth`, `ui-polish`, `customer-reply`, `seo-draft`
- Favor themes, artifacts, audience, or intent over generic filler
- Do not repeat existing structured fields
- Do not include file paths, source code, prompts, or user messages

## Example — task + subtask

Call `start_task` in parallel with your first tool use:

```json
{
  "agent_name": "copilot-cli",
  "model_name": "claude-3-5-sonnet",
  "work_type": "coding",
  "language": "typescript",
  "domain": "frontend",
  "complexity": "low",
  "confidence": 0.9,
  "estimated_time_min": 10,
  "custom_tags": ["component", "ui"]
}
```

Then call `start_subtask` before each distinct sub-step:

```json
{
  "agent_name": "copilot-cli",
  "model_name": "claude-3-5-sonnet",
  "parent_task_id": "<task_id-from-start_task>",
  "work_type": "debugging",
  "language": "typescript",
  "domain": "frontend",
  "complexity": "low",
  "confidence": 0.85,
  "estimated_time_min": 5
}
```

## Example — interruption

Call `log_interruption` with arguments like:

```json
{
  "agent_name": "copilot-cli",
  "model_name": "claude-3-5-sonnet",
  "parent_task_id": "<task_id-from-start_task>",
  "work_type": "analysis",
  "complexity": "medium",
  "confidence": 0.45,
  "estimated_time_min": 12,
  "custom_tags": ["blocked", "handoff-needed"]
}
```

## Privacy

Never include file paths, source code, prompts, or user messages in any field.
