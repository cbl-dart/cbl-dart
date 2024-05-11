import 'dart:io';

import 'package:logging/logging.dart';
import 'package:native_assets_cli/native_assets_cli.dart';

import 'tools.dart';

enum CbliteEdition {
  community,
  enterprise,
}

class CblitePackage {
  const CblitePackage._({
    required this.version,
    required this.edition,
    required this.os,
    this.iosSdk,
    required this.architectures,
    required ArchiveFormat archiveFormat,
    bool? isSingleArchitectureBundle,
  })  : _archiveFormat = archiveFormat,
        _isSingleArchitectureBundle =
            isSingleArchitectureBundle ?? architectures.length == 1;

  static List<CblitePackage> forOS(
    OS os, {
    required String version,
    required CbliteEdition edition,
  }) =>
      switch (os) {
        OS.android => [
            CblitePackage._(
              version: version,
              edition: edition,
              os: os,
              architectures: [
                Architecture.arm,
                Architecture.arm64,
                Architecture.x64,
                Architecture.ia32,
              ],
              archiveFormat: ArchiveFormat.zip,
            ),
          ],
        OS.iOS => [
            CblitePackage._(
              version: version,
              edition: edition,
              os: os,
              iosSdk: IOSSdk.iPhoneOS,
              architectures: [Architecture.arm64],
              archiveFormat: ArchiveFormat.zip,
              isSingleArchitectureBundle: false,
            ),
            CblitePackage._(
              version: version,
              edition: edition,
              os: os,
              iosSdk: IOSSdk.iPhoneSimulator,
              architectures: [Architecture.arm64, Architecture.x64],
              archiveFormat: ArchiveFormat.zip,
            ),
          ],
        OS.macOS => [
            CblitePackage._(
              version: version,
              edition: edition,
              os: os,
              architectures: [Architecture.arm64, Architecture.x64],
              archiveFormat: ArchiveFormat.zip,
            ),
          ],
        OS.linux => [
            for (final architecture in [Architecture.arm64, Architecture.x64])
              CblitePackage._(
                version: version,
                edition: edition,
                os: os,
                architectures: [architecture],
                archiveFormat: ArchiveFormat.tarGz,
              ),
          ],
        OS.windows => [
            for (final architecture in [Architecture.x64, Architecture.arm64])
              CblitePackage._(
                version: version,
                edition: edition,
                os: os,
                architectures: [architecture],
                archiveFormat: ArchiveFormat.zip,
              ),
          ],
        _ => [],
      };

  final String version;
  final CbliteEdition edition;
  final OS os;
  final IOSSdk? iosSdk;
  final List<Architecture> architectures;

  final ArchiveFormat _archiveFormat;
  final bool _isSingleArchitectureBundle;

