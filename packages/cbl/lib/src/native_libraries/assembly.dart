import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:path/path.dart' as p;

import 'artifact_resolution.dart';
import 'package.dart';
import 'utils.dart';

enum StageMode { copy, symlink }

String _lipoArchName(Architecture architecture) => switch (architecture) {
  Architecture.arm64 => 'arm64',
  Architecture.x64 => 'x86_64',
  _ => throw BuildError(
    message: 'Unsupported architecture for lipo: $architecture',
  ),
};

Future<Uri> stageCblite(
  ({Uri libPath, String includeDir}) cblite, {
  required String stagingDir,
  required OS targetOS,
  required Architecture targetArchitecture,
}) async {
  final libFile = cblite.libPath.toFilePath();

  switch (targetOS) {
    case OS.macOS:
      final outputFile = p.join(stagingDir, 'libcblite.dylib');
      final result = await Process.run('lipo', [
        libFile,
        '-thin',
        _lipoArchName(targetArchitecture),
        '-output',
        outputFile,
      ]);
      if (result.exitCode != 0) {
        throw BuildError(message: 'lipo failed: ${result.stderr}');
      }
      return Uri.file(outputFile);
    case OS.linux:
      final majorVersion = cbliteRelease.split('.').first;
      final sonameFile = p.join(stagingDir, 'libcblite.so.$majorVersion');
      await File(libFile).copy(sonameFile);
      await File(libFile).copy(p.join(stagingDir, 'libcblite.so'));
      return Uri.file(sonameFile);
    case OS.android:
      final dest = p.join(stagingDir, 'libcblite.so');
      await File(libFile).copy(dest);
      return Uri.file(dest);
    case OS.windows:
      final dllDest = p.join(stagingDir, 'cblite.dll');
      await File(libFile).copy(dllDest);
      final importLib = cblite.libPath
          .resolve('../lib/cblite.lib')
          .toFilePath();
      await File(importLib).copy(p.join(stagingDir, 'cblite.lib'));
      return Uri.file(dllDest);
    case OS.iOS:
      final dest = p.join(stagingDir, 'CouchbaseLite');
      final thinned = await lipoThin(
        cblite.libPath,
        targetArchitecture: targetArchitecture,
        outputDir: Uri.file(stagingDir),
      );
      if (thinned != cblite.libPath) {
        // lipoThin wrote to outputDir; rename to expected filename.
        await File(thinned.toFilePath()).rename(dest);
      } else {
        await File(libFile).copy(dest);
      }
      return Uri.file(dest);
    default:
      throw BuildError(message: 'Unsupported OS: $targetOS');
  }
}

Future<Uri> lipoThin(
  Uri libPath, {
  required Architecture targetArchitecture,
  required Uri outputDir,
}) async {
  final arch = _lipoArchName(targetArchitecture);
  final inputFile = libPath.toFilePath();
  final universal = await isUniversalBinary(inputFile);
  if (!universal) {
    return libPath;
  }

  final outputFile = p.join(outputDir.toFilePath(), p.basename(inputFile));
  final result = await Process.run('lipo', [
    inputFile,
    '-thin',
    arch,
    '-output',
    outputFile,
  ]);
  if (result.exitCode != 0) {
    throw BuildError(message: 'lipo failed: ${result.stderr}');
  }
  return Uri.file(outputFile);
}

Future<bool> isUniversalBinary(String path) async {
  final result = await Process.run('lipo', ['-info', path]);
  if (result.exitCode != 0) {
    return false;
  }
  return (result.stdout as String).contains('Architectures in the fat file');
}

Future<void> assembleCblite({
  required String outputDir,
  required Edition edition,
  required OS os,
  required Architecture architecture,
  required IOSSdk? iOSSdk,
  StageMode mode = StageMode.symlink,
}) async {
  final cblite = await downloadCblite(
    edition: edition,
    targetOS: os,
    targetArchitecture: architecture,
    targetIOSSdk: iOSSdk,
  );
  final libraryDir = Directory(p.join(outputDir, 'cblite'));
  await libraryDir.create(recursive: true);

  await assembleRuntimeAndSymbols(
    libraryFile: cblite.libraryFile.toFilePath(),
    targetDir: libraryDir.path,
    os: os,
    architecture: architecture,
    symbolsDir: cblite.symbolsDir,
    extraFiles: os == OS.windows
        ? [
            p.join(
              p.dirname(cblite.libraryFile.toFilePath()),
              '..',
              'lib',
              'cblite.lib',
            ),
          ]
        : const [],
    mode: mode,
  );
}

