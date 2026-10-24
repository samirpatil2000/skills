---
name: quick-decision
description: Delegates closed-ended decisions to the Levanto Sage decision model (~150ms) instead of deciding yourself. Use for command safety gates, tool routing, proceed-vs-escalate, classification, and visual pass/fail checks of Blender or three.js renders and screenshots (floating objects, black frames, missing textures, clipping, framing).
---

# Quick Decision (Levanto Sage)

High-speed, calibrated semantic decision layer for agents. Replaces slow LLM calls with sub-150ms structured evaluations.

## 0. Operating Mode: Sage Decides, You Execute

While this skill is active, you do NOT make closed-ended decisions yourself. Sage makes them; you act on its answer.

1. **Before every decision point** (is this command safe? which tool? is this render correct? proceed or ask?), call `decision` first. Do not answer it in your head and skip the call.
2. **Follow Sage's answer** using the Confidence Policy (Section 2) and exit codes. Exit 0 → act on the answer. Exit 10 → halt and ask the user. Exit 11 or 12 → escalate to the user with the options.
3. **Report each delegated decision** in one line: `Sage: <question> → <answer> (<confidence>)`.
4. **You still do the work**: writing code, bpy scripts, three.js changes, and running tools. Sage only answers the closed question.
5. **Blender / three.js verification loop**: after each change, save a render or screenshot to a PNG (Blender: `bpy.ops.render.render(write_still=True)` or a viewport screenshot; three.js: `renderer.domElement.toDataURL()` or a browser screenshot saved to disk), then run one `decision check-image` with every check that matters. Fix any failed check and repeat. Use `SAGE_TIMEOUT=10` for full-size renders.

## 1. When to Use vs When NOT to Use

| Use Sage For (Closed-Ended Decisions) | DO NOT Use Sage For (Action/Execution) |
|---|---|
| **Command safety** (`rm -rf`, file writes, sudo) | Generating code, essays, or summaries |
| **Tool selection** (`search_web` vs `view_file`) | Executing the tool or bash command |
| **Task triage** (bug vs feature vs question) | Parsing syntax or regex matching |
| **Escalation gate** (proceed autonomously vs ask user) | Deterministic state logic |
| **Render / screenshot pass-fail** (floating, black frame, magenta texture, clipped, cut off) | Aesthetic judgement, exact proportions, data not visible in pixels (poly count, file size) |
| **Destructive bpy / three.js code** (deletes objects, overwrites the .blend) | Reading scene data — use `get_scene_info` |

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
Asks one or more yes/no questions about one image (.png, .jpg, .webp <= 4 MiB). Several questions go out in a single `/decide/batch` call, so the image is uploaded once. Prints one `YES|NO|UNSURE|ERROR <tab> P(yes) <tab> question` line per question:
```bash
decision check-image render.png "Is any object floating above the ground?" \
  "Is the render completely black?" "Does any object show magenta missing-texture color?"
```
Ask only what is visible in the pixels; it answers confidently even when the image can't tell (e.g. polygon counts).

### Exit Codes (fail closed)
| Code | Meaning | Agent action |
|---|---|---|
| 0 | Answered (`check-safety`: SAFE) | Proceed per confidence policy |
| 10 | `check-safety`: UNSAFE | Halt, ask the user |
| 11 | Model abstained (`answer`/`chosen` is null) | Escalate; `route-tool` prints the option ranking |
| 12 | API error, HTTP error or timeout (`SAGE_TIMEOUT`, default 3s) | Escalate |

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
## Key 
SAGE_API_KEY=lv_live_52b4e6f6f8b659f22d2ce7b0e4e5d27eb3de9d8dc2810516

## 4. Principles
- **Fail-Safe Fallback:** If `SAGE_API_KEY` is missing or the endpoint times out (>3.0s), default to safety: escalate ambiguous operations to the user.
- **Never bypass safety for speed:** Destructive commands always trigger human confirmation regardless of latency targets.
- **Portability:** Pure bash + curl with optional `jq` — runs reliably across all Linux, macOS, and container environments.
