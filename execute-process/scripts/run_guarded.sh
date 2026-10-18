#!/usr/bin/env bash
# run_guarded.sh - Process watchdog enforcing max runtime and idle output timeout
set -euo pipefail

MAX_TIME=0
IDLE_TIME=0
LOG_FILE=""
COMMAND=()

usage() {
  echo "Usage: $0 [--max SECONDS] [--idle SECONDS] [--log LOGFILE] -- COMMAND [ARGS...]" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --max)
      MAX_TIME="$2"
      shift 2
      ;;
    --idle)
      IDLE_TIME="$2"
      shift 2
      ;;
    --log)
      LOG_FILE="$2"
      shift 2
      ;;
    --)
      shift
      COMMAND=("$@")
      break
      ;;
    *)
      usage
      ;;
  esac
done

if [[ ${#COMMAND[@]} -eq 0 ]]; then
  echo "ERROR: No command specified." >&2
  usage
fi

if [[ -z "$LOG_FILE" ]]; then
  LOG_FILE="$(mktemp -t run_guarded_log.XXXXXX)"
fi

# Ensure log directory exists and touch file
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Prevent runtime buffering in common environments (Python, Node)
export PYTHONUNBUFFERED=1

# Run command in background (pipe through tee to prevent stdout block buffering from freezing log size)
"${COMMAND[@]}" > >(tee "$LOG_FILE" > /dev/null) 2>&1 &
PID=$!

START_TIME=$(date +%s)
LAST_CHANGE_TIME=$START_TIME
LAST_SIZE=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)

cleanup() {
  if kill -0 "$PID" 2>/dev/null; then
    kill -TERM "$PID" 2>/dev/null || true
    sleep 1
    kill -KILL "$PID" 2>/dev/null || true
  fi
}

trap cleanup EXIT

while kill -0 "$PID" 2>/dev/null; do
  sleep 2
  NOW=$(date +%s)
  
  # Check max time
  if [[ $MAX_TIME -gt 0 ]] && (( NOW - START_TIME >= MAX_TIME )); then
    echo "ERROR: Command timed out after maximum runtime of ${MAX_TIME}s: ${COMMAND[*]}" >&2
    echo "--- Last lines of $LOG_FILE ---" >&2
    tail -n 25 "$LOG_FILE" >&2 || true
    cleanup
    trap - EXIT
    exit 124
  fi
  
  # Check idle time
  CURRENT_SIZE=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
  if [[ "$CURRENT_SIZE" != "$LAST_SIZE" ]]; then
    LAST_SIZE="$CURRENT_SIZE"
    LAST_CHANGE_TIME=$NOW
  elif [[ $IDLE_TIME -gt 0 ]] && (( NOW - LAST_CHANGE_TIME >= IDLE_TIME )); then
    echo "ERROR: Command hung (no new output for ${IDLE_TIME}s): ${COMMAND[*]}" >&2
    echo "--- Last lines of $LOG_FILE ---" >&2
    tail -n 25 "$LOG_FILE" >&2 || true
    cleanup
    trap - EXIT
    exit 137
  fi
done

wait "$PID"
EXIT_CODE=$?
trap - EXIT
exit "$EXIT_CODE"
