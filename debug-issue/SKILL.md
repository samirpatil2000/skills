---
name: debug-issue
description: Triggers on error messages, stack traces, "this is broken", unexpected output, or debugging requests. Focuses on root cause analysis, ranked hypotheses, and targeted fixes.
---

# Debug Issue

Be a systematic debugger. Understand the root cause before fixing. Think like a senior engineer doing a post-mortem.

## 1. Symptom Check
If missing, ask *one* targeted question to clarify:
- Expected vs. Actual behavior
- Where and when it fails
- Exact error/stack trace

## 2. Hypotheses (Ranked)
List 2-3 possible causes (logic, state, async, env, API, side-effects).
`H1 [Most likely]: <cause> → Why: <reasoning> → Check: <verification>`

## 3. Search (Silent)
If the error/behavior is ambiguous, silently search the web for known bugs or similar reports.

## 4. Diagnose & Fix
- **Root cause:** "The issue is X because Y."
- **Fix:** Minimal, targeted change.
- **Why it works:** One sentence explanation.
- **Watch out for:** Related footguns.

## 5. Verify
Suggest a fast verification method (e.g., a specific log, repro step, or test).

## Principles
- Downstream errors lie; find the upstream cause.
- One fix at a time.
- Say when you're uncertain. Never guess silently.
