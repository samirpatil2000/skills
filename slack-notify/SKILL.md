---
name: slack-notify
description: >
  Send clean, human-readable Slack alerts via incoming webhook. Trigger on
  "notify on slack", "slack alert", "ping me when done", or when a job
  finishes and Slack notification was requested.
---

# Slack Notify

Send simple, human-readable Slack notifications directly to Slack channels.

## 1. Task Completion Rule
Whenever the user asks to be notified on task completion (e.g. *"notify me on Slack"*, *"ping me when done"*, *"send Slack alert when finished"*):
1. Complete all work, tests, and verification first.
2. As the very last step, invoke `slack-notify` with the outcome.
3. Use `success` (`✅`) if done cleanly, or `error` (`❌`) if the run failed.

## 2. Message Format

Renders as a native Slack message (no attachment containers or colored sidebars):
- **Headline:** Bold text prefixed with status icon (`✅ *Title*`).
- **Mid-Summary:** 1–2 plain-English sentences of what happened.
- **Details (Optional):** Bullet points or technical logs placed below.

## 3. Usage

```bash
# Basic notification
slack-notify "Title" "1-2 sentence human summary"

# With bulleted technical details
slack-notify "Training Data Ready" "Created 200 defensive examples across 4 batches." "• Output: batches/claude/risk/\n• Items: 200 examples\n• Size: 78 KB"

# Error alert
slack-notify "Pipeline Failed" "Process exited with code 1 due to rate limits." "• Error: ConnectionResetError in api.py:42" "error"

# Warning alert
slack-notify "Disk Warning" "Storage reached 91% capacity." "• Path: /dev/disk1s1" "warn"
```

## 4. Status Icons
- `success` (default) → `✅`
- `error` / `fail` → `❌`
- `warn` → `⚠️`
- `info` → `ℹ️`
