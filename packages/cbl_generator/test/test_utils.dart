import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl_dart/cbl_dart.dart';
import 'package:test/scaffolding.dart';

Future<void> initCouchbaseLiteForTest() async {
  final tmpDir = await Directory.systemTemp.createTemp('cbl_generator_test');
  await CouchbaseLiteDart.init(
    edition: Edition.community,
    filesDir: tmpDir.path,
  );
}

Future<AsyncDatabase> openTestDatabase() async {
  final db = await Database.openAsync('test');
  addTearDown(db.delete);
  return db;
}
