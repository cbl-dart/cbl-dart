import 'dart:io';

import 'package:cbl/cbl.dart';

import 'cbl_flutter_platform_interface.dart';

/// [CblFlutterPlatform] implementation which expects to be able to access the
/// native libraries (`cblite` and `cblitedart`) through a platform specific
/// standard mechanism.
///
/// Platform implementations must ensure that the native libraries are bundled
/// with the Flutter app so that they are locatable through the mechanism
/// described below.
///
/// # iOS and macOS
///
/// The libraries are expected to be linked as dependent libraries, which are
/// loaded before the app starts to execute and whose symbols are available in
/// the process.
///
/// # Android
///
/// The libraries are expected to be loadable by the dynamic linker as
/// `libcblite.so` and `libcblitedart.so`.
///
/// # Linux
///
/// The libraries are expected to be located in the directory `lib`, next to the
/// app executable, with the names `libcblite.so` and `libcblitedart.so`.
class StandardCblFlutterPlatform extends CblFlutterPlatform {
  StandardCblFlutterPlatform({required this.enterpriseEdition});

  /// Whether the provided [libraries] are the enterprise edition.
  final bool enterpriseEdition;

  @override
  Libraries libraries() {
    late final LibraryConfiguration cbl;
    late final LibraryConfiguration cblDart;

    if (Platform.isIOS || Platform.isMacOS) {
      cbl = LibraryConfiguration.process();
      cblDart = LibraryConfiguration.process();
    } else if (Platform.isAndroid) {
      cbl = LibraryConfiguration.dynamic('libcblite');
      cblDart = LibraryConfiguration.dynamic('libcblitedart');
    } else if (Platform.isLinux) {
      final bundleDirectory = _dirname(Platform.resolvedExecutable);
      final libDirectory = _joinPaths(bundleDirectory, 'lib');
      cbl = LibraryConfiguration.dynamic(
        _joinPaths(libDirectory, 'libcblite'),
      );
      cblDart = LibraryConfiguration.dynamic(
        _joinPaths(libDirectory, 'libcblitedart'),
      );
    } else {
      throw UnsupportedError('This platform is not supported.');
    }

    return Libraries(
      enterpriseEdition: enterpriseEdition,
      cbl: cbl,
      cblDart: cblDart,
    );
  }
}

String _dirname(String path) =>
    (path.split(Platform.pathSeparator)..removeLast())
        .join(Platform.pathSeparator);

String _joinPaths(String path0, String path1) =>
    '$path0${Platform.pathSeparator}$path1';
