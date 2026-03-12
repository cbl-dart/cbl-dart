# Profiling Dart CLI Applications on macOS

## Overview

There are two main approaches to profiling Dart CLI apps on macOS:

1. **Dart DevTools** — The VM's built-in sampling profiler. Works with JIT code,
   shows Dart function names and call stacks. Best for pure Dart profiling.
2. **Native profilers** (Instruments, samply, flamegraph) — Work at the OS level.
   By default they cannot see Dart symbols, but with the **AOT assembly
   workaround** you get full Dart symbol visibility in native flame graphs.

## 1. Dart DevTools (JIT Profiling)

The Dart VM includes a sampling CPU profiler accessible through DevTools.

### Basic Usage

```bash
dart run --observe main.dart
```

This prints a DevTools URL. Open it in a browser to access:

> **Note:** `--observe` pauses isolates on start and exit, so the process will
> not terminate on its own after `main()` completes. This is useful for
> inspecting the final state in DevTools, but can be surprising. If you just
> want the VM service without pausing, use `--enable-vm-service` instead:
>
> ```bash
> dart run --enable-vm-service main.dart
> ```

- **CPU Profiler**: flame charts, call trees, bottom-up views
- **Memory**: heap snapshots, allocation profiles
- **Timeline Events**: VM, Isolate, GC events

### Useful VM Flags

These flags are VM-internal options and cannot be passed directly to `dart run`.
Use the `DART_VM_OPTIONS` environment variable instead:

```bash
DART_VM_OPTIONS="--sample-buffer-duration=120 --profile-period=250 --max_profile_depth=255 --timeline_streams=VM,Isolate,GC,Dart" \
  dart run --observe main.dart
```

| Flag                         | Effect                                        |
| ---------------------------- | --------------------------------------------- |
| `--sample-buffer-duration=N` | Keep N seconds of samples (default is small)  |
| `--profile-period=N`         | Sample interval in µs (default ~1000, min 50) |
| `--max_profile_depth=N`      | Max stack depth per sample                    |
| `--timeline_streams=...`     | Enable timeline event streams                 |
| `--complete-timeline`        | Record all timeline events (higher overhead)  |

### Programmatic Instrumentation

```dart
import 'dart:developer';

// Timeline events (visible in DevTools Timeline tab)
Timeline.startSync('MyOperation');
try {
  // ... code ...
} finally {
  Timeline.finishSync();
}

// UserTag for filtering CPU samples
final tag = UserTag('MyHotPath');
final previous = tag.makeCurrent();
try {
  // ... code to profile ...
} finally {
  previous.makeCurrent();
}
```

### Limitations

- Only works with JIT (requires a running VM service)
- Cannot profile AOT-compiled executables
- Does not show native/FFI call stacks

## 2. Native Profiling with AOT Assembly (Full Dart Symbols)

By default, `dart compile exe` and `dart compile aot-snapshot` produce ELF
output even on macOS. Native profilers cannot symbolicate this. The workaround
is to compile through assembly to produce a native shared library with symbols.

