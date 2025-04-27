import 'package:cbl/cbl.dart';
import 'package:cbl/src/bindings.dart';
import 'package:cbl_flutter/cbl_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await CouchbaseLiteFlutter.init();
  });

  testWidgets('initialize and use Couchbase Lite', (tester) async {
    final db = await Database.openAsync('init-and-use-test');
    final collection = await db.defaultCollection;
    expect(db.name, 'init-and-use-test');

    final doc = MutableDocument({'message': 'Hello Couchbase Lite!'});
    await collection.saveDocument(doc);
    expect(doc.revisionId, isNotNull);
  });

  group('vector search', () {
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
  });
}
