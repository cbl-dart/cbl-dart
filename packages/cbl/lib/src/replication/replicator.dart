import 'dart:async';

import '../database/database.dart';
import '../document/document.dart';
import '../support/resource.dart';
import '../support/utils.dart';
import 'configuration.dart';
import 'document_replication.dart';
import 'ffi_replicator.dart';
import 'replicator_change.dart';

/// The states a [Replicator] can be in during its lifecycle.
enum ReplicatorActivityLevel {
  /// The replicator is unstarted, finished, or hit a fatal error.
  stopped,

  /// The replicator is offline, as the remote host is unreachable.
  offline,

  /// The replicator is connecting to the remote host.
  connecting,

  /// The replicator is inactive, waiting for changes to sync.
  idle,

  /// The replicator is actively transferring data.
  busy,
}

/// Progress of a [Replicator].
///
/// If [progress] is zero, the process is indeterminate; otherwise, dividing the
/// two will produce a fraction that can be used to draw a progress bar.
class ReplicatorProgress {
  ReplicatorProgress(this.completed, this.progress);

  /// The number of [Document]s processed so far.
  final int completed;

  /// The overall progress as a number between `0.0` and `1.0`.
  ///
  /// The value is very approximate and may bounce around during replication;
  /// making it more accurate would require slowing down the replicator and
  /// incurring more load on the server.
  final double progress;

  @override
  String toString() => 'ReplicatorProgress('
      '${(progress * 100).toStringAsFixed(1)}%; '
      // ignore: missing_whitespace_between_adjacent_strings
      'completed: $completed'
      ')';
}

/// Combined [ReplicatorActivityLevel], [ReplicatorProgress] and possibly error
/// of a [Replicator].
class ReplicatorStatus {
  ReplicatorStatus(this.activity, this.progress, this.error);

  /// The current activity level of the [Replicator].
  final ReplicatorActivityLevel activity;

  /// The current progress of the [Replicator].
  final ReplicatorProgress progress;

  /// The current error of the [Replicator], if one has occurred.
  final Object? error;

  @override
  String toString() => [
        'ReplicatorStatus(',
        [
          describeEnum(activity),
          if (progress.completed != 0) 'progress: $progress',
          if (error != null) 'error: $error',
        ].join(', '),
        ')',
      ].join();
}

/// A replicator for replicating [Document]s between a local database and a
/// target database.
///
/// The replicator can be bidirectional or either push or pull. The replicator
/// can also be one-shot ore continuous. The replicator runs asynchronously, so
/// observe the [status] to be notified of progress.
abstract class Replicator implements ClosableResource {
  /// Creates a replicator for replicating [Document]s between a local
  /// [Database] and a target database.
  static FutureOr<Replicator> create(ReplicatorConfiguration config) {
    if (config.database is AsyncDatabase) {
      return Replicator.createAsync(config);
    }

    if (config.database is SyncDatabase) {
      return Replicator.createSync(config);
    }

    throw UnimplementedError();
  }

  /// {@template cbl.Replicator.createAsync}
  /// Creates a replicator for replicating [Document]s between a local
  /// [AsyncDatabase] and a target database.
  /// {@endtemplate}
  static Future<AsyncReplicator> createAsync(ReplicatorConfiguration config) =>
      AsyncReplicator.create(config);

  /// {@template cbl.Replicator.createSync}
  /// Creates a replicator for replicating [Document]s between a local
  /// [SyncDatabase] and a target database.
  /// {@endtemplate}
  // ignore: prefer_constructors_over_static_methods
  static SyncReplicator createSync(ReplicatorConfiguration config) =>
      SyncReplicator(config);

  /// This replicator's configuration.
  ReplicatorConfiguration get config;

  /// Returns this replicator's status.
  FutureOr<ReplicatorStatus> get status;

  /// Starts this replicator with an option to [reset] the local checkpoint of
  /// the replicator.
  ///
  /// When the local checkpoint is reset, the replicator will sync all changes
  /// since the beginning of time from the remote database.
  ///
  /// The method returns immediately; the replicator runs asynchronously and
  /// will report its progress through the [changes] stream.
  FutureOr<void> start({bool reset = false});

  /// Stops this replicator, if running.
  ///
  /// This method returns immediately; when the replicator actually stops, the
  /// replicator will change the [ReplicatorActivityLevel] of its [status] to
  /// [ReplicatorActivityLevel.stopped]. and the [changes] stream will
  /// be notified accordingly.
  FutureOr<void> stop();

  /// Returns a [Stream] which emits a [ReplicatorChange] event when this
  /// replicators [status] changes.
  Stream<ReplicatorChange> changes();

  /// Returns a [Stream] wich emits a [DocumentReplication] event when a set
  /// of [Document]s have been replicated.
  ///
  /// Because of performance optimization in the replicator, the returned
  /// [Stream] needs to be listened to before starting the replicator. If the
  /// [Stream] is listened to after this replicator is started, the replicator
  /// needs to be stopped and restarted again to ensure that the [Stream] will
  /// get the document replication events.
  Stream<DocumentReplication> documentReplications();

  /// Returns a [Set] of [Document] ids, who have revisions pending push.
  ///
  /// This API is a snapshot and results may change between the time the call
  /// was mad and the time the call returns.
  FutureOr<Set<String>> get pendingDocumentIds;

  /// Returns whether the [Document] with the given [documentId] has revisions
  /// pending push.
  ///
  /// This API is a snapshot and the result may change between the time the call
  /// was made and the time the call returns.
  FutureOr<bool> isDocumentPending(String documentId);
}

/// A [Replicator] with a primarily synchronous API.
abstract class SyncReplicator implements Replicator {
  /// {@macro cbl.Replicator.createSync}
  factory SyncReplicator(ReplicatorConfiguration config) => FfiReplicator(
        config,
        debugCreator: 'SyncReplicator()',
      );

  @override
  ReplicatorStatus get status;

  @override
  void start({bool reset = false});

  @override
  void stop();

  @override
  Set<String> get pendingDocumentIds;

  @override
  bool isDocumentPending(String documentId);
}

/// A [Replicator] with a primarily asynchronous API.
abstract class AsyncReplicator implements Replicator {
  /// {@macro cbl.Replicator.createAsync}
  static Future<AsyncReplicator> create(ReplicatorConfiguration config) =>
      throw UnimplementedError();

  @override
  Future<ReplicatorStatus> get status;

  @override
  Future<void> start({bool reset = false});

  @override
  Future<void> stop();

  @override
  Future<Set<String>> get pendingDocumentIds;

  @override
  Future<bool> isDocumentPending(String documentId);
}
