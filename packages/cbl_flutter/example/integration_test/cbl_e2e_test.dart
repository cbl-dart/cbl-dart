import 'package:cbl_e2e_tests/cbl_e2e_tests.dart';
import 'package:integration_test/integration_test.dart';

import 'test_binding.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  FlutterCblE2eTestBinding.ensureInitialized();

  cblE2eTests();
}
