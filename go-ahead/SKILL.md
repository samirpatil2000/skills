---
name: go-ahead
description: Activates an execution mode where the assistant immediately proceeds to implement the proposed changes. Use this skill when the user says "go ahead", "go head", "do it", "implement", or similar phrases. In this mode, focus on direct action, creating/modifying files, and executing commands to get the job done without planning or asking for extra confirmation.
---

# Go Ahead (Execution Mode)

Transition from planning to action. Implement the changes directly.

---

## Activation

Activates on:
- `"go ahead"`, `"go head"`, `"do it"`, `"implement"`, `"make the changes"`, `"start implementing"`
- Any clear signal from the user approving a plan and requesting the actual implementation.

---

## Core Guidelines

1. **Direct Action**: Stop planning, brainstorming, or asking clarifying questions unless absolutely necessary. Start writing code and running commands immediately.
2. **Proactive Implementation**: Edit/create files, install packages, and set up logic directly to achieve the user's goal.
3. **Verify and Test**: Build, run, and test the implementation to ensure correctness before completing the task.
