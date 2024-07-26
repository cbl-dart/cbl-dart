import 'package:cbl_native_assets/src/support/edition.dart';
import 'package:logging/logging.dart';
import 'package:native_assets_cli/native_assets_cli.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

import 'cblite_builder.dart';
import 'cblite_package.dart';

const remoteDatabaseArchiveLoader =
    RemoteDatabaseArchiveLoader(version: '3.1.6');

final localDatabaseArchiveLoader = LocalDatabaseArchiveLoader(
  archiveDirectoryUri:
      Uri.file('/Users/terwesten/Downloads/couchbase-lite-c-3.2.0-RC2'),
  build: 63,
  version: '3.2.0',
);

final localVectorSearchArchiveLoader = LocalVectorSearchArchiveLoader(
  archiveDirectoryUri: Uri.file(
    '/Users/terwesten/Downloads/couchbase-lite-vector-search-1.0.0-RC2',
  ),
  build: 58,
  version: '1.0.0',
);

// TODO(blaugold): make build time options configurable
const _edition = Edition.enterprise;
const _vectorSearch = _edition == Edition.enterprise;
final _databaseArchiveLoader = localDatabaseArchiveLoader;
final _vectorSearchArchiveLoader =
    _vectorSearch ? localVectorSearchArchiveLoader : null;

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

    final cbliteBuilder = CbliteBuilder(
      edition: _edition,
      databaseArchiveLoader: _databaseArchiveLoader,
      vectorSearchArchiveLoader: _vectorSearchArchiveLoader,
    );

    await cbliteBuilder.run(
      buildConfig: config,
      buildOutput: output,
      logger: _logger,
    );

    final cbliteLibraryUri = output.assets
        .whereType<NativeCodeAsset>()
        .where((asset) => asset.id.endsWith('cblite.dart'))
        .map((asset) => asset.file)
        .singleOrNull;

    final cblitedartBuilder = CBuilder.library(
      name: 'cblitedart',
      assetName: 'src/bindings/cblitedart.dart',
      language: Language.cpp,
      std: 'c++17',
      cppLinkStdLib: config.targetOS == OS.android ? 'c++_static' : null,
      defines: {
        if (_edition == Edition.enterprise) 'COUCHBASE_ENTERPRISE': '1',
        if (_vectorSearch) 'COUCHBASE_VECTOR_SEARCH': '1',
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
      config: config,
      output: output,
      logger: _logger,
    );
  });
}
