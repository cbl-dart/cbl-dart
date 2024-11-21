// ignore_for_file: non_constant_identifier_names

import 'dart:io';

import 'package:path/path.dart' as p;

import 'utils.dart';

/// An archive format.
enum ArchiveFormat {
  zip,
  tarGz;

  String get extension => switch (this) {
        ArchiveFormat.zip => 'zip',
        ArchiveFormat.tarGz => 'tar.gz'
      };
}

/// A library that is distributed as part of cbl-dart.
enum Library {
  cblite._('cblite'),
  cblitedart._('cblitedart'),
  vectorSearch._('CouchbaseLiteVectorSearch');

  const Library._(this.libraryName);

  static const databaseLibraries = [cblite, cblitedart];

  final String libraryName;

  String get libLibraryName => 'lib$libraryName';

  bool get isDatabaseLibrary => databaseLibraries.contains(this);
}

/// A Couchbase Lite edition.
enum Edition {
  community,
  enterprise,
}

/// An operating system.
enum OS {
  android,
  iOS,
  macOS,
  linux,
  windows;

  static OS get current {
    if (Platform.isAndroid) {
      return android;
    }

    if (Platform.isIOS) {
      return iOS;
    }

    if (Platform.isMacOS) {
      return macOS;
    }

    if (Platform.isLinux) {
      return linux;
    }

    if (Platform.isWindows) {
      return windows;
    }

    throw UnsupportedError('Unsupported platform');
  }
}

/// A CPU architecture.
enum Architecture {
  ia32,
  x64,
  arm,
  arm64,
}

abstract class PackageLoader {
  Future<Package> load(PackageConfig config) async =>
      config._package(await _packageDir(config));

  Future<String> _packageDir(PackageConfig config);
}

final class RemotePackageLoader extends PackageLoader {
  RemotePackageLoader({String? cacheDir})
      : cacheDir = cacheDir ?? _globalCacheDir;

  static String get _globalCacheDir =>
      p.join(userCachesDir, 'cbl_native_package');

  final String cacheDir;

  @override
  Future<String> _packageDir(PackageConfig config) async {
    final archiveBaseName =
        p.basenameWithoutExtension(Uri.parse(config._archiveUrl).path);

    final packageDir = p.join(cacheDir, archiveBaseName);

    final packageDirectory = Directory(packageDir);
    if (packageDirectory.existsSync()) {
      return packageDir;
    }

    final tempDirectory = await Directory.systemTemp.createTemp();
    try {
      final archiveData = await downloadUrl(config._archiveUrl);
      await unpackArchive(
        archiveData,
        format: config.archiveFormat,
        outputDir: tempDirectory.path,
      );
      try {
        await moveDirectory(tempDirectory, packageDirectory);
      } on PathExistsException {
        // Another process has already downloaded the archive.
      }
    } finally {
      if (tempDirectory.existsSync()) {
        await tempDirectory.delete(recursive: true);
      }
    }

    return packageDir;
  }
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
      ? os.sdkName
      : '${os.sdkName}-${architectures.single.sdkName}';
  String get version => release.split('-').first;

  String get _archiveUrl;

  Package _package(String packageDir);
}

final class DatabasePackageConfig extends PackageConfig {
  DatabasePackageConfig({
    required super.library,
    required super.os,
    required super.architectures,
    required super.release,
    required super.archiveFormat,
    required this.edition,
  });

  static List<DatabasePackageConfig> all({
    required Map<Library, String> releases,
    required Edition edition,
  }) {
    for (final library in releases.keys) {
      if (!library.isDatabaseLibrary) {
        throw ArgumentError('$library is not a database library');
      }
    }

    return [
      for (final MapEntry(key: library, value: release)
          in releases.entries) ...[
        DatabasePackageConfig(
          library: library,
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
        DatabasePackageConfig(
          library: library,
          os: OS.iOS,
          architectures: [
            Architecture.arm64,
            Architecture.x64,
          ],
          release: release,
          archiveFormat: ArchiveFormat.zip,
          edition: edition,
        ),
        DatabasePackageConfig(
          library: library,
          os: OS.macOS,
          architectures: [
            Architecture.arm64,
            Architecture.x64,
          ],
          release: release,
          archiveFormat: ArchiveFormat.zip,
          edition: edition,
        ),
        DatabasePackageConfig(
          library: library,
          os: OS.linux,
          architectures: [Architecture.x64],
          release: release,
          archiveFormat: ArchiveFormat.tarGz,
          edition: edition,
        ),
        DatabasePackageConfig(
          library: library,
          os: OS.windows,
          architectures: [Architecture.x64],
          release: release,
          archiveFormat: ArchiveFormat.zip,
          edition: edition,
        ),
      ]
    ];
  }

  final Edition edition;

  @override
  String get _archiveUrl => switch (library) {
        Library.cblite => Uri(
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
                '$targetId.${archiveFormat.extension}'
              ].join('-'),
            ],
          ).toString(),
        Library.cblitedart => Uri(
            scheme: 'https',
            host: 'github.com',
            pathSegments: [
              'cbl-dart',
              'cbl-dart',
              'releases',
              'download',
              'libcblitedart-v$release',
              [
                'couchbase-lite-dart',
                release,
                edition.name,
                '$targetId.${archiveFormat.extension}',
              ].join('-'),
            ],
          ).toString(),
        _ => throw UnsupportedError('$library'),
      };

  @override
  Package _package(String packageDir) => switch (os) {
        OS.android =>
          DatabaseAndroidPackage(config: this, packageDir: packageDir),
        _ => DatabaseStandardPackage(config: this, packageDir: packageDir),
      };
}

