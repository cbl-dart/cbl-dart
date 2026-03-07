import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:test/scaffolding.dart';
import 'package:test/test.dart';

Future<void> initCouchbaseLiteForTest() async {
  final tmpDir = await Directory.systemTemp.createTemp('cbl_generator_test');
  await CouchbaseLite.init(filesDir: tmpDir.path);
}

Future<AsyncDatabase> openTestDatabase() async {
  final db = await Database.openAsync('test');
  addTearDown(db.delete);
  return db;
}
