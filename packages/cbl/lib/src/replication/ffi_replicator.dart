// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:collection/collection.dart';

import '../bindings.dart';
import '../database.dart';
import '../database/ffi_database.dart';
import '../document/document.dart';
import '../document/ffi_document.dart';
import '../errors.dart';
import '../fleece/containers.dart' as fl;
import '../support/async_callback.dart';
import '../support/edition.dart';
import '../support/errors.dart';
import '../support/ffi.dart';
import '../support/listener_token.dart';
import '../support/resource.dart';
import '../support/streams.dart';
import '../support/utils.dart';
import 'authenticator.dart';
import 'common.dart';
import 'configuration.dart';
import 'conflict.dart';
import 'conflict_resolver.dart';
import 'document_replication.dart';
import 'endpoint.dart';
import 'replicator.dart';
import 'replicator_change.dart';

final _bindings = cblBindings.replicator;

class FfiReplicator
    with ClosableResourceMixin
    implements SyncReplicator, Finalizable {
  FfiReplicator._({
    required ReplicatorConfiguration config,
    required this.pointer,
    required FfiDatabase database,
    required void Function() closeCallbacks,
  })  : _config = config,
        _database = database,
        _closeCallbacks = closeCallbacks {
    _bindings.bindToDartObject(this, pointer);
    attachTo(_database);
  }

  static Future<FfiReplicator> create(
    ReplicatorConfiguration config, {
    bool ignoreCallbackErrorsInDart = false,
  }) async {
    // We make a copy of the configuration so that later modifications to the
    // configuration don't affect this replicator.
    // ignore: parameter_assignments
    config = ReplicatorConfiguration.from(config);

    // TODO(blaugold): Use record destructuring once issue in Dart is fixed
    // https://github.com/dart-lang/sdk/issues/54414
    final replicatorCollections = await resolveReplicatorCollections<
        SyncDatabase, SyncCollection, FfiDatabase, FfiCollection>(config);
    final database = replicatorCollections.$1;
    final collections = replicatorCollections.$2;

    final target = config.target;
    if (target is DatabaseEndpoint) {
      useEnterpriseFeature(EnterpriseFeature.localDbReplication);
      assertArgumentType<SyncDatabase>(
        target.database,
        'config.target.database',
      );
    }

    final fleeceContainers = <Object>[];
    final callbacks = <AsyncCallback>[];

    void closeCallbacks() {
      for (final callback in callbacks) {
        callback.close();
      }
    }

    final replicationCollections = collections.entries.map((entry) {
      final MapEntry(key: collection, value: config) = entry;

      AsyncCallback createFilterCallback(ReplicationFilter filter) =>
          _createReplicationFilterCallback(
            filter,
            collection,
            ignoreErrorsInDart: ignoreCallbackErrorsInDart,
          );
      AsyncCallback createConflictResolverCallback(ConflictResolver resolver) =>
          _createConflictResolverCallback(
            resolver,
            collection,
            ignoreErrorsInDart: ignoreCallbackErrorsInDart,
          );

      final pushFilterCallback = config.pushFilter?.let(createFilterCallback);
      final pullFilterCallback = config.pullFilter?.let(createFilterCallback);
      final conflictResolverCallback =
          config.conflictResolver?.let(createConflictResolverCallback);

      callbacks.addAll([
        pushFilterCallback,
        pullFilterCallback,
        conflictResolverCallback
      ].whereNotNull());

      final channelsArray = config.channels?.let(fl.MutableArray.new);
      final documentIDsArray = config.documentIds?.let(fl.MutableArray.new);

      // Make sure the Fleece containers are not garbage collected before the
      // replicator is created.
      fleeceContainers.addAll([channelsArray, documentIDsArray].whereNotNull());

      return CBLReplicationCollection(
        collection: collection.pointer,
        channels: channelsArray?.pointer.cast(),
        documentIDs: documentIDsArray?.pointer.cast(),
        pushFilter: pushFilterCallback?.pointer,
        pullFilter: pullFilterCallback?.pointer,
        conflictResolver: conflictResolverCallback?.pointer,
      );
    }).toList();

    final endpoint = config.createEndpoint();
    final authenticator = config.createAuthenticator();
    final headersDict = config.headers?.let(fl.MutableDict.new);

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
      trustedRootCertificates: config.trustedRootCertificates?.toData(),
      collections: replicationCollections,
      disableAutoPurge: !config.enableAutoPurge,
    );

    try {
      final pointer =
          runWithErrorTranslation(() => _bindings.createReplicator(ffiConfig));

      cblReachabilityFence(fleeceContainers);

      return FfiReplicator._(
        config: config,
        pointer: pointer,
        database: database,
        closeCallbacks: closeCallbacks,
      );

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

  final Pointer<CBLReplicator> pointer;

  final void Function() _closeCallbacks;

  var _isStarted = false;
  var _isStopping = false;
  Completer<void>? _stopped;

  @override
  ReplicatorConfiguration get config => ReplicatorConfiguration.from(_config);

  @override
  ReplicatorStatus get status => useSync(() => _status);

  ReplicatorStatus get _status =>
      _bindings.status(pointer).toReplicatorStatus();

  @override
  void start({bool reset = false}) => useSync(() {
        if (_database.ownsCurrentTransaction) {
          throw DatabaseException(
            'A replicator cannot be started from within a database '
            'transaction.',
            DatabaseErrorCode.transactionNotClosed,
          );
        }

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

        _bindings.start(pointer, resetCheckpoint: reset);
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

    _bindings.stop(pointer);
  }

  @override
  ListenerToken addChangeListener(ReplicatorChangeListener listener) =>
      useSync(() => _addChangeListener(listener).also(_listenerTokens.add));

  AbstractListenerToken _addChangeListener(ReplicatorChangeListener listener) {
    final database = _database;
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

    _bindings.addChangeListener(database.pointer, pointer, callback.pointer);

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
    final database = _database;
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

    _bindings.addDocumentReplicationListener(
      database.pointer,
      pointer,
      callback.pointer,
    );

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
  Set<String> get pendingDocumentIds => pendingDocumentIdsInCollection(
        _database.defaultCollection as FfiCollection,
      );

  @override
  bool isDocumentPending(String documentId) => isDocumentPendingInCollection(
        documentId,
        _database.defaultCollection as FfiCollection,
      );

  @override
  Set<String> pendingDocumentIdsInCollection(
    covariant FfiCollection collection,
  ) =>
      useSync(() {
        final dict = fl.Dict.fromPointer(
          _bindings.pendingDocumentIDs(pointer, collection.pointer),
          adopt: true,
        );
        return dict.keys.toSet();
      });

  @override
  bool isDocumentPendingInCollection(
    String documentId,
    covariant FfiCollection collection,
  ) =>
      useSync(() => _bindings.isDocumentPending(
            pointer,
            documentId,
            collection.pointer,
          ));

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
          'type: ${config.replicatorType.name}',
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
        scope,
        collection,
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
      return _bindings.createEndpointWithLocalDB(db.pointer);
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

AsyncCallback _createReplicationFilterCallback(
  ReplicationFilter filter,
  FfiCollection collection, {
  required bool ignoreErrorsInDart,
}) =>
    AsyncCallback(
      (arguments) async {
        final message =
            ReplicationFilterCallbackMessage.fromArguments(arguments);
        final doc = DelegateDocument(
          FfiDocumentDelegate.fromPointer(message.document),
          collection: collection,
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

AsyncCallback _createConflictResolverCallback(
  ConflictResolver resolver,
  FfiCollection collection, {
  required bool ignoreErrorsInDart,
}) =>
    AsyncCallback(
      (arguments) async {
        final message =
            ReplicationConflictResolverCallbackMessage.fromArguments(arguments);

        final local = message.localDocument?.let((pointer) => DelegateDocument(
              FfiDocumentDelegate.fromPointer(pointer),
              collection: collection,
            ));

        final remote =
            message.remoteDocument?.let((pointer) => DelegateDocument(
                  FfiDocumentDelegate.fromPointer(pointer),
                  collection: collection,
                ));

        final conflict = ConflictImpl(message.documentId, local, remote);
        final resolved = await resolver.resolve(conflict) as DelegateDocument?;

        FfiDocumentDelegate? resolvedDelegate;
        if (resolved != null) {
          if (!identical(resolved, local) && !identical(resolved, remote)) {
            resolvedDelegate = await collection.prepareDocument(resolved);

            // If the resolver returned a document other than `local` or
            // `remote`, the ref count of the resolved document needs to be
            // incremented because the native conflict resolver callback is
            // expected to returned a document with a ref count of +1, which the
            // caller balances with a release. This must happen on the Dart
            // side, because `resolvedDelegate` can be garbage collected before
            // the document pointer makes it back to the native side.
            cblBindings.base.retainRefCounted(resolvedDelegate.pointer.cast());
          } else {
            resolvedDelegate = resolved.delegate as FfiDocumentDelegate;
          }
        }

        return resolvedDelegate?.pointer.address;
      },
      ignoreErrorsInDart: ignoreErrorsInDart,
      debugName: 'ConflictResolver',
    );
