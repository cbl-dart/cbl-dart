import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl_dart/cbl_dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('database is created in filesDir', () async {
    final filesDir = await Directory.systemTemp.createTemp();

    await CouchbaseLiteDart.init(
      edition: Edition.enterprise,
      filesDir: filesDir.path,
    );

    final db = await Database.openAsync('a');
    await db.close();

    final databaseFile =
        Directory(p.join(filesDir.path, 'CouchbaseLite', 'a.cblite2'));
    expect(databaseFile.existsSync(), isTrue);
  });
}
