import 'dart:async';
import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';
import 'package:collection/collection.dart';

import '../database/ffi_database.dart';
import '../document/document.dart';
import '../document/ffi_document.dart';
import '../fleece/fleece.dart' as fl;
import '../support/async_callback.dart';
import '../support/errors.dart';
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
import 'replicator.dart';
import 'replicator_change.dart';

late final _bindings = cblBindings.replicator;

class FfiReplicator
    with ClosableResourceMixin, NativeResourceMixin<CBLReplicator>
    implements SyncReplicator {
  FfiReplicator(
    ReplicatorConfiguration config, {
    required String debugCreator,
    bool ignoreCallbackErrorsInDart = false,
  }) : _config = ReplicatorConfiguration.from(config) {
    final database = _config.database;
    if (database is! FfiDatabase) {
      throw ArgumentError.value(
        config.database,
        'config.database',
        'must by a SyncDatabase',
      );
    }

    _database = database;

    runNativeCalls(() {
      final pushFilterCallback =
          config.pushFilter?.let((it) => _wrapReplicationFilter(
                it,
                database,
                ignoreCallbackErrorsInDart,
              ));
      final pullFilterCallback =
          config.pullFilter?.let((it) => _wrapReplicationFilter(
                it,
                database,
                ignoreCallbackErrorsInDart,
              ));
      final conflictResolverCallback =
          config.conflictResolver?.let((it) => _wrapConflictResolver(
                it,
                database,
                ignoreCallbackErrorsInDart,
              ));

      _callbacks = [
        pushFilterCallback,
        pullFilterCallback,
        conflictResolverCallback
      ].whereNotNull().toList();

      final endpoint = config.createEndpoint();
      final authenticator = config.createAuthenticator();
      final configuration = CBLReplicatorConfiguration(
        database: database.native.pointer,
        endpoint: endpoint,
        replicatorType: config.replicatorType.toCBLReplicatorType(),
        continuous: config.continuous,
        maxAttempts: config.maxRetries + 1,
        maxAttemptWaitTime: config.maxRetryWaitTime.inSeconds,
        heartbeat: config.heartbeat.inSeconds,
        authenticator: authenticator,
        headers: config.headers
            ?.let((it) => fl.MutableDict(it).native.pointer.cast()),
        pinnedServerCertificate: config.pinnedServerCertificate?.toData(),
        channels: config.channels
            ?.let((it) => fl.MutableArray(it).native.pointer.cast()),
        documentIDs: config.documentIds
            ?.let((it) => fl.MutableArray(it).native.pointer.cast()),
        pushFilter: pushFilterCallback?.native.pointer,
        pullFilter: pullFilterCallback?.native.pointer,
        conflictResolver: conflictResolverCallback?.native.pointer,
      );

      try {
        final replicator = _bindings.createReplicator(configuration);

        native = CBLReplicatorObject(
          replicator,
          debugName: 'Replicator(creator: $debugCreator)',
        );

        database.registerChildResource(this);
        // ignore: avoid_catches_without_on_clauses
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

  late final FfiDatabase _database;

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
      useSync(() => native.call((pointer) => _bindings.start(
            pointer,
            resetCheckpoint: reset,
          )));

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
  bool isDocumentPending(String documentId) => useSync(() => native
      .call((pointer) => _bindings.isDocumentPending(pointer, documentId)));

  @override
  Future<void> performClose() async {
    try {
      var stopping = false;
      while (_status.activity != ReplicatorActivityLevel.stopped) {
        if (!stopping) {
          _stop();
          stopping = true;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    } finally {
      _disposeCallbacks();
    }
  }

  void _disposeCallbacks() {
    for (final callback in _callbacks) {
      callback.close();
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
      return _bindings.createEndpointWithUrl(target.url.toString());
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

        FfiDocumentDelegate? resolvedDelegate;
        if (resolved != null) {
          if (resolved != local && resolved != remote) {
            resolvedDelegate =
                database.prepareDocument(resolved) as FfiDocumentDelegate;

            // If the resolver returned a document other than `local` or
            // `remote`, the ref count of `resolved` needs to be incremented
            // because the native conflict resolver callback is expected to
            // returned a document with a ref count of +1, which the caller
            // balances with a release. This must happen on the Dart side,
            // because `resolved` can be garbage collected before
            // `resolvedAddress` makes it back to the native side.
            cblBindings.base
                .retainRefCounted(resolvedDelegate.native.pointerUnsafe.cast());
          } else {
            resolvedDelegate = resolved.delegate as FfiDocumentDelegate;
          }
        }

        return resolvedDelegate?.native.pointerUnsafe.address;
      },
      ignoreErrorsInDart: ignoreErrorsInDart,
      debugName: 'ConflictResolver',
    );
