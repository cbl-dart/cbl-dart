import 'dart:async';

import '../bindings.dart';
import '../database/collection.dart';
import '../database/database.dart';
import '../database/database_configuration.dart';
import '../database/ffi_database.dart';
import '../document/document.dart';
import '../document/ffi_document.dart';
import '../query/ffi_query.dart';
import '../query/index/index.dart';
import '../query/parameters.dart';
import '../query/result.dart';
import '../query/result_set.dart';
import '../replication.dart';
import '../replication/ffi_replicator.dart';
import '../support/encoding.dart';
import '../support/listener_token.dart';
import '../support/resource.dart';
import '../support/tracing.dart';
import '../support/utils.dart';
import '../tracing.dart';
import 'cbl_service_api.dart';
import 'channel.dart';
import 'object_registry.dart';

typedef CblServiceCollectionChangeListener = void Function(
  List<String> documentIds,
);

typedef CblServiceDocumentChangeListener = void Function();

typedef CblServiceQueryChangeListener = void Function(int resultSetId);

typedef CblServiceReplicationFilter = FutureOr<bool> Function(
  DocumentState state,
  Set<DocumentFlag> flags,
);

typedef CblServiceConflictResolver = FutureOr<DocumentState?> Function(
  String documentId,
  DocumentState? localState,
  DocumentState? remoteState,
);

typedef CblServiceReplicatorChangeListener = void Function(
  ReplicatorStatus status,
);

typedef CblServiceDocumentReplicationListener = void Function(
  DocumentReplicationEvent event,
);

class CblServiceClient {
  CblServiceClient({
    required this.channel,
  }) {
    channel
      ..addCallEndpoint(_traceData)
      ..addCallEndpoint(_callCollectionChangeListener)
      ..addCallEndpoint(_callDocumentChangeListener)
      ..addStreamEndpoint(_readBlobUpload)
      ..addCallEndpoint(_callQueryChangeListener)
      ..addCallEndpoint(_callReplicationFilter)
      ..addCallEndpoint(_callConflictResolver)
      ..addCallEndpoint(_callReplicatorChangeListener)
      ..addCallEndpoint(_callDocumentReplicationListener);
  }

  final Channel channel;

  final _onTraceData = Zone.current.bindUnaryCallbackGuarded(
    // ignore: invalid_use_of_visible_for_overriding_member
    (data) => currentTracingDelegate.onTraceData(data),
  );

  void unregisterObject(int id) => _objectRegistry.removeObjectById(id);

  int registerCollectionChangeListener(
    CblServiceCollectionChangeListener listener,
  ) {
    void handler(CallCollectionChangeListener request) =>
        listener(request.documentIds);

    return _objectRegistry.addObject(_bindListenerToZone(handler));
  }

  int registerDocumentChangeListener(
    CblServiceDocumentChangeListener listener,
  ) {
    void handler(CallDocumentChangeListener request) => listener();

    return _objectRegistry.addObject(_bindListenerToZone(handler));
  }

  int registerBlobUpload(Stream<Data> stream) =>
      _objectRegistry.addObject(stream);

  int registerQueryChangeListener(
    CblServiceQueryChangeListener listener,
  ) {
    void handler(CallQueryChangeListener request) =>
        listener(request.resultSetId);

    return _objectRegistry.addObject(_bindListenerToZone(handler));
  }

  int registerReplicationFilter(CblServiceReplicationFilter filter) {
    FutureOr<bool> handler(CallReplicationFilter request) =>
        filter(request.state, request.flags);

    return _objectRegistry.addObject(_bindCallbackToZone(handler));
  }

  int registerConflictResolver(CblServiceConflictResolver resolver) {
    FutureOr<DocumentState?> handler(CallConflictResolver request) => resolver(
          (request.localState?.docId ?? request.remoteState?.docId)!,
          request.localState,
          request.remoteState,
        );

    return _objectRegistry.addObject(_bindCallbackToZone(handler));
  }

  int registerReplicatorChangeListener(
    CblServiceReplicatorChangeListener listener,
  ) {
    void handler(CallReplicatorChangeListener request) =>
        listener(request.status);

    return _objectRegistry.addObject(_bindListenerToZone(handler));
  }

  int registerDocumentReplicationListener(
    CblServiceDocumentReplicationListener listener,
  ) {
    void handler(CallDocumentReplicationListener request) =>
        listener(request.event);

    return _objectRegistry.addObject(_bindListenerToZone(handler));
  }

