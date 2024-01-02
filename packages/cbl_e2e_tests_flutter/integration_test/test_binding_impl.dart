// ignore_for_file: prefer_function_declarations_over_variables

import 'dart:async';
import 'dart:io';

import 'package:cbl_flutter/cbl_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart' as ft;
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'cbl_e2e_tests/test_binding.dart';

void setupTestBinding() {
  final widgetBinding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // ignore: cascade_invocations
  widgetBinding.defaultTestTimeout = const Timeout(Duration(seconds: 30));

  FlutterCblE2eTestBinding.ensureInitialized();
}

class FlutterCblE2eTestBinding extends CblE2eTestBinding {
  static void ensureInitialized() {
    CblE2eTestBinding.ensureInitialized(FlutterCblE2eTestBinding.new);
  }

  @override
  FutureOr<void> initCouchbaseLite() => CouchbaseLiteFlutter.init();

  @override
  Future<String> resolveTmpDir() => getTemporaryDirectory()
      .then((dir) => Directory.fromUri(dir.uri.resolve('cbl_flutter')).path);

  @override
  FutureOr<String> loadLargeJsonFixture() => rootBundle
      .loadString('packages/cbl_e2e_tests/src/fixtures/1000people.json');

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
