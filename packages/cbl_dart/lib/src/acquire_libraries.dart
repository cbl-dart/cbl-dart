import 'dart:io';
import 'dart:isolate';

import 'package:cbl/cbl.dart';
// ignore: implementation_imports
import 'package:cbl/src/install.dart';
import 'package:path/path.dart' as p;

import '../cbl_dart.dart';
import 'install_libraries.dart';
import 'logging.dart';
import 'version_info.dart';

/// Libraries that should be used instead of downloading and installing them.
///
/// This is used during development and testing of CBL Dart.
///
/// See:
///
/// - [setupDevelopmentLibraries]
LibrariesConfiguration? _librariesOverride;

/// Setup local development libraries that will be used instead of the published
/// libraries.
///
/// This function must be called before [CouchbaseLiteDart.init] to have an
/// effect.
Future<void> setupDevelopmentLibraries({
  String? standaloneDartE2eTestDir,
}) async {
  const enterpriseEdition = true;

  String? directory;
  String cblLib;
  String cblDartLib;
  String vectorSearchLib;

  // TODO(blaugold): store development libraries in cbl_dart package
  // The standalone Dart e2e test directory is where the development libraries
  // have historically been located.
  standaloneDartE2eTestDir ??= await _resolveStandaloneDartE2eTestDir();
  final libDir = p.join(standaloneDartE2eTestDir, 'lib');
  final isUnix = Platform.isLinux || Platform.isMacOS;
  if (isUnix && FileSystemEntity.isDirectorySync(libDir)) {
    directory = libDir;
    cblLib = 'libcblite';
    cblDartLib = 'libcblitedart';
    vectorSearchLib = 'CouchbaseLiteVectorSearch';
  } else if (Platform.isMacOS) {
    directory = p.join(standaloneDartE2eTestDir, 'Frameworks');
    cblLib = 'CouchbaseLite';
    cblDartLib = 'CouchbaseLiteDart';
    vectorSearchLib = 'CouchbaseLiteVectorSearch';
  } else if (Platform.isWindows) {
    directory = p.join(standaloneDartE2eTestDir, 'bin');
    cblLib = 'cblite';
    cblDartLib = 'cblitedart';
    vectorSearchLib = 'CouchbaseLiteVectorSearch';
  } else {
    throw StateError('Could not find libraries for current platform');
  }

  _librariesOverride = LibrariesConfiguration(
    enterpriseEdition: enterpriseEdition,
    directory: directory,
    cbl: LibraryConfiguration.dynamic(cblLib),
    cblDart: LibraryConfiguration.dynamic(cblDartLib),
    vectorSearch: LibraryConfiguration.dynamic(
      vectorSearchLib,
      isAppleFramework: Platform.isMacOS,
    ),
  );
}

Future<String> _resolveStandaloneDartE2eTestDir() async {
  final cblDartPackageEntryLibrary = (await Isolate.resolvePackageUri(
    Uri.parse('package:cbl_dart/cbl_dart.dart'),
  ))!;
  assert(cblDartPackageEntryLibrary.path.contains('packages/cbl_dart'));

  final cblDartDir = p.join(cblDartPackageEntryLibrary.toFilePath(), '..', '..');

  return p.normalize(p.join(cblDartDir, '..', 'cbl_e2e_tests_standalone_dart'));
}

String? cblDartSharedCacheDirOverride;

String get cblDartSharedCacheDir => cblDartSharedCacheDirOverride ?? p.join(userCachesDir, 'cbl_dart');

String sharedMergedNativesLibrariesDir = p.join(cblDartSharedCacheDir, 'merged_native_libraries');

