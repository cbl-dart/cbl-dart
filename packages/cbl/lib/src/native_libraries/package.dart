import 'dart:io';

import 'package:code_assets/code_assets.dart' hide LinkMode;
import 'package:path/path.dart' as p;

import 'utils.dart';

export 'package:code_assets/code_assets.dart' show Architecture, OS;

String get nativeLibrariesCacheDir =>
    p.join(userCachesDir, 'cbl_native_libraries');

String get downloadedPackagesCacheDir =>
    p.join(nativeLibrariesCacheDir, 'downloads');

/// A library that is distributed as part of cbl-dart.
enum Library {
  cblite,
  vectorSearch;

  String? packageRootDir(OS os, String version) => switch (this) {
    cblite => switch (os) {
      OS.android || OS.linux || OS.macOS || OS.windows => 'libcblite-$version',
      OS.iOS => null,
      _ => throw UnsupportedError('Unsupported OS: $os'),
    },
    vectorSearch => null,
  };

  AppleFrameworkType? appleFrameworkType(OS os) => switch (this) {
    cblite => os == OS.iOS ? AppleFrameworkType.xcframework : null,
    vectorSearch => switch (os) {
      OS.iOS => AppleFrameworkType.xcframework,
      OS.macOS => AppleFrameworkType.framework,
      OS.android || OS.linux || OS.windows => null,
      _ => throw UnsupportedError('Unsupported OS: $os'),
    },
  };

  String? sharedLibrariesDir(OS os, Architecture architecture) =>
      switch (this) {
        cblite => switch (os) {
          OS.android => p.join('lib', architecture.androidTriple),
          OS.macOS => 'lib',
          OS.linux => p.join('lib', architecture.linuxTripple),
          OS.windows => 'bin',
          OS.iOS => null,
          _ => throw UnsupportedError('Unsupported OS: $os'),
        },
        vectorSearch => switch (os) {
          OS.linux || OS.android => 'lib',
          OS.windows => 'bin',
          OS.iOS || OS.macOS => null,
          _ => throw UnsupportedError('Unsupported OS: $os'),
        },
      };

  String libraryName(OS os) => switch (this) {
    cblite => switch (os) {
      OS.linux || OS.android || OS.macOS => 'libcblite',
      OS.windows => 'cblite',
      OS.iOS => 'CouchbaseLite',
      _ => throw UnsupportedError('Unsupported OS: $os'),
    },
    vectorSearch => switch (os) {
      OS.android => 'libCouchbaseLiteVectorSearch',
      OS.linux ||
      OS.windows ||
      OS.macOS ||
      OS.iOS => 'CouchbaseLiteVectorSearch',
      _ => throw UnsupportedError('Unsupported OS: $os'),
    },
  };
}

/// A Couchbase Lite edition.
enum Edition { community, enterprise }

/// An archive format.
enum ArchiveFormat {
  zip,
  tarGz;

  String get extension => switch (this) {
    zip => 'zip',
    tarGz => 'tar.gz',
  };
}

enum AppleFrameworkType {
  xcframework,
  framework;

  String get extension => switch (this) {
    xcframework => 'xcframework',
    framework => 'framework',
  };
}

abstract final class PackageConfig {
  PackageConfig({
    required this.library,
    required this.os,
    required this.architectures,
    required this.release,
    required this.archiveFormat,
  });

  final Library library;
  final OS os;
  final List<Architecture> architectures;
  final String release;
  final ArchiveFormat archiveFormat;

  bool get isMultiArchitecture => architectures.length > 1;

  String get targetId => isMultiArchitecture
      ? os.couchbaseSdkName
      : '${os.couchbaseSdkName}-${architectures.single.couchbaseSdkName}';

  String get version => release.split('-').first;

  String get _archiveUrl;

  Package _package(String packageDir) =>
      Package(config: this, packageDir: packageDir);

  Future<void> _postProcess(String packageDir) async {}
}

final class Package {
  Package({required this.config, required this.packageDir});

  final PackageConfig config;
  final String packageDir;

  OS get os => config.os;

  Library get library => config.library;

  String get rootDir => p.join(
    packageDir,
    config.library.packageRootDir(config.os, config.version),
  );

  String get libraryName => config.library.libraryName(config.os);

  AppleFrameworkType? get appleFrameworkType =>
      config.library.appleFrameworkType(os);

  bool get isNormalAppleFramework =>
      appleFrameworkType == AppleFrameworkType.framework;

  bool get isAppleFramework => appleFrameworkType != null;

  String? get appleFrameworkName {
    if (appleFrameworkType case final frameworkType?) {
      return '$libraryName.${frameworkType.extension}';
    } else {
      return null;
    }
  }

  String? get appleFrameworkDir {
    if (appleFrameworkName case final frameworkName?) {
      return p.join(rootDir, frameworkName);
    } else {
      return null;
    }
  }

  String? get singleSharedLibrariesDir {
    final sharedLibrariesDirectories = config.architectures
        .map(sharedLibrariesDir)
        .toSet();
    if (sharedLibrariesDirectories.length == 1) {
      return sharedLibrariesDirectories.single;
    } else {
      throw StateError(
        'Multiple shared libraries directories: $sharedLibrariesDirectories',
      );
    }
  }

