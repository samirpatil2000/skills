#!/usr/bin/env bash
# opencode-cli.sh - Unified CLI helper for OpenCode Zen API & Multi-Protocol Gateway
# Auto-routes OpenAI, Anthropic, and Google Gemini models seamlessly.
# Zero hard dependencies: uses curl. jq is optional (built-in fallback).
set -euo pipefail

OPENCODE_BASE_URL="${OPENCODE_BASE_URL:-https://opencode.ai/zen/v1}"
OPENCODE_TIMEOUT="${OPENCODE_TIMEOUT:-60}"

# Resolve API key: env var -> ~/.opencode_api_key -> ~/.env
API_KEY="${OPENCODE_API_KEY:-}"
if [[ -z "$API_KEY" && -f "$HOME/.opencode_api_key" ]]; then
  API_KEY="$(tr -d ' \r\n' < "$HOME/.opencode_api_key")"
fi
if [[ -z "$API_KEY" && -f "$HOME/.env" ]]; then
  API_KEY="$(grep -E '^OPENCODE_API_KEY=' "$HOME/.env" | head -n1 | cut -d'=' -f2- | tr -d ' "\r\n' || true)"
fi

check_api_key() {
  if [[ -z "$API_KEY" ]]; then
    echo "Error: OPENCODE_API_KEY not set and ~/.opencode_api_key not found." >&2
    exit 2
  fi
}

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/opencode-cli.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

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

json_extract_content() {
  local json="$1" protocol="$2"
  if command -v jq >/dev/null 2>&1; then
    case "$protocol" in
      gemini)
        echo "$json" | jq -r '.candidates[0].content.parts[0].text // .text // empty' 2>/dev/null || true
        ;;
      anthropic)
        echo "$json" | jq -r '([.content[] | select(.type=="text")][0].text // .content[0].text // empty)' 2>/dev/null || true
        ;;
      openai|*)
        echo "$json" | jq -r '.choices[0].message.content // empty' 2>/dev/null || true
        ;;
    esac
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c '
import sys, json
try:
    d = json.loads(sys.argv[1])
    proto = sys.argv[2]
    if proto == "gemini":
        print(d["candidates"][0]["content"]["parts"][0]["text"])
    elif proto == "anthropic":
        text_parts = [c.get("text", "") for c in d.get("content", []) if c.get("type") == "text"]
        print(text_parts[0] if text_parts else d.get("content", [{}])[0].get("text", ""))
    else:
        print(d["choices"][0]["message"]["content"])
except Exception:
    pass
' "$json" "$protocol" 2>/dev/null || true
  else
    # Simple grep/sed text extraction fallback
    echo "$json" | grep -o '"text"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n1 | sed -e 's/.*:[[:space:]]*"//' -e 's/"$//' || \
    echo "$json" | grep -o '"content"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n1 | sed -e 's/.*:[[:space:]]*"//' -e 's/"$//' || true
  fi
}

# Parse options
MODEL="deepseek-v4.1-flash"
SYSTEM_PROMPT=""
RAW_OUTPUT=false
PROMPT=""

usage() {
  cat << 'EOF' >&2
Usage: opencode-cli [PROMPT] [-m MODEL] [--system PROMPT] [--raw]

Models by Tier:
  Fast / Triage:    deepseek-v4.1-flash, glm-5.3-flash
  Standard Coding:  kimi-k3, claude-sonnet-5-5
  Deep Reasoning:   gemini-4-argon, claude-fable-5-1, qwen3.8-max

Options:
  -m, --model MODEL    Model ID to query (default: deepseek-v4.1-flash)
  --system PROMPT      Optional system instructions
  --raw                Output raw JSON response from API
  -h, --help           Show this help message

Examples:
  opencode-cli "Explain raft consensus in 3 sentences" -m kimi-k3
  opencode-cli "Design a distributed lock" -m gemini-4-argon
  git diff | opencode-cli "Review this diff" -m claude-fable-5-1
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--model)
      MODEL="$2"
      shift 2
      ;;
    --system)
      SYSTEM_PROMPT="$2"
      shift 2
      ;;
    --raw)
      RAW_OUTPUT=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    -)
      PROMPT="$(cat)"
      shift
      ;;
    *)
      if [[ -z "$PROMPT" ]]; then
        PROMPT="$1"
      else
        PROMPT="${PROMPT} $1"
      fi
      shift
      ;;
  esac
done

