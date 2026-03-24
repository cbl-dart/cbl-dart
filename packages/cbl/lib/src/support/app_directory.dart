import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

/// Resolves the platform's standard app data directory for storing databases
/// and other app data.
///
/// Returns the app data directory for mobile and deployed desktop applications.
/// Returns `null` when running during development (e.g. via `dart run`), in
/// which case callers should fall back to the current working directory.
///
/// Parameters can be overridden for testing. When not provided, values are read
/// from the current platform or resolved via platform APIs.
String? resolveAppFilesDirectory({
  String? resolvedExecutable,
  Map<String, String>? environment,
  bool? isIOS,
  bool? isMacOS,
  bool? isAndroid,
  bool? isLinux,
  bool? isWindows,
  String? iosAppSupportDir,
  String? macOSBundleId,
  String? macOSAppSupportDir,
  String? androidPackageName,
  String? linuxXdgDataHome,
  String? windowsAppDataDir,
}) {
  resolvedExecutable ??= Platform.resolvedExecutable;
  environment ??= Platform.environment;
  isIOS ??= Platform.isIOS;
  isMacOS ??= Platform.isMacOS;
  isAndroid ??= Platform.isAndroid;
  isLinux ??= Platform.isLinux;
  isWindows ??= Platform.isWindows;

  if (isIOS) {
    return _resolveIOSDirectory(iosAppSupportDir);
  } else if (isMacOS) {
    return _resolveMacOSDirectory(macOSBundleId, macOSAppSupportDir);
  } else if (isAndroid) {
    return _resolveAndroidDirectory(androidPackageName);
  } else if (isLinux) {
    return _resolveLinuxDirectory(
      resolvedExecutable,
      environment,
      linuxXdgDataHome,
    );
  } else if (isWindows) {
    return _resolveWindowsDirectory(resolvedExecutable, windowsAppDataDir);
  }
  return null;
}

/// iOS: Always sandboxed. Use the platform Application Support directory.
///
/// Uses `NSSearchPathForDirectoriesInDomains` via FFI to get the sandboxed
/// Application Support path directly.
String _resolveIOSDirectory(String? appSupportDir) =>
    appSupportDir ?? _nsSearchPathForApplicationSupport();

/// Android: Resolve the app's files directory from the package name.
///
/// Reads `/proc/self/cmdline` to determine the package name and constructs the
/// standard app data path. This avoids depending on Flutter or any platform
/// channel.
String _resolveAndroidDirectory(String? packageName) {
  final name = packageName ?? _readAndroidPackageName();
  return '/data/data/$name/files';
}

/// Android: Resolve the app's cache directory from the package name.
///
/// This is used as the temporary directory for Couchbase Lite on Android.
String resolveAndroidCacheDirectory({String? packageName}) {
  final name = packageName ?? _readAndroidPackageName();
  return '/data/data/$name/cache';
}

/// Reads the Android package name from `/proc/self/cmdline`.
///
/// Visible for testing.
String readAndroidPackageName() => _readAndroidPackageName();

String _readAndroidPackageName() {
  final cmdlineBytes = File('/proc/self/cmdline').readAsBytesSync();
  final nullIndex = cmdlineBytes.indexOf(0);
  return String.fromCharCodes(
    nullIndex == -1 ? cmdlineBytes : cmdlineBytes.sublist(0, nullIndex),
  );
}

/// macOS: Use `CFBundleGetIdentifier` to detect if running inside a `.app`
/// bundle. If a bundle identifier is found, use
/// `<Application Support>/<bundleId>`.
String? _resolveMacOSDirectory(String? bundleId, String? appSupportDir) {
  final resolvedBundleId = bundleId ?? _cfBundleIdentifier();
  if (resolvedBundleId == null) {
    return null;
  }
  final resolvedAppSupportDir =
      appSupportDir ?? _nsSearchPathForApplicationSupport();
  return p.join(resolvedAppSupportDir, resolvedBundleId);
}

/// Linux: Check for snap/flatpak containers, then check if running as a
/// compiled app (not the `dart` executable).
String? _resolveLinuxDirectory(
  String resolvedExecutable,
  Map<String, String> environment,
  String? xdgDataHome,
) {
  // Snap container: SNAP_USER_DATA is the app's data directory.
  final snapUserData = environment['SNAP_USER_DATA'];
  if (snapUserData != null) {
    return snapUserData;
  }

  // Flatpak container: XDG dirs are already redirected inside the sandbox,
  // so use XDG_DATA_HOME directly instead of nesting the app id again.
  final flatpakId = environment['FLATPAK_ID'];
  if (flatpakId != null) {
    final dataHome = xdgDataHome ?? _xdgDataHome(environment);
    if (dataHome != null) {
      return dataHome;
    }
  }

  // Regular compiled app (not running via `dart` CLI).
  final appName = _detectAppName(resolvedExecutable);
  if (appName != null) {
    final dataHome = xdgDataHome ?? _xdgDataHome(environment);
    if (dataHome != null) {
      return p.join(dataHome, appName);
    }
  }

  return null;
}

