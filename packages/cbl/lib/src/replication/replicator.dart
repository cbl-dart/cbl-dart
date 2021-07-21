import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';
import 'package:collection/collection.dart';

import '../database.dart';
import '../document/document.dart';
import '../errors.dart';
import '../fleece/fleece.dart' as fl;
import '../native_callback.dart';
import '../native_object.dart';
import '../resource.dart';
import '../streams.dart';
import '../utils.dart';
import '../worker/cbl_worker.dart';
import 'authenticator.dart';
import 'configuration.dart';
import 'conflict.dart';
import 'conflict_resolver.dart';
import 'document_replication.dart';
import 'endpoint.dart';
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
  ReplicatorProgress._(this.completed, this.progress);

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
      'completed: $completed'
      ')';
}

/// Combined [ReplicatorActivityLevel], [ReplicatorProgress] and possibly error
/// of a [Replicator].
class ReplicatorStatus {
  ReplicatorStatus._(this.activity, this.progress, this.error);

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
  /// Creates a replicator for replicating [Document]s between a local database
  /// and a target database.
  factory Replicator(ReplicatorConfiguration config) => ReplicatorImpl(
        config,
        debugCreator: 'Replicator()',
      );

  /// This replicator's configuration.
  ReplicatorConfiguration get config;

  /// Returns this replicator's status.
  Future<ReplicatorStatus> status();

  /// Starts this replicator with an option to [reset] the local checkpoint of
  /// the replicator.
  ///
  /// When the local checkpoint is reset, the replicator will sync all changes
  /// since the beginning of time from the remote database.
  ///
  /// The method returns immediately; the replicator runs asynchronously and
  /// will report its progress through the [changes] stream.
  Future<void> start({bool reset = false});

  /// Stops this replicator, if running.
  ///
  /// This method returns immediately; when the replicator actually stops, the
  /// replicator will change the [ReplicatorActivityLevel] of its [status] to
  /// [ReplicatorActivityLevel.stopped]. and the [changes] stream will
  /// be notified accordingly.
  Future<void> stop();

  /// Returns a [Stream] which emits a [ReplicatorChange] event when this
  /// replicators [status] changes.
  Stream<ReplicatorChange> changes({bool startWithCurrentStatus = false});

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
  Future<Set<String>> pendingDocumentIds();

  /// Returns whether the [Document] with the given [documentId] has revisions
  /// pending push.
  ///
  /// This API is a snapshot and the result may change between the time the call
  /// was made and the time the call returns.
  Future<bool> isDocumentPending(String documentId);
}

late final _bindings = CBLBindings.instance.replicator;

class ReplicatorImpl with ClosableResourceMixin implements Replicator {
  ReplicatorImpl(this._config, {required String debugCreator}) {
    final database = _database = (_config.database as DatabaseImpl);

    runKeepAlive(() {
      final pushFilterCallback =
          config.pushFilter?.let((it) => _wrapReplicationFilter(database, it));
      final pullFilterCallback =
          config.pullFilter?.let((it) => _wrapReplicationFilter(database, it));
      final conflictResolverCallback = config.conflictResolver
          ?.let((it) => _wrapConflictResolver(database, it));

      _callbacks = [
        pushFilterCallback,
        pullFilterCallback,
        conflictResolverCallback
      ].whereNotNull().toList();

      final endpoint = config.createEndpoint();
      final authenticator = config.createAuthenticator();

      try {
        final replicator =
            withCBLErrorExceptionTranslation(() => _bindings.createReplicator(
                  database.native.pointer,
                  endpoint,
                  config.replicatorType.toCBLReplicatorType(),
                  config.continuous,
                  null,
                  config.maxRetries + 1,
                  config.maxRetryWaitTime.inSeconds,
                  config.heartbeat.inSeconds,
                  authenticator,
                  null,
                  null,
                  null,
                  null,
                  null,
                  config.headers
                      ?.let((it) => fl.MutableDict(it).native.pointer.cast()),
                  config.pinnedServerCertificate,
                  null,
                  config.channels
                      ?.let((it) => fl.MutableArray(it).native.pointer.cast()),
                  config.documentIds
                      ?.let((it) => fl.MutableArray(it).native.pointer.cast()),
                  pushFilterCallback?.native.pointer,
                  pullFilterCallback?.native.pointer,
                  conflictResolverCallback?.native.pointer,
                ));

        _replicator = CBLReplicatorObject(
          replicator,
          debugName: 'Replicator(creator: $debugCreator)',
        );

        database.registerChildResource(this);
      } catch (e) {
        _disposeCallbacks();
        rethrow;
      } finally {
        _bindings.freeEndpoint(endpoint);
        if (authenticator != null) {
          _bindings.freeAuthenticator(authenticator);
        }
      }
    });
  }

