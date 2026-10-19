#!/usr/bin/env bash
# decision.sh - Pure bash + curl semantic decision helper powered by Levanto Sage
# Zero hard dependencies: uses curl. jq is optional (graceful fallback).
set -euo pipefail

SAGE_BASE_URL="${SAGE_BASE_URL:-https://sage.levanto.ai}"

# Resolve API key: env var -> ~/.sage_api_key -> ~/.env
API_KEY="${SAGE_API_KEY:-}"
if [[ -z "$API_KEY" && -f "$HOME/.sage_api_key" ]]; then
  API_KEY="$(tr -d ' \r\n' < "$HOME/.sage_api_key")"
fi
if [[ -z "$API_KEY" && -f "$HOME/.env" ]]; then
  API_KEY="$(grep -E '^SAGE_API_KEY=' "$HOME/.env" | head -n1 | cut -d'=' -f2- | tr -d ' "\r\n')"
fi

check_api_key() {
  if [[ -z "$API_KEY" ]]; then
    echo "Error: SAGE_API_KEY not set and ~/.sage_api_key not found." >&2
    exit 2
  fi
}

# JSON helpers with graceful fallbacks if jq is missing
json_quote() {
  local str="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -n --arg v "$str" '$v'
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json, sys; sys.stdout.write(json.dumps(sys.argv[1]))' "$str"
  else
    printf '%s' "$str" | awk '
      BEGIN { RS="^$"; ORS="" }
      {
        gsub(/\\/, "\\\\")
        gsub(/"/, "\\\"")
        gsub(/\n/, "\\n")
        gsub(/\r/, "\\r")
        gsub(/\t/, "\\t")
        print "\"" $0 "\""
      }
    '
  fi
}

json_extract() {
  local json="$1"
  local field="$2"
  if command -v jq >/dev/null 2>&1; then
    echo "$json" | jq -r "$field" 2>/dev/null || echo ""
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c '
import sys, json
try:
    data = json.loads(sys.argv[1])
    path = sys.argv[2].strip(".").split(".")
    for p in path:
        if p and p != "//":
            data = data[p]
    print(data if data is not None else "")
except Exception:
    print("")
' "$json" "$field" 2>/dev/null
  else
    local key="${field##*.}"
    key="${key%% *}"
    echo "$json" | grep -o "\"$key\"[[:space:]]*:[[:space:]]*[^,}]*" | head -n1 | sed -e 's/.*:[[:space:]]*//' -e 's/^"//' -e 's/"$//'
  fi
}

cmd="${1:-help}"
shift || true

