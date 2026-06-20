---
name: Terminal
description: Run a user-given shell command directly and return raw output, no commentary.
---

# Terminal

Trigger: user provides a shell command and wants it executed as-is.

Behavior:
- Run the exact command via bash_tool. No interpretation, no explanation, no extra context-gathering.
- Reply with only the raw terminal output (stdout/stderr), no preamble or analysis.
- Exception: skip commands that are clearly destructive/malicious (e.g. `rm -rf /`, fork bombs, credential exfiltration) — briefly say why instead of running them.
