import 'package:cbl_e2e_tests/cbl_e2e_tests.dart';
import 'package:cbl_flutter/cbl_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

class FlutterCblE2eTestBindings extends CblE2eTestBindings {
  @override
  final libraries = flutterLibraries();

  @override
  final tmpDirectory =
      getApplicationDocumentsDirectory().then((dir) => dir!.path);

  @override
  final testFn = (dynamic description, body) =>
      testWidgets(description as String, (tester) async => await body());

  @override
  final groupFn =
      (dynamic description, body) => group(description as Object, body);

  @override
  final setUpAllFn = setUpAll;

  @override
  final setUpFn = setUp;

  @override
  final tearDownAllFn = tearDownAll;

  @override
  final tearDownFn = tearDown;

  @override
  final addTearDownFn = addTearDown;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    print('This is a setup hook for all tests');
  });

  tearDownAll(() {
    print('This is a teardown hook for all tests');
  });

  cblE2eTests(FlutterCblE2eTestBindings());
}
