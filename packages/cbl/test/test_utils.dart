import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/bindings/bindings.dart';
import 'package:test/test.dart';

final _buildDir = '../../build';
final _cblLib = '$_buildDir/vendor/couchbase-lite-C/libCouchbaseLiteC';
final _cblDartLib = '$_buildDir/cbl-dart/libCouchbaseLiteDart';

/// The libraries config for tests.
final testLibraries = Libraries(
  cbl: LibraryConfiguration.dynamic(_cblLib),
  cblDart: LibraryConfiguration.dynamic(_cblDartLib),
);

Future<CouchbaseLite>? _couchbaseLite;

/// Initializes [CouchbaseLite] for tests.
///
/// Only on the first call [CouchbaseLite.init] is actually called. Subsequent
/// calls continue right away and receive the cached [CouchbaseLite] object.
Future<CouchbaseLite> initCouchbaseLiteForTests() =>
    _couchbaseLite ??= CouchbaseLite.init(libraries: testLibraries).then(
      (cbl) => cbl..logLevel = LogLevel.info,
    );

late final CouchbaseLite cbl;

var _testEnvironmentIsSetup = false;

void testEnvironmentSetup() {
  if (_testEnvironmentIsSetup) return;

  _testEnvironmentIsSetup = true;

  setUpAll(() async {
    await cleanTestTmpDir();
    cbl = await initCouchbaseLiteForTests();
  });

  tearDownAll(() => cbl.dispose());
}

final testTmpDir = 'test/.tmp';

Future cleanTestTmpDir() async {
  await Process.run('rm', ['-rf', testTmpDir]);
  await Process.run('mkdir', ['-p', testTmpDir]);
}

String testDbName(String testName) =>
    '$testName-${DateTime.now().millisecondsSinceEpoch}';
