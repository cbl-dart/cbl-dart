import 'dart:io';

import 'package:cbl_native_assets/src/support/edition.dart';
import 'package:native_assets_cli/native_assets_cli.dart';
import 'package:test/test.dart';

import '../hook/build.dart';
import '../hook/cblite_package.dart';
import 'helpers.dart';

void main() {
  final testDataDirectory = Directory.fromUri(
    Directory.current.uri.resolve('.dart_tool/test/data/CblitePackage'),
  );

  setUpAll(() {
    if (testDataDirectory.existsSync()) {
      testDataDirectory.deleteSync(recursive: true);
    }
    testDataDirectory.createSync(recursive: true);
  });

  group('CblitePackage', () {
    group('database', () {
      for (final os in OS.values) {
        for (final edition in [Edition.enterprise]) {
          for (final loader in [
            remoteDatabaseArchiveLoader,
            localDatabaseArchiveLoader,
          ]) {
            if (edition == Edition.community &&
                loader is LocalDatabaseArchiveLoader) {
              continue;
            }

            final packages = CblitePackage.database(
              edition: edition,
              os: os,
              loader: loader,
            );

            group('${loader.runtimeType}', () {
              for (final package in packages) {
                for (final architecture in package.architectures) {
                  test(
                    'installPackage ($os, $architecture, ${edition.name})',
                    () async {
                      final tmpDir = testDataDirectory.createTempSync();
                      await package.installPackage(
                          tmpDir.uri, architecture, logger);
                      final libraryUri =
                          package.resolveLibraryUri(tmpDir.uri, architecture);
                      final libraryFile = File.fromUri(libraryUri);
                      expect(libraryFile.existsSync(), isTrue);
                    },
                  );
                }
              }
            });
          }
        }
      }
    });

    group('vectorSearchExtension', () {
      for (final os in OS.values) {
        final packages = CblitePackage.vectorSearchExtension(
          os: os,
          loader: localVectorSearchArchiveLoader,
        );

        for (final package in packages) {
          for (final architecture in package.architectures) {
            test(
              'installPackage ($os, $architecture)',
              () async {
                final tmpDir = testDataDirectory.createTempSync();
                await package.installPackage(tmpDir.uri, architecture, logger);
                final libraryUri =
                    package.resolveLibraryUri(tmpDir.uri, architecture);
                final libraryFile = File.fromUri(libraryUri);
                expect(libraryFile.existsSync(), isTrue);
              },
            );
          }
        }
      }
    });
  });
}