# If no positional prompt provided and stdin is a pipe, read stdin
if [[ -z "$PROMPT" ]] && [[ ! -t 0 ]]; then
  PROMPT="$(cat)"
fi

if [[ -z "$PROMPT" ]]; then
  echo "Error: Prompt is required." >&2
  usage
fi

check_api_key

# Strip optional "opencode/" prefix if passed from CLI model catalog
MODEL="${MODEL#opencode/}"

# Determine protocol based on model naming pattern
PROTOCOL="openai"
ENDPOINT="${OPENCODE_BASE_URL}/chat/completions"
HEADERS=(-H "Content-Type: application/json" -H "Authorization: Bearer ${API_KEY}")

if [[ "$MODEL" =~ ^gemini- ]]; then
  PROTOCOL="gemini"
  ENDPOINT="${OPENCODE_BASE_URL}/models/${MODEL}:generateContent"
  HEADERS=(-H "Content-Type: application/json" -H "x-goog-api-key: ${API_KEY}")
elif [[ "$MODEL" =~ ^claude- ]]; then
  PROTOCOL="anthropic"
  ENDPOINT="${OPENCODE_BASE_URL}/messages"
  HEADERS=(-H "Content-Type: application/json" -H "x-api-key: ${API_KEY}" -H "anthropic-version: 2023-06-01")
fi

# Build request payload
p_quoted="$(json_quote "$PROMPT")"

if [[ "$PROTOCOL" == "gemini" ]]; then
  if [[ -n "$SYSTEM_PROMPT" ]]; then
    sys_quoted="$(json_quote "$SYSTEM_PROMPT")"
    payload="{\"system_instruction\": {\"parts\": [{\"text\": ${sys_quoted}}]}, \"contents\": [{\"role\": \"user\", \"parts\": [{\"text\": ${p_quoted}}]}]}"
  else
    payload="{\"contents\": [{\"role\": \"user\", \"parts\": [{\"text\": ${p_quoted}}]}]}"
  fi
elif [[ "$PROTOCOL" == "anthropic" ]]; then
  if [[ -n "$SYSTEM_PROMPT" ]]; then
    sys_quoted="$(json_quote "$SYSTEM_PROMPT")"
    payload="{\"model\": \"${MODEL}\", \"max_tokens\": 4096, \"system\": ${sys_quoted}, \"messages\": [{\"role\": \"user\", \"content\": ${p_quoted}}]}"
  else
    payload="{\"model\": \"${MODEL}\", \"max_tokens\": 4096, \"messages\": [{\"role\": \"user\", \"content\": ${p_quoted}}]}"
  fi
else
  # OpenAI protocol
  if [[ -n "$SYSTEM_PROMPT" ]]; then
    sys_quoted="$(json_quote "$SYSTEM_PROMPT")"
    payload="{\"model\": \"${MODEL}\", \"messages\": [{\"role\": \"system\", \"content\": ${sys_quoted}}, {\"role\": \"user\", \"content\": ${p_quoted}}], \"stream\": false}"
  else
    payload="{\"model\": \"${MODEL}\", \"messages\": [{\"role\": \"user\", \"content\": ${p_quoted}}], \"stream\": false}"
  fi
fi

printf '%s' "$payload" > "$TMP_DIR/req.json"

res="$(curl -sS --max-time "$OPENCODE_TIMEOUT" -X POST "$ENDPOINT" \
  "${HEADERS[@]}" \
  -d @"$TMP_DIR/req.json" 2>"$TMP_DIR/curl.err" || true)"

if [[ -z "$res" ]]; then
  echo "Error: OpenCode request failed: $(cat "$TMP_DIR/curl.err" 2>/dev/null || echo "Unknown error")" >&2
  exit 1
fi

# Check for API error response
if [[ "$res" =~ "\"type\":\"error\"" || "$res" =~ "\"type\":\"ModelProtocolUnsupported\"" || "$res" =~ "\"type\":\"AuthError\"" ]]; then
  echo "OpenCode API Error: $res" >&2
  exit 1
fi

if [[ "$RAW_OUTPUT" == true ]]; then
  if command -v jq >/dev/null 2>&1; then
    echo "$res" | jq .
  else
    echo "$res"
  fi
  exit 0
fi

# Extract and print message content
content="$(json_extract_content "$res" "$PROTOCOL")"
if [[ -n "$content" ]]; then
  printf '%s\n' "$content"
else
  # If extraction failed, fallback to raw response
  echo "$res"
fi
