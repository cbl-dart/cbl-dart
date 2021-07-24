import 'package:cbl/cbl.dart';
import 'package:rxdart/rxdart.dart';

import '../test_binding_impl.dart';
import 'test_binding.dart';
import 'utils/database_utils.dart';
import 'utils/matchers.dart';

void main() {
  setupTestBinding();

  group('Database', () {
    group('exists', () {
      test('works with inDirectory', () async {
        final dbName = testDbName('DatabaseExistsWithDir');

        expect(
          Database.exists(dbName, directory: tmpDir),
          isFalse,
        );

        final db = Database.open(
          dbName,
          config: DatabaseConfiguration(directory: tmpDir),
        );
        await db.close();

        expect(
          Database.exists(dbName, directory: tmpDir),
          isTrue,
        );
      });
    });

    group('open', () {
      test('creates database if it does not exist', () {
        final db = Database.open(
          testDbName('OpenNonExistingDatabase'),
          config: DatabaseConfiguration(
            directory: tmpDir,
          ),
        );

        expect(db.path, isDirectory);
      });
    });

    late String dbName;
    late DatabaseConfiguration dbConfig;
    late Database db;

    setUpAll(() {
      dbName = testDbName('Common');
      dbConfig = DatabaseConfiguration(directory: tmpDir);
      db = Database.open(dbName, config: dbConfig);
      addTearDown(db.close);
    });

    group('Database', () {
      test('name returns name of Database', () {
        expect(db.name, dbName);
      });

      test('path returns full path of Database', () {
        expect(db.path, '$tmpDir/$dbName.cblite2/');
      });

      test('config returns config of Database', () {
        expect(db.config, dbConfig);
      });

      test('close does not throw', () async {
        final db = Database.open(
          testDbName('CloseDatabase'),
          config: dbConfig,
        );

        await db.close();
      });

      test('delete deletes the database file', () async {
        final name = testDbName('DeleteDatabase');
        final db = Database.open(name, config: dbConfig);

        await db.delete();

        expect(
          Database.exists(name, directory: dbConfig.directory!),
          isFalse,
        );
      });

      test('performMaintenance: compact', () {
        db.performMaintenance(MaintenanceType.compact);
      });

      test('performMaintenance: reindex', () {
        final db = openTestDb('PerformMaintenance|Reindex');
        db.createIndex('a', ValueIndex('[".type"]'));
        final doc = MutableDocument({'type': 'A'});
        db.saveDocument(doc);
        db.performMaintenance(MaintenanceType.reindex);
      });

      test('performMaintenance: integrityCheck', () {
        db.performMaintenance(MaintenanceType.integrityCheck);
      });

      test('batch operations do not throw', () {
        db.beginBatch();
        db.saveDocument(MutableDocument());
        db.endBatch();
      });

      test('getDocument returns null when the document does not exist', () {
        expect(db.getDocument('x'), isNull);
      });

      test('getDocument returns the document when it exist', () {
        final doc = MutableDocument();
        db.saveDocument(doc);

        final loadedDoc = db.getDocument(doc.id);
        expect(loadedDoc, doc);
      });

      test('getMutableDocument returns null when the document does not exist',
          () {
        expect(db.getMutableDocument('x'), isNull);
      });

      test('getMutableDocument returns the document when it exist', () {
        final doc = MutableDocument();
        db.saveDocument(doc);
        final result = db.getMutableDocument(doc.id);
        expect(result!.id, doc.id);
      });

      test('saveDocument saves the document', () {
        final doc = MutableDocument({'a': 'b', 'c': 4});

        db.saveDocument(doc);
        final loadedDoc = db.getDocument(doc.id);

        expect(loadedDoc!.toPlainMap(), doc.toPlainMap());
      });

      test('saveDocumentResolving invokes the callback on conflict', () {
        final versionA = MutableDocument();
        db.saveDocument(versionA);
        final versionB = (db.getMutableDocument(versionA.id))!
          ..setValue('b', key: 'a');
        db.saveDocument(versionB);

        db.saveDocumentResolving(
          versionA.toMutable(),
          expectAsync2((documentBeingSaved, conflictingDocument) {
            expect(documentBeingSaved, versionA);
            expect(conflictingDocument, versionB);
            return true;
          }),
        );
      });

      test('saveDocumentResolving cancels save if handler returns false', () {
        final versionA = MutableDocument();
        db.saveDocument(versionA);
        final versionB = (db.getMutableDocument(versionA.id))!
          ..setValue('b', key: 'a');
        db.saveDocument(versionB);

        expect(
          () => db.saveDocumentResolving(
            versionA.toMutable(),
            expectAsync2((documentBeingSaved, conflictingDocument) {
              expect(documentBeingSaved, versionA);
              expect(conflictingDocument, versionB);
              return false;
            }),
          ),
          throwsA(isA<CouchbaseLiteException>().having(
            (it) => it.code,
            'code',
            CouchbaseLiteErrorCode.conflict,
          )),
        );
      });

      test('deleteDocument should remove document from the database', () {
        final doc = MutableDocument();
        db.saveDocument(doc);
        db.deleteDocument(doc);
        expect(db.getDocument(doc.id), isNull);
      });

      test('purgeDocumentById purges a document by id', () {
        final doc = MutableDocument();
        db.saveDocument(doc);

        db.purgeDocumentById(doc.id);

        expect(db.getDocument(doc.id), isNull);
      });

      test(
          'getDocumentExpiration returns null if the document has no expiration',
          () {
        final doc = MutableDocument();
        db.saveDocument(doc);

        expect(db.getDocumentExpiration(doc.id), isNull);
      });

      test(
          'getDocumentExpiration returns the time of expiration if the document has one',
          () {
        final expiration = DateTime.now().add(Duration(days: 1));
        final doc = MutableDocument();
        db.saveDocument(doc);

        db.setDocumentExpiration(doc.id, expiration);

        final storedExpiration = db.getDocumentExpiration(doc.id);

        expect(
          storedExpiration!.millisecondsSinceEpoch,
          expiration.millisecondsSinceEpoch,
        );
      });

      test('setDocumentExpiration sets a new time of expiration', () {
        final expiration = DateTime.now().add(Duration(days: 1));
        final doc = MutableDocument();
        db.saveDocument(doc);

        db.setDocumentExpiration(doc.id, expiration);

        final storedExpiration = db.getDocumentExpiration(doc.id);

        expect(
          storedExpiration!.millisecondsSinceEpoch,
          expiration.millisecondsSinceEpoch,
        );
      });

      test('setDocumentExpiration sets the time of expiration to null', () {
        final expiration = DateTime.now().add(Duration(days: 1));
        final doc = MutableDocument();
        db.saveDocument(doc);

        db.setDocumentExpiration(doc.id, expiration);
        db.setDocumentExpiration(doc.id, null);

        expect(db.getDocumentExpiration(doc.id), isNull);
      });

      test('document change listener is called when the document changes', () {
        final doc = MutableDocument();

        expect(
          db.changesOfDocument(doc.id),
          emitsInOrder(<dynamic>[null]),
        );

        db.saveDocument(doc);
      });

      test('database change listener is called when a document changes', () {
        final doc = MutableDocument();

        expect(
          db.changesOfAllDocuments(),
          emitsInOrder(<dynamic>[
            [doc.id]
          ]),
        );

        db.saveDocument(doc);
      });
    });

    group('Document', () {
      test("id returns the document's id", () {
        final doc = MutableDocument.withId('a');

        expect(doc.id, 'a');
      });

      test('revisionId returns `null` when the document is new', () {
        final doc = MutableDocument();

        expect(doc.revisionId, isNull);
      });

      test('revisionId returns string when document has been saved', () {
        final doc = MutableDocument();
        db.saveDocument(doc);

        expect(doc.revisionId, '1-581ad726ee407c8376fc94aad966051d013893c4');
      });

      test('sequence returns the documents sequence', () {
        final doc = MutableDocument();
        db.saveDocument(doc);

        expect(doc.sequence, isPositive);
      });

      test('toMap returns the documents properties', () {
        final props = {'a': 'b'};
        final doc = MutableDocument(props);

        expect(doc.toPlainMap(), props);
      });

      test('toMutable() returns a mutable copy of the document', () {
        final doc = MutableDocument({'a': 'b'});
        db.saveDocument(doc);

        expect(
          doc.toMutable(),
          isA<MutableDocument>().having(
            (it) => it.toPlainMap(),
            'toMap()',
            doc.toPlainMap(),
          ),
        );
      });
    });

    group('MutableDocument', () {
      test('supports specifying an id', () {
        final doc = MutableDocument.withId('id');

        expect(doc.id, 'id');
      });

      test('supports generating an id', () {
        final doc = MutableDocument();

        expect(doc.id, isNotEmpty);
      });
    });

    group('Index', () {
      late Database db;

      setUp(() {
        db = openTestDb('Index');
      });

      test('createIndex should work with ValueIndex', () {
        db.createIndex('a', ValueIndex('[[".a"]]'));

        final q = db.query(N1QLQuery('SELECT * WHERE a = "a"'));

        final explain = q.explain();

        expect(explain, contains('USING INDEX a'));
      });

      test('createIndex should work with FullTextIndex', () {
        db.createIndex('a', FullTextIndex('[[".a"]]'));

        final q = db.query(N1QLQuery(
          "SELECT * WHERE MATCH('a', 'query')",
        ));

        final explain = q.explain();

        expect(explain, contains('["MATCH()","a","query"]'));
      });

      test('deleteIndex should delete the given index', () {
        db.createIndex('a', ValueIndex('[[".a"]]'));

        expect(db.indexNames(), ['a']);

        db.deleteIndex('a');

        expect(db.indexNames(), isEmpty);
      });

      test('indexNames should return the names of all existing indexes', () {
        expect(db.indexNames(), isEmpty);

        db.createIndex('a', ValueIndex('[[".a"]]'));

        expect(db.indexNames(), ['a']);
      });
    });

    group('Query', () {
      late Database db;

      setUp(() {
        db = openTestDb('Query');
      });

      test('execute query with parameters', () {
        final q = db.query(N1QLQuery(r'SELECT doc WHERE META().id = $ID'));
        db.saveDocument(MutableDocument.withId('A'));

        q.parameters.setValue('A', name: 'ID');
        expect((q.execute()), isNotEmpty);

        q.parameters.setValue('B', name: 'ID');
        expect((q.execute()), isEmpty);
      });

      test('listen to query with parameters', () async {
        final q = db.query(N1QLQuery(r'SELECT doc WHERE META().id = $ID'));
        db.saveDocument(MutableDocument.withId('A'));

        q.parameters.setValue('A', name: 'ID');
        expect((await q.changes().first), isNotEmpty);

        q.parameters.setValue('B', name: 'ID');
        expect((await q.changes().first), isEmpty);
      });

      test('execute does not throw', () async {
        final q = db.query(N1QLQuery('SELECT doc'));
        expect(q.execute(), isEmpty);
      });

      test('explain returns the query plan explanation', () {
        final q = db.query(N1QLQuery('SELECT doc'));
        final queryPlan = q.explain();

        expect(
          queryPlan,
          allOf([
            contains('SCAN TABLE'),
            contains('{"WHAT":[[".doc"]]}'),
          ]),
        );
      });

      test('columCount returns correct count', () {
        final q = db.query(N1QLQuery('SELECT a'));
        expect(q.columnCount(), 1);
      });

      test('columnName returns correct name', () {
        final q = db.query(N1QLQuery('SELECT a'));
        expect(q.columnName(0), 'a');
      });

      test('listener is notified of changes', () {
        final q = db.query(N1QLQuery(
          'SELECT a FROM _default AS a WHERE a.b = "c"',
        ));

        final doc = MutableDocument({'b': 'c'});
        final result = {'a': doc.toPlainMap()};
        final stream = q
            .changes()
            .map((resultSet) => resultSet.asDictionaries
                .map((dict) => dict.toPlainMap())
                .toList())
            .shareReplay();

        // ignore: unawaited_futures
        stream.first.then((_) => db.saveDocument(doc));

        expect(
          stream,
          emitsInOrder(<dynamic>[
            isEmpty,
            [result],
          ]),
        );
      });

      test('bad query: error position highlighting', () {
        expect(
          () => db.query(N1QLQuery('SELECT foo()')),
          throwsA(isA<CouchbaseLiteException>().having(
            (it) => it.toString(),
            'toString()',
            '''
CouchbaseLiteException(message: query syntax error, code: CouchbaseLiteErrorCode.invalidQuery)
SELECT foo()
          ^
''',
          )),
        );
      });

      group('ResultSet', () {
        // TODO: fix bug which prevents id from being used an alias
        // The test uses id_ as a workaround.
        // https://github.com/couchbase/couchbase-lite-C/issues/149
        test('supports getting column by name', () async {
          final doc = MutableDocument.withId('ResultSetColumnByName');
          db.saveDocument(doc);

          final q = db.query(
              N1QLQuery(r'SELECT META().id AS id_ WHERE META().id = $ID'));
          q.parameters.setString(doc.id, name: 'ID');

          final resultSet = q.execute();
          final iterator = resultSet.iterator..moveNext();
          expect(iterator.current['id_'] as String, doc.id);
        });

        test('supports getting column by index', () async {
          final doc = MutableDocument.withId('ResultSetColumnIndex');
          db.saveDocument(doc);

          final q =
              db.query(N1QLQuery(r'SELECT META().id WHERE META().id = $ID'));
          q.parameters.setString(doc.id, name: 'ID');

          final resultSet = q.execute();
          final iterator = resultSet.iterator..moveNext();
          expect(iterator.current[0] as String, doc.id);
        });
      });
    });

    group('Scenarios', () {
      test('open the same database twice and receive change notifications',
          () async {
        final dbName = testDbName('OpenDbTwice');
        final dbA = openTestDb(dbName, useNameDirectly: true);
        final dbB = openTestDb(dbName, useNameDirectly: true);
        final doc = MutableDocument();

        expect(
          dbA.changesOfAllDocuments(),
          emitsInOrder(<dynamic>[
            [doc.id]
          ]),
        );

        // Streams such as `changesOfAllDocuments` are doing async work
        // when being listened to. That means we cannot assume the stream
        // is fully setup and will see changes at this point. In the context
        // of a single database this usually does not matter because all
        // resources related to that database share a single worker. A worker
        // behaves like a queue, so once a stream has been listened to, its
        // request to the worker will be handled before all other requests which
        // could affect it. In this case there are two database and two workers
        // handling requests in parallel. To prevent the doc from being saved
        // before the stream is ready, we wait a few milliseconds.
        // TODO: when streams expose a method to wait until they are fully
        // ready use that instead of this workaround
        await Future<void>.delayed(Duration(milliseconds: 50));

        dbB.saveDocument(doc);
      });

      test('N1QL meal planner example', () {
        db.createIndex('date', ValueIndex('[".type"]'));
        db.createIndex('group_index', ValueIndex('[".group"]'));

        final dish = MutableDocument({
          'type': 'dish',
          'title': 'Lasagna',
        });
        db.saveDocument(dish);

        db.saveDocument(MutableDocument({
          'type': 'meal',
          'dishes': [dish.id],
          'group': 'fam',
          'date': '2020-06-30',
        }));

        db.saveDocument(MutableDocument({
          'type': 'meal',
          'dishes': [dish.id],
          'group': 'fam',
          'date': '2021-01-15',
        }));

        final q = db.query(N1QLQuery(
          r'''
          SELECT dish, max(meal.date) AS last_used, count(meal._id) AS in_meals, meal 
          FROM _default AS dish
          JOIN _default AS meal ON array_contains(meal.dishes, dish._id)
          WHERE dish.type = "dish" AND meal.type = "meal"  AND meal.`group` = "fam"
          GROUP BY dish._id
          ORDER BY max(meal.date)
          ''',
        ));

        print(q.explain());

        var resultSet = q.execute();

        for (final result in resultSet.asDictionaries) {
          print(result);
        }
      });
    });
  });
}
