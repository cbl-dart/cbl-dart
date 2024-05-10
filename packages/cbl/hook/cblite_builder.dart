import 'package:logging/logging.dart';
import 'package:native_assets_cli/native_assets_cli.dart';

import 'cblite_package.dart';

class CbliteBuilder {
  const CbliteBuilder({required this.version, required this.edition});

  final String version;
  final CbliteEdition edition;

  Future<void> run({
    required BuildConfig buildConfig,
    required BuildOutput buildOutput,
    required Logger logger,
  }) async {
    final packages = CblitePackage.forOS(
      buildConfig.targetOS,
      version: version,
      edition: edition,
    );
    final assetPackages = buildConfig.dryRun
        ? packages
        : packages
            .where((package) => package.matchesBuildConfig(buildConfig))
            .toList();

    if (!buildConfig.dryRun) {
      await assetPackages.single.installPackage(
        buildConfig.outputDirectory,
        buildConfig.targetArchitecture!,
        logger,
      );
    }

    buildOutput
      ..addDependencies([
        buildConfig.packageRoot.resolve('hook/sdk_builder.dart'),
        buildConfig.packageRoot.resolve('hook/sdk_package.dart'),
        buildConfig.packageRoot.resolve('hook/tools.dart'),
        buildConfig.packageRoot.resolve('hook/utils.dart'),
      ])
      ..addAssets([
        for (final package in assetPackages)
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
              )
      ]);
  }
}
