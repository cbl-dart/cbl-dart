import 'dart:io';

// ignore: implementation_imports
import 'package:cbl/src/init.dart';
import 'package:cbl_ffi/cbl_ffi.dart';
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
Libraries _libraries() {
  if (Platform.isIOS || Platform.isMacOS) {
    return Libraries(
      cbl: LibraryConfiguration(process: true),
      cblDart: LibraryConfiguration(process: true),
    );
  } else if (Platform.isAndroid) {
    return Libraries(
      cbl: LibraryConfiguration(
        name: 'libcblite',
        appendExtension: true,
      ),
      cblDart: LibraryConfiguration(
        name: 'libcblitedart',
        appendExtension: true,
      ),
    );
  } else {
    throw UnsupportedError('This platform is not supported.');
  }
}

Future<CBLInitContext?> _context() async {
  if (Platform.isAndroid) {
    final filesDir = await getApplicationSupportDirectory();
    final externalFilesDir = await getExternalStorageDirectory();
    final tempDir = Directory.fromUri(externalFilesDir!.uri.resolve('CBLTemp'));
    await tempDir.create();
    return CBLInitContext(
      filesDir: filesDir.path,
      tempDir: tempDir.path,
    );
  }
}
