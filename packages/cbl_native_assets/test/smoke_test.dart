import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl_native_assets/cbl_native_assets.dart';
import 'package:test/test.dart';

void main() async {
  await CouchbaseLiteNativeAssets.init();

  test('open db', () async {
    final tempDir = await Directory.systemTemp.createTemp();
    addTearDown(() => tempDir.delete(recursive: true));

    final config = DatabaseConfiguration(directory: tempDir.path);
    final db = await Database.openAsync('test', config);
    await db.close();
  });
}
