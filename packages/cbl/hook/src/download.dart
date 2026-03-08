import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' as p;

// === Enums ===================================================================

enum Library {
  cblite,
  vectorSearch;

  String libraryName(OS os) => switch (this) {
    cblite => switch (os) {
      OS.linux || OS.android || OS.macOS => 'libcblite',
      OS.windows => 'cblite',
      OS.iOS => 'CouchbaseLite',
    },
    vectorSearch => switch (os) {
      OS.android => 'libCouchbaseLiteVectorSearch',
      OS.linux ||
      OS.windows ||
      OS.macOS ||
      OS.iOS => 'CouchbaseLiteVectorSearch',
    },
  };
}

enum Edition { community, enterprise }

enum ArchiveFormat {
  zip,
  tarGz;

  String get extension => switch (this) {
    zip => 'zip',
    tarGz => 'tar.gz',
  };
}

enum OS { android, iOS, macOS, linux, windows }

enum Architecture {
  ia32,
  x64,
  arm,
  arm64;

  String get couchbaseSdkName => switch (this) {
    arm => 'arm',
    arm64 => 'arm64',
    ia32 => 'i686',
    x64 => 'x86_64',
  };
}

// === Package Config ==========================================================

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
      ? os._couchbaseSdkName
      : '${os._couchbaseSdkName}-${architectures.single.couchbaseSdkName}';

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

  String get rootDir {
    final rootDirName = switch (config.library) {
      Library.cblite => 'libcblite-${config.version}',
      Library.vectorSearch => null,
    };
    return rootDirName != null ? p.join(packageDir, rootDirName) : packageDir;
  }

  String get libraryName => config.library.libraryName(config.os);

  String? get sharedLibrariesDir {
    final dir = switch (config.library) {
      Library.cblite => switch (config.os) {
        OS.android => p.join('lib', config.architectures.first._androidTriple),
        OS.macOS => 'lib',
        OS.linux => p.join('lib', config.architectures.first._linuxTriple),
        OS.windows => 'bin',
        OS.iOS => null,
      },
      Library.vectorSearch => switch (config.os) {
        OS.linux || OS.android => 'lib',
        OS.windows => 'bin',
        OS.macOS => '.',
        OS.iOS => null,
      },
    };
    return dir != null ? p.join(rootDir, dir) : null;
  }
}

// === Package Configs =========================================================

final class DatabasePackageConfig extends PackageConfig {
  DatabasePackageConfig({
    required super.os,
    required super.architectures,
    required super.release,
    required super.archiveFormat,
    required this.edition,
  }) : super(library: Library.cblite);

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
  }) : super(library: Library.vectorSearch, archiveFormat: ArchiveFormat.zip);

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
          os._couchbaseSdkName,
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
}

// === Package Loader ==========================================================

final class RemotePackageLoader {
  RemotePackageLoader({required this.cacheDir});

  final String cacheDir;

  Future<Package> load(PackageConfig config) async {
    final packageDir = await _packageDir(config);
    return config._package(packageDir);
  }

  Future<String> _packageDir(PackageConfig config) async {
    final archiveBaseName = p.basenameWithoutExtension(
      Uri.parse(config._archiveUrl).path,
    );

    final packageDir = p.join(cacheDir, archiveBaseName);

    final packageDirectory = Directory(packageDir);
    if (packageDirectory.existsSync()) {
      return packageDir;
    }

    final cacheTempDir = Directory(p.join(cacheDir, '.temp'));
    await cacheTempDir.create(recursive: true);

    final tempDirectory = await cacheTempDir.createTemp();
    try {
      final archiveData = await _downloadUrl(config._archiveUrl);
      await _unpackArchive(
        archiveData,
        format: config.archiveFormat,
        outputDir: tempDirectory.path,
      );
      await config._postProcess(tempDirectory.path);
      try {
        await tempDirectory.rename(packageDirectory.path);
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

// === Download Utilities ======================================================

Future<Uint8List> _downloadUrl(
  String url, {
  Duration timeout = const Duration(minutes: 5),
}) => _retryWithExponentialBackoff(
  operation: 'download $url',
  timeout: timeout,
  retryOn: (error) =>
      (error is HttpException && error.statusCode >= 500) ||
      error is SocketException ||
      error is ClientException,
  () async {
    final response = await get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw HttpException(
        'Failed to download $url: ${response.statusCode} ${response.body}',
        response.statusCode,
      );
    }

    return response.bodyBytes;
  },
);

Future<T> _retryWithExponentialBackoff<T>(
  Future<T> Function() fn, {
  required String operation,
  Duration delay = const Duration(seconds: 1),
  int maxAttempts = 5,
  Duration timeout = const Duration(minutes: 5),
  required bool Function(Object error) retryOn,
}) async {
  final start = DateTime.now();
  final random = Random();
  var attempt = 0;
  while (attempt < maxAttempts) {
    final now = DateTime.now();
    final duration = now.difference(start);
    if (duration > timeout) {
      throw TimeoutException(null, duration);
    }

    try {
      return await fn();
    } catch (e) {
      if (!retryOn(e)) {
        rethrow;
      }
      // ignore: avoid_print
      print('Retry ${attempt + 1}/$maxAttempts for $operation after error: $e');
    }
    await Future<void>.delayed(delay * random.nextDouble());
    // ignore: parameter_assignments
    delay *= 2;
    attempt++;
  }
  throw Exception(
    'Stopping to retry after $maxAttempts failed attempts for $operation.',
  );
}

Future<void> _unpackArchive(
  Uint8List archiveData, {
  required ArchiveFormat format,
  required String outputDir,
}) async {
  await switch (format) {
    ArchiveFormat.zip => _unpackZipArchive(archiveData, outputDir),
    ArchiveFormat.tarGz => _unpackTarGzArchive(archiveData, outputDir),
  };
}

Future<void> _unpackZipArchive(Uint8List archiveData, String outputDir) async {
  final archive = ZipDecoder().decodeBytes(archiveData, verify: true);
  for (final file in archive.files) {
    // Access content to force decompression before extracting to disk.
    file.content;
  }
  await extractArchiveToDisk(archive, outputDir);
}

Future<void> _unpackTarGzArchive(
  Uint8List archiveData,
  String outputDir,
) async {
  // ignore: prefer_const_constructors
  final tarArchiveData = GZipDecoder().decodeBytes(archiveData, verify: true);
  final archive = TarDecoder().decodeBytes(tarArchiveData, verify: true);
  await extractArchiveToDisk(archive, outputDir);
}

// === Extensions ==============================================================

extension on OS {
  String get _couchbaseSdkName => switch (this) {
    OS.android => 'android',
    OS.iOS => 'ios',
    OS.linux => 'linux',
    OS.macOS => 'macos',
    OS.windows => 'windows',
  };
}

final class HttpException implements Exception {
  HttpException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

extension on Architecture {
  String get _androidTriple => switch (this) {
    Architecture.arm => 'arm-linux-androideabi',
    Architecture.arm64 => 'aarch64-linux-android',
    Architecture.ia32 => 'i686-linux-android',
    Architecture.x64 => 'x86_64-linux-android',
  };

  String get _linuxTriple => switch (this) {
    Architecture.arm => 'arm-linux-gnu',
    Architecture.arm64 => 'aarch64-linux-gnu',
    Architecture.ia32 => 'i686-linux-gnu',
    Architecture.x64 => 'x86_64-linux-gnu',
  };
}
