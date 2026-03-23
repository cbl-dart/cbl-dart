import 'dart:io';

import '../bindings/base.dart';
import '../bindings/tracing.dart' show onTracedCall;
import 'app_directory.dart';
import 'tracing.dart';

class InitContext {
  InitContext({required this.filesDir, required this.tempDir});

  final String filesDir;
  final String tempDir;

  CBLInitContext toCbl() =>
      CBLInitContext(filesDir: filesDir, tempDir: tempDir);
}

final _bootstrapState = _IsolateBootstrapState();

/// Lazily bootstraps Couchbase Lite for the current isolate.
///
/// Call this at the start of a standalone API or binding implementation when
/// that API can be the first entry point in the current isolate that touches
/// native Couchbase Lite state.
///
/// Do not call this from inside allocation-management helpers such as
/// `withGlobalArena` or `runWithSingleFLString`. Bootstrap the isolate before
/// entering those helpers so initialization does not happen while temporary
/// allocation lifetimes are already active, and so entry points follow one
/// consistent structure.
///
/// Implementations that are only reachable after another entry point has
/// already bootstrapped the isolate do not need to call this again unless they
/// are also public entry points that can be invoked independently.
void ensureInitializedForCurrentIsolate() =>
    _bootstrapState.ensureInitializedForCurrentIsolate();

String get defaultDatabaseDirectory => _bootstrapState.defaultDatabaseDirectory;

void setDefaultDatabaseDirectory(String? value) {
  _bootstrapState.defaultDatabaseDirectoryOverride = value;
}

final class _IsolateBootstrapState {
  var _isInitialized = false;
  String? defaultDatabaseDirectoryOverride;
  InitContext? _initContext;

  String get defaultDatabaseDirectory =>
      defaultDatabaseDirectoryOverride ?? _resolvedDefaultDatabaseDirectory();

  void ensureInitializedForCurrentIsolate() {
    if (_isInitialized) {
      return;
    }

    final initContext = _ensureInitContextDirectories();

    onTracedCall = tracingDelegateTracedNativeCallHandler;
    BaseBindings.initializeNativeLibraries(initContext?.toCbl());

    _isInitialized = true;
  }

  InitContext? _ensureInitContextDirectories() {
    final initContext = _resolvedInitContext();
    if (initContext == null) {
      return null;
    }

    Directory(initContext.filesDir).createSync(recursive: true);
    Directory(initContext.tempDir).createSync(recursive: true);

    return initContext;
  }

  InitContext? _resolvedInitContext() => _initContext ??= () {
    final resolvedFilesDir = resolveAppFilesDirectory();
    if (resolvedFilesDir == null) {
      return null;
    }

    return InitContext(
      filesDir: resolvedFilesDir,
      tempDir: Platform.isAndroid
          ? resolveAndroidCacheDirectory()
          : resolvedFilesDir,
    );
  }();

  String _resolvedDefaultDatabaseDirectory() {
    final filesDir = _resolvedInitContext()?.filesDir;
    if (filesDir != null) {
      return '$filesDir${Platform.pathSeparator}CouchbaseLite';
    }

    return Directory.current.path;
  }
}
