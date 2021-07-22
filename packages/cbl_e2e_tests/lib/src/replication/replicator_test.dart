import 'dart:async';
import 'dart:typed_data';

import 'package:cbl/cbl.dart';
import 'package:rxdart/rxdart.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/database_utils.dart';
import '../utils/replicator_utils.dart';
import '../utils/test_document.dart';

void main() {
  setupTestBinding();

  group('Replicator', () {
    setupTestDocument();

    test('create Replicator smoke test', () async {
      final db = await openTestDb('CreateReplicatorSmoke');

      final repl = Replicator(ReplicatorConfiguration(
        database: db,
        target: UrlEndpoint(testSyncGatewayUrl),
        replicatorType: ReplicatorType.pushAndPull,
        continuous: false,
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

      await repl.start();
    });

    test('config returns copy', () async {
      final db = await openTestDb(null);
      final config = ReplicatorConfiguration(
        database: db,
        target: UrlEndpoint(testSyncGatewayUrl),
      );
      final repl = Replicator(config);
      final configA = repl.config;
      final configB = repl.config;
      expect(configA, isNot(same(config)));
      expect(configA, isNot(same(configB)));
    });

    test('continuous replication', () async {
      final pushDb = await openTestDb('ContinuousReplication-Push');
      final pullDb = await openTestDb('ContinuousReplication-Pull');

      final pusher = pushDb.createTestReplicator(
        replicatorType: ReplicatorType.push,
        continuous: true,
      );
      await pusher.start();

      final puller = pullDb.createTestReplicator(
        replicatorType: ReplicatorType.pull,
        continuous: true,
      );
      await puller.start();

      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final doc =
          MutableDocument.withId('continuouslyReplicatedDoc-$timestamp');

      final stream = pullDb.watchAllIds().shareReplay();

      // ignore: unawaited_futures
      stream.first.then((_) => pushDb.saveDocument(doc));

      expect(
        stream,
        emitsInOrder(<dynamic>[
          isNot(contains(doc.id)),
          contains(doc.id),
        ]),
      );
    });

    test('use documentIds to filter replicated documents', () async {
      // Insert doc A and B into push db
      // Sync push db  with server with documentIds == [docA.id]
      // Sync pull db  with server
      // => pull db contains doc A

      final pushDb = await openTestDb('ReplicationWithDocumentIds-Push');
      final pullDb = await openTestDb('ReplicationWithDocumentIds-Pull');

      final docA = MutableDocument();
      await pushDb.saveDocument(docA);
      final docB = MutableDocument();
      await pushDb.saveDocument(docB);

      final pusher = pushDb.createTestReplicator(
        replicatorType: ReplicatorType.push,
        documentIds: [docA.id],
      );
      await pusher.replicateOneShot();

      final puller = pullDb.createTestReplicator(
        replicatorType: ReplicatorType.pull,
      );
      await puller.replicateOneShot();

      final idsInPullDb = await pullDb.getAllIds().toList();
      expect(idsInPullDb, contains(docA.id));
    });

    test('use channels to filter pulled documents', () async {
      // Insert doc A and B into push db, where doc A is in channel A
      // Sync push db with server
      // Sync pull db with server with channels == ['A']
      // => pull db contains doc A

      final pushDb = await openTestDb('ReplicationWithChannels-Push');
      final pullDb = await openTestDb('ReplicationWithChannels-Push');

      final docA = MutableDocument({'channels': 'A'});
      await pushDb.saveDocument(docA);
      final docB = MutableDocument();
      await pushDb.saveDocument(docB);

      final pusher = pushDb.createTestReplicator(
        replicatorType: ReplicatorType.push,
      );
      await pusher.replicateOneShot();

      final puller = pullDb.createTestReplicator(
        replicatorType: ReplicatorType.pull,
        channels: ['A'],
      );
      await puller.replicateOneShot();

      final idsInPullDb = await pullDb.getAllIds().toList();
      expect(idsInPullDb, contains(docA.id));
    });

    test('use pushFilter to filter pushed documents', () async {
      final pushDb = await openTestDb('ReplicationWithPushFilter-Push');
      final pullDb = await openTestDb('ReplicationWithPushFilter-Pull');

      final docA = MutableDocument();
      await pushDb.saveDocument(docA);
      final docB = MutableDocument();
      await pushDb.saveDocument(docB);

      final pusher = pushDb.createTestReplicator(
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

      final puller = pullDb.createTestReplicator(
        replicatorType: ReplicatorType.pull,
      );
      await puller.replicateOneShot();

      final idsInPullDb = await pullDb.getAllIds().toList();
      expect(idsInPullDb, contains(docA.id));
      expect(idsInPullDb, isNot(contains(docB.id)));
    });

    test('pushFilter exception handling', () async {
      Object? uncaughtError;
      await runZonedGuarded(() async {
        final pushDb =
            await openTestDb('PushFilterExceptionHandling-Throws-Push');
        final pullDb =
            await openTestDb('PushFilterExceptionHandling-Throws-Pull');

        final doc = MutableDocument();
        await pushDb.saveDocument(doc);

        final pusher = pushDb.createTestReplicator(
          replicatorType: ReplicatorType.push,
          pushFilter: (document, flags) {
            throw 'Push failed';
          },
        );

        await pusher.replicateOneShot();

        final puller = pullDb.createTestReplicator(
          replicatorType: ReplicatorType.pull,
        );

        await puller.replicateOneShot();

        // Documents where filter throws are not pushed.
        expect(await pullDb.getDocument(doc.id), isNull);
      }, (error, _) {
        uncaughtError = error;
      });
      expect(uncaughtError, 'Push failed');
    });

    test('use pullFilter to filter pulled documents', () async {
      final pushDb = await openTestDb('PullFilterExceptionHandling-Push');
      final pullDb = await openTestDb('PullFilterExceptionHandling-Pull');

      final docA = MutableDocument();
      await pushDb.saveDocument(docA);
      final docB = MutableDocument();
      await pushDb.saveDocument(docB);

      final pusher = pushDb.createTestReplicator(
        replicatorType: ReplicatorType.push,
      );
      await pusher.replicateOneShot();

      final puller = pullDb.createTestReplicator(
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

      final idsInPullDb = await pullDb.getAllIds().toList();
      expect(idsInPullDb, contains(docA.id));
      expect(idsInPullDb, isNot(contains(docB.id)));
    });

    test('pullFilter exception handling', () async {
      Object? uncaughtError;
      await runZonedGuarded(() async {
        final pushDb =
            await openTestDb('ReplicationWithPullFilter-Throws-Push');
        final pullDb =
            await openTestDb('ReplicationWithPullFilter-Throws-Pull');

        final doc = MutableDocument();
        await pushDb.saveDocument(doc);

        final pusher = pushDb.createTestReplicator(
          replicatorType: ReplicatorType.push,
        );

        await pusher.replicateOneShot();

        final puller = pullDb.createTestReplicator(
          replicatorType: ReplicatorType.pull,
          pullFilter: (document, flags) {
            throw 'Pull failed';
          },
        );

        await puller.replicateOneShot();

        // Documents where filter throws are not pulled.
        expect(await pullDb.getDocument(doc.id), isNull);
      }, (error, _) {
        uncaughtError = error;
      });
      expect(uncaughtError, 'Pull failed');
    });

    test('custom conflict resolver', () async {
      // Create document in db A
      // Sync db A with server
      // Sync db B with server
      // Change doc in db A
      // Change doc in db B
      // Sync db B with server
      // Sync db A with server
      // => Conflict in db A

      final dbA = await openTestDb('ConflictResolver-DB-A');
      final replicatorA = dbA.createTestReplicator(
        conflictResolver: expectAsync1((conflict) {
          expect(conflict.documentId, testDocumentId);
          expect(conflict.localDocument, isTestDocument('DB-A-2'));
          expect(conflict.remoteDocument, isTestDocument('DB-B-1'));
          return conflict.remoteDocument;
        }),
      );

      final dbB = await openTestDb('ConflictResolver-DB-B');
      final replicatorB = dbB.createTestReplicator();

      await dbA.writeTestDocument('DB-A-1');
      await replicatorA.replicateOneShot();
      await replicatorB.replicateOneShot();
      await dbA.writeTestDocument('DB-A-2');
      await dbB.writeTestDocument('DB-B-1');
      await replicatorB.replicateOneShot();
      await replicatorA.replicateOneShot();

      expect(await dbA.getTestDocumentOrNull(), isTestDocument('DB-B-1'));
    });

    test('conflict resolver exception handling', () async {
      Object? uncaughtError;
      await runZonedGuarded(() async {
        final dbA = await openTestDb('ConflictResolver-Exception-Handling-A');
        final replicatorA = dbA.createTestReplicator(
          conflictResolver: expectAsync1((conflict) {
            throw 'Conflict resolver failed';
          }),
        );

        final dbB = await openTestDb('ConflictResolver-Exception-Handling-B');
        final replicatorB = dbB.createTestReplicator();

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
      expect(uncaughtError, 'Conflict resolver failed');
    });

    test('status returns the current status of the replicator', () async {
      final db = await openTestDb('GetReplicatorStatus');
      final replicator = db.createTestReplicator();
      final status = await replicator.status();
      expect(status.activity, ReplicatorActivityLevel.stopped);
      expect(status.error, isNull);
      expect(status.progress.progress, 0);
      expect(status.progress.completed, 0);
    });

    test('statusChanges emits when the replicators status changes', () async {
      final db = await openTestDb('ReplicatorStatusChanges');
      final replicator = db.createTestReplicator();

      expect(
        replicator.changes().map((it) => it.status.activity),
        emitsThrough(ReplicatorActivityLevel.stopped),
      );

      await replicator.start();
    });

    test('pendingDocumentIds returns ids of documents waiting to be pushed',
        () async {
      final db = await openTestDb('PendingDocumentIds');
      final replicator = db.createTestReplicator();
      final doc = MutableDocument();
      await db.saveDocument(doc);
      final pendingDocumentIds = await replicator.pendingDocumentIds();
      expect(pendingDocumentIds, [doc.id]);
    });

    test('isDocumentPending returns whether a document is waiting to be pushed',
        () async {
      final db = await openTestDb('IsDocumentPending');
      final replicator = db.createTestReplicator();
      final doc = MutableDocument();
      await db.saveDocument(doc);
      expect(await replicator.isDocumentPending(doc.id), isTrue);
    });

    test(
        'documentReplications emits events when documents have been replicated',
        () async {
      final db = await openTestDb('DocumentReplications');
      final replicator = db.createTestReplicator(
        replicatorType: ReplicatorType.push,
      );
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

      await replicator.start();
    });

    test('start and stop', () async {
      final db = await openTestDb('Replicator-Start-Stop');
      final repl = db.createTestReplicator(continuous: true);

      await repl.driveToStatus(
        hasActivityLevel(ReplicatorActivityLevel.idle),
        repl.start,
      );
      await repl.driveToStatus(
        hasActivityLevel(ReplicatorActivityLevel.stopped),
        repl.stop,
      );
    });
  });
}
