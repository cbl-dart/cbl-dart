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

  String get signatureContent =>
      [library.name, release, edition.name, target.id].join();
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

  final tmpDir = await Directory.systemTemp.createTemp();

  try {
    final tmpInstallDir = Directory.fromUri(tmpDir.uri.resolve('lib'));
    await tmpInstallDir.create();

    for (final package in packages) {
      await installNativeLibrary(
        package,
        installDir: tmpInstallDir.path,
        tmpDir: tmpDir.path,
      );
    }

    final installDir = mergedNativeLibrariesInstallDir(packages, directory);
    await installDir.create(recursive: true);

    await copyDirectoryContents(
      tmpInstallDir.path,
      installDir.path,
      filter: (entity) => !entity.path.contains('cmake'),
    );
  } finally {
    await tmpDir.delete(recursive: true);
  }
}

Future<void> installNativeLibrary(
  Package package, {
  required String installDir,
  required String tmpDir,
}) async {
  logger.fine('Installing native library ${package.libraryName}');

  await package.acquire();

  // Copy contents of lib dir from archive to install dir.
  await copyDirectoryContents(package.libDir, installDir);
}

LibrariesConfiguration mergedNativeLibrariesConfigurations(
  Iterable<Package> packages, {
  required String directory,
}) {
  final libraryDir = mergedNativeLibrariesInstallDir(packages, directory);

  Package packageFor(Library library) =>
      packages.firstWhere((package) => package.library == library);

  return LibrariesConfiguration(
    directory: libraryDir.path,
    enterpriseEdition: packages.first.edition == Edition.enterprise,
    cbl: _nativeLibraryConfiguration(packageFor(Library.libcblite)),
    cblDart: _nativeLibraryConfiguration(packageFor(Library.libcblitedart)),
  );
}

LibraryConfiguration _nativeLibraryConfiguration(Package package) {
  if (Platform.isMacOS || Platform.isLinux) {
    return LibraryConfiguration.dynamic(
      package.libraryName,
      // Specifying an exact version should not be necessary, but is because
      // the beta of libcblite does not distribute properly symlinked libraries
      // for macos. We need to use the libcblite.x.dylib because that is what
      // libcblitedart is linking against.
      version: package.version.split('.').first,
    );
  }

  if (Platform.isWindows) {
    return LibraryConfiguration.dynamic(package.libraryName);
  }

  throw UnsupportedError('Unsupported platform.');
}
