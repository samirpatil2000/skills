"""Create a Replicate prediction, stream its logs, download outputs, verify HTTP 200. Stdlib only.

    python run_replicate.py owner/model -i video=@samples/clip.mp4 -i resolution=720p \
        -s hf_token=@.secrets/hf_token [--token-file .secrets/replicate_token] [--version <id>] [--id <prediction>]

-i key=value   input; key=@file uploads the file to /v1/files first; numbers/true/false are parsed
-s key=@file   secret input read from a file
--id           resume polling an existing prediction
Exit code 0 only if the prediction succeeded and every output URL returned HTTP 200.
"""

import argparse
import json
import mimetypes
import sys
import time
import urllib.request
import uuid
from pathlib import Path

API = "https://api.replicate.com/v1"
UA = {"User-Agent": "cog-replicate-skill/1.0"}  # default Python-urllib UA gets 403 on some endpoints


def req(method, url, token, body=None, headers=None, timeout=300):
    r = urllib.request.Request(url, data=body, method=method,
                               headers={"Authorization": f"Bearer {token}", **UA, **(headers or {})})
    with urllib.request.urlopen(r, timeout=timeout) as resp:
        return json.loads(resp.read() or b"{}")


def upload(path: Path, token: str) -> str:
    boundary = uuid.uuid4().hex
    ctype = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
    body = (f'--{boundary}\r\nContent-Disposition: form-data; name="content"; filename="{path.name}"\r\n'
            f"Content-Type: {ctype}\r\n\r\n").encode() + path.read_bytes() + f"\r\n--{boundary}--\r\n".encode()
    return req("POST", f"{API}/files", token, body, {"Content-Type": f"multipart/form-data; boundary={boundary}"})["urls"]["get"]


def parse_value(v: str, token: str):
    if v.startswith("@"):
        return upload(Path(v[1:]), token)
    for conv in (int, float):
        try:
            return conv(v)
        except ValueError:
            pass
    return {"true": True, "false": False}.get(v.lower(), v)


def main():
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")  # Windows cp1252 consoles
    ap = argparse.ArgumentParser()
    ap.add_argument("model")
    ap.add_argument("-i", action="append", default=[])
    ap.add_argument("-s", action="append", default=[])
    ap.add_argument("--token-file", default=".secrets/replicate_token")
    ap.add_argument("--version")
    ap.add_argument("--id")
    ap.add_argument("--out", type=Path, default=Path("outputs"))
    ap.add_argument("--start-timeout", type=int, default=300,
                    help="Cancel the prediction if it stays 'starting' this many seconds (default 300)")
    args = ap.parse_args()

    token = Path(args.token_file).read_text().strip()
    if args.id:
        p = req("GET", f"{API}/predictions/{args.id}", token)
    else:
        version = args.version or req("GET", f"{API}/models/{args.model}", token)["latest_version"]["id"]
        inputs = {}
        for kv in args.i:
            k, v = kv.split("=", 1)
            inputs[k] = parse_value(v, token)
        for kv in args.s:
            k, v = kv.split("=", 1)
            inputs[k] = Path(v[1:]).read_text().strip() if v.startswith("@") else v
        p = req("POST", f"{API}/predictions", token, json.dumps({"version": version, "input": inputs}).encode(),
                {"Content-Type": "application/json"})
    print(f"prediction {p['id']}  version {p['version'][:12]}")

    t0, seen, last = time.time(), 0, None
    start_t0 = None  # when the prediction entered "starting"; reset when it leaves that state
    while p["status"] not in ("succeeded", "failed", "canceled"):
        time.sleep(10)
        p = req("GET", f"{API}/predictions/{p['id']}", token)
        logs = p.get("logs") or ""
        if len(logs) > seen:
            print(logs[seen:], end="", flush=True)
            seen = len(logs)
        if p["status"] != last:
            print(f"\n[{time.time() - t0:5.0f}s] status={p['status']}", flush=True)
            last = p["status"]
        if p["status"] == "starting":
            start_t0 = start_t0 or time.time()
            if time.time() - start_t0 > args.start_timeout:
                print(f"\nstart timeout: still 'starting' after {args.start_timeout}s, canceling", flush=True)
                req("POST", f"{API}/predictions/{p['id']}/cancel", token, b"{}", {"Content-Type": "application/json"})
                p = req("GET", f"{API}/predictions/{p['id']}", token)
                break
        else:
            start_t0 = None

    print(json.dumps({k: p.get(k) for k in ("status", "error", "metrics")}, indent=1))
    if p["status"] != "succeeded":
        raise SystemExit(1)

    out = p["output"]
    items = out if isinstance(out, list) else list(out.values()) if isinstance(out, dict) else [out]
    out_dir = args.out / p["id"]
    out_dir.mkdir(parents=True, exist_ok=True)
    ok = True
    for n, link in enumerate(items):
        if not isinstance(link, str) or not link.startswith("https://"):
            print(f"output[{n}] is not an HTTPS URL ({str(link)[:50]}...) -> return Path/List[Path], see errors.md")
            ok = False
            continue
        with urllib.request.urlopen(urllib.request.Request(link, headers=UA), timeout=1800) as r:
            dst = out_dir / (Path(link.split("?")[0]).name or f"output_{n}")
            dst.write_bytes(r.read())
            print(f"output[{n}]: HTTP {r.getcode()} {r.headers.get_content_type()} -> {dst} ({dst.stat().st_size} bytes)")
            ok &= r.getcode() == 200
    raise SystemExit(0 if ok else 1)


if __name__ == "__main__":
    main()
