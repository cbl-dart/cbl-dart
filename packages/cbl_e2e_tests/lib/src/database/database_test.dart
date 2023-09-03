// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/support/utils.dart';
import 'package:path/path.dart' as p;

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/api_variant.dart';
import '../utils/database_utils.dart';
import '../utils/encryption.dart';
import '../utils/matchers.dart';

void main() {
  setupTestBinding();

  group('Database', () {
    apiTest('remove', () async {
      final db = await openTestDatabase(tearDown: false);
      final name = db.name;
      final directory = db.config.directory;
      await db.close();

      expect(await databaseExists(name, directory: directory), isTrue);

      await removeDatabase(name, directory: directory);

      expect(await databaseExists(name, directory: directory), isFalse);
    });

    apiTest('exists', () async {
      const name = 'a';
      final directory = databaseDirectoryForTest();

      expect(await databaseExists(name, directory: directory), isFalse);

      await openTestDatabase(name: name);

      expect(await databaseExists(name, directory: directory), isTrue);
    });

    apiTest('copy', () async {
      final source = await openTestDatabase();
      final directory = databaseDirectoryForTest();

      await copyDatabase(
        from: source.path!,
        name: 'copy',
        config: DatabaseConfiguration(directory: directory),
      );

      expect(await databaseExists('copy', directory: directory), isTrue);
    });

    apiTest('copy without trailing path separator in from path', () async {
      // https://github.com/cbl-dart/cbl-dart/issues/444
      final source = await openTestDatabase();
      final directory = databaseDirectoryForTest();

      expect(source.path, endsWith(p.separator));

      await copyDatabase(
        from: source.path!.substring(0, source.path!.length - 1),
        name: 'copy',
        config: DatabaseConfiguration(directory: directory),
      );

      expect(await databaseExists('copy', directory: directory), isTrue);
    });

    apiTest('open in default directory', () async {
      final name = createUuid();
      final defaultConfig = DatabaseConfiguration();

      final db = await runWithApi(
        sync: () => Database.openSync(name),
        async: () => Database.openAsync(name),
      );
      addTearDown(db.delete);

      expect(db.path, startsWith(defaultConfig.directory));
    });

    group('Database', () {
      apiTest('config', () async {
        final config =
            DatabaseConfiguration(directory: databaseDirectoryForTest());
        final db = await openTestDatabase(config: config);

        expect(db.name, 'db');
        expect(
          db.path,
          [databaseDirectoryForTest(), 'db.cblite2', '']
              .join(Platform.pathSeparator),
        );
        expect(db.config, config);
      });

      apiTest('count', () async {
        final db = await openTestDatabase();

        expect(await db.count, 0);

        await db.saveDocument(MutableDocument());

        expect(await db.count, 1);
      });

      apiTest('document fragment', () async {
        final db = await openTestDatabase();

        expect((await db['a']).exists, isFalse);

        await db.saveDocument(MutableDocument.withId('a'));

        expect((await db['a']).exists, isTrue);
      });

      apiTest('close', () async {
        final db = await openTestDatabase();
        await db.close();
      });

      apiTest('delete', () async {
        final db = await openTestDatabase();

        await db.delete();

        expect(
          await databaseExists(
            'default',
            directory: db.config.directory,
          ),
          isFalse,
        );
      });

      apiTest('performMaintenance: compact', () async {
        final db = await openTestDatabase();
        await db.performMaintenance(MaintenanceType.compact);
      });

      apiTest('performMaintenance: reindex', () async {
        final db = await openTestDatabase();
        await db.createIndex('a', ValueIndexConfiguration(['type']));

        final doc = MutableDocument({'type': 'A'});
        await db.saveDocument(doc);
        await db.performMaintenance(MaintenanceType.reindex);
      });

      apiTest('performMaintenance: integrityCheck', () async {
        final db = await openTestDatabase();
        await db.performMaintenance(MaintenanceType.integrityCheck);
      });

      apiTest('changeEncryptionKey: encrypt database', () async {
        final key = EncryptionKey.key(randomRawEncryptionKey());
        final db = await openTestDatabase();

        await db.changeEncryptionKey(key);

        expect(Future(openTestDatabase), throwsNotADatabaseFile);
      });

      apiTest('changeEncryptionKey: decrypt database', () async {
        final key = EncryptionKey.key(randomRawEncryptionKey());
        final db = await openTestDatabase(
          config: DatabaseConfiguration(
            directory: databaseDirectoryForTest(),
            encryptionKey: key,
          ),
        );

        await expectLater(
          Future(openTestDatabase),
          throwsNotADatabaseFile,
        );

        await db.changeEncryptionKey(null);

        expect(Future(openTestDatabase), completes);
      });

      apiTest('changeEncryptionKey: change key', () async {
        final keyA = EncryptionKey.key(randomRawEncryptionKey());
        final keyB = EncryptionKey.key(randomRawEncryptionKey());
        final db = await openTestDatabase(
          config: DatabaseConfiguration(
            directory: databaseDirectoryForTest(),
            encryptionKey: keyA,
          ),
        );

        await db.changeEncryptionKey(keyB);

        expect(
          Future(() => openTestDatabase(
                config: DatabaseConfiguration(
                  directory: databaseDirectoryForTest(),
                  encryptionKey: keyA,
                ),
              )),
          throwsNotADatabaseFile,
        );
      });

      apiTest('inBatch commits transaction', () async {
        final db = await openTestDatabase();

        final doc = MutableDocument();

        await runWithApi(
          sync: () => (db as SyncDatabase).inBatchSync(() {
            db.saveDocument(doc);
          }),
          async: () => (db as AsyncDatabase).inBatch(() async {
            await db.saveDocument(doc);
          }),
        );

        expect(await db.document(doc.id), isNotNull);
      });

      apiTest('inBatch aborts transaction when callback throws', () async {
        final db = await openTestDatabase();

        final doc = MutableDocument();

        await runWithApi(
          sync: () => expect(
            () => (db as SyncDatabase).inBatchSync(() {
              db.saveDocument(doc);
              throw Exception();
            }),
            throwsA(isException),
          ),
          async: () => expectLater(
            (db as AsyncDatabase).inBatch(() async {
              await db.saveDocument(doc);
              throw Exception();
            }),
            throwsA(isException),
          ),
        );

        expect(await db.document(doc.id), isNull);
      });

      apiTest('inBatch throws when called recursively', () async {
        final db = await openTestDatabase();

        expect(
          Future.sync(() => db.inBatch(() => db.inBatch(() {}))),
          throwsA(isA<DatabaseException>()),
        );
      });

      apiTest('inBatch tracks and rejects late database uses', () async {
        final db = await openTestDatabase();

        late final Zone inBatchZone;
        await db.inBatch(() => inBatchZone = Zone.current);

        expect(
          () => inBatchZone.run(() => db.saveDocument(MutableDocument())),
          throwsA(isA<DatabaseException>()),
        );
      });

      apiTest('inBatch runs async calls sequential', () async {
        final db = await openTestDatabase();

        var inBatch0isDone = false;
        var inBatch1isDone = false;

        // ignore: unawaited_futures
        db.inBatch(() async {
          expect(inBatch1isDone, isFalse);

          // Yield to the event loop.
          await Future(() {});

          // inBatch1 should still not be running.
          expect(inBatch1isDone, isFalse);

          inBatch0isDone = true;
        });
        // ignore: unawaited_futures, cascade_invocations
        db.inBatch(() {
          expect(inBatch0isDone, isTrue);
          inBatch1isDone = true;
        });
      });

      test(
        'inBatch rejects starting new sync txn while an async txn is active',
        () async {
          final db = openSyncTestDatabase();

          final inBatch = db.inBatch(() async {});

          expect(
            () => db.saveDocument(MutableDocument()),
            throwsA(isA<DatabaseException>()),
          );

          await inBatch;

          // Verify that after inBatch is finished sync operations are allowed.
          db.saveDocument(MutableDocument());
        },
      );

      apiTest('inBatch rejects operations for the wrong database', () async {
        final dbA = await openTestDatabase();
        final dbB = await openTestDatabase();

        expect(
          dbA.inBatch(() async {
            await dbB.saveDocument(MutableDocument());
          }),
          throwsA(isA<DatabaseException>()),
        );
      });

      apiTest('document returns null when the document does not exist',
          () async {
        final db = await openTestDatabase();
        expect(await db.document('x'), isNull);
      });

      apiTest('document returns the document when it exist', () async {
        final db = await openTestDatabase();

        final doc = MutableDocument();
        await db.saveDocument(doc);

        expect(await db.document(doc.id), doc);
      });

      apiTest('saveDocument saves the document', () async {
        final db = await openTestDatabase();

        final doc = MutableDocument({'a': 'b', 'c': 4});
        await db.saveDocument(doc);

        expect((await db.document(doc.id))!.toPlainMap(), doc.toPlainMap());
      });

      apiTest(
        'save mutable document created from unsaved mutable document',
        () async {
          final db = await openTestDatabase();

          final initialDoc = MutableDocument({'a': 'b', 'c': 4});
          await db.saveDocument(initialDoc);

          final loadedDoc = (await db.document(initialDoc.id))!.toMutable();

          final doc = loadedDoc.toMutable();
          expect(await db.saveDocument(doc), isTrue);
        },
      );

      apiTest(
        'save mutable document created from changed mutable document '
        '(lastWriteWins)',
        () async {
          final db = await openTestDatabase();

          final initialDoc = MutableDocument({'a': 'b', 'c': 4});
          await db.saveDocument(initialDoc);

          final loadedDoc = (await db.document(initialDoc.id))!.toMutable();

          final doc = loadedDoc.toMutable();

          await db.saveDocument(loadedDoc);

          expect(await db.saveDocument(doc), isTrue);

          expect(
            await db.saveDocument(loadedDoc, ConcurrencyControl.failOnConflict),
            isFalse,
          );
        },
      );

      apiTest(
        'save mutable document created from changed mutable document '
        '(failOnConflict)',
        () async {
          final db = await openTestDatabase();

          final initialDoc = MutableDocument({'a': 'b', 'c': 4});
          await db.saveDocument(initialDoc);

          final loadedDoc = (await db.document(initialDoc.id))!.toMutable();

          final doc = loadedDoc.toMutable();

          await db.saveDocument(loadedDoc);

          expect(
            await db.saveDocument(doc, ConcurrencyControl.failOnConflict),
            isFalse,
          );
        },
      );

      group('saveDocumentWithConflictHandler', () {
        apiTest('save updated document', () async {
          final db = await openTestDatabase();

          final doc = MutableDocument();
          await db.saveDocument(doc);
          final updatedDoc = ((await db.document(doc.id))!.toMutable())
            ..setValue('b', key: 'a');
          db.saveDocument(updatedDoc);

          final SaveConflictHandler handler =
              expectAsync2((documentBeingSaved, conflictingDocument) {
            expect(documentBeingSaved, doc);
            expect(conflictingDocument, updatedDoc);
            documentBeingSaved.setValue('c', key: 'a');
            return apiFutureOr(true);
          });

          await expectLater(
            db.saveDocumentWithConflictHandler(doc, handler),
            completion(isTrue),
          );

          expect(doc.value('a'), 'c');
          expect((await db.document(doc.id))!.value('a'), 'c');
        });

        apiTest('save deleted document', () async {
          final db = await openTestDatabase();

          final doc = MutableDocument();
          await db.saveDocument(doc);
          await db.deleteDocument((await db.document(doc.id))!);

          final SaveConflictHandler handler =
              expectAsync2((documentBeingSaved, conflictingDocument) {
            expect(documentBeingSaved, doc);
            expect(conflictingDocument, isNull);
            documentBeingSaved.setValue('c', key: 'a');
            return apiFutureOr(true);
          });

          await expectLater(
            db.saveDocumentWithConflictHandler(doc, handler),
            completion(isTrue),
          );

          expect(doc.value('a'), 'c');
          expect((await db.document(doc.id))!.value('a'), 'c');
        });

        apiTest('cancels save if handler returns false', () async {
          final db = await openTestDatabase();

          final doc = MutableDocument();
          await db.saveDocument(doc);
          final updatedDoc = ((await db.document(doc.id))!.toMutable())
            ..setValue('b', key: 'a');
          await db.saveDocument(updatedDoc);

          final SaveConflictHandler handler =
              expectAsync2((documentBeingSaved, conflictingDocument) {
            expect(documentBeingSaved, doc);
            expect(conflictingDocument, updatedDoc);
            return apiFutureOr(false);
          });

          await expectLater(
            db.saveDocumentWithConflictHandler(doc, handler),
            completion(isFalse),
          );
        });

        test('save updated document with sync conflict handler', () async {
          final db = openSyncTestDatabase();

          final doc = MutableDocument();
          db.saveDocument(doc);
          final updatedDoc = ((db.document(doc.id))!.toMutable())
            ..setValue('b', key: 'a');
          db.saveDocument(updatedDoc);

          final SyncSaveConflictHandler handler =
              expectAsync2((documentBeingSaved, conflictingDocument) {
            expect(documentBeingSaved, doc);
            expect(conflictingDocument, updatedDoc);
            documentBeingSaved.setValue('c', key: 'a');
            return true;
          });

          await expectLater(
            db.saveDocumentWithConflictHandlerSync(doc, handler),
            isTrue,
          );

          expect(doc.value('a'), 'c');
          expect(db.document(doc.id)!.value('a'), 'c');
        });
      });

      apiTest(
        'deleteDocument should remove document from the database',
        () async {
          final db = await openTestDatabase();

          final doc = MutableDocument();
          await db.saveDocument(doc);
          await db.deleteDocument(doc);

          expect(await db.document(doc.id), isNull);
        },
      );

      apiTest('delete document that was loaded from database', () async {
        final db = await openTestDatabase();

        final doc = MutableDocument();
        await db.saveDocument(doc);
        await db.deleteDocument((await db.document(doc.id))!);

        expect(await db.document(doc.id), isNull);
      });

      apiTest(
        'delete mutable document that was loaded from database',
        () async {
          final db = await openTestDatabase();

          final doc = MutableDocument();
          await db.saveDocument(doc);
          await db.deleteDocument((await db.document(doc.id))!.toMutable());

          expect(await db.document(doc.id), isNull);
        },
      );

      apiTest('delete new unsaved document', () async {
        final db = await openTestDatabase();

        final doc = MutableDocument();
        expect(
          () => db.deleteDocument(doc),
          throwsA(isA<DatabaseException>().having(
            (exception) => exception.code,
            'code',
            DatabaseErrorCode.notFound,
          )),
        );
      });

      apiTest('purgeDocument purges a document', () async {
        final db = await openTestDatabase();

        final doc = MutableDocument();
        await db.saveDocument(doc);
        await db.purgeDocument(doc);

        expect(await db.document(doc.id), isNull);
      });

      apiTest('purgeDocumentById purges a document by id', () async {
        final db = await openTestDatabase();

        final doc = MutableDocument();
        await db.saveDocument(doc);
        await db.purgeDocumentById(doc.id);

        expect(await db.document(doc.id), isNull);
      });

      group('getDocumentExpiration', () {
        apiTest('returns null if the document has no expiration', () async {
          final db = await openTestDatabase();

          final doc = MutableDocument();
          await db.saveDocument(doc);

          expect(await db.getDocumentExpiration(doc.id), isNull);
        });

        apiTest(
          'returns the time of expiration if the document has one',
          () async {
            final db = await openTestDatabase();

            final expiration = DateTime.now().add(const Duration(days: 1));
            final doc = MutableDocument();
            await db.saveDocument(doc);
            await db.setDocumentExpiration(doc.id, expiration);

            final storedExpiration = await db.getDocumentExpiration(doc.id);

            expect(
              storedExpiration!.millisecondsSinceEpoch,
              expiration.millisecondsSinceEpoch,
            );
          },
        );
      });

      group('setDocumentExpiration', () {
        apiTest('sets a new time of expiration', () async {
          final db = await openTestDatabase();

          final expiration = DateTime.now().add(const Duration(days: 1));
          final doc = MutableDocument();
          await db.saveDocument(doc);
          await db.setDocumentExpiration(doc.id, expiration);

          final storedExpiration = await db.getDocumentExpiration(doc.id);

          expect(
            storedExpiration!.millisecondsSinceEpoch,
            expiration.millisecondsSinceEpoch,
          );
        });

        apiTest('sets the time of expiration to null', () async {
          final db = await openTestDatabase();

          final expiration = DateTime.now().add(const Duration(days: 1));
          final doc = MutableDocument();
          await db.saveDocument(doc);
          await db.setDocumentExpiration(doc.id, expiration);
          await db.setDocumentExpiration(doc.id, null);

          expect(await db.getDocumentExpiration(doc.id), isNull);
        });
      });

      apiTest('database change listener is notified while listening', () async {
        final db = await openTestDatabase();
        final doc = MutableDocument();
        final listenerWasCalled = Completer<void>();

        final token = await db.addChangeListener(expectAsync1((change) {
          expect(change.database, db);
          expect(change.documentIds, [doc.id]);
          listenerWasCalled.complete();
        }));

        // Change the database.
        await db.saveDocument(doc);

        // Wait for listener to be called and remove it.
        await listenerWasCalled.future;
        await db.removeChangeListener(token);

        // Change the database again, to verify listener is not called anymore.
        await db.saveDocument(MutableDocument());
      });

      apiTest('document change listener is notified while listening', () async {
        final db = await openTestDatabase();
        final doc = MutableDocument();
        final listenerWasCalled = Completer<void>();

        final token =
            await db.addDocumentChangeListener(doc.id, expectAsync1((change) {
          expect(change.database, db);
          expect(change.documentId, doc.id);
          listenerWasCalled.complete();
        }));

        // Saved the document.
        await db.saveDocument(doc);

        // Wait for listener to be called and remove it.
        await listenerWasCalled.future;
        await db.removeChangeListener(token);

        // Save the document again, to verify listener is not called anymore.
        await db.saveDocument(doc);
      });

      apiTest(
        'database change stream emits event when database changes',
        () async {
          final db = await openTestDatabase();
          final doc = MutableDocument();

          expect(
            db.changes(),
            emitsInOrder(<dynamic>[
              DatabaseChange(db, [doc.id])
            ]),
          );

          await db.saveDocument(doc);
        },
      );

      apiTest(
        'document change stream emits event when the document changes',
        () async {
          final db = await openTestDatabase();
          final collection = await db.defaultCollection;
          final doc = MutableDocument();

          expect(
            db.documentChanges(doc.id),
            emitsInOrder(<dynamic>[DocumentChange(db, collection, doc.id)]),
          );

          await db.saveDocument(doc);
        },
      );
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

      apiTest(
        'revisionId returns string when document has been saved',
        () async {
          final db = await openTestDatabase();

          final doc = MutableDocument();
          await db.saveDocument(doc);

          expect(doc.revisionId, '1-581ad726ee407c8376fc94aad966051d013893c4');
        },
      );

      apiTest('sequence returns the documents sequence', () async {
        final db = await openTestDatabase();

        final doc = MutableDocument();
        await db.saveDocument(doc);

        expect(doc.sequence, isPositive);
      });

      test('toPlainMap returns the documents properties', () {
        final props = {'a': 'b'};
        final doc = MutableDocument(props);

        expect(doc.toPlainMap(), props);
      });

      apiTest('toMutable() returns a mutable copy of the document', () async {
        final db = await openTestDatabase();

        final doc = MutableDocument({'a': 'b'});
        await db.saveDocument(doc);

        expect(
          doc.toMutable(),
          isA<MutableDocument>().having(
            (it) => it.toPlainMap(),
            'toPlainMap()',
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
      apiTest('createIndex should work with ValueIndexConfiguration', () async {
        final db = await openTestDatabase();
        await db.createIndex('a', ValueIndexConfiguration(['a']));

        final q = await Query.fromN1ql(db, 'SELECT * FROM _ WHERE a = "a"');

        final explain = await q.explain();

        expect(explain, contains('USING INDEX a'));
      });

      apiTest(
        'createIndex should work with FullTextIndexConfiguration',
        () async {
          final db = await openTestDatabase();
          await db.createIndex('a', FullTextIndexConfiguration(['a']));

          final q = await Query.fromN1ql(
            db,
            "SELECT * FROM _ WHERE MATCH(a, 'query')",
          );

          final explain = await q.explain();

          expect(explain, contains('fts1 VIRTUAL TABLE INDEX'));
        },
      );

      apiTest('createIndex should work with ValueIndex', () async {
        final db = await openTestDatabase();
        await db.createIndex(
          'a',
          IndexBuilder.valueIndex([ValueIndexItem.property('a')]),
        );

        final q = await Query.fromN1ql(db, 'SELECT * FROM _ WHERE a = "a"');

        final explain = await q.explain();

        expect(explain, contains('USING INDEX a'));
      });

      apiTest('createIndex should work with FullTextIndex', () async {
        final db = await openTestDatabase();
        await db.createIndex(
          'a',
          IndexBuilder.fullTextIndex([FullTextIndexItem.property('a')]),
        );

        final q = await Query.fromN1ql(
          db,
          "SELECT * FROM _ WHERE MATCH(a, 'query')",
        );

        final explain = await q.explain();

        expect(explain, contains('fts1 VIRTUAL TABLE INDEX'));
      });

      apiTest('deleteIndex should delete the given index', () async {
        final db = await openTestDatabase();
        await db.createIndex('a', ValueIndexConfiguration(['a']));

        expect(await db.indexes, ['a']);

        await db.deleteIndex('a');

        expect(await db.indexes, isEmpty);
      });

      apiTest(
        'indexes should return the names of all existing indexes',
        () async {
          final db = await openTestDatabase();
          expect(await db.indexes, isEmpty);

          await db.createIndex('a', ValueIndexConfiguration(['a']));

          expect(await db.indexes, ['a']);
        },
      );
    });

    group('Blob', () {
      apiTest('save and get blob from data', () async {
        final db = await openTestDatabase();
        final blob = Blob.fromData('', Uint8List.fromList([1, 2, 3]));
        expect(blob.digest, isNull);
        await db.saveBlob(blob);
        expect(blob.digest, isNotNull);

        final loadedBlob = await db.getBlob(blob.properties);
        expect(loadedBlob, blob);
        expect(await loadedBlob!.content(), await blob.content());
      });

      apiTest('save and get blob from stream', () async {
        final db = await openTestDatabase();
        final blob =
            Blob.fromStream('', Stream.value(Uint8List.fromList([1, 2, 3])));
        expect(blob.digest, isNull);
        expect(blob.length, isNull);
        await db.saveBlob(blob);
        expect(blob.digest, isNotNull);
        expect(blob.length, isNotNull);

        final loadedBlob = await db.getBlob(blob.properties);
        expect(loadedBlob, blob);
        expect(await loadedBlob!.content(), await blob.content());
      });

      apiTest(
        'saveBlob throws when using blob with multiple databases',
        () async {
          final dbA = await openTestDatabase(name: 'a');
          final dbB = await openTestDatabase(name: 'b');
          final blob =
              Blob.fromStream('', Stream.value(Uint8List.fromList([1, 2, 3])));
          await dbA.saveBlob(blob);
          expect(() => dbB.saveBlob(blob), throwsStateError);
        },
      );

      apiTest('getBlob throws when given metadata is invalid', () async {
        final db = await openTestDatabase();
        expect(() => db.getBlob({}), throwsArgumentError);
      });
    });

    group('Scenarios', () {
      apiTest('open the same database twice and receive change notifications',
          () async {
        final dbA = await openTestDatabase(name: 'A');
        final dbB = await openTestDatabase(name: 'A');
        final doc = MutableDocument();

        expect(
          dbA.changes(),
          emitsInOrder(<dynamic>[
            DatabaseChange(dbA, [doc.id])
          ]),
        );

        await dbB.saveDocument(doc);
      });

      apiTest('N1QL meal planner example', () async {
        final db = await openTestDatabase(name: 'A');
        await db.createIndex('date', ValueIndexConfiguration(['type']));
        await db.createIndex(
          'group_index',
          ValueIndexConfiguration(['`group`']),
        );

        final dish = MutableDocument({
          'type': 'dish',
          'title': 'Lasagna',
        });

        await db.saveDocument(dish);
        await db.saveDocument(MutableDocument({
          'type': 'meal',
          'dishes': [dish.id],
          'group': 'fam',
          'date': '2020-06-30',
        }));
        await db.saveDocument(MutableDocument({
          'type': 'meal',
          'dishes': [dish.id],
          'group': 'fam',
          'date': '2021-01-15',
        }));

        final q = await Query.fromN1ql(
          db,
          '''
          SELECT dish, max(meal.date) AS last_used, count(meal._id) AS in_meals, meal 
          FROM _ AS dish
          JOIN _ AS meal ON array_contains(meal.dishes, dish._id)
          WHERE dish.type = "dish" AND meal.type = "meal"  AND meal.`group` = "fam"
          GROUP BY dish._id
          ORDER BY max(meal.date)
          ''',
        );

        // ignore: avoid_print
        print(await q.explain());

        // ignore: avoid_print
        await (await q.execute()).asStream().forEach(print);
      });
    });
  });
}

FutureOr<void> removeDatabase(String name, {String? directory}) => runWithApi(
      sync: () => Database.removeSync(name, directory: directory),
      async: () => runWithIsolate(
        main: () => removeDatabaseWithSharedIsolate(
          name,
          directory: directory,
          isolate: Isolate.main,
        ),
        worker: () => Database.remove(name, directory: directory),
      ),
    );

FutureOr<bool> databaseExists(String name, {String? directory}) => runWithApi(
      sync: () => Database.existsSync(name, directory: directory),
      async: () async => runWithIsolate(
        main: () => databaseExistsWithSharedIsolate(
          name,
          directory: directory,
          isolate: Isolate.main,
        ),
        worker: () => Database.exists(name, directory: directory),
      ),
    );

FutureOr<void> copyDatabase({
  required String from,
  required String name,
  DatabaseConfiguration? config,
}) =>
    runWithApi(
      sync: () => Database.copySync(
        from: from,
        name: name,
        config: config,
      ),
      async: () async => runWithIsolate(
        main: () => copyDatabaseWithSharedIsolate(
          from: from,
          name: name,
          config: config,
          isolate: Isolate.main,
        ),
        worker: () => Database.copy(from: from, name: name, config: config),
      ),
    );
