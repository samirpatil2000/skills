---
name: codex-cli
description: >
  Delegate tasks to the locally installed Codex CLI (`codex exec`).
  Supports reasoning tiers (low to ultra), native image generation,
  vision input (-i), structured JSON output, and sandboxed execution.
---

# Codex CLI Delegation

Delegate execution to OpenAI Codex CLI (`codex exec`). Non-interactive only.

## 1. Execution Tiers

| Tier | Task | Model | Effort Flag |
|---|---|---|---|
| **Fast** | Quick scripts, syntax, small edits | `gpt-6-astra` | `-c model_reasoning_effort="low"` |
| **Standard** | Everyday features, debugging | `gpt-6-astra` | `-c model_reasoning_effort="medium"` |
| **Ultra** | Complex architecture, multi-agent logic | `gpt-6-astra` | `-c model_reasoning_effort="ultra"` |

## 2. Recipes

### Plain Query / Code Gen (Clean Output to File)
```bash
codex exec "PROMPT" --skip-git-repo-check --ephemeral --color never -s read-only -o output.txt
```
For deep/ultra reasoning runs or background logging, pipe through `tee` to avoid block-buffering:
```bash
codex exec "PROMPT" -c model_reasoning_effort="ultra" --skip-git-repo-check --ephemeral --color never -s read-only | tee output.txt
```

### Structured JSON Output (Strict Schema)
Outputs clean JSON directly to stdout (metadata headers route to stderr).
*Note: OpenAI Strict Outputs require `"additionalProperties": false` on objects.*
```bash
codex exec "PROMPT" --output-schema schema.json --skip-git-repo-check --ephemeral -s read-only
```

### Parse JSON Output Inline
```bash
codex exec "PROMPT" --output-schema schema.json --skip-git-repo-check --ephemeral -s read-only \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['key'])"
```

### Apply Edits Directly to Project
```bash
codex exec "PROMPT" --skip-git-repo-check --ephemeral -s workspace-write --cd /path/to/project
```

### Generate Image (Native Image Tool / ChatGPT)
```bash
codex exec "Generate an image of [DESCRIPTION] and save it as [PATH/TO/IMAGE.png]" \
  --skip-git-repo-check --ephemeral -s workspace-write --cd "$(pwd)"
```

### Vision Input (Analyze Screenshot / Image)
```bash
codex exec "Review this UI screenshot and implement the HTML/CSS" \
  -i /path/to/screenshot.png --skip-git-repo-check --ephemeral -s read-only
```

### Stdin Pipe
```bash
cat file.py | codex exec "Review this code" --skip-git-repo-check --ephemeral -s read-only -
```

## 3. Rules & Handling
- **Always include:** `--skip-git-repo-check --ephemeral` for clean, isolated execution.
- **Sandboxing:** Default to `-s read-only`. Only use `-s workspace-write` when file edits or image savings are explicitly needed.
- **Image Destination:** Always specify the full target file path in the prompt (e.g. `"save it as ./assets/logo.png"`).
- **Clean output:** Use `-o <file>` or `--output-schema` when you need response text/data without terminal metadata.
- **Unbuffered logging:** When capturing output in background tasks or deep reasoning runs (`ultra`), avoid raw redirection `> output.txt` which block-buffers stdout until exit. Use `| tee output.txt` (or `-o <file>`) so logs update incrementally in real time and do not trip inactivity watchdogs.
