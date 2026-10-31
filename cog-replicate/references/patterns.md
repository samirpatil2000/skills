# Patterns (copy, then adapt)

Working reference project: `D:\Desktop\projects\models\ltx-2_3-hdr` (LTX-2.3 HDR, 47 GB weights, gated LoRA,
verified on Replicate H100). Read its `cog.yaml`, `predict.py`, `weights.py`, `hdr_io.py`, `tests/` for a full example.

## Contents
1. cog.yaml
2. predict.py skeleton
3. weights.py (pget + gated HF)
4. Mock mode
5. Tests
6. .dockerignore / .gitignore
7. Precomputed prompt embeddings (no text encoder at run time)

## 1. cog.yaml

```yaml
build:
  gpu: true
  cuda: "12.8"            # match a cog base image: r8.im/cog-base:cuda12.8-python3.12 exists for torch 2.8
  python_version: "3.12"
  system_packages: ["git", "ffmpeg"]
  # No python_requirements: one big `pip install -r` layer (7 GB) fails to push to r8.im.
  # Each run step is its own layer; keep each <= ~2.5 GB. Pins = torch's own requires.
  run:
    - curl -fsSL -o /usr/local/bin/pget "https://github.com/replicate/pget/releases/download/v0.11.1/pget_Linux_x86_64" && chmod +x /usr/local/bin/pget
    - pip install --no-cache-dir nvidia-cudnn-cu12==9.10.2.21 nvidia-cuda-runtime-cu12==12.8.90 nvidia-cuda-nvrtc-cu12==12.8.93 nvidia-cuda-cupti-cu12==12.8.90
    - pip install --no-cache-dir nvidia-cublas-cu12==12.8.4.1 nvidia-cusparselt-cu12==0.7.1 nvidia-nccl-cu12==2.27.3
    - pip install --no-cache-dir nvidia-cusolver-cu12==11.7.3.90 nvidia-cusparse-cu12==12.5.8.93 nvidia-cufft-cu12==11.3.3.83 nvidia-curand-cu12==10.3.9.90 nvidia-nvjitlink-cu12==12.8.93 nvidia-nvtx-cu12==12.8.90 nvidia-cufile-cu12==1.13.1.3
    - pip install --no-cache-dir --extra-index-url https://download.pytorch.org/whl/cu128 torch==2.8.0+cu128 triton==3.4.0
    - pip install --no-cache-dir --extra-index-url https://download.pytorch.org/whl/cu128 torchvision==0.23.0+cu128 torchaudio==2.8.0+cu128
    - pip install --no-cache-dir "transformers==X" "huggingface-hub>=1.5,<2.0" accelerate safetensors ... pytest
    - pip install --no-cache-dir --no-deps "pkg @ git+https://github.com/org/repo.git@<commit>#subdirectory=packages/pkg"
    - python -c "import torch, pkg; print(torch.__version__)"   # import errors fail the build, not prediction #1
predict: "predict.py:Predictor"
```

Notes
- Get the nvidia pins for another torch version from the built image:
  `python -c "import importlib.metadata as m; print(m.requires('torch'))"`.
  Find big layers: `docker history --format "{{.Size}} {{.CreatedBy}}" <tag> | sort -h -r | head`.
- `pip` in build.run works with a cog base image. Without one (unsupported torch), use
  `uv run pip install --break-system-packages ...` (see errors.md).
- Source files are NOT available during `build.run`; inline package lists there.
- Pin git deps to a commit, not a branch.

## 2. predict.py skeleton

```python
import logging, os, pathlib, sys
from typing import List, Optional
import torch
from cog import BasePredictor, Input, Path, Secret   # real names only: no "Path as X"
import weights

class _CurrentStderrHandler(logging.StreamHandler):
    """coglet swaps sys.stderr per prediction; resolve it on every write."""
    @property
    def stream(self):
        return sys.stderr
    @stream.setter
    def stream(self, _value):
        pass

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s",
                    handlers=[_CurrentStderrHandler()])
logger = logging.getLogger("predict")
MOCK = os.environ.get("MODEL_MOCK") == "1"
OUT_DIR = pathlib.Path("/tmp/outputs")

class Predictor(BasePredictor):
    def setup(self) -> None:
        self.pipeline = None
        if MOCK:
            return
        self.paths = weights.download_public()          # pget, size-checked, skip if present
        # optional: read the big checkpoint once into page cache (setup time is free on public models)

    def predict(
        self,
        image: Path = Input(description="..."),
        hf_token: Secret = Input(description="HF read token with access to <gated repo>"),
        size: str = Input(choices=["512", "1024"], default="512"),   # literals only
        seed: Optional[int] = Input(default=None),
    ) -> List[Path]:                                    # List[Path]/Path -> uploaded URLs
        token = hf_token.get_secret_value()
        weights.check_gated_access(token)               # every call: cached model != access
        if not MOCK and self.pipeline is None:
            self._load_pipeline(token)                  # downloads gated files with caller token
        ...
        return [Path(OUT_DIR / "a.mp4"), Path(OUT_DIR / "b.mp4")]
```