  // === Request handlers ======================================================

  void _traceData(TraceDataRequest request) {
    _onTraceData(request.data);
  }

  void _callCollectionChangeListener(CallCollectionChangeListener request) =>
      _getCollectionChangeListenerById(request.listenerId)(request);

  void _callDocumentChangeListener(CallDocumentChangeListener request) =>
      _getDocumentChangeListenerById(request.listenerId)(request);

  Stream<MessageData> _readBlobUpload(ReadBlobUpload request) =>
      _takeBlobUploadById(request.uploadId).map(MessageData.new);

  void _callQueryChangeListener(CallQueryChangeListener request) =>
      _getQueryChangeListenerById(request.listenerId)(request);

  FutureOr<bool> _callReplicationFilter(CallReplicationFilter request) =>
      _getReplicationFilterById(request.filterId)(request);

  FutureOr<DocumentState?> _callConflictResolver(
    CallConflictResolver request,
  ) =>
      _getConflictResolverById(request.resolverId)(request);

  void _callReplicatorChangeListener(CallReplicatorChangeListener request) =>
      _getReplicatorChangeListenerById(request.listenerId)(request);

  void _callDocumentReplicationListener(
    CallDocumentReplicationListener request,
  ) =>
      _getDocumentReplicationListenerById(request.listenerId)(request);

  // === Objects ===============================================================

  final _objectRegistry = ObjectRegistry();

  void Function(CallCollectionChangeListener) _getCollectionChangeListenerById(
    int id,
  ) =>
      _objectRegistry.getObjectOrThrow(id);

  void Function(CallDocumentChangeListener) _getDocumentChangeListenerById(
    int id,
  ) =>
      _objectRegistry.getObjectOrThrow(id);

  Stream<Data> _takeBlobUploadById(int id) {
    final upload = _objectRegistry.getObjectOrThrow<Stream<Data>>(id);
    _objectRegistry.removeObject(upload);
    return upload;
  }

  void Function(CallQueryChangeListener) _getQueryChangeListenerById(
    int id,
  ) =>
      _objectRegistry.getObjectOrThrow(id);

  FutureOr<bool> Function(CallReplicationFilter) _getReplicationFilterById(
    int id,
  ) =>
      _objectRegistry.getObjectOrThrow(id);

  FutureOr<DocumentState?> Function(CallConflictResolver)
      _getConflictResolverById(int id) => _objectRegistry.getObjectOrThrow(id);

  void Function(CallReplicatorChangeListener) _getReplicatorChangeListenerById(
    int id,
  ) =>
      _objectRegistry.getObjectOrThrow(id);

  void Function(CallDocumentReplicationListener)
      _getDocumentReplicationListenerById(int id) =>
          _objectRegistry.getObjectOrThrow(id);
}

/// Returns a new function which wraps [fn], but treats exceptions as uncaught
/// error within the current [Zone], in addition to returning a rejected
/// [Future].
Future<R> Function(T) _bindCallbackToZone<T, R>(FutureOr<R> Function(T) fn) {
  final zone = Zone.current;

  // ignore: avoid_types_on_closure_parameters
  final zonedFn = zone.bindUnaryCallback((T arg) async {
    try {
      return await fn(arg);
    }
    // ignore: avoid_catches_without_on_clauses
    catch (error, stackTrace) {
      zone.handleUncaughtError(error, stackTrace);
      return AsyncError(error, stackTrace);
    }
  });

  return (arg) => zonedFn(arg).then((value) {
        if (value is AsyncError) {
          return Future.error(value.error, value.stackTrace);
        }
        return value as R;
      });
}

void Function(T) _bindListenerToZone<T>(void Function(T) fn) {
  final boundFn = _bindCallbackToZone(fn);
  return (arg) => boundFn(arg)
      // Callers of listeners are not interested in results or errors.
      // Errors in listeners should just be unhandled errors, in the zone
      // the listener was created in, which is what `_bindCallbackToZone`
      // already does.
      .onError((_, __) {});
}

