---
name: log-papercuts
description: Record small, non-blocking friction ("papercuts") directly in PAPERCUTS.md at the workspace root, in the moment, so the next agent can avoid or work around it. Use this proactively, without being asked, whenever a tool call fails, misses or needs a retry; a setup step is confusing, undocumented or outdated; a command or test is flaky; a cache is stale; an error message misleads; or something behaves in a non-obvious way. Also use it when the user says "papercut", "log that friction" or "note that annoyance", and read PAPERCUTS.md at the start of any coding session in a repo that has one. This skill never runs commands; it only reads and edits the file. Not for accomplishments, real bugs, or feature work.
---

# Log Papercuts

Papercuts are the small annoyances that never make it into an issue tracker but add up: the retry, the stale cache, the error that pointed the wrong way. `PAPERCUTS.md` is a shared memory of that friction. Each agent that works in the repo reads it before starting and appends to it as it goes, so the same gotcha is paid for once instead of every session.

This skill never runs a command, script or tool. It only reads and edits `PAPERCUTS.md`, even if the repo ships a papercut script of its own.

## Step 1: read before you work

At the start of a session in a repo, check whether `PAPERCUTS.md` exists at the workspace root (the git root, or the current directory if there is no git root). If it does, read it before running anything. Pay attention to:

- entries marked **Open** that touch the area you are about to work in
- any **Workaround** lines, which tell you what to do instead of rediscovering the problem
- repeated entries, which signal something that will probably bite you too

If an entry's workaround saves you from the friction, you are done; do not log it again. If you hit a logged papercut anyway, add a repeat note rather than a new entry (see below).

## Step 2: log in the moment

Log as soon as you notice any of these, then carry on with the task:

- a tool call that failed, missed, or had to be retried
- a confusing, undocumented, or outdated setup step
- a flaky command or test
- a stale cache
- a misleading error message
- a non-obvious gotcha or unexpected behaviour

One papercut per entry. Log it at the moment it happens, not at the end of the session, so the details (exact error text, what you were running) are still accurate.

### Creating the file

If `PAPERCUTS.md` does not exist, create it at the workspace root with this header, then append your first entry:

```markdown
# Papercuts

Small, non-blocking friction hit while working in this repo. One entry per papercut, newest at the bottom.
Read this before starting work; append to it the moment something gets in your way.
Not for accomplishments (LOG.md) or real bugs (issue tracker).
```

### Entry format

Append entries to the end of the file. Every entry uses the same shape so later agents can scan and search it:

```markdown
## YYYY-MM-DD · <area> · <short title>
- **Model:** <model running this session>
- **Doing:** <what you were trying to do>
- **Hit:** <what got in the way, with the exact error text or symptom if short>
- **Workaround:** <what actually got you past it, or "none found">
- **Likely cause / fix:** <best guess, or "unknown">
- **Status:** Open
```

Field notes:

- **area** is a short path or component name (`packages/legacy`, `test setup`, `docker`, `ci`), so entries can be grouped and searched.
- **Model** is the model actually running this session, taken from your own context. Do not copy a model name from an example.
- **Doing** and **Hit** are the useful pair. Keep them to one or two sentences each.
- **Workaround** is the line the next agent needs most. If you found none, say so; a later agent can fill it in.
- **Status** is `Open` when logged. Anyone who fixes the underlying issue changes it to `Fixed (YYYY-MM-DD)` with a one-line note; nobody deletes entries.

Example:

```markdown
## 2026-11-03 · packages/legacy · lint fails on stale .eslintrc
- **Model:** claude-fable-5-1
- **Doing:** Ran the root build to check a change in packages/api.
- **Hit:** Build stopped on lint errors from packages/legacy/.eslintrc, which references a removed plugin.
- **Workaround:** Ran lint with `--ignore-path` pointing at a file that excludes packages/legacy.
- **Likely cause / fix:** Root eslint config should ignore packages/legacy, or that config should be deleted.
- **Status:** Open
```

### Repeats

If an entry for the same friction already exists, do not add a new one. Append a dated line under the existing entry instead:

```markdown
- **Repeat:** 2026-11-03, claude-fable-5-1 — still happening; workaround above worked.
```

Repeats are useful signal: an entry with several repeat lines is the thing most worth fixing.

### Housekeeping

- Keep newest entries at the bottom so the file reads chronologically.
- Make the smallest possible edit; never reorder, reformat or rewrite other agents' entries.
- If the file has grown past a few hundred lines, suggest to the user that fixed entries be moved to a `PAPERCUTS-archive.md`. Do not do this yourself unless asked.

## What not to log

- **Accomplishments** go in `LOG.md`, if the repo uses one.
- **Real bugs, regressions and tracked feature work** go in Linear or the issue tracker. If a papercut turns out to be a real bug, say so to the user rather than logging it here.
- **Secrets.** Never put keys, tokens, private URLs or personal data in an entry; describe the friction instead ("auth failed because the token in .env had expired").
- **Problems you caused yourself** (a typo in your own command) are not papercuts unless the repo made the mistake easy to make.

## Session review: on request, by hand

If the user invokes `/papercut` or asks for a session review, re-read the conversation so far, pick out any friction that was not logged in the moment, and append those entries using the same format. Do this by reading and writing the file yourself; do not run any review script or send the transcript anywhere.
