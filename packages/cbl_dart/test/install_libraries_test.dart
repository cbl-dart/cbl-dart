import 'dart:io';

import 'package:cbl_dart/src/install_libraries.dart';
import 'package:cbl_dart/src/package.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('install merged native libraries', () async {
    final installDir = await Directory.systemTemp.createTemp();

    final packages = Library.values.map((library) => Package(
          library: library,
          release: Package.latestReleases[library]!,
          edition: Edition.enterprise,
          target: Target.host,
        ));

    await installMergedNativeLibraries(packages, directory: installDir.path);

    final installDirEntries = installDir.listSync();
    expect(installDirEntries, hasLength(1));

    final libDir = installDirEntries.first as Directory;
    expect(p.basename(libDir.path), Package.mergedSignature(packages));

    final libDirEntries = libDir.listSync();
    final libDirBasenames =
        libDirEntries.map((entry) => p.basename(entry.path)).toList();

    expect(
      libDirBasenames,
      containsAll(<Object>[
        contains('cblite.'),
        contains('cblitedart.'),
      ]),
    );
  });
}
