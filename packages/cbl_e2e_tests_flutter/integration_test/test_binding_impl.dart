// ignore_for_file: prefer_function_declarations_over_variables

import 'dart:async';
import 'dart:io';

import 'package:cbl_flutter_2/cbl_flutter.dart';
import 'package:cbl_flutter_local/cbl_flutter_local.dart';
import 'package:flutter_test/flutter_test.dart' as ft;
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'cbl_e2e_tests/test_binding.dart';

void setupTestBinding() {
  // TODO(blaugold): remove when mobile support registration of dart plugins
  if (Platform.isIOS || Platform.isAndroid) {
    CblFlutterLocal.registerWith();
  }

  final widgetBinding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
      as IntegrationTestWidgetsFlutterBinding;
  // ignore: cascade_invocations
  widgetBinding.defaultTestTimeout = const Timeout(Duration(seconds: 30));

  FlutterCblE2eTestBinding.ensureInitialized();
}

class FlutterCblE2eTestBinding extends CblE2eTestBinding {
  static void ensureInitialized() {
    CblE2eTestBinding.ensureInitialized(() => FlutterCblE2eTestBinding());
  }

  @override
  FutureOr<void> initCouchbaseLite() => CouchbaseLiteFlutter.init();

  @override
  Future<String> resolveTmpDir() => getTemporaryDirectory()
      .then((dir) => Directory.fromUri(dir.uri.resolve('cbl_flutter')).path);

  @override
  bool get useDartConsoleLogger => true;

  @override
  final testFn = (description, body) =>
      ft.testWidgets(description, (tester) async => await body());

  @override
  final groupFn = ft.group;

  @override
  final setUpAllFn = ft.setUpAll;

  @override
  final setUpFn = ft.setUp;

  @override
  final tearDownAllFn = ft.tearDownAll;

  @override
  final tearDownFn = ft.tearDown;

  @override
  final addTearDownFn = ft.addTearDown;
}
