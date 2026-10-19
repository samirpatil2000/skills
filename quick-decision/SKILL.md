---
name: quick-decision
description: Ultra-fast (<150ms) semantic decision engine powered by Levanto Sage. Use for binary checks (command safety, proceed vs escalate), multi-option tool routing, classification, and confidence-gated agent workflows without heavyweight LLM calls.
---

# Quick Decision (Levanto Sage)

High-speed, calibrated semantic decision layer for agents. Replaces slow LLM calls with sub-150ms structured evaluations.

## 1. When to Use vs When NOT to Use

| Use Sage For (Closed-Ended Decisions) | DO NOT Use Sage For (Action/Execution) |
|---|---|
| **Command safety** (`rm -rf`, file writes, sudo) | Generating code, essays, or summaries |
| **Tool selection** (`search_web` vs `view_file`) | Executing the tool or bash command |
| **Task triage** (bug vs feature vs question) | Parsing syntax or regex matching |
| **Escalation gate** (proceed autonomously vs ask user) | Deterministic state logic |

## 2. Confidence Policy

| Confidence Score | Decision Policy | Agent Action |
|---|---|---|
| **$\ge 0.85$** | High Confidence | Proceed autonomously without prompting the user. |
| **$0.70 - 0.84$** | Moderate Confidence | Proceed if low risk; verify if writing/modifying code. |
| **$< 0.70$ or `null`** | Ambiguous / Low Confidence | **Escalate to user.** Prompt user with clear choices. |
| **Any Unsafe Flag** | Safety Violation | **Halt immediately.** Require explicit user authorization. |

## 3. Recipes

Helper CLI: `decision` (bash + curl at `~/.local/bin/decision`, or script at `scripts/decision.sh`). Zero runtime dependencies — `jq` is optional (built-in fallbacks handle JSON parsing seamlessly if missing).

### Command Safety Check (Binary Gate via curl)
Evaluates if a shell command is destructive or modifies system files (exits code 0 if safe, code 10 if unsafe):
```bash
decision check-safety "git status"
decision check-safety "rm -rf /var/log"  # returns [UNSAFE], exit code 10
```

### Tool Routing (Discrete Choice via curl)
Chooses the optimal tool from candidate options:
```bash
decision route-tool "Find where user auth tokens are stored in the repo" \
  search_code run_command ask_question search_web
```

### Arbitrary Decision (`yesno`, `choice`, `scale`, `tags`)
```bash
decision decide "Customer message: I want to cancel my account immediately." \
  "Is the user requesting account cancellation or churn?" yesno
```

### Visual / Image Decisions (Screenshots & Media)
Evaluates images (.png, .jpg, .webp <= 4 MiB) with optional accompanying text:
```bash
decision check-image screenshot.png "Does this UI screen display a critical payment error modal?"
```

### Direct Raw curl (Zero CLI Dependencies)
```bash
KEY="${SAGE_API_KEY:-$(cat ~/.sage_api_key)}"
curl -s -X POST "https://sage.levanto.ai/decide" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "git clean -fdx",
    "question": {"id": "q1", "kind": "yesno", "instructions": "Is this command destructive?"}
  }'
```

## 4. Principles
- **Fail-Safe Fallback:** If `SAGE_API_KEY` is missing or the endpoint times out (>3.0s), default to safety: escalate ambiguous operations to the user.
- **Never bypass safety for speed:** Destructive commands always trigger human confirmation regardless of latency targets.
- **Portability:** Pure bash + curl with optional `jq` — runs reliably across all Linux, macOS, and container environments.