  String? sharedLibrariesDir(Architecture architecture) {
    if (!config.architectures.contains(architecture)) {
      throw ArgumentError.value(
        architecture,
        'architecture',
        'must be in ${config.architectures}',
      );
    }

    if (config.library.sharedLibrariesDir(config.os, architecture)
        case final librariesDir?) {
      return p.join(rootDir, librariesDir);
    } else {
      return null;
    }
  }
}

abstract class PackageLoader {
  Future<Package> load(PackageConfig config) async =>
      config._package(await _packageDir(config));

  Future<String> _packageDir(PackageConfig config);
}

final class RemotePackageLoader extends PackageLoader {
  RemotePackageLoader({String? cacheDir})
    : cacheDir = cacheDir ?? downloadedPackagesCacheDir;

  final String cacheDir;

  @override
  Future<String> _packageDir(PackageConfig config) => downloadAndUnpackToCache(
    url: config._archiveUrl,
    format: config.archiveFormat,
    cacheDir: cacheDir,
    postProcess: config._postProcess,
  );
}

/// Downloads an archive from [url], unpacks it into [cacheDir], and returns the
/// resulting directory path. The directory name is derived from the archive URL
/// basename. If the directory already exists, the download is skipped.
Future<String> downloadAndUnpackToCache({
  required String url,
  required ArchiveFormat format,
  required String cacheDir,
  Future<void> Function(String packageDir)? postProcess,
}) async {
  final archiveBaseName = p.basenameWithoutExtension(Uri.parse(url).path);
  final packageDir = p.join(cacheDir, archiveBaseName);
  final packageDirectory = Directory(packageDir);
  if (packageDirectory.existsSync()) {
    return packageDir;
  }

  final cacheTempDir = Directory(p.join(cacheDir, '.temp'));
  await cacheTempDir.create(recursive: true);

  final tempDirectory = await cacheTempDir.createTemp();
  try {
    final archiveData = await downloadUrl(url);
    await unpackArchive(
      archiveData,
      format: format,
      outputDir: tempDirectory.path,
    );
    if (postProcess != null) {
      await postProcess(tempDirectory.path);
    }
    try {
      await moveDirectory(tempDirectory, packageDirectory);
    } on PathExistsException {
      // Another process has already downloaded the archive.
    } on FileSystemException catch (e) {
      if (!_concurrentCachePopulationDetected(e, packageDirectory)) {
        rethrow;
      }
    }
  } finally {
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  }

  return packageDir;
}

bool _concurrentCachePopulationDetected(
  FileSystemException error,
  Directory packageDirectory,
) {
  if (!packageDirectory.existsSync()) {
    return false;
  }

  final errorCode = error.osError?.errorCode;
  return errorCode == 17 || errorCode == 66;
}

final class CblitePackageConfig extends PackageConfig {
  CblitePackageConfig({
    required super.library,
    required super.os,
    required super.architectures,
    required super.release,
    required super.archiveFormat,
    required this.edition,
  });

  static List<CblitePackageConfig> all({
    required String release,
    required Edition edition,
  }) => [
    CblitePackageConfig(
      library: Library.cblite,
      os: OS.android,
      architectures: [
        Architecture.arm,
        Architecture.arm64,
        Architecture.ia32,
        Architecture.x64,
      ],
      release: release,
      archiveFormat: ArchiveFormat.zip,
      edition: edition,
    ),
    CblitePackageConfig(
      library: Library.cblite,
      os: OS.iOS,
      architectures: [Architecture.arm64, Architecture.x64],
      release: release,
      archiveFormat: ArchiveFormat.zip,
      edition: edition,
    ),
    CblitePackageConfig(
      library: Library.cblite,
      os: OS.macOS,
      architectures: [Architecture.arm64, Architecture.x64],
      release: release,
      archiveFormat: ArchiveFormat.zip,
      edition: edition,
    ),
    CblitePackageConfig(
      library: Library.cblite,
      os: OS.linux,
      architectures: [Architecture.x64],
      release: release,
      archiveFormat: ArchiveFormat.tarGz,
      edition: edition,
    ),
    CblitePackageConfig(
      library: Library.cblite,
      os: OS.windows,
      architectures: [Architecture.x64],
      release: release,
      archiveFormat: ArchiveFormat.zip,
      edition: edition,
    ),
  ];

  final Edition edition;

  @override
  String get _archiveUrl => Uri(
    scheme: 'https',
    host: 'packages.couchbase.com',
    pathSegments: [
      'releases',
      'couchbase-lite-c',
      release,
      [
        'couchbase-lite-c',
        edition.name,
        release,
        '$targetId.${archiveFormat.extension}',
      ].join('-'),
    ],
  ).toString();
}

final class VectorSearchPackageConfig extends PackageConfig {
  VectorSearchPackageConfig({
    required super.os,
    required super.architectures,
    required super.release,
  }) : super(library: Library.vectorSearch, archiveFormat: ArchiveFormat.zip);

