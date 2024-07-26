import 'dart:io';
import 'dart:typed_data';

import 'package:cbl_native_assets/src/support/edition.dart';
import 'package:logging/logging.dart';
import 'package:native_assets_cli/native_assets_cli.dart';

import 'tools.dart';

// ignore: one_member_abstracts
abstract class CbliteArchiveLoader {
  String get version;

  Future<Uint8List> loadArchiveData(CblitePackage package, Logger logger);
}

class RemoteDatabaseArchiveLoader implements CbliteArchiveLoader {
  const RemoteDatabaseArchiveLoader({required this.version});

  @override
  final String version;

  Uri _archiveUrl(CblitePackage package) {
    assert(package.binary == CbliteBinary.databaseCommunity ||
        package.binary == CbliteBinary.databaseEnterprise);

    final CblitePackage(
      :binary,
      :os,
      :isSingleArchitectureBundle,
      :architectures,
      :archiveFormat
    ) = package;

    return Uri(
      scheme: 'https',
      host: 'packages.couchbase.com',
      pathSegments: [
        'releases',
        'couchbase-lite-c',
        version,
        '${[
          'couchbase-lite-c',
          binary.edition!.name,
          version,
          os.sdkName,
          if (isSingleArchitectureBundle) architectures.single.sdkName
        ].join('-')}.${archiveFormat.ext}',
      ],
    );
  }

  @override
  Future<Uint8List> loadArchiveData(CblitePackage package, Logger logger) =>
      downloadUrl(_archiveUrl(package), logger: logger);
}

class LocalDatabaseArchiveLoader implements CbliteArchiveLoader {
  const LocalDatabaseArchiveLoader({
    required this.archiveDirectoryUri,
    required this.version,
    required this.build,
  });

  final Uri archiveDirectoryUri;
  @override
  final String version;
  final int build;

  Uri _archiveFileUri(CblitePackage package) {
    assert(package.binary == CbliteBinary.databaseCommunity ||
        package.binary == CbliteBinary.databaseEnterprise);

    final CblitePackage(
      :binary,
      :os,
      :isSingleArchitectureBundle,
      :architectures,
      :archiveFormat
    ) = package;

    return Uri(
      scheme: 'file',
      pathSegments: [
        ...archiveDirectoryUri.pathSegments,
        '${[
          'couchbase-lite-c',
          binary.edition!.name,
          version,
          build,
          os.sdkName,
          if (isSingleArchitectureBundle) architectures.single.sdkName
        ].join('-')}.${archiveFormat.ext}'
      ],
    );
  }

  @override
  Future<Uint8List> loadArchiveData(CblitePackage package, Logger logger) =>
      File.fromUri(_archiveFileUri(package)).readAsBytes();
}

class LocalVectorSearchArchiveLoader implements CbliteArchiveLoader {
  const LocalVectorSearchArchiveLoader({
    required this.archiveDirectoryUri,
    required this.version,
    required this.build,
  });

  final Uri archiveDirectoryUri;
  @override
  final String version;
  final int build;

  Uri _archiveFileUri(CblitePackage package) {
    assert(package.binary == CbliteBinary.vectorSearchExtension);

    final CblitePackage(
      :os,
      :isSingleArchitectureBundle,
      :architectures,
      :archiveFormat
    ) = package;

    return Uri(
      scheme: 'file',
      pathSegments: [
        ...archiveDirectoryUri.pathSegments,
        if (os == OS.iOS)
          'couchbase-lite-vector-search_xcframework_'
              '$version-$build.${archiveFormat.ext}'
        else
          '${[
            'couchbase-lite-vector-search',
            version,
            build,
            os.sdkName,
            if (isSingleArchitectureBundle)
              if (os == OS.android &&
                  architectures.single == Architecture.arm64)
                'arm64-v8a'
              else
                architectures.single.sdkName
          ].join('-')}.${archiveFormat.ext}'
      ],
    );
  }

  @override
  Future<Uint8List> loadArchiveData(CblitePackage package, Logger logger) =>
      File.fromUri(_archiveFileUri(package)).readAsBytes();
}

