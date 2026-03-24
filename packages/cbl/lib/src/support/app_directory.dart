import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

// === Public API ==============================================================

/// The operating system the app is running on.
enum OperatingSystem { ios, macos, android, linux, windows, unknown }

/// Captures the platform state needed to resolve the app data directory.
///
/// Use [PlatformContext.current] for production. Construct directly for tests,
/// supplying only the fields relevant to the platform under test.
class PlatformContext {
  const PlatformContext({
    required this.resolvedExecutable,
    this.environment = const {},
    required this.os,
    this.isFlutterApp,
    this.appleAppSupportDir,
    this.macOSBundleId,
    this.androidPackageName,
    this.androidUserId,
    this.windowsAppDataDir,
  });

  /// Creates a context from the live [Platform] values.
  factory PlatformContext.current() => PlatformContext(
    resolvedExecutable: Platform.resolvedExecutable,
    environment: Platform.environment,
    os: _currentOS(),
  );

  /// The resolved path of the running executable.
  final String resolvedExecutable;

  /// The process environment variables.
  final Map<String, String> environment;

  /// The current operating system.
  final OperatingSystem os;

  /// Whether the current process is a Flutter app. When `null`, this is
  /// auto-detected from the runtime environment. Set explicitly in tests.
  final bool? isFlutterApp;

  /// Override for the Apple Application Support directory (iOS / macOS). When
  /// `null`, resolved via `NSSearchPathForDirectoriesInDomains` FFI.
  final String? appleAppSupportDir;

  /// Override for the macOS main bundle identifier. When `null`, resolved via
  /// `CFBundleGetIdentifier` FFI.
  final String? macOSBundleId;

  /// Override for the Android package name. When `null`, read from
  /// `/proc/self/cmdline`.
  final String? androidPackageName;

  /// Override for the Android user ID. When `null`, derived from the process
  /// UID via `getuid()` FFI (`uid ~/ 100000`).
  final int? androidUserId;

  /// Override for the Windows Local AppData directory. When `null`, resolved
  /// via `SHGetKnownFolderPath` FFI.
  final String? windowsAppDataDir;
}

/// Whether the current process is running inside a Flutter app.
///
/// Returns `false` for standalone Dart processes (`dart run`, `dart test`,
/// compiled Dart CLI executables, etc.).
///
/// Detection is based on the availability of `dart:ui`, which is provided
/// exclusively by the Flutter engine and is absent in standalone Dart.
///
/// The [context] parameter allows overriding this via
/// [PlatformContext.isFlutterApp] for testing.
bool isFlutterApp({PlatformContext? context}) {
  final ctx = context ?? PlatformContext.current();
  return _isFlutterApp(ctx);
}

/// Resolves the platform's standard app data directory for storing databases
/// and other app data.
///
/// Only resolves a directory for Flutter apps. Standalone Dart processes always
/// get `null`, in which case callers should fall back to the current working
/// directory.
String? resolveAppFilesDirectory({PlatformContext? context}) {
  final ctx = context ?? PlatformContext.current();
  if (!_isFlutterApp(ctx)) {
    return null;
  }
  for (final strategy in _strategies) {
    if (strategy.appliesTo(ctx)) {
      return strategy.resolve(ctx);
    }
  }
  return null;
}

/// Resolves the Android app cache directory from the package name.
///
/// Used as the temporary directory for Couchbase Lite on Android.
String resolveAndroidCacheDirectory({PlatformContext? context}) {
  final ctx = context ?? PlatformContext.current();
  return '${_androidAppBasePath(ctx)}/cache';
}

// === Internal helpers ========================================================

/// `dart:ui` is provided exclusively by the Flutter engine and is absent in
/// standalone Dart. This compile-time constant is the canonical way to detect
/// Flutter without depending on it.
// ignore: do_not_use_environment
const _kIsFlutter = bool.fromEnvironment('dart.library.ui');

bool _isFlutterApp(PlatformContext ctx) {
  if (ctx.isFlutterApp != null) {
    return ctx.isFlutterApp!;
  }
  if (!_kIsFlutter) {
    return false;
  }
  // `dart.library.ui` is also true under `flutter test`, which runs inside
  // the Flutter engine but is not a real app. Filter out the test runner
  // executable so tests fall back to the working directory.
  final exe = p.basenameWithoutExtension(ctx.resolvedExecutable);
  if (exe == 'flutter_tester') {
    return false;
  }
  return true;
}

