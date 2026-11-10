"""A pinned Flutter SDK plus bounded, real Pub dependency workload; no app build."""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import time
import urllib.request

root = Path(os.environ["CACHE_ROOT"])
root.mkdir(parents=True, exist_ok=True)
sdk = root / "flutter"
release = {"version": "3.47.9", "hash": "c197ca5199e9ee5661e865596c9c07294dfab51c", "sha256": "25ed8c3c29d51a7353f2a944310b478af8214920639524b19c50a19e6c044c5a", "url": "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.9-stable.tar.xz"}
timings = {}
archive_bytes = 0
if not (sdk / "bin/dart").exists():
    archive = Path(os.environ["RUNNER_TEMP"]) / "flutter-3.47.9.tar.xz"
    start = time.monotonic()
    urllib.request.urlretrieve(release["url"], archive)
    timings["download_ms"] = round((time.monotonic()-start)*1000)
    archive_bytes = archive.stat().st_size
    start = time.monotonic()
    hasher = hashlib.sha256()
    with archive.open("rb") as f:
        for chunk in iter(lambda: f.read(1024*1024), b""):
            hasher.update(chunk)
    digest = hasher.hexdigest()
    assert digest == release["sha256"], digest
    timings["archive_verify_ms"] = round((time.monotonic()-start)*1000)
    start = time.monotonic()
    subprocess.run(["tar", "-xJf", str(archive), "-C", str(root)], check=True)
    timings["extract_ms"] = round((time.monotonic()-start)*1000)
    archive.unlink()
else:
    timings.update(download_ms=0, archive_verify_ms=0, extract_ms=0)
start = time.monotonic()
subprocess.run([str(sdk / "bin/flutter"), "--version", "--machine"], check=True)
timings["flutter_version_ms"] = round((time.monotonic()-start)*1000)
actual_hash = subprocess.check_output(["git", "-C", str(sdk), "rev-parse", "HEAD"], text=True).strip()
assert actual_hash == release["hash"], actual_hash

fixture = Path(os.environ["RUNNER_TEMP"]) / "bench-pub-fixture"
(fixture / "bin").mkdir(parents=True, exist_ok=True)
(fixture / "pubspec.yaml").write_text("\n".join(["name: bench_sdk_pub", "publish_to: none", "environment:", "  sdk: '>=3.13.0 <4.0.0'", "dependencies:", "  code_assets: 2.2.0", "  collection: 1.19.1", "  hooks: 2.2.0", "  http: 1.6.0", "  native_toolchain_c: 0.19.6", "  path: 1.9.1", ""]))
lock = fixture / "pubspec.lock"
retained_lock = root / "fixture.lock"
if retained_lock.exists():
    shutil.copy2(retained_lock, lock)
else:
    source = Path("pubspec.lock").read_text()
    body, sdks = source.split("packages:\n", 1)[1].split("\nsdks:\n", 1)
    blocks = re.split(r"(?m)(?=^  [a-zA-Z0-9_]+:\n)", body)
    lock.write_text("# Seeded from the repo's hosted package pins.\npackages:\n" + "".join(b for b in blocks if "    source: hosted\n" in b) + "\nsdks:\n" + sdks)
args = [str(sdk / "bin/dart"), "pub", "get"]
if os.environ["BENCH_PHASE"] == "warm":
    args += ["--offline", "--enforce-lockfile"]
start = time.monotonic()
subprocess.run(args, cwd=fixture, check=True)
timings["pub_get_ms"] = round((time.monotonic()-start)*1000)
shutil.copy2(lock, retained_lock)
(fixture / "bin/probe.dart").write_text("import 'dart:convert';\nimport 'package:collection/collection.dart';\nimport 'package:path/path.dart' as p;\nvoid main() { print(jsonEncode({'path':p.join('cache','probe'), 'sum':[1,2,3].sum})); }\n")
start = time.monotonic()
subprocess.run([str(sdk / "bin/dart"), "run", "bin/probe.dart"], cwd=fixture, check=True)
timings["probe_ms"] = round((time.monotonic()-start)*1000)
sizes = []
for path in (sdk, root / "pub"):
    logical = int(subprocess.check_output(["du", "-sb", str(path)], text=True).split()[0])
    allocated = int(subprocess.check_output(["du", "-s", "--block-size=1", str(path)], text=True).split()[0])
    sizes.append({"path":str(path), "logical_bytes":logical, "allocated_bytes":allocated, "files":sum(1 for x in path.rglob("*") if x.is_file())})
result = {"dataset":"flutter-pub", "backend":os.environ["BENCH_BACKEND"], "phase":os.environ["BENCH_PHASE"], "initialization":os.environ["BENCH_INITIALIZATION"], "cache_hit":os.environ.get("CACHE_HIT", ""), "release":release, "archive_bytes":archive_bytes, "lock_sha256":hashlib.sha256(lock.read_bytes()).hexdigest(), "timings":timings, "cache_directories":sizes, "run_id":os.environ["GITHUB_RUN_ID"], "run_attempt":os.environ["GITHUB_RUN_ATTEMPT"], "commit":os.environ["GITHUB_SHA"], "sticky_dir":os.environ.get("RUNS_ON_STICKYDISK_DIR"), "sticky_lineage":os.environ.get("RUNS_ON_STICKYDISK_NAME")}
(Path(os.environ["RUNNER_TEMP"])/"sticky-benchmark-result.json").write_text(json.dumps(result,indent=2)+"\n")
print(json.dumps(result),flush=True)
