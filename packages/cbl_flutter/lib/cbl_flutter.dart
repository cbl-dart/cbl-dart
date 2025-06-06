// ignore_for_file: implementation_imports

import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/bindings.dart';
import 'package:cbl/src/support/isolate.dart';
import 'package:cbl/src/support/tracing.dart';
import 'package:cbl_flutter_platform_interface/cbl_flutter_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

// ignore: avoid_classes_with_only_static_members
/// Initializes global resources and configures global settings, such as
/// logging, for usage of Couchbase Lite in Flutter apps.
abstract final class CouchbaseLiteFlutter {
  /// Initializes the `cbl` package, for the main isolate.
  static Future<void> init({bool autoEnableVectorSearch = true}) =>
      asyncOperationTracePoint(InitializeOp.new, () async {
        if (Platform.isAndroid) {
          await _preloadLibrariesForAndroid();
        }

        await initPrimaryIsolate(
          IsolateContext(
            libraries: CblFlutterPlatform.instance.libraries(),
            initContext: await _context(),
          ),
          autoEnableVectorSearch: autoEnableVectorSearch,
        );
      });
}

Future<InitContext> _context() async {
  final filesDir = await getApplicationSupportDirectory();
  final clbTempDir = Directory.fromUri(filesDir.uri.resolve('CBLTemp'));
  await clbTempDir.create(recursive: true);

  return InitContext(filesDir: filesDir.path, tempDir: clbTempDir.path);
}

/// Preloads the native libraries for Android and implements a workaround for
/// loading of libraries on older Android versions.
Future<void> _preloadLibrariesForAndroid() async {
  final libraries = CblFlutterPlatform.instance.libraries();

  try {
    DynamicLibraries.fromConfig(libraries);
    // ignore: avoid_catching_errors
  } on ArgumentError {
    // If we were not able to load the libraries from Dart FFI directly,
    // load them using the Android Java API. After that, we can load the
    // libraries from Dart FFI.
    await _Native.instance.loadLibraries(
      [
        libraries.cbl.name!,
        libraries.cblDart.name!,
      ].map((name) => name.replaceFirst('lib', '')).toList(),
    );

    DynamicLibraries.fromConfig(libraries);
  }
}

class _Native {
  static final instance = _Native();

  final _methodChannel = const MethodChannel('cbl_flutter');

  Future<void> loadLibraries(List<String> libraries) async =>
      _methodChannel.invokeMethod('loadLibraries', libraries);
}
