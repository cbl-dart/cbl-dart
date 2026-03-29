import 'dart:io';

import 'package:cbl/src/native_libraries.dart' as native;
import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) async {
  await build(args, buildHook);
}

Future<void> buildHook(BuildInput input, BuildOutputBuilder output) async {
  final defaults = native.resolveNativeLibraryDefaultsFromUserDefines(
    input.userDefines,
  );
  final edition = defaults.editions.single;
  final vectorSearch = defaults.vectorSearch;

  final targetOS = input.config.code.targetOS;
  final targetArchitecture = input.config.code.targetArchitecture;

  final cblite = await native.downloadCblite(
    edition: edition,
    targetOS: targetOS,
    targetArchitecture: targetArchitecture,
    targetIOSSdk: targetOS == OS.iOS ? input.config.code.iOS.targetSdk : null,
  );

  const libDirName = 'lib';
  final libDir = p.join(input.outputDirectory.toFilePath(), libDirName);
  await Directory(libDir).create(recursive: true);

  final cbliteAssetPath = await native.stageCblite(
    (libPath: cblite.libraryFile, includeDir: cblite.includeDir),
    stagingDir: libDir,
    targetOS: targetOS,
    targetArchitecture: targetArchitecture,
  );

  output.assets.code.add(
    CodeAsset(
      package: 'cbl',
      name: 'src/bindings/cblite.dart',
      linkMode: DynamicLoadingBundled(),
      file: cbliteAssetPath,
    ),
  );

  final cblitedartCacheDir = await native.ensureCblitedartBuildCache(
    packageRoot: input.packageRoot,
    edition: edition,
    targetOS: targetOS,
    targetArchitecture: targetArchitecture,
    targetIOSSdk: targetOS == OS.iOS ? input.config.code.iOS.targetSdk : null,
  );

  final cblitedartBinary = native.findCblitedartBinary(cblitedartCacheDir);
  final cblitedartDest = p.join(libDir, p.basename(cblitedartBinary.path));
  await File(cblitedartBinary.path).copy(cblitedartDest);
  output.assets.code.add(
    CodeAsset(
      package: 'cbl',
      name: 'src/bindings/cblitedart.dart',
      linkMode: DynamicLoadingBundled(),
      file: Uri.file(cblitedartDest),
    ),
  );

  for (final entity in cblitedartCacheDir.listSync()) {
    if (p.basename(entity.path) == p.basename(cblitedartBinary.path)) {
      continue;
    }
    await native.stagePath(
      source: entity.path,
      destination: p.join(libDir, p.basename(entity.path)),
      mode: native.StageMode.copy,
    );
  }

  if (edition == native.Edition.enterprise &&
      vectorSearch &&
      native.vectorSearchSupported(targetArchitecture)) {
    final vectorSearchPackage = await native.downloadVectorSearchPackage(
      targetOS: targetOS,
      targetArchitecture: targetArchitecture,
    );

    var vectorSearchLib = native.findVectorSearchLibrary(
      vectorSearchPackage,
      os: targetOS,
      architecture: targetArchitecture,
      targetIOSSdk: targetOS == OS.iOS ? input.config.code.iOS.targetSdk : null,
    );

    if (targetOS == OS.macOS || targetOS == OS.iOS) {
      vectorSearchLib = await native.lipoThin(
        vectorSearchLib,
        targetArchitecture: targetArchitecture,
        outputDir: input.outputDirectory,
      );
    }

    final vsName = switch (targetOS) {
      OS.macOS => 'CouchbaseLiteVectorSearch.dylib',
      _ => p.basename(vectorSearchLib.toFilePath()),
    };
    final vsDest = p.join(libDir, vsName);
    await File(vectorSearchLib.toFilePath()).copy(vsDest);
    output.assets.code.add(
      CodeAsset(
        package: 'cbl',
        name: 'src/bindings/cblite_vector_search.dart',
        linkMode: DynamicLoadingBundled(),
        file: Uri.file(vsDest),
      ),
    );

    if (targetOS == OS.windows) {
      final vsSourceDir = p.dirname(vectorSearchLib.toFilePath());
      var depIndex = 0;
      for (final entity in Directory(vsSourceDir).listSync()) {
        if (entity is! File || !entity.path.endsWith('.dll')) {
          continue;
        }
        final name = p.basename(entity.path);
        if (name == p.basename(vectorSearchLib.toFilePath())) {
          continue;
        }

        final depDest = p.join(libDir, name);
        await entity.copy(depDest);
        output.assets.code.add(
          CodeAsset(
            package: 'cbl',
            name: 'src/bindings/vector_search_dep_$depIndex.dart',
            linkMode: DynamicLoadingBundled(),
            file: Uri.file(depDest),
          ),
        );
        depIndex++;
      }
    }
  }
}
