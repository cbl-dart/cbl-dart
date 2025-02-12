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
String nativePackage = cblDartSharedCacheDirOverride ?? p.join(userCachesDir, 'cbl_native_package');

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
  bool? skipVectorSearch,
}) async {
  logger.fine('Acquiring libraries');

  // Strategy, take our cache folders + files  ->>> mirror what cbl is expecting:)
  if (Platform.isWindows) {
    String uuid = 'c2ddf39c36bd6ab58d86b27ddc102286';

    // I need to create the following because this is super WONKY....
    Directory cblDirectory =
        Directory('$nativePackage\\couchbase-lite-c-enterprise-3.2.0-windows-x86_64\\libcblite-3.2.0\\bin');
    Directory cblMergedDirectory = Directory(
        '$sharedMergedNativesLibrariesDir\\couchbase-lite-c-enterprise-3.2.0-windows-x86_64\\libcblite-3.2.0\\bin');
    if (cblDirectory.existsSync()) {
      await cblDirectory.delete(recursive: true);
    }
    if (cblMergedDirectory.existsSync()) {
      await cblMergedDirectory.delete(recursive: true);
    }
    await cblDirectory.create(recursive: true);
    await cblMergedDirectory.create(recursive: true);
    // copy our dynamic libs into here...
    for (var entity in Directory('$mergedNativeLibrariesDir${Platform.pathSeparator}$uuid').listSync()) {
      if (entity.path.contains('cblite.')) {
        File cacheFile =
            await File('${cblDirectory.path}${Platform.pathSeparator}${entity.path.split(Platform.pathSeparator).last}')
                .create(recursive: true);
        await File(entity.path).copy(cacheFile.path);
        File mergedFile = await File(
                '${cblMergedDirectory.path}${Platform.pathSeparator}${entity.path.split(Platform.pathSeparator).last}')
            .create(recursive: true);
        await File(entity.path).copy(mergedFile.path);
      }
    }

    Directory cblDartDirectory =
        Directory('$nativePackage\\couchbase-lite-dart-8.0.0-enterprise-windows-x86_64\\libcblitedart-8.0.0\\bin');
    Directory cblDartMergedDirectory = Directory(
        '$sharedMergedNativesLibrariesDir\\couchbase-lite-dart-8.0.0-enterprise-windows-x86_64\\libcblitedart-8.0.0\\bin');
    if (cblDartDirectory.existsSync()) {
      await cblDartDirectory.delete(recursive: true);
    }
    if (cblDartMergedDirectory.existsSync()) {
      await cblDartMergedDirectory.delete(recursive: true);
    }
    await cblDartDirectory.create(recursive: true);
    await cblDartMergedDirectory.create(recursive: true);
    // copy our dynamic libs into here...
    for (var entity in Directory('$mergedNativeLibrariesDir${Platform.pathSeparator}$uuid').listSync()) {
      if (entity.path.contains('cblitedart.')) {
        File cacheFile = await File(
                '${cblDartDirectory.path}${Platform.pathSeparator}${entity.path.split(Platform.pathSeparator).last}')
            .create(recursive: true);
        await File(entity.path).copy(cacheFile.path);
        File mergedFile = await File(
                '${cblDartMergedDirectory.path}${Platform.pathSeparator}${entity.path.split(Platform.pathSeparator).last}')
            .create(recursive: true);
        await File(entity.path).copy(mergedFile.path);
      }
    }

    Directory vectorDirectory = Directory(
        '$nativePackage\\couchbase-lite-vector-search-1.0.0-windows-x86_64\\CouchbaseLiteVectorSearch.framework\\bin');
    Directory vectorMergedDirectory = Directory(
        '$sharedMergedNativesLibrariesDir\\couchbase-lite-vector-search-1.0.0-windows-x86_64\\CouchbaseLiteVectorSearch.framework\\bin');
    if (vectorDirectory.existsSync()) {
      await vectorDirectory.delete(recursive: true);
    }
    if (vectorMergedDirectory.existsSync()) {
      await vectorMergedDirectory.delete(recursive: true);
    }

    // if we are using vectorSearch ensure that we create our cache directories.
    if (!(skipVectorSearch ?? false)) {
      await vectorDirectory.create(recursive: true);
      await vectorMergedDirectory.create(recursive: true);
      for (var entity in Directory('$mergedNativeLibrariesDir${Platform.pathSeparator}$uuid').listSync()) {
        if (entity.path.contains('CouchbaseLiteVectorSearch.') || entity.path.contains('libomp140')) {
          File cacheFile = await File(
                  '${vectorDirectory.path}${Platform.pathSeparator}${entity.path.split(Platform.pathSeparator).last}')
              .create(recursive: true);
          await File(entity.path).copy(cacheFile.path);
          File mergedFile = await File(
                  '${vectorMergedDirectory.path}${Platform.pathSeparator}${entity.path.split(Platform.pathSeparator).last}')
              .create(recursive: true);
          await File(entity.path).copy(mergedFile.path);
        }
      }
    }

    if (skipVectorSearch ?? false == true) {
      return LibrariesConfiguration(
        enterpriseEdition: edition == Edition.enterprise,
        directory: mergedNativeLibrariesDir,
        cbl: LibraryConfiguration.dynamic('$uuid\\cblite'),
        cblDart: LibraryConfiguration.dynamic('$uuid\\cblitedart'),
        vectorSearch: null,
      );
    }
  } else if (Platform.isMacOS) {
    String uuid = 'c4f61c9bde1085be63f32dd54ca8829e';

    // I need to create the following because this is super WONKY....
    Directory cblDirectory = Directory('$nativePackage/couchbase-lite-c-enterprise-3.2.0-macos/libcblite-3.2.0/lib');
    Directory cblMergedDirectory =
        Directory('$sharedMergedNativesLibrariesDir/couchbase-lite-c-enterprise-3.2.0-macos/libcblite-3.2.0/lib');

    if (cblDirectory.existsSync()) {
      await cblDirectory.delete(recursive: true);
    }
    if (cblMergedDirectory.existsSync()) {
      await cblMergedDirectory.delete(recursive: true);
    }
    await cblDirectory.create(recursive: true);
    await cblMergedDirectory.create(recursive: true);
    // copy our dynamic libs into here...
    for (var entity in Directory('$mergedNativeLibrariesDir/$uuid').listSync()) {
      if (entity.path.contains('libcblite.')) {
        File cacheFile = await File('${cblDirectory.path}/${entity.path.split('/').last}').create(recursive: true);
        await File(entity.path).copy(cacheFile.path);
        File mergedFile =
            await File('${cblMergedDirectory.path}/${entity.path.split('/').last}').create(recursive: true);
        await File(entity.path).copy(mergedFile.path);
      }
    }

    Directory cblDartDirectory =
        Directory('$nativePackage/couchbase-lite-dart-8.0.0-enterprise-macos/libcblitedart-8.0.0/lib');
    Directory cblDartMergedDirectory = Directory(
        '$sharedMergedNativesLibrariesDir/couchbase-lite-dart-8.0.0-enterprise-macos/libcblitedart-8.0.0/lib');
    if (cblDartDirectory.existsSync()) {
      await cblDartDirectory.delete(recursive: true);
    }
    if (cblDartMergedDirectory.existsSync()) {
      await cblDartMergedDirectory.delete(recursive: true);
    }
    await cblDartDirectory.create(recursive: true);
    await cblDartMergedDirectory.create(recursive: true);
    // copy our dynamic libs into here...
    for (var entity in Directory('$mergedNativeLibrariesDir/$uuid').listSync()) {
      if (entity.path.contains('libcblitedart')) {
        File cacheFile = await File('${cblDartDirectory.path}/${entity.path.split('/').last}').create(recursive: true);
        await File(entity.path).copy(cacheFile.path);
        File mergedFile =
            await File('${cblDartMergedDirectory.path}/${entity.path.split('/').last}').create(recursive: true);
        await File(entity.path).copy(mergedFile.path);
      }
    }

    Directory vectorDirectory =
        Directory('$nativePackage/couchbase-lite-vector-search-1.0.0-macos/CouchbaseLiteVectorSearch.framework');
    Directory vectorMergedDirectory = Directory(
        '$sharedMergedNativesLibrariesDir/couchbase-lite-vector-search-1.0.0-macos/CouchbaseLiteVectorSearch.framework');
    if (vectorDirectory.existsSync()) {
      await vectorDirectory.delete(recursive: true);
    }
    if (vectorMergedDirectory.existsSync()) {
      await vectorMergedDirectory.delete(recursive: true);
    }

    // if we are using vectorSearch ensure that we create our cache directories.
    if (!(skipVectorSearch ?? false)) {
      await vectorDirectory.create(recursive: true);
      await vectorMergedDirectory.create(recursive: true);
      // copy our dynamic libs into here...
      await copyDirectoryContents(
          '$mergedNativeLibrariesDir/$uuid/CouchbaseLiteVectorSearch.framework', vectorDirectory.path);
      await copyDirectoryContents(
          '$mergedNativeLibrariesDir/$uuid/CouchbaseLiteVectorSearch.framework', vectorMergedDirectory.path);
      print('copy success full for vector');
    }

    // before we continue rolling here we also need to copy these files to a different dir structure as well.

    // return our libraries

    // if (skipVectorSearch ?? false == true) {
    //   // return LibrariesConfiguration(
    //   //   enterpriseEdition: edition == Edition.enterprise,
    //   //   directory: mergedNativeLibrariesDir,
    //   //   cbl: LibraryConfiguration.dynamic('$uuid/libcblite.3'),
    //   //   cblDart: LibraryConfiguration.dynamic('$uuid/libcblitedart'),
    //   //   vectorSearch: null,
    //   // );
    // }
  }

  if (_librariesOverride != null) {
    assert(mergedNativeLibrariesDir == null);
    assert((edition == Edition.enterprise) == _librariesOverride!.enterpriseEdition);
    return _librariesOverride!;
  }

  mergedNativeLibrariesDir ??= sharedMergedNativesLibrariesDir;
  await Directory(mergedNativeLibrariesDir).create(recursive: true);

  // NOTE: we need to pass this in here...
  final loader = RemotePackageLoader();
  final packageConfigs = <PackageConfig>[];

  // ignore: cascade_invocations
  packageConfigs.addAll(
    DatabasePackageConfig.all(
      releases: latestReleases,
      edition: edition,
    ).where((config) {
      print('config: ${config.library.libraryName(config.os)}');
      return config.os == OS.current;
    }),
  );

  if (edition == Edition.enterprise && !(skipVectorSearch ?? false)) {
    print('add our vector search package??');
    packageConfigs.addAll(
      VectorSearchPackageConfig.all(release: '1.0.0').where((config) => config.os == OS.current),
    );
  }

  final packages = await Future.wait(packageConfigs.map(loader.load));
  for (var package in packages) {
    print('b4: ${package.libraryName}');
  }
  //
  // if ((skipVectorSearch ?? false) == true) {
  //   // NOTE: same name on windows/and macos.
  //   packages.removeWhere((package) => package.libraryName.contains('CouchbaseLiteVectorSearch'));
  // }
  // print('should we skip vectorSearch?? $skipVectorSearch');
  //
  // for (var package in packages) {
  //   print('aftr: ${package.libraryName}');
  // }

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
    skipVectorSearch: skipVectorSearch,
  );
}
