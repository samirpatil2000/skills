# Error modes → cause → fix

Verified with Cog v0.23.0, Docker Engine 29 in WSL2 Ubuntu 26.04, Windows 11, Replicate (Oct 2026).
"(LumaFlux)" = found in the parallel LumaFlux project. "UNVERIFIED" = reported, not reproduced.
Grep this file for a fragment of the error text.

## Contents
1. Toolchain / WSL
2. cog build
3. cog predict / local runtime
4. cog push
5. Replicate predictions
6. Claude Code session issues

## 1. Toolchain / WSL

| Symptom | Cause | Fix |
|---|---|---|
| `could not select device driver "" with capabilities: [[gpu]]` | nvidia-container-toolkit missing; `cog predict` with `gpu: true` passes `--gpus all` | Install toolkit, `nvidia-ctk runtime configure --runtime=docker`, restart docker (scripts/wsl_setup.sh) |
| `The command 'docker' could not be found in this WSL 2 distro` | Docker Desktop installed but no engine in the distro | Install Docker Engine in WSL (wsl_setup.sh) and do not also enable Desktop WSL integration for that distro |
| Path like `C:/Program Files/Git/mnt/c/...: No such file` | Git Bash rewrites `/mnt/...` arguments | `MSYS_NO_PATHCONV=1 wsl ...` |
| `$PWD` / exit codes wrong inside `wsl -- bash -lc "..."` from PowerShell (LumaFlux) | quoting/escaping across shells | Put the logic in a `.sh` file and run `wsl -d Ubuntu -u root -- bash /mnt/c/.../x.sh` |
| WSL VM restarted, `/tmp` files gone | memory pressure; WSL `/tmp` is tmpfs | Write logs to `/root/...`; drop caches; avoid parallel heavy jobs |
| Windows free RAM near 0 during docker work | WSL page cache is counted as used by Windows (vmmem) | `sync; echo 3 > /proc/sys/vm/drop_caches` in WSL; optionally `.wslconfig` memory limit (shared setting) |

## 2. cog build

| Symptom | Cause | Fix |
|---|---|---|
| `cannot resolve type 'X' (imported from 'cog') - external types cannot be statically analyzed` | `from cog import Path as X` alias; cog 0.23 schema is static | Import cog types by their real names; use `import pathlib` for local paths |
| `parameter 'p': choices expression cannot be statically resolved` | `choices=list(DICT)` or `le=CONSTANT` in `Input()` | Use literal lists/numbers in `Input()` |
| `Predictor.predict() is deprecated; use run() instead` | cog ≥0.20 renamed predict/BasePredictor → run/BaseRunner | Warning only; `predict:` still works on Replicate (verified). New projects can use `run: run.py:Runner` |
| `ERROR: Cannot install ... X depends on Y>=...` (LumaFlux) | pins chosen by date conflict | Resolve before building: `pip install --dry-run --report` / `uv pip compile` in a matching python container |
| `/bin/sh: 1: pip: not found` in build.run (LumaFlux) | no cog base image for that CUDA/Python/Torch combo → uv-managed python without a `pip` binary | Use `uv run pip install --break-system-packages ...` in build.run, or `python -m pip`. With a cog base image (e.g. cuda12.8-python3.12, torch 2.8) plain `pip` works |
| `Could not find a suitable base image ... (CUDA: 12.8 / Python: 3.11 / Torch: 2.11.0)` (LumaFlux) | no prebuilt cog base image for new torch | Works, but the image is bigger and cannot reuse cached base layers. Prefer a supported torch version. `--use-cuda-base-image false` does NOT help (see below) |
| Upstream package pulls wrong CUDA wheels (e.g. cu132 index in its uv config) | project's own index pins | Install torch yourself first, then `pip install --no-deps "pkg @ git+https://...@<commit>#subdirectory=..."` |
| `ERROR: ... load .dockerignore ... no access allowed to dir "context"` in the final stage | cosmetic, in cog's schema-label stage | Ignore if the build ends with `Image built as ...` |
| `ModuleNotFoundError` for project modules in `python scripts/x.py` (LumaFlux) | `sys.path[0]` is the script folder | `sys.path.insert(0, str(Path(__file__).resolve().parent.parent))` or `python -m scripts.x` |
| Confusing imports for `weights.py` + `weights/` folder (LumaFlux) | module vs namespace package with the same name | Name the folder differently (e.g. `model-cache/`) |
| Image still ~21 GB with `--use-cuda-base-image false` (LumaFlux, verified) | in cog 0.23.0 with `gpu: true` + `cuda:` set, the flag has no effect: the CUDA apt layers (5.99 + 3.11 + 1.05 GB) stay | Do not use it as a size fix; split pip layers instead (≤ 2.1–2.4 GB layers pushed fine in both projects) |
| Library needs a module that is not a declared dependency (e.g. cv2 in an optional helper) | optional imports | Grep the call path; write your own small helper instead of adding big deps |

