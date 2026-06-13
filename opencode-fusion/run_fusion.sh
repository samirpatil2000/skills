#!/usr/bin/env bash
# =============================================================================
# OpenCode Fusion — Parallel Multi-Model Synthesis
# Usage: bash run_fusion.sh "<TASK>"
# =============================================================================

set -euo pipefail

TASK="${1:-}"
if [[ -z "$TASK" ]]; then
  echo "ERROR: No task provided." >&2
  echo "Usage: bash run_fusion.sh \"<your task here>\"" >&2
  exit 1
fi

OPENCODE_SERVER="${OPENCODE_SERVER:-http://localhost:37993}"
FUSION_DIR="/tmp/fusion-$$"          # unique per run (PID-scoped)
JUDGE_OUTPUT="$FUSION_DIR/judge.txt"
FINAL_OUTPUT="$FUSION_DIR/synthesis.txt"

# =============================================================================
# MODEL PANEL — edit freely
# Format: "model-id:slug"   slug used for /tmp dirs and display names
# =============================================================================
MODELS=(
  "opencode/claude-sonnet-4-6:claude-sonnet-4-6"
  "opencode/gpt-5.5-pro:gpt-5.5-pro"
  "opencode/glm-5.1:glm-5.1"
  # "opencode/claude-opus-4-8:claude-opus-4-8"
  # "opencode/gpt-5.5:gpt-5.5"
  # "opencode/glm-5:glm-5"
)

# =============================================================================
# Helpers
# =============================================================================
log()  { echo "[fusion] $*" >&2; }
sep()  { echo "================================================================" >&2; }

check_deps() {
  if ! command -v opencode &>/dev/null; then
    echo "ERROR: opencode CLI not found. See references/setup.md for install instructions." >&2
    exit 1
  fi
}

check_server() {
  if ! curl -sf "$OPENCODE_SERVER" -o /dev/null 2>/dev/null; then
    echo "WARN: OpenCode server at $OPENCODE_SERVER may not be running." >&2
    echo "      Start it with: opencode serve" >&2
    echo "      Continuing anyway — opencode may manage its own session." >&2
  fi
}

# =============================================================================
# Phase 1: Parallel model execution
# =============================================================================
run_models() {
  mkdir -p "$FUSION_DIR"
  local pids=()
  local slugs=()

  sep
  log "Phase 1 — Launching ${#MODELS[@]} models in parallel"
  sep

  for entry in "${MODELS[@]}"; do
    local model_id="${entry%%:*}"
    local slug="${entry##*:}"
    local model_dir="$FUSION_DIR/$slug"
    mkdir -p "$model_dir"

    log "Starting model: $model_id"
    (
      opencode run "$TASK" \
        -m "$model_id" \
        --attach "$OPENCODE_SERVER" \
        --dangerously-skip-permissions \
        > "$model_dir/output.txt" 2>"$model_dir/err.txt"
      echo $? > "$model_dir/exit_code.txt"
    ) &
    pids+=($!)
    slugs+=("$slug")
  done

  log "Waiting for all models to complete..."
  local all_ok=true
  for i in "${!pids[@]}"; do
    local pid="${pids[$i]}"
    local slug="${slugs[$i]}"
    if wait "$pid" 2>/dev/null; then
      log "✓ $slug completed"
    else
      log "✗ $slug failed — will use partial output if available"
      all_ok=false
    fi
  done

  if [[ "$all_ok" == false ]]; then
    log "One or more models failed. Continuing with available outputs."
  fi
}

# =============================================================================
# Phase 2: Collect outputs and build combined context
# =============================================================================
build_combined_context() {
  local combined="$FUSION_DIR/combined.txt"

  echo "=== ORIGINAL TASK ===" > "$combined"
  echo "$TASK" >> "$combined"
  echo "" >> "$combined"

  local model_count=0
  for entry in "${MODELS[@]}"; do
    local slug="${entry##*:}"
    local output_file="$FUSION_DIR/$slug/output.txt"

    if [[ -f "$output_file" && -s "$output_file" ]]; then
      echo "=== MODEL: $slug ===" >> "$combined"
      cat "$output_file" >> "$combined"
      echo "" >> "$combined"
      ((model_count++))
    else
      echo "=== MODEL: $slug ===" >> "$combined"
      echo "[No output — model failed or returned empty]" >> "$combined"
      echo "" >> "$combined"
    fi
  done

  if [[ "$model_count" -eq 0 ]]; then
    log "ERROR: All models failed — no outputs to synthesize." >&2
    exit 1
  fi

  log "Collected outputs from $model_count/${#MODELS[@]} models"
  echo "$combined"
}

