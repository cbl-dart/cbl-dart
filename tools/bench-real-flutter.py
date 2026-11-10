"""Run the existing Flutter setup and exact Formatting-Dart workload, no app build."""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time

result_path = Path(os.environ["RUNNER_TEMP"]) / "bench-real-flutter-result.json"
guard_path = Path(os.environ["RUNNER_TEMP"]) / "bench-real-flutter-guard.json"
backend = os.environ["BENCH_BACKEND"]
phase = os.environ["BENCH_PHASE"]
def blob(path):
    return subprocess.check_output(["git", "rev-parse", "HEAD:"+path], text=True).strip()
def hash_file(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def measured(name,args,cwd=None):
    begin=time.monotonic()
    subprocess.run(args,cwd=cwd,check=True)
    return round((time.monotonic()-begin)*1000)

if sys.argv[1] == "guard":
    sdk=Path(os.environ["CONFIG_SDK_PATH"])
    pub=Path(os.environ["CONFIG_PUB_PATH"])
    key=os.environ["CONFIG_SDK_KEY"]
    assert sdk.parent == Path(os.environ["RUNNER_TOOL_CACHE"])/"flutter"
    assert pub == Path.home()/".pub-cache"
    sdk_hash=re.search(r"([a-f0-9]{40})$",key).group(1)
    contract={"sdk_key":key,"pubspec_lock_sha256":hash_file("pubspec.lock"),"setup_script_blob":blob(".github/actions/setup-flutter/setup.sh")}
    seal=sdk.parent/(".bench-complete-"+hashlib.sha256(json.dumps(contract,sort_keys=True).encode()).hexdigest()+".json")
    previous=json.loads(seal.read_text()) if seal.exists() else None
    trusted=backend=="sticky" and os.environ.get("DISK_CACHE_HIT")=="true" and previous and previous.get("contract")==contract
    if trusted:
        trusted=all(path.exists() for path in (sdk/"bin/flutter",sdk/"bin/cache/dart-sdk/bin/dart",sdk/"bin/cache/flutter_tools.snapshot"))
        if trusted:
            trusted=subprocess.check_output(["git","-C",str(sdk),"rev-parse","HEAD"],text=True).strip()==sdk_hash
    trusted=bool(trusted)
    if backend=="sticky":
        if phase=="seed":assert os.environ.get("DISK_CACHE_HIT")!="true"
        if phase=="warm":assert trusted, "Warm snapshot must contain a completed seed workload"
        # A cancelled/failed job can still be snapshotted. It must not retain a success seal.
        seal.unlink(missing_ok=True)
        if not trusted:
            if sdk.exists():shutil.rmtree(sdk)
            if pub.exists():
                for child in pub.iterdir():
                    if child.is_dir() and not child.is_symlink():shutil.rmtree(child)
                    else:child.unlink()
    data={"backend":backend,"phase":phase,"trusted":trusted,"disk_cache_hit":os.environ.get("DISK_CACHE_HIT",""),"sdk_path":str(sdk),"pub_path":str(pub),"sdk_hash":sdk_hash,"contract":contract,"seal_path":str(seal),"previous_seal":previous,"run_id":os.environ["GITHUB_RUN_ID"]}
    guard_path.write_text(json.dumps(data,indent=2)+"\n")
    with open(os.environ["GITHUB_OUTPUT"],"a") as f:f.write("trusted="+str(trusted).lower()+"\n")
    print(json.dumps(data),flush=True)
    sys.exit(0)

guard=json.loads(guard_path.read_text())
sdk=Path(guard["sdk_path"]);pub=Path(guard["pub_path"])
result={"backend":backend,"phase":phase,"run_id":os.environ["GITHUB_RUN_ID"],"commit":os.environ["GITHUB_SHA"],"guard":guard,"source_blobs":{"action":blob(".github/actions/setup-flutter/action.yaml"),"setup_script":blob(".github/actions/setup-flutter/setup.sh"),"lockfile":blob("pubspec.lock")},"sdk_action_cache_hit":os.environ.get("SDK_ACTION_CACHE_HIT",""),"pub_action_cache_hit":os.environ.get("PUB_ACTION_CACHE_HIT",""),"timings_ms":{}}
try:
    assert Path(os.environ["FLUTTER_ROOT"]) == sdk
    assert Path(os.environ["PUB_CACHE"]) == pub
    info=subprocess.check_output([str(sdk/"bin/flutter"),"--version","--machine"],text=True)
    info=json.loads(info[info.index("{"):info.rfind("}")+1])
    assert info["frameworkVersion"]=="3.47.9"
    assert info["frameworkRevision"]==guard["sdk_hash"]
    result["flutter"]=info
    if phase=="warm" and backend=="s3":
        assert result["sdk_action_cache_hit"]=="true"
        assert result["pub_action_cache_hit"]=="true"
    dart=str(sdk/"bin/dart")
    result["timings_ms"]["melos_activate"]=measured("melos",[dart,"pub","global","activate","melos","7.8.1"])
    result["timings_ms"]["daco_activate"]=measured("daco",[dart,"pub","global","activate","daco"])
    result["timings_ms"]["pub_get"]=measured("pub",[dart,"pub","get","--enforce-lockfile"])
    assert hash_file("pubspec.lock")==guard["contract"]["pubspec_lock_sha256"]
    assert Path(".dart_tool/package_config.json").is_file()
    result["timings_ms"]["format_check"]=measured("format",[str(pub/"bin/melos"),"formatting:check"])
    result["sizes"]={}
    for label,path in (("sdk",sdk),("pub",pub)):
        result["sizes"][label]={"logical_bytes":int(subprocess.check_output(["du","-sb",str(path)],text=True).split()[0]),"allocated_bytes":int(subprocess.check_output(["du","-s","--block-size=1",str(path)],text=True).split()[0])}
    result["completed"]=True
    if backend=="sticky":
        seal={"contract":guard["contract"],"successful_phase":phase,"run_id":os.environ["GITHUB_RUN_ID"]}
        Path(guard["seal_path"]).write_text(json.dumps(seal,sort_keys=True)+"\n")
        result["seal_written"]=True
except Exception as e:
    result["error"]=repr(e)
    raise
finally:
    result_path.write_text(json.dumps(result,indent=2)+"\n")
    print(json.dumps(result),flush=True)
