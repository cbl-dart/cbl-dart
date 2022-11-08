import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'utils.dart';

/// Runs the given [executable] with the given [arguments].
Future<void> execute(
  String executable, {
  List<String>? arguments,
  Duration? timeout,
}) async {
  logger.fine('Executing command: $executable ${arguments?.join(' ')}');

  var future = Process.run(
    executable,
    arguments ?? [],
    stderrEncoding: utf8,
    stdoutEncoding: utf8,
  );

  if (timeout != null) {
    future = future.timeout(timeout, onTimeout: () {
      final message = 'Command timed out after $timeout: '
          '$executable ${arguments?.join(' ')}';
      logger.fine(message);
      throw TimeoutException(message);
    });
  }

  final result = await future;

  if (result.exitCode != 0) {
    final message = 'Command failed: $executable ${arguments?.join(' ')} '
        '(${result.exitCode})\n'
        '${result.stdout}\n'
        '${result.stderr}';
    logger.fine(message);
    throw Exception(message);
  }

  logger.fine('Command finished: $executable ${arguments?.join(' ')}');
}

/// Downloads the contents of [url] into [outputFile].
Future<void> downloadFile(
  String url,
  String outputFile, {
  Duration timeout = const Duration(minutes: 5),
}) async {
  await execute(
    'curl',
    arguments: [
      '-L',
      '-o',
      outputFile,
      '-f',
      '--retry',
      '5',
      '--retry-max-time',
      '30',
      url
    ],
    timeout: const Duration(minutes: 5),
  );
}

/// Unpacks a zip or tar.gz [archiveFile] into [outputDir].
Future<void> unpackArchive(
  String archiveFile,
  String outputDir, {
  Duration timeout = const Duration(minutes: 5),
}) async {
  await Directory(outputDir).create(recursive: true);

  final extension = p.extension(archiveFile, 2);

  switch (extension) {
    case '.zip':
      if (Platform.isWindows) {
        await execute(
          'powershell',
          arguments: [
            '-NoProfile',
            '-NonInteractive',
            '-NoLogo',
            '-Command',
            // ignore: no_adjacent_strings_in_list
            'Expand-Archive '
                '-LiteralPath $archiveFile '
                '-DestinationPath $outputDir'
          ],
          timeout: timeout,
        );
      } else {
        await execute(
          'unzip',
          arguments: [archiveFile, '-d', outputDir],
          timeout: timeout,
        );
      }
      break;
    case '.tar.gz':
      await execute(
        'tar',
        arguments: ['-xzf', archiveFile, '-C', outputDir],
        timeout: timeout,
      );
      break;
    default:
      throw Exception('Unknown archive extension: $extension');
  }
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
