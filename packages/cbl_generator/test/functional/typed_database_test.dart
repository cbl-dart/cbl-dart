import 'package:cbl/cbl.dart';
import 'package:test/test.dart';

import '../fixtures/app_database.cbl.database.g.dart';
import '../fixtures/builtin_types.dart';
import '../fixtures/document_meta_data.dart';
import '../fixtures/typed_database.cbl.database.g.dart';
import '../fixtures/user.dart';
import '../test_utils.dart';

void main() {
  setUpAll(configureCouchbaseLiteForTest);

  test('load document', () {
    final db = DocWithIdDatabase.openSync('test');
    final collection = db.defaultCollection;
    addTearDown(db.delete);
    final doc = MutableDocWithId('a');
    collection.saveTypedDocument(doc).withConcurrencyControl();
    expect(collection.typedDocument<DocWithIdDocument>('b'), isNull);
    expect(collection.typedDocument<DocWithIdDocument>('a'), isNotNull);
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

  test('default type matcher value is the annotated class name', () {
    final db = AppDatabase.openSync('test');
    addTearDown(db.delete);
    final collection = db.defaultCollection;

    final user = MutableUser(
      name: PersonalName(first: 'Alice', last: 'Green'),
      username: 'ali',
      createdAt: DateTime.utc(2026),
    );
    collection.saveTypedDocument(user).withConcurrencyControl();
    expect(collection.document(user.id)!.string('type'), 'User');

    // A document written by cbl_generator 0.3, which used the annotated class
    // name as the type value, too.
    collection.saveDocument(
      MutableDocument(id: 'existing', {
        'type': 'User',
        'name': {'first': 'Bob', 'last': 'Brown'},
        'username': 'bob',
        'createdAt': DateTime.utc(2025).toIso8601String(),
      }),
    );
    expect(collection.typedDocument<UserDocument>('existing')!.username, 'bob');
  });
}
