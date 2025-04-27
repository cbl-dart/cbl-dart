import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/bindings.dart';
import 'package:cbl_dart/cbl_dart.dart';
import 'package:test/test.dart';

void main() async {
  setUpAll(() async {
    final filesDir = await Directory.systemTemp.createTemp();
    await CouchbaseLiteDart.init(
      edition: Edition.enterprise,
      filesDir: filesDir.path,
    );
  });

  test('find vector search library', () async {
    expect(CBLBindings.instance.libraries.vectorSearchLibraryPath, isNotNull);
  });

  test('create vector search index', () async {
    final db = await Database.openAsync('vector_search_index_test');
    addTearDown(db.delete);

    final collection = await db.defaultCollection;

    await collection.createIndex(
      'a',
      VectorIndexConfiguration('a', dimensions: 2, centroids: 1),
    );

    expect(await collection.indexes, ['a']);
  });
}
