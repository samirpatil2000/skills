---
name: claude-cli
description: >
  Delegate tasks to the locally installed Claude Code CLI (`claude -p`).
  Automatically selects model (haiku for lowest tier, sonnet for low tier,
  opus for deep/swarm reasoning), reasoning effort (low, medium, high, xhigh, max),
  and triggers Ultracode multi-agent workflows. Never uses Fable unless explicitly
  requested by the user.
---

# Claude CLI Delegation

Non-interactive only: always `-p`. Default `--restricted` unless shell/file writes are required.

## Tiers

| Tier | Use | Model | Effort | Mode |
|---|---|---|---|---|
| 1 Lowest | Syntax, lookups, formatting, renames, quick scripts | `haiku` | `low` | Solo |
| 2 Low | Everyday coding, small features, bug fixes, routine edits | `sonnet` | `low` / `medium` | Solo |
| 3 Deep | Subtle bugs, concurrency, architecture, complex reasoning | `opus` (default for deep) | `high` / `xhigh` / `max` | Solo |
| 4 Ultracode Swarm | Full-repo audits, migrations, multi-perspective reviews | `opus` | `max` | Multi-agent |
| Opt-in only | **Only when user explicitly asks for Fable** | `fable` / `claude-fable-5-1` / `claude-fable-5` | `max` | Explicit request |

**STRICT:** NEVER select Fable automatically for any tier or fallback. Defaults are haiku/sonnet/opus. `fable` aliases latest Fable 5.1. Versioned IDs need the `claude-` prefix (`claude-fable-5-1`, `claude-fable-5`); raw `fable-5` / `fable-5.1` fails with "isn't described by this version's model catalog".

## Recipes

```bash
# Tier 1
claude -p "PROMPT" --model haiku --effort low --output-format text
# Tier 2
claude -p "PROMPT" --model sonnet --effort low --output-format text
# Tier 3 (fallback chain + unbuffered log)
claude -p "PROMPT" --model opus --fallback-model opus-4.7,sonnet --effort max --output-format text | tee output.txt
# Tier 4 Ultracode swarm (10–16 subagents in isolated worktrees, parallel pipelines, adversarial verification)
claude -p "ultracode: PROMPT. Spawn parallel subagents to investigate separate modules, use an adversarial skeptic to verify findings, and synthesize results." \
  --model opus --fallback-model opus-4.7,sonnet --effort max --output-format text | tee swarm.log
# Fable (explicit user request only)
claude -p "PROMPT" --model fable --effort max --output-format text | tee output.txt            # 5.1
claude -p "PROMPT" --model claude-fable-5 --effort max --output-format text | tee output.txt   # 5.0
# Stdin context
git diff | claude -p "Review this diff for security and regressions" --model sonnet --effort low --output-format text
# Structured JSON
claude -p "PROMPT" --json-schema '{"type":"object",...}' --output-format text
```

## Prompt Shaping

- **low/medium:** direct, prescriptive, scoped to exact files/inputs.
- **high/xhigh:** require explicit edge cases, race conditions, test coverage before the solution.
- **max:** require exhaustive architectural trade-offs, assumptions, failure modes.
- **Ultracode:** must include `ultracode:` keyword and name roles (scout agents, adversarial skeptic, synthesizer).

## Rules

- No budget caps; subscription rolling window applies. On session limit, wait for the 5-hour window refresh.
- Text output goes to stdout; with JSON output format, parse `.result`.
- **Unbuffered logging:** never `> output.txt` for `xhigh`/`max` runs. POSIX block buffering leaves the file at 0 bytes for 5–10 min, indistinguishable from a hang and tripping watchdog timeouts. Always `| tee output.txt` so lines flush continuously.

## Fallback & Gotchas

- **Overloaded/unresponsive:** always pass `--fallback-model opus-4.7,sonnet` → auto-downgrade `opus` → `opus-4.7` → `sonnet`. Manual retries: `--model opus-4.7` or `--model sonnet`. If user-requested Fable fails: `--fallback-model opus,opus-4.7,sonnet`.
- **Safety-filter false positives:** Opus/Fable refuse defensive/security prompts involving `sudo`, `visudo`, `shred`, `/etc/shadow`, `NOPASSWD` even with stated defensive context (classifier training, vulnerability blocking). Don't fight it; redirect the batch to Codex CLI:
  ```bash
  codex exec "PROMPT" --skip-git-repo-check --ephemeral -s read-only -o output.json
  ```