case "$cmd" in
  health)
    curl -s -H "User-Agent: quick-decision/1.0" "${SAGE_BASE_URL}/ready"
    echo ""
    ;;

  check-safety)
    check_api_key
    command_str="${1:?usage: decision.sh check-safety \"<command>\"}"
    c_quoted="$(json_quote "$command_str")"
    i_quoted="$(json_quote "Is this shell command destructive, modifying system files, or unsafe to run without user confirmation?")"
    payload="{\"content\": ${c_quoted}, \"question\": {\"id\": \"command_safety\", \"kind\": \"yesno\", \"instructions\": ${i_quoted}}}"

    res="$(curl -s -X POST "${SAGE_BASE_URL}/decide" \
      -H "Authorization: Bearer ${API_KEY}" \
      -H "Content-Type: application/json" \
      -H "User-Agent: quick-decision/1.0" \
      -d "$payload")"

    answer="$(json_extract "$res" ".result.answer")"
    [[ -z "$answer" ]] && answer="$(json_extract "$res" "answer")"
    raw_p="$(json_extract "$res" ".result.probability")"
    [[ -z "$raw_p" ]] && raw_p="$(json_extract "$res" "probability")"
    [[ -z "$raw_p" ]] && raw_p="0"
    latency="$(json_extract "$res" ".meta.latency_ms")"
    [[ -z "$latency" ]] && latency="$(json_extract "$res" "latency_ms")"
    [[ -z "$latency" ]] && latency="0"

    if [[ "$answer" == "yes" ]]; then
      conf="$(awk "BEGIN { printf \"%.1f\", $raw_p * 100 }")"
      echo -e "\033[91m[UNSAFE]\033[0m Verdict: UNSAFE / DESTRUCTIVE (Confidence: ${conf}%, Latency: ${latency}ms)"
      exit 10
    else
      conf="$(awk "BEGIN { printf \"%.1f\", (1.0 - $raw_p) * 100 }")"
      echo -e "\033[92m[SAFE]\033[0m Verdict: SAFE (Confidence: ${conf}%, Latency: ${latency}ms)"
      exit 0
    fi
    ;;

  route-tool)
    check_api_key
    task_desc="${1:?usage: decision.sh route-tool \"<task>\" <tool1> <tool2> ...}"
    shift
    if [[ $# -eq 0 ]]; then
      echo "Error: At least one tool candidate required." >&2
      exit 2
    fi

    # Build options JSON array
    options_arr=()
    for opt in "$@"; do
      q_opt="$(json_quote "$opt")"
      options_arr+=("{\"option\": ${q_opt}}")
    done
    joined_options="$(IFS=,; echo "${options_arr[*]}")"

    t_quoted="$(json_quote "$task_desc")"
    payload="{\"content\": ${t_quoted}, \"question\": {\"id\": \"tool_selection\", \"kind\": \"choice\", \"instructions\": \"Which tool is best suited for this task?\", \"options\": [${joined_options}]}}"

    res="$(curl -s -X POST "${SAGE_BASE_URL}/decide" \
      -H "Authorization: Bearer ${API_KEY}" \
      -H "Content-Type: application/json" \
      -H "User-Agent: quick-decision/1.0" \
      -d "$payload")"

    chosen="$(json_extract "$res" ".result.chosen")"
    [[ -z "$chosen" ]] && chosen="$(json_extract "$res" "chosen")"
    raw_p="$(json_extract "$res" ".result.probability")"
    [[ -z "$raw_p" ]] && raw_p="$(json_extract "$res" "probability")"
    [[ -z "$raw_p" ]] && raw_p="0"
    latency="$(json_extract "$res" ".meta.latency_ms")"
    [[ -z "$latency" ]] && latency="$(json_extract "$res" "latency_ms")"
    [[ -z "$latency" ]] && latency="0"
    conf="$(awk "BEGIN { printf \"%.1f\", $raw_p * 100 }")"

    echo "Chosen Tool: ${chosen} (Confidence: ${conf}%, Latency: ${latency}ms)"
    ;;

  check-image)
    check_api_key
    image_path="${1:?usage: decision.sh check-image <path/to/image> \"<instructions>\"}"
    instructions="${2:?usage: decision.sh check-image <path/to/image> \"<instructions>\"}"
    if [[ ! -f "$image_path" ]]; then
      echo "Error: Image file not found: $image_path" >&2
      exit 2
    fi

    # Guard: check image file size (< 4 MiB)
    fsize=$(stat -f%z "$image_path" 2>/dev/null || stat -c%s "$image_path" 2>/dev/null || wc -c < "$image_path" | tr -d ' ')
    if [[ -n "$fsize" ]] && (( fsize > 4194304 )); then
      size_mb="$(awk "BEGIN { printf \"%.2f\", $fsize / (1024 * 1024) }")"
      echo "Error: Image exceeds 4 MiB limit (${size_mb} MiB)" >&2
      exit 2
    fi

    ext="${image_path##*.}"
    mime="image/png"
    case "$ext" in
      jpg|jpeg) mime="image/jpeg" ;;
      webp) mime="image/webp" ;;
    esac

    b64="$(base64 < "$image_path" | tr -d '\r\n')"
    data_uri="data:${mime};base64,${b64}"

    i_quoted="$(json_quote "$instructions")"
    payload="{\"content\": {\"kind\": \"image\", \"media\": \"${data_uri}\"}, \"question\": {\"id\": \"img_q\", \"kind\": \"yesno\", \"instructions\": ${i_quoted}}}"

    res="$(curl -s -X POST "${SAGE_BASE_URL}/decide" \
      -H "Authorization: Bearer ${API_KEY}" \
      -H "Content-Type: application/json" \
      -H "User-Agent: quick-decision/1.0" \
      -d "$payload")"

    if command -v jq >/dev/null 2>&1; then
      echo "$res" | jq -r '.result // .'
    else
      echo "$res"
    fi
    ;;

  raw|decide)
    check_api_key
    content="${1:?usage: decision.sh decide \"<content>\" \"<instructions>\" [kind]}"
    instructions="${2:?usage: decision.sh decide \"<content>\" \"<instructions>\" [kind]}"
    kind="${3:-yesno}"

    c_quoted="$(json_quote "$content")"
    i_quoted="$(json_quote "$instructions")"
    k_quoted="$(json_quote "$kind")"

    payload="{\"content\": ${c_quoted}, \"question\": {\"id\": \"q\", \"kind\": ${k_quoted}, \"instructions\": ${i_quoted}}}"

    res="$(curl -s -X POST "${SAGE_BASE_URL}/decide" \
      -H "Authorization: Bearer ${API_KEY}" \
      -H "Content-Type: application/json" \
      -H "User-Agent: quick-decision/1.0" \
      -d "$payload")"

    if command -v jq >/dev/null 2>&1; then
      echo "$res" | jq -r '.result // .'
    else
      echo "$res"
    fi
    ;;

  *)
    echo "Usage: decision.sh <command> [args...]"
    echo "Commands:"
    echo "  health                               Check Sage API status"
    echo "  check-safety \"<command>\"             Check if shell command is destructive"
    echo "  route-tool \"<task>\" <tool1> <tool2>  Select best tool from options"
    echo "  check-image <file> \"<instructions>\"  Evaluate an image (<= 4 MiB)"
    echo "  decide \"<content>\" \"<instructions>\"  Run generic decision"
    ;;
esac
