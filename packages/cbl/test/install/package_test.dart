import 'dart:io';

import 'package:cbl/src/install/package.dart';
import 'package:test/test.dart';

void main() {
  group('DatabasePackageConfig', () {
    test('download packages ', () async {
      final tempCacheDir = Directory.systemTemp.createTempSync();
      addTearDown(() => tempCacheDir.deleteSync(recursive: true));

      final loader = RemotePackageLoader(cacheDir: tempCacheDir.path);
      final configs = [
        for (final edition in Edition.values)
          ...DatabasePackageConfig.all(
            releases: {Library.cblite: '3.2.0', Library.cblitedart: '8.0.0'},
            edition: edition,
          ),
      ].withoutMacOSonDifferentHost;
      await Future.wait(configs.map(loader.load));
    });
  });

  group('VectorSearchPackageConfig', () {
    test('download packages', () async {
      final tempCacheDir = Directory.systemTemp.createTempSync();
      addTearDown(() => tempCacheDir.deleteSync(recursive: true));

      final loader = RemotePackageLoader(cacheDir: tempCacheDir.path);
      final packageConfigs = VectorSearchPackageConfig.all(release: '1.0.0')
          .withoutMacOSonDifferentHost;
      await Future.wait(packageConfigs.map(loader.load));
    });

    test('package layout', () async {
      final loader = RemotePackageLoader();
      final packageConfigs = VectorSearchPackageConfig.all(release: '1.0.0')
          .withoutMacOSonDifferentHost;

      for (final packageConfig in packageConfigs) {
        final package = await loader.load(packageConfig);
        for (final architecture in package.config.architectures) {
          if (package.sharedLibrariesDir(architecture)
              case final sharedLibrariesDir?) {
            expect(
              Directory(sharedLibrariesDir).existsSync(),
              isTrue,
              reason: 'Missing: $sharedLibrariesDir',
            );
          }
        }
      }
    });
  });
}

extension on Iterable<PackageConfig> {
  /// Filters out macOS packages on a a non macOS host.
  ///
  /// This is useful to avoid loading macOS packages on a CI host that doesn't
  /// have the necessary tools (e.g. codesign).
  Iterable<PackageConfig> get withoutMacOSonDifferentHost => where((config) {
        if (config.os == OS.macOS) {
          return Platform.isMacOS;
        }

        return true;
      });
}
