import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/bindings/bindings.dart';
import 'package:test/test.dart';

/// The [Libraries] to use when running tests during development.
Libraries devLibraries() {
  final buildDir = '../../build';
  final cblLib = '$buildDir/vendor/couchbase-lite-C/libCouchbaseLiteC';
  final cblDartLib = '$buildDir/cbl-dart/libCouchbaseLiteDart';
  return Libraries(
    cbl: LibraryConfiguration.dynamic(cblLib),
    cblDart: LibraryConfiguration.dynamic(cblDartLib),
  );
}

/// The [Libraries] to use when running tests as part of CI.
Libraries ciLibraries() {
  final libsDIr = '../../libs';
  final cblLib = '$libsDIr/libCouchbaseLiteC';
  final cblDartLib = '$libsDIr/libCouchbaseLiteDart';
  return Libraries(
    cbl: LibraryConfiguration.dynamic(cblLib),
    cblDart: LibraryConfiguration.dynamic(cblDartLib),
  );
}

/// `true` if tests are running as part of CI.
final isCi = Platform.environment.containsKey('CI');

/// The libraries config for tests.
late final testLibraries = isCi ? ciLibraries() : devLibraries();

Future<CouchbaseLite>? _couchbaseLite;

/// Initializes [CouchbaseLite] for tests.
///
/// Only on the first call [CouchbaseLite.init] is actually called. Subsequent
/// calls continue right away and receive the cached [CouchbaseLite] object.
Future<CouchbaseLite> initCouchbaseLiteForTests() =>
    _couchbaseLite ??= Future.sync(() async {
      if (isCi) print('Running tests in CI');

      final cbl = await CouchbaseLite.init(libraries: testLibraries);

      cbl..logLevel = LogLevel.info;

      return cbl;
    });

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
