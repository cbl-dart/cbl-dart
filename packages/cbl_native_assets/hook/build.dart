import 'dart:io';

import 'package:cbl/src/install.dart' as cbl;
import 'package:cbl/src/install.dart' hide OS, Architecture;
import 'package:native_assets_cli/code_assets.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) {
  build(args, (config, output) async {
    final packageConfigs = DatabasePackageConfig.all(
      releases: {
        Library.cblite: '3.2.1',
        Library.cblitedart: '8.0.0',
      },
      edition: Edition.enterprise,
    );

    final targetOS = config.targetOS;
    final targetArchitecture =
        config.dryRun ? null : config.codeConfig.targetArchitecture;
    final targetPackageConfigs = packageConfigs
        .where((config) =>
            config.os.codeAssetsOS == targetOS &&
            (targetArchitecture == null ||
                config.architectures
                    .map((e) => e.codeAssetsArchitecture)
                    .contains(targetArchitecture)))
        .toList();

    if (targetPackageConfigs.isEmpty) {
      throw StateError('$targetOS on $targetArchitecture is not supported');
    }

    final loader = cbl.RemotePackageLoader();

    const dartLibrary = {
      Library.cblite: 'src/cblite.dart',
      Library.cblitedart: 'src/cblitedart.dart',
    };

    for (final packageConfig in targetPackageConfigs) {
      final package = await loader.load(packageConfig);

      final majorVersion = package.config.version.split('.').first;

      var libraryName = package.library.name;
      if (targetOS == OS.macOS && package.library == Library.cblite) {
        libraryName += '.$majorVersion';
      }

      libraryName =
          targetOS.libraryFileName(libraryName, DynamicLoadingBundled());

      if (targetOS == OS.linux && package.library == Library.cblite) {
        libraryName += '.$majorVersion';
      }

      final outputLibraryFile = File(p.join(
        config.outputDirectory.toFilePath(),
        libraryName,
      ));

      if (targetArchitecture != null) {
        final libraryPath = p.join(
          package.sharedLibrariesDir(targetArchitecture.cblArchitecture)!,
          libraryName,
        );

        final libraryFile = File(libraryPath);

        if (targetOS == OS.macOS) {
          // Strip the fat binary to only contain the target architecture.
          final result = await Process.run('lipo', [
            libraryFile.path,
            '-thin',
            if (targetArchitecture == Architecture.arm64) 'arm64' else 'x86_64',
            '-output',
            outputLibraryFile.path,
          ]);
          if (result.exitCode != 0) {
            throw StateError(
              'Failed to strip fat binary (${result.exitCode}):\n'
              '${result.stdout}\n'
              '${result.stderr}',
            );
          }
        } else {
          await libraryFile.copy(outputLibraryFile.path);
        }
      }

      output.codeAssets.add(CodeAsset(
        package: 'cbl_native_assets',
        name: dartLibrary[package.library]!,
        linkMode: DynamicLoadingBundled(),
        os: targetOS,
        architecture: targetArchitecture,
        file: outputLibraryFile.uri,
      ));
    }
  });
}

extension on cbl.OS {
  OS get codeAssetsOS => switch (this) {
        cbl.OS.android => OS.android,
        cbl.OS.iOS => OS.iOS,
        cbl.OS.linux => OS.linux,
        cbl.OS.macOS => OS.macOS,
        cbl.OS.windows => OS.windows
      };
}

extension on cbl.Architecture {
  Architecture get codeAssetsArchitecture => switch (this) {
        cbl.Architecture.arm => Architecture.arm,
        cbl.Architecture.arm64 => Architecture.arm64,
        cbl.Architecture.ia32 => Architecture.ia32,
        cbl.Architecture.x64 => Architecture.x64
      };
}

extension on Architecture {
  cbl.Architecture get cblArchitecture => cbl.Architecture.values
      .firstWhere((e) => e.codeAssetsArchitecture == this);
}
