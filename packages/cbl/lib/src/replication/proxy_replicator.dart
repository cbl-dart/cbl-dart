import 'dart:async';

import 'package:collection/collection.dart';

import '../bindings.dart';
import '../database.dart';
import '../database/proxy_database.dart';
import '../document/document.dart';
import '../document/proxy_document.dart';
import '../errors.dart';
import '../service/cbl_service.dart';
import '../service/cbl_service_api.dart';
import '../service/proxy_object.dart';
import '../support/edition.dart';
import '../support/errors.dart';
import '../support/listener_token.dart';
import '../support/resource.dart';
import '../support/streams.dart';
import '../support/utils.dart';
import 'common.dart';
import 'configuration.dart';
import 'conflict.dart';
import 'conflict_resolver.dart';
import 'document_replication.dart';
import 'endpoint.dart';
import 'replicator.dart';
import 'replicator_change.dart';

class ProxyReplicator extends ProxyObject
    with ClosableResourceMixin
    implements AsyncReplicator {
  ProxyReplicator({
    required ProxyDatabase database,
    required int objectId,
    required ReplicatorConfiguration config,
    required void Function() unregisterCallbacks,
  })  : _database = database,
        _config = ReplicatorConfiguration.from(config),
        super(database.channel, objectId, proxyFinalizer: unregisterCallbacks) {
    attachTo(_database);
  }

  static Future<ProxyReplicator> create(
    ReplicatorConfiguration config,
  ) async {
    final (database, collections) = await resolveReplicatorCollections<
        AsyncDatabase, AsyncCollection, ProxyDatabase, ProxyCollection>(config);

    var target = config.target;
    if (target is DatabaseEndpoint) {
      useEnterpriseFeature(EnterpriseFeature.localDbReplication);

      final database = assertArgumentType<AsyncDatabase>(
        target.database,
        'config.target.database',
      ) as ProxyDatabase;
      target = ServiceDatabaseEndpoint(database.objectId);
    }

    final client = database.client;

    final callbacksIds = <int>[];

    void unregisterCallbacks() {
      callbacksIds.whereNotNull().forEach(client.unregisterObject);
    }

    final createReplicatorCollections = collections.entries.map((entry) {
      final MapEntry(key: collection, value: config) = entry;

      final pushFilterId = config.pushFilter
          ?.let((it) => _wrapReplicationFilter(it, collection))
          .let(client.registerReplicationFilter);
      final pullFilterId = config.pullFilter
          ?.let((it) => _wrapReplicationFilter(it, collection))
          .let(client.registerReplicationFilter);
      final conflictResolverId = config.conflictResolver
          ?.let((it) => _wrapConflictResolver(it, collection))
          .let(client.registerConflictResolver);

      callbacksIds.addAll([
        pushFilterId,
        pullFilterId,
        conflictResolverId,
      ].whereNotNull());

      return CreateReplicatorCollection(
        collectionId: collection.objectId,
        channels: config.channels,
        documentIds: config.documentIds,
        pushFilterId: pushFilterId,
        pullFilterId: pullFilterId,
        conflictResolverId: conflictResolverId,
      );
    }).toList();

    try {
      final objectId = await database.channel.call(CreateReplicator(
        propertiesFormat: database.encodingFormat,
        target: target,
        replicatorType: config.replicatorType,
        continuous: config.continuous,
        authenticator: config.authenticator,
        pinnedServerCertificate: config.pinnedServerCertificate?.toData(),
        trustedRootCertificates: config.trustedRootCertificates?.toData(),
        headers: config.headers,
        enableAutoPurge: config.enableAutoPurge,
        heartbeat: config.heartbeat,
        maxAttempts: config.maxAttempts,
        maxAttemptWaitTime: config.maxAttemptWaitTime,
        collections: createReplicatorCollections,
      ));
      return ProxyReplicator(
        database: database,
        objectId: objectId,
        config: config,
        unregisterCallbacks: unregisterCallbacks,
      );
    }
    // ignore: avoid_catches_without_on_clauses
    catch (e) {
      unregisterCallbacks();
      rethrow;
    }
  }

  final ProxyDatabase _database;

  late final _listenerTokens = ListenerTokenRegistry(this);

  @override
  ReplicatorConfiguration get config => ReplicatorConfiguration.from(_config);
  final ReplicatorConfiguration _config;

  @override
  Future<ReplicatorStatus> get status =>
      use(() => channel.call(GetReplicatorStatus(
            replicatorId: objectId,
          )));

  @override
  // ignore: prefer_expression_function_bodies
  Future<void> start({bool reset = false}) => use(() {
        if (_database.ownsCurrentTransaction) {
          throw DatabaseException(
            'A replicator cannot be started from within a database '
            'transaction.',
            DatabaseErrorCode.transactionNotClosed,
          );
        }

        // Starting a replicator while the database has an active transaction
        // causes a deadlock. To avoid this, we synchronize the start call with
        // the database's transaction lock.
        return _database.asyncTransactionLock
            .synchronized(() => channel.call(StartReplicator(
                  replicatorId: objectId,
                  reset: reset,
                )));
      });

  @override
  Future<void> stop() => use(_stop);

  Future<void> _stop() => channel.call(StopReplicator(replicatorId: objectId));

  @override
  Future<ListenerToken> addChangeListener(ReplicatorChangeListener listener) =>
      use(() async {
        final token = await _addChangeListener(listener);
        return token.also(_listenerTokens.add);
      });

  Future<AbstractListenerToken> _addChangeListener(
      ReplicatorChangeListener listener) async {
    late final ProxyListenerToken<ReplicatorChange> token;
    final listenerId =
        _database.client.registerReplicatorChangeListener((status) {
      token.callListener(ReplicatorChangeImpl(this, status));
    });

    await channel.call(AddReplicatorChangeListener(
      replicatorId: objectId,
      listenerId: listenerId,
    ));

    return token =
        ProxyListenerToken(_database.client, this, listenerId, listener);
  }

  @override
  Future<ListenerToken> addDocumentReplicationListener(
    DocumentReplicationListener listener,
  ) =>
      use(() async {
        final token = await _addDocumentReplicationListener(listener);
        return token.also(_listenerTokens.add);
      });

  Future<AbstractListenerToken> _addDocumentReplicationListener(
    DocumentReplicationListener listener,
  ) async {
    late final ProxyListenerToken<DocumentReplication> token;
    final listenerId =
        _database.client.registerDocumentReplicationListener((event) {
      token.callListener(DocumentReplicationImpl(
        this,
        event.isPush,
        event.documents,
      ));
    });

    await channel.call(AddDocumentReplicationListener(
      replicatorId: objectId,
      listenerId: listenerId,
    ));

    return token =
        ProxyListenerToken(_database.client, this, listenerId, listener);
  }

  @override
  Future<void> removeChangeListener(ListenerToken token) =>
      use(() => _listenerTokens.remove(token));

  @override
  AsyncListenStream<ReplicatorChange> changes() => useSync(() => ListenerStream(
        parent: this,
        addListener: _addChangeListener,
      ));

  @override
  AsyncListenStream<DocumentReplication> documentReplications() =>
      useSync(() => ListenerStream(
            parent: this,
            addListener: _addDocumentReplicationListener,
          ));

  @override
  Future<Set<String>> get pendingDocumentIds async =>
      pendingDocumentIdsInCollection(
        (await _database.defaultCollection) as ProxyCollection,
      );

  @override
  Future<bool> isDocumentPending(String documentId) async =>
      isDocumentPendingInCollection(
        documentId,
        (await _database.defaultCollection) as ProxyCollection,
      );

  @override
  Future<Set<String>> pendingDocumentIdsInCollection(
    covariant ProxyCollection collection,
  ) =>
      use(() => channel
          .call(ReplicatorPendingDocumentIds(
            replicatorId: objectId,
            collectionId: collection.objectId,
          ))
          .then((value) => value.toSet()));

  @override
  Future<bool> isDocumentPendingInCollection(
    String documentId,
    covariant ProxyCollection collection,
  ) =>
      use(() => channel.call(ReplicatorIsDocumentPending(
            replicatorId: objectId,
            documentId: documentId,
            collectionId: collection.objectId,
          )));

  @override
  FutureOr<void> performClose() => finalizeEarly();

  @override
  String toString() => [
        'ProxyReplicator(',
        [
          'database: $_database',
          'type: ${config.replicatorType.name}',
          if (config.continuous) 'CONTINUOUS'
        ].join(', '),
        ')'
      ].join();
}

CblServiceReplicationFilter _wrapReplicationFilter(
  ReplicationFilter filter,
  ProxyCollection collection,
) =>
    (state, flags) =>
        filter(_documentStateToDocument(collection)(state), flags);

CblServiceConflictResolver _wrapConflictResolver(
  ConflictResolver resolver,
  ProxyCollection collection,
) =>
    (documentId, localState, remoteState) async {
      final local = localState?.let(_documentStateToDocument(collection));
      final remote = remoteState?.let(_documentStateToDocument(collection));
      final conflict = ConflictImpl(documentId, local, remote);

      final result = await resolver.resolve(conflict) as DelegateDocument?;

      if (result != null) {
        final includeProperties =
            !identical(result, local) && !identical(result, local);
        final delegate = await collection.prepareDocument(
          result,
          syncProperties: includeProperties,
        );
        return delegate.getState(withProperties: includeProperties);
      }
      return null;
    };

DelegateDocument Function(DocumentState) _documentStateToDocument(
  ProxyCollection collection,
) =>
    (state) => DelegateDocument(
          ProxyDocumentDelegate.fromState(state, database: collection.database),
          collection: collection,
        );
