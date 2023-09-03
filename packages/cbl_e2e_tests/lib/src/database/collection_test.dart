import 'dart:async';

import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/api_variant.dart';
import '../utils/database_utils.dart';

void main() {
  setupTestBinding();

  group('Collection', () {
    apiTest('defaultCollection', () async {
      final db = await openTestDatabase();

      final defaultScope = await db.defaultScope;
      expect(defaultScope.name, Scope.defaultName);

      final defaultCollection = await db.defaultCollection;
      expect(defaultCollection.name, Collection.defaultName);
      expect(defaultCollection.scope.name, Scope.defaultName);

      final scopes = await db.scopes;
      expect(scopes, hasLength(1));
      expect(scopes.single.name, Scope.defaultName);

      final collections = await scopes.single.collections;
      expect(collections, hasLength(1));
      expect(collections.single.name, Collection.defaultName);
    });

    apiTest('createCollection', () async {
      final db = await openTestDatabase();

      final collectionInDefaultScope = await db.createCollection('a');
      expect(collectionInDefaultScope.name, 'a');
      expect(collectionInDefaultScope.scope.name, Scope.defaultName);
      expect(await db.collections(), hasLength(2));

      final collectionInCustomScope = await db.createCollection('b', 'c');
      expect(collectionInCustomScope.name, 'b');
      expect(collectionInCustomScope.scope.name, 'c');
      expect(await db.collections('c'), hasLength(1));
    });

    apiTest('deleteCollection', () async {
      final db = await openTestDatabase();

      await db.createCollection('a');
      await db.deleteCollection('a');
      expect(await db.collections(), hasLength(1));

      await db.createCollection('a', 'c');
      await db.deleteCollection('a', 'c');
      expect(await db.collections('c'), hasLength(0));
    });
    apiTest('count', () async {
      final db = await openTestDatabase();
      final collection = await db.defaultCollection;

      expect(await collection.count, 0);

      await collection.saveDocument(MutableDocument());

      expect(await collection.count, 1);
    });

    apiTest('document fragment', () async {
      final db = await openTestDatabase();
      final collection = await db.defaultCollection;

      expect((await collection['a']).exists, isFalse);

      await collection.saveDocument(MutableDocument.withId('a'));

      expect((await collection['a']).exists, isTrue);
    });

    group('document', () {
      apiTest('returns null when the document does not exist', () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;
        expect(await collection.document('x'), isNull);
      });

      apiTest('returns the document when it exist', () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;

        final doc = MutableDocument();
        await collection.saveDocument(doc);

        expect(await collection.document(doc.id), doc);
      });
    });

    apiTest('saveDocument saves the document', () async {
      final db = await openTestDatabase();
      final collection = await db.defaultCollection;

      final doc = MutableDocument({'a': 'b', 'c': 4});
      await collection.saveDocument(doc);

      expect(
        (await collection.document(doc.id))!.toPlainMap(),
        doc.toPlainMap(),
      );
    });

    apiTest(
      'save mutable document created from unsaved mutable document',
      () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;

        final initialDoc = MutableDocument({'a': 'b', 'c': 4});
        await collection.saveDocument(initialDoc);

        final loadedDoc =
            (await collection.document(initialDoc.id))!.toMutable();

        final doc = loadedDoc.toMutable();
        expect(await collection.saveDocument(doc), isTrue);
      },
    );

    apiTest(
      'save mutable document created from changed mutable document '
      '(lastWriteWins)',
      () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;

        final initialDoc = MutableDocument({'a': 'b', 'c': 4});
        await collection.saveDocument(initialDoc);

        final loadedDoc =
            (await collection.document(initialDoc.id))!.toMutable();

        final doc = loadedDoc.toMutable();

        await collection.saveDocument(loadedDoc);

        expect(await collection.saveDocument(doc), isTrue);

        expect(
          await collection.saveDocument(
            loadedDoc,
            ConcurrencyControl.failOnConflict,
          ),
          isFalse,
        );
      },
    );

    apiTest(
      'save mutable document created from changed mutable document '
      '(failOnConflict)',
      () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;

        final initialDoc = MutableDocument({'a': 'b', 'c': 4});
        await collection.saveDocument(initialDoc);

        final loadedDoc =
            (await collection.document(initialDoc.id))!.toMutable();

        final doc = loadedDoc.toMutable();

        await collection.saveDocument(loadedDoc);

        expect(
          await collection.saveDocument(doc, ConcurrencyControl.failOnConflict),
          isFalse,
        );
      },
    );

    group('saveDocumentWithConflictHandler', () {
      apiTest('save updated document', () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;

        final doc = MutableDocument();
        await collection.saveDocument(doc);
        final updatedDoc = ((await collection.document(doc.id))!.toMutable())
          ..setValue('b', key: 'a');
        collection.saveDocument(updatedDoc);

        final SaveConflictHandler handler =
            expectAsync2((documentBeingSaved, conflictingDocument) {
          expect(documentBeingSaved, doc);
          expect(conflictingDocument, updatedDoc);
          documentBeingSaved.setValue('c', key: 'a');
          return apiFutureOr(true);
        });

        await expectLater(
          collection.saveDocumentWithConflictHandler(doc, handler),
          completion(isTrue),
        );

        expect(doc.value('a'), 'c');
        expect((await collection.document(doc.id))!.value('a'), 'c');
      });

      apiTest('save deleted document', () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;

        final doc = MutableDocument();
        await collection.saveDocument(doc);
        await collection.deleteDocument((await collection.document(doc.id))!);

        final SaveConflictHandler handler =
            expectAsync2((documentBeingSaved, conflictingDocument) {
          expect(documentBeingSaved, doc);
          expect(conflictingDocument, isNull);
          documentBeingSaved.setValue('c', key: 'a');
          return apiFutureOr(true);
        });

        await expectLater(
          collection.saveDocumentWithConflictHandler(doc, handler),
          completion(isTrue),
        );

        expect(doc.value('a'), 'c');
        expect((await collection.document(doc.id))!.value('a'), 'c');
      });

      apiTest('cancels save if handler returns false', () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;

        final doc = MutableDocument();
        await collection.saveDocument(doc);
        final updatedDoc = ((await collection.document(doc.id))!.toMutable())
          ..setValue('b', key: 'a');
        await collection.saveDocument(updatedDoc);

        final SaveConflictHandler handler =
            expectAsync2((documentBeingSaved, conflictingDocument) {
          expect(documentBeingSaved, doc);
          expect(conflictingDocument, updatedDoc);
          return apiFutureOr(false);
        });

        await expectLater(
          collection.saveDocumentWithConflictHandler(doc, handler),
          completion(isFalse),
        );
      });

      test('save updated document with sync conflict handler', () async {
        final db = openSyncTestDatabase();
        final collection = db.defaultCollection;

        final doc = MutableDocument();
        collection.saveDocument(doc);
        final updatedDoc = ((collection.document(doc.id))!.toMutable())
          ..setValue('b', key: 'a');
        collection.saveDocument(updatedDoc);

        final SyncSaveConflictHandler handler =
            expectAsync2((documentBeingSaved, conflictingDocument) {
          expect(documentBeingSaved, doc);
          expect(conflictingDocument, updatedDoc);
          documentBeingSaved.setValue('c', key: 'a');
          return true;
        });

        await expectLater(
          collection.saveDocumentWithConflictHandlerSync(doc, handler),
          isTrue,
        );

        expect(doc.value('a'), 'c');
        expect(collection.document(doc.id)!.value('a'), 'c');
      });
    });

    apiTest(
      'deleteDocument should remove document from the database',
      () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;

        final doc = MutableDocument();
        await collection.saveDocument(doc);
        await collection.deleteDocument(doc);

        expect(await collection.document(doc.id), isNull);
      },
    );

    apiTest('delete document that was loaded from database', () async {
      final db = await openTestDatabase();
      final collection = await db.defaultCollection;

      final doc = MutableDocument();
      await collection.saveDocument(doc);
      await collection.deleteDocument((await collection.document(doc.id))!);

      expect(await collection.document(doc.id), isNull);
    });

    apiTest(
      'delete mutable document that was loaded from database',
      () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;

        final doc = MutableDocument();
        await collection.saveDocument(doc);
        await collection
            .deleteDocument((await collection.document(doc.id))!.toMutable());

        expect(await collection.document(doc.id), isNull);
      },
    );

    apiTest('delete new unsaved document', () async {
      final db = await openTestDatabase();
      final collection = await db.defaultCollection;

      final doc = MutableDocument();
      expect(
        () => collection.deleteDocument(doc),
        throwsA(isA<DatabaseException>().having(
          (exception) => exception.code,
          'code',
          DatabaseErrorCode.notFound,
        )),
      );
    });

    apiTest('purgeDocument purges a document', () async {
      final db = await openTestDatabase();
      final collection = await db.defaultCollection;

      final doc = MutableDocument();
      await collection.saveDocument(doc);
      await collection.purgeDocument(doc);

      expect(await collection.document(doc.id), isNull);
    });

    apiTest('purgeDocumentById purges a document by id', () async {
      final db = await openTestDatabase();
      final collection = await db.defaultCollection;

      final doc = MutableDocument();
      await collection.saveDocument(doc);
      await collection.purgeDocumentById(doc.id);

      expect(await collection.document(doc.id), isNull);
    });

    group('getDocumentExpiration', () {
      apiTest('returns null if the document has no expiration', () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;

        final doc = MutableDocument();
        await collection.saveDocument(doc);

        expect(await collection.getDocumentExpiration(doc.id), isNull);
      });

      apiTest(
        'returns the time of expiration if the document has one',
        () async {
          final db = await openTestDatabase();
          final collection = await db.defaultCollection;

          final expiration = DateTime.now().add(const Duration(days: 1));
          final doc = MutableDocument();
          await collection.saveDocument(doc);
          await collection.setDocumentExpiration(doc.id, expiration);

          final storedExpiration =
              await collection.getDocumentExpiration(doc.id);

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
        final collection = await db.defaultCollection;

        final expiration = DateTime.now().add(const Duration(days: 1));
        final doc = MutableDocument();
        await collection.saveDocument(doc);
        await collection.setDocumentExpiration(doc.id, expiration);

        final storedExpiration = await collection.getDocumentExpiration(doc.id);

        expect(
          storedExpiration!.millisecondsSinceEpoch,
          expiration.millisecondsSinceEpoch,
        );
      });

      apiTest('sets the time of expiration to null', () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;

        final expiration = DateTime.now().add(const Duration(days: 1));
        final doc = MutableDocument();
        await collection.saveDocument(doc);
        await collection.setDocumentExpiration(doc.id, expiration);
        await collection.setDocumentExpiration(doc.id, null);

        expect(await collection.getDocumentExpiration(doc.id), isNull);
      });
    });

    group('listeners', () {
      apiTest('database change listener is notified while listening', () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;

        final doc = MutableDocument();
        final listenerWasCalled = Completer<void>();

        final token = await collection.addChangeListener(expectAsync1((change) {
          expect(change.collection, collection);
          expect(change.documentIds, [doc.id]);
          listenerWasCalled.complete();
        }));

        // Change the database.
        await collection.saveDocument(doc);

        // Wait for listener to be called and remove it.
        await listenerWasCalled.future;
        await collection.removeChangeListener(token);

        // Change the database again, to verify listener is not called anymore.
        await collection.saveDocument(MutableDocument());
      });

      apiTest('document change listener is notified while listening', () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;

        final doc = MutableDocument();
        final listenerWasCalled = Completer<void>();

        final token = await collection.addDocumentChangeListener(doc.id,
            expectAsync1((change) {
          expect(change.database, db);
          expect(change.collection, collection);
          expect(change.documentId, doc.id);
          listenerWasCalled.complete();
        }));

        // Saved the document.
        await collection.saveDocument(doc);

        // Wait for listener to be called and remove it.
        await listenerWasCalled.future;
        await collection.removeChangeListener(token);

        // Save the document again, to verify listener is not called anymore.
        await collection.saveDocument(doc);
      });

      apiTest(
        'database change stream emits event when database changes',
        () async {
          final db = await openTestDatabase();
          final collection = await db.defaultCollection;

          final doc = MutableDocument();

          expect(
            collection.changes(),
            emitsInOrder(<dynamic>[
              CollectionChange(collection, [doc.id])
            ]),
          );

          await collection.saveDocument(doc);
        },
      );

      apiTest(
        'document change stream emits event when the document changes',
        () async {
          final db = await openTestDatabase();
          final collection = await db.defaultCollection;
          final doc = MutableDocument();

          expect(
            collection.documentChanges(doc.id),
            emitsInOrder(<dynamic>[DocumentChange(db, collection, doc.id)]),
          );

          await collection.saveDocument(doc);
        },
      );
    });

    group('Index', () {
      apiTest('createIndex should work with ValueIndexConfiguration', () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;

        await collection.createIndex('a', ValueIndexConfiguration(['a']));

        final q = await Query.fromN1ql(db, 'SELECT * FROM _ WHERE a = "a"');

        final explain = await q.explain();

        expect(explain, contains('USING INDEX a'));
      });

      apiTest(
        'createIndex should work with FullTextIndexConfiguration',
        () async {
          final db = await openTestDatabase();
          final collection = await db.defaultCollection;

          await collection.createIndex('a', FullTextIndexConfiguration(['a']));

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
        final collection = await db.defaultCollection;

        await collection.createIndex(
          'a',
          IndexBuilder.valueIndex([ValueIndexItem.property('a')]),
        );

        final q = await Query.fromN1ql(db, 'SELECT * FROM _ WHERE a = "a"');

        final explain = await q.explain();

        expect(explain, contains('USING INDEX a'));
      });

      apiTest('createIndex should work with FullTextIndex', () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;

        await collection.createIndex(
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
        final collection = await db.defaultCollection;

        await collection.createIndex('a', ValueIndexConfiguration(['a']));

        expect(await collection.indexes, ['a']);

        await collection.deleteIndex('a');

        expect(await collection.indexes, isEmpty);
      });

      apiTest(
        'indexes should return the names of all existing indexes',
        () async {
          final db = await openTestDatabase();
          final collection = await db.defaultCollection;

          expect(await collection.indexes, isEmpty);

          await collection.createIndex('a', ValueIndexConfiguration(['a']));

          expect(await collection.indexes, ['a']);
        },
      );
    });
  });
}