/// Returns `/data/user/<userId>/<packageName>` for Android.
String _androidAppBasePath(PlatformContext ctx) {
  final name = ctx.androidPackageName ?? _readAndroidPackageName();
  final userId = ctx.androidUserId ?? _getAndroidUserId();
  return '/data/user/$userId/$name';
}

String? _xdgDataHome(Map<String, String> environment) {
  final explicit = environment['XDG_DATA_HOME'];
  if (explicit != null) {
    return explicit;
  }
  final home = environment['HOME'];
  if (home == null) {
    return null;
  }
  return p.join(home, '.local', 'share');
}

// === Strategies ==============================================================

const _strategies = <_AppDirectoryStrategy>[
  _IOSStrategy(),
  _MacOSStrategy(),
  _AndroidStrategy(),
  _LinuxStrategy(),
  _WindowsStrategy(),
];

abstract class _AppDirectoryStrategy {
  const _AppDirectoryStrategy();

  bool appliesTo(PlatformContext ctx);
  String? resolve(PlatformContext ctx);
}

/// iOS: Always sandboxed. Use the platform Application Support directory.
class _IOSStrategy extends _AppDirectoryStrategy {
  const _IOSStrategy();

  @override
  bool appliesTo(PlatformContext ctx) => ctx.os == OperatingSystem.ios;

  @override
  String resolve(PlatformContext ctx) =>
      ctx.appleAppSupportDir ?? _nsSearchPathForApplicationSupport();
}

/// macOS: Use `<Application Support>/<bundleId>`.
class _MacOSStrategy extends _AppDirectoryStrategy {
  const _MacOSStrategy();

  @override
  bool appliesTo(PlatformContext ctx) => ctx.os == OperatingSystem.macos;

  @override
  String? resolve(PlatformContext ctx) {
    final bundleId = ctx.macOSBundleId ?? _cfBundleIdentifier();
    if (bundleId == null) {
      return null;
    }
    final appSupport =
        ctx.appleAppSupportDir ?? _nsSearchPathForApplicationSupport();
    return p.join(appSupport, bundleId);
  }
}

/// Android: Resolve from the package name and user ID.
///
/// Uses `/data/user/<userId>/<package>/files` which is the canonical path that
/// works correctly for both the primary user (ID 0) and secondary user
/// profiles. The commonly seen `/data/data/` path is merely a symlink to
/// `/data/user/0/` and does not work for other user profiles.
class _AndroidStrategy extends _AppDirectoryStrategy {
  const _AndroidStrategy();

  @override
  bool appliesTo(PlatformContext ctx) => ctx.os == OperatingSystem.android;

  @override
  String resolve(PlatformContext ctx) => '${_androidAppBasePath(ctx)}/files';
}

/// Linux: Check for snap/flatpak containers, then use XDG with the app name.
class _LinuxStrategy extends _AppDirectoryStrategy {
  const _LinuxStrategy();

  @override
  bool appliesTo(PlatformContext ctx) => ctx.os == OperatingSystem.linux;

  @override
  String? resolve(PlatformContext ctx) {
    final env = ctx.environment;

    // Snap container: SNAP_USER_DATA is the app's data directory.
    final snapUserData = env['SNAP_USER_DATA'];
    if (snapUserData != null) {
      return snapUserData;
    }

    // Flatpak container: XDG dirs are already redirected inside the sandbox.
    final flatpakId = env['FLATPAK_ID'];
    if (flatpakId != null) {
      final dataHome = _xdgDataHome(env);
      if (dataHome != null) {
        return dataHome;
      }
    }

    // Regular Flutter app: use XDG data directory with the executable name.
    final appName = p.basenameWithoutExtension(ctx.resolvedExecutable);
    final dataHome = _xdgDataHome(env);
    if (dataHome != null) {
      return p.join(dataHome, appName);
    }

    return null;
  }
}

/// Windows: Use `<Local AppData>/<appName>`.
class _WindowsStrategy extends _AppDirectoryStrategy {
  const _WindowsStrategy();

  @override
  bool appliesTo(PlatformContext ctx) => ctx.os == OperatingSystem.windows;