class CblService {
  CblService({
    required this.channel,
  }) {
    channel
      ..addCallEndpoint(_ping)
      ..addCallEndpoint(_installTracingDelegate)
      ..addCallEndpoint(_uninstallTracingDelegate)
      ..addCallEndpoint(_releaseObject)
      ..addCallEndpoint(_removeChangeListener)
      ..addCallEndpoint(_encryptionKeyFromPassword)
      ..addCallEndpoint(_removeDatabase)
      ..addCallEndpoint(_databaseExists)
      ..addCallEndpoint(_copyDatabase)
      ..addCallEndpoint(_openDatabase)
      ..addCallEndpoint(_deleteDatabase)
      ..addCallEndpoint(_getScope)
      ..addCallEndpoint(_getScopes)
      ..addCallEndpoint(_getCollection)
      ..addCallEndpoint(_getCollections)
      ..addCallEndpoint(_createCollection)
      ..addCallEndpoint(_deleteCollection)
      ..addCallEndpoint(_getCollectionCount)
      ..addCallEndpoint(_getCollectionIndexes)
      ..addCallEndpoint(_getDocument)
      ..addCallEndpoint(_saveDocument)
      ..addCallEndpoint(_deleteDocument)
      ..addCallEndpoint(_purgeDocument)
      ..addCallEndpoint(_beginDatabaseTransaction)
      ..addCallEndpoint(_endDatabaseTransaction)
      ..addCallEndpoint(_setDocumentExpiration)
      ..addCallEndpoint(_getDocumentExpiration)
      ..addCallEndpoint(_performDatabaseMaintenance)
      ..addCallEndpoint(_changeDatabaseEncryptionKey)
      ..addCallEndpoint(_addCollectionChangeListener)
      ..addCallEndpoint(_addDocumentChangeListener)
      ..addCallEndpoint(_createIndex)
      ..addCallEndpoint(_deleteIndex)
      ..addCallEndpoint(_blobExists)
      ..addStreamEndpoint(_readBlob)
      ..addCallEndpoint(_saveBlob)
      ..addCallEndpoint(_createQuery)
      ..addCallEndpoint(_setQueryParameters)
      ..addCallEndpoint(_explainQuery)
      ..addCallEndpoint(_executeQuery)
      ..addStreamEndpoint(_getQueryResultSet)
      ..addCallEndpoint(_addQueryChangeListener)
      ..addCallEndpoint(_createReplicator)
      ..addCallEndpoint(_getReplicatorStatus)
      ..addCallEndpoint(_startReplicator)
      ..addCallEndpoint(_stopReplicator)
      ..addCallEndpoint(_addReplicatorChangeListener)
      ..addCallEndpoint(_addDocumentReplicationsListener)
      ..addCallEndpoint(_replicatorIsDocumentPending)
      ..addCallEndpoint(_replicatorPendingDocumentIds);
  }

  final Channel channel;

  Future<void> dispose() async {
    final objects = _objectRegistry.getObjects();
    _objectRegistry.clear();

    await Future.wait(objects
        .whereType<ClosableResource>()
        .where((resource) => !resource.isClosed)
        .map((resource) => resource.close()));
  }

  // === Handlers ==============================================================

  DateTime _ping(PingRequest _) => DateTime.now();

  Future<void> _installTracingDelegate(InstallTracingDelegate request) =>
      TracingDelegate.install(request.delegate);

  Future<void> _uninstallTracingDelegate(UninstallTracingDelegate _) =>
      TracingDelegate.uninstall(currentTracingDelegate);

  FutureOr<void> _releaseObject(ReleaseObject request) {
    final object = _objectRegistry.removeObjectById(request.objectId);
    if (object is ClosableResource) {
      return object.close();
    }
  }

  Future<void> _removeChangeListener(
    RemoveChangeListener request,
  ) async {
    final target = _objectRegistry.getObjectOrThrow<Object>(request.targetId);
    final token = _listenerIdsToTokens.remove(request.listenerId)!
        as AbstractListenerToken;

    if (target is Collection) {
      await target.removeChangeListener(token);
    } else if (target is _Query) {
      target.query.removeChangeListener(token);
    } else if (target is Replicator) {
      await target.removeChangeListener(token);
    } else {
      assert(
        false,
        'target to remove change listener from is of unknown type: $target',
      );
    }
  }

  EncryptionKeyImpl _encryptionKeyFromPassword(
    EncryptionKeyFromPassword request,
  ) =>
      EncryptionKeyImpl.passwordSync(request.password);

  void _removeDatabase(RemoveDatabase request) =>
      FfiDatabase.remove(request.name, directory: request.directory);

