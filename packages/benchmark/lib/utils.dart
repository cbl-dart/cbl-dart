import 'dart:convert';
import 'dart:io';

import 'package:cbl/cbl.dart';

String loadFixtureAsString(String name) =>
    File('fixture/$name.json').readAsStringSync();

Object? loadFixtureAsJson(String name) => jsonDecode(loadFixtureAsString(name));

Future<void> configureCouchbaseLite() async {
  Database.defaultDirectory = Directory.systemTemp
      .createTempSync('cbl_benchmark')
      .path;
}
