import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:path/path.dart' as p;

import 'artifact_resolution.dart';
import 'assembly.dart';
import 'package.dart';
import 'utils.dart';

String get localBuildCacheDir =>
    p.join(nativeLibrariesCacheDir, 'local_builds');

Future<void> buildCblitedartAsset({
  required BuildInput input,
  required BuildOutputBuilder output,
  required String cbliteIncludeDir,
  String? cbliteFrameworkSearchPath,
  required Edition edition,
}) async {
  final targetOS = input.config.code.targetOS;
  final builder = CBuilder.library(
    name: 'cblitedart',
    assetName: 'src/bindings/cblitedart.dart',
    sources: [
      'native/couchbase-lite-dart/src/CBL+Dart.cpp',
      'native/couchbase-lite-dart/src/Fleece+Dart.cpp',
      'native/couchbase-lite-dart/src/AsyncCallback.cpp',
      'native/couchbase-lite-dart/src/Utils.cpp',
      'native/couchbase-lite-dart/src/CpuSupport.cpp',
      'native/couchbase-lite-dart/src/dart_api_dl.cpp',
    ],
    includes: [
      'native/vendor/dart/include',
      'native/couchbase-lite-dart/include',
    ],
    libraries: [if (targetOS != OS.iOS) 'cblite'],
    libraryDirectories: [if (targetOS != OS.iOS) 'lib'],
    flags: [
      if (targetOS != OS.windows) '-fvisibility=hidden',
      '-I$cbliteIncludeDir',
      if (targetOS == OS.iOS) ...[
        '-F${cbliteFrameworkSearchPath!}',
        '-framework',
        'CouchbaseLite',
      ],
    ],
    defines: {if (edition == Edition.enterprise) 'COUCHBASE_ENTERPRISE': '1'},
    language: Language.cpp,
    std: 'c++17',
    cppLinkStdLib: targetOS == OS.android ? 'c++_static' : null,
  );
  await builder.run(input: input, output: output);
}

Future<Directory> ensureCblitedartBuildCache({
  required Uri packageRoot,
  required Edition edition,
  required OS targetOS,
  required Architecture targetArchitecture,
  required IOSSdk? targetIOSSdk,
}) async {
  final cachePathSegments = [
    localBuildCacheDir,
    'cblitedart',
    edition.name,
    targetOS.name,
    targetArchitecture.name,
    if (targetIOSSdk != null) targetIOSSdk.type,
  ];
  final cacheDir = Directory(p.joinAll(cachePathSegments));

  if (containsCblitedartArtifact(cacheDir)) {
    return cacheDir;
  }

  final buildTempRoot = Directory(p.join(localBuildCacheDir, '.temp'));
  await buildTempRoot.create(recursive: true);
  final tempDir = await buildTempRoot.createTemp();
  try {
    final tempUri = tempDir.uri.normalizePath();
    final outputDirectoryShared = tempUri.resolve('output_shared/');
    final outputFile = tempUri.resolve('output.json');
    await Directory.fromUri(outputDirectoryShared).create(recursive: true);

    final inputBuilder = BuildInputBuilder()
      ..setupShared(
        packageRoot: packageRoot,
        packageName: 'cbl',
        outputFile: outputFile,
        outputDirectoryShared: outputDirectoryShared,
        userDefines: PackageUserDefines(
          workspacePubspec: PackageUserDefinesSource(
            defines: {'edition': edition.name},
            basePath: packageRoot,
          ),
        ),
      )
      ..setupBuildInput()
      ..config.setupBuild(linkingEnabled: false);

    CodeAssetExtension(
      linkModePreference: LinkModePreference.dynamic,
      targetArchitecture: targetArchitecture,
      targetOS: targetOS,
      iOS: targetOS == OS.iOS
          ? IOSCodeConfig(
              targetSdk: targetIOSSdk ?? IOSSdk.iPhoneOS,
              targetVersion: 17,
            )
          : null,
      macOS: targetOS == OS.macOS ? MacOSCodeConfig(targetVersion: 13) : null,
      android: targetOS == OS.android
          ? AndroidCodeConfig(targetNdkApi: 30)
          : null,
    ).setupBuildInput(inputBuilder);

    final input = inputBuilder.build();
    final output = BuildOutputBuilder();

    final cblite = await downloadCblite(
      edition: edition,
      targetOS: targetOS,
      targetArchitecture: targetArchitecture,
      targetIOSSdk: targetIOSSdk,
    );

    final libDir = p.join(input.outputDirectory.toFilePath(), 'lib');
    await Directory(libDir).create(recursive: true);
    await stageCblite(
      (libPath: cblite.libraryFile, includeDir: cblite.includeDir),
      stagingDir: libDir,
      targetOS: targetOS,
      targetArchitecture: targetArchitecture,
    );
    await buildCblitedartAsset(
      input: input,
      output: output,
      cbliteIncludeDir: cblite.includeDir,
      cbliteFrameworkSearchPath: cblite.frameworkSearchPath,
      edition: edition,
    );

    final cblitedartAsset = output.build().assets.code.singleWhere(
      (asset) => asset.id == 'package:cbl/src/bindings/cblitedart.dart',
    );
    final binaryFile = File.fromUri(cblitedartAsset.file!);

    if (cacheDir.existsSync()) {
      await cacheDir.delete(recursive: true);
    }
    await cacheDir.create(recursive: true);
    await binaryFile.copy(p.join(cacheDir.path, p.basename(binaryFile.path)));

    for (final companion in findDebugCompanions(binaryFile)) {
      final destination = p.join(cacheDir.path, p.basename(companion.path));
      if (companion is Directory) {
        await copyDirectoryContents(
          companion.path,
          destination,
          dereferenceLinks: true,
        );
      } else if (companion is File) {
        await companion.copy(destination);
      }
    }
  } finally {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  }

  return cacheDir;
}

bool containsCblitedartArtifact(Directory dir) {
  if (!dir.existsSync()) {
    return false;
  }
  return dir.listSync().any((entity) {
    final name = p.basename(entity.path);
    final exists =
        File(entity.path).existsSync() || Directory(entity.path).existsSync();
    return name.contains('cblitedart') &&
        exists &&
        (name.endsWith('.so') ||
            name.endsWith('.dylib') ||
            name.endsWith('.dll'));
  });
}

FileSystemEntity findCblitedartBinary(Directory cacheDir) =>
    cacheDir.listSync().firstWhere(
      (entity) =>
          entity is! Directory &&
          entity.path.contains('cblitedart') &&
          (entity.path.endsWith('.so') ||
              entity.path.endsWith('.dylib') ||
              entity.path.endsWith('.dll')),
    );

Iterable<FileSystemEntity> findDebugCompanions(File binaryFile) sync* {
  final dir = binaryFile.parent;
  final baseName = p.basenameWithoutExtension(binaryFile.path);
  for (final entity in dir.listSync()) {
    final name = p.basename(entity.path);
    if (name == p.basename(binaryFile.path)) {
      continue;
    }
    if (entity is File && name.startsWith(baseName)) {
      yield entity;
    }
    if (entity is Directory &&
        name.contains(baseName) &&
        name.endsWith('.dSYM')) {
      yield entity;
    }
  }
}