  bool _databaseExists(DatabaseExists request) =>
      FfiDatabase.exists(request.name, directory: request.directory);

  void _copyDatabase(CopyDatabase request) => FfiDatabase.copy(
        from: request.from,
        name: request.name,
        config: request.config,
      );

  DatabaseState _openDatabase(OpenDatabase request) {
    final database = SyncDatabase(request.name, request.config);
    _objectRegistry.addObject(database);
    return _createDatabaseState(database);
  }

  Future<void> _deleteDatabase(DeleteDatabase request) =>
      _objectRegistry.removeObjectById<Database>(request.databaseId).delete();

  Future<ScopeState?> _getScope(GetScope request) async {
    final scope = _getDatabaseById(request.databaseId).scope(request.name);
    if (scope == null) {
      return null;
    }
    return ScopeState(id: _objectRegistry.addObject(scope), name: scope.name);
  }

  Future<List<ScopeState>> _getScopes(GetScopes request) async =>
      _getDatabaseById(request.databaseId)
          .scopes
          .map((scope) => ScopeState(
                id: _objectRegistry.addObject(scope),
                name: scope.name,
              ))
          .toList();

  Future<CollectionState?> _getCollection(GetCollection request) async {
    final collection = _getScopeById(request.scopeId).collection(request.name);
    if (collection == null) {
      return null;
    }
    return CollectionState(
      id: _objectRegistry.addObject(collection),
      name: collection.name,
    );
  }

  Future<List<CollectionState>> _getCollections(GetCollections request) async =>
      _getScopeById(request.scopeId)
          .collections
          .map((collection) => CollectionState(
                id: _objectRegistry.addObject(collection),
                name: collection.name,
              ))
          .toList();

  Future<CollectionState> _createCollection(CreateCollection request) async {
    final collection = _getDatabaseById(request.databaseId)
        .createCollection(request.collection, request.scope);
    return CollectionState(
      id: _objectRegistry.addObject(collection),
      name: collection.name,
    );
  }

  Future<void> _deleteCollection(DeleteCollection request) async =>
      _getDatabaseById(request.databaseId)
          .deleteCollection(request.collection, request.scope);

  Future<int> _getCollectionCount(GetCollectionCount request) async =>
      _getCollectionById(request.collectionId).count;

  List<String> _getCollectionIndexes(GetCollectionIndexes request) =>
      _getCollectionById(request.collectionId).indexes;

  Future<DocumentState?> _getDocument(GetDocument request) async {
    final document = _getCollectionById(request.collectionId)
        .document(request.documentId) as DelegateDocument?;

    return document?.createState(
      withProperties: true,
      propertiesFormat: request.propertiesFormat,
      objectRegistry: _objectRegistry,
    );
  }

  Future<DocumentState?> _saveDocument(SaveDocument request) async {
    final collection = _getCollectionById(request.collectionId);

    final document = _getDocumentForUpdate<MutableDelegateDocument>(
      request.state,
      concurrencyControl: request.concurrencyControl,
    );

    if (document == null) {
      return null;
    }

    document.setEncodedProperties(request.state.properties!.encodedData!);

    if (collection.saveDocument(document, request.concurrencyControl)) {
      return document.createState(
        withProperties: false,
        objectRegistry: _objectRegistry,
      );
    } else {
      return null;
    }
  }

  Future<DocumentState?> _deleteDocument(DeleteDocument request) async {
    final collection = _getCollectionById(request.collectionId);

    final document = _getDocumentForUpdate(
      request.state,
      concurrencyControl: request.concurrencyControl,
    );

    if (document == null) {
      return null;
    }

    if (collection.deleteDocument(document, request.concurrencyControl)) {
      return document.createState(
        withProperties: false,
        objectRegistry: _objectRegistry,
      );
    } else {
      return null;
    }
  }

  void _purgeDocument(PurgeDocument request) =>
      _getCollectionById(request.collectionId)
          .purgeDocumentById(request.documentId);

  void _beginDatabaseTransaction(BeginDatabaseTransaction request) =>
      _getDatabaseById(request.databaseId).beginTransaction();

  void _endDatabaseTransaction(EndDatabaseTransaction request) =>
      _getDatabaseById(request.databaseId)
          .endTransaction(commit: request.commit);

  void _setDocumentExpiration(SetDocumentExpiration request) =>
      _getCollectionById(request.collectionId)
          .setDocumentExpiration(request.documentId, request.expiration);

