import 'dart:async';
import 'dart:io';

import 'package:cbl_dart/cbl_dart.dart';
import 'package:cbl_dart/src/acquire_libraries.dart';
import 'package:path/path.dart' as p;

import 'cbl_e2e_tests/test_binding.dart';

void setupTestBinding() {
  StandaloneDartCblE2eTestBinding.ensureInitialized();
}

class StandaloneDartCblE2eTestBinding extends CblE2eTestBinding {
  static void ensureInitialized() {
    CblE2eTestBinding.ensureInitialized(StandaloneDartCblE2eTestBinding.new);
  }

  @override
  Future<void> initCouchbaseLite() async {
    await setupDevelopmentLibraries();
    await CouchbaseLiteDart.init(edition: Edition.enterprise);
  }

  @override
  String resolveTmpDir() => p.absolute(p.join('test', '.tmp'));

  @override
  FutureOr<String> loadLargeJsonFixture() =>
      File(p.join('test', 'cbl_e2e_tests', 'fixtures', '1000people.json'))
          .readAsString();
}