## 3. cog predict / local runtime

| Symptom | Cause | Fix |
|---|---|---|
| Predict-time `logging` lines missing (setup lines visible) | coglet swaps `sys.stderr` per prediction; handler bound to the old stream | `_CurrentStderrHandler` (patterns.md) |
| `print()` inside predict not shown by `cog predict` / `cog run` (LumaFlux) | the CLI shows only setup + subprocess output | Check the `logs` field over HTTP (scripts/http_predict.py) |
| `cog predict` prints huge base64 JSON, no files written | local runs have no upload URL | Decode the JSON, or use scripts/http_predict.py |
| `cog serve: unknown shorthand flag 'e'` | `cog serve` has no env flag | `docker run -d --gpus all -p 127.0.0.1:5055:5000 -e VAR=1 <tag>` then POST `/predictions` |
| `invalid build.python_requirements "requirements.txt": file does not exist` | `cog predict` run from another directory | Run from the project dir (or `-f path/cog.yaml` plus correct cwd) |
| HTTP POST with a local path input fails (LumaFlux) | the server does not read local paths | Send `data:<mime>;base64,...` for small files |
| Output video shorter than expected after audio mux | ffmpeg `-shortest` with audio slightly shorter than video | `-af apad -shortest` (video sets the length) |
| Odd width/height fails in yuv420p writers (LumaFlux) | 4:2:0 needs even dimensions | Round to even (or ×32 for diffusion models) only for video outputs |
| Python `round()` gives smaller sizes than expected (22.5 → 22) | banker's rounding | `math.floor(x + 0.5)` |

## 4. cog push

