import 'package:cbl/src/support/edition.dart';
import 'package:logging/logging.dart';
import 'package:native_assets_cli/native_assets_cli.dart';

import 'cblite_package.dart';

class CbliteBuilder {
  const CbliteBuilder({
    required this.edition,
    required this.databaseArchiveLoader,
  });

  final Edition edition;
  final CbliteArchiveLoader databaseArchiveLoader;

  Future<void> run({
    required BuildConfig buildConfig,
    required BuildOutput buildOutput,
    required Logger logger,
  }) async {
    final databasePackages = CblitePackage.database(
      edition: edition,
      os: buildConfig.targetOS,
      loader: databaseArchiveLoader,
    );

    final databaseAssetPackages = buildConfig.dryRun
        ? databasePackages
        : databasePackages
            .where((package) => package.matchesBuildConfig(buildConfig))
            .toList();

    if (!buildConfig.dryRun) {
      await databaseAssetPackages.single.installPackage(
        buildConfig.outputDirectory,
        buildConfig.targetArchitecture!,
        logger,
      );
    }

    buildOutput.addAssets([
      for (final package in databaseAssetPackages)
        for (final architecture in package.architectures)
          if (buildConfig.dryRun ||
              architecture == buildConfig.targetArchitecture!)
            NativeCodeAsset(
              package: buildConfig.packageName,
              name: 'src/bindings/cblite.dart',
              linkMode: DynamicLoadingBundled(),
              os: buildConfig.targetOS,
              architecture: architecture,
              file: package.resolveLibraryUri(
                buildConfig.outputDirectory,
                architecture,
              ),
            ),
    ]);
  }
}
