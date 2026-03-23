import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:test/scaffolding.dart';
import 'package:test/test.dart';

Future<void> configureCouchbaseLiteForTest() async {
  final tmpDir = await Directory.systemTemp.createTemp('cbl_generator_test');
  Database.defaultDirectory = tmpDir.path;
}

Future<AsyncDatabase> openTestDatabase() async {
  final db = await Database.openAsync('test');
  addTearDown(db.delete);
  return db;
}
