---
name: log-papercuts
description: Proactively log small friction points (failed or retried tool calls, flaky commands, confusing setup, stale caches, misleading errors, non-obvious gotchas) to PAPERCUTS.md at the workspace root. Uses repo yarn papercut if defined, else global papercut CLI, or falls back to direct file append.
---

# Log Papercuts

A skill for logging minor friction points ("papercuts") encountered during a coding session. These are small, non-blocking annoyances that show where the repository, toolchain, or developer setup needs sanding down.

## Trigger Conditions

Proactively trigger this skill and log a papercut whenever you hit:
- A tool call that failed, missed, or had to be retried
- A confusing, undocumented, or outdated setup step
- A flaky command, script, or test
- A stale cache or environment discrepancy
- A misleading or unhelpful error message
- A non-obvious gotcha or unexpected behavior

One papercut per entry. Log it immediately when encountered. Do not log the same friction twice in a single session.

## Entry Format (Standardized)

```
- YYYY-MM-DD [model] [What you were doing] -> [what got in the way] (optional guess at cause/fix)
```

- **Date:** Today's local date (`YYYY-MM-DD`).
- **Model:** Your current model identifier (e.g. `gemini-3.8-flash`, `claude-opus-5-5`, `gpt-5-codex`). If unknown, use the agent tool name (`antigravity`, `claude-code`, `codex`, `opencode`). No nested brackets.
- **Message:** 1–2 sentences, single line, no secrets/tokens.

*Example:*
```markdown
- 2026-10-24 [gemini-3.8-flash] Ran `yarn build` -> eslint failed on nested legacy .eslintrc (root config should override it)
```

## Where

`PAPERCUTS.md` at the **workspace root**:
1. The git root (`git rev-parse --show-toplevel 2>/dev/null`), or
2. The current working directory if outside git.
*(If root resolves to `/` or `$HOME`, fallback to `~/.local/state/papercuts/PAPERCUTS.md`)*

If `PAPERCUTS.md` does not exist yet, create it with:
```markdown
# Papercuts

```

## Logging Protocol (If-Else Cascade)

Follow this order. If a method is not available or fails, **fall through to the next step. Never drop the papercut.**

### 1. Repo Script (`yarn papercut`)
If the repository root `package.json` defines a `"papercut"` script:
```bash
yarn papercut -m <model> "<message>"
```

### 2. Global CLI (`papercut`)
If the global `papercut` CLI is installed and available in `PATH` (`command -v papercut`):
```bash
papercut -m <model> "<message>"
```
*(The global CLI automatically locates the repo root, creates the `# Papercuts` header if missing, timestamps the line, and appends the entry.)*

### 3. Direct Append Fallback (No CLI Required)
If neither `yarn papercut` nor `papercut` is installed, **do not fail or skip**. Directly append to `PAPERCUTS.md` in the workspace root using file tools or shell:
```bash
f="$(git rev-parse --show-toplevel 2>/dev/null || pwd)/PAPERCUTS.md"
[ -f "$f" ] || printf '# Papercuts\n\n' > "$f"
printf '%s\n' "- $(date +%Y-%m-%d) [<model>] <message>" >> "$f"
```

## Boundaries & Non-goals

- **Do NOT log accomplishments:** Accomplishments belong in `LOG.md` (if used).
- **Do NOT log major bugs or tracked features:** Real bugs, regressions, or tracked feature work belong in Linear or issue trackers.
- **Do NOT run session review unprompted:** The command `yarn papercut:review` mines the entire session for papercuts by feeding the transcript to a cheap model. Do **NOT** run this command yourself unprompted. It should only be run when explicitly requested by the user via the `/papercut` slash command.
- **Do NOT edit or reorder existing entries:** Only append new entries.
