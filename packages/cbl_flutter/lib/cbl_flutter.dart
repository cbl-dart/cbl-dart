import 'dart:io';

import 'package:cbl/cbl.dart';

/// Locates and returns the [Libraries] shipped by this package (`cbl_flutter`),
/// handling the differences between platforms.
Libraries flutterLibraries() {
  if (Platform.isIOS || Platform.isMacOS) {
    return Libraries(
      cbl: LibraryConfiguration.executable(),
      cblDart: LibraryConfiguration.executable(),
    );
  } else {
    throw UnsupportedError('This platform is not supported.');
  }
}
