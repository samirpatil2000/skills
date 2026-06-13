---
name: opencode-fusion
description: >
  Multi-model analysis and synthesis using OpenCode CLI — replicates OpenRouter Fusion
  style workflows locally. Runs multiple LLMs in parallel, judges their outputs, and
  produces a single synthesized response. Trigger whenever the user wants to run a task
  against multiple models, compare model outputs, get a consensus answer, or says things
  like "fusion run", "multi-model", "run all models", "synthesize model outputs", or
  "parallel agents". Also trigger when the user wants to reduce hallucinations by
  cross-checking multiple LLMs, or when high-stakes tasks need more than one model's
  perspective.
---

# OpenCode Fusion Skill

Implements an **OpenRouter Fusion-style** workflow entirely through OpenCode CLI:
parallel model execution → judge analysis → final synthesis.

**Full workflow runs automatically** after loading this skill. No external orchestration needed.

---

## Architecture Overview

```
TASK INPUT
    │
    ▼
┌─────────────────────────────────────┐
│  Phase 1: Parallel Model Execution  │
│  ┌────────┐ ┌──────┐ ┌──────┐      │
│  │ Claude │ │ GPT  │ │ GLM  │      │  ← add/remove freely
│  └────────┘ └──────┘ └──────┘      │
│       All run simultaneously        │
└────────────────┬────────────────────┘
                 │ outputs → /tmp/fusion-*/
                 ▼
┌─────────────────────────────────────┐
│  Phase 2: Judge Layer               │
│  Analyzes consensus, contradictions,│
│  gaps, risks, unique insights       │
└────────────────┬────────────────────┘
                 │ judge report → /tmp/
                 ▼
┌─────────────────────────────────────┐
│  Phase 3: Synthesizer               │
│  Merges best ideas, resolves        │
│  conflicts, fills gaps              │
└────────────────┬────────────────────┘
                 │
                 ▼
         FINAL OUTPUT (only this shown to user)
```

---

## Invocation

The skill runner should call `run_fusion.sh` with the task as argument:

```bash
bash run_fusion.sh "<TASK>"
```

Everything else is automated. The script handles parallel execution, waiting, judging, and synthesis.

---

## Phase 1: Model Panel Configuration

The panel is defined at the top of `run_fusion.sh` as a bash array — easy to add/remove models.

**Default models**: `opencode/claude-sonnet-4-6`, `opencode/gpt-5.5-pro`, `opencode/glm-5.1`

Each model runs via:
```bash
opencode run "<TASK>" \
  -m "<MODEL_ID>" \
  --attach http://localhost:37993 \
  --dangerously-skip-permissions \
  > /tmp/fusion-<MODEL_SLUG>/output.txt 2>/tmp/fusion-<MODEL_SLUG>/err.txt &
```

All jobs launched with `&`, then `wait` collects them. Exit codes checked per-model — failures are noted but don't abort synthesis.

---

## Phase 2: Judge Prompt

Read `references/judge-prompt.md` for the full judge system prompt.

The judge receives all model outputs concatenated with clear `=== MODEL: <name> ===` delimiters and produces a **structured report** with:

- `CONSENSUS` — points all/most models agree on
- `CONTRADICTIONS` — where models conflict, with analysis of which is likely correct
- `GAPS` — important aspects no model covered
- `RISKS` — identified failure modes or edge cases
- `UNIQUE_INSIGHTS` — valuable points from individual models
- `RECOMMENDED_APPROACH` — synthesis direction

---

## Phase 3: Synthesizer Prompt

Read `references/synthesizer-prompt.md` for the full synthesizer system prompt.

The synthesizer receives:
1. The original task
2. The judge's structured report
3. All raw model outputs

It produces the **single final response** shown to the user.

---

## Skill Runner Instructions

When this skill is invoked with a task:

1. Check that `opencode` CLI is available (`which opencode`)
2. Check that the OpenCode server is running (`curl -s http://localhost:37993/health` or similar)
3. Execute `bash run_fusion.sh "<TASK>"`
4. Stream the final synthesized output to the user
5. Optionally report which models succeeded/failed

If `opencode` is not available or the server is not running, output a clear error with setup instructions (see `references/setup.md`).

---

## Adding / Removing Models

Edit the `MODELS` array in `run_fusion.sh`:

```bash
MODELS=(
  "opencode/claude-sonnet-4-6:claude-sonnet-4-6"
  "opencode/gpt-5.5-pro:gpt-5.5-pro"
  "opencode/glm-5.1:glm-5.1"
  # "opencode/claude-opus-4-8:claude-opus-4-8"
  # "opencode/gpt-5.5:gpt-5.5"
  # "opencode/glm-5:glm-5"
)
```

Format: `"<model-id>:<slug>"` — the slug is used for temp file naming.

---

## Reference Files

- `references/judge-prompt.md` — Full judge system prompt
- `references/synthesizer-prompt.md` — Full synthesizer system prompt
- `references/setup.md` — OpenCode setup and server prerequisites
- `run_fusion.sh` — Main orchestration script
