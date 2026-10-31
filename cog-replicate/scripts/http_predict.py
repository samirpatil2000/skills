"""Local end-to-end test over the Cog HTTP API (shows the predict-time `logs` field, unlike `cog predict`).

Run inside WSL, after `cog build -t <tag>`:
    docker run -d --rm --gpus all -p 127.0.0.1:5055:5000 -e MODEL_MOCK=1 --name cogtest <tag>
    python3 http_predict.py -i video=@samples/clip.mp4 -i resolution=720p -s hf_token=@.secrets/hf_token
    docker logs cogtest; docker stop cogtest

-i key=value      plain input (numbers/true/false are parsed); key=@file sends the file as a data: URI
-s key=@file      secret input read from a file (not echoed)
Writes returned data: URIs to ./http_out/.
"""

import argparse
import base64
import json
import mimetypes
import time
import urllib.request
from pathlib import Path


def parse_value(v: str):
    if v.startswith("@"):
        p = Path(v[1:])
        mime = mimetypes.guess_type(p.name)[0] or "application/octet-stream"
        return f"data:{mime};base64," + base64.b64encode(p.read_bytes()).decode()
    for conv in (int, float):
        try:
            return conv(v)
        except ValueError:
            pass
    return {"true": True, "false": False}.get(v.lower(), v)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--url", default="http://127.0.0.1:5055")
    ap.add_argument("-i", action="append", default=[])
    ap.add_argument("-s", action="append", default=[])
    args = ap.parse_args()

    for _ in range(240):  # wait for setup()
        try:
            with urllib.request.urlopen(args.url + "/health-check", timeout=5) as r:
                status = json.loads(r.read())["status"]
            if status == "READY":
                break
            if status in ("SETUP_FAILED", "DEFUNCT"):
                raise SystemExit(f"server status {status}")
        except OSError:
            pass
        time.sleep(2)

    inputs = {}
    for kv in args.i:
        k, v = kv.split("=", 1)
        inputs[k] = parse_value(v)
    for kv in args.s:
        k, v = kv.split("=", 1)
        inputs[k] = Path(v[1:]).read_text().strip() if v.startswith("@") else v

    req = urllib.request.Request(args.url + "/predictions", data=json.dumps({"input": inputs}).encode(),
                                 headers={"Content-Type": "application/json"}, method="POST")
    with urllib.request.urlopen(req, timeout=3600) as r:
        d = json.loads(r.read())
    print("status:", d.get("status"))
    print("error:", d.get("error"))
    print("logs:\n" + (d.get("logs") or ""))
    out = d.get("output")
    items = out if isinstance(out, list) else [out]
    Path("http_out").mkdir(exist_ok=True)
    for n, item in enumerate(items):
        if isinstance(item, str) and item.startswith("data:"):
            mime, b64 = item[5:].split(";base64,", 1)
            ext = mimetypes.guess_extension(mime) or ".bin"
            dst = Path("http_out") / f"output_{n}{ext}"
            dst.write_bytes(base64.b64decode(b64))
            print(f"output[{n}] -> {dst} ({dst.stat().st_size} bytes)")
        else:
            print(f"output[{n}]:", str(item)[:200])


if __name__ == "__main__":
    main()
