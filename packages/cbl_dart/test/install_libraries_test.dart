import 'dart:io';

import 'package:cbl/src/install.dart';
import 'package:cbl_dart/src/install_libraries.dart';
import 'package:cbl_dart/src/version_info.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('install merged native libraries', () async {
    final installDir = await Directory.systemTemp.createTemp();

    final loader = RemotePackageLoader();
    final packageConfigs = DatabasePackageConfig.all(
      releases: latestReleases,
      edition: Edition.enterprise,
    ).where((config) => config.os == OS.current);
    final packages = await Future.wait(packageConfigs.map(loader.load));

    await installMergedNativeLibraries(packages, directory: installDir.path);

    final installDirEntries = installDir.listSync();
    expect(installDirEntries, hasLength(1));

    final libDir = installDirEntries.first as Directory;
    expect(p.basename(libDir.path), PackageMerging.signature(packages));

    final libDirEntries = libDir.listSync();
    final libDirBasenames = libDirEntries
        .map((entry) => p.basename(entry.path))
        .toList();

    expect(
      libDirBasenames,
      containsAll(<Object>[contains('cblite.'), contains('cblitedart.')]),
    );
  });
}
