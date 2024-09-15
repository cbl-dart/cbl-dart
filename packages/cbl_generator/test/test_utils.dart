import 'package:cbl/cbl.dart';
import 'package:test/scaffolding.dart';
import 'package:test/test.dart';

Future<void> initCouchbaseLiteForTest() async {
  await CouchbaseLite.init();
}

Future<AsyncDatabase> openTestDatabase() async {
  final db = await Database.openAsync('test');
  addTearDown(db.delete);
  return db;
}
