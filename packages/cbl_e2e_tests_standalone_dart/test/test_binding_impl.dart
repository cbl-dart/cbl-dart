import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:path/path.dart' as p;

import 'cbl_e2e_tests/test_binding.dart';

void setupTestBinding() {
  StandaloneDartCblE2eTestBinding.ensureInitialized();
}

class StandaloneDartCblE2eTestBinding extends CblE2eTestBinding {
  static void ensureInitialized() {
    CblE2eTestBinding.ensureInitialized(
        () => StandaloneDartCblE2eTestBinding());
  }

  @override
  String resolveTmpDir() => Directory('test/.tmp').absolute.path;

  @override
  late final libraries = (() {
    final libDir = p.absolute('lib');
    final frameworksDir = p.absolute('Frameworks');

    String findLibInFrameworks(String name) =>
        '$frameworksDir/$name.framework/Versions/A/$name';

    late String cblLib;
    late String cblDartLib;

    final isUnix = Platform.isLinux || Platform.isMacOS;

    if (isUnix && FileSystemEntity.isDirectorySync(libDir)) {
      cblLib = '$libDir/libcblite';
      cblDartLib = '$libDir/libcblitedart';

      return Libraries(
        cbl: LibraryConfiguration.dynamic(cblLib, version: '3'),
        cblDart: LibraryConfiguration.dynamic(cblDartLib),
      );
    } else if (Platform.isMacOS) {
      cblLib = findLibInFrameworks('CouchbaseLite');
      cblDartLib = findLibInFrameworks('CouchbaseLiteDart');

      return Libraries(
        cbl: LibraryConfiguration.dynamic(
          cblLib,
          appendExtension: false,
        ),
        cblDart: LibraryConfiguration.dynamic(
          cblDartLib,
          appendExtension: false,
        ),
      );
    } else {
      throw StateError('Could not find libraries for current platform');
    }
  })();
}
