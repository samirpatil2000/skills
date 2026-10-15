---
name: execute-process
description: Execution mode. Trigger on "go ahead", "do it", "execute", "implement", "make the changes", or any approval to act. Stop planning, start building. Also governs how long-running commands, scripts, and AI CLI tools (opencode, claude -p, codex, aider, gemini, etc.) are run during execution, so that nothing can hang silently for hours.
---

# Execute

Act. No more planning, no more questions. Build it.

## Rules

1. **Immediately exit planning mode**: no confirmation prompt, no "are you sure?", no gates. The user invoking execute IS the confirmation.
2. Write code, edit files, run commands, immediately.
3. Install what's needed, create what's missing.
4. Test and verify before reporting done.
5. **Nothing runs without a time limit.** Every external command that could block gets a timeout, and a timeout is reported as a failure. A silent hang is worse than a crash, because a crash gets noticed and a hang can burn hours before anyone looks.

## Never let a process hang silently

A process that stops making progress but never exits produces no error, so no one flags it. The fix is to make "stuck" detectable and turn it into a loud, normal failure. Apply all of the following whenever you run a CLI tool, an AI agent, a network call, or any script that wraps one.

### 1. Close stdin for non-interactive runs

Many CLIs (opencode especially) wait for input, a confirmation, or a login prompt when they think a terminal is attached. With no human there, they wait forever. Always redirect stdin:

```bash
opencode run --model <model> "prompt" < /dev/null
```

In Python, pass `stdin=subprocess.DEVNULL`. Also set `CI=1` and `TERM=dumb` in the environment; many tools skip interactive prompts and spinners when they see these.

### 2. Put a hard timeout on every call

```bash
timeout --kill-after=15s 600 opencode run --model <model> "prompt" < /dev/null
rc=$?
if [ $rc -eq 124 ] || [ $rc -eq 137 ]; then
  echo "ERROR: opencode timed out after 600s" >&2
  exit 1
fi
```

On macOS, `timeout` comes from coreutils (`brew install coreutils`) and is called `gtimeout`. In Python:

```python
import subprocess
try:
    r = subprocess.run(cmd, stdin=subprocess.DEVNULL, capture_output=True,
                       text=True, timeout=600)
except subprocess.TimeoutExpired:
    raise RuntimeError(f"Timed out after 600s: {cmd}")  # fail loudly, never swallow
if r.returncode != 0:
    raise RuntimeError(f"Exit {r.returncode}: {r.stderr[-2000:]}")
```

Pick the timeout from what the task should take, then roughly double it. A single model prompt should be minutes, not hours.

### 3. For long jobs, add an inactivity watchdog

A hard timeout alone does not help when a job legitimately takes two hours: you'd have to set the limit above two hours, and a hang would still burn all of it. Watch for **no new output** instead. Use the bundled script:

```bash
scripts/run_guarded.sh --max 7200 --idle 300 --log run.log -- opencode run --model <model> "prompt"
```

This kills the whole process tree and exits non-zero if the command produces no output for `--idle` seconds or runs past `--max` seconds. The exit message says which limit was hit and shows the last lines of the log.

### 4. Smoke-test the tool before the real run

Before starting a long job that depends on a CLI or model, run the smallest possible call with a short timeout (30 to 60 seconds):

```bash
timeout 60 opencode run --model <model> "Reply with the single word OK" < /dev/null
```

If this hangs or doesn't print OK, stop and fix or switch the model now. Don't discover it two hours later.

### 5. Run long jobs in the background and actually check on them

Start long jobs in the background with output going to a log file, then poll: check that the process is alive and that the log is still growing. If the log hasn't changed in several minutes, treat the job as hung, kill it, and report it. Never start a job and walk away assuming it will finish.

### 6. Timeouts and hangs are failures, not silence

When something times out or is killed by a watchdog:
- Exit non-zero and print a clear `ERROR:` line saying which command, which limit, and how long it ran.
- Report it to the user in the final summary. Never report a task as done if any step timed out.
- Do not blindly retry the same command with the same model more than once. If it hangs twice, it will hang again; switch the model or approach.

## Known gotchas

Add new entries here whenever a tool is found to hang or misbehave.

- **OpenCode + DeepSeek free model hangs.** `opencode run --model opencode/deepseek-v4.1-flash-free` has hung on basic non-interactive prompts without printing anything or exiting, and needed to be killed. When using it: always close stdin, always wrap in `timeout` or `run_guarded.sh`, and run the smoke test first. If the smoke test hangs, switch to a different model rather than retrying.
