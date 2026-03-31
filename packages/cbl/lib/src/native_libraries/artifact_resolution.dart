import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:path/path.dart' as p;

import 'package.dart';
import 'target_matrix.dart';

const cbliteRelease = '4.0.3';
const vectorSearchRelease = '2.0.0';

final class CblitePackage {
  CblitePackage({
    required this.package,
    required this.libraryFile,
    required this.includeDir,
    this.frameworkSearchPath,
    this.symbolsDir,
  });

  final Package package;
  final Uri libraryFile;
  final String includeDir;
  final String? frameworkSearchPath;
  final String? symbolsDir;
}

Future<CblitePackage> downloadCblite({
  required Edition edition,
  required OS targetOS,
  required Architecture targetArchitecture,
  IOSSdk? targetIOSSdk,
}) async {
  final package =
      await RemotePackageLoader(cacheDir: downloadedPackagesCacheDir).load(
        CblitePackageConfig(
          library: Library.cblite,
          os: targetOS,
          architectures: cbliteArchitectures(targetOS, targetArchitecture),
          release: cbliteRelease,
          archiveFormat: targetOS == OS.linux
              ? ArchiveFormat.tarGz
              : ArchiveFormat.zip,
          edition: edition,
        ),
      );

  if (targetOS == OS.iOS) {
    final framework = await findIOSFramework(package, targetIOSSdk!);
    return CblitePackage(
      package: package,
      libraryFile: framework.libPath,
      includeDir: framework.includeDir,
      frameworkSearchPath: framework.frameworkSearchPath,
      symbolsDir: p.join(
        package.packageDir,
        'CouchbaseLite.xcframework',
        iosSliceDir(targetIOSSdk),
        'dSYMs',
      ),
    );
  }

  return CblitePackage(
    package: package,
    libraryFile: findLibrary(
      package,
      targetOS,
      architecture: targetArchitecture,
    ),
    includeDir: p.join(package.rootDir, 'include'),
    symbolsDir: await downloadSymbolsArchive(
      library: Library.cblite,
      edition: edition,
      os: targetOS,
      architecture: targetArchitecture,
      release: cbliteRelease,
    ),
  );
}

Future<Package> downloadVectorSearchPackage({
  required OS targetOS,
  required Architecture targetArchitecture,
}) => RemotePackageLoader(cacheDir: downloadedPackagesCacheDir).load(
  VectorSearchPackageConfig(
    os: targetOS,
    architectures: vectorSearchArchitectures(targetOS, targetArchitecture),
    release: vectorSearchRelease,
  ),
);

Future<String?> downloadSymbolsArchive({
  required Library library,
  required Edition edition,
  required OS os,
  required Architecture architecture,
  required String release,
}) async {
  final archive = switch (library) {
    Library.cblite => cbliteSymbolsArchive(
      edition: edition,
      os: os,
      architecture: architecture,
      release: release,
    ),
    Library.vectorSearch => vectorSearchSymbolsArchive(
      os: os,
      architecture: architecture,
      release: release,
    ),
  };

  if (archive == null) {
    return null;
  }

  final (archiveUrl, archiveFormat) = archive;
  return downloadAndUnpackToCache(
    url: archiveUrl,
    format: archiveFormat,
    cacheDir: downloadedPackagesCacheDir,
  );
}

(String, ArchiveFormat)? cbliteSymbolsArchive({
  required Edition edition,
  required OS os,
  required Architecture architecture,
  required String release,
}) {
  if (os == OS.android || os == OS.iOS) {
    return null;
  }

  final format = os == OS.linux ? ArchiveFormat.tarGz : ArchiveFormat.zip;
  final targetId = os == OS.macOS
      ? 'macos'
      : os == OS.windows
      ? 'windows-${architecture.couchbaseSdkName}'
      : 'linux-${architecture.couchbaseSdkName}';

  final url = Uri(
    scheme: 'https',
    host: 'packages.couchbase.com',
    pathSegments: [
      'releases',
      'couchbase-lite-c',
      release,
      cbliteSymbolsArchiveName(
        edition: edition,
        release: release,
        targetId: targetId,
        format: format,
      ),
    ],
  ).toString();
  return (url, format);
}

String cbliteSymbolsArchiveName({
  required Edition edition,
  required String release,
  required String targetId,
  required ArchiveFormat format,
}) =>
    'couchbase-lite-c-${edition.name}-$release-'
    '$targetId-symbols.${format.extension}';

