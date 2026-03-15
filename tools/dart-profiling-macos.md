# Profiling Dart CLI Applications on macOS

## Overview

| Approach                          | Dart Symbols | Native/FFI | Setup  |
| --------------------------------- | ------------ | ---------- | ------ |
| DevTools (JIT)                    | Yes          | No         | Low    |
| AOT assembly + native profiler    | Yes          | Yes        | Medium |
| Native profiler without assembly  | No           | Yes        | Low    |

**Recommended for FFI-heavy code:** Section 2 (or Section 3 for native assets) gives
full Dart + native symbolication in Instruments, `sample`, or samply.

## 1. Dart DevTools (JIT Profiling)

```bash
dart run --observe main.dart
```

Opens a DevTools URL with CPU Profiler (flame charts, call trees), Memory (heap
snapshots), and Timeline Events.

> `--observe` pauses isolates on start/exit. Use `--enable-vm-service` instead if you
> don't want pausing.

### VM Flags

Pass via `DART_VM_OPTIONS` (not directly to `dart run`):

```bash
DART_VM_OPTIONS="--sample-buffer-duration=120 --profile-period=250" \
  dart run --observe main.dart
```

| Flag                         | Effect                                        |
| ---------------------------- | --------------------------------------------- |
| `--sample-buffer-duration=N` | Keep N seconds of samples (default is small)  |
| `--profile-period=N`         | Sample interval in us (default ~1000, min 50) |
| `--max_profile_depth=N`      | Max stack depth per sample                    |
| `--timeline_streams=...`     | Enable timeline event streams                 |

### Programmatic Instrumentation

```dart
import 'dart:developer';

Timeline.startSync('MyOperation');
try { /* ... */ } finally { Timeline.finishSync(); }

final tag = UserTag('MyHotPath');
final previous = tag.makeCurrent();
try { /* ... */ } finally { previous.makeCurrent(); }
```

### Limitations

- JIT only (requires running VM service), no AOT support
- Does not show native/FFI call stacks

## 2. Native Profiling with AOT Assembly

