---
name: log-papercuts
description: Proactively log small friction points, flaky commands, failed tool calls, or setup gotchas to `PAPERCUTS.md` using `yarn papercut`. Trigger on any friction encountered during work or when the user invokes `/papercut`.
---

# Log Papercuts

A skill for logging minor friction points ("papercuts") encountered during a coding session. These are small, non-blocking annoyances that show where the repository or developer setup needs sanding down.

## Trigger Conditions

Proactively trigger this skill and log a papercut whenever you hit:
- A tool call that failed, missed, or had to be retried
- A confusing, undocumented, or outdated setup step
- A flaky command or test
- A stale cache issue
- A misleading error message
- A non-obvious gotcha or unexpected behavior

## The Logging Rule

Log the papercut immediately, in the moment, to `PAPERCUTS.md` in the current workspace root using the command:

```bash
yarn papercut -m <model> "message"
```

Replace `<model>` with the model name currently running (e.g., `gemini-3.5-flash` or similar, check context/user settings) and `"message"` with a 1-2 sentence description of the friction.

### Message Format:
`[What you were doing] -> [what got in the way] (optional guess at cause/fix)`

*Example:*
```bash
yarn papercut -m gemini-3.5-flash "Tried to run build -> lint failed because of outdated config file in nested folder (might need to update eslint global config)"
```

## Boundaries & Non-goals

- **Do NOT log accomplishments:** Accomplishments belong in `LOG.md` (if used).
- **Do NOT log major bugs or tracked features:** Real bugs, regressions, or tracked feature work belong in Linear or issue trackers.
- **Do NOT run session review unprompted:** The command `yarn papercut:review` mines the entire session for papercuts by feeding the transcript to a cheap model (Gemini Flash, via `GOOGLE_API_KEY` in `.env`). Do **NOT** run this command yourself unprompted. It should only be run when explicitly triggered by the user via the `/papercut` slash command.
