"""Benchmark only the repo's pinned native Android toolchain cache."""

import json
import os
from pathlib import Path
import re
import subprocess
import time

sdk = Path(os.environ["ANDROID_HOME"])
ndk = sdk / "ndk/28.0.13004108"
cmake = sdk / "cmake/3.18.1"
start = time.monotonic()
subprocess.run(["bash", "tools/android-sdk.sh", "installNativeToolchain"], check=True)
install_ms = round((time.monotonic() - start) * 1000)
assert "Pkg.Revision=28.0.13004108" in re.sub(r"\s+", "", (ndk / "source.properties").read_text())
assert "3.18.1" in (cmake / "source.properties").read_text()

work = Path(os.environ["RUNNER_TEMP"]) / "native-cache-probe"
work.mkdir(exist_ok=True)
source = work / "probe.cpp"
source.write_text('extern "C" int cache_probe() { return 42; }\n')
start = time.monotonic()
subprocess.run([str(cmake / "bin/cmake"), "--version"], check=True)
subprocess.run(
    [
        str(ndk / "toolchains/llvm/prebuilt/linux-x86_64/bin/clang++"),
        "--target=aarch64-linux-android21",
        "-shared",
        "-fPIC",
        str(source),
        "-o",
        str(work / "libprobe.so"),
    ],
    check=True,
)
probe_ms = round((time.monotonic() - start) * 1000)
sizes = []
for path in (ndk, cmake):
    logical = int(subprocess.check_output(["du", "-sb", str(path)], text=True).split()[0])
    allocated = int(subprocess.check_output(["du", "-s", "--block-size=1", str(path)], text=True).split()[0])
    files = sum(1 for p in path.rglob("*") if p.is_file())
    sizes.append({"path": str(path), "logical_bytes": logical, "allocated_bytes": allocated, "files": files})

result = {
    "backend": os.environ["BENCH_BACKEND"],
    "phase": os.environ["BENCH_PHASE"],
    "cache_hit": os.environ.get("CACHE_HIT", ""),
    "install_ms": install_ms,
    "probe_ms": probe_ms,
    "cache_directories": sizes,
    "run_id": os.environ["GITHUB_RUN_ID"],
    "run_attempt": os.environ["GITHUB_RUN_ATTEMPT"],
    "commit": os.environ["GITHUB_SHA"],
    "sticky_dir": os.environ.get("RUNS_ON_STICKYDISK_DIR"),
    "sticky_lineage": os.environ.get("RUNS_ON_STICKYDISK_NAME"),
}
target = Path(os.environ["RUNNER_TEMP"]) / "sticky-benchmark-result.json"
target.write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps(result), flush=True)
