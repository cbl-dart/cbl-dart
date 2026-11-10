#!/usr/bin/env bash
set -euo pipefail

fixture="$GITHUB_WORKSPACE/.bench-gradle"
results="$GITHUB_WORKSPACE/bench-results"
mkdir -p "$fixture/app/src/main/java/bench/cache" "$results"
export BENCH_FIXTURE="$fixture"
python3 - <<'PY'
import hashlib, os
from pathlib import Path
p=Path(os.environ['BENCH_FIXTURE'])
seed=int(hashlib.sha256((os.environ['BENCH_BATCH']+os.environ['BENCH_MODE']).encode()).hexdigest()[:7],16)
for i in range(200):
    (p/f'app/src/main/java/bench/cache/Value{i}.java').write_text(f'package bench.cache; public class Value{i} {{ public static int value(int x) {{ return x * {i+1} + {seed}; }} }}\n')
PY
cat > "$fixture/settings.gradle" <<'EOF'
pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
dependencyResolutionManagement { repositories { google(); mavenCentral() } }
rootProject.name = 'runs-on-gradle-cache-probe'
include ':app'
buildCache { local { enabled = System.getenv('BENCH_MODE') != 'remote' } }
gradle.settingsEvaluated { s ->
    println "BENCH_SETTINGS buildCacheEnabled=${gradle.startParameter.buildCacheEnabled} localEnabled=${s.buildCache.local.enabled} remoteConfigured=${s.buildCache.remote != null} remoteEnabled=${s.buildCache.remote?.enabled}"
}
EOF
cat > "$fixture/build.gradle" <<'EOF'
plugins { id 'com.android.application' version '8.11.1' apply false }
EOF
cat > "$fixture/gradle.properties" <<'EOF'
org.gradle.jvmargs=-Xmx2G
android.useAndroidX=true
EOF
cat > "$fixture/app/build.gradle" <<'EOF'
plugins { id 'com.android.application' }
android {
    namespace 'bench.cache'
    compileSdk 36
    buildToolsVersion '35.0.0'
    defaultConfig { applicationId 'bench.cache'; minSdk 24; targetSdk 36; versionCode 1; versionName '1' }
    compileOptions { sourceCompatibility JavaVersion.VERSION_17; targetCompatibility JavaVersion.VERSION_17 }
}
EOF
printf '<manifest xmlns:android="http://schemas.android.com/apk/res/android"><application /></manifest>\n' > "$fixture/app/src/main/AndroidManifest.xml"
printf 'sdk.dir=%s\n' "$ANDROID_HOME" > "$fixture/local.properties"

if [[ "$BENCH_MODE" == remote ]]; then
  rm -rf "${GRADLE_USER_HOME:-$HOME/.gradle}/caches/build-cache-1"
fi
cache_flag=--build-cache
if [[ "$BENCH_MODE" == default ]]; then cache_flag=--no-build-cache; fi
start_ns=$(date +%s%N)
gradle -p "$fixture" --info --console=plain --no-daemon --no-configuration-cache "$cache_flag" :app:compileDebugJavaWithJavac 2>&1 | tee "$results/gradle.log"
end_ns=$(date +%s%N)
export BENCH_ELAPSED_MS=$(((end_ns-start_ns)/1000000))
python3 - <<'PY'
import json,os,re
from pathlib import Path
p=Path(os.environ['GITHUB_WORKSPACE'])/'bench-results'
t=(p/'gradle.log').read_text()
tasks=re.findall(r'^> Task (.+)$',t,re.M)
out={'mode':os.environ['BENCH_MODE'],'phase':os.environ['BENCH_PHASE'],'batch':os.environ['BENCH_BATCH'],'workloadMs':int(os.environ['BENCH_ELAPSED_MS']),'cacheSettings':re.findall(r'^BENCH_SETTINGS.*$',t,re.M),'fromCache':[x for x in tasks if 'FROM-CACHE' in x],'upToDate':[x for x in tasks if 'UP-TO-DATE' in x],'tasks':tasks,'cacheBytes':{}}
home=Path(os.environ.get('GRADLE_USER_HOME',str(Path.home()/'.gradle')))
for name in ['caches','wrapper','caches/build-cache-1']:
    out['cacheBytes'][name]=sum(f.stat().st_size for f in (home/name).rglob('*') if f.is_file())
(p/'result.json').write_text(json.dumps(out,indent=2)+'\n')
print('BENCH_RESULT '+json.dumps(out))
# AGP has no-source/setup tasks that can be UP-TO-DATE on a fresh runner;
# the actual compilation must be EXECUTED or FROM-CACHE, never UP-TO-DATE.
assert not any(':app:compileDebugJavaWithJavac UP-TO-DATE' in x for x in out['upToDate'])
if out['mode']=='remote':
    assert any('localEnabled=false' in x and 'remoteEnabled=true' in x for x in out['cacheSettings'])
    if out['phase']=='warm': assert any(':app:compileDebugJavaWithJavac FROM-CACHE' in x for x in out['fromCache'])
PY
