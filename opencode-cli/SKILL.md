---
name: opencode-cli
description: >
  Delegate tasks to OpenCode Zen API (https://opencode.ai/zen/v1) and OpenCode CLI
  (`opencode run`). Supports multi-protocol auto-routing across OpenCode's top models
  (Fast: deepseek-v4.1-flash, Standard: kimi-k3, Deep: gemini-4-argon, claude-fable-5-1,
  qwen3.8-max).
---

# OpenCode Delegation

Two entry points: `opencode-cli` helper (single-shot query via Zen API, auto-routes protocol per model) and `opencode run` (autonomous agent with workspace file edits). Default to `opencode-cli`; escalate to `opencode run` only when multi-file edits are required.

## Tiers

| Tier | Use | Model | Entry |
|---|---|---|---|
| 1 Fast / Triage | Syntax, lookups, formatting, renames | `deepseek-v4.1-flash` | `opencode-cli` |
| 2 Standard Coding | Features, bug fixes, routine edits | `kimi-k3` / `claude-sonnet-5-5` | `opencode-cli` |
| 3 Deep Reasoning / Flagship | Architecture, concurrency, hard bugs | `gemini-4-argon` / `claude-fable-5-1` / `qwen3.8-max` | `opencode-cli` |
| 4 Autonomous CLI | Multi-file workspace edits, repo-wide tasks | `opencode run --model opencode/<model>` | `opencode run` |

Defaults: Tier 1 `deepseek-v4.1-flash`, Tier 2 `kimi-k3`, Tier 3 `gemini-4-argon`. Tier 3 alternates (`claude-fable-5-1`, `qwen3.8-max`) for second opinions or when Argon is overloaded. Tier 4 model = whichever tier the task would otherwise use, prefixed `opencode/`.

## Recipes

```bash
# Tier 1 fast query
opencode-cli "PROMPT" -m deepseek-v4.1-flash
# Tier 2 standard
opencode-cli "PROMPT" -m kimi-k3
# Tier 3 deep reasoning (unbuffered log)
opencode-cli "PROMPT" -m gemini-4-argon | tee output.txt
# Tier 3 Fable
opencode-cli "PROMPT" -m claude-fable-5-1 | tee output.txt
# Stdin context
git diff | opencode-cli "Review this diff for security and regressions" -m kimi-k3
# Tier 4 autonomous workspace run (stdin MUST be redirected)
opencode run "TASK" --model opencode/gemini-4-argon < /dev/null | tee run.log
```

### Direct curl (bypass helper; protocol must match model)

```bash
# OpenAI protocol — kimi-k3, deepseek-*, qwen3.8-max
curl -sS https://opencode.ai/zen/v1/chat/completions \
  -H "Authorization: Bearer $OPENCODE_API_KEY" -H "Content-Type: application/json" \
  -d '{"model":"kimi-k3","messages":[{"role":"user","content":"PROMPT"}]}'
# Anthropic protocol — claude-*
curl -sS https://opencode.ai/zen/v1/messages \
  -H "x-api-key: $OPENCODE_API_KEY" -H "anthropic-version: 2023-06-01" -H "Content-Type: application/json" \
  -d '{"model":"claude-fable-5-1","max_tokens":8192,"messages":[{"role":"user","content":"PROMPT"}]}'
# Gemini protocol — gemini-*
curl -sS "https://opencode.ai/zen/v1/models/gemini-4-argon:generateContent" \
  -H "x-goog-api-key: $OPENCODE_API_KEY" -H "Content-Type: application/json" \
  -d '{"contents":[{"role":"user","parts":[{"text":"PROMPT"}]}]}'
```

## Prompt Shaping

- **Tier 1/2:** direct, prescriptive, scoped to exact files/inputs; paste the snippet via stdin rather than describing it.
- **Tier 3:** require explicit edge cases, race conditions, failure modes, and trade-offs before the solution.
- **Tier 4:** state the goal, the allowed file set, and the verification command (tests/build) the agent must run before finishing.

## Rules

- **Protocol auto-routing:** `gemini-*` → Google Gemini API, `claude-*` → Anthropic messages, everything else → OpenAI `chat/completions`. `opencode-cli` does this for you; raw curl does not.
- **Unbuffered logging:** never `> output.txt` on long Tier 3/4 runs. Block buffering leaves the file at 0 bytes for minutes, indistinguishable from a hang. Always `| tee output.txt`.
- Text output goes to stdout; stderr carries helper diagnostics. Keep them separate (`2>errors.log`) when parsing.
- Paid models only on the external API; see free-tier gotcha below.

## Gotchas

- **ModelProtocolUnsupported:** sending `claude-*` or `gemini-*` to `/chat/completions` (or `kimi-k3` to `/messages`) fails with this error. Not a model outage; wrong endpoint. Use `opencode-cli` to auto-route, or pick the matching curl recipe above.
- **Stdin hang:** `opencode run` blocks forever waiting on an attached terminal and looks like a stalled run. Always append `< /dev/null`. Same applies inside scripts, cron, and subagents.
- **FreeTierError:** models ending in `-free` (e.g. `deepseek-v4.1-flash-free`) are blocked on the external API. Drop the suffix (`deepseek-v4.1-flash`) or use the OpenCode desktop app.
- **Overloaded flagship:** if `gemini-4-argon` times out, retry on `claude-fable-5-1`, then `qwen3.8-max`. No automatic fallback flag; the retry is manual.
- **Model prefix:** `opencode run` needs `opencode/` before the model name (`--model opencode/kimi-k3`); `opencode-cli -m` takes the bare name. Mixing them yields "unknown model".
