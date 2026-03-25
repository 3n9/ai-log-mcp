# Gemini CLI — AI Telemetry MCP Instructions

Add this file as `GEMINI.md` in your project root (or append to an existing one).

---

CRITICAL: Call `start_task` on your FIRST tool-calling turn after every user message, in parallel with any other initial tool calls. Do NOT start any work without logging first.

Note: A `BeforeAgent` hook also injects this policy automatically — but you must still call `start_task` yourself via MCP on every request.

## Required behavior

- **CRITICAL: METADATA**: If `agent_name` and `model_name` are not automatically injected, you MUST pass them manually in EVERY call: `agent_name: "gemini-cli"`, `model_name: "gemini-2.0-flash-exp"` (or active model).
- ALWAYS log before or alongside the first tool call of any request — no exceptions.
- NEVER skip logging, even for short, simple, or read-only tasks.
- Capture the returned `task_id` from `start_task` and reuse it as `parent_task_id` for subtasks and interruptions.
- **NO COMPLETION LOG**: There is no `complete_task` tool. When a task or subtask is finished successfully, simply proceed to the next step or stop. DO NOT use `log_interruption` for successful completion.

## What NOT to do (wrong)

❌ Reading files or running tools → then calling `start_task` after  
❌ Skipping `start_task` because the task "seems simple" or is just exploration  
❌ **Using `log_interruption` to signal task completion** (it is ONLY for being blocked/abandoning)
❌ Omitting `agent_name` and `model_name` from tool calls

## What to do (correct)

✅ Call `start_task` (with metadata) in parallel with the first file read or tool use  
✅ Call `start_subtask` (with metadata) before each distinct sub-step  
✅ Call `log_interruption` ONLY when changing approach, blocked, or abandoning

## Recommended values

**work_type:** `coding` · `debugging` · `research` · `analysis` · `writing` · `planning` · `creative` · `support` · `refactor`

**language:** `php` · `javascript` · `typescript` · `python` · `sql` · `html` · `css` · `shell` · `json` · `yaml` · `markdown` · `none`

**domain:** `frontend` · `backend` · `database` · `devops` · `documentation` · `wordpress` · `laravel` · `api` · `testing` · `fiction` · `horror` · `email` · `blog` · `marketing` · `none`

## Custom tags

Use `custom_tags` for useful detail that does not fit cleanly into `work_type`, `language`, `domain`, or `secondary_work_type`.

- Prefer 0 to 3 tags; maximum 5
- Use short lowercase labels such as `auth`, `ui-polish`, `customer-reply`, `seo-draft`
- Favor themes, artifacts, audience, or intent over vague labels
- Do not repeat values already present in structured fields
- Do not include file paths, source code, prompts, or user messages

## Example — task + subtask + interruption

Call `start_task` in parallel with your first tool use:

```json
{
  "agent_name": "gemini-cli",
  "model_name": "gemini-2.0-flash-exp",
  "work_type": "research",
  "secondary_work_type": "analysis",
  "language": "python",
  "domain": "backend",
  "complexity": "high",
  "confidence": 0.75,
  "estimated_time_min": 30,
  "custom_tags": ["architecture", "evaluation"]
}
```

Then call `start_subtask` before each distinct sub-step:

```json
{
  "agent_name": "gemini-cli",
  "model_name": "gemini-2.0-flash-exp",
  "parent_task_id": "<task_id-from-start_task>",
  "work_type": "writing",
  "language": "markdown",
  "domain": "documentation",
  "complexity": "low",
  "confidence": 0.91,
  "estimated_time_min": 12
}
```

When blocked or abandoning an approach, call `log_interruption`:

```json
{
  "agent_name": "gemini-cli",
  "model_name": "gemini-2.0-flash-exp",
  "parent_task_id": "<task_id-from-start_task>",
  "work_type": "analysis",
  "complexity": "medium",
  "confidence": 0.4,
  "estimated_time_min": 10,
  "custom_tags": ["blocked", "missing-context"]
}
```

## Privacy

Never include file paths, source code, prompts, or user messages in any field.