| Symptom | Cause | Fix |
|---|---|---|
| `a CLI auth token. Please fetch a token from https://replicate.com/auth/token` then `authorization failed` | `cog login` does not accept `r8_` API tokens | `cat token \| docker login r8.im -u <owner> --password-stdin` |
| `error during image push: use of closed network connection` (one layer `Retrying` then fails) | one very large layer (a 7.11 GB pip layer failed; ≤ 2.4 GB layers pushed fine) | First retry the push once (finished layers stay uploaded; a 2.66 GB torch layer failed once, then pushed on retry — LTX-2.5, 2026-10-16). If the same layer fails again: set `"max-concurrent-uploads": 1` in /etc/docker/daemon.json and `systemctl restart docker`, then push again (ExMR 2026-10-24: a 2.19 GB cuDNN layer failed twice with the default concurrency, then pushed with 1; no rebuild needed). Last resort: split installs into several `build.run` steps (patterns.md) - this rebuilds and re-uploads every later layer. Check sizes: `docker history --format "{{.Size}} {{.CreatedBy}}" <tag> \| sort -h -r \| head` |
| Push process dies silently, Windows free RAM ~0 | `COG_PUSH_OCI=1` exports the full image → page cache fills the WSL VM | Do not use OCI push on small-RAM machines; split layers instead |
| 403 on blob upload (cog #2093) | Docker containerd image store | `/etc/docker/daemon.json`: `{"features":{"containerd-snapshotter":false}}` |
| `unknown blob` on push (cog #3164, open) | UNVERIFIED | Retry; check the issue |
| Push "stopped because the system is running low on memory" | Claude Code background-shell memory reaper | scripts/push_detached.sh, or user runs the push in their own terminal |

## 5. Replicate predictions

| Symptom | Cause | Fix |
|---|---|---|
| Outputs are `data:video/mp4;base64,...` in the API JSON | `Path` fields inside a `BaseModel` output are inlined (coglet output.rs) — only top-level Path / IOBase / list/tuple are uploaded | Return `Path` or `List[Path]` |
| Output list order differs from the order predict() returned | coglet appends each URL when its upload finishes (parallel uploads) | Never rely on list order; give files distinct names and match by name |
| Python worker killed, API `status: failed, error: Worker crashed`, next POST `409 Conflict` | OOM kill inside the container (check `dmesg`); the slot is poisoned until restart | Smaller local test inputs; on Replicate nodes RAM is large (H100 node reported 2 TB, 128 CPUs) |
| `HTTP Error 403: Forbidden` from Python urllib on api.replicate.com | default `Python-urllib` User-Agent blocked | Send any `User-Agent` header |
| `UnicodeEncodeError: 'charmap' codec` printing logs on Windows | cp1252 console | `sys.stdout.reconfigure(encoding="utf-8", errors="replace")` |
| `latest_version: None` on the model | nothing pushed yet / push failed | Check push log for the `digest:` line |
| Prediction killed at 30 min | Replicate prediction timeout | Cap inputs by a time estimate and fail fast with the max input that fits (LumaFlux pattern) |
| `setup()` killed | platform setup limit ~10 min (enterprise can raise); old coglet had 300 s | cog ≥ 0.17; keep download + load < 10 min; measure `total_time - predict_time` |
| Gated HF file 401/403 | token lacks gate approval or fine-grained permission | User clicks "Agree" on the repo; token needs "read access to public gated repos". `X-Error-Code: GatedRepo` header explains it |

## 6. Claude Code session issues

| Symptom | Cause | Fix |
|---|---|---|
| Background task killed for low memory; told not to restart | memory reaper | Ask the user; run detached or in their terminal; `CLAUDE_CODE_DISABLE_BG_SHELL_PRESSURE_REAP=1` must be set when starting Claude Code |
| `sleep N && check` blocked | harness forbids sleep-polling | Use Monitor with an until-loop, or a background command that waits for a marker in the log |
| `pkill -f pattern` kills your own shell (exit 15) | pattern matches the pkill command line itself | Use a more specific pattern or `pgrep` + kill by PID |
| pyenv-win `python -c "multi\nline"` → `|| goto :error` IndentationError | Windows .bat shim breaks newlines in args | `python - <<'EOF' ... EOF` |
| Image input on Replicate goes down the video path (e.g. a 1-frame mp4 instead of a PNG) (LumaFlux) | Replicate/coglet passes input files to `run()` without the original file extension, so `input.suffix` checks fail | Detect the input type by content: `PIL.Image.open` (format in PNG/JPEG/WEBP/BMP/TIFF and `n_frames == 1`) or ffprobe `format_name`, not by extension |
| Watcher says "already running" but nothing runs (LumaFlux) | `pgrep -f <name>` matched the watcher's own or the wsl wrapper's command line | Store the job PID in a file (`echo $! > job.pid`) and test it with `kill -0 $(cat job.pid)` |
| `--use-cuda-base-image false` has no effect (LumaFlux, cog 0.23.0, `gpu: true` + `cuda:` set) | Cog still builds on the CUDA base image (apt layers 6.0 + 3.1 + 1.1 GB); image grew to 21.4 GB | Do not count on this flag to make the image smaller; it is not a fix for push failures (split pip layers are) |
| `HTTP Error 429: Too Many Requests` from api.replicate.com during a sweep (LumaFlux) | Prediction creates + 5 s polls (+ another session polling the same account) hit the API rate limit | Wrap API calls in a retry with backoff (honor `Retry-After`, else 5·2^n s, max 60 s); poll every 10 s; make sweeps resumable (skip configs that already succeeded on the same version) |

| Symptom | Cause | Fix |
|---|---|---|
| `CUDA out of memory` in a batched text-encoder forward (ltx-2_3-gemma-encoder, L40S, batch 16) | Gemma 3 12B at 1024 padded tokens needs ~0.7 GB per prompt on top of 30 GB weights | Default small batches and halve the batch after `torch.OutOfMemoryError` (free the failed batch outside the `except` block first) |
