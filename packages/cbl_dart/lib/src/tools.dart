import 'dart:io';

import 'package:path/path.dart' as p;

/// Runs the given [executable] with the given [arguments].
Future<void> execute(String executable, [List<String>? arguments]) async {
  final result = await Process.run(executable, arguments ?? []);

  if (result.exitCode != 0) {
    throw Exception(
      'Command failed: $executable ${arguments?.join(' ')}\n'
      '${result.stdout}\n'
      '${result.stderr}',
    );
  }
}

/// Downloads the contents of [url] into [outputFile].
Future<void> downloadFile(String url, String outputFile) => execute(
      'curl',
      [
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
    );

/// Unpacks a zip or tar.gz [archiveFile] into [outputDir].
Future<void> unpackArchive(String archiveFile, String outputDir) async {
  await Directory(outputDir).create(recursive: true);
  return execute('tar', ['-xf', archiveFile, '-C', outputDir]);
}

/// Copies the contents of [sourceDir] to [destinationDir].
Future<void> copyDirectoryContents(
  String sourceDir,
  String destinationDir, {
  bool Function(FileSystemEntity)? filter,
}) async {
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
