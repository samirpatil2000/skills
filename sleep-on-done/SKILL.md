---
name: sleep-on-done
description: Put macOS to sleep once a task or workflow is complete. Trigger on "sleep when done", "sleep after finishing", "sleep once done", "pmset sleepnow", or requests to put the machine to sleep after task completion.
---

# Sleep on Done

Puts macOS to sleep immediately after all tasks are finished.

## Command

```bash
pmset sleepnow
```

## Behavior & Rules

1. **Absolute Final Step:** Always execute `pmset sleepnow` as the very last action. All code changes, tests, git operations, and notifications (e.g. `slack-notify`) must complete first.
2. **Failure Handling:** Unless explicitly instructed to sleep regardless of errors, do not sleep if a command or test fails, allowing the user to inspect the failure.
3. **Execution Patterns:**
   - **Agent-managed:** Complete the task, provide the final response, then run `pmset sleepnow` as the last command.
   - **Shell chaining:**
     ```bash
     command && pmset sleepnow
     ```
