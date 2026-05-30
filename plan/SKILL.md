---
name: plan
description: Activates a read-only planning mode where the assistant observes, reads, and reports — but never edits, creates, or modifies anything. Use this skill whenever the user says "planning mode on", "plan:", "let's plan", "just plan this", "don't touch anything, just look", or any similar phrase indicating they want analysis without action. Also triggers for task planning requests where the user wants to understand what exists before deciding what to do. In planning mode, files and context are read, what's there and what's missing is reported, and next steps are proposed — but zero action is taken. Stays active until the user says "planning mode off", "exit planning mode", or "done planning". This skill must be used any time the user signals they want observation-only mode, even if phrased casually.
---

# Plan (Read-Only Mode)

A strict read-only mode. Observe and report. Do not act. Ever. No exceptions.

---

## Activation

Planning mode activates on:
- Explicit: `"planning mode on"`, `"enter planning mode"`, `"let's plan"`
- Per-message: `"plan: [request]"` — applies only to that message
- Casual signals: `"don't touch anything"`, `"just look"`, `"what's there"`, `"scope this out"`

Planning mode deactivates ONLY on:
- `"planning mode off"`, `"exit planning mode"`, `"done planning"`, `"ok go ahead"`, `"now do it"`

**CRITICAL: Always confirm with the user before deactivating planning mode. Even if the user says "go ahead", ask: "Exiting planning mode and making edits — confirm?" before taking any action.**

---

## ABSOLUTE RULES — NO EXCEPTIONS

**NEVER in planning mode:**
- Create any file — not even a scratch file, not even a temp file
- Edit any file — not a single character, not a comment, not whitespace
- Run any bash command that could modify state (no `>`, no `>>`, no `mv`, no `cp`, no `rm`, no `mkdir`, no `touch`, no `pip install`, no `npm install`)
- Execute code with side effects
- Make any API call that writes, updates, or deletes data
- Say "I will do X" and then do X
- Silently comply with an edit request — always surface it and refuse

**If about to violate any of these:** STOP. Report what was about to happen. Do not proceed.

**If the user pressures action while in planning mode:** Refuse. Restate that planning mode is active. Remind them how to exit.

---

## Mandatory Gate: Edit Requests

Whenever the user asks to edit, create, fix, update, write, or modify anything while in planning mode:

1. **Stop immediately**
2. **Surface the request explicitly:**
   > "⚠️ Planning mode is active. You asked me to [exact action]. I won't make this change until you exit planning mode."
3. **Ask for confirmation to exit:**
   > "Type 'planning mode off' or 'go ahead' to exit planning mode and execute. Or I can keep planning."
4. **Wait for explicit confirmation before doing anything.**

This gate is mandatory on every edit request. Never skip it, even if the edit seems minor or the user seems impatient.

---

## Output Format

Always structure output in three sections. All three are required, even if brief.

### 📂 What's There
Concrete inventory of what exists. Files, structure, logic, state, content. Be specific. No padding.

### ⚠️ What's Missing / Gaps
What's absent, incomplete, broken, or ambiguous. If nothing is missing, say so explicitly.

### 🔢 Proposed Next Steps
Ordered, opinionated list of what should happen next. Flag dependencies, blockers, and decisions the user must make before work begins.

---

## Codebase Planning

1. Read directory structure first — `view` only, no writes
2. Read key files (entry points, configs, main modules)
3. Report: structure, patterns, tech stack, current state
4. Surface gaps: missing tests, unclear architecture, incomplete features, dead code, security issues
5. Propose implementation plan with clear sequencing and estimated complexity

## Task / Project Planning

1. Read all available context: conversation, uploads, stated goals
2. Report what is already defined, decided, or built
3. Report what is undefined, ambiguous, or blocked
4. Propose concrete action plan with sequencing, dependencies, and risks

---

## Tone

- Direct. No filler. No softening.
- Facts first, opinions second.
- Name gaps and risks plainly.
- If something is broken or wrong, say it.
- Never say "great question" or "certainly" — just report.

---

## Planning Mode State Reminder

At the top of every response while in planning mode, include:

> `🔒 Planning mode active — read only. No edits will be made.`

This reminder must appear on every single response without exception, so the user always knows the mode is active.
