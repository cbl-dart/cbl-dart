import 'dart:async';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../database.dart';
import '../database/proxy_database.dart';
import '../document/document.dart';
import '../document/proxy_document.dart';
import '../service/cbl_service.dart';
import '../service/cbl_service_api.dart';
import '../service/proxy_object.dart';
import '../support/edition.dart';
import '../support/errors.dart';
import '../support/listener_token.dart';
import '../support/resource.dart';
import '../support/streams.dart';
import '../support/utils.dart';
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
    required this.database,
    required int objectId,
    required ReplicatorConfiguration config,
    required void Function() unregisterCallbacks,
  })  : assert(database == config.database),
        _config = ReplicatorConfiguration.from(config),
        super(database.channel, objectId, proxyFinalizer: unregisterCallbacks) {
    attachTo(database);
  }

  static Future<ProxyReplicator> create(
    ReplicatorConfiguration config,
  ) async {
    final database =
        assertArgumentType<AsyncDatabase>(config.database, 'config.database')
            as ProxyDatabase;

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

    final pushFilterId = config.pushFilter
        ?.let((it) => _wrapReplicationFilter(it, database))
        .let(client.registerReplicationFilter);
    final pullFilterId = config.pullFilter
        ?.let((it) => _wrapReplicationFilter(it, database))
        .let(client.registerReplicationFilter);
    final conflictResolverId = config.conflictResolver
        ?.let((it) => _wrapConflictResolver(it, database))
        .let(client.registerConflictResolver);

    void unregisterCallbacks() {
      [
        pushFilterId,
        pullFilterId,
        conflictResolverId,
      ].whereType<int>().forEach(client.unregisterObject);
    }

    try {
      final objectId = await database.channel.call(CreateReplicator(
        databaseId: database.objectId,
        propertiesFormat: database.encodingFormat,
        target: target,
        replicatorType: config.replicatorType,
        continuous: config.continuous,
        authenticator: config.authenticator,
        pinnedServerCertificate: config.pinnedServerCertificate?.toData(),
        headers: config.headers,
        channels: config.channels,
        documentIds: config.documentIds,
        pushFilterId: pushFilterId,
        pullFilterId: pullFilterId,
        conflictResolverId: conflictResolverId,
        enableAutoPurge: config.enableAutoPurge,
        heartbeat: config.heartbeat,
        maxAttempts: config.maxAttempts,
        maxAttemptWaitTime: config.maxAttemptWaitTime,
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

  final ProxyDatabase database;

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
  Future<void> start({bool reset = false}) =>
      use(() => channel.call(StartReplicator(
            replicatorId: objectId,
            reset: reset,
          )));

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
        database.client.registerReplicatorChangeListener((status) {
      token.callListener(ReplicatorChangeImpl(this, status));
    });

    await channel.call(AddReplicatorChangeListener(
      replicatorId: objectId,
      listenerId: listenerId,
    ));

    return token =
        ProxyListenerToken(database.client, this, listenerId, listener);
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
        database.client.registerDocumentReplicationListener((event) {
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
        ProxyListenerToken(database.client, this, listenerId, listener);
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
  Future<bool> isDocumentPending(String documentId) =>
      use(() => channel.call(ReplicatorIsDocumentPending(
            replicatorId: objectId,
            documentId: documentId,
          )));

  @override
  Future<Set<String>> get pendingDocumentIds => use(() => channel
      .call(ReplicatorPendingDocumentIds(replicatorId: objectId))
      .then((value) => value.toSet()));

  @override
  FutureOr<void> performClose() => finalizeEarly();

  @override
  String toString() => [
        'ProxyReplicator(',
        [
          'database: $database',
          'type: ${describeEnum(config.replicatorType)}',
          if (config.continuous) 'CONTINUOUS'
        ].join(', '),
        ')'
      ].join();
}

CblServiceReplicationFilter _wrapReplicationFilter(
  ReplicationFilter filter,
  ProxyDatabase database,
) =>
    (state, flags) => filter(_documentStateToDocument(database)(state), flags);

CblServiceConflictResolver _wrapConflictResolver(
  ConflictResolver resolver,
  ProxyDatabase database,
) =>
    (documentId, localState, remoteState) async {
      final local = localState?.let(_documentStateToDocument(database));
      final remote = remoteState?.let(_documentStateToDocument(database));
      final conflict = ConflictImpl(documentId, local, remote);

      final result = await resolver.resolve(conflict) as DelegateDocument?;

      if (result != null) {
        final includeProperties = result != local && result != remote;
        final delegate = await database.prepareDocument(
          result,
          syncProperties: includeProperties,
        );
        return delegate.getState(withProperties: includeProperties);
      }
      return null;
    };

DelegateDocument Function(DocumentState) _documentStateToDocument(
  ProxyDatabase database,
) =>
    (state) => DelegateDocument(
          ProxyDocumentDelegate.fromState(state),
          database: database,
        );
