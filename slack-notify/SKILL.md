---
name: slack-notify
description: >
  Send formatted notifications and alerts to Slack via incoming webhook.
  Trigger on "notify on slack", "send slack message", "slack alert",
  "ping slack", or when an automated process/agent completes a task and
  needs to notify the user on Slack.
---

# Slack Notify

Send structured, formatted notifications directly to Slack channels via incoming webhook.

## 1. Quick Usage

Run the shell command or bundled helper:

```bash
slack-notify "Task Completed" "Deployment to production finished successfully."
```

Or using the bundled script directly with custom status colors:

```bash
# Success (Green)
scripts/slack-notify.sh "Build Passed" "All 42 unit tests passed in 3.4s" "#36a64f"

# Failure / Alert (Red)
scripts/slack-notify.sh "Job Failed" "Process exited with code 1: see error.log" "#e01e5a"

# Warning (Yellow)
scripts/slack-notify.sh "Disk Warning" "Storage reached 88% capacity" "#ecb22e"
```

## 2. In-line Bash Function

If running in subshells or isolated environments where functions are needed:

```bash
slack-notify() {
  local title="${1:?usage: slack-notify \"title\" \"description\"}"
  local desc="${2:-}"
  local color="${3:-#36a64f}"

  local url="${SLACK_WEBHOOK_URL:-$(cat ~/.slack_webhook_url 2>/dev/null)}"
  if [[ -z "$url" ]]; then
    echo "ERROR: SLACK_WEBHOOK_URL not configured." >&2
    return 1
  fi

  jq -n \
    --arg title "$title" \
    --arg desc "$desc" \
    --arg color "$color" \
    '{attachments: [{color: $color, title: $title, text: $desc, mrkdwn_in: ["text", "title"]}]}' \
  | curl -s -X POST -H 'Content-type: application/json' -d @- "$url"
}
```

## 3. Configuration & Webhook Resolution
The tool looks for the webhook URL in the following order:
1. `SLACK_WEBHOOK_URL` environment variable.
2. `~/.slack_webhook_url` file (local secure storage).

To set or update the webhook:
```bash
echo "https://hooks.slack.com/services/..." > ~/.slack_webhook_url
chmod 600 ~/.slack_webhook_url
```

## 4. Best Practices
- **Post-process notifications:** Trigger when long-running scripts, dataset generations, or builds complete.
- **Include links & metrics:** Format descriptions with markdown links and runtime metrics (duration, counts, errors).
- **Match colors to status:** Green (`#36a64f`) for success, red (`#e01e5a`) for errors, yellow (`#ecb22e`) for warnings.
