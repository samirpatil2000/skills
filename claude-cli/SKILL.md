---
name: claude-cli
description: >
  Delegate tasks to the locally installed Claude Code CLI (`claude -p`).
  Automatically selects model (haiku, sonnet, opus), reasoning effort (low,
  medium, high, xhigh, max), and triggers Ultracode multi-agent dynamic
  workflows for large-scale tasks.
---

# Claude CLI Delegation

Delegate execution to Claude Code CLI (`claude -p`). Non-interactive only.

## 1. Execution Tiers

| Tier | When to Use | Model | Effort Flag | Mode |
|---|---|---|---|---|
| **Tier 1 (Fast)** | Syntax, simple lookups, formatting, renames | `haiku` | `--effort low` | Solo |
| **Tier 2 (Standard)** | Everyday coding, small features, bug fixes | `sonnet` | `--effort high` | Solo |
| **Tier 3 (Deep)** | Subtle bugs, concurrency, architecture, security | `opus` / `sonnet` | `--effort xhigh` or `--effort max` | Solo (Deep) |
| **Tier 4 (Ultracode Swarm)** | Full-repo audits, migrations, multi-perspective reviews | `opus` | `--effort max` | Multi-Agent Swarm |

## 2. Invocation Recipes

### Standard Execution (Solo Agent)
```bash
claude -p "PROMPT" --model sonnet --effort high --output-format text
```

### Deep Reasoning (Max Effort with Automatic Fallback & Real-Time Logging)
Always pipe through `tee` when redirecting to a file to prevent stdout block buffering:
```bash
claude -p "PROMPT" --model opus --fallback-model opus-4.7,sonnet --effort max --output-format text | tee output.txt
```

### Ultracode Multi-Agent Swarm
Triggers Claude's Dynamic Workflow engine (spawns 10–16 concurrent subagents in isolated git worktrees with parallel pipelines and adversarial verification):
```bash
claude -p "ultracode: PROMPT. Spawn parallel subagents to investigate separate modules, use an adversarial skeptic to verify findings, and synthesize results." \
  --model opus \
  --fallback-model opus-4.7,sonnet \
  --effort max \
  --output-format text | tee swarm.log
```

### Stdin Context Pipe
```bash
git diff | claude -p "Review this diff for security and regressions" --model sonnet --effort high --output-format text
```

### Structured JSON Output
```bash
claude -p "PROMPT" --json-schema '{"type":"object",...}' --output-format text
```

## 3. Prompt Shaping by Effort Level
- **Low / Medium:** Keep prompt direct, prescriptive, and scoped to exact files or inputs.
- **High / Extra (`xhigh`):** Ask Claude to explicitly examine edge cases, race conditions, and test coverage before providing the solution.
- **Max:** Ask for exhaustive architectural trade-offs, underlying assumptions, and failure modes.
- **Ultracode:** Always include the keyword `ultracode:` and specify multi-agent roles (e.g. *scout agents*, *adversarial skeptic*, *synthesizer*).

## 4. Safety & Rules
- **Non-interactive only:** Always include `-p` / `--print`.
- **Default restriction:** Use `--restricted` unless shell access or file modifications are explicitly required.
- **No budget caps:** Subscription rolling window applies.
- **Output handling:** Text prints directly to stdout. If JSON output format is used, parse `.result`.
- **Unbuffered logging:** When redirecting long reasoning runs (`--effort xhigh` / `max`) to a log file, do not use raw `> output.txt` (POSIX block buffering keeps the file at 0 bytes for minutes, mimicking a hang). Always pipe through `| tee output.txt` so timestamps and progress flush continuously.
- **Rate limits:** If session limit is hit, wait for the rolling 5-hour window refresh.

## 5. Fallback, Model Downgrades & Gotchas

### Subprocess Output Buffering on Long Reasoning Runs (Empty Log Gotcha)
- **Gotcha:** Running `claude -p ... --effort max > output.txt` causes libc/POSIX to block-buffer all stdout until process exit. The task log appears completely empty (0 bytes) for 5–10 minutes, making it indistinguishable from a hung process or network freeze.
- **Resolution:** Pipe stdout through `tee` instead of direct file redirection:
  ```bash
  claude -p "PROMPT" --model opus --effort max --output-format text | tee output.txt
  ```
  In background task runners or watchdog guards, `| tee` flushes output line-by-line, keeping the log file continuously updated and preventing premature watchdog timeouts.

### Unresponsive / Overloaded Model Downgrades
If the primary model does not respond, hangs, or is overloaded:
1. Always pass `--fallback-model opus-4.7,sonnet` in CLI commands so Claude CLI automatically downgrades in order:
   `opus` → `opus-4.7` → `sonnet`.
2. For explicit retry invocations, manually downgrade to `--model opus-4.7` or `--model sonnet`.

### Safety Filter False Positives (Defensive / Security Datasets)
- **Gotcha:** Claude Opus CLI frequently triggers safety filter false-positives and refuses prompts involving administrative, privileged, or destructive commands (e.g. `sudo`, `visudo`, `shred`, `/etc/shadow`, `NOPASSWD`), even when prompts explicitly state the context is purely defensive classifier training or vulnerability blocking.
- **Resolution:** Do not fight the Claude safety filter. Immediately delegate the declined batch or security analysis task to **Codex CLI (`codex-cli` / `codex exec`)**, which processes defensive security command evaluations without false refusals:
  ```bash
  codex exec "PROMPT" --skip-git-repo-check --ephemeral -s read-only -o output.json
  ```
