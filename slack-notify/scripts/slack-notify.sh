#!/usr/bin/env bash
# slack-notify.sh - Send clean, human-readable Slack alert (no attachment boxes/bars)
set -euo pipefail

TITLE="${1:?usage: slack-notify \"title\" \"summary\" [\"details\"] [\"status\"]}"
SUMMARY="${2:-}"
DETAILS="${3:-}"
STATUS="${4:-success}"

ICON="✅"
case "$STATUS" in
  error|fail|failed) ICON="❌" ;;
  warn|warning)      ICON="⚠️" ;;
  info)              ICON="ℹ️" ;;
esac

# Interpret any literal \n into real linebreaks
REAL_SUMMARY="$(printf '%b' "$SUMMARY")"
REAL_DETAILS="$(printf '%b' "$DETAILS")"

MSG="${ICON} *${TITLE}*"
if [[ -n "$REAL_SUMMARY" ]]; then
  MSG="${MSG}
${REAL_SUMMARY}"
fi
if [[ -n "$REAL_DETAILS" ]]; then
  MSG="${MSG}

${REAL_DETAILS}"
fi

WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
if [[ -z "$WEBHOOK_URL" && -f "$HOME/.slack_webhook_url" ]]; then
  WEBHOOK_URL="$(tr -d ' \r\n' < "$HOME/.slack_webhook_url")"
fi

if [[ -z "$WEBHOOK_URL" ]]; then
  echo "ERROR: SLACK_WEBHOOK_URL not set and ~/.slack_webhook_url not found." >&2
  exit 1
fi

jq -n --arg text "$MSG" '{text: $text}' \
| curl -s -X POST -H 'Content-type: application/json' -d @- "$WEBHOOK_URL" > /dev/null
