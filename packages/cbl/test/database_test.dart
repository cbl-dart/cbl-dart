import 'package:cbl/cbl.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  testEnvironmentSetup();

  group('databaseExists', () {
    test('returns correct result', () async {
      expect(
        await cbl.databaseExists('XXX'),
        isFalse,
        reason: 'Database does not exist',
      );

      final dbName = testDbName('DatabaseExists');

      final db = await cbl.openDatabase(
        dbName,
        config: DatabaseConfiguration(directory: testTmpDir),
      );
      await db.close();

      expect(
        await cbl.databaseExists('$testTmpDir/$dbName'),
        isTrue,
        reason: 'Database does exist',
      );
    });

    test('works with inDirectory', () async {
      expect(
        await cbl.databaseExists(
          testDbName('DatabaseExistsWithDir'),
          directory: testTmpDir,
        ),
        isFalse,
      );
    });
  });

  group('openDatabase', () {
    test('throws when database does not exist', () {
      expect(
        cbl.openDatabase(
          testDbName('OpenNonExistingDatabase'),
          config: DatabaseConfiguration(
            directory: testTmpDir,
            flags: {},
          ),
        ),
        throwsA(isA<CouchbaseLiteException>().having(
          (e) => e.code,
          'code',
          equals(CouchbaseLiteErrorCode.notFound),
        )),
      );
    });
  });

  late String dbName;
  late DatabaseConfiguration dbConfig;
  late Database db;

  setUpAll(() async {
    dbName = testDbName('Common');
    dbConfig = DatabaseConfiguration(directory: testTmpDir);
    db = await cbl.openDatabase(dbName, config: dbConfig);
  });

  tearDownAll(() async {
    await db.close();
  });

  group('Database', () {
    test('name returns name of Database', () {
      expect(db.name, completion(equals(dbName)));
    });

    test('path returns full path of Database', () {
      expect(db.path, completion(equals('$testTmpDir/$dbName.cblite2/')));
    });

    test('config returns config of Database', () {
      expect(db.config, completion(equals(dbConfig)));
    });

    test('close does not throw', () async {
      final db = await cbl.openDatabase(
        testDbName('CloseDatabase'),
        config: dbConfig,
      );

      await db.close();
    });

    test('delete deletes the database file', () async {
      final name = testDbName('DeleteDatabase');
      final db = await cbl.openDatabase(name, config: dbConfig);

      await db.delete();

      expect(
        cbl.databaseExists(name, directory: dbConfig.directory),
        completion(isFalse),
      );
    });

    test('compact does not throw', () async {
      await db.compact();
    });

    test('batch operations do not throw', () async {
      await db.beginBatch();
      await db.saveDocument(MutableDocument());
      await db.endBatch();
    });

    test('getDocument returns null when the document does not exist', () async {
      expect(db.getDocument('x'), completion(isNull));
    });

    test('getDocument returns the document when it exist', () async {
      final doc = await db.saveDocument(MutableDocument());
      expect(db.getDocument(doc.id), completion(equals(doc)));
    });

    test('getMutableDocument returns null when the document does not exist',
        () async {
      expect(db.getMutableDocument('x'), completion(isNull));
    });

    test('getMutableDocument returns the document when it exist', () async {
      final doc = await db.saveDocument(MutableDocument());
      final result = await db.getMutableDocument(doc.id);
      expect(result!.id, equals(doc.id));
    });

    test('saveDocument saves the document', () async {
      final doc = MutableDocument()
        ..properties.addAll({
          'a': 'b',
          'c': 4,
        });

      final savedDoc = await db.saveDocument(doc);

      expect(savedDoc.properties, equals(doc.properties));
    });

    test('saveDocumentResolving invokes the callback on conflict', () async {
      final docToSave = await db.saveDocument(MutableDocument());
      final conflictDoc =
          await db.saveDocument(docToSave.mutableCopy()..properties['a'] = 'b');

      await db.saveDocumentResolving(
        docToSave.mutableCopy(),
        expectAsync2(
          (documentBeingSaved, conflictingDocument) async {
            expect(documentBeingSaved.sequence, equals(docToSave.sequence));
            expect(conflictingDocument?.sequence, equals(conflictDoc.sequence));

            return true;
          },
          count: 1,
          id: 'ConflictResolver',
        ),
      );
    });

    test('saveDocumentResolving cancels save if handler returns false',
        () async {
      final docToSave = await db.saveDocument(MutableDocument());
      await db.saveDocument(docToSave.mutableCopy()..properties['a'] = 'b');

      expect(
        db.saveDocumentResolving(
          docToSave.mutableCopy(),
          (documentBeingSaved, conflictingDocument) async => false,
        ),
        throwsA(isA<CouchbaseLiteException>().having(
          (it) => it.code,
          'code',
          equals(CouchbaseLiteErrorCode.conflict),
        )),
      );
    });

    test('purgeDocument purges a document by id', () async {
      final doc = await db.saveDocument(MutableDocument());

      await db.purgeDocumentById(doc.id);

      expect(db.getDocument(doc.id), completion(isNull));
    });

    test('getDocumentExpiration returns null if the document has no expiration',
        () async {
      final doc = await db.saveDocument(MutableDocument());

      expect(db.getDocumentExpiration(doc.id), completion(isNull));
    });

    test(
        'getDocumentExpiration returns the time of expiration if the document has one',
        () async {
      final expiration = DateTime.now().add(Duration(days: 1));
      final doc = await db.saveDocument(MutableDocument());

      await db.setDocumentExpiration(doc.id, expiration);

      final storedExpiration = await db.getDocumentExpiration(doc.id);

      expect(
        storedExpiration!.millisecondsSinceEpoch,
        equals(expiration.millisecondsSinceEpoch),
      );
    });

    test('setDocumentExpiration sets a new time of expiration', () async {
      final expiration = DateTime.now().add(Duration(days: 1));
      final doc = await db.saveDocument(MutableDocument());

      await db.setDocumentExpiration(doc.id, expiration);

      final storedExpiration = await db.getDocumentExpiration(doc.id);

      expect(
        storedExpiration!.millisecondsSinceEpoch,
        equals(expiration.millisecondsSinceEpoch),
      );
    });

    test('setDocumentExpiration sets the time of expiration to null', () async {
      final expiration = DateTime.now().add(Duration(days: 1));
      final doc = await db.saveDocument(MutableDocument());

      await db.setDocumentExpiration(doc.id, expiration);
      await db.setDocumentExpiration(doc.id, null);

      expect(db.getDocumentExpiration(doc.id), completion(isNull));
    });

    test('document change listener is called when the document changes',
        () async {
      final doc = MutableDocument();

      final listener = expectAsync2(
        (database, id) {
          expect(database, equals(db));
          expect(id, equals(doc.id));
        },
        count: 1,
        id: 'DocumentChangeListener',
        reason: 'The Document was changed while listener is registered',
      );

      await db.saveDocument(doc);
      await db.addDocumentChangeListener(doc.id, listener);
      await db.saveDocument(doc, concurrency: ConcurrencyControl.lastWriteWins);
      await db.removeDocumentChangeListener(listener);
      await db.saveDocument(doc, concurrency: ConcurrencyControl.lastWriteWins);
    });

    test('database change listener is called when a document changes',
        () async {
      final doc = MutableDocument();

      final listener = expectAsync2(
        (database, ids) {
          expect(database, equals(db));
          expect(ids, equals([doc.id]));
        },
        count: 1,
        id: 'DatabaseChangeListener',
        reason: 'Some Document was changed while listener is registered',
      );

      await db.addChangeListener(listener);
      await db.saveDocument(doc, concurrency: ConcurrencyControl.lastWriteWins);
      await db.removeChangeListener(listener);
      await db.saveDocument(doc, concurrency: ConcurrencyControl.lastWriteWins);
    });
  });

  group('Document', () {
    test('delete should remove document from the database', () async {
      final doc = await db.saveDocument(MutableDocument());
      await doc.delete();
      expect(db.getDocument(doc.id), completion(isNull));
    });

    test('purge should remove document from the database', () async {
      final doc = await db.saveDocument(MutableDocument());
      await doc.purge();
      expect(db.getDocument(doc.id), completion(isNull));
    });
  });

  group('Index', () {
    late Database db;

    setUp(() async {
      db = await cbl.openDatabase(
        testDbName('Index'),
        config: DatabaseConfiguration(directory: testTmpDir),
      );
    });

    tearDown(() => db.close());

    test('createIndex should work with ValueIndex', () async {
      await db.createIndex('a', ValueIndex('[[".a"]]'));

      final q = await db.query('SELECT * WHERE a = "a"');

      final explain = await q.explain();

      expect(explain, contains('USING INDEX a'));
    });

    test('createIndex should work with FullTextIndex', () async {
      await db.createIndex('a', FullTextIndex('[[".a"]]'));

      final q = await db.query('SELECT * WHERE "a" MATCH "query"');

      final explain = await q.explain();

      expect(explain, contains('["MATCH","a","query"]'));
    });

    test('deleteIndex should delete the given index', () async {
      await db.createIndex('a', ValueIndex('[[".a"]]'));

      expect(await db.indexNames(), equals(['a']));

      await db.deleteIndex('a');

      expect(await db.indexNames(), isEmpty);
    });

    test('indexNames should return the names of all existing indexes',
        () async {
      expect(await db.indexNames(), isEmpty);

      await db.createIndex('a', ValueIndex('[[".a"]]'));

      expect(db.indexNames(), completion(equals(['a'])));
    });
  });

  group('Query', () {
    late Database db;

    setUp(() async {
      db = await cbl.openDatabase(
        testDbName('Index'),
        config: DatabaseConfiguration(directory: testTmpDir),
      );
    });

    tearDown(() => db.close());

    test('(set/get)Parameters sets and gets the query parameters', () async {
      final q = await db.query('SELECT doc');

      final parameters = MutableDict()..addAll({'a': true});

      await q.setParameters(parameters);

      expect(q.getParameters(), completion(equals(parameters)));
    });

    test('execute does not throw', () async {
      final q = await db.query('SELECT doc');
      expect(q.execute(), completion(isEmpty));
    });

    test('explain returns the query plan explanation', () async {
      final q = await db.query('SELECT doc');
      final queryPlan = await q.explain();

      expect(
        queryPlan,
        allOf([
          contains('SCAN TABLE'),
          contains('{"WHAT":[[".doc"]]}'),
        ]),
      );
    });

    test('columCount returns correct count', () async {
      final q = await db.query('SELECT a');
      expect(q.columnCount, completion(equals(1)));
    });

    test('columnName returns correct name', () async {
      final q = await db.query('SELECT a');
      expect(q.columnName(0), completion(equals('a')));
    });

    test('listener is notified of changes', () async {
      final q = await db.query('SELECT a FROM a WHERE a.b = "c"');

      final doc = MutableDocument()..properties.addAll({'b': 'c'});
      final result = MutableDict()..addAll({'a': doc.properties});

      var callIndex = 0;

      final QueryChangeListener listener = expectAsync2(
        (query, resultSet) {
          switch (callIndex++) {
            // When listening for the first time the query is executed.
            case 0:
              expect(resultSet.asDicts.toList(), isEmpty);
              break;
            // This call is triggered by the doc save below.
            case 1:
              expect(resultSet.asDicts.toList(), equals([result]));
              break;
          }
        },
        count: 2,
      );

      addTearDown(() => q.removeChangeListener(listener));

      await q.addChangeListener(listener);

      // Wait a bit to ensure expected order. Query listeners run
      // asynchronously and need some time to execute the query for the first
      // time.
      await Future<void>.delayed(Duration(milliseconds: 50));

      await db.saveDocument(doc);
    });

    group('ResultSet', () {
      test('supports getting column by name', () async {
        final doc = MutableDocument('ResultSetColumnByName');
        await db.saveDocument(doc);

        final q = await db.query(r'SELECT META.id AS id WHERE META.id = $ID');
        await q.setParameters(MutableDict()..addAll({'ID': doc.id}));

        final resultSet = await q.execute();
        final iterator = resultSet.iterator..moveNext();
        expect(iterator['id'].asString, doc.id);
      });

      test('supports getting column by index', () async {
        final doc = MutableDocument('ResultSetColumnIndex');
        await db.saveDocument(doc);

        final q = await db.query(r'SELECT META.id WHERE META.id = $ID');
        await q.setParameters(MutableDict()..addAll({'ID': doc.id}));

        final resultSet = await q.execute();
        final iterator = resultSet.iterator..moveNext();
        expect(iterator[0].asString, doc.id);
      });
    });
  });

  group('Scenarios', () {
    test('open the same database twice', () async {
      final dbName = testDbName('OpenDbTwice');
      final dbA = await cbl.openDatabase(
        dbName,
        config: DatabaseConfiguration(directory: testTmpDir),
      );
      addTearDown(() => dbA.close());

      final dbB = await cbl.openDatabase(
        dbName,
        config: DatabaseConfiguration(directory: testTmpDir),
      );
      addTearDown(() => dbB.close());

      final doc = MutableDocument();

      await dbA.addChangeListener(expectAsync2((database, ids) {
        expect(ids, equals([doc.id]));
      }));

      await dbB.saveDocument(doc);
    });

    test('N1QL meal planner example', () async {
      await db.createIndex('date', ValueIndex('[".type"]'));
      await db.createIndex('group', ValueIndex('[".group"]'));

      final dish = await db.saveDocument(MutableDocument()
        ..properties.addAll({
          'type': 'dish',
          'title': 'Lasagna',
        }));

      await db.saveDocument(MutableDocument()
        ..properties.addAll({
          'type': 'meal',
          'dishes': MutableArray()..add(dish.id),
          'group': 'fam',
          'date': '2020-06-30',
        }));

      await db.saveDocument(MutableDocument()
        ..properties.addAll({
          'type': 'meal',
          'dishes': MutableArray()..add(dish.id),
          'group': 'fam',
          'date': '2021-01-15',
        }));

      final q = await db.query(
        r'''
        SELECT dish, max(meal.date) AS last_used, count(meal._id) AS in_meals, meal FROM dish
        JOIN meal ON array_contains(meal.dishes, dish._id)
        WHERE dish.type = "dish" AND meal.type = "meal"  AND meal.`group` = "fam"
        GROUP BY dish._id
        ORDER BY max(meal.date)
        '''
            .replaceAll('\n', ' '),
      );

      print(await q.explain());

      var resultSet = await q.execute();

      for (final result in resultSet.asDicts) {
        print(result);
      }
    });
  });
}
