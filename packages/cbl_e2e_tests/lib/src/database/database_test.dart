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

    apiTest('open with fullSync', () async {
      final config = DatabaseConfiguration(
        directory: databaseDirectoryForTest(),
        fullSync: true,
      );
      final db = await openTestDatabase(config: config);
      final collection = await db.defaultCollection;
      await collection.saveDocument(MutableDocument({}));
    });

    group('Database', () {
      apiTest('config', () async {
        final config = DatabaseConfiguration(
          directory: databaseDirectoryForTest(),
        );
        final db = await openTestDatabase(config: config);

        expect(db.name, 'db');
        expect(
          db.path,
          [
            databaseDirectoryForTest(),
            'db.cblite2',
            '',
          ].join(Platform.pathSeparator),
        );
        expect(db.config, config);
      });

      apiTest('close', () async {
        final db = await openTestDatabase();
        await db.close();
      });

      apiTest('delete', () async {
        final db = await openTestDatabase();

        await db.delete();

        expect(
          await databaseExists('default', directory: db.config.directory),
          isFalse,
        );
      });

      apiTest('performMaintenance: compact', () async {
        final db = await openTestDatabase();
        await db.performMaintenance(MaintenanceType.compact);
      });

      apiTest('performMaintenance: reindex', () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;
        await collection.createIndex('a', ValueIndexConfiguration(['type']));

        final doc = MutableDocument({'type': 'A'});
        await collection.saveDocument(doc);
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

        await expectLater(Future(openTestDatabase), throwsNotADatabaseFile);

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
          Future(
            () => openTestDatabase(
              config: DatabaseConfiguration(
                directory: databaseDirectoryForTest(),
                encryptionKey: keyA,
              ),
            ),
          ),
          throwsNotADatabaseFile,
        );
      });

      apiTest('inBatch commits transaction', () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;

        final doc = MutableDocument({});

        await runWithApi(
          sync: () => (db as SyncDatabase).inBatchSync(() {
            (collection as SyncCollection).saveDocument(doc);
          }),
          async: () => (db as AsyncDatabase).inBatch(() async {
            await (collection as AsyncCollection).saveDocument(doc);
          }),
        );

        expect(await collection.document(doc.id), isNotNull);
      });

      apiTest('inBatch aborts transaction when callback throws', () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;

        final doc = MutableDocument({});

        await runWithApi(
          sync: () => expect(
            () => (db as SyncDatabase).inBatchSync(() {
              (collection as SyncCollection).saveDocument(doc);
              throw Exception();
            }),
            throwsA(isException),
          ),
          async: () => expectLater(
            (db as AsyncDatabase).inBatch(() async {
              await (collection as AsyncCollection).saveDocument(doc);
              throw Exception();
            }),
            throwsA(isException),
          ),
        );

        expect(await collection.document(doc.id), isNull);
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
        final collection = await db.defaultCollection;

        late final Zone inBatchZone;
        await db.inBatch(() => inBatchZone = Zone.current);

        expect(
          () => inBatchZone.run(
            () => collection.saveDocument(MutableDocument({})),
          ),
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
          final collection = db.defaultCollection;

          final inBatch = db.inBatch(() {});

          expect(
            () => collection.saveDocument(MutableDocument({})),
            throwsA(isA<DatabaseException>()),
          );

          await inBatch;

          // Verify that after inBatch is finished sync operations are allowed.
          collection.saveDocument(MutableDocument({}));
        },
      );

      apiTest('inBatch rejects operations for the wrong database', () async {
        final dbA = await openTestDatabase();
        final dbB = await openTestDatabase();
        final collectionB = await dbB.defaultCollection;

        expect(
          dbA.inBatch(() async {
            await collectionB.saveDocument(MutableDocument({}));
          }),
          throwsA(isA<DatabaseException>()),
        );
      });
    });

    group('Document', () {
      test("id returns the document's id", () {
        final doc = MutableDocument(id: 'a', {});

        expect(doc.id, 'a');
      });

      test('revisionId returns `null` when the document is new', () {
        final doc = MutableDocument({});

        expect(doc.revisionId, isNull);
      });

      test('timestamp returns `0` when the document is new', () {
        final doc = MutableDocument({});

        expect(doc.timestamp, 0);
      });

      apiTest(
        'revisionId returns string when document has been saved',
        () async {
          final db = await openTestDatabase();
          final collection = await db.defaultCollection;

          final doc = MutableDocument({});
          await collection.saveDocument(doc);

          expect(doc.revisionId, isNotNull);
          expect(doc.revisionId, isNotEmpty);
        },
      );

      apiTest('timestamp returns the documents timestamp', () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;

        final doc = MutableDocument({});
        await collection.saveDocument(doc);

        expect(doc.timestamp, isPositive);

        final loadedDoc = (await collection.document(doc.id))!;
        expect(loadedDoc.timestamp, doc.timestamp);
      });

      apiTest(
        'revisionId and timestamp change when the document is updated',
        () async {
          final db = await openTestDatabase();
          final collection = await db.defaultCollection;

          final doc = MutableDocument({'value': 'initial'});
          await collection.saveDocument(doc);
          final initialRevisionId = doc.revisionId;
          final initialTimestamp = doc.timestamp;

          doc.setValue('updated', key: 'value');
          await collection.saveDocument(doc);

          expect(doc.revisionId, isNot(initialRevisionId));
          expect(doc.timestamp, greaterThan(initialTimestamp));
        },
      );

      apiTest('sequence returns the documents sequence', () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;

        final doc = MutableDocument({});
        await collection.saveDocument(doc);

        expect(doc.sequence, isPositive);
      });

      test('toPlainMap returns the documents properties', () {
        final props = {'a': 'b'};
        final doc = MutableDocument(props);

        expect(doc.toPlainMap(), props);
      });

      apiTest('toMutable() returns a mutable copy of the document', () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;

        final doc = MutableDocument({'a': 'b'});
        await collection.saveDocument(doc);

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
        final doc = MutableDocument(id: 'id', {});

        expect(doc.id, 'id');
      });

      test('supports generating an id', () {
        final doc = MutableDocument({});

        expect(doc.id, isNotEmpty);
      });
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
        final blob = Blob.fromStream(
          '',
          Stream.value(Uint8List.fromList([1, 2, 3])),
        );
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
          final blob = Blob.fromStream(
            '',
            Stream.value(Uint8List.fromList([1, 2, 3])),
          );
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
      apiTest(
        'open the same database twice and receive change notifications',
        () async {
          final dbA = await openTestDatabase(name: 'A');
          final dbB = await openTestDatabase(name: 'A');
          final collectionA = await dbA.defaultCollection;
          final collectionB = await dbB.defaultCollection;
          final doc = MutableDocument({});

          expect(
            collectionA.changes(),
            emitsInOrder(<dynamic>[
              CollectionChange(collectionA, [doc.id]),
            ]),
          );

          await collectionB.saveDocument(doc);
        },
      );

      apiTest('SQL++ meal planner example', () async {
        final db = await openTestDatabase(name: 'A');
        final collection = await db.defaultCollection;
        await collection.createIndex('date', ValueIndexConfiguration(['type']));
        await collection.createIndex(
          'group_index',
          ValueIndexConfiguration(['`group`']),
        );

        final dish = MutableDocument({'type': 'dish', 'title': 'Lasagna'});

        await collection.saveDocument(dish);
        await collection.saveDocument(
          MutableDocument({
            'type': 'meal',
            'dishes': [dish.id],
            'group': 'fam',
            'date': '2020-06-30',
          }),
        );
        await collection.saveDocument(
          MutableDocument({
            'type': 'meal',
            'dishes': [dish.id],
            'group': 'fam',
            'date': '2021-01-15',
          }),
        );

        final q = await db.createQuery('''
          SELECT dish, max(meal.date) AS last_used, count(meal._id) AS in_meals, meal
          FROM _ AS dish
          JOIN _ AS meal ON array_contains(meal.dishes, dish._id)
          WHERE dish.type = "dish" AND meal.type = "meal"  AND meal.`group` = "fam"
          GROUP BY dish._id
          ORDER BY max(meal.date)
          ''');

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
  async: () => runWithIsolate(
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
}) => runWithApi(
  sync: () => Database.copySync(from: from, name: name, config: config),
  async: () => runWithIsolate(
    main: () => copyDatabaseWithSharedIsolate(
      from: from,
      name: name,
      config: config,
      isolate: Isolate.main,
    ),
    worker: () => Database.copy(from: from, name: name, config: config),
  ),
);
