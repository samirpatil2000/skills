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

### Deep Reasoning (Max Effort)
```bash
claude -p "PROMPT" --model opus --effort max --output-format text
```

### Ultracode Multi-Agent Swarm
Triggers Claude's Dynamic Workflow engine (spawns 10–16 concurrent subagents in isolated git worktrees with parallel pipelines and adversarial verification):
```bash
claude -p "ultracode: PROMPT. Spawn parallel subagents to investigate separate modules, use an adversarial skeptic to verify findings, and synthesize results." \
  --model opus \
  --effort max \
  --output-format text
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
- **Rate limits:** If session limit is hit, wait for the rolling 5-hour window refresh.
