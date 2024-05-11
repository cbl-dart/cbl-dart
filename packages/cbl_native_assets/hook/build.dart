import 'package:cbl_native_assets/src/support/edition.dart';
import 'package:cbl_native_assets/src/version.dart';
import 'package:logging/logging.dart';
import 'package:native_assets_cli/native_assets_cli.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

import 'cblite_builder.dart';

const _edition = Edition.community;

final _logger = Logger('')
  ..level = Level.ALL
  // ignore: avoid_print
  ..onRecord.listen((record) => print(record.message));

void main(List<String> arguments) async {
  await build(arguments, (config, output) async {
    output.addDependencies([
      config.packageRoot.resolve('hook/build.dart'),
      config.packageRoot.resolve('lib/src/version.dart'),
    ]);

    const cbliteBuilder = CbliteBuilder(
      version: cbliteVersion,
      edition: _edition,
    );

    await cbliteBuilder.run(
      buildConfig: config,
      buildOutput: output,
      logger: _logger,
    );

    final cbliteLibraryUri = output.assets
        .whereType<NativeCodeAsset>()
        .map((asset) => asset.file)
        .singleOrNull;

    final cblitedartBuilder = CBuilder.library(
      name: 'cblitedart',
      assetName: 'src/bindings/cblitedart.dart',
      dartBuildFiles: ['hook/build.dart'],
      language: Language.cpp,
      std: 'c++17',
      cppLinkStdLib: config.targetOS == OS.android ? 'c++_static' : null,
      defines: {
        if (_edition == Edition.enterprise) 'COUCHBASE_ENTERPRISE': '1',
      },
      flags: [
        if (cbliteLibraryUri != null)
          ...switch (config.targetOS) {
            OS.iOS => [
                '-F${cbliteLibraryUri.resolve('../').toFilePath()}',
                '-framework',
                'CouchbaseLite',
              ],
            _ => [
                '-L${cbliteLibraryUri.resolve('./').toFilePath()}',
                '-lcblite',
              ]
          },
        if (config.targetOS == OS.iOS) '-miphoneos-version-min=12.0',
        if (config.targetOS == OS.android) ...['-lc++abi']
      ],
      includes: [
        'src/vendor/cblite/include',
        'src/vendor/dart/include',
        'src/cblitedart/include',
      ],
      sources: [
        'src/cblitedart/src/AsyncCallback.cpp',
        'src/cblitedart/src/CBL+Dart.cpp',
        'src/cblitedart/src/Fleece+Dart.cpp',
        'src/cblitedart/src/Sentry.cpp',
        'src/cblitedart/src/Utils.cpp',
        'src/vendor/dart/include/dart/dart_api_dl.c',
      ],
    );
    await cblitedartBuilder.run(
      buildConfig: config,
      buildOutput: output,
      logger: _logger,
    );
  });
}
