// ignore_for_file: avoid_catches_without_on_clauses

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' as p;

import 'package.dart';
import 'utils.dart';

/// Downloads the contents of [url] into memory.
Future<Uint8List> downloadUrl(
  String url, {
  Duration timeout = const Duration(minutes: 5),
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

        final response = await get(Uri.parse(url));
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

void unpackArchive(
  Uint8List archiveData, {
  required ArchiveFormat format,
  required String outputDir,
}) {
  logger.fine('Unpacking ${format.name} archive into $outputDir ...');

  switch (format) {
    case ArchiveFormat.zip:
      _unpackZipArchive(archiveData, outputDir);
      break;
    case ArchiveFormat.tarGz:
      _unpackTarGzArchive(archiveData, outputDir);
      break;
  }
}

void _unpackZipArchive(Uint8List archiveData, String outputDir) {
  final archive = ZipDecoder().decodeBytes(archiveData, verify: true);

  // TODO(blaugold): Remove once archive package has published a fix
  // Workaround for a bug in the archive package.
  // https://github.com/brendan-duncan/archive/pull/223
  for (final file in archive.files) {
    file.content;
  }

  extractArchiveToDisk(archive, outputDir);
}

void _unpackTarGzArchive(Uint8List archiveData, String outputDir) {
  final tarArchiveData = GZipDecoder().decodeBytes(archiveData, verify: true);
  final archive = TarDecoder().decodeBytes(tarArchiveData, verify: true);
  extractArchiveToDisk(archive, outputDir);
}

/// Copies the contents of [sourceDir] to [destinationDir].
Future<void> copyDirectoryContents(
  String sourceDir,
  String destinationDir, {
  bool Function(FileSystemEntity)? filter,
}) async {
  logger.fine('Copying directory contents: $sourceDir -> $destinationDir');

  final sourceDirPath = p.absolute(sourceDir);
  final destinationDirPath = p.absolute(destinationDir);

  final entities = Directory(sourceDirPath).list(
    recursive: true,
    followLinks: false,
  );

  await for (final entity in entities) {
    if (!(filter?.call(entity) ?? true)) {
      continue;
    }

    final relativePath = p.relative(entity.path, from: sourceDirPath);
    final destPath = p.join(destinationDirPath, relativePath);

    if (entity is Link) {
      await Link(destPath).create(await entity.target());
    } else if (entity is File) {
      await entity.copy(destPath);
    } else if (entity is Directory) {
      await Directory(destPath).create(recursive: true);
    }
  }
}
