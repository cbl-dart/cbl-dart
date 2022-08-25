import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl_dart/cbl_dart.dart';
import 'package:cbl_dart/src/acquire_libraries.dart';
import 'package:test/scaffolding.dart';
import 'package:test/test.dart';

Future<void> initCouchbaseLiteForTest() async {
  final tmpDir = await Directory.systemTemp.createTemp('cbl_generator_test');
  await setupDevelopmentLibraries();
  await CouchbaseLiteDart.init(
    edition: Edition.enterprise,
    filesDir: tmpDir.path,
  );
}

Future<AsyncDatabase> openTestDatabase() async {
  final db = await Database.openAsync('test');
  addTearDown(db.delete);
  return db;
}
