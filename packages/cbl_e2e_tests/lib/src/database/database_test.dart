import 'dart:async';

import 'package:cbl/cbl.dart';
import 'package:meta/meta.dart';

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
      dbName = testDbName('Database|Common');
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
        @isTest
        void matrixTest(
          String description,
          FutureOr<void> Function(bool async) fn,
        ) {
          void _test(bool async) {
            test('$description (variant: async: $async)', () => fn(async));
          }

          _test(true);
          _test(false);
        }

        SaveConflictHandler toSync(AsyncSaveConflictHandler handler) =>
            (documentBeingSaved, conflictingDocument) =>
                handler(documentBeingSaved, conflictingDocument) as bool;

        matrixTest('save updated document', (async) async {
          final doc = MutableDocument();
          db.saveDocument(doc);
          final updatedDoc = (db.document(doc.id)!.toMutable())
            ..setValue('b', key: 'a');
          db.saveDocument(updatedDoc);

          final AsyncSaveConflictHandler handler =
              expectAsync2((documentBeingSaved, conflictingDocument) {
            expect(documentBeingSaved, doc);
            expect(conflictingDocument, updatedDoc);
            documentBeingSaved.setValue('c', key: 'a');
            if (async) {
              return Future.value(true);
            }
            return true;
          });

          if (async) {
            await expectLater(
              db.saveDocumentWithConflictHandlerAsync(doc, handler),
              completion(isTrue),
            );
          } else {
            expect(
              db.saveDocumentWithConflictHandler(doc, toSync(handler)),
              isTrue,
            );
          }

          expect(doc.value('a'), 'c');
          expect(db.document(doc.id)!.value('a'), 'c');
        });

        matrixTest('save deleted document', (async) async {
          final doc = MutableDocument();
          db.saveDocument(doc);
          db.deleteDocument(db.document(doc.id)!);

          final AsyncSaveConflictHandler handler =
              expectAsync2((documentBeingSaved, conflictingDocument) {
            expect(documentBeingSaved, doc);
            expect(conflictingDocument, isNull);
            documentBeingSaved.setValue('c', key: 'a');
            if (async) {
              return Future.value(true);
            }
            return true;
          });

          if (async) {
            await expectLater(
              db.saveDocumentWithConflictHandlerAsync(doc, handler),
              completion(isTrue),
            );
          } else {
            expect(
              db.saveDocumentWithConflictHandler(doc, toSync(handler)),
              isTrue,
            );
          }

          expect(doc.value('a'), 'c');
          expect(db.document(doc.id)!.value('a'), 'c');
        });

        matrixTest('cancels save if handler returns false', (async) async {
          final doc = MutableDocument();
          db.saveDocument(doc);
          final updatedDoc = (db.document(doc.id)!.toMutable())
            ..setValue('b', key: 'a');
          db.saveDocument(updatedDoc);

          final AsyncSaveConflictHandler handler =
              expectAsync2((documentBeingSaved, conflictingDocument) {
            expect(documentBeingSaved, doc);
            expect(conflictingDocument, updatedDoc);
            if (async) {
              return Future.value(false);
            }
            return false;
          });

          if (async) {
            await expectLater(
              db.saveDocumentWithConflictHandlerAsync(doc, handler),
              completion(isFalse),
            );
          } else {
            expect(
              db.saveDocumentWithConflictHandler(doc, toSync(handler)),
              isFalse,
            );
          }
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
      test('createIndex should work with ValueIndexConfiguration', () {
        final db = openTestDb('CreateValueIndexConfiguration');
        db.createIndex('a', ValueIndexConfiguration(['a']));

        final q = Query(db, 'SELECT * FROM _ WHERE a = "a"');

        final explain = q.explain();

        expect(explain, contains('USING INDEX a'));
      });

      test('createIndex should work with FullTextIndexConfiguration', () {
        final db = openTestDb('CreateFullTextIndexConfiguration');
        db.createIndex('a', FullTextIndexConfiguration(['a']));

        final q = Query(db, "SELECT * FROM _ WHERE MATCH('a', 'query')");

        final explain = q.explain();

        expect(explain, contains('fts1 VIRTUAL TABLE INDEX'));
      });

      test('createIndex should work with ValueIndex', () {
        final db = openTestDb('CreateValueIndex');
        db.createIndex(
          'a',
          IndexBuilder.valueIndex([ValueIndexItem.property('a')]),
        );

        final q = Query(db, 'SELECT * FROM _ WHERE a = "a"');

        final explain = q.explain();

        expect(explain, contains('USING INDEX a'));
      });

      test('createIndex should work with FullTextIndex', () {
        final db = openTestDb('CreateFullTextIndex');
        db.createIndex(
          'a',
          IndexBuilder.fullTextIndex([FullTextIndexItem.property('a')]),
        );

        final q = Query(db, "SELECT * FROM _ WHERE MATCH('a', 'query')");

        final explain = q.explain();

        expect(explain, contains('fts1 VIRTUAL TABLE INDEX'));
      });

      test('deleteIndex should delete the given index', () {
        final db = openTestDb('DeleteIndex');
        db.createIndex('a', ValueIndexConfiguration(['a']));

        expect(db.indexes, ['a']);

        db.deleteIndex('a');

        expect(db.indexes, isEmpty);
      });

      test('indexes should return the names of all existing indexes', () {
        final db = openTestDb('DatabaseIndexNames');
        expect(db.indexes, isEmpty);

        db.createIndex('a', ValueIndexConfiguration(['a']));

        expect(db.indexes, ['a']);
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
          r'''
          SELECT dish, max(meal.date) AS last_used, count(meal._id) AS in_meals, meal 
          FROM _ AS dish
          JOIN _ AS meal ON array_contains(meal.dishes, dish._id)
          WHERE dish.type = "dish" AND meal.type = "meal"  AND meal.`group` = "fam"
          GROUP BY dish._id
          ORDER BY max(meal.date)
          ''',
        );

        print(q.explain());

        var resultSet = q.execute();

        for (final result in resultSet) {
          print(result);
        }
      });
    });
  });
}