Why each rule
- `List[Path]` not `BaseModel`: coglet uploads only top-level Path / IOBase / list / tuple; Path fields
  in a BaseModel become base64 data URIs (coglet `output.rs`, `predictor.rs`). Use clear file names
  because list items have no field names.
- Literal `choices`/`ge`/`le`: cog 0.23 builds the schema by static analysis.
- Token check on every call: once the pipeline is cached, a later caller without access would
  otherwise use the gated weights.
- Clean `OUT_DIR` at the start of each prediction.

## 3. weights.py (pget + gated HF)

```python
PUBLIC_FILES = {"model.safetensors": 46_149_345_334}   # exact bytes from the HF API
def download_public():
    missing = [n for n, s in PUBLIC_FILES.items() if not _complete(WEIGHTS_DIR / n, s)]
    manifest = "".join(f"https://huggingface.co/{REPO}/resolve/{REV}/{n} {WEIGHTS_DIR / n}\n" for n in missing)
    subprocess.run(["pget", "multifile", "-", "--log-level", "warn"], input=manifest.encode(), check=True)
    # verify sizes again after download

def check_gated_access(token):
    r = requests.head(f"https://huggingface.co/{GATED}/resolve/main/{SMALL_FILE}",
                      headers={"Authorization": f"Bearer {token}"}, allow_redirects=False, timeout=20)
    # 200/302/307 ok; 401 invalid token; 403 gate not accepted (X-Error-Code: GatedRepo)

def download_gated(token):
    hf_hub_download(GATED, name, token=token, local_dir=GATED_DIR)   # small files: fine
```

- Gated LFS files: a HEAD with the token and `allow_redirects=False` returns 302 with a signed CDN URL
  that needs no auth → pget can download it fast (LumaFlux). Small non-LFS files return 307 to a
  relative path → use requests/hf_hub_download.
- The gated repo's file list is public: `GET https://huggingface.co/api/models/<repo>` (siblings).
- On Replicate, HF traffic goes through an internal proxy (`hermes.services.svc.cluster.local`);
  47 GB downloaded within a 2–4 min cold boot.

## 4. Mock mode

`MODEL_MOCK=1`: setup skips weights; predict keeps input parsing, token check, sizing and the real
output writers, but replaces the model call with a cheap fake (e.g., decode input, expand values).
Run it with `cog predict -e MODEL_MOCK=1 ...` and over HTTP (scripts/http_predict.py).
This catches schema errors, output-type errors (base64!), ffmpeg/audio bugs and token handling
before a paid GPU run.

## 5. Tests (`tests/test_local.py`, run inside the image)

- Imports of the pinned upstream package (catches version drift).
- Output writers: ffprobe codec / pix_fmt / color tags / frame count; image formats and metadata.
- Values outside the display range survive (e.g., EXR > 1.0) if the model is HDR.
- Sizing and frame rules (multiples of 32/64, 8k+1 frames, VRAM caps).
- Return annotation is a list: `typing.get_origin(inspect.signature(Predictor.predict).return_annotation) is list`.

## 6. Ignore files

`.dockerignore`: `.secrets/ weights/ outputs/ samples/ docs/ *.safetensors *.mp4 *.zip .cog/ __pycache__/`
`.gitignore`: `.secrets/ outputs/ samples/`

## 7. Precomputed prompt embeddings (no text encoder at run time)

Reference projects: `D:\Desktop\projects\models\ltx-2_3-gemma-encoder` (encoder model) and
`D:\Desktop\projects\models\ltx-2_3-relight` (consumer, 96 fixed captions). Status 2026-10-23: built and
verified on Replicate (encoder L40S, relight H100; self-check diff 0.0).

When: the pipeline loads a large text encoder only to encode prompts, and the prompt set is finite.
- Make a separate small Cog model that runs the upstream encoder code exactly (same pinned commit) and
  returns the embeddings as a file. Run it once; commit the file to the consumer repo if it is small.
- Store the smallest stage that is exact. LTX-2.3: Gemma hidden states -> feature extractor -> connectors ->
  context. The connectors replace padded tokens with learnable registers, so the feature-extractor output
  of the REAL tokens only (~0.3 MB/prompt) is lossless; the full 1024-token context is 12.6 MB/prompt.
  The consumer runs the small connectors from its own checkpoint.
- Prove the equivalence: a unit test on a tiny random module, plus a `self_check` field in report.json
  that compares the upstream full path with the shortcut on the real model.
- Swap the encoder out without forking upstream: replace the module-level name the pipeline class looks up
  (`ltx_pipelines.ic_lora.PromptEncoder = Stub`) before building it, and add a test that the name is still
  looked up globally (`"PromptEncoder" in Pipeline.__init__.__code__.co_names`).
- Encoder weights that live inside a huge checkpoint: read the safetensors header with HTTP range requests
  and download only the needed tensors into a small safetensors file with the same `__metadata__`
  (LTX-2.3 text stack: 262 tensors, 5.9 GB of 46 GB). Test it with two small real tensors (`-m network`).
- Fixed captions belong in code (`prompts.py`) and in the model's `choices`; build the caption from the
  inputs (e.g. direction from an angle) so callers cannot send a prompt that has no embedding.
