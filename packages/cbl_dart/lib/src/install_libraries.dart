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
    final signatures = packages.map((package) => package.signatureContent).toList()..sort();

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
    if (package.isAppleFramework) {
      await copyDirectoryContents(
        package.appleFrameworkDir!,
        '${installDir.path}/${package.appleFrameworkName!}',
      );
    } else {
      await copyDirectoryContents(
        package.singleSharedLibrariesDir!,
        installDir.path,
        filter: (entity) => !entity.path.contains('cmake'),
      );
    }
  }
}

LibrariesConfiguration mergedNativeLibrariesConfigurations(
  Iterable<Package> packages, {
  required String directory,
  required bool enterpriseEdition,
  required bool? skipVectorSearch,
}) {
  final libraryDir = mergedNativeLibrariesInstallDir(packages, directory);

  Package? packageFor(Library library) => packages.where((package) => package.config.library == library).firstOrNull;

  final cblPackage = packageFor(Library.cblite)!;
  final cblDartPackage = packageFor(Library.cblitedart)!;
  final vectorSearchPackage = (skipVectorSearch ?? false) == true ? null : packageFor(Library.vectorSearch);

  return LibrariesConfiguration(
    directory: libraryDir.path,
    enterpriseEdition: enterpriseEdition,
    cbl: _nativeLibraryConfiguration(cblPackage),
    cblDart: _nativeLibraryConfiguration(cblDartPackage),
    vectorSearch: vectorSearchPackage != null ? _nativeLibraryConfiguration(vectorSearchPackage) : null,
  );
}

LibraryConfiguration _nativeLibraryConfiguration(Package package) => LibraryConfiguration.dynamic(
      package.libraryName,
      // Specifying an exact version should not be necessary, but is
      // because the beta of libcblite does not distribute properly
      // symlinked libraries for macos. We need to use the
      // libcblite.x.dylib because that is what libcblitedart is linking
      // against.
      version: package.os == OS.macOS && package.config.library.isDatabaseLibrary
          ? package.config.version.split('.').first
          : null,
      isAppleFramework: package.isNormalAppleFramework,
    );
