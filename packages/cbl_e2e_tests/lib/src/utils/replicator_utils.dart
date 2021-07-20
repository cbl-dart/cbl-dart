import 'dart:async';

import 'package:cbl/cbl.dart';

import '../test_binding.dart';
import 'database_utils.dart';

final testSyncGatewayUrl = Uri.parse('ws://localhost:4984/db');

extension ReplicatorUtilsDatabaseExtension on Database {
  /// Creates a replicator which is configured with the test sync gateway
  /// endpoint.
  Future<Replicator> createTestReplicator({
    ReplicatorType? replicatorType,
    bool? continuous,
    List<String>? channels,
    List<String>? documentIds,
    ReplicationFilter? pushFilter,
    ReplicationFilter? pullFilter,
    ConflictResolverFunction? conflictResolver,
  }) async =>
      Replicator(ReplicatorConfiguration(
        database: this,
        target: UrlEndpoint(testSyncGatewayUrl),
        replicatorType: replicatorType ?? ReplicatorType.pushAndPull,
        continuous: continuous ?? false,
        channels: channels,
        documentIds: documentIds,
        pushFilter: pushFilter,
        pullFilter: pullFilter,
        conflictResolver: conflictResolver != null
            ? ConflictResolver.from(conflictResolver)
            : null,
      ));
}

extension ReplicatorUtilsExtension on Replicator {
  Future<T> waitForActivityLevel<T>(
    ReplicatorActivityLevel level,
    FutureOr<T> Function() fn,
  ) async {
    final statusReached = changes().firstWhere((change) {
      var error = change.status.error;
      if (error != null) {
        throw error;
      }
      return change.status.activity == level;
    });
    final result = await fn();
    await statusReached;
    return result;
  }

  /// Starts this replicator and waits until it stops. If it stops with an
  /// error, that error is thrown.
  Future<void> startAndWaitUntilStopped() async {
    var lastStatus = await status();
    if (lastStatus.activity != ReplicatorActivityLevel.stopped) {
      throw StateError('Expected replicator to be stopped');
    }

    await waitForActivityLevel(ReplicatorActivityLevel.stopped, start);
  }
}

/// Clears the db of the test server by first pulling all documents into a local
/// db, deleting them and then pushing the changes to the server db.
Future<void> clearTestServerDb() async {
  final db = await openTestDb('ClearTestServer', autoClose: false);
  addTearDown(db.delete);

  final pullReplicator =
      await db.createTestReplicator(replicatorType: ReplicatorType.pull);

  await pullReplicator.startAndWaitUntilStopped();

  final didDeleteDocuments = await db.deleteAllDocuments();

  if (didDeleteDocuments) {
    final pushReplicator =
        await db.createTestReplicator(replicatorType: ReplicatorType.push);
    await pushReplicator.startAndWaitUntilStopped();
  }
}
