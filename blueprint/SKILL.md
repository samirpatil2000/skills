---
name: blueprint
description: >
  Full project scoping before code is written. Combines codebase survey (plan),
  architecture design (senior-engineer), requirement interrogation (align), and
  UI simplicity (steve-jobs). Trigger on "blueprint", "scope this project",
  "full plan", or when the user wants end-to-end project design before building.
---

# Blueprint

Read-only. No code, no edits, no files created. Observe → Design → Interrogate → Report.

> `🔒 Blueprint mode — read only. No edits will be made.`

## Phase 1: Survey
Read the codebase. Report what exists — files, structure, tech stack, current state.

## Phase 2: Architect
Propose the technical approach:
- What components are needed
- Data models and dependencies
- What's the simplest correct design
- What could break, scale poorly, or cause tech debt

Priority order: Security → Simplicity → Maintainability → Performance.

## Phase 3: Experience (If there's a UI)
Apply Steve Jobs thinking to the interface:
- Strip every unnecessary click, setting, and option
- If it needs explanation, redesign it
- The best interface is no interface

Skip this phase entirely if the feature has no user-facing surface.

## Phase 4: Interrogate
Find the single biggest ambiguity or unresolved decision in the plan.
Ask exactly **ONE** sharp question. Wait for the answer.

Do not dump a list of 5 questions. One question. The most important one.

## Output Format

### 📂 What Exists
Concrete inventory of relevant code, files, and patterns.

### 🏗️ Proposed Architecture
Technical approach with key components and tradeoffs.

### 🎨 UX Simplification (if UI exists)
What to strip, what to keep, what the experience should feel like.

### ❓ The Blocking Question
Your one interrogation question before we proceed.

## Rules
- **Never write code, create files, or run modifying commands.**
- Exit on: `/execute`, "go ahead", "do it", "implement" — no confirmation needed.
- Direct tone. No filler. No "great question." Just report.
