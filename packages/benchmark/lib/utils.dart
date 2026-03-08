import 'dart:convert';
import 'dart:io';

import 'package:cbl/cbl.dart';

String jsonEncodePretty(Map<String, Object?> json) =>
    const JsonEncoder.withIndent('  ').convert(json);

String loadFixtureAsString(String name) =>
    File('fixture/$name.json').readAsStringSync();

Object? loadFixtureAsJson(String name) => jsonDecode(loadFixtureAsString(name));

Future<void> initCouchbaseLite() async {
  await CouchbaseLite.init();
}
