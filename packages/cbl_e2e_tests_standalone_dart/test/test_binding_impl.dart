import 'dart:async';
import 'dart:io';

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
  Future<String> resolveTmpDir() async => p.absolute(p.join('test', '.tmp'));

  @override
  Future<String> loadLargeJsonFixture() async =>
      File(p.join('test', 'cbl_e2e_tests', 'fixtures', '1000people.json'))
          .readAsString();
}
