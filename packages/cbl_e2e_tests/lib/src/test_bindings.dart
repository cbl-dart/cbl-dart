import 'dart:async';

import 'package:cbl/cbl.dart';
import 'package:test/test.dart';

/// Signature of the function to return from [CblE2eTestBindings.testFn].
typedef TestFn = void Function(dynamic description, dynamic Function() body);

typedef TestHook = void Function(dynamic Function() body);

/// The properties which end are the functions used to declare tests, groups
/// and lifecycle hooks. Per default these properties return the corresponding
/// functions from the `test` package.
///
/// Overriding these properties is useful to run tests with the
/// `integration_test` package, which requires that all tests are declared
/// through `widgetTest`.
abstract class CblE2eTestBindings {
  static void register(CblE2eTestBindings instance) {
    _instance = instance;
  }

  static late final CblE2eTestBindings _instance;

  /// The global instance of [CblE2eTestBindings] by which is used by tests.
  static CblE2eTestBindings get instance => _instance;

  TestFn get testFn => test;

  TestFn get groupFn => group;

  TestHook get setUpAllFn => setUpAll;

  TestHook get setUpFn => setUp;

  TestHook get tearDownAllFn => tearDownAll;

  TestHook get tearDownFn => tearDown;

  TestHook get addTearDownFn => addTearDown;

  /// The [Libraries] to use in tests.
  Libraries get libraries;

  /// Temporary directory for files created during tests, such as databases.
  FutureOr<String> get tmpDirectory;
}