enum CbliteBinary {
  databaseCommunity,
  databaseEnterprise,
  vectorSearchExtension;

  factory CbliteBinary.fromEdition(Edition edition) => switch (edition) {
        Edition.community => databaseCommunity,
        Edition.enterprise => databaseEnterprise,
      };

  Edition? get edition => switch (this) {
        databaseCommunity => Edition.community,
        databaseEnterprise => Edition.enterprise,
        vectorSearchExtension => null
      };
}

class CblitePackage {
  const CblitePackage._({
    required this.binary,
    required this.os,
    this.iosSdk,
    required this.architectures,
    required this.archiveFormat,
    required this.loader,
    bool? isSingleArchitectureBundle,
  }) : isSingleArchitectureBundle =
            isSingleArchitectureBundle ?? architectures.length == 1;

  static List<CblitePackage> database({
    required Edition edition,
    required OS os,
    required CbliteArchiveLoader loader,
  }) =>
      switch (os) {
        OS.android => [
            CblitePackage._(
              binary: CbliteBinary.fromEdition(edition),
              os: os,
              loader: loader,
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
              binary: CbliteBinary.fromEdition(edition),
              os: os,
              loader: loader,
              iosSdk: IOSSdk.iPhoneOS,
              architectures: [Architecture.arm64],
              archiveFormat: ArchiveFormat.zip,
              isSingleArchitectureBundle: false,
            ),
            CblitePackage._(
              binary: CbliteBinary.fromEdition(edition),
              os: os,
              loader: loader,
              iosSdk: IOSSdk.iPhoneSimulator,
              architectures: [Architecture.arm64, Architecture.x64],
              archiveFormat: ArchiveFormat.zip,
            ),
          ],
        OS.macOS => [
            CblitePackage._(
              binary: CbliteBinary.fromEdition(edition),
              os: os,
              loader: loader,
              architectures: [Architecture.arm64, Architecture.x64],
              archiveFormat: ArchiveFormat.zip,
            ),
          ],
        OS.linux => [
            for (final architecture in [Architecture.arm64, Architecture.x64])
              CblitePackage._(
                binary: CbliteBinary.fromEdition(edition),
                os: os,
                loader: loader,
                architectures: [architecture],
                archiveFormat: ArchiveFormat.tarGz,
              ),
          ],
        OS.windows => [
            for (final architecture in [Architecture.x64, Architecture.arm64])
              CblitePackage._(
                binary: CbliteBinary.fromEdition(edition),
                os: os,
                loader: loader,
                architectures: [architecture],
                archiveFormat: ArchiveFormat.zip,
              ),
          ],
        _ => [],
      };

  static List<CblitePackage> vectorSearchExtension({
    required OS os,
    required CbliteArchiveLoader loader,
  }) =>
      switch (os) {
        OS.android => [
            for (final architecture in [Architecture.arm64, Architecture.x64])
              CblitePackage._(
                binary: CbliteBinary.vectorSearchExtension,
                os: os,
                loader: loader,
                architectures: [architecture],
                archiveFormat: ArchiveFormat.zip,
              ),
          ],
        OS.iOS => [
            CblitePackage._(
              binary: CbliteBinary.vectorSearchExtension,
              os: os,
              loader: loader,
              iosSdk: IOSSdk.iPhoneOS,
              architectures: [Architecture.arm64],
              archiveFormat: ArchiveFormat.zip,
              isSingleArchitectureBundle: false,
            ),
            CblitePackage._(
              binary: CbliteBinary.vectorSearchExtension,
              os: os,
              loader: loader,
              iosSdk: IOSSdk.iPhoneSimulator,
              architectures: [Architecture.arm64, Architecture.x64],
              archiveFormat: ArchiveFormat.zip,
            ),
          ],
        OS.macOS => [
            CblitePackage._(
              binary: CbliteBinary.vectorSearchExtension,
              os: os,
              loader: loader,
              architectures: [Architecture.arm64, Architecture.x64],
              archiveFormat: ArchiveFormat.zip,
            ),
          ],
        OS.linux => [
            for (final architecture in [Architecture.arm64, Architecture.x64])
              CblitePackage._(
                binary: CbliteBinary.vectorSearchExtension,
                os: os,
                loader: loader,
                architectures: [architecture],
                archiveFormat: ArchiveFormat.zip,
              ),
          ],
        OS.windows => [
            for (final architecture in [Architecture.x64, Architecture.arm64])
              CblitePackage._(
                binary: CbliteBinary.vectorSearchExtension,
                os: os,
                loader: loader,
                architectures: [architecture],
                archiveFormat: ArchiveFormat.zip,
              ),
          ],
        _ => [],
      };

