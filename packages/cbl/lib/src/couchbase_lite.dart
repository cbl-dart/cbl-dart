import 'dart:io';
import 'dart:isolate';

import 'bindings.dart';
import 'bindings/cblite_native_assets_bridge.dart';
import 'bindings/cblite_vector_search.dart' as vector_search;
import 'bindings/cblitedart_native_assets.dart' as cblitedart_native;
import 'bindings/cblitedart_native_assets_bridge.dart';
import 'database/database.dart';
import 'log.dart';
import 'support/isolate.dart';
import 'support/tracing.dart';
import 'tracing.dart';

export 'support/listener_token.dart' show ListenerToken;
export 'support/resource.dart' show Resource, ClosableResource;
export 'support/streams.dart' show AsyncListenStream;

/// Initializes global resources and configures global settings, such as
/// logging.
abstract final class CouchbaseLite {
  /// Initializes the `cbl` package, for the main isolate.
  ///
  /// With native assets, libraries are loaded automatically by the Dart VM. No
  /// manual library configuration is needed. The edition and optional features
  /// are configured via user defines in `pubspec.yaml`:
  ///
  /// ```yaml
  /// hooks:
  ///   user_defines:
  ///     cbl:
  ///       edition: enterprise
  ///       vector_search: true
  /// ```
  ///
  /// If specified, [filesDir] is used to store files created by Couchbase Lite
  /// by default. For example if a [Database] is opened or copied without
  /// specifying a directory, a subdirectory in the directory specified here
  /// will be used. If no [filesDir] directory is provided, the working
  /// directory is used when opening and copying databases.
  static Future<void> init({String? filesDir}) =>
      asyncOperationTracePoint(InitializeOp.new, () async {
        // On Android, filesDir is required. Auto-detect it from the package
        // name if not explicitly provided.
        final resolvedFilesDir =
            filesDir ??
            (Platform.isAndroid ? await _resolveAndroidFilesDir() : null);

        final context = resolvedFilesDir == null
            ? null
            : await _initContext(resolvedFilesDir);

        // Try to discover the vector search library path. If the extension
        // was bundled by the build hook, Native.addressOf will resolve the
        // symbol and we can find the library directory. If not bundled, the
        // symbol resolution will fail and we get null.
        final vectorSearchPath = _tryGetVectorSearchPath();

        final bindingsLibraries = BindingsLibraries(
          enterpriseEdition: cblitedart_native.CBLDart_IsEnterprise(),
          vectorSearchLibraryPath: vectorSearchPath,
          cblite: const cbliteNativeAssetsBridge(),
          cblitedart: const cblitedartNativeAssetsBridge(),
        );

        await initPrimaryIsolate(
          IsolateContext(
            initContext: context,
            bindings: CBLBindings(bindingsLibraries),
            bindingsLibraries: bindingsLibraries,
          ),
          autoEnableVectorSearch: true,
        );

        _setupLogging();
      });

  /// Context object to pass to [initSecondary], when initializing a secondary
  /// [Isolate].
  ///
  /// This object can be safely passed from one [Isolate] to another.
  static Object get context => IsolateContext.instance.forSecondaryIsolate();

  /// Initializes the `cbl` package, for a secondary isolate.
  ///
  /// A value for [context] can be obtained from [CouchbaseLite.context].
  static Future<void> initSecondary(Object context) =>
      asyncOperationTracePoint(InitializeOp.new, () async {
        if (context is! IsolateContext) {
          throw ArgumentError.value(context, 'context', 'is invalid');
        }

        await initSecondaryIsolate(context);
      });
}

/// Tries to resolve the vector search library directory path using native
/// assets symbol resolution. Returns null if the extension is not bundled.
String? _tryGetVectorSearchPath() {
  try {
    return vector_search.vectorSearchLibraryPath;
  } on Object {
    // The vector search extension is not bundled, so the @Native symbol
    // resolution fails. This is expected and not an error.
    return null;
  }
}

/// Resolves the Android app's files directory from the package name.
///
/// Reads `/proc/self/cmdline` to determine the package name and constructs the
/// standard app data path. This avoids depending on Flutter or any platform
/// channel.
Future<String> _resolveAndroidFilesDir() async {
  final cmdlineBytes = File('/proc/self/cmdline').readAsBytesSync();
  final nullIndex = cmdlineBytes.indexOf(0);
  final packageName = String.fromCharCodes(
    nullIndex == -1 ? cmdlineBytes : cmdlineBytes.sublist(0, nullIndex),
  );
  final dir = '/data/data/$packageName/files';
  await Directory(dir).create(recursive: true);
  return dir;
}

Future<InitContext> _initContext(String filesDir) async {
  await Directory(filesDir).create(recursive: true);
  return InitContext(filesDir: filesDir, tempDir: filesDir);
}

void _setupLogging() {
  Database.log.console.level = LogLevel.warning;
}
