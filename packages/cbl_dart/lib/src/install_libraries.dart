import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:path/path.dart' as p;

import 'package.dart';
import 'tools.dart';
import 'utils.dart';

Directory mergedNativeLibrariesInstallDir(
  Iterable<Package> packages,
  String directory,
) {
  final signature = Package.mergedSignature(packages);
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
  final tmpDir = await Directory.systemTemp.createTemp();

  try {
    final tmpInstallDir = Directory.fromUri(tmpDir.uri.resolve('lib'));
    await tmpInstallDir.create(recursive: true);

    await Future.wait(packages.map((package) => installNativeLibrary(
          package,
          installDir: tmpInstallDir.path,
          tmpDir: tmpDir.path,
        )));

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

Map<Library, LibraryConfiguration> mergedNativeLibraryConfigurations(
  Iterable<Package> packages, {
  required String directory,
}) {
  final libraryDir = mergedNativeLibrariesInstallDir(packages, directory);

  return Map.fromIterables(
    packages.map((package) => package.library),
    packages.map((package) => nativeLibraryConfiguration(
          package,
          directory: libraryDir.path,
        )),
  );
}

Future<void> installNativeLibrary(
  Package package, {
  required String installDir,
  required String tmpDir,
}) async {
  final archiveBasename =
      '${package.library.name}.${package.archiveFormat.ext}';
  final archiveFile = p.join(tmpDir, archiveBasename);
  final packageRootDir =
      p.join(tmpDir, '${package.library.name}-${package.version}');
  final targetLibDir = p.join(packageRootDir, package.targetLibDir);

  await downloadFile(package.archiveUrl, archiveFile);
  await unpackArchive(archiveFile, tmpDir);

  // Copy contents of lib dir from archive to install dir.
  await copyDirectoryContents(targetLibDir, installDir);
}

LibraryConfiguration nativeLibraryConfiguration(
  Package package, {
  required String directory,
}) {
  if (Platform.isMacOS || Platform.isLinux) {
    final libraryFile = p.join(directory, package.library.name);
    return LibraryConfiguration.dynamic(
      libraryFile,
      // Specifying an exact version should not be necessary, but is because
      // the beta of libcblite does not distribute properly symlinked libraries
      // for macos. We need to use the libcblite.x.dylib because that is what
      // libcblitedart is linking against.
      version: package.version.split('.').first,
    );
  } else {
    throw UnsupportedError('Unsupported platform.');
  }
}
