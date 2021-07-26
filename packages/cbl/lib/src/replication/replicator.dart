import 'dart:async';
import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';
import 'package:collection/collection.dart';

import '../database/database.dart';
import '../document/document.dart';
import '../errors.dart';
import '../fleece/fleece.dart' as fl;
import '../support/async_callback.dart';
import '../support/ffi.dart';
import '../support/native_object.dart';
import '../support/resource.dart';
import '../support/streams.dart';
import '../support/utils.dart';
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
  ReplicatorStatus get status;

  /// Starts this replicator with an option to [reset] the local checkpoint of
  /// the replicator.
  ///
  /// When the local checkpoint is reset, the replicator will sync all changes
  /// since the beginning of time from the remote database.
  ///
  /// The method returns immediately; the replicator runs asynchronously and
  /// will report its progress through the [changes] stream.
  void start({bool reset = false});

  /// Stops this replicator, if running.
  ///
  /// This method returns immediately; when the replicator actually stops, the
  /// replicator will change the [ReplicatorActivityLevel] of its [status] to
  /// [ReplicatorActivityLevel.stopped]. and the [changes] stream will
  /// be notified accordingly.
  void stop();

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
  Set<String> get pendingDocumentIds;

  /// Returns whether the [Document] with the given [documentId] has revisions
  /// pending push.
  ///
  /// This API is a snapshot and the result may change between the time the call
  /// was made and the time the call returns.
  bool isDocumentPending(String documentId);
}

late final _bindings = cblBindings.replicator;