  Uri get _archiveUrl => Uri(
        scheme: 'https',
        host: 'packages.couchbase.com',
        pathSegments: [
          'releases',
          'couchbase-lite-c',
          version,
          '${[
            'couchbase-lite-c',
            edition.name,
            version,
            os.sdkName,
            if (_isSingleArchitectureBundle) architectures.single.sdkName
          ].join('-')}.${_archiveFormat.ext}',
        ],
      );

  bool matchesBuildConfig(BuildConfig buildConfig) =>
      architectures.contains(buildConfig.targetArchitecture) &&
      (iosSdk == null || buildConfig.targetIOSSdk == iosSdk);

  Uri resolveLibraryUri(
    Uri outputDirectoryUri,
    Architecture architecture,
  ) =>
      _resolveLibraryUriInArchive(
        _resolveArchiveDirectoryUri(outputDirectoryUri),
        architecture,
      );

  Future<void> installPackage(
    Uri outputDirectoryUri,
    Architecture architecture,
    Logger logger,
  ) async {
    final archiveDirectoryUri = _resolveArchiveDirectoryUri(outputDirectoryUri);
    final archiveDirectory = Directory.fromUri(archiveDirectoryUri);

    // TODO(blaugold): Avoid downloading the archive if it already exists.
    if (archiveDirectory.existsSync()) {
      archiveDirectory.deleteSync(recursive: true);
    }

    final archiveData = await downloadUrl(_archiveUrl, logger: logger);
    await unpackArchive(
      archiveData,
      outputDirectory: archiveDirectoryUri,
      format: _archiveFormat,
      logger: logger,
    );

    // Replace fat binary with an architecture specific binary, because
    // iOS native code assets are expected to be architecture specific.
    if (iosSdk == IOSSdk.iPhoneSimulator) {
      await _thinLibrary(outputDirectoryUri, architecture);
    }
  }

  Future<void> installHeaders(Uri outputDirectoryUri, Logger logger) async {
    final tmpDirectory = Directory.systemTemp.createTempSync();

    try {
      final archiveData = await downloadUrl(_archiveUrl, logger: logger);
      await unpackArchive(
        archiveData,
        outputDirectory: tmpDirectory.uri,
        format: _archiveFormat,
        logger: logger,
      );
      final includeDirectoryUri = _resolveIncludeDirectoryUri(tmpDirectory.uri);
      final includeDirectory = Directory.fromUri(includeDirectoryUri);

      final outputDirectory = Directory.fromUri(outputDirectoryUri);
      if (outputDirectory.existsSync()) {
        await outputDirectory.delete(recursive: true);
      }

      await includeDirectory.rename(outputDirectory.path);
    } finally {
      await tmpDirectory.delete(recursive: true);
    }
  }

  Uri _resolveArchiveDirectoryUri(Uri outputDirectoryUri) =>
      outputDirectoryUri.resolve('CouchbaseLite/');

  Uri _resolveLibraryUriInArchive(
    Uri archiveDirectoryUri,
    Architecture architecture,
  ) {
    final fileNameVersion = version.split('.').first;

    final pathInArchive = switch (os) {
      OS.android =>
        'libcblite-$version/lib/${architecture.androidTriple}/libcblite.so',
      OS.iOS =>
        'CouchbaseLite.xcframework/${iosSdk!.iosFrameworkDirectory}/CouchbaseLite.framework/CouchbaseLite',
      OS.macOS => 'libcblite-$version/lib/libcblite.$fileNameVersion.dylib',
      OS.linux =>
        'libcblite-$version/lib/${architecture.linuxTripple}/libcblite.so.$fileNameVersion',
      OS.windows => 'libcblite-$version/bin/cblite.dll',
      _ => throw UnimplementedError(),
    };

    return archiveDirectoryUri.resolve(pathInArchive);
  }

  Uri _resolveIncludeDirectoryUri(Uri archiveDirectory) => switch (os) {
        OS.macOS => archiveDirectory.resolve('libcblite-$version/include/'),
        _ => throw UnimplementedError(),
      };

  Future<void> _thinLibrary(
    Uri outputDirectoryUri,
    Architecture architecture,
  ) async {
    final libraryUri = resolveLibraryUri(outputDirectoryUri, architecture);
    final thinLibraryUri = libraryUri.resolve('thin');

    final result = Process.runSync('lipo', [
      libraryUri.toFilePath(),
      '-thin',
      if (architecture == Architecture.arm64) 'arm64' else 'x86_64',
      '-output',
      thinLibraryUri.toFilePath(),
    ]);

    if (result.exitCode != 0) {
      throw Exception('Failed to extract thin library: ${result.stderr}');
    }

    await File.fromUri(libraryUri).delete();
    await File.fromUri(thinLibraryUri).rename(libraryUri.toFilePath());
  }
}

extension on OS {
  String get sdkName => switch (this) {
        OS.android => 'android',
        OS.iOS => 'ios',
        OS.linux => 'linux',
        OS.macOS => 'macos',
        OS.windows => 'windows',
        _ => throw UnimplementedError(),
      };
}

extension on Architecture {
  String get sdkName => switch (this) {
        Architecture.arm => 'arm',
        Architecture.arm64 => 'arm64',
        Architecture.ia32 => 'i686',
        Architecture.x64 => 'x86_64',
        _ => throw UnimplementedError(),
      };
}

extension on Architecture {
  String get androidTriple => switch (this) {
        Architecture.arm => 'arm-linux-androideabi',
        Architecture.arm64 => 'aarch64-linux-android',
        Architecture.ia32 => 'i686-linux-android',
        Architecture.x64 => 'x86_64-linux-android',
        _ => throw UnimplementedError(),
      };
}

extension on Architecture {
  String get linuxTripple => switch (this) {
        Architecture.arm => 'arm-linux-gnu',
        Architecture.arm64 => 'aarch64-linux-gnu',
        Architecture.ia32 => 'i686-linux-gnu',
        Architecture.x64 => 'x86_64-linux-gnu',
        _ => throw UnimplementedError(),
      };
}

extension on IOSSdk {
  String get iosFrameworkDirectory => switch (this) {
        IOSSdk.iPhoneOS => 'ios-arm64',
        IOSSdk.iPhoneSimulator => 'ios-arm64_x86_64-simulator',
        _ => throw UnimplementedError(),
      };
}
