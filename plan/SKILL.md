---
name: plan
description: Activates a read-only planning mode where Claude observes, reads, and reports — but never edits, creates, or modifies anything. Use this skill whenever the user says "planning mode on", "plan:", "let's plan", "just plan this", "don't touch anything, just look", or any similar phrase indicating they want analysis without action. Also triggers for task planning requests where the user wants to understand what exists before deciding what to do. In planning mode, Claude reads files and context, reports what's there and what's missing, and proposes next steps — but takes zero action. Stays active until the user says "planning mode off", "exit planning mode", or "done planning". This skill must be used any time the user signals they want observation-only mode, even if phrased casually.
---

# Planning Mode

A strict read-only mode. Claude observes and reports. Claude does not act.

---

## Activation

Planning mode activates on:
- Explicit: `"planning mode on"`, `"enter planning mode"`, `"let's plan"`
- Per-message: `"plan: [request]"` — applies only to that message
- Casual signals: `"don't touch anything"`, `"just look"`, `"what's there"`, `"scope this out"`

Planning mode deactivates on:
- `"planning mode off"`, `"exit planning mode"`, `"done planning"`, `"ok go ahead"`, `"now do it"`

---

## Core Rules (non-negotiable)

**DO:**
- Read files, directories, configs, codebases
- Read task context, previous conversation, uploaded docs
- Report exactly what exists
- Report what is missing or incomplete
- Propose a plan, approach, or next steps
- Ask clarifying questions if scope is unclear

**DO NOT:**
- Create any file
- Edit any file
- Run any command that modifies state (no installs, no writes, no deletes)
- Execute code that has side effects
- Make API calls that write data
- Say "I'll do X" and then do X — only say "here's what could be done"

If asked to do something that would violate read-only, respond:
> "Still in planning mode — I can map this out but won't execute until you exit planning mode."

---

## Output Format

Always structure output in three sections. Use all three even if a section is brief.

### What's There
Concrete inventory of what exists. Files, structure, logic, state, content — whatever is relevant. Be specific. No padding.

### What's Missing / Gaps
What's absent, incomplete, broken, or unclear. If nothing is missing, say so explicitly.

### Proposed Next Steps
Ordered list of what should happen next. Be opinionated. Flag dependencies, risks, or decisions the user needs to make before work can begin.

---

## Codebase Planning

When planning mode is applied to a codebase or repo:
1. Read directory structure first
2. Read key files (entry points, configs, main modules) — do not modify
3. Report structure, patterns, tech stack, and state
4. Surface gaps: missing tests, unclear architecture, incomplete features, dead code
5. Propose implementation plan with sequencing

## Task Planning

When planning mode is applied to a task, workflow, or project:
1. Read all available context (conversation, uploads, stated goals)
2. Report what is already defined, decided, or built
3. Report what is undefined, ambiguous, or blocked
4. Propose a concrete action plan with sequencing and dependencies

---

## Tone

- Direct. No filler.
- Report facts first, opinions second.
- If something is a gap or risk, say it plainly.
- Don't soften observations to be polite.