(String, ArchiveFormat)? vectorSearchSymbolsArchive({
  required OS os,
  required Architecture architecture,
  required String release,
}) {
  if (os == OS.android || os == OS.windows || os == OS.iOS) {
    return null;
  }

  const format = ArchiveFormat.zip;
  final archiveName =
      'couchbase-lite-vector-search-$release-${os.couchbaseSdkName}'
      '${os == OS.macOS ? '' : '-${architecture.couchbaseSdkName}'}'
      '-symbols.${format.extension}';
  final url = Uri(
    scheme: 'https',
    host: 'packages.couchbase.com',
    pathSegments: [
      'releases',
      'couchbase-lite-vector-search',
      release,
      archiveName,
    ],
  ).toString();
  return (url, format);
}

Future<({Uri libPath, String includeDir, String frameworkSearchPath})>
findIOSFramework(Package package, IOSSdk targetSdk) async {
  final sliceDir = iosSliceDir(targetSdk);
  final sliceRoot = p.join(
    package.packageDir,
    'CouchbaseLite.xcframework',
    sliceDir,
  );
  final frameworkDir = p.join(sliceRoot, 'CouchbaseLite.framework');
  final headersDir = p.join(frameworkDir, 'Headers');

  final includeDir = p.join(package.packageDir, 'include');
  for (final subdir in ['cbl', 'fleece', 'CouchbaseLite']) {
    final link = Link(p.join(includeDir, subdir));
    if (!link.existsSync()) {
      await link.create(headersDir, recursive: true);
    }
  }

  return (
    libPath: Uri.file(p.join(frameworkDir, 'CouchbaseLite')),
    includeDir: includeDir,
    frameworkSearchPath: sliceRoot,
  );
}

Uri findIOSVectorSearchLibrary(Package package, IOSSdk targetSdk) {
  final sliceDir = iosSliceDir(targetSdk);
  final frameworkDir = p.join(
    package.packageDir,
    'CouchbaseLiteVectorSearch.xcframework',
    sliceDir,
    'CouchbaseLiteVectorSearch.framework',
  );
  return Uri.file(p.join(frameworkDir, 'CouchbaseLiteVectorSearch'));
}

Uri findVectorSearchLibrary(
  Package package, {
  required OS os,
  required Architecture architecture,
  IOSSdk? targetIOSSdk,
}) {
  if (os == OS.iOS) {
    return findIOSVectorSearchLibrary(package, targetIOSSdk!);
  }

  if (os == OS.macOS) {
    final frameworkDir = p.join(
      package.packageDir,
      'CouchbaseLiteVectorSearch.framework',
    );
    return Uri.file(p.join(frameworkDir, 'CouchbaseLiteVectorSearch'));
  }

  return findLibrary(package, os, architecture: architecture);
}

String iosSliceDir(IOSSdk targetSdk) => switch (targetSdk) {
  IOSSdk.iPhoneOS => 'ios-arm64',
  IOSSdk.iPhoneSimulator => 'ios-arm64_x86_64-simulator',
  _ => throw UnsupportedError('Unsupported iOS SDK: $targetSdk'),
};

Uri findLibrary(Package package, OS os, {Architecture? architecture}) {
  final libDir = switch (architecture) {
    final architecture? => package.sharedLibrariesDir(architecture),
    null => package.singleSharedLibrariesDir,
  };
  if (libDir == null) {
    throw StateError(
      'No shared libraries directory for ${package.libraryName}',
    );
  }

  final libraryName = package.libraryName;
  final extensions = switch (os) {
    OS.macOS || OS.iOS => ['.dylib'],
    OS.linux || OS.android => ['.so'],
    OS.windows => ['.dll'],
    _ => throw UnsupportedError('Unsupported OS: $os'),
  };

  for (final ext in extensions) {
    final candidate = p.join(libDir, '$libraryName$ext');
    if (File(candidate).existsSync()) {
      return Uri.file(candidate);
    }
  }

  final dir = Directory(libDir);
  if (dir.existsSync()) {
    for (final entity in dir.listSync()) {
      final name = p.basename(entity.path);
      if (entity is File && name.startsWith(libraryName)) {
        return Uri.file(entity.path);
      }
    }
  }

  throw StateError('Could not find $libraryName in $libDir');
}
