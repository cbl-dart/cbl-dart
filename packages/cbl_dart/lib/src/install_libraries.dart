import 'dart:convert';
import 'dart:io';

import 'package:cbl/cbl.dart';
// ignore: implementation_imports
import 'package:cbl/src/install.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'logging.dart';

extension PackageMerging on Package {
  static String signature(Iterable<Package> packages) {
    final signatures =
        packages.map((package) => package.signatureContent).toList()..sort();

    return md5
        .convert(utf8.encode(signatures.join()))
        .bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  String get signatureContent => [
        config.library.name,
        config.release,
        if (config case DatabasePackageConfig(:final edition)) edition.name,
        config.targetId
      ].join();
}

Directory mergedNativeLibrariesInstallDir(
  Iterable<Package> packages,
  String directory,
) {
  final signature = PackageMerging.signature(packages);
  return Directory(p.join(directory, signature));
}

bool areMergedNativeLibrariesInstalled(
  Iterable<Package> packages, {
  required String directory,
}) =>
    mergedNativeLibrariesInstallDir(packages, directory).existsSync();

Future<void> installMergedNativeLibraries(
  Iterable<Package> packages, {
  required String directory,
}) async {
  logger.fine('Installing native libraries into $directory');

  final installDir = mergedNativeLibrariesInstallDir(packages, directory);
  await installDir.create(recursive: true);

  for (final package in packages) {
    await copyDirectoryContents(
      (package as StandardPackage).sharedLibrariesDir,
      installDir.path,
      filter: (entity) => !entity.path.contains('cmake'),
    );
  }
}

LibrariesConfiguration mergedNativeLibrariesConfigurations(
  Iterable<Package> packages, {
  required String directory,
}) {
  final libraryDir = mergedNativeLibrariesInstallDir(packages, directory);

  Package packageFor(Library library) =>
      packages.firstWhere((package) => package.config.library == library);

  return LibrariesConfiguration(
    directory: libraryDir.path,
    enterpriseEdition:
        (packages.first.config as DatabasePackageConfig).edition ==
            Edition.enterprise,
    cbl: _nativeLibraryConfiguration(packageFor(Library.libcblite)),
    cblDart: _nativeLibraryConfiguration(packageFor(Library.libcblitedart)),
  );
}

LibraryConfiguration _nativeLibraryConfiguration(Package package) {
  final libraryName = (package as StandardPackage).libraryName;

  if (Platform.isMacOS || Platform.isLinux) {
    return LibraryConfiguration.dynamic(
      libraryName,
      // Specifying an exact version should not be necessary, but is because
      // the beta of libcblite does not distribute properly symlinked libraries
      // for macos. We need to use the libcblite.x.dylib because that is what
      // libcblitedart is linking against.
      version: package.config.version.split('.').first,
    );
  }

  if (Platform.isWindows) {
    return LibraryConfiguration.dynamic(libraryName);
  }

  throw UnsupportedError('Unsupported platform.');
}
