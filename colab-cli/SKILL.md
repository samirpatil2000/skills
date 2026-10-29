---
name: colab-cli
description: Run code on Google Colab CPU, GPU (T4, L4, A100, H100), and TPU (v5e1, v6e1) runtimes via `colab`.
---

# Colab CLI Delegation

Remote execution via `colab`. Non-interactive only (`exec`, `run`, `install`). Never run `repl`, `console`, or `drivemount` without a human TTY.

## 1. Hardware Tiers

| Tier | Hardware | Flag | Use |
|---|---|---|---|
| **CPU** | 2 vCPU, 13 GB RAM | *(default)* | Fast scripts, data parsing, testing |
| **GPU Entry** | Nvidia T4 (16 GB) | `--gpu T4` | Inference, light fine-tuning, PyTorch |
| **GPU Mid** | Nvidia L4 (24 GB) | `--gpu L4` | Diffusion, medium LLMs, fast inference |
| **GPU Ultra** | Nvidia A100 / H100 | `--gpu A100` / `--gpu H100` | Heavy training *(paid compute units)* |
| **TPU** | TPU v5e1 / v6e1 | `--tpu v5e1` / `--tpu v6e1` | JAX / PyTorch-XLA workloads |
| **High-RAM** | High memory shape | `--high-mem` | Large dataset processing *(Pro/Pro+)* |

## 2. Recipes

```bash
# One-shot ephemeral job (spins up VM, executes, tears down VM)
colab run --gpu T4 train.py --epochs 10 | tee run.log

# Ephemeral with keep-alive (inspect after finish)
colab run --gpu L4 --keep -s worker script.py

# Persistent session lifecycle (state persists between exec calls)
colab new -s job --gpu T4
colab install -s job torch transformers
colab upload -s job ./data.csv /content/data.csv
colab exec -s job -f train.py | tee train.log
colab download -s job /content/model.pt ./model.pt
colab stop -s job

# Piped stdin / inline execution
echo 'import torch; print(torch.cuda.get_device_name(0))' | colab exec -s job

# Notebook execution (writes output to <name>_output.ipynb)
colab exec -s job -f notebook.ipynb

# Save plots directly to local file
colab exec -s job -f plot.py --output-image plot.png
```

## 3. Rules & Gotchas

- **Always name sessions:** Pass `-s <name>` on `new`/`exec`/`stop`. Omitted names generate random hex IDs.
- **State persists:** Variables and imports survive between `colab exec` calls within the same session. Reset with `colab restart-kernel -s <name>`.
- **Always clean up:** Idle VMs burn units. Always call `colab stop -s <name>`. Prefer `colab run` for self-cleaning jobs.
- **Unbuffered logging:** Always pipe through `| tee output.txt` for long runs to prevent stdout block-buffering.
- **Paths:** Remote working directory is `/content`. Use absolute `/content/...` paths for file operations.
- **Quota/400 errors:** Accelerator unavailable or out of quota → fallback to `--gpu T4` or default CPU. Unrecognized `--gpu` values silently default to A100.