  final ReplicatorConfiguration _config;

  late final DatabaseImpl _database;

  Worker get _worker => _database.native.worker;

  late final NativeObject<CBLReplicator> _replicator;

  late final List<NativeCallback> _callbacks;

  @override
  ReplicatorConfiguration get config => ReplicatorConfiguration.from(_config);

  @override
  Future<ReplicatorStatus> status() => use(_status);

  Future<ReplicatorStatus> _status() => runKeepAlive(() {
        return _worker.execute(GetReplicatorStatus(_replicator.pointer));
      });

  @override
  Future<void> start({bool reset = false}) => use(() => runKeepAlive(() {
        return _worker.execute(StartReplicator(_replicator.pointer, reset));
      }));

  @override
  Future<void> stop() => use(_stop);

  Future<void> _stop() => runKeepAlive(() {
        return _worker.execute(StopReplicator(_replicator.pointer));
      });

  @override
  Stream<ReplicatorChange> changes({bool startWithCurrentStatus = false}) =>
      useSync(() => _changes(startWithCurrentStatus: startWithCurrentStatus));

  Stream<ReplicatorChange> _changes({bool startWithCurrentStatus = false}) {
    final changes = CallbackStreamController<ReplicatorChange, void>(
      parent: this,
      worker: _database.native.worker,
      createRegisterCallbackRequest: (callback) => AddReplicatorChangeListener(
        _replicator.pointerUnsafe,
        callback.native.pointerUnsafe,
      ),
      createEvent: (_, arguments) {
        final message =
            ReplicatorStatusCallbackMessage.fromArguments(arguments);
        return ReplicatorChangeImpl(
          this,
          message.status.ref.toReplicatorStatus(),
        );
      },
    ).stream;

    if (startWithCurrentStatus) {
      return changeStreamWithInitialValue(
        createInitialValue: () async =>
            ReplicatorChangeImpl(this, await _status()),
        createChangeStream: () => changes,
      );
    } else {
      return changes;
    }
  }

  @override
  Stream<DocumentReplication> documentReplications() =>
      useSync(() => CallbackStreamController(
            parent: this,
            worker: _database.native.worker,
            createRegisterCallbackRequest: (callback) =>
                AddReplicatorDocumentListener(
              _replicator.pointerUnsafe,
              callback.native.pointerUnsafe,
            ),
            createEvent: (_, arguments) {
              final message =
                  DocumentReplicationsCallbackMessage.fromArguments(arguments);

              final documents = List.generate(
                message.documentCount,
                (index) => message.documents.elementAt(index),
              ).map((it) => it.ref.toReplicatedDocument()).toList();

              return DocumentReplicationImpl(this, message.isPush, documents);
            },
          ).stream);

  @override
  Future<Set<String>> pendingDocumentIds() => use(() => runKeepAlive(() async {
        final dict = fl.Dict.fromPointer(
          (await _worker.execute(
                  GetReplicatorPendingDocumentIds(_replicator.pointer)))
              .pointer,
          retain: false,
          release: true,
        );
        return dict.keys.toSet();
      }));

  @override
  Future<bool> isDocumentPending(String documentId) =>
      use(() => runKeepAlive(() {
            return _worker.execute(GetReplicatorIsDocumentPening(
              _replicator.pointer,
              documentId,
            ));
          }));

  @override
  Future<void> performClose() async {
    try {
      final status =
          _changes(startWithCurrentStatus: true).map((change) => change.status);

      var stopping = false;

      await status.asyncMap((status) async {
        if (status.activity != ReplicatorActivityLevel.stopped && !stopping) {
          stopping = true;
          await _stop();
        }
        return status;
      }).firstWhere((status) {
        return status.activity == ReplicatorActivityLevel.stopped;
      });
    } finally {
      _disposeCallbacks();
    }
  }

  void _disposeCallbacks() =>
      _callbacks.forEach((callback) => callback.close());

  @override
  String toString() => [
        'Replicator(',
        [
          'database: $_database',
          'type: ${describeEnum(config.replicatorType)}',
          if (config.continuous) 'CONTINUOUS'
        ].join(', '),
        ')'
      ].join();
}

extension on ReplicatorType {
  CBLReplicatorType toCBLReplicatorType() => CBLReplicatorType.values[index];
}

