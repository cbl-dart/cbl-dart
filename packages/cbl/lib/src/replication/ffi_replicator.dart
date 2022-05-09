import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../database.dart';
import '../database/ffi_database.dart';
import '../document/document.dart';
import '../document/ffi_document.dart';
import '../fleece/containers.dart' as fl;
import '../support/async_callback.dart';
import '../support/edition.dart';
import '../support/errors.dart';
import '../support/ffi.dart';
import '../support/listener_token.dart';
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
import 'replicator.dart';
import 'replicator_change.dart';

late final _bindings = cblBindings.replicator;

class FfiReplicator
    with ClosableResourceMixin
    implements SyncReplicator, NativeResource<CBLReplicator> {
  FfiReplicator._(
    this._config,
    this._database,
    this.native,
    this._closeCallbacks,
  );

  static Future<FfiReplicator> create(
    ReplicatorConfiguration config, {
    required String debugCreator,
    bool ignoreCallbackErrorsInDart = false,
  }) async {
    // We make a copy of the configuration so that later modifications to the
    // configuration don't affect this replicator.
    // ignore: parameter_assignments
    config = ReplicatorConfiguration.from(config);

    final database =
        assertArgumentType<SyncDatabase>(config.database, 'config.database')
            as FfiDatabase;

    final target = config.target;
    if (target is DatabaseEndpoint) {
      useEnterpriseFeature(EnterpriseFeature.localDbReplication);
      assertArgumentType<SyncDatabase>(
        target.database,
        'config.target.database',
      );
    }

    AsyncCallback Function(T) _makeCallback<T>(
      AsyncCallback Function(T, FfiDatabase, bool) callbackFactory,
    ) =>
        (callback) =>
            callbackFactory(callback, database, ignoreCallbackErrorsInDart);

    final pushFilterCallback =
        config.combinedPushFilter?.let(_makeCallback(_wrapReplicationFilter));
    final pullFilterCallback =
        config.combinedPullFilter?.let(_makeCallback(_wrapReplicationFilter));
    final conflictResolverCallback = config.combinedConflictResolver
        ?.let(_makeCallback(_wrapConflictResolver));

    void closeCallbacks() {
      pushFilterCallback?.close();
      pullFilterCallback?.close();
      conflictResolverCallback?.close();
    }

    final endpoint = config.createEndpoint();
    final authenticator = config.createAuthenticator();
    final headersDict = config.headers?.let(fl.MutableDict.new);
    final channelsArray = config.channels?.let(fl.MutableArray.new);
    final documentIDsArray = config.documentIds?.let(fl.MutableArray.new);
    final pushFilterCallbackNative = pushFilterCallback?.native;
    final pullFilterCallbackNative = pullFilterCallback?.native;
    final conflictResolverCallbackNative = conflictResolverCallback?.native;
    final ffiConfig = CBLReplicatorConfiguration(
      database: database.pointer,
      endpoint: endpoint,
      replicatorType: config.replicatorType.toCBLReplicatorType(),
      continuous: config.continuous,
      heartbeat: config.heartbeat?.inSeconds,
      maxAttempts: config.maxAttempts,
      maxAttemptWaitTime: config.maxAttemptWaitTime?.inSeconds,
      authenticator: authenticator,
      headers: headersDict?.pointer.cast(),
      pinnedServerCertificate: config.pinnedServerCertificate?.toData(),
      channels: channelsArray?.pointer.cast(),
      documentIDs: documentIDsArray?.pointer.cast(),
      pushFilter: pushFilterCallbackNative?.pointer,
      pullFilter: pullFilterCallbackNative?.pointer,
      conflictResolver: conflictResolverCallbackNative?.pointer,
      disableAutoPurge: !config.enableAutoPurge,
    );

    try {
      final replicator =
          runWithErrorTranslation(() => _bindings.createReplicator(ffiConfig));
      cblReachabilityFence(database);
      cblReachabilityFence(headersDict);
      cblReachabilityFence(channelsArray);
      cblReachabilityFence(documentIDsArray);
      cblReachabilityFence(pushFilterCallbackNative);
      cblReachabilityFence(pullFilterCallbackNative);
      cblReachabilityFence(conflictResolverCallbackNative);

      final native = CBLReplicatorObject(
        replicator,
        debugName: 'Replicator(creator: $debugCreator)',
      );

      return FfiReplicator._(config, database, native, closeCallbacks)
        ..attachTo(database);

      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      closeCallbacks();
      rethrow;
    } finally {
      _bindings.freeEndpoint(endpoint);
      if (authenticator != null) {
        _bindings.freeAuthenticator(authenticator);
      }
    }
  }

  static const _sleepWaitingForConnection = Duration(milliseconds: 5);

  late final _listenerTokens = ListenerTokenRegistry(this);

  final ReplicatorConfiguration _config;

  final FfiDatabase _database;

  @override
  final NativeObject<CBLReplicator> native;

  final void Function() _closeCallbacks;

  var _isStarted = false;
  var _isStopping = false;
  Completer<void>? _stopped;

  @override
  ReplicatorConfiguration get config => ReplicatorConfiguration.from(_config);

  @override
  ReplicatorStatus get status => useSync(() => _status);

  ReplicatorStatus get _status {
    final result = _bindings.status(native.pointer).toReplicatorStatus();
    cblReachabilityFence(native);
    return result;
  }

  @override
  void start({bool reset = false}) => useSync(() {
        if (_isStarted) {
          return;
        }
        _isStarted = true;
        _isStopping = false;

        late AbstractListenerToken token;
        token = _addChangeListener((change) {
          if (change.status.activity == ReplicatorActivityLevel.stopped) {
            _isStarted = false;
            _isStopping = false;
            _stopped?.complete();
            _stopped = null;
            token.removeListener();
          }
        });

        _bindings.start(native.pointer, resetCheckpoint: reset);
        cblReachabilityFence(native);
      });

  @override
  void stop() => useSync(_stop);

  void _stop() {
    if (_isStopping) {
      return;
    }
    _isStopping = true;

    // As a workaround for a bug in Couchbase Lite, a replicator is only stopped
    // when it is not connecting. The bug can cause a crash if a replicator is
    // stopped before the web socket connection to the target has been
    // established.
    // ignore: literal_only_boolean_expressions
    while (true) {
      switch (_status.activity) {
        case ReplicatorActivityLevel.stopped:
          return;
        case ReplicatorActivityLevel.connecting:
          sleep(_sleepWaitingForConnection);
          continue;
        case ReplicatorActivityLevel.busy:
        case ReplicatorActivityLevel.idle:
        case ReplicatorActivityLevel.offline:
      }
      break;
    }

    _bindings.stop(native.pointer);
    cblReachabilityFence(native);
  }

  @override
  ListenerToken addChangeListener(ReplicatorChangeListener listener) =>
      useSync(() => _addChangeListener(listener).also(_listenerTokens.add));

  AbstractListenerToken _addChangeListener(ReplicatorChangeListener listener) {
    final callback = AsyncCallback(
      (arguments) {
        final message =
            ReplicatorStatusCallbackMessage.fromArguments(arguments);
        final change =
            ReplicatorChangeImpl(this, message.status.toReplicatorStatus());
        listener(change);
        return null;
      },
      debugName: 'FfiReplicator.addChangeListener',
    );

    final callbackNative = callback.native;
    _bindings.addChangeListener(native.pointer, callbackNative.pointer);
    cblReachabilityFence(native);
    cblReachabilityFence(callbackNative);

    return FfiListenerToken(callback);
  }

  @override
  ListenerToken addDocumentReplicationListener(
    DocumentReplicationListener listener,
  ) =>
      useSync(() =>
          _addDocumentReplicationListener(listener).also(_listenerTokens.add));

  AbstractListenerToken _addDocumentReplicationListener(
    DocumentReplicationListener listener,
  ) {
    final callback = AsyncCallback(
      (arguments) {
        final message =
            DocumentReplicationsCallbackMessage.fromArguments(arguments);

        final documents =
            message.documents.map((it) => it.toReplicatedDocument()).toList();

        final replication =
            DocumentReplicationImpl(this, message.isPush, documents);
        listener(replication);
        return null;
      },
      debugName: 'FfiReplicator.addDocumentReplicationListener',
    );

    final callbackNative = callback.native;
    _bindings.addDocumentReplicationListener(
      native.pointer,
      callbackNative.pointer,
    );
    cblReachabilityFence(native);
    cblReachabilityFence(callbackNative);

    return FfiListenerToken(callback);
  }

  @override
  void removeChangeListener(ListenerToken token) => useSync(() {
        final result = _listenerTokens.remove(token);
        assert(result is! Future);
      });

  @override
  Stream<ReplicatorChange> changes() => useSync(_changes);

  Stream<ReplicatorChange> _changes() => ListenerStream(
        parent: this,
        addListener: _addChangeListener,
      );

  @override
  Stream<DocumentReplication> documentReplications() =>
      useSync(() => ListenerStream(
            parent: this,
            addListener: _addDocumentReplicationListener,
          ));

  @override
  Set<String> get pendingDocumentIds => useSync(() {
        final dict = fl.Dict.fromPointer(
          _bindings.pendingDocumentIDs(native.pointer),
          adopt: true,
        );
        cblReachabilityFence(native);
        return dict.keys.toSet();
      });

  @override
  bool isDocumentPending(String documentId) => useSync(() {
        final result = _bindings.isDocumentPending(native.pointer, documentId);
        cblReachabilityFence(native);
        return result;
      });

  @override
  Future<void> performClose() async {
    await _ensureIsStopped();
    _closeCallbacks();
  }

  Future<void> _ensureIsStopped() async {
    if (_isStarted) {
      _stopped = Completer<void>();

      if (!_isStopping) {
        _stop();
      }

      await _stopped!.future;
    }
  }

  @override
  String toString() => [
        'FfiReplicator(',
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
  ReplicatorStatus toReplicatorStatus() => ReplicatorStatus(
        activity.toReplicatorActivityLevel(),
        ReplicatorProgress(
          progressDocumentCount,
          progressComplete,
        ),
        error?.toCouchbaseLiteException(),
      );
}

extension on CBLReplicatedDocument {
  ReplicatedDocument toReplicatedDocument() => ReplicatedDocumentImpl(
        id,
        flags.map((flag) => flag.toReplicatedDocumentFlag()).toSet(),
        error?.toCouchbaseLiteException(),
      );
}

extension on ReplicatorConfiguration {
  Pointer<CBLEndpoint> createEndpoint() {
    final target = this.target;
    if (target is UrlEndpoint) {
      return runWithErrorTranslation(
        () => _bindings.createEndpointWithUrl(target.url.toString()),
      );
    } else if (target is DatabaseEndpoint) {
      final db = target.database as FfiDatabase;
      final result = _bindings.createEndpointWithLocalDB(db.pointer);
      cblReachabilityFence(db);
      return result;
    } else {
      throw UnimplementedError('Endpoint type is not implemented: $target');
    }
  }

  Pointer<CBLAuthenticator>? createAuthenticator() {
    final authenticator = this.authenticator;
    if (authenticator == null) {
      return null;
    }

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
  ReplicationFilter filter,
  FfiDatabase database,
  bool ignoreErrorsInDart,
) =>
    AsyncCallback(
      (arguments) async {
        final message =
            ReplicationFilterCallbackMessage.fromArguments(arguments);
        final doc = DelegateDocument(
          FfiDocumentDelegate.fromPointer(
            doc: message.document,
            adopt: false,
            debugCreator: 'ReplicationFilter()',
          ),
          database: database,
        );

        return filter(
          doc,
          message.flags.map((flag) => flag.toReplicatedDocumentFlag()).toSet(),
        );
      },
      errorResult: false,
      ignoreErrorsInDart: ignoreErrorsInDart,
      debugName: 'ReplicationFilter',
    );

AsyncCallback _wrapConflictResolver(
  ConflictResolver resolver,
  FfiDatabase database,
  bool ignoreErrorsInDart,
) =>
    AsyncCallback(
      (arguments) async {
        final message =
            ReplicationConflictResolverCallbackMessage.fromArguments(arguments);

        final local = message.localDocument?.let((it) => DelegateDocument(
              FfiDocumentDelegate.fromPointer(
                doc: it,
                adopt: false,
                debugCreator: 'ConflictResolver(local)',
              ),
              database: database,
            ));

        final remote = message.remoteDocument?.let((it) => DelegateDocument(
              FfiDocumentDelegate.fromPointer(
                doc: it,
                adopt: false,
                debugCreator: 'ConflictResolver(remote)',
              ),
              database: database,
            ));

        final conflict = ConflictImpl(message.documentId, local, remote);
        final resolved = await resolver.resolve(conflict) as DelegateDocument?;

        NativeObject<CBLDocument>? resolvedDelegateNative;
        if (resolved != null) {
          if (resolved != local && resolved != remote) {
            final resolvedDelegate =
                database.prepareDocument(resolved) as FfiDocumentDelegate;
            resolvedDelegateNative = resolvedDelegate.native;

            // If the resolver returned a document other than `local` or
            // `remote`, the ref count of `resolved` needs to be incremented
            // because the native conflict resolver callback is expected to
            // returned a document with a ref count of +1, which the caller
            // balances with a release. This must happen on the Dart side,
            // because `resolved` can be garbage collected before
            // `resolvedAddress` makes it back to the native side.
            cblBindings.base
                .retainRefCounted(resolvedDelegateNative.pointer.cast());
          } else {
            resolvedDelegateNative =
                (resolved.delegate as FfiDocumentDelegate).native;
          }
        }

        final result = resolvedDelegateNative?.pointer.address;
        cblReachabilityFence(resolvedDelegateNative);
        return result;
      },
      ignoreErrorsInDart: ignoreErrorsInDart,
      debugName: 'ConflictResolver',
    );
