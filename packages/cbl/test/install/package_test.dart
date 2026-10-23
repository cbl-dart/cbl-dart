import 'dart:io';

import 'package:cbl/src/install/package.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('DatabasePackageConfig', () {
    test('download packages ', () async {
      final tempCacheDir = tempTestDirectory();
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
      final tempCacheDir = tempTestDirectory();
      final loader = RemotePackageLoader(cacheDir: tempCacheDir.path);
      final packageConfigs = VectorSearchPackageConfig.all(
        release: '2.0.0',
      ).withoutMacOSonDifferentHost;
      await Future.wait(packageConfigs.map(loader.load));
    });

    test(
      'preserves versioned xcframework links from a fresh cache',
      () async {
        final cache = tempTestDirectory();
        final package = await RemotePackageLoader(cacheDir: cache.path).load(
          VectorSearchPackageConfig(
            os: OS.iOS,
            architectures: [Architecture.arm64, Architecture.x64],
            release: '1.0.0',
          ),
        );
        for (final slice in [
          'macos-arm64_x86_64',
          'ios-arm64_x86_64-maccatalyst',
        ]) {
          final framework =
              '${package.appleFrameworkDir}/$slice/'
              'CouchbaseLiteVectorSearch.framework';
          expect(Link('$framework/Versions/Current').targetSync(), 'A');
          expect(
            Link('$framework/CouchbaseLiteVectorSearch').targetSync(),
            'Versions/Current/CouchbaseLiteVectorSearch',
          );
          expect(
            Link('$framework/Resources').targetSync(),
            'Versions/Current/Resources',
          );
          expect(
            File('$framework/CouchbaseLiteVectorSearch').lengthSync(),
            greaterThan(0),
          );
          expect(File('$framework/Resources/Info.plist').existsSync(), isTrue);
        }
      },
      skip: Platform.isWindows,
    );

    test('package layout', () async {
      final loader = RemotePackageLoader();
      final packageConfigs = VectorSearchPackageConfig.all(
        release: '2.0.0',
      ).withoutMacOSonDifferentHost;

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
