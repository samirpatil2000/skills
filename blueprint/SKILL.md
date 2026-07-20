---
name: blueprint
description: >
  Full project scoping before code is written. Combines codebase survey (plan),
  architecture design (senior-engineer), requirement interrogation (align), and
  UI simplicity (steve-jobs). Trigger on "blueprint", "scope this project",
  "full plan", "design this before building", or when the user describes a
  non-trivial feature/project and wants end-to-end design before implementation.
  Do NOT trigger for small single-file edits, bug fixes, or pure questions.
---

# Blueprint

Read-only scoping mode. Observe → Design → Interrogate → Report. No implementation until released.

Open every blueprint response with:

> `🔒 Blueprint mode — read only. No edits will be made.`

## Phase 1: Survey
Read the codebase before proposing anything. Scale the survey to the task — a feature touching 3 files doesn't need a full-repo audit.

Report what exists: relevant files, structure, tech stack, conventions, and current state. Note constraints the design must respect (existing patterns, frameworks, versions).

**Greenfield?** If there's no codebase, skip the inventory. Instead, pin down the ground truth: target platform, language/framework preference, and deployment context. If unknown, that becomes the Phase 4 question.

## Phase 2: Architect
Propose the technical approach:
- Components needed and how they connect
- Data models and dependencies
- The simplest design that is correct — then stop simplifying
- What could break, scale poorly, or cause tech debt

For the one or two decisions that matter most, name the rejected alternative and why in one line each. Don't pad with fake options.

Priority order: Security → Simplicity → Maintainability → Performance.

## Phase 3: Experience (only if there's a UI)
Apply Steve Jobs thinking to the interface:
- Strip every unnecessary click, setting, and option
- If it needs explanation, redesign it
- The best interface is no interface

Skip this phase entirely — heading included — if the feature has no user-facing surface.

## Phase 4: Interrogate
Find the single biggest ambiguity or unresolved decision — the one whose answer would most change the architecture. Ask exactly **ONE** sharp question, with 2–3 concrete options if that helps the user answer fast. Wait.

Do not dump a list of 5 questions. One question. The most important one.

**After the answer:** fold it into the blueprint and restate only the sections that changed. If the answer exposes a new blocker, ask the next single question. Hard cap: 3 rounds — after that, state your assumptions explicitly and present the final blueprint.

## Output Format

### 📂 What Exists
Concrete inventory of relevant code, files, and patterns. (Greenfield: constraints and ground truth instead.)

### 🏗️ Proposed Architecture
Technical approach with key components, tradeoffs, and rejected alternatives.

### 🎨 UX Simplification (if UI exists)
What to strip, what to keep, what the experience should feel like.

### ❓ The Blocking Question
Your one interrogation question before we proceed.

## Rules
- **Read-only means:** no Write/Edit, no file creation, no mutating shell commands (git commits, installs, migrations). Reading, searching, and listing are always allowed.
- Exit on: `/execute`, "go ahead", "do it", "implement" — no confirmation needed. On exit, implement the agreed blueprint directly; do not re-plan.
- If the user changes requirements mid-blueprint, revise the affected sections — don't restart from Phase 1.
- Direct tone. No filler. No "great question." Just report.
