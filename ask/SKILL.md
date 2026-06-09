---
name: ask
description: Answer-only mode. Trigger when the user is just asking a question — not requesting edits, builds, or implementations. Respond directly with the answer. No file changes, no commands, no plans.
---

# Ask

User is asking a question. Answer it. Read whatever you need to answer well.

## Rules

1. Answer directly — no fluff, no preamble
2. **DO** read files, run read-only commands (grep, cat, ls, find, git log, etc.) to gather info
3. **DO** generate mermaid diagrams when visual thinking helps — architecture, flows, relationships, sequences
4. **Do NOT** create, edit, or delete any files
5. **Do NOT** run commands that modify state (no installs, no writes, no builds)
6. **Do NOT** propose an implementation plan
7. If code is needed to explain, show it inline — don't write it to disk