This method was documented by mkustermann in
[dart-lang/sdk#54207](https://github.com/dart-lang/sdk/issues/54207).

### Finding the Dart SDK

The AOT toolchain (`dartaotruntime`, `gen_snapshot`, `gen_kernel_aot.dart.snapshot`)
lives inside the Dart SDK directory. The standard detection method is:

```bash
DART_SDK=$(dirname $(dirname $(which dart)))
```

However, this does **not** work when using the Dart SDK embedded in Flutter,
where `which dart` points to a Flutter wrapper and the real SDK is nested at
`<flutter-sdk>/bin/cache/dart-sdk/`.

To find the correct path, verify that `$DART_SDK/bin/dartaotruntime` exists:

```bash
DART_SDK=$(dirname $(dirname $(which dart)))

# If using Flutter's embedded Dart, the SDK is nested under bin/cache/dart-sdk
if [ ! -f "$DART_SDK/bin/dartaotruntime" ] && [ -f "$DART_SDK/bin/cache/dart-sdk/bin/dartaotruntime" ]; then
  DART_SDK="$DART_SDK/bin/cache/dart-sdk"
fi

# Verify
ls "$DART_SDK/bin/dartaotruntime" "$DART_SDK/bin/utils/gen_snapshot" \
   "$DART_SDK/bin/snapshots/gen_kernel_aot.dart.snapshot" \
   "$DART_SDK/lib/_internal/vm_platform_strong.dill" > /dev/null
```

### Step-by-Step

```bash
# 1. Compile Dart source to kernel (dill)
$DART_SDK/bin/dartaotruntime \
  $DART_SDK/bin/snapshots/gen_kernel_aot.dart.snapshot \
  --platform=$DART_SDK/lib/_internal/vm_platform_strong.dill \
  --aot --tfa \
  -o app.dill \
  main.dart

# 2. Generate native assembly from AOT compiler
$DART_SDK/bin/utils/gen_snapshot \
  --snapshot-kind=app-aot-assembly \
  --assembly=app.S \
  app.dill

# 3. Compile assembly into a native shared library
gcc -shared -o app.so app.S

# 4. Run with dartaotruntime
$DART_SDK/bin/dartaotruntime app.so
```

The resulting `app.so` is a native Mach-O shared library with Dart symbol names
visible to any native profiler.

### Bypassing Hardened Runtime for dtrace

macOS System Integrity Protection blocks dtrace from attaching to binaries
with hardened runtime entitlements. Instruments and `sample` work without this
workaround, but dtrace-based tools (e.g., flamegraph) require it. Make a copy
of `dartaotruntime` and re-sign it with an ad-hoc signature (which strips the
hardened runtime entitlements):

```bash
cp $DART_SDK/bin/dartaotruntime /tmp/dartaotruntime
codesign -s - /tmp/dartaotruntime
```

> **Note:** On Apple Silicon, `codesign --remove-signature` will not work —
> macOS requires all arm64 binaries to have at least an ad-hoc signature.
> Using `codesign -s -` re-signs the binary without the original entitlements
> and works on both Intel and Apple Silicon.

Then use the re-signed copy:

```bash
sudo flamegraph -- /tmp/dartaotruntime app.so
```

### Using with Instruments

```bash
xcrun xctrace record --template 'Time Profiler' \
  --launch -- $DART_SDK/bin/dartaotruntime app.so
```

You may see a `Failed to stop recording session: Failed stoping ktrace session`
error — this is a known SIP-related issue on macOS and does not affect the
recorded data. The trace file is saved and can be opened in Instruments normally.

### Using with `sample`

The built-in macOS `sample` command works without any extra setup. Launch the
AOT binary, then sample by PID:

```bash
$DART_SDK/bin/dartaotruntime app.so &
sample $! 10 -f output.txt
```

Because `app.so` is a native Mach-O with symbols, the output will include Dart
function names in the call graph.

### Using with samply

[samply](https://github.com/mstange/samply) produces profiles viewable in the
Firefox Profiler:

```bash
# Install: cargo install samply  (or: brew install samply)
samply record $DART_SDK/bin/dartaotruntime app.so
```

## 3. Native Profilers Without the Assembly Workaround

Without the assembly workaround, native profilers can still attach to any Dart
process, but Dart function names will be missing. This is useful when you only
care about native/FFI code.

### Instruments

```bash
# Attach to running process
xcrun xctrace record --template 'Time Profiler' --attach <PID> --output profile.trace

# Or launch directly
xcrun xctrace record --template 'Time Profiler' --launch -- dart run main.dart
```

### samply

```bash
samply record dart run main.dart
```

### macOS `sample` Command

```bash
sample <PID> 10 -f output.txt
```

Without the assembly workaround, Dart code will appear as `???` in the call
graph. Use the AOT assembly approach from Section 2 to get Dart symbol names.

### What You Can See

- Time spent in the Dart VM (GC, compiler, interpreter)
- Native C/C++ code called via FFI
- System library calls
- Thread activity and scheduling

### What You Cannot See

- Dart function names (appear as anonymous memory regions in JIT, or hidden
  ELF symbols in AOT)

## 4. Combined Dart + Native Profiling

There is no single tool that shows both Dart and native symbols in one view.
The practical approach:

1. **DevTools** for Dart-level profiling
2. **Native profiler + AOT assembly** for a unified native view including Dart
   symbols
3. Correlate manually using timestamps when using DevTools alongside a native
   profiler

## 5. Summary

| Approach                       | Dart Symbols | Native/FFI Symbols | Setup Effort |
| ------------------------------ | ------------ | ------------------ | ------------ |
| DevTools (JIT)                 | Yes          | No                 | Low          |
| AOT assembly + native profiler | Yes          | Yes                | Medium       |
| Native profiler (no assembly)  | No           | Yes                | Low          |

## References

- [dart-lang/sdk#54207](https://github.com/dart-lang/sdk/issues/54207) — AOT
  assembly workaround for native profiling
- [dart-lang/sdk#54254](https://github.com/dart-lang/sdk/issues/54254) —
  Feature request: make `dart compile` produce profilable output natively
- [dart-lang/sdk#60307](https://github.com/dart-lang/sdk/issues/60307) —
  Native Mach-O writer in gen_snapshot (landed, used by Flutter)
- [Dart DevTools documentation](https://dart.dev/tools/dart-devtools)
- [CPU Profiler guide](https://docs.flutter.dev/tools/devtools/cpu-profiler)