  @override
  String? resolve(PlatformContext ctx) {
    final appName = p.basenameWithoutExtension(ctx.resolvedExecutable);
    final appData = ctx.windowsAppDataDir ?? _windowsLocalAppDataPath();
    if (appData == null) {
      return null;
    }

    return p.join(appData, appName);
  }
}

// === Private helpers =========================================================

OperatingSystem _currentOS() {
  if (Platform.isIOS) {
    return OperatingSystem.ios;
  }
  if (Platform.isMacOS) {
    return OperatingSystem.macos;
  }
  if (Platform.isAndroid) {
    return OperatingSystem.android;
  }
  if (Platform.isLinux) {
    return OperatingSystem.linux;
  }
  if (Platform.isWindows) {
    return OperatingSystem.windows;
  }
  return OperatingSystem.unknown;
}

String _readAndroidPackageName() {
  final cmdlineBytes = File('/proc/self/cmdline').readAsBytesSync();
  final nullIndex = cmdlineBytes.indexOf(0);
  return String.fromCharCodes(
    nullIndex == -1 ? cmdlineBytes : cmdlineBytes.sublist(0, nullIndex),
  );
}

/// Returns the Android user ID by calling `getuid()` via FFI.
///
/// Android assigns UIDs as `userId * 100000 + appId`, so integer division by
/// 100000 recovers the user ID.
int _getAndroidUserId() {
  final libc = DynamicLibrary.open('libc.so');
  final getuid = libc.lookupFunction<Uint32 Function(), int Function()>(
    'getuid',
  );
  return getuid() ~/ 100000;
}

// === Apple FFI helpers =======================================================

/// Calls `NSSearchPathForDirectoriesInDomains` with
/// `NSApplicationSupportDirectory` and `NSUserDomainMask` via FFI.
///
/// Uses an explicit autorelease pool to ensure the temporary `NSArray` and
/// `NSString` objects are released after we copy the result into a Dart string.
String _nsSearchPathForApplicationSupport() {
  final foundation = DynamicLibrary.process();

  final pool = _autoreleasePoolPush(foundation);
  try {
    // NSSearchPathForDirectoriesInDomains returns NSArray<NSString *>*.
    // NSApplicationSupportDirectory = 14, NSUserDomainMask = 1.
    final nsSearchPath = foundation
        .lookupFunction<
          Pointer Function(UnsignedLong, UnsignedLong, UnsignedChar),
          Pointer Function(int, int, int)
        >('NSSearchPathForDirectoriesInDomains');

    final cfArrayGetValueAtIndex = foundation
        .lookupFunction<
          Pointer Function(Pointer, Long),
          Pointer Function(Pointer, int)
        >('CFArrayGetValueAtIndex');

    // Arguments: directory (14), domainMask (1), expandTilde (YES = 1).
    final array = nsSearchPath(14, 1, 1);
    final firstElement = cfArrayGetValueAtIndex(array, 0);
    return _nsStringToString(foundation, firstElement);
  } finally {
    _autoreleasePoolPop(foundation, pool);
  }
}

/// Calls `CFBundleGetMainBundle()` and `CFBundleGetIdentifier()` via FFI.
String? _cfBundleIdentifier() {
  final foundation = DynamicLibrary.process();

  final cfBundleGetMainBundle = foundation
      .lookupFunction<Pointer Function(), Pointer Function()>(
        'CFBundleGetMainBundle',
      );

  final cfBundleGetIdentifier = foundation
      .lookupFunction<Pointer Function(Pointer), Pointer Function(Pointer)>(
        'CFBundleGetIdentifier',
      );

  final bundle = cfBundleGetMainBundle();
  final identifier = cfBundleGetIdentifier(bundle);
  if (identifier == nullptr) {
    return null;
  }
  return _nsStringToString(foundation, identifier);
}

