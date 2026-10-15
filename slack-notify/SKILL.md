---
name: slack-notify
description: Send Slack alerts via incoming webhook. Trigger on "notify on slack", "slack alert", or when a job finishes.
---

# Slack Notify

Send alerts to Slack via incoming webhook (`~/.slack_webhook_url` or `SLACK_WEBHOOK_URL`).

## Usage

```bash
slack-notify "Title" "Description"
```

## Color Variants

```bash
# Success (Green)
scripts/slack-notify.sh "Build Succeeded" "Finished in 45s" "#36a64f"

# Failure (Red)
scripts/slack-notify.sh "Job Failed" "Exited with code 1" "#e01e5a"

# Warning (Yellow)
scripts/slack-notify.sh "High Memory" "RAM usage at 91%" "#ecb22e"
```

## Configuration
Stores webhook in `~/.slack_webhook_url` (or `$SLACK_WEBHOOK_URL`).
```bash
echo "https://hooks.slack.com/services/..." > ~/.slack_webhook_url
```
