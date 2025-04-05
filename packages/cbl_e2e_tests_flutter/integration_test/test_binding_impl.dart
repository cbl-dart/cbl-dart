// ignore_for_file: prefer_function_declarations_over_variables

import 'dart:async';
import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl_flutter/cbl_flutter.dart';
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

final class FlutterCblE2eTestBinding extends CblE2eTestBinding {
  static void ensureInitialized() {
    CblE2eTestBinding.ensureInitialized(FlutterCblE2eTestBinding.new);
  }

  @override
  FutureOr<void> initCouchbaseLite() async {
    await CouchbaseLiteFlutter.init(autoEnableVectorSearch: false);
    Extension.enableVectorSearch();
  }

  @override
  Future<String> resolveTmpDir() => getTemporaryDirectory()
      .then((dir) => Directory.fromUri(dir.uri.resolve('cbl_flutter')).path);

  @override
  final testFn = (description, body, {Object? skip}) => ft.testWidgets(
        description,
        (tester) async => await body(),
        skip: skip != null,
      );

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
