import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cbl/cbl.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart' as t;

export 'package:test/test.dart'
    hide
        test,
        group,
        setUpAll,
        setUp,
        tearDownAll,
        tearDown,
        addTearDown,
        registerException,
        printOnFailure,
        markTestSkipped;

/// Signature of the function to return from [CblE2eTestBinding.testFn].
typedef TestFn = void Function(dynamic description, dynamic Function() body);

typedef TestHook = void Function(dynamic Function() body);

/// The properties which end are the functions used to declare tests, groups
/// and lifecycle hooks. Per default these properties return the corresponding
/// functions from the `test` package.
///
/// Overriding these properties is useful to run tests with the
/// `integration_test` package, which requires that all tests are declared
/// through `widgetTest`.
abstract class CblE2eTestBinding {
  static void ensureInitialized(CblE2eTestBinding Function() createBinding) {
    if (_instance != null) return;
    _instance = createBinding();

    _instance!
      .._setupLogging()
      .._setupTestLifecycleHooks();
  }

  static CblE2eTestBinding? _instance;

  /// The global instance of [CblE2eTestBinding] by which is used by tests.
  static CblE2eTestBinding get instance => _instance!;

  /// The [Libraries] to use in tests.
  Libraries get libraries;

  /// Temporary directory for files created during tests, such as databases.
  FutureOr<String> resolveTmpDir();

  /// Temporary directory for tests.
  late final String tmpDir;

  TestFn get testFn => t.test;

  TestFn get groupFn => t.group;

  TestHook get setUpAllFn => t.setUpAll;

  TestHook get setUpFn => t.setUp;

  TestHook get tearDownAllFn => t.tearDownAll;

  TestHook get tearDownFn => t.tearDown;

  TestHook get addTearDownFn => t.addTearDown;

  void _setupLogging() {
    Zone.root.run(() {
      Logger.root.onRecord.listen((record) {
        final stringBuilder = StringBuffer();

        stringBuilder.write(
          '[${record.level.name}] ${record.loggerName} | ${record.message}',
        );

        if (record.error != null) {
          stringBuilder.write('\nError: ${record.error}');
        }

        if (record.stackTrace != null) {
          stringBuilder.write('\n${record.stackTrace}');
        }

        print(stringBuilder.toString());
      });
    });
  }

  void _setupTestLifecycleHooks() {
    setUpAllFn(() async {
      tmpDir = await resolveTmpDir();
      await _cleanTestTmpDir();
      await _initCouchbaseLite();
    });

    tearDownAllFn(() => CouchbaseLite.dispose());
  }

  Future _cleanTestTmpDir() async {
    final tmpDir = Directory(this.tmpDir);
    if (await tmpDir.exists()) {
      await tmpDir.delete(recursive: true);
    }
    await tmpDir.create(recursive: true);
  }

  Future<void> _initCouchbaseLite() =>
      CouchbaseLite.initialize(libraries: libraries).then(
        (cbl) => cbl
          ..logLevel = LogLevel.info
          ..logCallback = loggerCallback(),
      );
}

/// Alias of [CouchbaseLite.instance].
late final cbl = CouchbaseLite.instance;

/// Alias of [CblE2eTestBinding.tmpDir].
late final tmpDir = CblE2eTestBinding.instance.tmpDir;

late final libraries = CblE2eTestBinding.instance.libraries;

/// Returns a unique name for a database every time it is called, which starts
/// with [testName].
String testDbName(String testName) => '$testName-'
    '${DateTime.now().millisecondsSinceEpoch}-'
    '${Random().nextInt(10000)}';

@isTest
void test(dynamic description, dynamic Function() body) =>
    CblE2eTestBinding.instance.testFn(description, body);

@isTestGroup
void group(dynamic description, dynamic Function() body) =>
    CblE2eTestBinding.instance.groupFn(description, body);

void setUpAll(dynamic Function() body) =>
    CblE2eTestBinding.instance.setUpAllFn(body);

void setUp(dynamic Function() body) => CblE2eTestBinding.instance.setUpFn(body);

void tearDownAll(dynamic Function() body) =>
    CblE2eTestBinding.instance.tearDownAllFn(body);

void tearDown(dynamic Function() body) =>
    CblE2eTestBinding.instance.tearDownFn(body);

void addTearDown(dynamic Function() body) =>
    CblE2eTestBinding.instance.addTearDownFn(body);