/// Converts an NSString (toll-free bridged with CFStringRef) to a Dart String.
String _nsStringToString(DynamicLibrary foundation, Pointer nsString) {
  // kCFStringEncodingUTF8 = 0x08000100
  const kCFStringEncodingUTF8 = 0x08000100;

  // Try the fast path first: CFStringGetCStringPtr returns a direct pointer
  // to the internal buffer, but may return null.
  final cfStringGetCStringPtr = foundation
      .lookupFunction<
        Pointer<Utf8> Function(Pointer, Uint32),
        Pointer<Utf8> Function(Pointer, int)
      >('CFStringGetCStringPtr');
  final cString = cfStringGetCStringPtr(nsString, kCFStringEncodingUTF8);
  if (cString != nullptr) {
    return cString.toDartString();
  }

  // Fallback: copy the string into a buffer.
  final cfStringGetLength = foundation
      .lookupFunction<Long Function(Pointer), int Function(Pointer)>(
        'CFStringGetLength',
      );
  final cfStringGetCString = foundation
      .lookupFunction<
        Bool Function(Pointer, Pointer<Utf8>, Long, Uint32),
        bool Function(Pointer, Pointer<Utf8>, int, int)
      >('CFStringGetCString');

  final length = cfStringGetLength(nsString);
  // UTF-8 can use up to 4 bytes per character, plus null terminator.
  final bufferSize = length * 4 + 1;
  final buffer = malloc<Uint8>(bufferSize);
  try {
    if (!cfStringGetCString(
      nsString,
      buffer.cast<Utf8>(),
      bufferSize,
      kCFStringEncodingUTF8,
    )) {
      throw StateError('CFStringGetCString failed for NSString conversion');
    }
    return buffer.cast<Utf8>().toDartString();
  } finally {
    malloc.free(buffer);
  }
}

Pointer _autoreleasePoolPush(DynamicLibrary foundation) {
  final push = foundation
      .lookupFunction<Pointer Function(), Pointer Function()>(
        'objc_autoreleasePoolPush',
      );
  return push();
}

void _autoreleasePoolPop(DynamicLibrary foundation, Pointer pool) {
  final pop = foundation
      .lookupFunction<Void Function(Pointer), void Function(Pointer)>(
        'objc_autoreleasePoolPop',
      );
  pop(pool);
}

// === Windows FFI helpers =====================================================

/// Calls `SHGetKnownFolderPath(FOLDERID_LocalAppData, 0, NULL, &path)` via FFI
/// to get the Local AppData directory.
///
/// Local AppData is preferred over Roaming AppData for database files because
/// they are large, machine-specific, and should not be synced via roaming
/// profiles.
String? _windowsLocalAppDataPath() {
  final shell32 = DynamicLibrary.open('shell32.dll');
  final ole32 = DynamicLibrary.open('ole32.dll');

  final shGetKnownFolderPath = shell32
      .lookupFunction<
        Int32 Function(Pointer<GUID>, Uint32, Pointer, Pointer<Pointer<Utf16>>),
        int Function(Pointer<GUID>, int, Pointer, Pointer<Pointer<Utf16>>)
      >('SHGetKnownFolderPath');

  final coTaskMemFree = ole32
      .lookupFunction<Void Function(Pointer), void Function(Pointer)>(
        'CoTaskMemFree',
      );

  // FOLDERID_LocalAppData = {F1B32785-6FBA-4FCF-9D55-7B8E7F157091}
  final folderIdPtr = _localAppDataFolderId();

  final pathPtr = malloc<Pointer<Utf16>>();

  try {
    // S_OK = 0
    final hr = shGetKnownFolderPath(folderIdPtr, 0, nullptr, pathPtr);
    if (hr != 0) {
      return null;
    }
    final path = pathPtr.value.toDartString();
    coTaskMemFree(pathPtr.value);
    return path;
  } finally {
    malloc
      ..free(pathPtr)
      ..free(folderIdPtr);
  }
}

Pointer<GUID> _localAppDataFolderId() {
  final ptr = malloc<GUID>();
  ptr.ref
    ..data1 = 0xF1B32785
    ..data2 = 0x6FBA
    ..data3 = 0x4FCF;
  ptr.ref.data4[0] = 0x9D;
  ptr.ref.data4[1] = 0x55;
  ptr.ref.data4[2] = 0x7B;
  ptr.ref.data4[3] = 0x8E;
  ptr.ref.data4[4] = 0x7F;
  ptr.ref.data4[5] = 0x15;
  ptr.ref.data4[6] = 0x70;
  ptr.ref.data4[7] = 0x91;
  return ptr;
}

/// Windows GUID struct for FFI.
final class GUID extends Struct {
  @Uint32()
  external int data1;

  @Uint16()
  external int data2;

  @Uint16()
  external int data3;

  @Array(8)
  external Array<Uint8> data4;
}
