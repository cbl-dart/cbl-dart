// ignore_for_file: dead_code

import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl_dart/cbl_dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('database is created in working directory', () async {
    return markTestSkipped(
      'TODO(blaugold): enable when cbl uses current working directory for '
      'default db dir',
    );
    final workingDir = await Directory.systemTemp.createTemp();
    // Note: There might be a problem with tests changing the current working
    // directory.
    Directory.current = workingDir.path;

    await CouchbaseLiteDart.init(edition: Edition.enterprise);

    final db = await Database.openAsync('a');
    await db.close();

    final databaseFile = Directory(p.join(workingDir.path, 'a.cblite2'));
    expect(databaseFile.existsSync(), isTrue);
  });
}
