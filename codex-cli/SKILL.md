---
name: codex-cli
description: >
  Delegate tasks to the locally installed Codex CLI (`codex exec`).
  Supports reasoning tiers (low to ultra), native image generation,
  vision input (-i), and sandboxed execution.
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

### Structured JSON Output (Strict Schema)
```bash
codex exec "PROMPT" --output-schema schema.json --skip-git-repo-check --ephemeral --color never -s read-only -o output.json
```

### Python Programmatic Extraction (e.g. data generation scripts)
```python
import subprocess, json, tempfile

with tempfile.NamedTemporaryFile(suffix=".json") as tmp:
    cmd = [
        "codex", "exec",
        "--skip-git-repo-check", "--ephemeral", "--color", "never",
        "-s", "read-only",
        "-o", tmp.name,
        prompt
    ]
    subprocess.run(cmd, check=True)
    raw = open(tmp.name).read()
    start, end = raw.find('{'), raw.rfind('}')
    data = json.loads(raw[start:end+1])
```

## 3. Rules & Handling
- **Always include:** `--skip-git-repo-check --ephemeral` for clean, isolated execution.
- **Sandboxing:** Default to `-s read-only`. Only use `-s workspace-write` when file edits or image savings are explicitly needed.
- **Image Destination:** Always specify the full target file path in the prompt (e.g. `"save it as ./assets/logo.png"`).
- **Clean output:** Use `-o <file>` when you need the response text without terminal metadata.
