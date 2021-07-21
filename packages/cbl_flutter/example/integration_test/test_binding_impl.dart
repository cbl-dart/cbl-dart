import 'package:cbl_flutter/cbl_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'cbl_e2e_tests/test_binding.dart';

void setupTestBinding() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  FlutterCblE2eTestBinding.ensureInitialized();
}

class FlutterCblE2eTestBinding extends CblE2eTestBinding {
  static void ensureInitialized() {
    CblE2eTestBinding.ensureInitialized(() => FlutterCblE2eTestBinding());
  }

  @override
  final libraries = flutterLibraries();

  @override
  Future<String> resolveTmpDir() =>
      getTemporaryDirectory().then((dir) => path.join(dir.path, 'cbl_flutter'));
}