extension on CBLReplicatorActivityLevel {
  ReplicatorActivityLevel toReplicatorActivityLevel() =>
      ReplicatorActivityLevel.values[index];
}

extension on CBLReplicatedDocumentFlag {
  DocumentFlag toReplicatedDocumentFlag() =>
      DocumentFlag.values[CBLReplicatedDocumentFlag.values.indexOf(this)];
}

extension CBLReplicatorStatusExt on CBLReplicatorStatus {
  ReplicatorStatus toReplicatorStatus() => ReplicatorStatus._(
        activity.toReplicatorActivityLevel(),
        ReplicatorProgress._(
          progress.documentCount,
          progress.complete,
        ),
        exception?.translate(),
      );
}

extension on CBLDart_ReplicatedDocument {
  ReplicatedDocument toReplicatedDocument() => ReplicatedDocumentImpl(
        ID,
        flags.map((flag) => flag.toReplicatedDocumentFlag()).toSet(),
        exception?.translate(),
      );
}

extension on ReplicatorConfiguration {
  Pointer<CBLEndpoint> createEndpoint() {
    final target = this.target;
    if (target is UrlEndpoint) {
      return _bindings.createEndpointWithUrl(target.url.toString());
    } else {
      throw UnimplementedError('Endpoint type is not implemented: $target');
    }
  }

  Pointer<CBLAuthenticator>? createAuthenticator() {
    final authenticator = this.authenticator;
    if (authenticator == null) return null;

    if (authenticator is BasicAuthenticator) {
      return _bindings.createPasswordAuthenticator(
        authenticator.username,
        authenticator.password,
      );
    } else if (authenticator is SessionAuthenticator) {
      return _bindings.createSessionAuthenticator(
        authenticator.sessionId,
        authenticator.cookieName,
      );
    } else {
      throw UnimplementedError(
        'Authenticator type is not implemented: $authenticator',
      );
    }
  }
}

NativeCallback _wrapReplicationFilter(
  DatabaseImpl database,
  ReplicationFilter filter,
) =>
    NativeCallback((arguments) async {
      final message = ReplicationFilterCallbackMessage.fromArguments(arguments);
      final doc = DocumentImpl(
        database: database,
        doc: message.document,
        retain: true,
        debugCreator: 'ReplicationFilter()',
      );

      var decision = false;
      try {
        decision = await filter(
          doc,
          message.flags.map((flag) => flag.toReplicatedDocumentFlag()).toSet(),
        );
      } finally {
        return decision;
      }
    });

NativeCallback _wrapConflictResolver(
  DatabaseImpl database,
  ConflictResolver resolver,
) =>
    NativeCallback((arguments) async {
      final message =
          ReplicationConflictResolverCallbackMessage.fromArguments(arguments);

      final local = message.localDocument?.let((it) => DocumentImpl(
            database: database,
            doc: it,
            retain: true,
            debugCreator: 'ConflictResolver(local)',
          ));

      final remote = message.remoteDocument?.let((it) => DocumentImpl(
            database: database,
            doc: it,
            retain: true,
            debugCreator: 'ConflictResolver(remote)',
          ));

      var resolved = remote;
      // TODO: throw on the native side when resolver throws
      // Also review whether other callbacks can be aborted.
      try {
        final conflict = ConflictImpl(message.documentId, local, remote);
        resolved = await resolver.resolve(conflict) as DocumentImpl?;
        if (resolved is MutableDocumentImpl) {
          resolved.database = database;
          await resolved.flushProperties();
        }
      } finally {
        final resolvedPointer = resolved?.doc.pointerUnsafe;

        // If the resolver returned a document other than `local` or `remote`,
        // the ref count of `resolved` needs to be incremented because the
        // native conflict resolver callback is expected to returned a document
        // with a ref count of +1, which the caller balances with a release.
        // This must happen on the Dart side, because `resolved` can be garbage
        // collected before `resolvedAddress` makes it back to the native side.
        // if (resolvedPointer != null &&
        //     resolved != local &&
        //     resolved != remote) {
        //   CBLBindings.instance.base.retainRefCounted(resolvedPointer.cast());
        // }

        // Workaround for a bug in CBL C SDK, which frees all resolved
        // documents, not just merged ones. When this bug is fixed the above
        // commented out code block should replace this one.
        // https://github.com/couchbase/couchbase-lite-C/issues/148
        if (resolvedPointer != null) {
          CBLBindings.instance.base.retainRefCounted(resolvedPointer.cast());
        }

        return resolvedPointer?.address;
      }
    });
