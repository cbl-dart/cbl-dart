import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/bindings/bindings.dart';
import 'package:meta/meta.dart';

import 'test_bindings.dart';

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

Future<CouchbaseLite>? _couchbaseLite;

/// Initializes [CouchbaseLite] for tests.
///
/// Only on the first call [CouchbaseLite.init] is actually called. Subsequent
/// calls continue right away and receive the cached [CouchbaseLite] object.
Future<CouchbaseLite> initCouchbaseLiteForTests() =>
    _couchbaseLite ??= Future.sync(() async {
      final cbl = await CouchbaseLite.init(
        libraries: CblE2eTestBindings.instance.libraries,
      );

      cbl..logLevel = LogLevel.info;

      return cbl;
    });

/// Global instance of [CouchbaseLite] initialized by
/// [initCouchbaseLiteForTests].
late final CouchbaseLite cbl;

var _testEnvironmentIsSetup = false;

/// Register test hooks to setup a common test environment.
///
/// Before all tests:
/// - [testTmpDir] is cleaned.
/// - [initCouchbaseLiteForTests] is called to initialized [cbl].
///
/// After all tests:
/// - [cbl.dispose()] is called.
void testEnvironmentSetup() {
  if (_testEnvironmentIsSetup) return;

  _testEnvironmentIsSetup = true;

  setUpAll(() async {
    testTmpDir = await CblE2eTestBindings.instance.tmpDirectory;
    await _cleanTestTmpDir();
    cbl = await initCouchbaseLiteForTests();
  });

  tearDownAll(() => cbl.dispose());
}

/// See [CblE2eTestBindings.tmpDirectory].
late String testTmpDir;

Future _cleanTestTmpDir() async {
  await Process.run('rm', ['-rf', testTmpDir]);
  await Process.run('mkdir', ['-p', testTmpDir]);
}

/// Returns a unique name for a database every time it is called, which starts
/// with [testName].
String testDbName(String testName) =>
    '$testName-${DateTime.now().millisecondsSinceEpoch}';

@isTest
void test(dynamic description, dynamic Function() body) =>
    CblE2eTestBindings.instance.testFn(description, body);

@isTestGroup
void group(dynamic description, dynamic Function() body) =>
    CblE2eTestBindings.instance.groupFn(description, body);

void setUpAll(dynamic Function() body) =>
    CblE2eTestBindings.instance.setUpAllFn(body);

void setUp(dynamic Function() body) =>
    CblE2eTestBindings.instance.setUpFn(body);

void tearDownAll(dynamic Function() body) =>
    CblE2eTestBindings.instance.tearDownAllFn(body);

void tearDown(dynamic Function() body) =>
    CblE2eTestBindings.instance.tearDownFn(body);

void addTearDown(dynamic Function() body) =>
    CblE2eTestBindings.instance.addTearDownFn(body);
