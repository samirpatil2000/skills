#!/usr/bin/env bash
# slack-notify.sh - Send formatted Slack notification via incoming webhook
set -euo pipefail

TITLE="${1:?usage: slack-notify \"title\" [\"description\"] [\"color\"]}"
DESC="${2:-}"
COLOR="${3:-#36a64f}"

# Resolve webhook URL (env var -> ~/.slack_webhook_url)
WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
if [[ -z "$WEBHOOK_URL" && -f "$HOME/.slack_webhook_url" ]]; then
  WEBHOOK_URL="$(tr -d ' \r\n' < "$HOME/.slack_webhook_url")"
fi

if [[ -z "$WEBHOOK_URL" ]]; then
  echo "ERROR: SLACK_WEBHOOK_URL not set and ~/.slack_webhook_url not found." >&2
  exit 1
fi

jq -n \
  --arg title "$TITLE" \
  --arg desc "$DESC" \
  --arg color "$COLOR" \
  '{attachments: [{color: $color, title: $title, text: $desc, mrkdwn_in: ["text", "title"]}]}' \
| curl -s -X POST -H 'Content-type: application/json' \
    -d @- \
    "$WEBHOOK_URL"
echo ""
