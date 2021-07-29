import 'dart:async';

import 'package:cbl/cbl.dart';
import 'package:rxdart/rxdart.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/database_utils.dart';
import '../utils/matchers.dart';

void main() {
  setupTestBinding();

  group('Database', () {
    test('remove', () async {
      final db = openTestDb('Remove');
      final name = db.name;
      final directory = db.config.directory;
      await db.close();

      expect(Database.exists(name, directory: directory), isTrue);

      Database.remove(name, directory: directory);

      expect(Database.exists(name, directory: directory), isFalse);
    });

    test('exists', () async {
      final dbName = testDbName('DatabaseExistsWithDir');

      expect(
        Database.exists(dbName, directory: tmpDir),
        isFalse,
      );

      final db = Database(dbName, DatabaseConfiguration(directory: tmpDir));
      await db.close();

      expect(Database.exists(dbName, directory: tmpDir), isTrue);
    });

    test('copy', () {
      final db = openTestDb('Copy-Source');
      final copyName = testDbName('Copy-Copy');

      Database.copy(
        from: db.path!,
        name: copyName,
        configuration: DatabaseConfiguration(directory: tmpDir),
      );

      expect(Database.exists(copyName, directory: tmpDir), isTrue);
    });

    test('creates database if it does not exist', () {
      final db = Database(
        testDbName('OpenNonExistingDatabase'),
        DatabaseConfiguration(
          directory: tmpDir,
        ),
      );

      expect(db.path, isDirectory);
    });

    late String dbName;
    late DatabaseConfiguration dbConfig;
    late Database db;

    setUpAll(() {
      dbName = testDbName('Common');
      dbConfig = DatabaseConfiguration(directory: tmpDir);
      db = Database(dbName, dbConfig);
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
        final db = Database(testDbName('CloseDatabase'), dbConfig);

        await db.close();
      });

      test('delete deletes the database file', () async {
        final name = testDbName('DeleteDatabase');
        final db = Database(name, dbConfig);

        await db.delete();

        expect(
          Database.exists(name, directory: dbConfig.directory),
          isFalse,
        );
      });

      test('performMaintenance: compact', () {
        db.performMaintenance(MaintenanceType.compact);
      });

      test('performMaintenance: reindex', () {
        final db = openTestDb('PerformMaintenance|Reindex');
        db.createIndex('a', ValueIndexConfiguration(['type']));
        final doc = MutableDocument({'type': 'A'});
        db.saveDocument(doc);
        db.performMaintenance(MaintenanceType.reindex);
      });

      test('performMaintenance: integrityCheck', () {
        db.performMaintenance(MaintenanceType.integrityCheck);
      });

      test('batch operations do not throw', () {
        db.inBatch(() {
          db.saveDocument(MutableDocument());
        });
      });

      test('document returns null when the document does not exist', () {
        expect(db.document('x'), isNull);
      });

      test('document returns the document when it exist', () {
        final doc = MutableDocument();
        db.saveDocument(doc);

        final loadedDoc = db.document(doc.id);
        expect(loadedDoc, doc);
      });

      test('saveDocument saves the document', () {
        final doc = MutableDocument({'a': 'b', 'c': 4});

        db.saveDocument(doc);
        final loadedDoc = db.document(doc.id);

        expect(loadedDoc!.toPlainMap(), doc.toPlainMap());
      });

      group('saveDocumentWithConflictHandler', () {
        test('invokes the callback on conflict', () {
          final versionA = MutableDocument();
          db.saveDocument(versionA);
          final versionB = (db.document(versionA.id)!.toMutable())
            ..setValue('b', key: 'a');
          db.saveDocument(versionB);

          db.saveDocumentWithConflictHandler(
            versionA.toMutable(),
            expectAsync2((documentBeingSaved, conflictingDocument) {
              expect(documentBeingSaved, versionA);
              expect(conflictingDocument, versionB);
              return true;
            }),
          );
        });

        test('cancels save if handler returns false', () {
          final versionA = MutableDocument();
          db.saveDocument(versionA);
          final versionB = (db.document(versionA.id)!.toMutable())
            ..setValue('b', key: 'a');
          db.saveDocument(versionB);

          expect(
            db.saveDocumentWithConflictHandler(
              versionA.toMutable(),
              expectAsync2((documentBeingSaved, conflictingDocument) {
                expect(documentBeingSaved, versionA);
                expect(conflictingDocument, versionB);
                return false;
              }),
            ),
            isFalse,
          );
        });

        test('handler exceptions are unhandled in current zone', () {
          final versionA = MutableDocument();
          db.saveDocument(versionA);
          final versionB = (db.document(versionA.id)!.toMutable())
            ..setValue('b', key: 'a');
          db.saveDocument(versionB);

          runZonedGuarded(() {
            db.saveDocumentWithConflictHandler(
              versionA.toMutable(),
              (documentBeingSaved, conflictingDocument) {
                throw false;
              },
            );
          }, expectAsync2((error, __) {
            expect(error, isFalse);
          }));
        });
      });

      test('deleteDocument should remove document from the database', () {
        final doc = MutableDocument();
        db.saveDocument(doc);
        db.deleteDocument(doc);
        expect(db.document(doc.id), isNull);
      });

      test('purgeDocumentById purges a document by id', () {
        final doc = MutableDocument();
        db.saveDocument(doc);

        db.purgeDocumentById(doc.id);

        expect(db.document(doc.id), isNull);
      });

      group('getDocumentExpiration', () {
        test('returns null if the document has no expiration', () {
          final doc = MutableDocument();
          db.saveDocument(doc);

          expect(db.getDocumentExpiration(doc.id), isNull);
        });

        test('returns the time of expiration if the document has one', () {
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
      });

      group('setDocumentExpiration', () {
        test('sets a new time of expiration', () {
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

        test('sets the time of expiration to null', () {
          final expiration = DateTime.now().add(Duration(days: 1));
          final doc = MutableDocument();
          db.saveDocument(doc);

          db.setDocumentExpiration(doc.id, expiration);
          db.setDocumentExpiration(doc.id, null);

          expect(db.getDocumentExpiration(doc.id), isNull);
        });
      });

      test('document change listener is called when the document changes', () {
        final doc = MutableDocument();

        expect(
          db.documentChanges(doc.id),
          emitsInOrder(<dynamic>[DocumentChange(db, doc.id)]),
        );

        db.saveDocument(doc);
      });

      test('database change listener is called when a document changes', () {
        final doc = MutableDocument();

        expect(
          db.changes(),
          emitsInOrder(<dynamic>[
            DatabaseChange(db, [doc.id])
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

      test('toPlainMap returns the documents properties', () {
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

      test('createIndex should work with ValueIndexConfiguration', () {
        db.createIndex('a', ValueIndexConfiguration(['a']));

        final q = Query(db, N1QLQuery('SELECT * FROM _ WHERE a = "a"'));

        final explain = q.explain();

        expect(explain, contains('USING INDEX a'));
      });

      test('createIndex should work with FullTextIndexConfiguration', () {
        db.createIndex('a', FullTextIndexConfiguration(['a']));

        final q =
            Query(db, N1QLQuery("SELECT * FROM _ WHERE MATCH('a', 'query')"));

        final explain = q.explain();

        expect(explain, contains('["MATCH()","a","query"]'));
      });

      test('deleteIndex should delete the given index', () {
        db.createIndex('a', ValueIndexConfiguration(['a']));

        expect(db.indexes, ['a']);

        db.deleteIndex('a');

        expect(db.indexes, isEmpty);
      });

      test('indexes should return the names of all existing indexes', () {
        expect(db.indexes, isEmpty);

        db.createIndex('a', ValueIndexConfiguration(['a']));

        expect(db.indexes, ['a']);
      });
    });

    group('Query', () {
      late Database db;

      setUp(() {
        db = openTestDb('Query');
      });

      test('execute query with parameters', () {
        final q =
            Query(db, N1QLQuery(r'SELECT doc FROM _ WHERE META().id = $ID'));
        db.saveDocument(MutableDocument.withId('A'));

        q.parameters.setValue('A', name: 'ID');
        expect((q.execute()), isNotEmpty);

        q.parameters.setValue('B', name: 'ID');
        expect((q.execute()), isEmpty);
      });

      test('listen to query with parameters', () async {
        final q =
            Query(db, N1QLQuery(r'SELECT doc FROM _ WHERE META().id = $ID'));
        db.saveDocument(MutableDocument.withId('A'));

        q.parameters.setValue('A', name: 'ID');
        expect((await q.changes().first), isNotEmpty);

        q.parameters.setValue('B', name: 'ID');
        expect((await q.changes().first), isEmpty);
      });

      test('execute does not throw', () async {
        final q = Query(db, N1QLQuery('SELECT doc FROM _'));
        expect(q.execute(), isEmpty);
      });

      test('explain returns the query plan explanation', () {
        final q = Query(db, N1QLQuery('SELECT doc FROM _'));
        final queryPlan = q.explain();

        expect(
          queryPlan,
          allOf([
            contains('SCAN TABLE'),
            contains('{"FROM":[{"COLLECTION":"_"}],"WHAT":[[".doc"]]}'),
          ]),
        );
      });

      test('columCount returns correct count', () {
        final q = Query(db, N1QLQuery('SELECT a FROM _'));
        expect(q.columnCount(), 1);
      });

      test('columnName returns correct name', () {
        final q = Query(db, N1QLQuery('SELECT a FROM _'));
        expect(q.columnName(0), 'a');
      });

      test('listener is notified of changes', () {
        final q = Query(db, N1QLQuery('SELECT a FROM _ AS a WHERE a.b = "c"'));

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
          () => Query(db, N1QLQuery('SELECT foo()')),
          throwsA(isA<DatabaseException>().having(
            (it) => it.toString(),
            'toString()',
            '''
DatabaseException(query syntax error, code: invalidQuery)
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

          final q = Query(
            db,
            N1QLQuery(r'SELECT META().id AS id_ FROM _ WHERE META().id = $ID'),
          );
          q.parameters.setString(doc.id, name: 'ID');

          final resultSet = q.execute();
          final iterator = resultSet.iterator..moveNext();
          expect(iterator.current['id_'] as String, doc.id);
        });

        test('supports getting column by index', () async {
          final doc = MutableDocument.withId('ResultSetColumnIndex');
          db.saveDocument(doc);

          final q = Query(
              db, N1QLQuery(r'SELECT META().id FROM _ WHERE META().id = $ID'));
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
          dbA.changes(),
          emitsInOrder(<dynamic>[
            DatabaseChange(dbA, [doc.id])
          ]),
        );

        dbB.saveDocument(doc);
      });

      test('N1QL meal planner example', () {
        db.createIndex('date', ValueIndexConfiguration(['type']));
        db.createIndex('group_index', ValueIndexConfiguration(['`group`']));

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

        final q = Query(
          db,
          N1QLQuery(
            r'''
            SELECT dish, max(meal.date) AS last_used, count(meal._id) AS in_meals, meal 
            FROM _ AS dish
            JOIN _ AS meal ON array_contains(meal.dishes, dish._id)
            WHERE dish.type = "dish" AND meal.type = "meal"  AND meal.`group` = "fam"
            GROUP BY dish._id
            ORDER BY max(meal.date)
            ''',
          ),
        );

        print(q.explain());

        var resultSet = q.execute();

        for (final result in resultSet.asDictionaries) {
          print(result);
        }
      });
    });
  });
}