  final CbliteBinary binary;
  final OS os;
  final CbliteArchiveLoader loader;
  final IOSSdk? iosSdk;
  final List<Architecture> architectures;
  final ArchiveFormat archiveFormat;
  final bool isSingleArchitectureBundle;

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

    final archiveData = await loader.loadArchiveData(this, logger);
    await unpackArchive(
      archiveData,
      outputDirectory: archiveDirectoryUri,
      format: archiveFormat,
      logger: logger,
    );

    // Replace fat binary with an architecture specific binary, because
    // iOS native code assets are expected to be architecture specific.
    if (iosSdk == IOSSdk.iPhoneSimulator || os == OS.macOS) {
      await _thinLibrary(outputDirectoryUri, architecture);
    }
  }

  Future<void> installHeaders(Uri outputDirectoryUri, Logger logger) async {
    final tmpDirectory = Directory.systemTemp.createTempSync();

    try {
      final archiveData = await loader.loadArchiveData(this, logger);
      await unpackArchive(
        archiveData,
        outputDirectory: tmpDirectory.uri,
        format: archiveFormat,
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
      outputDirectoryUri.resolve(switch (binary) {
        CbliteBinary.databaseCommunity ||
        CbliteBinary.databaseEnterprise =>
          'CouchbaseLite/',
        CbliteBinary.vectorSearchExtension => 'CouchbaseLiteVectorSearch/',
      });

  Uri _resolveLibraryUriInArchive(
    Uri archiveDirectoryUri,
    Architecture architecture,
  ) {
    final version = loader.version;
    final fileNameVersion = version.split('.').first;

    final pathInArchive = switch (binary) {
      CbliteBinary.databaseCommunity ||
      CbliteBinary.databaseEnterprise =>
        switch (os) {
          OS.android =>
            'libcblite-$version/lib/${architecture.androidTriple}/libcblite.so',
          OS.iOS =>
            'CouchbaseLite.xcframework/${iosSdk!.iosFrameworkDirectory}/CouchbaseLite.framework/CouchbaseLite',
          OS.macOS => 'libcblite-$version/lib/libcblite.$fileNameVersion.dylib',
          OS.linux =>
            'libcblite-$version/lib/${architecture.linuxTripple}/libcblite.so.$fileNameVersion',
          OS.windows => 'libcblite-$version/bin/cblite.dll',
          _ => throw UnimplementedError(),
        },
      CbliteBinary.vectorSearchExtension => switch (os) {
          OS.android => 'lib/libCouchbaseLiteVectorSearch.so',
          OS.iOS =>
            'CouchbaseLiteVectorSearch.xcframework/${iosSdk!.iosFrameworkDirectory}/CouchbaseLiteVectorSearch.framework/CouchbaseLiteVectorSearch',
          OS.macOS => 'CouchbaseLiteVectorSearch.dylib',
          OS.linux => 'lib/CouchbaseLiteVectorSearch.so',
          OS.windows => 'bin/CouchbaseLiteVectorSearch.dll',
          _ => throw UnimplementedError(),
        },
    };

    return archiveDirectoryUri.resolve(pathInArchive);
  }

  Uri _resolveIncludeDirectoryUri(Uri archiveDirectory) => switch (os) {
        OS.macOS =>
          archiveDirectory.resolve('libcblite-${loader.version}/include/'),
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
