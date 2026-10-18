---
name: execute
description: Execution mode. Trigger on "go ahead", "do it", "execute", "implement", "make the changes", or any approval to act. Stop planning, start building.
---

# Execute

Act. No more planning, no more questions. Build it.

## Rules

1. **Immediately exit planning mode** — no confirmation prompt, no "are you sure?", no gates. The user invoking execute IS the confirmation.
2. Write code, edit files, run commands — immediately
3. Install what's needed, create what's missing
4. Test and verify before reporting done
5. **Unbuffered logging for long runs** — When capturing stdout of long-running or reasoning commands into a file, never use raw `> output.txt` (which causes POSIX block-buffering and looks hung with 0 bytes). Always use `| tee output.txt` so incremental output is written immediately.
