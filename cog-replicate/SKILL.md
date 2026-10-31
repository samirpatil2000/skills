---
name: cog-replicate
description: Package an ML model (diffusion, video, LLM, any PyTorch/HF model) with Replicate Cog and push it to Replicate, from a Windows machine through WSL2 — toolchain setup (Docker Engine, nvidia-container-toolkit, cog), cog.yaml and predict.py patterns, large weights with pget, gated Hugging Face weights with per-caller tokens, local mock testing without a big GPU, pushing big images to r8.im, running and verifying predictions over the Replicate API, plus a catalogue of known error modes and fixes. Use this skill whenever the user wants to "set up a model with cog", "push to replicate", "deploy a model on replicate", write or fix a cog.yaml / predict.py / run.py, debug a failing cog build, cog push or Replicate prediction, or asks about cold boots, weights, or GPU choice on Replicate — even if they only name the model and say "make it run on Replicate".
---

# Cog → Replicate

Replicate runs a Docker image that Cog builds from `cog.yaml` + `predict.py`. The local machine is
usually only a **build-and-push box**: it does not need a GPU that can run the model. Plan for this split
from the start, because most of the pain is in the build/push/weights logistics, not in the model code.

Read the reference files when you reach the matching step:
- `references/patterns.md` — copy-ready `cog.yaml`, `predict.py`, `weights.py` patterns and why each line exists.
- `references/errors.md` — error text → cause → fix. Search it (grep) the moment a build, push or prediction fails.
- `references/optimizations.md` — cold boot, billing, GPU choice, image size, concurrency.

Scripts (run them, do not re-invent them):
- `scripts/wsl_setup.sh` — one-time toolchain inside WSL Ubuntu (Docker Engine, buildx, nvidia-container-toolkit, cog).
- `scripts/push_detached.sh <project_dir> <r8.im/owner/model>` — push that survives the Claude Code memory reaper.
- `scripts/http_predict.py` — local end-to-end test against `docker run` of the built image (shows the `logs` field).
- `scripts/run_replicate.py` — create a prediction on Replicate, stream logs, download outputs, check HTTP 200.

## 0. Before you start: facts to collect

Collect these first; each one changes the design:

1. **Machine**: OS, local GPU VRAM, RAM, free disk on each drive, whether WSL2/Docker exist.
   On Windows, Cog runs only inside WSL2. A 4–8 GB local GPU is fine — it is only used for smoke tests.
2. **Model weights**: exact repos, file names, byte sizes (HF API `?blobs=true`), license, gated or not.
   Pin a code revision (git tag/commit) of the inference repo — upstream `main` moves (example: LTX-2 `main`
   switched the HDR pipeline to a different model family; the 2.3 LoRA needed tag v1.3.0).
3. **Text encoder**: does the pipeline load a big text encoder (LTX-2.3: Gemma 3 12B, 24 GB, gated by
   Google)? Does the repo ship precomputed embeddings (LTX HDR LoRAs: `*-scene-emb.safetensors`)? If the
   prompt set is finite (fixed captions, dropdowns), precompute once and keep the encoder out of the
   runtime image — patterns.md §7. Hosted chat APIs (AI Studio, Replicate, fal) return text, not the
   hidden states that diffusion models condition on.
4. **Target GPU and VRAM need** (see `references/optimizations.md`). Check the model's own VRAM table.
5. **Replicate**: owner/model name, public or private (billing differs a lot), API token.
6. **Shared machine?** If another Claude session uses the same Docker/WSL, agree who changes shared
   state (daemon.json, .wslconfig, WSL restarts, prune) and tell each other before builds/pushes —
   two parallel builds/pushes on a 6 GB WSL VM run out of memory.

Write findings to a local `docs/RESEARCH.md` as you go; long sessions get compacted.

## 1. Toolchain (one time, WSL2)

Run `scripts/wsl_setup.sh` as root inside the distro (`wsl -d Ubuntu -u root -- bash /mnt/c/.../wsl_setup.sh`).
It installs Docker Engine (not Docker Desktop), buildx, nvidia-container-toolkit, cog, and sets
`containerd-snapshotter: false` (the containerd image store causes 403s on push).
Check: `docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi -L`.

- Keep the distro's ext4.vhdx on a drive with free space (`wsl --manage <distro> --move D:\WSL\<distro>`).
- From Git Bash on Windows, prefix `MSYS_NO_PATHCONV=1` before `wsl ... /mnt/...`, or paths get mangled.
- Login: `cog login --token-stdin` rejects `r8_` API tokens (it wants a CLI token from
  replicate.com/auth/token). This works with the API token:
  `cat token | docker login r8.im -u <owner> --password-stdin`.