final class VectorSearchPackageConfig extends PackageConfig {
  VectorSearchPackageConfig({
    required super.os,
    required super.architectures,
    required super.release,
  }) : super(
          library: Library.vectorSearch,
          archiveFormat: ArchiveFormat.zip,
        );

  static List<VectorSearchPackageConfig> all({
    required String release,
  }) =>
      [
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
          architectures: [
            Architecture.arm64,
            Architecture.x64,
          ],
          release: release,
        ),
        VectorSearchPackageConfig(
          os: OS.macOS,
          architectures: [
            Architecture.arm64,
            Architecture.x64,
          ],
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
            '${[
              'couchbase-lite-vector-search',
              release,
              os.sdkName,
              if (!isMultiArchitecture)
                if (os == OS.android &&
                    architectures.single == Architecture.arm64)
                  'arm64-v8a'
                else
                  architectures.single.sdkName
            ].join('-')}.${archiveFormat.extension}'
        ],
      ).toString();

  @override
  Package _package(String packageDir) =>
      VectorSearchPackage(config: this, packageDir: packageDir);
}

sealed class Package {
  Package({
    required this.config,
    required this.packageDir,
  });

  final PackageConfig config;
  final String packageDir;
}

final class DatabaseAndroidPackage extends Package {
  DatabaseAndroidPackage({required super.config, required super.packageDir})
      : assert(config.os == OS.android);

  String get baseDir =>
      p.join(packageDir, '${config.library.libLibraryName}-${config.version}');

  String sharedLibrariesDir(Architecture architecture) =>
      p.join(baseDir, p.join('lib', architecture.androidTriple));
}

final class DatabaseStandardPackage extends Package {
  DatabaseStandardPackage({required super.config, required super.packageDir});

  String get baseDir =>
      p.join(packageDir, '${config.library.libLibraryName}-${config.version}');

  String get includeDir => p.join(baseDir, 'include');

  String get sharedLibrariesDir => p.join(
        baseDir,
        switch (config.os) {
          OS.macOS => 'lib',
          OS.linux => p.join('lib', config.architectures.single.linuxTripple),
          OS.windows => 'bin',
          _ => throw UnsupportedError('${config.os}'),
        },
      );

  String get libraryName => switch (config.os) {
        OS.linux || OS.macOS => config.library.libLibraryName,
        OS.windows => config.library.libraryName,
        _ => throw UnsupportedError('${config.os}'),
      };
}

final class VectorSearchPackage extends Package {
  VectorSearchPackage({required super.config, required super.packageDir});

  String? get sharedLibrariesDir {
    final directory = switch (config.os) {
      OS.macOS => packageDir,
      OS.linux || OS.android => 'lib',
      OS.windows => 'bin',
      OS.iOS => null,
    };

    if (directory == null) {
      return null;
    }

    return p.join(packageDir, directory);
  }

  String get libraryName => switch (config.os) {
        OS.linux => config.library.libLibraryName,
        OS.windows || OS.macOS => config.library.libraryName,
        _ => throw UnsupportedError('${config.os}'),
      };
}

extension on OS {
  String get sdkName => switch (this) {
        OS.android => 'android',
        OS.iOS => 'ios',
        OS.linux => 'linux',
        OS.macOS => 'macos',
        OS.windows => 'windows',
      };
}

extension on Architecture {
  String get sdkName => switch (this) {
        Architecture.arm => 'arm',
        Architecture.arm64 => 'arm64',
        Architecture.ia32 => 'i686',
        Architecture.x64 => 'x86_64',
      };

  String get androidTriple => switch (this) {
        Architecture.arm => 'arm-linux-androideabi',
        Architecture.arm64 => 'aarch64-linux-android',
        Architecture.ia32 => 'i686-linux-android',
        Architecture.x64 => 'x86_64-linux-android',
      };

  String get linuxTripple => switch (this) {
        Architecture.arm => 'arm-linux-gnu',
        Architecture.arm64 => 'aarch64-linux-gnu',
        Architecture.ia32 => 'i686-linux-gnu',
        Architecture.x64 => 'x86_64-linux-gnu',
      };
}
