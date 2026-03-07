import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

/// Resolves the appropriate application files directory for storing databases
/// and other app data.
///
/// Returns `null` if no app identity can be detected, in which case callers
/// should fall back to the current working directory.
///
/// Parameters can be overridden for testing. When not provided, values are read
/// from the current platform.
String? resolveAppFilesDirectory({
  String? resolvedExecutable,
  Map<String, String>? environment,
  bool? isIOS,
  bool? isMacOS,
  bool? isAndroid,
  bool? isLinux,
  bool? isWindows,
  String? iosHome,
}) {
  resolvedExecutable ??= Platform.resolvedExecutable;
  environment ??= Platform.environment;
  isIOS ??= Platform.isIOS;
  isMacOS ??= Platform.isMacOS;
  isAndroid ??= Platform.isAndroid;
  isLinux ??= Platform.isLinux;
  isWindows ??= Platform.isWindows;

  if (isIOS) {
    return _resolveIOSDirectory(iosHome);
  } else if (isMacOS) {
    return _resolveMacOSDirectory(resolvedExecutable, environment);
  } else if (isLinux) {
    return _resolveLinuxDirectory(resolvedExecutable, environment);
  } else if (isWindows) {
    return _resolveWindowsDirectory(resolvedExecutable, environment);
  }
  // Android is handled separately in CouchbaseLite.init().
  return null;
}

/// iOS: Always sandboxed. Use `<sandbox>/Library/Application Support`.
///
/// Uses `NSHomeDirectory()` via FFI to get the app sandbox home directory.
String _resolveIOSDirectory(String? iosHome) {
  final home = iosHome ?? _nsHomeDirectory();
  return p.join(home, 'Library', 'Application Support');
}

/// macOS: Detect if running inside a `.app` bundle by checking the executable
/// path structure. If a bundle identifier is found, use
/// `~/Library/Application Support/<bundleId>`.
String? _resolveMacOSDirectory(
  String resolvedExecutable,
  Map<String, String> environment,
) {
  final bundleId = detectMacOSBundleId(resolvedExecutable);
  if (bundleId == null) {
    return null;
  }
  final home = environment['HOME'];
  if (home == null) {
    return null;
  }
  return p.join(home, 'Library', 'Application Support', bundleId);
}

/// Detects the bundle identifier from a macOS `.app` bundle.
///
/// Expects the executable to be at `Foo.app/Contents/MacOS/Foo`. Reads
/// `Foo.app/Contents/Info.plist` to extract `CFBundleIdentifier`.
///
/// Visible for testing.
String? detectMacOSBundleId(String resolvedExecutable) {
  final parts = p.split(resolvedExecutable);

  // Look for the pattern: .../Foo.app/Contents/MacOS/executable
  // We need at least 3 parts above the executable: Foo.app, Contents, MacOS
  if (parts.length < 4) {
    return null;
  }

  final exeIndex = parts.length - 1;
  final macosDir = parts[exeIndex - 1];
  final contentsDir = parts[exeIndex - 2];
  final appDir = parts[exeIndex - 3];

  if (macosDir != 'MacOS' ||
      contentsDir != 'Contents' ||
      !appDir.endsWith('.app')) {
    return null;
  }

  final contentsPath = p.joinAll(parts.sublist(0, exeIndex - 1));
  final plistPath = p.join(contentsPath, 'Info.plist');

  return readBundleIdFromPlist(plistPath);
}

/// Reads the `CFBundleIdentifier` value from an XML plist file.
///
/// Visible for testing.
String? readBundleIdFromPlist(String plistPath) {
  final file = File(plistPath);
  if (!file.existsSync()) {
    return null;
  }

  final content = file.readAsStringSync();
  return parseBundleIdFromPlistXml(content);
}

/// Parses `CFBundleIdentifier` from plist XML content.
///
/// Visible for testing.
String? parseBundleIdFromPlistXml(String xml) {
  // Look for:
  //   <key>CFBundleIdentifier</key>
  //   <string>com.example.app</string>
  final keyPattern = RegExp(
    r'<key>\s*CFBundleIdentifier\s*</key>\s*<string>([^<]+)</string>',
  );
  final match = keyPattern.firstMatch(xml);
  return match?.group(1)?.trim();
}

/// Linux: Check for snap/flatpak containers, then check if running as a
/// compiled app (not the `dart` executable).
String? _resolveLinuxDirectory(
  String resolvedExecutable,
  Map<String, String> environment,
) {
  // Snap container: SNAP_USER_DATA is the app's data directory.
  final snapUserData = environment['SNAP_USER_DATA'];
  if (snapUserData != null) {
    return snapUserData;
  }

  // Flatpak container: XDG dirs are already redirected inside the sandbox.
  final flatpakId = environment['FLATPAK_ID'];
  if (flatpakId != null) {
    final xdgDataHome =
        environment['XDG_DATA_HOME'] ?? _xdgDataHomeDefault(environment);
    if (xdgDataHome != null) {
      return p.join(xdgDataHome, flatpakId);
    }
  }

  // Regular compiled app (not running via `dart` CLI).
  final appName = _detectAppName(resolvedExecutable);
  if (appName != null) {
    final xdgDataHome =
        environment['XDG_DATA_HOME'] ?? _xdgDataHomeDefault(environment);
    if (xdgDataHome != null) {
      return p.join(xdgDataHome, appName);
    }
  }

  return null;
}

/// Windows: Check if running as a compiled app (not the `dart.exe` executable).
String? _resolveWindowsDirectory(
  String resolvedExecutable,
  Map<String, String> environment,
) {
  final appName = _detectAppName(resolvedExecutable);
  if (appName == null) {
    return null;
  }

  final appData = environment['APPDATA'];
  if (appData == null) {
    return null;
  }

  return p.join(appData, appName);
}

/// Returns the default XDG_DATA_HOME path (`~/.local/share`).
String? _xdgDataHomeDefault(Map<String, String> environment) {
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

/// Calls `NSHomeDirectory()` from Foundation framework via FFI.
///
/// Returns the app's home directory. On iOS this is the sandbox root. On macOS
/// this is the user's home directory (or sandbox container if sandboxed).
String _nsHomeDirectory() {
  final foundation = DynamicLibrary.process();

  // NSHomeDirectory() returns NSString* (an Objective-C object pointer).
  final nsHomeDirectory = foundation
      .lookupFunction<Pointer Function(), Pointer Function()>(
        'NSHomeDirectory',
      );

  final nsString = nsHomeDirectory();
  return _nsStringToString(foundation, nsString);
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
      throw StateError('CFStringGetCString failed for NSHomeDirectory()');
    }
    return buffer.cast<Utf8>().toDartString();
  } finally {
    malloc.free(buffer);
  }
}
