// ignore_for_file: implementation_imports

import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/support/isolate.dart';
import 'package:cbl/src/support/tracing.dart';
import 'package:cbl_flutter_platform_interface/cbl_flutter_platform_interface.dart';
import 'package:path_provider/path_provider.dart';

/// Initializes global resources and configures global settings, such as
/// logging, for usage of Couchbase Lite in Flutter apps.
class CouchbaseLiteFlutter {
  /// Private constructor to allow control over instance creation.
  CouchbaseLiteFlutter._();

  /// Initializes the `cbl` package, for the main isolate.
  static Future<void> init() =>
      asyncOperationTracePoint(InitializeOp.new, () async {
        await initPrimaryIsolate(IsolateContext(
          libraries: CblFlutterPlatform.instance.libraries(),
          initContext: await _context(),
        ));
      });
}

Future<InitContext> _context() async {
  final directories = await Future.wait([
    getApplicationSupportDirectory(),
    if (Platform.isAndroid)
      getExternalStorageDirectory()
    else
      Future<Directory?>.value()
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
