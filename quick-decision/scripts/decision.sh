#!/usr/bin/env bash
# decision.sh - Pure bash + curl semantic decision helper powered by Levanto Sage
# Zero hard dependencies: uses curl. jq is optional (graceful fallback).
#
# Fails closed: errors, timeouts and model abstentions never report SAFE.
# Exit codes:
#   0   answered (check-safety: SAFE)
#   2   usage / configuration error
#   10  check-safety: UNSAFE
#   11  model abstained or unsure -> escalate to the user
#   12  API error, HTTP error or timeout -> escalate to the user
set -euo pipefail

SAGE_BASE_URL="${SAGE_BASE_URL:-https://sage.levanto.ai}"
SAGE_TIMEOUT="${SAGE_TIMEOUT:-3}"

# Resolve API key: env var -> ~/.sage_api_key -> ~/.env
API_KEY="${SAGE_API_KEY:-}"
if [[ -z "$API_KEY" && -f "$HOME/.sage_api_key" ]]; then
  API_KEY="$(tr -d ' \r\n' < "$HOME/.sage_api_key")"
fi
if [[ -z "$API_KEY" && -f "$HOME/.env" ]]; then
  API_KEY="$(grep -E '^SAGE_API_KEY=' "$HOME/.env" | head -n1 | cut -d'=' -f2- | tr -d ' "\r\n' || true)"
fi

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/decision.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

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

# Prints the value at a dotted path, or "" when missing or null.
json_extract() {
  local json="$1"
  local field="$2"
  local out=""
  if command -v jq >/dev/null 2>&1; then
    out="$(echo "$json" | jq -r "$field // empty" 2>/dev/null || true)"
  elif command -v python3 >/dev/null 2>&1; then
    out="$(python3 -c '
import sys, json
try:
    data = json.loads(sys.argv[1])
    for p in sys.argv[2].strip(".").split("."):
        if p:
            data = data[p]
    print("" if data is None else data)
except Exception:
    print("")
' "$json" "$field" 2>/dev/null || true)"
  else
    local key="${field##*.}"
    out="$(echo "$json" | grep -o "\"$key\"[[:space:]]*:[[:space:]]*[^,}]*" | head -n1 | sed -e 's/.*:[[:space:]]*//' -e 's/^"//' -e 's/"$//' || true)"
  fi
  [[ "$out" == "null" ]] && out=""
  printf '%s' "$out"
}

# sage_post <path> <payload-file>: prints the response body on HTTP 200.
# On curl failure, timeout or non-200 it prints the reason to stderr and returns 12.
sage_post() {
  local path="$1" payload_file="$2" body rc=0 http
  body="$(curl -sS --max-time "$SAGE_TIMEOUT" -w '\n%{http_code}' -X POST "${SAGE_BASE_URL}${path}" \
    -H "Authorization: Bearer ${API_KEY}" \
    -H "Content-Type: application/json" \
    -H "User-Agent: quick-decision/1.1" \
    -d @"$payload_file" 2>"$TMP_DIR/curl.err")" || rc=$?
  if (( rc != 0 )); then
    if (( rc == 28 )); then
      echo "Error: Sage request timed out after ${SAGE_TIMEOUT}s. Escalate to the user." >&2
    else
      echo "Error: Sage request failed (curl exit $rc): $(tr -d '\n' < "$TMP_DIR/curl.err"). Escalate to the user." >&2
    fi
    return 12
  fi
  http="${body##*$'\n'}"
  body="${body%$'\n'*}"
  if [[ "$http" != "200" ]]; then
    local detail
    detail="$(json_extract "$body" ".detail")"
    echo "Error: Sage returned HTTP ${http}: ${detail:-$body}. Escalate to the user." >&2
    return 12
  fi
  printf '%s' "$body"
}

percent() { awk -v p="${1:-0}" 'BEGIN { printf "%.1f", p * 100 }'; }

cmd="${1:-help}"
shift || true