  DateTime? _getDocumentExpiration(GetDocumentExpiration request) =>
      _getCollectionById(request.collectionId)
          .getDocumentExpiration(request.documentId);

  void _performDatabaseMaintenance(PerformDatabaseMaintenance request) =>
      _getDatabaseById(request.databaseId).performMaintenance(request.type);

  void _changeDatabaseEncryptionKey(ChangeDatabaseEncryptionKey request) =>
      _getDatabaseById(request.databaseId)
          .changeEncryptionKey(request.encryptionKey);

  void _addCollectionChangeListener(AddCollectionChangeListener request) {
    _listenerIdsToTokens[request.listenerId] =
        _getCollectionById(request.collectionId).addChangeListener((change) {
      channel.call(CallCollectionChangeListener(
        listenerId: request.listenerId,
        documentIds: change.documentIds,
      ));
    });
  }

  void _addDocumentChangeListener(AddDocumentChangeListener request) {
    _listenerIdsToTokens[request.listenerId] =
        _getCollectionById(request.collectionId)
            .addDocumentChangeListener(request.documentId, (_) {
      channel.call(CallDocumentChangeListener(listenerId: request.listenerId));
    });
  }

  void _createIndex(CreateIndex request) =>
      _getCollectionById(request.collectionId).createIndex(
        request.name,
        _CBLIndexSpecIndex(request.spec),
      );

  void _deleteIndex(DeleteIndex request) =>
      _getCollectionById(request.collectionId).deleteIndex(request.name);

  bool _blobExists(BlobExists request) => _getDatabaseById(request.databaseId)
      .blobStore
      .blobExists(request.properties);

  Stream<MessageData> _readBlob(ReadBlob request) =>
      _getDatabaseById(request.databaseId)
          .blobStore
          .readBlob(request.properties)!
          .map(MessageData.new);

  Future<SaveBlobResponse> _saveBlob(SaveBlob request) async {
    final stream = channel
        .stream(ReadBlobUpload(uploadId: request.uploadId))
        .map((event) => event.data);
    final properties = await _getDatabaseById(request.databaseId)
        .blobStore
        .saveBlobFromStream(request.contentType, stream);
    return SaveBlobResponse(properties);
  }

  QueryState _createQuery(CreateQuery request) {
    final query = FfiQuery(
      database: _getDatabaseById(request.databaseId),
      definition: request.queryDefinition,
      language: request.language,
    );
    final id = _objectRegistry.addObject(_Query(query, request.resultEncoding));
    return QueryState(id: id, columnNames: query.columnNames);
  }

  void _setQueryParameters(SetQueryParameters request) {
    _getQueryById(request.queryId).query.setParameters(
          (request.parameters?.toPlainObject() as StringMap?)
              ?.let(Parameters.new),
        );
  }

  String _explainQuery(ExplainQuery request) =>
      _getQueryById(request.queryId).query.explain();

  int _executeQuery(ExecuteQuery request) =>
      _getQueryById(request.queryId).execute();

  Stream<TransferableValue> _getQueryResultSet(GetQueryResultSet request) =>
      _getQueryById(request.queryId).takeResultSet(request.resultSetId);

  void _addQueryChangeListener(AddQueryChangeListener request) {
    _listenerIdsToTokens[request.listenerId] =
        _getQueryById(request.queryId).addChangeListener((resultSetId) {
      channel.call(CallQueryChangeListener(
        listenerId: request.listenerId,
        resultSetId: resultSetId,
      ));
    });
  }