By default, `dart compile exe` produces ELF even on macOS — native profilers can't
symbolicate it. The workaround: compile through assembly to produce a Mach-O shared
library with Dart symbols. (See
[dart-lang/sdk#54207](https://github.com/dart-lang/sdk/issues/54207).)

### Finding the Dart SDK

```bash
DART_SDK=$(dirname $(dirname $(which dart)))

# Flutter embeds the SDK under bin/cache/dart-sdk
if [ ! -f "$DART_SDK/bin/dartaotruntime" ] && \
   [ -f "$DART_SDK/bin/cache/dart-sdk/bin/dartaotruntime" ]; then
  DART_SDK="$DART_SDK/bin/cache/dart-sdk"
fi
```

### Build Steps

```bash
# 1. Compile to kernel
$DART_SDK/bin/dartaotruntime \
  $DART_SDK/bin/snapshots/gen_kernel_aot.dart.snapshot \
  --platform=$DART_SDK/lib/_internal/vm_platform_strong.dill \
  --aot --tfa -o app.dill main.dart

# 2. Generate assembly
$DART_SDK/bin/utils/gen_snapshot \
  --snapshot-kind=app-aot-assembly --assembly=app.S app.dill

# 3. Compile to shared library
gcc -shared -o app.dylib app.S

# 4. Run
$DART_SDK/bin/dartaotruntime app.dylib
```

### Profiling with `sample`

The most reliable option — uses `task_for_pid`, unaffected by SIP:

```bash
$DART_SDK/bin/dartaotruntime app.dylib &
sample $! 10 -f output.txt
```

### Profiling with Instruments

Instruments can't resolve symbols from dylibs that are unloaded before recording ends.
The Dart runtime unloads the AOT snapshot on exit (`dlclose` in `~DylibAppSnapshot`).
See [dart-lang/sdk#60484](https://github.com/dart-lang/sdk/issues/60484).

**Workaround:** Call `DynamicLibrary.open()` on the snapshot path at program start to
bump the `dlopen` refcount. The snapshot stays mapped after the runtime's `dlclose`.
`DynamicLibrary` does not auto-close on GC — only an explicit `.close()` releases it.

```dart
import 'dart:ffi';
import 'dart:io';

void main() {
  final snapshotPath = Platform.environment['PROFILE_SNAPSHOT_PATH'];
  if (snapshotPath != null && snapshotPath.isNotEmpty) {
    DynamicLibrary.open(snapshotPath);
  }
  // ... rest of program ...
}
```

```bash
SNAPSHOT=/path/to/app.dylib
xcrun xctrace record --template 'Time Profiler' \
  --env "PROFILE_SNAPSHOT_PATH=$SNAPSHOT" \
  --launch -- $DART_SDK/bin/dartaotruntime "$SNAPSHOT"
```

**Alternative (no code changes):** Add `sleep(Duration(hours: 1))` at the end of your
program and use `--time-limit 30s`, or stop manually with `Ctrl-C`.

### Profiling with samply

```bash
samply record $DART_SDK/bin/dartaotruntime app.dylib
```

### Bypassing Hardened Runtime for dtrace

dtrace-based tools (e.g., flamegraph) require stripping hardened runtime entitlements.
Instruments and `sample` do **not** need this.

```bash
cp $DART_SDK/bin/dartaotruntime /tmp/dartaotruntime
codesign -s - /tmp/dartaotruntime   # ad-hoc re-sign strips entitlements
sudo flamegraph -- /tmp/dartaotruntime app.dylib
```

> Do **not** use this re-signed copy with Instruments — it strips the entitlements
> that Instruments and `DYLD_INSERT_LIBRARIES` require.

## 3. Native Assets (`@ffi.DefaultAsset` / `DynamicLoadingBundled`)

When your code uses native assets, `dartaotruntime` can't resolve `@ffi.DefaultAsset`
lookups (no native assets manifest). Pre-load the libraries with
`DYLD_INSERT_LIBRARIES` to make symbols available via `dlsym(RTLD_DEFAULT, ...)`.

> **Why not `DYLD_LIBRARY_PATH`?** `@ffi.DefaultAsset` resolves via
> `dlsym(RTLD_DEFAULT, ...)`, not `dlopen()` by name. Only
> `DYLD_INSERT_LIBRARIES` makes symbols globally available.

### Build Steps

Steps 2-4 are identical to Section 2. Step 1 additionally builds native assets:

```bash
# 1. Build native assets (downloads/compiles native libraries)
dart build cli --target=main.dart --output=build/profile

# 2-4. Same as Section 2, producing build/profile/app.dylib
```

### Running and Profiling

```bash
NATIVE_LIBS=build/profile/bundle/lib

# With sample
DYLD_INSERT_LIBRARIES="$NATIVE_LIBS/libfoo.dylib:$NATIVE_LIBS/libbar.dylib" \
  $DART_SDK/bin/dartaotruntime build/profile/app.dylib &
sample $! 30 -f profile_output.txt

# With Instruments (use --env; shell env vars are NOT forwarded by xctrace)
SNAPSHOT=build/profile/app.dylib
xcrun xctrace record --template 'Time Profiler' \
  --env "PROFILE_SNAPSHOT_PATH=$SNAPSHOT" \
  --env "DYLD_INSERT_LIBRARIES=$NATIVE_LIBS/libfoo.dylib:$NATIVE_LIBS/libbar.dylib" \
  --launch -- $DART_SDK/bin/dartaotruntime "$SNAPSHOT"
```

### Native Library Debug Symbols (dSYM)

Pre-compiled native libraries are typically stripped. Download the dSYM package and
place it next to the binary for full internal symbolication.

**Couchbase Lite C SDK** provides `-symbols` packages:

```bash
# URL pattern: ...-{edition}-{version}-macos-symbols.zip
curl -L -o cblite-symbols.zip \
  "https://packages.couchbase.com/releases/couchbase-lite-c/4.0.3/couchbase-lite-c-enterprise-4.0.3-macos-symbols.zip"
unzip cblite-symbols.zip
cp -R libcblite-4.0.3/libcblite.dylib.dSYM build/profile/bundle/lib/

# Verify UUIDs match
dwarfdump -u build/profile/bundle/lib/libcblite.dylib
dwarfdump -u build/profile/bundle/lib/libcblite.dylib.dSYM
```

### Concrete Example: Benchmarks in This Repo

```bash
cd packages/benchmark

# 1. Build native assets
dart build cli \
  --target=benchmark/cbl_insert.dart \
  --output=.dart_tool/benchmark-aot/profile_run

# 1b. (Optional) Download dSYM for full native symbolication
curl -L -o /tmp/cblite-symbols.zip \
  "https://packages.couchbase.com/releases/couchbase-lite-c/4.0.3/couchbase-lite-c-enterprise-4.0.3-macos-symbols.zip"
unzip -o /tmp/cblite-symbols.zip -d /tmp/cblite-symbols
cp -R /tmp/cblite-symbols/libcblite-4.0.3/libcblite.dylib.dSYM \
  .dart_tool/benchmark-aot/profile_run/bundle/lib/

# 2-4. Compile to assembly shared library
$DART_SDK/bin/dartaotruntime \
  $DART_SDK/bin/snapshots/gen_kernel_aot.dart.snapshot \
  --platform=$DART_SDK/lib/_internal/vm_platform_strong.dill \
  --aot --tfa \
  -o .dart_tool/benchmark-aot/profile_run/app.dill \
  benchmark/cbl_insert.dart

$DART_SDK/bin/utils/gen_snapshot \
  --snapshot-kind=app-aot-assembly \
  --assembly=.dart_tool/benchmark-aot/profile_run/app.S \
  .dart_tool/benchmark-aot/profile_run/app.dill

gcc -shared \
  -o .dart_tool/benchmark-aot/profile_run/app.dylib \
  .dart_tool/benchmark-aot/profile_run/app.S

# 5. Profile
NATIVE_LIBS=.dart_tool/benchmark-aot/profile_run/bundle/lib
SNAPSHOT=.dart_tool/benchmark-aot/profile_run/app.dylib

# 5a. With sample (text output)
EXECUTION_MODE=aot API_TYPE=sync OPERATION_COUNT=10000 BATCH_SIZE=10 FIXTURE=users \
DYLD_INSERT_LIBRARIES="$NATIVE_LIBS/libcblite.dylib:$NATIVE_LIBS/libcblitedart.dylib:$NATIVE_LIBS/CouchbaseLiteVectorSearch.dylib" \
  $DART_SDK/bin/dartaotruntime "$SNAPSHOT" &
sample $! 30 -f profile_output.txt

# 5b. With Instruments (GUI)
xcrun xctrace record --template 'Time Profiler' \
  --output profile.trace \
  --env EXECUTION_MODE=aot --env API_TYPE=sync \
  --env OPERATION_COUNT=10000 --env BATCH_SIZE=10 --env FIXTURE=users \
  --env "PROFILE_SNAPSHOT_PATH=$SNAPSHOT" \
  --env "DYLD_INSERT_LIBRARIES=$NATIVE_LIBS/libcblite.dylib:$NATIVE_LIBS/libcblitedart.dylib:$NATIVE_LIBS/CouchbaseLiteVectorSearch.dylib" \
  --launch -- $DART_SDK/bin/dartaotruntime "$SNAPSHOT"
```

With the dSYM in place (step 1b), profiles show fully symbolicated frames across all
layers: Dart (`CblInsertBenchmark.runSync`, `FleeceEncoder.writeDartObject`), Fleece
(`fleece::impl::Encoder::writeValue`), LiteCore, and SQLite (`sqlite3VdbeExec`).

## References

- [dart-lang/sdk#54207](https://github.com/dart-lang/sdk/issues/54207) — AOT
  assembly workaround for native profiling
- [dart-lang/sdk#54254](https://github.com/dart-lang/sdk/issues/54254) — Feature
  request: make `dart compile` produce profilable output natively
- [dart-lang/sdk#60307](https://github.com/dart-lang/sdk/issues/60307) — Native
  Mach-O writer in gen_snapshot (landed, used by Flutter)
- [dart-lang/sdk#60484](https://github.com/dart-lang/sdk/issues/60484) — Instruments
  dylib unload workaround
- [Dart DevTools](https://dart.dev/tools/dart-devtools)
