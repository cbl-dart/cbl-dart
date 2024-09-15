// ignore_for_file: avoid_catches_without_on_clauses

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';

/// Downloads the contents of [url] into memory.
Future<Uint8List> downloadUrl(
  Uri url, {
  Duration timeout = const Duration(minutes: 5),
  required Logger logger,
}) =>
    _retryWithExponentialBackoff(
      timeout: timeout,
      retryOn: (error) {
        if (error is Response) {
          return error.statusCode >= 500;
        }
        return false;
      },
      () async {
        logger.fine('Downloading $url ...');

        final response = await get(url);
        if (response.statusCode != 200) {
          logger.fine(
            'Download failed: $url (${response.statusCode})\n${response.body}',
          );
          // ignore: only_throw_errors
          throw response;
        }

        logger.fine('Downloaded $url');

        return response.bodyBytes;
      },
    );

Future<T> _retryWithExponentialBackoff<T>(
  Future<T> Function() fn, {
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
    }
    await Future<void>.delayed(delay * random.nextDouble());
    // ignore: parameter_assignments
    delay *= 2;
    attempt++;
  }
  throw Exception('Stopping to retry after $maxAttempts failed attempts.');
}

enum ArchiveFormat {
  zip,
  tarGz;

  String get ext {
    switch (this) {
      case ArchiveFormat.zip:
        return 'zip';
      case ArchiveFormat.tarGz:
        return 'tar.gz';
    }
  }
}

Future<void> unpackArchive(
  Uint8List archiveData, {
  required ArchiveFormat format,
  required Uri outputDirectory,
  required Logger logger,
}) async {
  logger.fine('Unpacking ${format.name} archive into $outputDirectory ...');

  await switch (format) {
    ArchiveFormat.zip => _unpackZipArchive(archiveData, outputDirectory),
    ArchiveFormat.tarGz => _unpackTarGzArchive(archiveData, outputDirectory),
  };
}

Future<void> _unpackZipArchive(Uint8List archiveData, Uri outputDir) async {
  final archive = ZipDecoder().decodeBytes(archiveData, verify: true);

  // TODO(blaugold): Remove once archive package has published a fix
  // Workaround for a bug in the archive package.
  // https://github.com/brendan-duncan/archive/pull/223
  for (final file in archive.files) {
    file.content;
  }

  await extractArchiveToDisk(archive, outputDir.toFilePath());
}

Future<void> _unpackTarGzArchive(
  Uint8List archiveData,
  Uri outputDir,
) async {
  final tarArchiveData = GZipDecoder().decodeBytes(archiveData, verify: true);
  final archive = TarDecoder().decodeBytes(tarArchiveData, verify: true);
  await extractArchiveToDisk(archive, outputDir.toFilePath());
}
