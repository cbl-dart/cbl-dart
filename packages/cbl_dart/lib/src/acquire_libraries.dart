import 'dart:io';
import 'dart:isolate';

import 'package:cbl/cbl.dart';
import 'package:path/path.dart' as p;

import '../cbl_dart.dart';
import 'install_libraries.dart';
import 'package.dart';

/// Libraries that should be used instead of downloading and installing them.
///
/// This is used during development and testing of CBL Dart.
///
/// See:
///
/// - [setupDevelopmentLibraries]
LibrariesConfiguration? _librariesOverride;

/// Setup local development libraries that will be used instead of the
/// published libraries.
///
/// This function must be called before [CouchbaseLiteDart.init] to have
/// an effect.
Future<void> setupDevelopmentLibraries() async {
  final cblDartPackageEntryLibrary = (await Isolate.resolvePackageUri(
    Uri.parse('package:cbl_dart/cbl_dart.dart'),
  ))!;

  final cblDartPackageDir = p.join(cblDartPackageEntryLibrary.path, '../..');
  assert(cblDartPackageDir.contains('packages/cbl_dart'));
  final standaloneDartTestPackageDir = p.normalize(
    p.join(cblDartPackageDir, '..', 'cbl_e2e_tests_standalone_dart'),
  );

  const enterpriseEdition = true;

  String? directory;
  String cblLib;
  String cblDartLib;

  final libDir = p.join(standaloneDartTestPackageDir, 'lib');
  final isUnix = Platform.isLinux || Platform.isMacOS;
  if (isUnix && FileSystemEntity.isDirectorySync(libDir)) {
    directory = libDir;
    cblLib = 'libcblite';
    cblDartLib = 'libcblitedart';
  } else if (Platform.isMacOS) {
    directory = p.join(standaloneDartTestPackageDir, 'Frameworks');
    cblLib = 'CouchbaseLite';
    cblDartLib = 'CouchbaseLiteDart';
  } else if (Platform.isWindows) {
    directory = p.join(standaloneDartTestPackageDir, 'bin');
    cblLib = 'cblite';
    cblDartLib = 'cblitedart';
  } else {
    throw StateError('Could not find libraries for current platform');
  }

  _librariesOverride = LibrariesConfiguration(
    enterpriseEdition: enterpriseEdition,
    directory: directory,
    cbl: LibraryConfiguration.dynamic(cblLib),
    cblDart: LibraryConfiguration.dynamic(cblDartLib),
  );
}

/// Ensures that the latest releases of the libraries are installed and returns
/// the corresponding [LibrariesConfiguration] configuration.
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
  if (_librariesOverride != null) {
    assert(mergedNativeLibrariesDir == null);
    assert((edition == Edition.enterprise) ==
        _librariesOverride!.enterpriseEdition);
    return _librariesOverride!;
  }

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
