import 'dart:io';

import 'package:cbl/cbl.dart';
// ignore: implementation_imports
import 'package:cbl/src/support/isolate.dart';
import 'package:path_provider/path_provider.dart';

/// Initializes global resources and configures global settings, such as
/// logging, for usage of Couchbase Lite in Flutter apps.
class CouchbaseLiteFlutter {
  /// Private constructor to allow control over instance creation.
  CouchbaseLiteFlutter._();

  /// Initializes the `cbl` package, for the main isolate.
  static Future<void> init() async {
    initMainIsolate(IsolateContext(
      libraries: _libraries(),
      initContext: await _context(),
    ));

    _setupLogging();
  }
}

/// Locates and returns the [Libraries] shipped by this package (`cbl_flutter`),
/// handling the differences between platforms.
Libraries _libraries() {
  if (Platform.isIOS || Platform.isMacOS) {
    return Libraries(
      cbl: LibraryConfiguration.process(),
      cblDart: LibraryConfiguration.process(),
    );
  } else if (Platform.isAndroid) {
    return Libraries(
      cbl: LibraryConfiguration.dynamic('libcblite'),
      cblDart: LibraryConfiguration.dynamic('libcblitedart'),
    );
  } else if (Platform.isLinux) {
    final bundleDirectory = _dirname(Platform.resolvedExecutable);
    final libDirectory = _joinPaths(bundleDirectory, 'lib');
    return Libraries(
      cbl: LibraryConfiguration.dynamic(
        _joinPaths(libDirectory, 'libcblite'),
        version: '3',
      ),
      cblDart: LibraryConfiguration.dynamic(
        _joinPaths(libDirectory, 'libcblitedart'),
      ),
    );
  } else {
    throw UnsupportedError('This platform is not supported.');
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

String _dirname(String path) =>
    (path.split(Platform.pathSeparator)..removeLast())
        .join(Platform.pathSeparator);

String _joinPaths(String path0, String path1) =>
    '$path0${Platform.pathSeparator}$path1';