case "$cmd" in
  health)
    curl -sS --max-time "$SAGE_TIMEOUT" -H "User-Agent: quick-decision/1.1" "${SAGE_BASE_URL}/ready" || exit 12
    echo ""
    ;;

  check-safety)
    check_api_key
    command_str="${1:?usage: decision.sh check-safety \"<command>\"}"
    c_quoted="$(json_quote "$command_str")"
    i_quoted="$(json_quote "Is this shell command destructive, modifying system files, or unsafe to run without user confirmation?")"
    printf '%s' "{\"content\": ${c_quoted}, \"question\": {\"id\": \"command_safety\", \"kind\": \"yesno\", \"instructions\": ${i_quoted}}}" > "$TMP_DIR/req.json"

    if ! res="$(sage_post /decide "$TMP_DIR/req.json")"; then
      echo -e "\033[93m[ESCALATE]\033[0m Verdict: UNKNOWN (API unavailable) - ask the user before running."
      exit 12
    fi

    answer="$(json_extract "$res" ".result.answer")"
    raw_p="$(json_extract "$res" ".result.probability")"
    latency="$(json_extract "$res" ".meta.latency_ms")"

    case "$answer" in
      yes)
        echo -e "\033[91m[UNSAFE]\033[0m Verdict: UNSAFE / DESTRUCTIVE (Confidence: $(percent "$raw_p")%, Latency: ${latency:-?}ms)"
        exit 10
        ;;
      no)
        echo -e "\033[92m[SAFE]\033[0m Verdict: SAFE (Confidence: $(percent "$(awk -v p="${raw_p:-0}" 'BEGIN { print 1 - p }')")%, Latency: ${latency:-?}ms)"
        exit 0
        ;;
      *)
        echo -e "\033[93m[ESCALATE]\033[0m Verdict: UNSURE (P(unsafe)=${raw_p:-?}, Latency: ${latency:-?}ms) - ask the user before running."
        exit 11
        ;;
    esac
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
    printf '%s' "{\"content\": ${t_quoted}, \"question\": {\"id\": \"tool_selection\", \"kind\": \"choice\", \"instructions\": \"Which tool is best suited for this task?\", \"options\": [${joined_options}]}}" > "$TMP_DIR/req.json"

    res="$(sage_post /decide "$TMP_DIR/req.json")" || exit 12

    chosen="$(json_extract "$res" ".result.chosen")"
    raw_p="$(json_extract "$res" ".result.probability")"
    latency="$(json_extract "$res" ".meta.latency_ms")"

    if [[ -n "$chosen" ]]; then
      echo "Chosen Tool: ${chosen} (Confidence: $(percent "$raw_p")%, Latency: ${latency:-?}ms)"
      exit 0
    fi

    echo "Chosen Tool: none - model abstained (Latency: ${latency:-?}ms). Ask the user or pick from the ranking:"
    if command -v jq >/dev/null 2>&1; then
      echo "$res" | jq -r '.result.probabilities // [] | sort_by(-.probability) | .[] | "  \(.option)\t\(.probability * 1000 | round / 10)%"'
    elif command -v python3 >/dev/null 2>&1; then
      python3 -c '
import json, sys
probs = json.loads(sys.argv[1]).get("result", {}).get("probabilities") or []
for p in sorted(probs, key=lambda x: -x["probability"]):
    print("  %s\t%.1f%%" % (p["option"], p["probability"] * 100))