- Keep tokens in `<project>/.secrets/` and list `.secrets/` in both `.gitignore` and `.dockerignore`.

## 2. Project files

Start from `references/patterns.md`. The decisions that matter:

- **Weights are not baked** when they are large (> ~5 GB). `setup()` downloads them with `pget`
  (parallel downloader) if missing, with exact size checks. Public HF `resolve/` URLs work directly.
- **Gated weights**: do not bake them into a public image (anyone can pull it) and do not bake a token.
  Take an `hf_token: Secret` input, verify access on every prediction (HEAD on a gated file), download
  on first use, cache the pipeline. `cog.Secret` is not available in `setup()`.
- **Return files as `Path` or `List[Path]`**, never `Path` fields inside a `BaseModel` — cog 0.23 inlines
  those as base64 `data:` URIs instead of uploading them (huge JSON, no download links). The list order is
  NOT preserved on Replicate (uploads finish in any order) — give files distinct names.
- **Telemetry**: return one `report.json` (copy `scripts/telemetry.py`): per-phase time, GPU util/VRAM,
  media info. It is the only way to see where billed GPU time goes.
- **Logging**: coglet swaps `sys.stderr` per prediction; a handler created at import loses predict-time logs.
  Use the `_CurrentStderrHandler` from patterns.md.
- **Mock mode** (`<NAME>_MOCK=1`): skip weights and the model, fake the output tensor, keep the real
  input parsing, token check and output writers. This is how you test end-to-end on a small GPU.
- **Input() values must be literals** (choices, ge, le). Cog 0.23 parses the file statically.
- **Split big pip installs into several `build.run` steps** (each layer ≤ ~2.5 GB). A single 7 GB
  `pip install -r requirements.txt` layer fails to push.

## 3. Local verification (no big GPU needed)

Do these in order; each catches a different class of bug cheaply:

1. **Resolve deps first** (minutes, not a 30-min build): `pip install --dry-run --report` or
   `uv pip compile` in a matching python container.
2. `cog build -t <tag>` (first build 20–40 min). Add a final `build.run` step that imports the model
   package, so import errors fail the build, not the first prediction.
3. Unit tests inside the image: `docker run --rm -v <proj>:/src -w /src <tag> python -m pytest -q tests/`.
   Test the output writers, sizing rules, and the return type (List[Path]).
4. `cog predict -e <NAME>_MOCK=1 -i video=@sample.mp4 -i hf_token=$(cat .secrets/hf_token)`.
   Also run once with a bad token and confirm a clear error.
5. HTTP test (`scripts/http_predict.py`): this is the only way to see predict-time logs locally
   (`cog predict` hides them) and to see exactly what the API returns.

## 4. Push

- Create the model first (web UI replicate.com/create or `POST /v1/models`), choose hardware there.
- Use `scripts/push_detached.sh`. It runs `cog push` with `setsid nohup` inside WSL, keeps one `wsl`
  client attached (WSL stops an idle VM), and drops page caches (WSL page cache counts as used memory
  on Windows). A plain background task in Claude Code can be killed by the memory reaper; Claude Code
  then forbids restarting it without the user's approval — ask the user instead of retrying.
- Re-pushes after code-only changes upload one small layer (seconds).
- If one layer keeps failing ("use of closed network connection"), split it (see errors.md) — do not use
  `COG_PUSH_OCI=1` on a small-RAM machine: it exports the whole image first.

## 5. Run on Replicate and verify

`python scripts/run_replicate.py <owner/model> -i video=@samples/clip.mp4 -s hf_token=@.secrets/hf_token`

The runner cancels a prediction that stays `starting` for 5 minutes (`--start-timeout`, default 300). A stall at
`starting` means the container never booted (image pull or start), so setup logs never appear. Check the image size
first (`docker history`), not the weights.

- Start with the smallest real input (a 5 s clip, a 512px image). The first prediction includes a cold
  boot (image pull + `setup()`); record `metrics.predict_time` vs `total_time`.
- Success = status `succeeded` AND every output is an `https://replicate.delivery/...` URL that returns
  HTTP 200 AND the files pass a content check (ffprobe: codec, frame count, color tags; image: size).
- Check the content, not only the container: e.g., for HDR, measure values above diffuse white and look
  at frames at negative exposure. A file with the right tags can still be SDR inside.
- Outputs and logs are deleted after 1 hour — download what you need.

## 6. Report back

Tell the user: version id, prediction ids, predict/total time, cost estimate (predict_time × $/s),
output checks, what is still untested. Update `docs/RESEARCH.md` with any new error mode, and add it to
`references/errors.md` of this skill if it is generic.
