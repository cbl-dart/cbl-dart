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
///
/// # Windows
///
/// The libraries are expected to be located next to the app executable, with
/// the names `cblite.dll` and `cblitedart.dll`.
class StandardCblFlutterPlatform extends CblFlutterPlatform {
  StandardCblFlutterPlatform({required this.enterpriseEdition});

  /// Whether the provided [libraries] are the enterprise edition.
  final bool enterpriseEdition;

  @override
  LibrariesConfiguration libraries() {
    String? directory;
    final LibraryConfiguration cbl;
    final LibraryConfiguration cblDart;

    if (Platform.isIOS || Platform.isMacOS) {
      cbl = cblDart = LibraryConfiguration.process();
    } else if (Platform.isAndroid || Platform.isLinux) {
      if (Platform.isLinux) {
        directory = _joinPaths(_dirname(Platform.resolvedExecutable), 'lib');
      }
      cbl = LibraryConfiguration.dynamic('libcblite');
      cblDart = LibraryConfiguration.dynamic('libcblitedart');
    } else if (Platform.isWindows) {
      cbl = LibraryConfiguration.dynamic('cblite');
      cblDart = LibraryConfiguration.dynamic('cblitedart');
    } else {
      throw UnsupportedError('This platform is not supported.');
    }

    return LibrariesConfiguration(
      enterpriseEdition: enterpriseEdition,
      directory: directory,
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
