import 'dart:async';
import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart' as t;

import 'utils/database_utils.dart';
import 'utils/file_system.dart';
import 'utils/time_bomb.dart';
import 'utils/utils.dart';

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
        printOnFailure;

typedef TestFn = void Function(
  String description,
  FutureOr<void> Function() body,
);

typedef GroupFn = void Function(
  String description,
  void Function() body,
);

typedef TestHook = void Function(dynamic Function() body);

/// The properties which end are the functions used to declare tests, groups and
/// lifecycle hooks. Per default these properties return the corresponding
/// functions from the `test` package.
///
/// Overriding these properties is useful to run tests with the
/// `integration_test` package, which requires that all tests are declared
/// through `widgetTest`.
abstract class CblE2eTestBinding {
  static void ensureInitialized(CblE2eTestBinding Function() createBinding) {
    if (_instance != null) {
      return;
    }
    _instance = createBinding();

    _instance!._setupTestLifecycleHooks();
  }

  static CblE2eTestBinding? _instance;

  /// The global instance of [CblE2eTestBinding] by which is used by tests.
  static CblE2eTestBinding get instance => _instance!;

  FutureOr<void> initCouchbaseLite();

  /// Temporary directory for files created during tests, such as databases.
  FutureOr<String> resolveTmpDir();

  /// Temporary directory for tests.
  late final String tmpDir;

  FutureOr<String> loadLargeJsonFixture();

  late final String largeJsonFixture;

  TestFn get testFn => t.test;

  GroupFn get groupFn => t.group;

  TestHook get setUpAllFn => t.setUpAll;

  TestHook get setUpFn => t.setUp;

  TestHook get tearDownAllFn => t.tearDownAll;

  TestHook get tearDownFn => t.tearDown;

  TestHook get addTearDownFn => t.addTearDown;

  final _groupDescriptions = <String>[];

  void _test(String description, FutureOr<void> Function() body) {
    final testDescriptions = [..._groupDescriptions, description];
    testFn(
      description,
      () => runZoned<dynamic>(body, zoneValues: {
        #testId: md5OfString(testDescriptions.join()),
        #testDescriptions: testDescriptions,
      }),
    );
  }

  void _group(String description, void Function() body) {
    _groupDescriptions.add(description);
    groupFn(description, body);
    _groupDescriptions.removeLast();
  }

  void _setupTestLifecycleHooks() {
    setUpAllFn(() async {
      tmpDir = await resolveTmpDir();
      await _cleanTestTmpDir();
      await initCouchbaseLite();

      const consoleLogLevel = LogLevel.warning;
      const fileLogLevel = LogLevel.verbose;

      Database.log.file
        ..config = LogFileConfiguration(
          directory: '$tmpDir/logs',
          usePlainText: true,
          maxRotateCount: 100,
          // Should be large enough to captures all logs of a test run without
          // file splitting.
          maxSize: 100 * 1024 * 1024, // 100 MB
        )
        ..level = fileLogLevel;

      Database.log.console.level = consoleLogLevel;

      largeJsonFixture = await loadLargeJsonFixture();
    });

    setupTestTimeBomb();
    setupSharedTestMainIsolateClient();
    setupSharedTestWorkerIsolateClient();
    setupSharedTestDatabases();
  }

  Future _cleanTestTmpDir() async {
    final dir = Directory(tmpDir);
    await dir.create(recursive: true);
    final pidFile = File.fromUri(dir.uri.resolve('pid'));

    // Load the pid currently in the pid file.
    final currentPid = await pidFile
        .readAsString()
        .then<int?>(int.parse)
        .onError<FileSystemException>((_, __) => null);

    // Each process should only reset the tmp directory once, so isolates
    // don't delete the data written to the directory by other isolates.
    if (currentPid != pid) {
      await dir.reset();
      await pidFile.writeAsString(pid.toString());
    }
  }
}

/// Alias of [CblE2eTestBinding.tmpDir].
final tmpDir = CblE2eTestBinding.instance.tmpDir;

final largeJsonFixture = CblE2eTestBinding.instance.largeJsonFixture;

String? get testId => Zone.current[#testId] as String?;

List<String>? get testDescriptions =>
    Zone.current[#testDescriptions] as List<String>?;

@isTest
void test(String description, FutureOr<void> Function() body) =>
    CblE2eTestBinding.instance._test(description, body);

@isTestGroup
void group(String description, void Function() body) =>
    CblE2eTestBinding.instance._group(description, body);

void setUpAll(dynamic Function() body) =>
    CblE2eTestBinding.instance.setUpAllFn(body);

void setUp(dynamic Function() body) => CblE2eTestBinding.instance.setUpFn(body);

void tearDownAll(dynamic Function() body) =>
    CblE2eTestBinding.instance.tearDownAllFn(body);

void tearDown(dynamic Function() body) =>
    CblE2eTestBinding.instance.tearDownFn(body);

void addTearDown(dynamic Function() body) =>
    CblE2eTestBinding.instance.addTearDownFn(body);
