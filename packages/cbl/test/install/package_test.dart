import 'dart:io';

import 'package:cbl/src/install/package.dart';
import 'package:test/test.dart';

void main() {
  group('VectorSearchPackageConfig', () {
    test('download packages', () async {
      final tempCacheDir = Directory.systemTemp.createTempSync();
      addTearDown(() => tempCacheDir.deleteSync(recursive: true));

      final loader = RemotePackageLoader(cacheDir: tempCacheDir.path);
      final packageConfigs = VectorSearchPackageConfig.all(release: '1.0.0');
      await Future.wait(packageConfigs.map(loader.load));
    });

    test('package layout', () async {
      final loader = RemotePackageLoader();
      final packageConfigs = VectorSearchPackageConfig.all(release: '1.0.0');

      for (final packageConfig in packageConfigs) {
        final package = await loader.load(packageConfig) as VectorSearchPackage;
        if (package.sharedLibrariesDir case final sharedLibrariesDir?) {
          expect(
            Directory(sharedLibrariesDir).existsSync(),
            isTrue,
            reason: 'Missing: $sharedLibrariesDir',
          );
        }
      }
    });
  });
}
