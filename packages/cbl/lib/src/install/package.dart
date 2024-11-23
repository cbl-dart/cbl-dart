// ignore_for_file: non_constant_identifier_names

import 'dart:io';

import 'package:path/path.dart' as p;

import 'utils.dart';

/// An archive format.
enum ArchiveFormat {
  zip,
  tarGz;

  String get _ext => switch (this) {
        ArchiveFormat.zip => 'zip',
        ArchiveFormat.tarGz => 'tar.gz'
      };
}

/// A library that is distributed as part of cbl-dart.
enum Library {
  libcblite,
  libcblitedart,
}

/// A Couchbase Lite edition.
enum Edition {
  community,
  enterprise,
}

/// An operating system.
enum OS {
  android,
  ios,
  macos,
  linux,
  windows;

  static OS get current {
    if (Platform.isAndroid) {
      return android;
    }

    if (Platform.isIOS) {
      return ios;
    }

    if (Platform.isMacOS) {
      return macos;
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
  x86,
  x86_64,
  arm,
  arm64,
}

abstract class PackageLoader {
  Future<Package> load(PackageConfig config) async =>
      config._package(await _packageDir(config));

  Future<String> _packageDir(PackageConfig config);
}

final class RemotePackageLoader extends PackageLoader {
  static String get _cacheDir => p.join(userCachesDir, 'cbl_native_package');

  @override
  Future<String> _packageDir(PackageConfig config) async {
    final archiveBaseName =
        p.basenameWithoutExtension(Uri.parse(config._archiveUrl).path);

    final packageDir = p.join(_cacheDir, archiveBaseName);

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
  String get targetId =>
      isMultiArchitecture ? os.name : '${os.name}-${architectures.single.name}';
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
  }) =>
      [
        for (final library in [Library.libcblite, Library.libcblitedart]) ...[
          DatabasePackageConfig(
            library: library,
            os: OS.android,
            architectures: [
              Architecture.arm,
              Architecture.arm64,
              Architecture.x86,
              Architecture.x86_64,
            ],
            release: releases[library]!,
            archiveFormat: ArchiveFormat.zip,
            edition: edition,
          ),
          DatabasePackageConfig(
            library: library,
            os: OS.ios,
            architectures: [
              Architecture.arm64,
              Architecture.x86_64,
            ],
            release: releases[library]!,
            archiveFormat: ArchiveFormat.zip,
            edition: edition,
          ),
          DatabasePackageConfig(
            library: library,
            os: OS.macos,
            architectures: [
              Architecture.arm64,
              Architecture.x86_64,
            ],
            release: releases[library]!,
            archiveFormat: ArchiveFormat.zip,
            edition: edition,
          ),
          DatabasePackageConfig(
            library: library,
            os: OS.linux,
            architectures: [Architecture.x86_64],
            release: releases[library]!,
            archiveFormat: ArchiveFormat.tarGz,
            edition: edition,
          ),
          DatabasePackageConfig(
            library: library,
            os: OS.windows,
            architectures: [Architecture.x86_64],
            release: releases[library]!,
            archiveFormat: ArchiveFormat.zip,
            edition: edition,
          ),
        ]
      ];

  final Edition edition;

  @override
  String get _archiveUrl => switch (library) {
        Library.libcblite => 'https://packages.couchbase.com/releases/'
            'couchbase-lite-c/$release/'
            'couchbase-lite-c-${edition.name}-$release-'
            '$targetId.${archiveFormat._ext}',
        Library.libcblitedart =>
          'https://github.com/cbl-dart/cbl-dart/releases/download/'
              'libcblitedart-v$release/'
              'couchbase-lite-dart-$release-${edition.name}-'
              '$targetId.${archiveFormat._ext}'
      };

  @override
  Package _package(String packageDir) => switch (os) {
        OS.android => AndroidPackage(config: this, packageDir: packageDir),
        _ => StandardPackage(config: this, packageDir: packageDir),
      };
}

sealed class Package {
  Package({
    required this.config,
    required this.packageDir,
  });

  final PackageConfig config;
  final String packageDir;
}

final class AndroidPackage extends Package {
  AndroidPackage({required super.config, required super.packageDir})
      : assert(config.os == OS.android);

  String get baseDir =>
      p.join(packageDir, '${config.library.name}-${config.version}');

  String sharedLibrariesDir(Architecture architecture) => p.join(
        baseDir,
        p.join(
          'lib',
          switch (architecture) {
            Architecture.x86 => 'i686-linux-android',
            Architecture.x86_64 => 'x86_64-linux-android',
            Architecture.arm => 'arm-linux-androideabi',
            Architecture.arm64 => 'aarch64-linux-android',
          },
        ),
      );
}

final class StandardPackage extends Package {
  StandardPackage({required super.config, required super.packageDir});

  String get baseDir =>
      p.join(packageDir, '${config.library.name}-${config.version}');

  String get includeDir => p.join(baseDir, 'include');

  String get sharedLibrariesDir => p.join(
        baseDir,
        switch (config.os) {
          OS.macos => 'lib',
          OS.linux =>
            p.join('lib', '${config.architectures.single.name}-linux-gnu'),
          OS.windows => 'bin',
          _ => throw UnsupportedError('${config.os}'),
        },
      );

  String get libraryName => switch (config.os) {
        OS.linux || OS.macos => config.library.name,
        OS.windows => config.library.name.replaceAll('lib', ''),
        _ => throw UnsupportedError('${config.os}'),
      };
}
