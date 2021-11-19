import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:path/path.dart' as p;

import 'install_libraries.dart';
import 'package.dart';

/// Ensures that the latest releases of the libraries are installed and
/// returns the corresponding [LibrariesConfiguration] configuration.
///
/// See [Package.latestReleases] for the releases installed by this function.
///
/// [edition] is the edition of Couchbase Lite to install.
///
/// [mergedNativeLibrariesDir] is the directory where the native libraries will
/// be installed. If not specified, the platform specific, system-wide default
/// directory will be used.
Future<LibrariesConfiguration> acquireLibraries({
  required Edition edition,
  String? mergedNativeLibrariesDir,
}) async {
  mergedNativeLibrariesDir ??= _sharedMergedNativesLibrariesDir();
  await Directory(mergedNativeLibrariesDir).create(recursive: true);

  final packages = Library.values.map((library) => Package(
        library: library,
        release: Package.latestReleases[library]!,
        edition: edition,
        target: Target.host,
      ));

  if (!areMergedNativeLibrariesInstalled(
    packages,
    directory: mergedNativeLibrariesDir,
  )) {
    await installMergedNativeLibraries(
      packages,
      directory: mergedNativeLibrariesDir,
    );
  }

  return mergedNativeLibrariesConfigurations(
    packages,
    directory: mergedNativeLibrariesDir,
  );
}

String get _homeDir {
  if (Platform.isMacOS || Platform.isLinux) {
    return Platform.environment['HOME']!;
  }

  if (Platform.isWindows) {
    return Platform.environment['USERPROFILE']!;
  }

  throw UnsupportedError('Not supported on this platform.');
}

String? sharedCacheDirOverride;

String _sharedCacheDir() {
  if (sharedCacheDirOverride != null) {
    return sharedCacheDirOverride!;
  }

  if (Platform.isMacOS) {
    return '$_homeDir/Library/Caches/cbl_dart';
  }

  if (Platform.isLinux) {
    return '$_homeDir/.cache/cbl_dart';
  }

  if (Platform.isWindows) {
    return '$_homeDir/AppData/Local/cbl_dart';
  }

  throw UnsupportedError('Unsupported platform.');
}

String _sharedMergedNativesLibrariesDir() =>
    p.join(_sharedCacheDir(), 'merged_native_libraries');