class ReplicatorImpl
    with ClosableResourceMixin, NativeResourceMixin<CBLReplicator>
    implements Replicator {
  ReplicatorImpl(ReplicatorConfiguration config, {required String debugCreator})
      : _config = ReplicatorConfiguration.from(config) {
    final database = _database = (_config.database as DatabaseImpl);

    runNativeCalls(() {
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
        final replicator = _bindings.createReplicator(
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
          config.headers?.let((it) => fl.MutableDict(it).native.pointer.cast()),
          config.pinnedServerCertificate,
          null,
          config.channels
              ?.let((it) => fl.MutableArray(it).native.pointer.cast()),
          config.documentIds
              ?.let((it) => fl.MutableArray(it).native.pointer.cast()),
          pushFilterCallback?.native.pointer,
          pullFilterCallback?.native.pointer,
          conflictResolverCallback?.native.pointer,
        );

        native = CBLReplicatorObject(
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

  @override
  late final NativeObject<CBLReplicator> native;

  late final List<AsyncCallback> _callbacks;

  @override
  ReplicatorConfiguration get config => ReplicatorConfiguration.from(_config);

  @override
  ReplicatorStatus get status => useSync(() => _status);

  ReplicatorStatus get _status =>
      native.call(_bindings.status).toReplicatorStatus();

  @override
  void start({bool reset = false}) =>
      useSync(() => native.call((pointer) => _bindings.start(pointer, reset)));

  @override
  void stop() => useSync(_stop);

  void _stop() => native.call(_bindings.stop);

  @override
  Stream<ReplicatorChange> changes() => useSync(_changes);

  Stream<ReplicatorChange> _changes() =>
      CallbackStreamController<ReplicatorChange, void>(
        parent: this,
        startStream: (callback) => _bindings.addChangeListener(
          native.pointer,
          callback.native.pointer,
        ),
        createEvent: (_, arguments) {
          final message =
              ReplicatorStatusCallbackMessage.fromArguments(arguments);
          return ReplicatorChangeImpl(
            this,
            message.status.toReplicatorStatus(),
          );
        },
      ).stream;

  @override
  Stream<DocumentReplication> documentReplications() =>
      useSync(() => CallbackStreamController(
            parent: this,
            startStream: (callback) => _bindings.addDocumentReplicationListener(
              native.pointer,
              callback.native.pointer,
            ),
            createEvent: (_, arguments) {
              final message =
                  DocumentReplicationsCallbackMessage.fromArguments(arguments);

              final documents = message.documents
                  .map((it) => it.toReplicatedDocument())
                  .toList();

              return DocumentReplicationImpl(this, message.isPush, documents);
            },
          ).stream);

  @override
  Set<String> get pendingDocumentIds => useSync(() {
        final dict = fl.Dict.fromPointer(
          native.call(_bindings.pendingDocumentIDs),
          adopt: true,
        );
        return dict.keys.toSet();
      });

  @override
  bool isDocumentPending(String documentId) =>
      useSync(() => native.call((pointer) {
            return _bindings.isDocumentPending(pointer, documentId);
          }));

  @override
  Future<void> performClose() async {
    try {
      var stopping = false;
      while (_status.activity != ReplicatorActivityLevel.stopped) {
        if (!stopping) {
          _stop();
          stopping = true;
        }
        await Future<void>.delayed(Duration(milliseconds: 100));
      }
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

extension on CBLReplicatorStatus {
  ReplicatorStatus toReplicatorStatus() => ReplicatorStatus._(
        activity.toReplicatorActivityLevel(),
        ReplicatorProgress._(
          progressDocumentCount,
          progressComplete,
        ),
        error?.translate(),
      );
}

extension on CBLReplicatedDocument {
  ReplicatedDocument toReplicatedDocument() => ReplicatedDocumentImpl(
        id,
        flags.map((flag) => flag.toReplicatedDocumentFlag()).toSet(),
        error?.translate(),
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

AsyncCallback _wrapReplicationFilter(
  DatabaseImpl database,
  ReplicationFilter filter,
) =>
    AsyncCallback((arguments) async {
      final message = ReplicationFilterCallbackMessage.fromArguments(arguments);
      final doc = DocumentImpl(
        database: database,
        doc: message.document,
        adopt: false,
        debugCreator: 'ReplicationFilter()',
      );

      return filter(
        doc,
        message.flags.map((flag) => flag.toReplicatedDocumentFlag()).toSet(),
      );
    }, errorResult: false, debugName: 'ReplicationFilter');

AsyncCallback _wrapConflictResolver(
  DatabaseImpl database,
  ConflictResolver resolver,
) =>
    AsyncCallback((arguments) async {
      final message =
          ReplicationConflictResolverCallbackMessage.fromArguments(arguments);

      final local = message.localDocument?.let((it) => DocumentImpl(
            database: database,
            doc: it,
            adopt: false,
            debugCreator: 'ConflictResolver(local)',
          ));

      final remote = message.remoteDocument?.let((it) => DocumentImpl(
            database: database,
            doc: it,
            adopt: false,
            debugCreator: 'ConflictResolver(remote)',
          ));

      final conflict = ConflictImpl(message.documentId, local, remote);
      final resolved = await resolver.resolve(conflict) as DocumentImpl?;
      if (resolved is MutableDocumentImpl) {
        resolved.database = database;
        resolved.flushProperties();
      }

      final resolvedPointer = resolved?.native.pointerUnsafe;

      // If the resolver returned a document other than `local` or `remote`,
      // the ref count of `resolved` needs to be incremented because the
      // native conflict resolver callback is expected to returned a document
      // with a ref count of +1, which the caller balances with a release.
      // This must happen on the Dart side, because `resolved` can be garbage
      // collected before `resolvedAddress` makes it back to the native side.
      // if (resolvedPointer != null &&
      //     resolved != local &&
      //     resolved != remote) {
      //   cblBindings.base.retainRefCounted(resolvedPointer.cast());
      // }

      // Workaround for a bug in CBL C SDK, which frees all resolved
      // documents, not just merged ones. When this bug is fixed the above
      // commented out code block should replace this one.
      // https://github.com/couchbase/couchbase-lite-C/issues/148
      if (resolvedPointer != null) {
        cblBindings.base.retainRefCounted(resolvedPointer.cast());
      }

      return resolvedPointer?.address;
    }, debugName: 'ConflictResolver');
