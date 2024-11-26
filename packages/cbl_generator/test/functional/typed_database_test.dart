import 'package:cbl/cbl.dart';
import 'package:test/test.dart';

import '../fixtures/builtin_types.dart';
import '../fixtures/document_meta_data.dart';
import '../fixtures/typed_database.cbl.database.g.dart';
import '../test_utils.dart';

void main() {
  setUpAll(initCouchbaseLiteForTest);

  test('load document', () {
    final db = DocWithIdDatabase.openSync('test');
    final collection = db.defaultCollection;
    addTearDown(db.delete);
    final doc = MutableDocWithId('a');
    collection.saveTypedDocument(doc).withConcurrencyControl();
    expect(collection.typedDocument<DocWithId>('b'), isNull);
    expect(collection.typedDocument<DocWithId>('a'), isNotNull);
    expect(collection.typedDocument<MutableDocWithId>('a'), isNotNull);
  });

  test('run typed query', () {
    final db = StringDictDatabase.openSync('test');
    addTearDown(db.delete);
    final doc = MutableDocument({'value': 'a'});
    db.defaultCollection.saveDocument(doc);

    final resultSet = db.createQuery('SELECT value FROM _').execute();
    final typedResults = resultSet.allTypedResults<StringDict>();
    expect(typedResults, hasLength(1));
    expect(typedResults.first.value, 'a');
  });
}
