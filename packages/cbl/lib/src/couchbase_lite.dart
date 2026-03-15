import 'dart:io';
import 'dart:isolate';

import 'database/database.dart';
import 'extension.dart';
import 'log.dart';
import 'support/app_directory.dart';
import 'support/isolate.dart';
import 'support/tracing.dart';
import 'tracing.dart';

export 'support/listener_token.dart' show ListenerToken;
export 'support/resource.dart' show ClosableResource, Resource;
export 'support/streams.dart' show AsyncListenStream;

/// Initializes global resources and configures global settings, such as
/// logging.
abstract final class CouchbaseLite {
  /// Initializes the `cbl` package, for the main isolate.
  ///
  /// With native assets, libraries are loaded automatically by the Dart VM. No
  /// manual library configuration is needed. The edition and optional features
  /// are configured via `hooks.user_defines.cbl` in your package
  /// `pubspec.yaml`:
  ///
  /// ```yaml
  /// hooks:
  ///   user_defines:
  ///     cbl:
  ///       edition: enterprise
  ///       vector_search: true
  /// ```
  ///
  /// In a pub workspace, user defines are read from the workspace root
  /// `pubspec.yaml`, so place this configuration there instead.
  ///
  /// If specified, [filesDir] is used to store files created by Couchbase Lite
  /// by default. For example if a [Database] is opened or copied without
  /// specifying a directory, a subdirectory in the directory specified here
  /// will be used. If [filesDir] is not provided, the platform's standard app
  /// data directory is used for mobile and deployed desktop applications. When
  /// running during development (e.g. via `dart run`), the current working
  /// directory is used.
  ///
  /// Vector search is not enabled automatically. If you enabled
  /// `vector_search: true`, call [Extension.enableVectorSearch] after
  /// initialization and before opening a database that uses vector search.
  static Future<void> init({String? filesDir}) =>
      asyncOperationTracePoint(InitializeOp.new, () async {
        final context = await _initContext(filesDir);

        await initPrimaryIsolate(IsolateContext(initContext: context));

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

Future<InitContext?> _initContext(String? filesDir) async {
  // Auto-detect the app files directory from the platform if not
  // explicitly provided.
  final resolvedFilesDir = filesDir ?? resolveAppFilesDirectory();
  if (resolvedFilesDir == null) {
    return null;
  }

  await Directory(resolvedFilesDir).create(recursive: true);

  String tempDir;
  if (Platform.isAndroid) {
    tempDir = resolveAndroidCacheDirectory();
    await Directory(tempDir).create(recursive: true);
  } else {
    tempDir = resolvedFilesDir;
  }

  return InitContext(filesDir: resolvedFilesDir, tempDir: tempDir);
}

void _setupLogging() {
  Database.log.console.level = LogLevel.warning;
}
