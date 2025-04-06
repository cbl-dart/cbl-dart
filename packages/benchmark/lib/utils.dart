import 'dart:convert';
import 'dart:io';

import 'package:cbl_dart/cbl_dart.dart';
// ignore: implementation_imports
import 'package:cbl_dart/src/acquire_libraries.dart';

String jsonEncodePretty(Map<String, Object?> json) =>
    const JsonEncoder.withIndent('  ').convert(json);

String loadFixtureAsString(String name) =>
    File('fixture/$name.json').readAsStringSync();

Object? loadFixtureAsJson(String name) => jsonDecode(loadFixtureAsString(name));

Future<void> initCouchbaseLite() async {
  await setupDevelopmentLibraries(
    standaloneDartE2eTestDir: '../cbl_e2e_tests_standalone_dart',
  );
  await CouchbaseLiteDart.init(edition: Edition.enterprise);
}
