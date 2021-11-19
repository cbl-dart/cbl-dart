import 'dart:async';
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
  FutureOr<void> initCouchbaseLite() {
    CouchbaseLite.init(libraries: _libraries());
  }

  @override
  String resolveTmpDir() => p.absolute(p.join('test', '.tmp'));
}

LibrariesConfiguration _libraries() {
  const enterpriseEdition = true;

  String? directory;
  String cblLib;
  String cblDartLib;
  String? cblVersion;

  final libDir = p.absolute('lib');
  final isUnix = Platform.isLinux || Platform.isMacOS;
  if (isUnix && FileSystemEntity.isDirectorySync(libDir)) {
    directory = libDir;
    cblLib = 'libcblite';
    cblDartLib = 'libcblitedart';
    // TODO(blaugold): remove version when symlinks in macOS release are fixed
    cblVersion = '3';
  } else if (Platform.isMacOS) {
    directory = p.absolute('Frameworks');
    cblLib = 'CouchbaseLite';
    cblDartLib = 'CouchbaseLiteDart';
  } else if (Platform.isWindows) {
    directory = p.absolute('bin');
    cblLib = 'cblite';
    cblDartLib = 'cblitedart';
  } else {
    throw StateError('Could not find libraries for current platform');
  }

  return LibrariesConfiguration(
    enterpriseEdition: enterpriseEdition,
    directory: directory,
    cbl: LibraryConfiguration.dynamic(cblLib, version: cblVersion),
    cblDart: LibraryConfiguration.dynamic(cblDartLib),
  );
}
