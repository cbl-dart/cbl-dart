import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' as p;

import 'package.dart';

String get homeDir {
  if (Platform.isMacOS || Platform.isLinux) {
    return Platform.environment['HOME']!;
  }

  if (Platform.isWindows) {
    return Platform.environment['USERPROFILE']!;
  }

  throw UnsupportedError('Unsupported platform.');
}

String get userCachesDir {
  if (Platform.isMacOS) {
    return p.join(homeDir, 'Library', 'Caches');
  }

  if (Platform.isLinux) {
    return p.join(homeDir, '.cache');
  }

  if (Platform.isWindows) {
    return p.join(homeDir, 'AppData', 'Local');
  }

  throw UnsupportedError('Unsupported platform.');
}

/// The root of the CBL Dart project, if the current working directory is inside
/// the CBL Dart project.
final _cblDartProjectRoot = () {
  const repoName = 'cbl-dart';
  final currentPath = Directory.current.path;
  final repoNameIndex = currentPath.lastIndexOf(repoName);
  if (repoNameIndex == -1) {
    return null;
  }

  return currentPath.substring(0, repoNameIndex + repoName.length);
}();

/// The native vendor directory, if the current working directory is inside the
/// CBL Dart project.
final _nativeVendorDirectory = _cblDartProjectRoot != null
    ? p.join(_cblDartProjectRoot!, 'native', 'vendor')
    : null;

/// Tries to load the file at [uri] from the native vendor directory.
///
/// The file is expected to be in the native vendor directory, in a directory
/// named after the host of the URI, and in a subdirectory named after the path
/// of the URI.
Future<Uint8List?> _loadFileFromNativeVendorDirectory(Uri uri) async {
  final nativeVendorDirectory = _nativeVendorDirectory;
  if (nativeVendorDirectory == null) {
    return null;
  }

  final localUri = uri.replace(
    scheme: 'file',
    host: '',
    pathSegments: [
      ...p.split(nativeVendorDirectory).sublist(1),
      uri.host,
      ...uri.pathSegments,
    ],
  );

  final localFile = File.fromUri(localUri);
  if (localFile.existsSync()) {
    return localFile.readAsBytes();
  }

  return null;
}

/// Downloads the contents of [url] into memory.
Future<Uint8List> downloadUrl(
  String url, {
  Duration timeout = const Duration(minutes: 5),
}) => _retryWithExponentialBackoff(
  timeout: timeout,
  retryOn: (error) {
    if (error is Response) {
      return error.statusCode >= 500;
    }
    return false;
  },
  () async {
    final uri = Uri.parse(url);
    final response = await get(uri);

    if (response.statusCode case 404 || 403) {
      if (await _loadFileFromNativeVendorDirectory(uri) case final data?) {
        return data;
      }
    }

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to download $url: ${response.statusCode} ${response.body}',
      );
    }

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

Future<void> unpackArchive(
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

  // TODO(blaugold): Remove once archive package has published a fix
  // Workaround for a bug in the archive package.
  // https://github.com/brendan-duncan/archive/pull/223
  for (final file in archive.files) {
    file.content;
  }

  await _extractArchiveWithLinks(archive, outputDir);
}

Future<void> _unpackTarGzArchive(
  Uint8List archiveData,
  String outputDir,
) async {
  // Don't use const constructor to allow for backwards compatibility with
  // older version of the archive package.
  // ignore: prefer_const_constructors
  final tarArchiveData = GZipDecoder().decodeBytes(archiveData, verify: true);
  final archive = TarDecoder().decodeBytes(tarArchiveData, verify: true);
  await _extractArchiveWithLinks(archive, outputDir);
}

// archive 4.5 rejects links through other links, including the standard
// Binary -> Versions/Current/Binary, Versions/Current -> A framework layout.
// Extract files first so none can be written through an archive-created link.
Future<void> _extractArchiveWithLinks(Archive archive, String outputDir) async {
  final files = Archive();
  final links = <ArchiveFile>[];
  for (final entry in archive) {
    if (entry.isSymbolicLink) {
      links.add(entry);
    } else {
      files.addFile(entry);
    }
  }
  await extractArchiveToDisk(files, outputDir);

  final root = await Directory(outputDir).resolveSymbolicLinks();
  // Resolve chains in dependency order, independently of archive entry order.
  // Unresolvable (including dangling and cyclic) links are left out.
  var remaining = links;
  while (remaining.isNotEmpty) {
    final deferred = <ArchiveFile>[];
    for (final entry in remaining) {
      final target = entry.symbolicLink!;
      final linkPath = p.normalize(p.join(root, entry.name));
      if (p.isAbsolute(entry.name) ||
          p.isAbsolute(target) ||
          !p.isWithin(root, linkPath) ||
          !p.isWithin(root, p.normalize(p.join(p.dirname(linkPath), target))) ||
          FileSystemEntity.typeSync(linkPath, followLinks: false) !=
              FileSystemEntityType.notFound) {
        continue;
      }

      // A link's own parent must not traverse a link. Never create directories
      // through an existing link, even if its final destination is inside root.
      var parent = p.dirname(linkPath);
      var parentIsLink = false;
      while (parent != root) {
        if (FileSystemEntity.isLinkSync(parent)) {
          parentIsLink = true;
          break;
        }
        parent = p.dirname(parent);
      }
      if (parentIsLink) {
        continue;
      }

      await Directory(p.dirname(linkPath)).create(recursive: true);
      final targetPath = p.join(p.dirname(linkPath), target);
      final String resolvedTarget;
      try {
        resolvedTarget = await File(targetPath).resolveSymbolicLinks();
      } on FileSystemException {
        deferred.add(entry);
        continue;
      }
      if (!p.isWithin(root, resolvedTarget)) {
        continue;
      }
      await Link(linkPath).create(target, recursive: true);
    }
    if (deferred.length == remaining.length) {
      break;
    }
    remaining = deferred;
  }
}

/// Copies [sourceDir] to [destinationDir].
Future<void> copyDirectoryContents(
  String sourceDir,
  String destinationDir, {
  bool dereferenceLinks = false,
  bool Function(FileSystemEntity)? filter,
}) async {
  final sourceDirPath = p.absolute(sourceDir);
  final destinationDirPath = p.absolute(destinationDir);
  await Directory(destinationDirPath).create(recursive: true);

  final entities = Directory(
    sourceDirPath,
  ).list(recursive: true, followLinks: false);

  await for (final entity in entities) {
    if (!(filter?.call(entity) ?? true)) {
      continue;
    }

    final relativePath = p.relative(entity.path, from: sourceDirPath);
    final destPath = p.join(destinationDirPath, relativePath);

    if (entity is Link) {
      if (dereferenceLinks) {
        await File(destPath).create(recursive: true);
        await File(entity.resolveSymbolicLinksSync()).copy(destPath);
      } else {
        try {
          await Link(destPath).create(await entity.target());
        } on PathExistsException {
          // Links can't be overwritten on some platforms.
          await Link(destPath).delete();
          await Link(destPath).create(await entity.target());
        }
      }
    } else if (entity is File) {
      await entity.copy(destPath);
    } else if (entity is Directory) {
      await Directory(destPath).create(recursive: true);
    }
  }
}

Future<void> moveDirectory(Directory from, Directory to) async {
  await to.parent.create(recursive: true);
  await from.rename(to.path);
}
