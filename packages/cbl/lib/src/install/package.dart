// ignore_for_file: non_constant_identifier_names

import 'dart:io';

import 'package:path/path.dart' as p;

import 'utils.dart';

/// A library that is distributed as part of cbl-dart.
enum Library {
  cblite,
  cblitedart,
  vectorSearch;

  static const databaseLibraries = [cblite, cblitedart];

  bool get isDatabaseLibrary => databaseLibraries.contains(this);

  String? packageRootDir(OS os, String version) => switch (this) {
        cblite => switch (os) {
            OS.android ||
            OS.linux ||
            OS.macOS ||
            OS.windows =>
              'libcblite-$version',
            OS.iOS => null
          },
        cblitedart => switch (os) {
            OS.android ||
            OS.linux ||
            OS.macOS ||
            OS.windows =>
              'libcblitedart-$version',
            OS.iOS => null
          },
        vectorSearch => null,
      };

  AppleFrameworkType? appleFrameworkType(OS os) => switch (this) {
        cblite ||
        cblitedart =>
          os == OS.iOS ? AppleFrameworkType.xcframework : null,
        vectorSearch => switch (os) {
            OS.iOS => AppleFrameworkType.xcframework,
            OS.macOS => AppleFrameworkType.framework,
            OS.android || OS.linux || OS.windows => null,
          },
      };

  String? sharedLibrariesDir(OS os, Architecture architecture) =>
      switch (this) {
        cblite || cblitedart => switch (os) {
            OS.android => p.join('lib', architecture.androidTriple),
            OS.macOS => 'lib',
            OS.linux => p.join('lib', architecture.linuxTripple),
            OS.windows => 'bin',
            OS.iOS => null,
          },
        vectorSearch => switch (os) {
            OS.linux || OS.android => 'lib',
            OS.windows => 'bin',
            OS.iOS || OS.macOS => null,
          }
      };

  String libraryName(OS os) => switch (this) {
        cblite => switch (os) {
            OS.linux || OS.android || OS.macOS => 'libcblite',
            OS.windows => 'cblite',
            OS.iOS => 'CouchbaseLite',
          },
        cblitedart => switch (os) {
            OS.linux || OS.android || OS.macOS => 'libcblitedart',
            OS.windows => 'cblitedart',
            OS.iOS => 'CouchbaseLiteDart',
          },
        vectorSearch => switch (os) {
            OS.android => 'libCouchbaseLiteVectorSearch',
            OS.linux ||
            OS.windows ||
            OS.macOS ||
            OS.iOS =>
              'CouchbaseLiteVectorSearch',
          },
      };
}

/// A Couchbase Lite edition.
enum Edition {
  community,
  enterprise,
}

/// An archive format.
enum ArchiveFormat {
  zip,
  tarGz;

  String get extension => switch (this) { zip => 'zip', tarGz => 'tar.gz' };
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
  Package({
    required this.config,
    required this.packageDir,
  });

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
    final sharedLibrariesDirectories =
        config.architectures.map(sharedLibrariesDir).toSet();
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
      : cacheDir = cacheDir ?? _globalCacheDir;

  static String get _globalCacheDir =>
      p.join(userCachesDir, 'cbl_native_package');

  final String cacheDir;

  @override
  Future<String> _packageDir(PackageConfig config) async {
    print(config._archiveUrl);
    final archiveBaseName =
        p.basenameWithoutExtension(Uri.parse(config._archiveUrl).path);

    final packageDir = p.join(cacheDir, archiveBaseName);

    final packageDirectory = Directory(packageDir);
    if (packageDirectory.existsSync()) {
      return packageDir;
    }

    final cacheTempDir = Directory(p.join(cacheDir, '.temp'));
    await cacheTempDir.create(recursive: true);

    final tempDirectory = await cacheTempDir.createTemp();
    try {
      final archiveData = await downloadUrl(config._archiveUrl);
      await unpackArchive(
        archiveData,
        format: config.archiveFormat,
        outputDir: tempDirectory.path,
      );
      await config._postProcess(tempDirectory.path);
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
              os.couchbaseSdkName,
              if (!isMultiArchitecture)
                if (os == OS.android &&
                    architectures.single == Architecture.arm64)
                  'arm64-v8a'
                else
                  architectures.single.couchbaseSdkName
            ].join('-')}.${archiveFormat.extension}'
        ],
      ).toString();

  @override
  Future<void> _postProcess(String packageDir) async {
    if (os == OS.macOS) {
      // It seems like the shared library was taken out of a framework, but for
      // linking during the build process for a macOS App and loading of the
      // extension to work, it needs to be in a framework.
      // So we place the shared library back into a framework.
      final libraryFile =
          File(p.join(packageDir, 'CouchbaseLiteVectorSearch.dylib'));
      final frameworkDirectory = Directory(p.join(
        packageDir,
        'CouchbaseLiteVectorSearch.framework',
      ));
      final versionedLibraryPath =
          p.join('Versions', 'A', 'CouchbaseLiteVectorSearch');
      final versionedLibraryFile =
          File(p.join(frameworkDirectory.path, versionedLibraryPath));
      await versionedLibraryFile.parent.create(recursive: true);
      await libraryFile.rename(versionedLibraryFile.path);
      await Link(p.join(frameworkDirectory.path, 'CouchbaseLiteVectorSearch'))
          .create(versionedLibraryPath);

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

extension on OS {
  String get couchbaseSdkName => switch (this) {
        OS.android => 'android',
        OS.iOS => 'ios',
        OS.linux => 'linux',
        OS.macOS => 'macos',
        OS.windows => 'windows',
      };
}

extension on Architecture {
  String get couchbaseSdkName => switch (this) {
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
