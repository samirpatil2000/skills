"""Per-prediction telemetry -> one report.json (schema "replicate-telemetry/1").

    tel = Telemetry(model="owner/name", inputs={...})       # Secrets must not be passed in
    with tel.phase("stage 1", kind="gpu"):
        ...
    tel.add_output(path); tel.data["delivery"] = {...}
    report_path = tel.write(out_dir / "report.json")

Phase kinds: gpu | cpu | io | network | wall (an umbrella span, not summed). Phases may overlap (parallel output writers); totals.wall_s is the
real elapsed time. A background thread samples GPU utilisation and memory every 0.5 s through NVML
(package nvidia-ml-py); without NVML the util fields are null. Not covered: coglet's upload of the returned
files after predict() returns -> derive it as Replicate metrics.predict_time - totals.wall_s.
Shared with the LumaFlux project; keep the schema stable.
"""

import json
import os
import platform
import threading
import time
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path

import torch

SCHEMA = "replicate-telemetry/1"
SAMPLE_INTERVAL_S = 0.5


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds")


class _GpuSampler(threading.Thread):
    def __init__(self):
        super().__init__(daemon=True)
        self.samples: list[tuple[float, int, float]] = []  # (t, util %, mem used GB)
        self._halt = threading.Event()
        self.ok = False
        try:
            import pynvml

            pynvml.nvmlInit()
            self._nvml = pynvml
            self._handle = pynvml.nvmlDeviceGetHandleByIndex(0)
            self.ok = True
        except Exception:
            self._nvml = None

    def run(self):
        while self.ok and not self._halt.is_set():
            try:
                u = self._nvml.nvmlDeviceGetUtilizationRates(self._handle).gpu
                m = self._nvml.nvmlDeviceGetMemoryInfo(self._handle).used / 2**30
                self.samples.append((time.monotonic(), int(u), round(m, 2)))
            except Exception:
                pass
            self._halt.wait(SAMPLE_INTERVAL_S)

    def stop(self):
        self._halt.set()

    def window(self, t0: float, t1: float):
        sel = [s for s in self.samples if t0 <= s[0] <= t1]
        if not sel:
            return None, None, None
        utils = [s[1] for s in sel]
        return round(sum(utils) / len(utils), 1), max(utils), max(s[2] for s in sel)


class Telemetry:
    def __init__(self, model: str, inputs: dict):
        self._t0 = time.monotonic()
        self._lock = threading.Lock()
        self._windows: list[tuple[float, float]] = []
        self._gpu = _GpuSampler()
        self._gpu.start()
        cuda = torch.cuda.is_available()
        self.data = {
            "schema": SCHEMA,
            "model": model,
            "started_at": _now_iso(),
            "finished_at": None,
            "hardware": {
                "gpu_name": torch.cuda.get_device_name(0) if cuda else None,
                "vram_gb": round(torch.cuda.get_device_properties(0).total_memory / 2**30, 1) if cuda else None,
                "cpu_count": os.cpu_count(),
                "ram_gb": round(os.sysconf("SC_PAGE_SIZE") * os.sysconf("SC_PHYS_PAGES") / 2**30, 1),
                "torch": torch.__version__,
                "python": platform.python_version(),
                "nvml": self._gpu.ok,
            },
            "inputs": inputs,
            "media": {},
            "phases": [],
            "totals": {},
            "outputs": [],
            "delivery": None,
            "notes": [],
            "errors": [],
        }

    @contextmanager
    def phase(self, name: str, kind: str):
        cuda = torch.cuda.is_available()
        if cuda:
            torch.cuda.reset_peak_memory_stats()
        t0 = time.monotonic()
        try:
            yield
        finally:
            if cuda and kind == "gpu":
                torch.cuda.synchronize()
            t1 = time.monotonic()
            avg, mx, mem = self._gpu.window(t0, t1)
            entry = {
                "name": name,
                "kind": kind,
                "start_s": round(t0 - self._t0, 2),
                "seconds": round(t1 - t0, 2),
                "gpu_util_avg": avg,
                "gpu_util_max": mx,
                "gpu_mem_used_max_gb": mem,
                # torch-allocated peak; only meaningful for phases that do not overlap with other GPU work
                "vram_peak_gb": round(torch.cuda.max_memory_allocated() / 2**30, 2) if cuda else None,
            }
            with self._lock:
                self.data["phases"].append(entry)
                if kind == "gpu":
                    self._windows.append((t0, t1))

    def add_span(self, name: str, kind: str, t0: float, t1: float):
        """Record a phase measured elsewhere (time.monotonic() stamps), e.g. inside a library call."""
        avg, mx, mem = self._gpu.window(t0, t1)
        with self._lock:
            self.data["phases"].append({
                "name": name, "kind": kind, "start_s": round(t0 - self._t0, 2), "seconds": round(t1 - t0, 2),
                "gpu_util_avg": avg, "gpu_util_max": mx, "gpu_mem_used_max_gb": mem, "vram_peak_gb": None,
            })
            if kind == "gpu":
                self._windows.append((t0, t1))

    def add_output(self, path: Path, seconds: float | None = None, **info):
        p = Path(path)
        self.data["outputs"].append({"file": p.name, "bytes": p.stat().st_size, "seconds": seconds, **info})

    def note(self, msg: str):
        self.data["notes"].append(msg)

    def _gpu_busy_seconds(self) -> float:
        # union of gpu-phase windows (phases can overlap)
        total, end = 0.0, None
        for a, b in sorted(self._windows):
            if end is None or a > end:
                total += b - a
                end = b
            elif b > end:
                total += b - end
                end = b
        return total

    def write(self, path: Path) -> Path:
        self._gpu.stop()
        wall = time.monotonic() - self._t0
        by_kind = {}
        for p in self.data["phases"]:
            if p["kind"] == "wall":
                continue
            by_kind[p["kind"]] = by_kind.get(p["kind"], 0.0) + p["seconds"]
        gpu_s = self._gpu_busy_seconds()
        util = [s[1] for s in self._gpu.samples]
        self.data["totals"] = {
            "wall_s": round(wall, 2),
            "gpu_s": round(gpu_s, 2),
            "cpu_s": round(by_kind.get("cpu", 0.0), 2),
            "io_s": round(by_kind.get("io", 0.0), 2),
            "network_s": round(by_kind.get("network", 0.0), 2),
            "gpu_busy_share": round(gpu_s / wall, 3) if wall else None,
            "gpu_util_avg_whole_run": round(sum(util) / len(util), 1) if util else None,
            "note": "cpu/io/network sums can exceed wall_s when phases run in parallel",
        }
        self.data["finished_at"] = _now_iso()
        path = Path(path)
        path.write_text(json.dumps(self.data, indent=1))
        return path