/// Ensures that the latest releases of the libraries are installed and returns
/// the corresponding [LibrariesConfiguration] configuration.
///
/// See [latestReleases] for the releases installed by this function.
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
  logger.fine('Acquiring libraries');
  print('what is this path??? ${sharedMergedNativesLibrariesDir}');

  if (mergedNativeLibrariesDir != null && !Directory(sharedMergedNativesLibrariesDir).existsSync()) {
    // then lets copy our files to this location
    await copyDirectoryContents(mergedNativeLibrariesDir, sharedMergedNativesLibrariesDir);
  }

  if (mergedNativeLibrariesDir != null) sharedMergedNativesLibrariesDir = mergedNativeLibrariesDir;

  if (Platform.isWindows) {
    return LibrariesConfiguration(
      enterpriseEdition: edition == Edition.enterprise,
      directory: mergedNativeLibrariesDir,
      //  cblLib = 'cblite';
      //  cblDartLib = 'cblitedart';
      //  vectorSearchLib = 'CouchbaseLiteVectorSearch';
      cbl: LibraryConfiguration.dynamic('c2ddf39c36bd6ab58d86b27ddc102286\\cblite'),
      cblDart: LibraryConfiguration.dynamic('c2ddf39c36bd6ab58d86b27ddc102286\\cblitedart'),
      vectorSearch: LibraryConfiguration.dynamic(
        'c2ddf39c36bd6ab58d86b27ddc102286\\CouchbaseLiteVectorSearch',
        isAppleFramework: false,
      ),
    );
  } else if (Platform.isMacOS) {
    // before we continue rolling here we also need to copy these files to a different dir structure as well.

    // I need to create the following because this is super WONKY....
    Directory cblDirectory =
        Directory('$sharedMergedNativesLibrariesDir/couchbase-lite-c-enterprise-3.2.0-macos/libcblite-3.2.0/lib');
    if (!cblDirectory.existsSync()) {
      await cblDirectory.create(recursive: true);
      // copy our dynamic libs into here...
      // copy our dynamic libs into here...
      for (var entity in Directory(mergedNativeLibrariesDir!).listSync()) {
        if (entity.path.contains('libcblite.')) {
          await File(entity.path).copy(cblDirectory.path);
        }
      }
    }
    Directory cblDartDirectory = Directory(
        '$sharedMergedNativesLibrariesDir/couchbase-lite-dart-8.0.0-enterprise-macos/libcblitedart-8.0.0/lib');
    if (!cblDartDirectory.existsSync()) {
      await cblDartDirectory.create(recursive: true);
      // copy our dynamic libs into here...
      for (var entity in Directory(mergedNativeLibrariesDir!).listSync()) {
        if (entity.path.contains('libcblitedart')) {
          await File(entity.path).copy(cblDartDirectory.path);
        }
      }
    }
    Directory vectorDirectory = Directory(
        '$sharedMergedNativesLibrariesDir/couchbase-lite-vector-search-1.0.0-macos/CouchbaseLiteVectorSearch.framework');
    if (!vectorDirectory.existsSync()) {
      await vectorDirectory.create(recursive: true);
      // copy our dynamic libs into here...
      await copyDirectoryContents(
          '$mergedNativeLibrariesDir/CouchbaseLiteVectorSearch.framework', vectorDirectory.path);
      print('copy success full for vector');
    }
    // before we continue rolling here we also need to copy these files to a different dir structure as well.

    // final versionedLibraryPath =
    // p.join('Versions', 'A', 'CouchbaseLiteVectorSearch');
    // final versionedLibraryFile =
    // File(p.join(frameworkDirectory.path, versionedLibraryPath));
    // await versionedLibraryFile.parent.create(recursive: true);
    // await libraryFile.rename(versionedLibraryFile.path);
    // await Link(p.join(frameworkDirectory.path, 'CouchbaseLiteVectorSearch'))
    //     .create(versionedLibraryPath);
    // libcblite.3.2.0.dylib
    // libcblite.3.dylib
    // libcblite.dylib
    // libcblitedart.8.0.0.dylib
    // libcblitedart.8.dylib
    // libcblitedart.dylib
    return LibrariesConfiguration(
      enterpriseEdition: edition == Edition.enterprise,
      directory: mergedNativeLibrariesDir,
      cbl: LibraryConfiguration.dynamic('c4f61c9bde1085be63f32dd54ca8829e/libcblite.3'),
      cblDart: LibraryConfiguration.dynamic('c4f61c9bde1085be63f32dd54ca8829e/libcblitedart'),
      vectorSearch: LibraryConfiguration.dynamic(
        // 'c4f61c9bde1085be63f32dd54ca8829e/CouchbaseLiteVectorSearch.framework/CouchbaseLiteVectorSearch',
        'c4f61c9bde1085be63f32dd54ca8829e/CouchbaseLiteVectorSearch.framework/Versions/A/CouchbaseLiteVectorSearch',
        isAppleFramework: true,
      ),
    );
  }

  if (_librariesOverride != null) {
    assert(mergedNativeLibrariesDir == null);
    assert((edition == Edition.enterprise) == _librariesOverride!.enterpriseEdition);
    return _librariesOverride!;
  }

  mergedNativeLibrariesDir ??= sharedMergedNativesLibrariesDir;
  await Directory(mergedNativeLibrariesDir).create(recursive: true);

  // NOTE: we need to pass this in here...
  final loader = RemotePackageLoader(cacheDir: sharedMergedNativesLibrariesDir);
  final packageConfigs = <PackageConfig>[];

  // ignore: cascade_invocations
  packageConfigs.addAll(
    DatabasePackageConfig.all(
      releases: latestReleases,
      edition: edition,
    ).where((config) => config.os == OS.current),
  );

  if (edition == Edition.enterprise) {
    packageConfigs.addAll(
      VectorSearchPackageConfig.all(release: '1.0.0').where((config) => config.os == OS.current),
    );
  }

  final packages = await Future.wait(packageConfigs.map(loader.load));

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
    enterpriseEdition: edition == Edition.enterprise,
  );
}
