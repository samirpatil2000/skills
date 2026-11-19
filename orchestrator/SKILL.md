---
name: orchestrator
description: >
  Orchestrate a complex, multi-step task by planning it, delegating each subtask
  to the cheapest model tier that can do it reliably, verifying every result, and
  integrating the final output. Use this whenever a task splits into several
  subtasks, spans many files, mixes research with implementation, or the user
  says "orchestrate", "delegate", "use subagents", "fan out", "route by model",
  or asks to save cost by using smaller models. Do not use for single-step tasks
  or quick questions.
---

# Orchestrator

You are the orchestrator: the model this session is running on. You plan,
delegate, verify, and integrate. Do not do work yourself that a cheaper
subagent can do reliably. Skip delegation entirely when a subtask is faster to
do than to brief.

## 1. Routing

Pick the lowest tier that will do the subtask well.

| Tier | Use for | Claude Code | Antigravity | OpenCode Zen |
|---|---|---|---|---|
| 1 Fast | Search, file reads, formatting, renames, boilerplate, log and diff summaries | `haiku` | `flash_lite` | `opencode/deepseek-v4.1-flash` |
| 2 Workhorse | Implementation, multi-file edits, bug fixes, refactors, tests, docs | `sonnet` | `flash` | `opencode/kimi-k3`, `opencode/claude-sonnet-5-5` |
| 3 Deep | Architecture, subtle or concurrency bugs, security, costly trade-offs, final review | `opus` | `pro` | `opencode/gemini-4-argon`, `opencode/qwen3.8-max` |

**Fable policy.** Never route a subagent to Fable (`fable`,
`opencode/claude-fable-5-2`) on your own, at any tier or as a fallback. Use it
only when the user explicitly asks. If the user started this session on Fable,
you still orchestrate as normal and delegate downward.

Model lists change often. If an ID is rejected, check what is live
(`opencode models`, `/model` in Claude Code) instead of guessing.

## 2. Rules

1. **Plan first.** Before any work, output a dispatch table: subtask, tier and
   model, one-line reason, and what it depends on.
2. **Default down, escalate once.** Start at the lowest feasible tier. Move up
   one tier only after a failure, or up front when a mistake would be costly
   or hard to reverse.
3. **Brief from zero.** A subagent cannot see this conversation. It can read
   the workspace only if it runs in it, so name exact paths. Every brief uses
   the template in section 3.
4. **Fan out.** Run subtasks that do not depend on each other in parallel.
5. **Verify everything.** Run the tests, read the diff, check the claim. If the
   result is wrong, retry once with a brief that names the exact flaw. If it
   fails again, escalate one tier or do it yourself.
6. **Own the result.** Integrate the pieces, check cross-file consistency, and
   end with a short summary: each subtask, which model did it, and how it was
   verified.

## 3. Brief template

```text
GOAL: <one line>
CONTEXT: <exact file paths, relevant snippets, current error or state>
CONSTRAINTS: <what must not change, patterns to follow, dependencies to avoid>
OUTPUT: <exact format: diff, function, JSON, short report>
DONE WHEN: <measurable check: tests pass, exit code 0, cases covered>
```

## 4. How to dispatch

### Claude Code

Prefer the built-in subagent tool and set its model per call. Use the CLI when
you need a separate process:

```bash
# Tier 1: read-only search
timeout 300 claude -p "$(cat brief.txt)" --model haiku --effort low < /dev/null

# Tier 2: implementation (needs permission to edit in print mode)
timeout 900 claude -p "$(cat brief.txt)" --model sonnet \
  --permission-mode acceptEdits < /dev/null

# Tier 3: deep review
timeout 1200 claude -p "$(cat brief.txt)" --model opus --effort high < /dev/null
```

### Antigravity

`invoke_subagent` takes `TypeName`, `Role`, `Prompt`, and an optional `Model`
that must be one of `inherit`, `flash_lite`, `flash`, `pro`. It does not accept
concrete model IDs.

```python
invoke_subagent(TypeName="research", Role="File Surveyor",
                Model="flash_lite", Prompt="<brief>")
invoke_subagent(TypeName="self", Role="Feature Implementer",
                Model="flash", Prompt="<brief>")
invoke_subagent(TypeName="self", Role="Architect Reviewer",
                Model="pro", Prompt="<brief>")
```

### OpenCode

```bash
timeout 900 opencode run "$(cat brief.txt)" -m opencode/kimi-k3 < /dev/null
```

## 5. Gotchas

- **Nothing may hang.** Every CLI subagent call gets a `timeout`, closed stdin
  (`< /dev/null`), and a non-interactive mode (`claude -p`, `opencode run`).
- **Logs.** For long calls, save and watch output with `2>&1 | tee run.log`.
  This does not make output arrive sooner; the subagent decides when it
  flushes. If you need live progress, use the tool's streaming output mode.
- **Print-mode permissions.** A `claude -p` subagent cannot edit files or run
  commands unless you grant it (`--permission-mode` or `--allowedTools`).
  Grant the minimum the subtask needs.
- **Friction.** If a subagent times out, invents imports, or fails twice, log
  it to `PAPERCUTS.md` with the `log-papercuts` skill.
