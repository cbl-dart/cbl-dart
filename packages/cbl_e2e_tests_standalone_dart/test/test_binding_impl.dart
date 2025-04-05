import 'dart:async';

import 'package:cbl/cbl.dart';
import 'package:cbl_dart/cbl_dart.dart';
import 'package:cbl_dart/src/acquire_libraries.dart';
import 'package:path/path.dart' as p;

import 'cbl_e2e_tests/test_binding.dart';

void setupTestBinding() {
  StandaloneDartCblE2eTestBinding.ensureInitialized();
}

final class StandaloneDartCblE2eTestBinding extends CblE2eTestBinding {
  static void ensureInitialized() {
    CblE2eTestBinding.ensureInitialized(StandaloneDartCblE2eTestBinding.new);
  }

  @override
  Future<void> initCouchbaseLite() async {
    await setupDevelopmentLibraries();
    await CouchbaseLiteDart.init(
      edition: Edition.enterprise,
      autoEnableVectorSearch: false,
    );
    Extension.enableVectorSearch();
  }

  @override
  String resolveTmpDir() => p.absolute(p.join('test', '.tmp'));
}
