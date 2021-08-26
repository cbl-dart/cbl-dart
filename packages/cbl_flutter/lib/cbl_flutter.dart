import 'dart:io';

import 'package:cbl/cbl.dart';
// ignore: implementation_imports
import 'package:cbl/src/couchbase_lite.dart';
import 'package:cbl_ffi/cbl_ffi.dart' as ffi;
import 'package:path_provider/path_provider.dart';

/// Initializes global resources and configures global settings, such as
/// logging, for usage of Couchbase Lite in Flutter apps.
class CouchbaseLiteFlutter {
  /// Private constructor to allow control over instance creation.
  CouchbaseLiteFlutter._();

  /// Initializes the `cbl` package.
  static Future<void> init() async => initMainIsolate(
        libraries: _libraries(),
        context: await _context(),
      );
}

/// Locates and returns the [Libraries] shipped by this package (`cbl_flutter`),
/// handling the differences between platforms.
ffi.Libraries _libraries() {
  if (Platform.isIOS || Platform.isMacOS) {
    return ffi.Libraries(
      cbl: ffi.LibraryConfiguration(process: true),
      cblDart: ffi.LibraryConfiguration(process: true),
    );
  } else if (Platform.isAndroid) {
    return ffi.Libraries(
      cbl: ffi.LibraryConfiguration(
        name: 'libcblite',
        appendExtension: true,
      ),
      cblDart: ffi.LibraryConfiguration(
        name: 'libcblitedart',
        appendExtension: true,
      ),
    );
  } else {
    throw UnsupportedError('This platform is not supported.');
  }
}

Future<ffi.CBLInitContext?> _context() async {
  if (Platform.isAndroid) {
    final filesDir = await getApplicationSupportDirectory();
    final externalFilesDir = await getExternalStorageDirectory();
    final tempDir = Directory.fromUri(externalFilesDir!.uri.resolve('CBLTemp'));
    await tempDir.create();
    return ffi.CBLInitContext(
      filesDir: filesDir.path,
      tempDir: tempDir.path,
    );
  }
}