' "$res"
    fi
    exit 11
    ;;

  check-image)
    check_api_key
    image_path="${1:?usage: decision.sh check-image <path/to/image> \"<question>\" [\"<question>\" ...]}"
    shift
    if [[ $# -eq 0 ]]; then
      echo "usage: decision.sh check-image <path/to/image> \"<question>\" [\"<question>\" ...]" >&2
      exit 2
    fi
    if [[ ! -f "$image_path" ]]; then
      echo "Error: Image file not found: $image_path" >&2
      exit 2
    fi
    if ! command -v jq >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
      echo "Error: check-image needs jq or python3 to read the response." >&2
      exit 2
    fi

    # Guard: check image file size (< 4 MiB)
    fsize=$(stat -f%z "$image_path" 2>/dev/null || stat -c%s "$image_path" 2>/dev/null || wc -c < "$image_path" | tr -d ' ')
    if [[ -n "$fsize" ]] && (( fsize > 4194304 )); then
      size_mb="$(awk "BEGIN { printf \"%.2f\", $fsize / (1024 * 1024) }")"
      echo "Error: Image exceeds 4 MiB limit (${size_mb} MiB)" >&2
      exit 2
    fi

    ext="$(printf '%s' "${image_path##*.}" | tr '[:upper:]' '[:lower:]')"
    mime="image/png"
    case "$ext" in
      jpg|jpeg) mime="image/jpeg" ;;
      webp) mime="image/webp" ;;
    esac

    # One upload, all questions in a single /decide/batch call.
    questions_arr=()
    n=0
    for q in "$@"; do
      n=$((n + 1))
      questions_arr+=("{\"id\": \"q${n}\", \"kind\": \"yesno\", \"instructions\": $(json_quote "$q")}")
    done
    joined_questions="$(IFS=,; echo "${questions_arr[*]}")"

    # Stream the base64 straight into the payload file so large images never hit ARG_MAX.
    {
      printf '{"requests": [{"content": {"kind": "image", "media": "data:%s;base64,' "$mime"
      base64 < "$image_path" | tr -d '\r\n'
      printf '"}, "questions": [%s]}]}' "$joined_questions"
    } > "$TMP_DIR/req.json"

    res="$(sage_post /decide/batch "$TMP_DIR/req.json")" || exit 12
    latency="$(json_extract "$res" ".meta.latency_ms")"

    # One line per question: VERDICT <tab> P(yes) <tab> question
    printf '%s' "$res" > "$TMP_DIR/res.json"
    if command -v jq >/dev/null 2>&1; then
      lines="$(jq -r '
        (.results[0].answers // []) as $a
        | $ARGS.positional | to_entries[]
        | ($a[.key]) as $r
        | if ($r == null) or ($r.ok != true) then "ERROR\t-\t\(.value)\t\($r.error // "no answer returned")"
          elif $r.result.result.answer == null then "UNSURE\t\($r.result.result.probability // "-")\t\(.value)"
          else "\($r.result.result.answer | ascii_upcase)\t\($r.result.result.probability)\t\(.value)"
          end' --args "$@" < "$TMP_DIR/res.json")"
    else
      lines="$(python3 -c '
import json, sys
res = json.load(open(sys.argv[1]))
answers = (res.get("results") or [{}])[0].get("answers") or []
for i, q in enumerate(sys.argv[2:]):
    r = answers[i] if i < len(answers) else None
    if not r or not r.get("ok"):
        print("ERROR\t-\t%s\t%s" % (q, (r or {}).get("error") or "no answer returned"))
        continue
    out = r["result"]["result"]
    if out.get("answer") is None:
        print("UNSURE\t%s\t%s" % (out.get("probability", "-"), q))
    else:
        print("%s\t%s\t%s" % (out["answer"].upper(), out["probability"], q))
' "$TMP_DIR/res.json" "$@")"
    fi

    echo "$lines"
    echo "(${n} question(s), Latency: ${latency:-?}ms)"
    # Fail closed: anything other than YES/NO lines is an error or abstention.
    [[ -z "$lines" || $'\n'"$lines" == *$'\n'ERROR* ]] && exit 12
    [[ $'\n'"$lines" == *$'\n'UNSURE* ]] && exit 11
    exit 0
    ;;

  raw|decide)
    check_api_key
    content="${1:?usage: decision.sh decide \"<content>\" \"<instructions>\" [kind]}"
    instructions="${2:?usage: decision.sh decide \"<content>\" \"<instructions>\" [kind]}"
    kind="${3:-yesno}"

    c_quoted="$(json_quote "$content")"
    i_quoted="$(json_quote "$instructions")"
    k_quoted="$(json_quote "$kind")"

    printf '%s' "{\"content\": ${c_quoted}, \"question\": {\"id\": \"q\", \"kind\": ${k_quoted}, \"instructions\": ${i_quoted}}}" > "$TMP_DIR/req.json"

    res="$(sage_post /decide "$TMP_DIR/req.json")" || exit 12

    if command -v jq >/dev/null 2>&1; then
      echo "$res" | jq -r '.result // .'
    else
      echo "$res"
    fi
    # yesno -> answer, choice -> chosen; null means the model abstained.
    if [[ "$kind" == "yesno" && -z "$(json_extract "$res" ".result.answer")" ]] \
      || [[ "$kind" == "choice" && -z "$(json_extract "$res" ".result.chosen")" ]]; then
      exit 11
    fi
    ;;

  *)
    echo "Usage: decision.sh <command> [args...]"
    echo "Commands:"
    echo "  health                                         Check Sage API status"
    echo "  check-safety \"<command>\"                       Check if shell command is destructive"
    echo "  route-tool \"<task>\" <tool1> <tool2>            Select best tool from options"
    echo "  check-image <file> \"<q1>\" [\"<q2>\" ...]         Ask yes/no questions about one image (<= 4 MiB)"
    echo "  decide \"<content>\" \"<instructions>\" [kind]     Run generic decision"
    echo "Exit codes: 0 ok/safe, 10 unsafe, 11 unsure (escalate), 12 API error/timeout (escalate)"
    echo "Env: SAGE_TIMEOUT (seconds, default 3), SAGE_BASE_URL"
    ;;
esac
