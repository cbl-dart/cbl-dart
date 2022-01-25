import 'dart:io';

import 'package:cbl/cbl.dart';
// ignore: implementation_imports
import 'package:cbl/src/support/isolate.dart';
import 'package:cbl_flutter_platform_interface/cbl_flutter_platform_interface.dart';
import 'package:path_provider/path_provider.dart';

/// Initializes global resources and configures global settings, such as
/// logging, for usage of Couchbase Lite in Flutter apps.
class CouchbaseLiteFlutter {
  /// Private constructor to allow control over instance creation.
  CouchbaseLiteFlutter._();

  /// Initializes the `cbl` package, for the main isolate.
  static Future<void> init({TracingDelegate? tracingDelegate}) async {
    initMainIsolate(IsolateContext(
      libraries: CblFlutterPlatform.instance.libraries(),
      initContext: await _context(),
      tracingDelegate: tracingDelegate,
    ));

    _setupLogging();
  }
}

Future<InitContext> _context() async {
  final directories = await Future.wait([
    getApplicationSupportDirectory(),
    getExternalStorageDirectory().onError<UnsupportedError>((_, __) => null),
  ]);

  final filesDir = directories[0]!;

  // For temporary files, we try to use the apps external storage directory
  // and fallback to the application support directory, if it's not available.
  final tempDir = directories[1] ?? filesDir;
  final clbTempDir = Directory.fromUri(tempDir.uri.resolve('CBLTemp'));
  await clbTempDir.create();

  return InitContext(
    filesDir: filesDir.path,
    tempDir: clbTempDir.path,
  );
}

void _setupLogging() {
  Database.log
    // stdout and stderr is not visible to Flutter developers, usually. That is
    // why the console logger is disabled and a custom logger which logs to
    // Dart's `print` functions is installed.
    ..console.level = LogLevel.none
    ..custom = DartConsoleLogger(LogLevel.warning);
}
