import 'dart:async';

import '../database/collection.dart';
import '../database/database.dart';
import '../document/document.dart';
import '../support/listener_token.dart';
import '../support/resource.dart';
import '../support/streams.dart';
import 'configuration.dart';
import 'document_replication.dart';
import 'ffi_replicator.dart';
import 'proxy_replicator.dart';
import 'replicator_change.dart';

/// The states a [Replicator] can be in during its lifecycle.
///
/// {@category Replication}
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
///
/// {@category Replication}
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
///
/// {@category Replication}
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
          activity.name,
          if (progress.completed != 0) 'progress: $progress',
          if (error != null) 'error: $error',
        ].join(', '),
        ')',
      ].join();
}

/// A listener that is called when a [Replicator]s [Replicator.status] changes.
///
/// {@category Replication}
typedef ReplicatorChangeListener = void Function(ReplicatorChange change);

/// A listener that is called when a [Replicator] has replicated one or more
/// [Document]s.
///
/// {@category Replication}
typedef DocumentReplicationListener = void Function(
  DocumentReplication change,
);

/// A replicator for replicating [Document]s between a local database and a
/// target database.
///
/// The replicator can be bidirectional or either push or pull. The replicator
/// can also be one-shot ore continuous. The replicator runs asynchronously, so
/// observe the [status] to be notified of progress.
///
/// {@category Replication}
abstract class Replicator implements ClosableResource {
  /// Creates a replicator for replicating [Document]s between a local
  /// [Database] and a target database.
  static Future<Replicator> create(ReplicatorConfiguration config) {
    config.validate();

    // ignore: deprecated_member_use_from_same_package
    if (config.database is AsyncDatabase ||
        config.collections.keys
            .any((collection) => collection is AsyncCollection)) {
      return Replicator.createAsync(config);
    }

    // ignore: deprecated_member_use_from_same_package
    if (config.database is SyncDatabase ||
        config.collections.keys
            .any((collection) => collection is SyncCollection)) {
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
  static Future<SyncReplicator> createSync(ReplicatorConfiguration config) =>
      SyncReplicator.create(config);

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
  /// [ReplicatorActivityLevel.stopped]. and the [changes] stream will be
  /// notified accordingly.
  FutureOr<void> stop();

  /// Adds a [listener] to be notified of changes to the [status] of this
  /// replicator.
  ///
  /// {@macro cbl.Collection.addChangeListener}
  ///
  /// See also:
  ///
  /// - [ReplicatorChange] for the change event given to [listener].
  /// - [addDocumentReplicationListener] for listening for
  ///   [DocumentReplication]s performed by this replicator.
  /// - [removeChangeListener] for removing a previously added listener.
  FutureOr<ListenerToken> addChangeListener(ReplicatorChangeListener listener);

  /// Adds a [listener] to be notified of [DocumentReplication]s performed by
  /// this replicator.
  ///
  /// {@template cbl.Replicator.addDocumentReplicationListener.listening}
  /// Because of performance optimization in the replicator, document
  /// replications need to be listened to before starting the replicator. If the
  /// listener is added after the replicator is started, the replicator needs to
  /// be stopped and restarted again to ensure that the listener will get the
  /// document replication events.
  /// {@endtemplate}
  ///
  /// {@macro cbl.Collection.addChangeListener}
  ///
  /// See also:
  ///
  /// - [DocumentReplication] for the change event given to [listener].
  /// - [addChangeListener] for listening for changes to the [status] this
  ///   replicator.
  /// - [removeChangeListener] for removing a previously added listener.
  FutureOr<ListenerToken> addDocumentReplicationListener(
    DocumentReplicationListener listener,
  );

  /// {@macro cbl.Collection.removeChangeListener}
  ///
  /// See also:
  ///
  /// - [addChangeListener] for listening for changes to the [status] this
  ///   replicator.
  /// - [addDocumentReplicationListener] for listening for
  ///   [DocumentReplication]s performed by this replicator.
  FutureOr<void> removeChangeListener(ListenerToken token);

  /// Returns a [Stream] to be notified of changes to the [status] of this
  /// replicator.
  ///
  /// This is an alternative stream based API for the [addChangeListener] API.
  ///
  /// {@macro cbl.Collection.AsyncListenStream}
  Stream<ReplicatorChange> changes();

  /// Returns a [Stream] to be notified of [DocumentReplication]s performed by
  /// this replicator.
  ///
  /// This is an alternative stream based API for the
  /// [addDocumentReplicationListener] API.
  ///
  /// {@macro cbl.Replicator.addDocumentReplicationListener.listening}
  ///
  /// {@macro cbl.Collection.AsyncListenStream}
  Stream<DocumentReplication> documentReplications();

  /// Returns a [Set] of ids for [Document]s in the default collection, who have
  /// revisions pending to be pushed.
  ///
  /// This API is a snapshot and results may change between the time the call
  /// was mad and the time the call returns.
  @Deprecated('Use pendingDocumentIdsInCollection instead.')
  FutureOr<Set<String>> get pendingDocumentIds;

  /// Returns whether the [Document] with the given [documentId], in the default
  /// collection, has revisions pending to be pushed.
  ///
  /// This API is a snapshot and the result may change between the time the call
  /// was made and the time the call returns.
  @Deprecated('Use isDocumentPendingInCollection instead.')
  FutureOr<bool> isDocumentPending(String documentId);

  /// Returns a [Set] of ids for [Document]s in the given [collection], who have
  /// revisions pending to be pushed.
  ///
  /// This API is a snapshot and results may change between the time the call
  /// was mad and the time the call returns.
  FutureOr<Set<String>> pendingDocumentIdsInCollection(Collection collection);

  /// Returns whether the [Document] with the given [documentId], in the given
  /// [collection], has revisions pending to be pushed.
  ///
  /// This API is a snapshot and the result may change between the time the call
  /// was made and the time the call returns.
  FutureOr<bool> isDocumentPendingInCollection(
    String documentId,
    Collection collection,
  );
}

/// A [Replicator] with a primarily synchronous API.
///
/// {@category Replication}
abstract class SyncReplicator implements Replicator {
  /// {@macro cbl.Replicator.createSync}
  static Future<SyncReplicator> create(ReplicatorConfiguration config) =>
      FfiReplicator.create(config);

  @override
  ReplicatorStatus get status;

  @override
  void start({bool reset = false});

  @override
  void stop();

  @override
  ListenerToken addChangeListener(ReplicatorChangeListener listener);

  @override
  ListenerToken addDocumentReplicationListener(
    DocumentReplicationListener listener,
  );

  @override
  void removeChangeListener(ListenerToken token);

  @Deprecated('Use pendingDocumentIdsInCollection instead.')
  @override
  Set<String> get pendingDocumentIds;

  @Deprecated('Use isDocumentPendingInCollection instead.')
  @override
  bool isDocumentPending(String documentId);

  @override
  Set<String> pendingDocumentIdsInCollection(Collection collection);

  @override
  bool isDocumentPendingInCollection(
    String documentId,
    Collection collection,
  );
}

/// A [Replicator] with a primarily asynchronous API.
///
/// {@category Replication}
abstract class AsyncReplicator implements Replicator {
  /// {@macro cbl.Replicator.createAsync}
  static Future<AsyncReplicator> create(ReplicatorConfiguration config) =>
      ProxyReplicator.create(config);

  @override
  Future<ReplicatorStatus> get status;

  @override
  Future<void> start({bool reset = false});

  @override
  Future<void> stop();

  @override
  Future<ListenerToken> addChangeListener(ReplicatorChangeListener listener);

  @override
  Future<ListenerToken> addDocumentReplicationListener(
    DocumentReplicationListener listener,
  );

  @override
  Future<void> removeChangeListener(ListenerToken token);

  @override
  AsyncListenStream<ReplicatorChange> changes();

  @override
  AsyncListenStream<DocumentReplication> documentReplications();

  @Deprecated('Use pendingDocumentIdsInCollection instead.')
  @override
  Future<Set<String>> get pendingDocumentIds;

  @Deprecated('Use isDocumentPendingInCollection instead.')
  @override
  Future<bool> isDocumentPending(String documentId);

  @override
  Future<Set<String>> pendingDocumentIdsInCollection(Collection collection);

  @override
  Future<bool> isDocumentPendingInCollection(
    String documentId,
    Collection collection,
  );
}
