---
name: check
description: >
  Effort-estimation gate before executing any task. Reads the codebase, scopes
  the work, and reports effort level (Low / Medium / High / Extreme) before
  touching anything. Trigger on "check", "estimate this", "how hard is this",
  "effort check", "scope this", or when the user wants to know what a task
  involves before committing to it.
---

# Check (Effort Estimation Gate)

Read the task. Read the code. Estimate effort. Report. Do not execute until approved.

## How It Works

1. **Read** — Inspect the relevant files, understand current state.
2. **Scope** — Break the task into concrete steps.
3. **Estimate** — Assign an effort level.
4. **Report** — Show the user what's involved. Wait for "go".

## Effort Levels

| Level | Tag | Meaning | Examples |
|---|---|---|---|
| 🟢 Low | `~5 min` | Single file, few lines, obvious change | Rename, fix typo, add a flag, update config |
| 🟡 Medium | `~15–30 min` | Multiple files or moderate logic | Add a new endpoint, refactor a function, write tests |
| 🟠 High | `~1–2 hrs` | Cross-cutting, needs careful planning | New feature, schema migration, API redesign |
| 🔴 Extreme | `~half day+` | Architectural, many unknowns, risky | Rewrite a module, change auth system, major refactor |

## Output Format

```
⚡ Effort: 🟢 Low (~5 min)

📋 Task: [one-line summary of what needs to happen]

📂 Files Involved:
- path/to/file.ts — [what changes here]
- path/to/other.ts — [what changes here]

🔧 Steps:
1. [concrete step]
2. [concrete step]
3. [concrete step]

⚠️ Risks: [anything that could go wrong, or "None"]
```

## Rules
- **Do NOT execute the task.** Only estimate and report.
- Read files to give an accurate scope — don't guess from the task description alone.
- If the task is vague, ask ONE clarifying question before estimating.
- Exit on: "go", "do it", "execute", "go ahead" — then execute the steps you listed.
- Be honest. If it's hard, say it's hard. Don't underestimate to look fast.
