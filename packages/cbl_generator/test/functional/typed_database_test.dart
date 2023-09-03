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
    addTearDown(db.delete);
    final doc = MutableDocWithId('a');
    db.saveTypedDocument(doc).withConcurrencyControl();
    expect(db.typedDocument<DocWithId>('b'), isNull);
    expect(db.typedDocument<DocWithId>('a'), isNotNull);
    expect(db.typedDocument<MutableDocWithId>('a'), isNotNull);
  });

  test('run typed query', () {
    final db = StringDictDatabase.openSync('test');
    addTearDown(db.delete);
    final doc = MutableDocument({'value': 'a'});
    db.defaultCollection.saveDocument(doc);

    final resultSet = Query.fromN1qlSync(db, 'SELECT value FROM _').execute();
    final typedResults = resultSet.allTypedResults<StringDict>();
    expect(typedResults, hasLength(1));
    expect(typedResults.first.value, 'a');
  });
}