  Future<int> _createReplicator(CreateReplicator request) async {
    var target = request.target;
    if (target is ServiceDatabaseEndpoint) {
      target = DatabaseEndpoint(_getDatabaseById(target.databaseId));
    }

    ReplicationFilter createReplicationFilter(int filterId) =>
        _createReplicatorFilterForwarder(
          filterId,
          propertiesFormat: request.propertiesFormat,
        );

    ConflictResolver createConflictResolver(int resolverId) =>
        _createConflictResolverForwarder(
          resolverId,
          propertiesFormat: request.propertiesFormat,
        );

    final config = ReplicatorConfiguration(
      target: target,
      replicatorType: request.replicatorType,
      continuous: request.continuous,
      authenticator: request.authenticator,
      pinnedServerCertificate: request.pinnedServerCertificate?.toTypedList(),
      trustedRootCertificates: request.trustedRootCertificates?.toTypedList(),
      headers: request.headers,
      enableAutoPurge: request.enableAutoPurge,
      heartbeat: request.heartbeat,
      maxAttempts: request.maxAttempts,
      maxAttemptWaitTime: request.maxAttemptWaitTime,
    );
    for (final collection in request.collections) {
      config.addCollection(
        _getCollectionById(collection.collectionId),
        CollectionConfiguration(
          channels: collection.channels,
          documentIds: collection.documentIds,
          pushFilter: collection.pushFilterId?.let(createReplicationFilter),
          pullFilter: collection.pullFilterId?.let(createReplicationFilter),
          conflictResolver:
              collection.conflictResolverId?.let(createConflictResolver),
        ),
      );
    }
    final replicator = await FfiReplicator.create(
      config,
      // The isolate running this service should not be crashed by unhandled
      // errors in the callbacks registered by the client. The client is
      // responsible for reporting those errors as unhandled in its isolate.
      ignoreCallbackErrorsInDart: true,
    );
    return _objectRegistry.addObject(replicator);
  }

  ReplicatorStatus _getReplicatorStatus(GetReplicatorStatus request) =>
      _getReplicatorById(request.replicatorId).status;

  void _startReplicator(StartReplicator request) =>
      _getReplicatorById(request.replicatorId).start(reset: request.reset);

  void _stopReplicator(StopReplicator request) =>
      _getReplicatorById(request.replicatorId).stop();

  void _addReplicatorChangeListener(AddReplicatorChangeListener request) {
    _listenerIdsToTokens[request.listenerId] =
        _getReplicatorById(request.replicatorId).addChangeListener((change) {
      channel.call(CallReplicatorChangeListener(
        listenerId: request.listenerId,
        status: change.status,
      ));
    });
  }

  void _addDocumentReplicationsListener(
    AddDocumentReplicationListener request,
  ) {
    _listenerIdsToTokens[request.listenerId] =
        _getReplicatorById(request.replicatorId)
            .addDocumentReplicationListener((change) {
      channel.call(CallDocumentReplicationListener(
        listenerId: request.listenerId,
        event: DocumentReplicationEvent(
          isPush: change.isPush,
          documents: change.documents,
        ),
      ));
    });
  }

  bool _replicatorIsDocumentPending(ReplicatorIsDocumentPending request) =>
      _getReplicatorById(request.replicatorId).isDocumentPendingInCollection(
        request.documentId,
        _getCollectionById(request.collectionId),
      );

  List<String> _replicatorPendingDocumentIds(
    ReplicatorPendingDocumentIds request,
  ) =>
      _getReplicatorById(request.replicatorId)
          .pendingDocumentIdsInCollection(
            _getCollectionById(request.collectionId),
          )
          .toList();

  // === Misc ==================================================================

  DatabaseState _createDatabaseState(SyncDatabase database) => DatabaseState(
        id: _objectRegistry.getObjectId(database)!,
        name: database.name,
        path: database.path,
      );

  T? _getDocumentForUpdate<T extends DelegateDocument>(
    DocumentState state, {
    required ConcurrencyControl concurrencyControl,
  }) {
    if (state.revisionId == null) {
      // The document is new.
      return MutableDocument.withId(state.docId) as T;
    } else {
      if (state.id != null) {
        // A document has already been obtained and added to the object
        // registry for the proxy document.
        return _objectRegistry.getObjectOrThrow<T>(state.id!);
      } else {
        // The proxy document has been created through `toMutable` and does not
        // have an equivalent object in the object registry yet, and we need to
        // create it.
        final source =
            _objectRegistry.getObjectOrThrow<DelegateDocument>(state.sourceId!);

        if (concurrencyControl == ConcurrencyControl.failOnConflict &&
            source.revisionId != state.revisionId) {
          // The source document has been updated since the proxy document was
          // created, so they no longer point to the same revision.
          return null;
        }

        return source.toMutable() as T;
      }
    }
  }

  ReplicationFilter _createReplicatorFilterForwarder(
    int filterId, {
    required EncodingFormat? propertiesFormat,
  }) =>
      (document, flags) async {
        final state = await (document as DelegateDocument).createState(
          withProperties: true,
          propertiesFormat: propertiesFormat,
          objectRegistry: _objectRegistry,
        );

        return channel.call(CallReplicationFilter(
          filterId: filterId,
          state: state,
          flags: flags,
        ));
      };

