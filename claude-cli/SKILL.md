---
name: claude-cli
description: >
  Delegate tasks to the locally installed Claude CLI (Claude Code).
  Trigger on "run this in claude", "delegate to claude", "use claude cli",
  or when a task benefits from a separate Claude Code session.
---

# Claude CLI Delegation

Run tasks in Claude Code CLI (`claude -p`) from this agent. Non-interactive only.

## Command Pattern
```
claude -p "PROMPT" \
  --model MODEL \
  --effort EFFORT \
  --output-format FORMAT
```

## Model × Effort Selection

| Task | Model | Effort |
|---|---|---|
| Quick lookup, formatting | `haiku` | `low` |
| Code gen, analysis, review | `sonnet` | `high` |
| Deep reasoning, architecture | `opus` | `max` |

## Recipes

**Plain answer:**
```bash
claude -p "PROMPT" --model haiku --effort low --output-format text
```

**With file context (stdin pipe):**
```bash
cat file.py | claude -p "Review this code" --model sonnet --output-format text
```

**Structured output:**
```bash
claude -p "PROMPT" --json-schema '{"type":"object",...}' --output-format text
```

**Read-only repo analysis:**
```bash
claude -p "PROMPT" --restricted --model sonnet --effort high --output-format text
```

**With specific tools only:**
```bash
claude -p "PROMPT" --allowed-tools "Read Bash(git *)" --output-format text
```

**Custom system prompt:**
```bash
claude -p "PROMPT" --system-prompt "You are a JSON API." --output-format text
```

## Safety Rules
- Default to `--restricted` unless shell access is explicitly needed.
- Never pass secrets in `--system-prompt` (visible in `ps`).
- Use `--permission-mode manual` for any write operations.

## Output Handling
- `--output-format text` → plain result on stdout.
- `--output-format json` → full JSON with `.result` field, `.usage`.
- Parse JSON: `claude -p "..." --output-format json | python3 -c "import sys,json; print(json.load(sys.stdin)['result'])"`

## Error Handling
- Non-zero exit code = failure. Check stderr.
- Auth expired → run `claude auth login`.
- Rate / session limits reached → wait for the next rolling window reset.