# =============================================================================
# Phase 2: Judge layer
# =============================================================================
run_judge() {
  local combined_file="$1"
  sep
  log "Phase 2 — Running Judge analysis"
  sep

  local judge_prompt
  judge_prompt=$(cat <<'JUDGE_PROMPT'
You are a senior technical judge analyzing outputs from multiple AI models for the same task.
Your job is NOT to pick a winner — it is to produce a structured analytical report that a
synthesizer will use to generate the final response.

Analyze the model outputs below and produce a report with EXACTLY these sections:

CONSENSUS
- List points that most/all models agree on (these are high-confidence)

CONTRADICTIONS
- List conflicts between models
- For each contradiction, state which position is more likely correct and why

GAPS
- List important aspects of the task that NO model addressed adequately

RISKS
- Identify failure modes, security issues, edge cases, or implementation risks raised by any model

UNIQUE_INSIGHTS
- List valuable ideas, approaches, or details found in ONLY ONE model output
  Format: [model-name]: <insight>

RECOMMENDED_APPROACH
- A concise synthesis direction: what the final answer should prioritize, combine, and avoid
- Should be specific enough that a synthesizer can produce a complete final answer

Be analytical, precise, and concise. Do not reproduce large blocks of model output.
Focus on what DIFFERS and what is UNIQUELY VALUABLE across models.
JUDGE_PROMPT
)

  local combined_content
  combined_content=$(cat "$combined_file")

  opencode run "$(printf '%s\n\n%s' "$judge_prompt" "$combined_content")" \
    -m "opencode/claude-code" \
    --attach "$OPENCODE_SERVER" \
    --dangerously-skip-permissions \
    > "$JUDGE_OUTPUT" 2>"$FUSION_DIR/judge_err.txt" || {
      log "WARN: Judge model failed. Attempting fallback synthesis without judge report."
      echo "JUDGE_FAILED=true"
      return
    }

  log "✓ Judge analysis complete"
}

# =============================================================================
# Phase 3: Synthesizer
# =============================================================================
run_synthesizer() {
  local combined_file="$1"
  local judge_failed="${2:-false}"
  sep
  log "Phase 3 — Running Synthesizer"
  sep

  local judge_content=""
  if [[ "$judge_failed" != "true" && -f "$JUDGE_OUTPUT" ]]; then
    judge_content=$(cat "$JUDGE_OUTPUT")
  else
    judge_content="[Judge analysis unavailable — synthesize directly from model outputs]"
  fi

  local combined_content
  combined_content=$(cat "$combined_file")

  local synthesizer_prompt
  synthesizer_prompt=$(cat <<'SYNTH_PROMPT'
You are a master synthesizer. Your job is to produce ONE final, complete, actionable response
to the original task by combining the best elements from multiple model outputs.

You have been given:
1. The original task
2. A judge analytical report
3. All raw model outputs

Your synthesis rules:
- Start from the RECOMMENDED_APPROACH in the judge report (if available)
- Incorporate UNIQUE_INSIGHTS that add genuine value
- Resolve CONTRADICTIONS using the judge guidance
- Fill any GAPS the judge identified
- Do NOT mention that this is a synthesis or that multiple models were used
- Do NOT say "Model A said X, Model B said Y"
- Write as if you are a single expert giving their best answer
- The output must be directly usable — code should run, plans should be executable
- Be comprehensive but not bloated; cut anything redundant

Produce only the final response. No preamble. No meta-commentary.
SYNTH_PROMPT
)

  local full_synth_input
  full_synth_input=$(printf '%s\n\n=== JUDGE REPORT ===\n%s\n\n=== ALL MODEL OUTPUTS ===\n%s' \
    "$synthesizer_prompt" "$judge_content" "$combined_content")

  opencode run "$full_synth_input" \
    -m "opencode/claude-code" \
    --attach "$OPENCODE_SERVER" \
    --dangerously-skip-permissions \
    > "$FINAL_OUTPUT" 2>"$FUSION_DIR/synth_err.txt" || {
      log "ERROR: Synthesizer failed." >&2
      exit 1
    }

  log "✓ Synthesis complete"
}

# =============================================================================
# Cleanup
# =============================================================================
cleanup() {
  rm -rf "$FUSION_DIR"
}
# Uncomment to auto-cleanup after run:
# trap cleanup EXIT

# =============================================================================
# Main
# =============================================================================
main() {
  check_deps
  check_server

  run_models

  local combined_file
  combined_file=$(build_combined_context)

  local judge_failed="false"
  local judge_result
  judge_result=$(run_judge "$combined_file")
  if [[ "$judge_result" == *"JUDGE_FAILED=true"* ]]; then
    judge_failed="true"
  fi

  run_synthesizer "$combined_file" "$judge_failed"

  sep
  log "Fusion complete. Temp files at: $FUSION_DIR"
  sep

  # Output ONLY the synthesized result
  cat "$FINAL_OUTPUT"
}

main "$@"
