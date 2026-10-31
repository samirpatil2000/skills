# Optimizations and cost (Replicate, Oct 2026)

Do these only when they solve a measured problem; measure first on the real GPU.

## Billing facts
- Public model: you pay only active prediction time. Setup and idle are free.
- Private model and deployments: setup + idle + active are all billed.
- Image pull / container boot are not billed; `setup()` is (for private).
- Prices ($/s): gpu-h100 0.001525 (80 GB, 144 GB RAM), gpu-a100-large 0.0014 (80 GB), gpu-l40s 0.000975
  (48 GB, 65 GB RAM), gpu-t4 0.000225 (16 GB). 2x SKUs only help if the code uses 2 GPUs.
- Cost per job = time × price. A faster GPU is often cheaper per job (H100 was cheapest per LTX job).
- Always-warm (`min_instances=1` deployment) costs ~ $3.6–4k/month for one 80 GB GPU.

## Limits
- Platform `setup()` limit ~10 min (enterprise: up to 3 h). Prediction limit 30 min.
- Outputs, inputs and logs are deleted after 1 hour.

## Cold boot
- Slim image + pget in `setup()` beats baking large weights: smaller push, no layer decompression.
  Measured: 47 GB of HF weights + boot = 2–4 min total on H100.
- Bake only small (< ~5 GB) weights, or gated weights in private images.
- Public-model trick: setup is free, so read the big checkpoint once in `setup()` to warm the page cache
  (only if node RAM > checkpoint size; skip on 65 GB L40S nodes).
- Cog base images (`r8.im/cog-base:cudaX-pythonY`) are already on Replicate: their layers are not
  uploaded and are likely cached on nodes. Choose a CUDA/Python/Torch combination that has one.

## Image size / push
- Split installs into ≤ ~2.5 GB layers (also makes re-pushes after dependency changes partial).
- Code-only changes re-push one tiny layer.
- `--use-cuda-base-image false` has NO effect in cog 0.23.0 with `gpu: true` + `cuda:` set (LumaFlux,
  verified: the CUDA base layers stayed, image 21.4 GB). Do not rely on it.

## GPU sizing
- Use the model's own VRAM table; derive a frames × pixels budget and enforce it in code with a clear error.
- fp8 weight casting (e.g. FP8_CAST) halves transformer VRAM on Ada/Hopper/Ampere(cast-only).

## Choosing hardware by cost (formula and test plan)
Check https://replicate.com/pricing before each decision; prices change.

- Cost per prediction (public model) = `predict_time` (s) × $/s of the GPU SKU.
- Cost per prediction (private model) = (`setup` + idle + `predict_time`) × $/s. Keep idle low, or use a
  fast-booting fine-tune.
- Break-even: a faster, pricier GPU wins when its speedup is larger than the price ratio.
  Example (Oct 2026): H100 0.001525 $/s vs A100 0.0014 $/s. The H100 is cheaper per job if it runs at
  least ~9% faster than the A100 on the same input.
- Memory gate before any run: check the model's VRAM table and the host RAM of each SKU. Record the
  SKU-specific limits in the project's `docs/RESEARCH.md`.
- Do not assume a SKU works. Measure each candidate on the same representative inputs, then compare
  `predict_time × $/s`.
- Test plan: run the same small set of inputs on each candidate SKU. Record `predict_time`, peak VRAM,
  output checks. Ask the user before any paid test run on a new SKU.

## Concurrency inside one GPU
- Before threading one model object, check for per-call state written to `self`
  (e.g., LTX `_diffusion_registry.clear()`, LumaFlux shared context dict). If present, threads are unsafe.
- Batching shares weights safely but gains little when one item already saturates the GPU
  (1080p video diffusion). Measure GPU utilization first.
- Long inputs: either cap them (simple, predictable) or chunk with overlap + cross-fade (more cost,
  seam risk). Decide with the user.