  ConflictResolver _createConflictResolverForwarder(
    int resolverId, {
    required EncodingFormat? propertiesFormat,
  }) =>
      ConflictResolver.from((conflict) async {
        final localDocument = conflict.localDocument as DelegateDocument?;
        final remoteDocument = conflict.remoteDocument as DelegateDocument?;
        final localState = await localDocument?.createState(
          withProperties: true,
          propertiesFormat: propertiesFormat,
          objectRegistry: _objectRegistry,
        );
        final remoteState = await remoteDocument?.createState(
          withProperties: true,
          propertiesFormat: propertiesFormat,
          objectRegistry: _objectRegistry,
        );

        final resolvedState = await channel.call(CallConflictResolver(
          resolverId: resolverId,
          localState: localState,
          remoteState: remoteState,
        ));

        if (resolvedState != null) {
          final stateToExistingDocument = {
            localState: conflict.localDocument,
            remoteState: conflict.remoteDocument,
          };

          return stateToExistingDocument[resolvedState] ??
              MutableDelegateDocument.fromDelegate(
                NewDocumentDelegate(
                  resolvedState.docId,
                  resolvedState.properties!.encodedData,
                ),
              );
        }

        return null;
      });

  // === Objects ===============================================================

  final _objectRegistry = ObjectRegistry();

  FfiDatabase _getDatabaseById(int id) => _objectRegistry.getObjectOrThrow(id);

  FfiScope _getScopeById(int id) => _objectRegistry.getObjectOrThrow(id);

  FfiCollection _getCollectionById(int id) =>
      _objectRegistry.getObjectOrThrow(id);

  _Query _getQueryById(int id) => _objectRegistry.getObjectOrThrow(id);

  FfiReplicator _getReplicatorById(int id) =>
      _objectRegistry.getObjectOrThrow(id);

  final _listenerIdsToTokens = <int, ListenerToken>{};
}

class _CBLIndexSpecIndex implements IndexImplInterface {
  _CBLIndexSpecIndex(this.spec);

  final CBLIndexSpec spec;

  @override
  CBLIndexSpec toCBLIndexSpec() => spec;
}

class _Query {
  _Query(this.query, this.resultEncoding);

  final FfiQuery query;
  final EncodingFormat? resultEncoding;

  int _nextResultSetId = 0;
  final _resultSets = <int, ResultSet>{};

  int execute() => _storeResultSet(query.execute());

  int _storeResultSet(ResultSet resultSet) {
    final id = _nextResultSetId++;
    _resultSets[id] = resultSet;
    return id;
  }

  Stream<TransferableValue> takeResultSet(int id) =>
      _resultSetStream(_resultSets.remove(id)!);

  Stream<TransferableValue> _resultSetStream(ResultSet resultSet) =>
      resultSet.asStream().map((result) {
        final resultImpl = result as ResultImpl;
        final resultEncoding = this.resultEncoding;
        if (resultEncoding != null) {
          return TransferableValue.fromEncodedData(
            resultImpl.encodeColumnValues(resultEncoding),
          );
        } else {
          return TransferableValue.fromValue(resultImpl.columnValuesArray!);
        }
      });

  ListenerToken addChangeListener(void Function(int resultSetId) listener) =>
      query.addChangeListener((change) {
        listener(_storeResultSet(change.results));
      });
}

extension on ObjectRegistry {
  T getObjectOrThrow<T>(int id) {
    final object = getObject<T>(id);
    if (object == null) {
      throw NotFoundException(id, T.toString());
    }
    return object;
  }
}

extension on DelegateDocument {
  Future<DocumentState> createState({
    required bool withProperties,
    EncodingFormat? propertiesFormat,
    required ObjectRegistry objectRegistry,
  }) async {
    TransferableValue? properties;
    if (withProperties) {
      if (propertiesFormat != null) {
        properties = TransferableValue.fromEncodedData(
          await encodeProperties(format: propertiesFormat),
        );
      } else {
        properties = TransferableValue.fromValue(
          (delegate as FfiDocumentDelegate).propertiesDict,
        );
      }
    }

    return DocumentState(
      id: objectRegistry.addObjectIfAbsent(this),
      docId: id,
      revisionId: revisionId,
      sequence: sequence,
      properties: properties,
    );
  }
}