Future<void> assembleVectorSearch({
  required String outputDir,
  required OS os,
  required Architecture architecture,
  required IOSSdk? iOSSdk,
  StageMode mode = StageMode.symlink,
}) async {
  final package = await downloadVectorSearchPackage(
    targetOS: os,
    targetArchitecture: architecture,
  );
  final libraryDir = Directory(p.join(outputDir, 'vector_search'));
  await libraryDir.create(recursive: true);

  final libraryFile = findVectorSearchLibrary(
    package,
    os: os,
    architecture: architecture,
    targetIOSSdk: iOSSdk,
  );
  final symbolsDir = os == OS.iOS
      ? p.join(
          package.packageDir,
          'CouchbaseLiteVectorSearch.xcframework',
          iosSliceDir(iOSSdk!),
          'dSYMs',
        )
      : await downloadSymbolsArchive(
          library: Library.vectorSearch,
          edition: Edition.enterprise,
          os: os,
          architecture: architecture,
          release: vectorSearchRelease,
        );

  final extraFiles = <String>[];
  if (os == OS.windows) {
    final sourceDir = p.dirname(libraryFile.toFilePath());
    for (final entity in Directory(sourceDir).listSync()) {
      if (entity is File && entity.path.endsWith('.dll')) {
        extraFiles.add(entity.path);
      }
      if (entity is File && entity.path.endsWith('.lib')) {
        extraFiles.add(entity.path);
      }
      if (entity is File && entity.path.endsWith('.pdb')) {
        extraFiles.add(entity.path);
      }
    }
  }

  await assembleRuntimeAndSymbols(
    libraryFile: libraryFile.toFilePath(),
    targetDir: libraryDir.path,
    os: os,
    architecture: architecture,
    symbolsDir: symbolsDir,
    extraFiles: extraFiles,
    mode: mode,
  );
}

Future<void> assembleRuntimeAndSymbols({
  required String libraryFile,
  required String targetDir,
  required OS os,
  required Architecture architecture,
  required String? symbolsDir,
  required List<String> extraFiles,
  required StageMode mode,
}) async {
  await stageAssemblyLibraryFile(
    libraryFile: libraryFile,
    targetDir: targetDir,
    os: os,
    architecture: architecture,
    mode: mode,
  );

  for (final extraFile in extraFiles) {
    if (!File(extraFile).existsSync()) {
      continue;
    }
    await stagePath(
      source: extraFile,
      destination: p.join(targetDir, p.basename(extraFile)),
      mode: mode,
    );
  }

  if (symbolsDir == null) {
    return;
  }

  final dir = Directory(symbolsDir);
  if (dir.existsSync()) {
    for (final entity in dir.listSync()) {
      await stagePath(
        source: entity.path,
        destination: p.join(targetDir, p.basename(entity.path)),
        mode: mode,
      );
    }
    return;
  }

  final file = File(symbolsDir);
  if (file.existsSync()) {
    await stagePath(
      source: file.path,
      destination: p.join(targetDir, p.basename(file.path)),
      mode: mode,
    );
  }
}

Future<void> stageAssemblyLibraryFile({
  required String libraryFile,
  required String targetDir,
  required OS os,
  required Architecture architecture,
  required StageMode mode,
}) async {
  final destination = p.join(targetDir, p.basename(libraryFile));

  if (os == OS.macOS || os == OS.iOS) {
    final thinnedLibrary = await lipoThin(
      Uri.file(libraryFile),
      targetArchitecture: architecture,
      outputDir: Uri.file(targetDir),
    );
    final thinnedLibraryFile = thinnedLibrary.toFilePath();

    if (thinnedLibraryFile == destination) {
      return;
    }

    await stagePath(
      source: thinnedLibraryFile,
      destination: destination,
      mode: StageMode.copy,
    );
    return;
  }

  await stagePath(source: libraryFile, destination: destination, mode: mode);
}

Future<void> stagePath({
  required String source,
  required String destination,
  required StageMode mode,
}) async {
  final stat = FileStat.statSync(source);
  switch (stat.type) {
    case FileSystemEntityType.file:
      switch (mode) {
        case StageMode.copy:
          await File(source).copy(destination);
        case StageMode.symlink:
          await symlinkOrCopyFile(source, destination);
      }
    case FileSystemEntityType.directory:
      switch (mode) {
        case StageMode.copy:
          await copyDirectoryContents(
            source,
            destination,
            dereferenceLinks: true,
          );
        case StageMode.symlink:
          await symlinkOrCopyDirectory(source, destination);
      }
    case FileSystemEntityType.link:
      final resolvedSource = Link(source).resolveSymbolicLinksSync();
      await stagePath(
        source: resolvedSource,
        destination: destination,
        mode: mode,
      );
    case FileSystemEntityType.notFound:
    case FileSystemEntityType.pipe:
    case FileSystemEntityType.unixDomainSock:
      break;
  }
}