/// Windows: Check if running as a compiled app (not the `dart.exe` executable).
///
/// Uses `SHGetKnownFolderPath` via FFI to get the Roaming AppData path.
String? _resolveWindowsDirectory(
  String resolvedExecutable,
  String? appDataDir,
) {
  final appName = _detectAppName(resolvedExecutable);
  if (appName == null) {
    return null;
  }

  final appData = appDataDir ?? _windowsRoamingAppDataPath();
  if (appData == null) {
    return null;
  }

  return p.join(appData, appName);
}

/// Resolves the XDG data home directory.
///
/// Reads the `XDG_DATA_HOME` environment variable, falling back to
/// `$HOME/.local/share`.
///
/// Visible for testing.
String? xdgDataHome({Map<String, String>? environment}) =>
    _xdgDataHome(environment ?? Platform.environment);

String? _xdgDataHome(Map<String, String> environment) {
  final xdgDataHome = environment['XDG_DATA_HOME'];
  if (xdgDataHome != null) {
    return xdgDataHome;
  }
  final home = environment['HOME'];
  if (home == null) {
    return null;
  }
  return p.join(home, '.local', 'share');
}

/// Detects the app name from the resolved executable path.
///
/// Returns `null` if the executable appears to be the Dart CLI itself,
/// indicating a development/CLI context where the current working directory
/// should be used instead.
///
/// Visible for testing.
String? detectAppName(String resolvedExecutable) =>
    _detectAppName(resolvedExecutable);

String? _detectAppName(String resolvedExecutable) {
  final name = p.basenameWithoutExtension(resolvedExecutable);

  // If the executable is `dart` or `dart.exe`, we're running via the Dart CLI
  // (e.g., `dart run`, `dart test`), not as a compiled app.
  if (name == 'dart') {
    return null;
  }

  // Flutter test runner uses an executable like `flutter_tester`.
  if (name == 'flutter_tester') {
    return null;
  }

  return name;
}

// === Apple FFI helpers ======================================================

/// Returns the Application Support directory via
/// `NSSearchPathForDirectoriesInDomains`.
///
/// Visible for testing.
String nsSearchPathForApplicationSupport() =>
    _nsSearchPathForApplicationSupport();

/// Returns the main bundle identifier via `CFBundleGetIdentifier`, or `null` if
/// not running inside a `.app` bundle.
///
/// Visible for testing.
String? cfBundleIdentifier() => _cfBundleIdentifier();

/// Calls `NSSearchPathForDirectoriesInDomains` with
/// `NSApplicationSupportDirectory` and `NSUserDomainMask` via FFI.
///
/// Returns the first path from the result array, which is the Application
/// Support directory for the current user.
String _nsSearchPathForApplicationSupport() {
  final foundation = DynamicLibrary.process();

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

  final array = nsSearchPath(14, 1, 1);
  final firstElement = cfArrayGetValueAtIndex(array, 0);
  return _nsStringToString(foundation, firstElement);
}

/// Calls `CFBundleGetMainBundle()` and `CFBundleGetIdentifier()` via FFI.
///
/// Returns the bundle identifier string, or `null` if the main bundle has no
/// identifier (e.g. when running via `dart run` or as a standalone executable).
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

// === Windows FFI helpers ====================================================

/// Returns the Roaming AppData directory via `SHGetKnownFolderPath`.
///
/// Visible for testing.
String? windowsRoamingAppDataPath() => _windowsRoamingAppDataPath();

/// Calls `SHGetKnownFolderPath(FOLDERID_RoamingAppData, 0, NULL, &path)` via
/// FFI to get the Roaming AppData directory.
String? _windowsRoamingAppDataPath() {
  final shell32 = DynamicLibrary.open('shell32.dll');
  final ole32 = DynamicLibrary.open('ole32.dll');

  // SHGetKnownFolderPath(REFKNOWNFOLDERID, DWORD, HANDLE, PWSTR*)
  final shGetKnownFolderPath = shell32
      .lookupFunction<
        Int32 Function(Pointer<GUID>, Uint32, Pointer, Pointer<Pointer<Utf16>>),
        int Function(Pointer<GUID>, int, Pointer, Pointer<Pointer<Utf16>>)
      >('SHGetKnownFolderPath');

  final coTaskMemFree = ole32
      .lookupFunction<Void Function(Pointer), void Function(Pointer)>(
        'CoTaskMemFree',
      );

  // FOLDERID_RoamingAppData = {3EB685DB-65F9-4CF6-A03A-E3EF65729F3D}
  final folderIdPtr = _roamingAppDataFolderId();

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

Pointer<GUID> _roamingAppDataFolderId() {
  final ptr = malloc<GUID>();
  ptr.ref
    ..data1 = 0x3EB685DB
    ..data2 = 0x65F9
    ..data3 = 0x4CF6
    ..data4_0 = 0xA0
    ..data4_1 = 0x3A
    ..data4_2 = 0xE3
    ..data4_3 = 0xEF
    ..data4_4 = 0x65
    ..data4_5 = 0x72
    ..data4_6 = 0x9F
    ..data4_7 = 0x3D;
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

  @Uint8()
  external int data4_0;

  @Uint8()
  external int data4_1;

  @Uint8()
  external int data4_2;

  @Uint8()
  external int data4_3;

  @Uint8()
  external int data4_4;

  @Uint8()
  external int data4_5;

  @Uint8()
  external int data4_6;

  @Uint8()
  external int data4_7;
}