  static List<VectorSearchPackageConfig> all({required String release}) => [
    VectorSearchPackageConfig(
      os: OS.android,
      architectures: [Architecture.arm64],
      release: release,
    ),
    VectorSearchPackageConfig(
      os: OS.android,
      architectures: [Architecture.x64],
      release: release,
    ),
    VectorSearchPackageConfig(
      os: OS.iOS,
      architectures: [Architecture.arm64, Architecture.x64],
      release: release,
    ),
    VectorSearchPackageConfig(
      os: OS.macOS,
      architectures: [Architecture.arm64, Architecture.x64],
      release: release,
    ),
    VectorSearchPackageConfig(
      os: OS.linux,
      architectures: [Architecture.x64],
      release: release,
    ),
    VectorSearchPackageConfig(
      os: OS.windows,
      architectures: [Architecture.x64],
      release: release,
    ),
  ];

  @override
  String get _archiveUrl => Uri(
    scheme: 'https',
    host: 'packages.couchbase.com',
    pathSegments: [
      'releases',
      'couchbase-lite-vector-search',
      release,
      if (os == OS.iOS)
        'couchbase-lite-vector-search_xcframework_'
            '$release.${archiveFormat.extension}'
      else
        [
          'couchbase-lite-vector-search',
          '-',
          release,
          '-',
          os.couchbaseSdkName,
          if (!isMultiArchitecture) ...[
            '-',
            if (os == OS.android && architectures.single == Architecture.arm64)
              'arm64-v8a'
            else
              architectures.single.couchbaseSdkName,
          ],
          '.',
          archiveFormat.extension,
        ].join(),
    ],
  ).toString();

  @override
  Future<void> _postProcess(String packageDir) async {
    if (os == OS.macOS) {
      // It seems like the shared library was taken out of a framework, but for
      // linking during the build process for a macOS App and loading of the
      // extension to work, it needs to be in a framework.
      // So we place the shared library back into a framework.
      final libraryFile = File(
        p.join(packageDir, 'CouchbaseLiteVectorSearch.dylib'),
      );
      final frameworkDirectory = Directory(
        p.join(packageDir, 'CouchbaseLiteVectorSearch.framework'),
      );
      final versionedLibraryPath = p.join(
        'Versions',
        'A',
        'CouchbaseLiteVectorSearch',
      );
      final versionedLibraryFile = File(
        p.join(frameworkDirectory.path, versionedLibraryPath),
      );
      await versionedLibraryFile.parent.create(recursive: true);
      await libraryFile.rename(versionedLibraryFile.path);
      await Link(
        p.join(frameworkDirectory.path, 'CouchbaseLiteVectorSearch'),
      ).create(versionedLibraryPath);

      // The library needs to be code signed for it to be included in the
      // release build of a macOS App. It is shipped without any code signing.
      final codesignResult = await Process.run('codesign', [
        '--force',
        '--sign',
        '-',
        '--timestamp=none',
        versionedLibraryFile.path,
      ]);
      if (codesignResult.exitCode != 0) {
        throw Exception(
          'Failed to code sign the CouchbaseLiteVectorSearch library '
          '(${codesignResult.exitCode}):\n'
          '${codesignResult.stdout}\n'
          '${codesignResult.stderr}',
        );
      }
    }
  }
}

extension NativeLibraryOSExtension on OS {
  String get couchbaseSdkName => switch (this) {
    OS.android => 'android',
    OS.fuchsia => throw UnsupportedError('Unsupported OS: $this'),
    OS.iOS => 'ios',
    OS.linux => 'linux',
    OS.macOS => 'macos',
    OS.windows => 'windows',
    _ => throw UnsupportedError('Unsupported OS: $this'),
  };
}

extension NativeLibraryArchitectureExtension on Architecture {
  String get couchbaseSdkName => switch (this) {
    Architecture.arm => 'arm',
    Architecture.arm64 => 'arm64',
    Architecture.ia32 => 'i686',
    Architecture.x64 => 'x86_64',
    Architecture.riscv32 || Architecture.riscv64 => throw UnsupportedError(
      'Unsupported architecture: $this',
    ),
    _ => throw UnsupportedError('Unsupported architecture: $this'),
  };

  String get androidTriple => switch (this) {
    Architecture.arm => 'arm-linux-androideabi',
    Architecture.arm64 => 'aarch64-linux-android',
    Architecture.ia32 => 'i686-linux-android',
    Architecture.x64 => 'x86_64-linux-android',
    Architecture.riscv32 || Architecture.riscv64 => throw UnsupportedError(
      'Unsupported architecture: $this',
    ),
    _ => throw UnsupportedError('Unsupported architecture: $this'),
  };

  String get linuxTripple => switch (this) {
    Architecture.arm => 'arm-linux-gnu',
    Architecture.arm64 => 'aarch64-linux-gnu',
    Architecture.ia32 => 'i686-linux-gnu',
    Architecture.x64 => 'x86_64-linux-gnu',
    Architecture.riscv32 || Architecture.riscv64 => throw UnsupportedError(
      'Unsupported architecture: $this',
    ),
    _ => throw UnsupportedError('Unsupported architecture: $this'),
  };
}
