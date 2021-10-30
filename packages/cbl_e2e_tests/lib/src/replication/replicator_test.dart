import 'dart:async';
import 'dart:typed_data';

import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/api_variant.dart';
import '../utils/database_utils.dart';
import '../utils/replicator_utils.dart';
import '../utils/test_document.dart';

void main() {
  setupTestBinding();

  group('Replicator', () {
    setupTestDocument();

    setUp(flushSyncGatewayDatabase);

    apiTest('create Replicator smoke test', () async {
      final db = await openTestDatabase();

      final repl = await Replicator.create(ReplicatorConfiguration(
        database: db,
        target: UrlEndpoint(syncGatewayReplicationUrl),
        authenticator: BasicAuthenticator(
          username: 'user',
          password: 'password',
        ),
        headers: {'Client': 'test'},
        pinnedServerCertificate: Uint8List(0),
        channels: ['channel'],
        documentIds: ['id'],
        pullFilter: (document, isDeleted) => true,
        pushFilter: (document, isDeleted) => true,
        conflictResolver:
            ConflictResolver.from((conflict) => conflict.localDocument),
      ));

      // Check that is possible to start the replicator with this configuration.
      await repl.start();
      await repl.close();
    });

    apiTest('config returns copy', () async {
      final db = await openTestDatabase();
      final config = ReplicatorConfiguration(
        database: db,
        target: UrlEndpoint(syncGatewayReplicationUrl),
      );
      final repl = await Replicator.create(config);
      addTearDown(repl.close);
      final configA = repl.config;
      final configB = repl.config;
      expect(configA, isNot(same(config)));
      expect(configA, isNot(same(configB)));
    });

    apiTest('continuous replication', () async {
      final pushDb = await openTestDatabase(name: 'Push');
      final pullDb = await openTestDatabase(name: 'Pull');

      final pushRepl = await pushDb.createTestReplicator(
        replicatorType: ReplicatorType.push,
        continuous: true,
      );

      final pullRepl = await pullDb.createTestReplicator(
        replicatorType: ReplicatorType.pull,
        continuous: true,
      );

      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final doc =
          MutableDocument.withId('continuouslyReplicatedDoc-$timestamp');

      expect(
        pullDb.watchAllIds(),
        emitsThrough(contains(doc.id)),
      );

      await pushRepl.start();
      await pullRepl.start();
      await pushDb.saveDocument(doc);
    });

    apiTest('listen to query while replicator is pulling', () async {
      final pullDb = await openTestDatabase();

      final pullRepl = await pullDb.createTestReplicator(
        replicatorType: ReplicatorType.pull,
        continuous: true,
      );
      await pullRepl.start();

      await pullDb.watchAllIds().first;
    });

    apiTest('use documentIds to filter replicated documents', () async {
      // Insert doc A and B into push db
      // Sync push db  with server with documentIds == [docA.id]
      // Sync pull db  with server
      // => pull db contains doc A

      final pushDb = await openTestDatabase(name: 'Push');
      final pullDb = await openTestDatabase(name: 'Pull');

      final docA = MutableDocument();
      await pushDb.saveDocument(docA);
      final docB = MutableDocument();
      await pushDb.saveDocument(docB);

      final pusher = await pushDb.createTestReplicator(
        replicatorType: ReplicatorType.push,
        documentIds: [docA.id],
      );
      await pusher.replicateOneShot();

      final puller = await pullDb.createTestReplicator(
        replicatorType: ReplicatorType.pull,
      );
      await puller.replicateOneShot();

      final idsInPullDb = await pullDb.getAllIds();
      expect(idsInPullDb, contains(docA.id));
    });

    apiTest('use channels to filter pulled documents', () async {
      // Insert doc A and B into push db, where doc A is in channel A
      // Sync push db with server
      // Sync pull db with server with channels == ['A']
      // => pull db contains doc A

      final pushDb = await openTestDatabase(name: 'Push');
      final pullDb = await openTestDatabase(name: 'Push');

      final docA = MutableDocument({'channels': 'A'});
      await pushDb.saveDocument(docA);
      final docB = MutableDocument();
      await pushDb.saveDocument(docB);

      final pusher = await pushDb.createTestReplicator(
        replicatorType: ReplicatorType.push,
      );
      await pusher.replicateOneShot();

      final puller = await pullDb.createTestReplicator(
        replicatorType: ReplicatorType.pull,
        channels: ['A'],
      );
      await puller.replicateOneShot();

      final idsInPullDb = await pullDb.getAllIds();
      expect(idsInPullDb, contains(docA.id));
    });

    apiTest('use pushFilter to filter pushed documents', () async {
      final pushDb = await openTestDatabase(name: 'Push');
      final pullDb = await openTestDatabase(name: 'Pull');

      final docA = MutableDocument();
      await pushDb.saveDocument(docA);
      final docB = MutableDocument();
      await pushDb.saveDocument(docB);

      final pusher = await pushDb.createTestReplicator(
        replicatorType: ReplicatorType.push,
        pushFilter: expectAsync2(
          (document, flags) {
            expect(flags, isEmpty);
            expect(document.id, anyOf(docA.id, docB.id));
            return docA.id == document.id;
          },
          count: 2,
        ),
      );
      await pusher.replicateOneShot();

      final puller = await pullDb.createTestReplicator(
        replicatorType: ReplicatorType.pull,
      );
      await puller.replicateOneShot();

      final idsInPullDb = await pullDb.getAllIds();
      expect(idsInPullDb, contains(docA.id));
      expect(idsInPullDb, isNot(contains(docB.id)));
    });

    apiTest('pushFilter exception handling', () async {
      Object? uncaughtError;
      await runZonedGuarded(() async {
        final pushDb = await openTestDatabase(name: 'Push');
        final pullDb = await openTestDatabase(name: 'Pull');

        final doc = MutableDocument();
        await pushDb.saveDocument(doc);

        final pusher = await pushDb.createTestReplicator(
          replicatorType: ReplicatorType.push,
          pushFilter: (document, flags) {
            throw Exception();
          },
        );

        await pusher.replicateOneShot();

        final puller = await pullDb.createTestReplicator(
          replicatorType: ReplicatorType.pull,
        );

        await puller.replicateOneShot();

        // Documents where filter throws are not pushed.
        expect(await pullDb.document(doc.id), isNull);
      }, (error, _) {
        uncaughtError = error;
      });
      expect(uncaughtError, isException);
    });

    apiTest('use pullFilter to filter pulled documents', () async {
      final pushDb = await openTestDatabase(name: 'Push');
      final pullDb = await openTestDatabase(name: 'Pull');

      final docA = MutableDocument();
      await pushDb.saveDocument(docA);
      final docB = MutableDocument();
      await pushDb.saveDocument(docB);

      final pusher = await pushDb.createTestReplicator(
        replicatorType: ReplicatorType.push,
      );
      await pusher.replicateOneShot();

      final puller = await pullDb.createTestReplicator(
        replicatorType: ReplicatorType.pull,
        pullFilter: expectAsync2(
          (document, flags) {
            expect(flags, isEmpty);
            return docA.id == document.id;
          },
          count: 2,
          max: -1,
        ),
      );
      await puller.replicateOneShot();

      final idsInPullDb = await pullDb.getAllIds();
      expect(idsInPullDb, contains(docA.id));
      expect(idsInPullDb, isNot(contains(docB.id)));
    });

    apiTest('pullFilter exception handling', () async {
      Object? uncaughtError;
      await runZonedGuarded(() async {
        final pushDb = await openTestDatabase(name: 'Push');
        final pullDb = await openTestDatabase(name: 'Pull');

        final doc = MutableDocument();
        await pushDb.saveDocument(doc);

        final pusher = await pushDb.createTestReplicator(
          replicatorType: ReplicatorType.push,
        );

        await pusher.replicateOneShot();

        final puller = await pullDb.createTestReplicator(
          replicatorType: ReplicatorType.pull,
          pullFilter: (document, flags) {
            throw Exception();
          },
        );

        await puller.replicateOneShot();

        // Documents where filter throws are not pulled.
        expect(await pullDb.document(doc.id), isNull);
      }, (error, _) {
        uncaughtError = error;
      });
      expect(uncaughtError, isException);
    });

    apiTest('custom conflict resolver', () async {
      // Create document in db A
      // Sync db A with server
      // Sync db B with server
      // Change doc in db A
      // Change doc in db B
      // Sync db B with server
      // Sync db A with server
      // => Conflict in db A

      final dbA = await openTestDatabase(name: 'A');
      final replicatorA = await dbA.createTestReplicator(
        conflictResolver: expectAsync1((conflict) {
          expect(conflict.documentId, testDocumentId);
          expect(conflict.localDocument, isTestDocument('DB-A-2'));
          expect(conflict.remoteDocument, isTestDocument('DB-B-1'));
          return conflict.remoteDocument;
        }),
      );

      final dbB = await openTestDatabase(name: 'B');
      final replicatorB = await dbB.createTestReplicator();

      await dbA.writeTestDocument('DB-A-1');
      await replicatorA.replicateOneShot();
      await replicatorB.replicateOneShot();
      await dbA.writeTestDocument('DB-A-2');
      await dbB.writeTestDocument('DB-B-1');
      await replicatorB.replicateOneShot();
      await replicatorA.replicateOneShot();

      expect(await dbA.getTestDocumentOrNull(), isTestDocument('DB-B-1'));
    });

    apiTest('conflict resolver exception handling', () async {
      Object? uncaughtError;
      await runZonedGuarded(() async {
        final dbA = await openTestDatabase(name: 'A');
        final replicatorA = await dbA.createTestReplicator(
          conflictResolver: expectAsync1((conflict) {
            throw Exception();
          }),
        );

        final dbB = await openTestDatabase(name: 'B');
        final replicatorB = await dbB.createTestReplicator();

        await dbA.writeTestDocument('DB-A-1');
        await replicatorA.replicateOneShot();
        await replicatorB.replicateOneShot();
        await dbA.writeTestDocument('DB-A-2');
        await dbB.writeTestDocument('DB-B-1');
        await replicatorB.replicateOneShot();
        await replicatorA.replicateOneShot();
      }, (error, _) {
        uncaughtError = error;
      });
      expect(uncaughtError, isException);
    });

    apiTest('status returns the current status of the replicator', () async {
      final db = await openTestDatabase();
      final replicator = await db.createTestReplicator();
      final status = await replicator.status;
      expect(status.activity, ReplicatorActivityLevel.stopped);
      expect(status.error, isNull);
      expect(status.progress.progress, 0);
      expect(status.progress.completed, 0);
    });

    apiTest('change listener is notified while listening', () async {
      final db = await openTestDatabase();
      final replicator = await db.createTestReplicator();

      late final ListenerToken token;
      token = await replicator.addChangeListener(expectAsync1((change) {
        expect(change.replicator, replicator);
        expect(change.status.activity, ReplicatorActivityLevel.busy);
        replicator.removeChangeListener(token);
      }));

      // A full replication notifies listeners more than once. This allows us
      // to verify that after having been removed, the listener is not called
      // any more.
      await replicator.replicateOneShot();
    });

    apiTest('document replication listener is notified while listening',
        () async {
      final db = await openTestDatabase();
      final replicator = await db.createTestReplicator();
      final doc = MutableDocument();
      await db.saveDocument(doc);

      late final ListenerToken token;
      token = await replicator
          .addDocumentReplicationListener(expectAsync1((change) {
        expect(change.replicator, replicator);
        expect(change.isPush, isTrue);
        expect(change.documents.map((it) => it.id), [doc.id]);
        replicator.removeChangeListener(token);
      }));

      // Trigger two replication runs, to verify that after the listener is
      // removed it won't be called any more.
      await replicator.replicateOneShot();
      await db.saveDocument(doc);
      await replicator.replicateOneShot();
    });

    apiTest('changes stream emits replicator changes', () async {
      final db = await openTestDatabase();
      final replicator = await db.createTestReplicator();

      expect(
        replicator.changes().map((it) => it.status.activity),
        emitsInOrder(<Object>[
          emits(ReplicatorActivityLevel.busy),
          emitsThrough(ReplicatorActivityLevel.stopped)
        ]),
      );

      await replicator.replicateOneShot();
    });

    apiTest('documentReplications emits document replications', () async {
      final db = await openTestDatabase();
      final replicator = await db.createTestReplicator();
      final doc = MutableDocument();
      await db.saveDocument(doc);

      expect(
        replicator.documentReplications(),
        emits(isA<DocumentReplication>()
            .having((it) => it.isPush, 'isPush', isTrue)
            .having((it) => it.documents, 'documents', [
          isA<ReplicatedDocument>()
              .having((it) => it.id, 'id', doc.id)
              .having((it) => it.flags, 'flags', isEmpty)
              .having((it) => it.error, 'error', isNull)
        ])),
      );

      await replicator.replicateOneShot();
    });

    apiTest(
      'pendingDocumentIds returns ids of documents waiting to be pushed',
      () async {
        final db = await openTestDatabase();
        final replicator = await db.createTestReplicator();
        final doc = MutableDocument();
        await db.saveDocument(doc);
        final pendingDocumentIds = await replicator.pendingDocumentIds;
        expect(pendingDocumentIds, [doc.id]);
      },
    );

    apiTest(
      'isDocumentPending returns whether a document is waiting to be pushed',
      () async {
        final db = await openTestDatabase();
        final replicator = await db.createTestReplicator();
        final doc = MutableDocument();
        await db.saveDocument(doc);
        expect(await replicator.isDocumentPending(doc.id), isTrue);
      },
    );

    apiTest('start and stop', () async {
      final db = await openTestDatabase();
      final repl = await db.createTestReplicator(continuous: true);

      await repl.driveToStatus(
        hasActivityLevel(ReplicatorActivityLevel.idle),
        repl.start,
      );
      await repl.driveToStatus(
        hasActivityLevel(ReplicatorActivityLevel.stopped),
        repl.stop,
      );
    });

    apiTest(
      'enableAutoPurge: true',
      () => autoPurgeTest(enableAutoPurge: true),
    );

    apiTest(
      'enableAutoPurge: false',
      () => autoPurgeTest(enableAutoPurge: false),
    );
  });
}

/// Test that verifies behavior of [enableAutoPurge].
Future<void> autoPurgeTest({required bool enableAutoPurge}) async {
  Database.log.console.level = LogLevel.warning;
  final db = await openTestDatabase();
  final replicator = await db.createTestReplicator(
    authenticator: aliceAuthenticator,
    continuous: true,
    enableAutoPurge: enableAutoPurge,
  );

  final doc = MutableDocument({
    'channels': ['Alice']
  });

  late StreamSubscription sub;
  sub = replicator.documentReplications().listen((replication) {
    final replDoc = replication.documents.first;
    expect(replDoc.id, doc.id);

    // Document has been pushed.
    if (replication.isPush) {
      // Remove user's channel.
      doc.setValue(<void>[], key: 'channels');
      db.saveDocument(doc);
    }

    // User has lost access.
    if (!replication.isPush) {
      expect(replDoc.flags, contains(DocumentFlag.accessRemoved));

      // Check that document either does or does not exist in database.
      Future.value(db.document(doc.id)).then((loadedDoc) {
        expect(loadedDoc, enableAutoPurge ? isNull : isNotNull);
        sub.cancel();
      });
    }
  });

  await replicator.start();

  await db.saveDocument(doc);
}
