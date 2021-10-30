import 'dart:async';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../database/database.dart';
import '../database/ffi_database.dart';
import '../document/document.dart';
import '../document/proxy_document.dart';
import '../query/ffi_query.dart';
import '../query/index/index.dart';
import '../query/parameters.dart';
import '../query/result.dart';
import '../query/result_set.dart';
import '../replication.dart';
import '../replication/ffi_replicator.dart';
import '../support/encoding.dart';
import '../support/listener_token.dart';
import '../support/utils.dart';
import 'cbl_service_api.dart';
import 'channel.dart';
import 'object_registry.dart';

typedef CblServiceDatabaseChangeListener = void Function(
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
      ..addCallEndpoint(_callDatabaseChangeListener)
      ..addCallEndpoint(_callDocumentChangeListener)
      ..addStreamEndpoint(_readBlobUpload)
      ..addCallEndpoint(_callQueryChangeListener)
      ..addCallEndpoint(_callReplicationFilter)
      ..addCallEndpoint(_callConflictResolver)
      ..addCallEndpoint(_callReplicatorChangeListener)
      ..addCallEndpoint(_callDocumentReplicationListener);
  }

  final Channel channel;

  void unregisterObject(int id) => _objectRegistry.removeObjectById(id);

  int registerDatabaseChangeListener(
    CblServiceDatabaseChangeListener listener,
  ) {
    void handler(CallDatabaseChangeListener request) =>
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
          (request.localState?.id ?? request.remoteState?.id)!,
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

  void _callDatabaseChangeListener(CallDatabaseChangeListener request) =>
      _getDatabaseChangeListenerById(request.listenerId)(request);

  void _callDocumentChangeListener(CallDocumentChangeListener request) =>
      _getDocumentChangeListenerById(request.listenerId)(request);

  Stream<Data> _readBlobUpload(ReadBlobUpload request) =>
      _takeBlobUploadById(request.uploadId);

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

  void Function(CallDatabaseChangeListener) _getDatabaseChangeListenerById(
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
      ..addCallEndpoint(_releaseObject)
      ..addCallEndpoint(_removeChangeListener)
      ..addCallEndpoint(_removeDatabase)
      ..addCallEndpoint(_databaseExists)
      ..addCallEndpoint(_copyDatabase)
      ..addCallEndpoint(_openDatabase)
      ..addCallEndpoint(_getDatabase)
      ..addCallEndpoint(_closeDatabase)
      ..addCallEndpoint(_deleteDatabase)
      ..addCallEndpoint(_getDocument)
      ..addCallEndpoint(_saveDocument)
      ..addCallEndpoint(_deleteDocument)
      ..addCallEndpoint(_purgeDocument)
      ..addCallEndpoint(_beginDatabaseTransaction)
      ..addCallEndpoint(_endDatabaseTransaction)
      ..addCallEndpoint(_setDocumentExpiration)
      ..addCallEndpoint(_getDocumentExpiration)
      ..addCallEndpoint(_performDatabaseMaintenance)
      ..addCallEndpoint(_addDatabaseChangeListener)
      ..addCallEndpoint(_addDocumentChangeListener)
      ..addCallEndpoint(_deleteIndex)
      ..addCallEndpoint(_createIndex)
      ..addStreamEndpoint(_readBlob)
      ..addCallEndpoint(_saveBlob)
      ..addCallEndpoint(_createQuery)
      ..addCallEndpoint(_setQueryParameters)
      ..addCallEndpoint(_explainQuery)
      ..addStreamEndpoint(_executeQuery)
      ..addCallEndpoint(_addQueryChangeListener)
      ..addStreamEndpoint(_queryChangeResultSet)
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
        .whereType<Database>()
        .where((database) => !database.isClosed)
        .map((database) => database.close()));
  }

  // === Handlers ==============================================================

  DateTime _ping(PingRequest _) => DateTime.now();

  void _releaseObject(ReleaseObject request) =>
      _objectRegistry.removeObjectById(request.objectId);

  Future<void> _removeChangeListener(
    RemoveChangeListener request,
  ) async {
    final target = _objectRegistry.getObjectOrThrow<Object>(request.targetId);
    final token = _listenerIdsToTokens.remove(request.listenerId)!
        as AbstractListenerToken;

    if (target is Database) {
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

  DatabaseState _getDatabase(GetDatabase request) =>
      _createDatabaseState(_getDatabaseById(request.databaseId));

  Future<void> _closeDatabase(CloseDatabase request) =>
      _getDatabaseById(request.databaseId).close();

  Future<void> _deleteDatabase(DeleteDatabase request) =>
      _getDatabaseById(request.databaseId).delete();

  Future<DocumentState?> _getDocument(GetDocument request) async {
    final document = _getDatabaseById(request.databaseId)
        .document(request.documentId) as DelegateDocument?;

    if (document == null) {
      return null;
    }

    _objectRegistry.addObject(document);

    return _createDocumentState(
      document,
      propertiesFormat: request.propertiesFormat,
    );
  }

  Future<DocumentState?> _saveDocument(SaveDocument request) async {
    final database = _getDatabaseById(request.databaseId);

    final document = _getDocumentForUpdate(
      database,
      request.state,
      request.concurrencyControl,
    );

    if (document == null) {
      return null;
    }

    document.setProperties(request.state.properties!);

    final success = database.saveDocument(document, request.concurrencyControl);

    return success ? _createDocumentState(document) : null;
  }

  Future<DocumentState?> _deleteDocument(DeleteDocument request) async {
    final database = _getDatabaseById(request.databaseId);

    final document = _getDocumentForUpdate(
      database,
      request.state,
      request.concurrencyControl,
    );

    if (document == null) {
      return null;
    }

    final success =
        database.deleteDocument(document, request.concurrencyControl);

    return success ? _createDocumentState(document) : null;
  }

  void _purgeDocument(PurgeDocument request) =>
      _getDatabaseById(request.databaseId)
          .purgeDocumentById(request.documentId);

  void _beginDatabaseTransaction(BeginDatabaseTransaction request) =>
      _getDatabaseById(request.databaseId).beginTransaction();

  void _endDatabaseTransaction(EndDatabaseTransaction request) =>
      _getDatabaseById(request.databaseId)
          .endTransaction(commit: request.commit);

  void _setDocumentExpiration(SetDocumentExpiration request) =>
      _getDatabaseById(request.databaseId)
          .setDocumentExpiration(request.documentId, request.expiration);

  DateTime? _getDocumentExpiration(GetDocumentExpiration request) =>
      _getDatabaseById(request.databaseId)
          .getDocumentExpiration(request.documentId);

  void _performDatabaseMaintenance(PerformDatabaseMaintenance request) =>
      _getDatabaseById(request.databaseId).performMaintenance(request.type);

  void _addDatabaseChangeListener(AddDatabaseChangeListener request) {
    _listenerIdsToTokens[request.listenerId] =
        _getDatabaseById(request.databaseId).addChangeListener((change) {
      channel.call(CallDatabaseChangeListener(
        listenerId: request.listenerId,
        documentIds: change.documentIds,
      ));
    });
  }

  void _addDocumentChangeListener(AddDocumentChangeListener request) {
    _listenerIdsToTokens[request.listenerId] =
        _getDatabaseById(request.databaseId)
            .addDocumentChangeListener(request.documentId, (_) {
      channel.call(CallDocumentChangeListener(listenerId: request.listenerId));
    });
  }

  void _createIndex(CreateIndex request) =>
      _getDatabaseById(request.databaseId).createIndex(
        request.name,
        _CBLIndexSpecIndex(request.spec),
      );

  void _deleteIndex(DeleteIndex request) =>
      _getDatabaseById(request.databaseId).deleteIndex(request.name);

  Stream<Data> _readBlob(ReadBlob request) =>
      _getDatabaseById(request.databaseId)
          .blobStore
          .readBlob(request.properties)!;

  Future<SaveBlobResponse> _saveBlob(SaveBlob request) async {
    final stream = channel.stream(ReadBlobUpload(uploadId: request.uploadId));
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
      debugCreator: 'CblService._createQuery()',
    );
    final id = _objectRegistry.addObject(_Query(query, request.resultEncoding));
    return QueryState(id: id, columnNames: query.columnNames);
  }

  void _setQueryParameters(SetQueryParameters request) {
    _getQueryById(request.queryId).query.setParameters(
          (request.parameters?.toPlainObject() as StringMap?)
              ?.let((it) => Parameters(it)),
        );
  }

  String _explainQuery(ExplainQuery request) =>
      _getQueryById(request.queryId).query.explain();

  Stream<EncodedData> _executeQuery(ExecuteQuery request) =>
      _getQueryById(request.queryId).execute();

  void _addQueryChangeListener(AddQueryChangeListener request) {
    _listenerIdsToTokens[request.listenerId] =
        _getQueryById(request.queryId).addChangeListener((resultSetId) {
      channel.call(CallQueryChangeListener(
        listenerId: request.listenerId,
        resultSetId: resultSetId,
      ));
    });
  }

  Stream<EncodedData> _queryChangeResultSet(QueryChangeResultSet request) =>
      _getQueryById(request.queryId).takeResultSet(request.resultSetId);

  int _createReplicator(CreateReplicator request) {
    final db = _getDatabaseById(request.databaseId);
    final config = ReplicatorConfiguration(
      database: db,
      target: request.target,
      replicatorType: request.replicatorType,
      continuous: request.continuous,
      authenticator: request.authenticator,
      pinnedServerCertificate: request.pinnedServerCertificate?.toTypedList(),
      headers: request.headers,
      channels: request.channels,
      documentIds: request.documentIds,
      pushFilter: request.pushFilterId?.let((id) => _createReplicatorFilter(
            id,
            propertiesFormat: request.propertiesFormat,
          )),
      pullFilter: request.pullFilterId?.let((id) => _createReplicatorFilter(
            id,
            propertiesFormat: request.propertiesFormat,
          )),
      conflictResolver:
          request.conflictResolverId?.let((id) => _createConflictResolver(
                id,
                propertiesFormat: request.propertiesFormat,
              )),
      enableAutoPurge: request.enableAutoPurge,
      heartbeat: request.heartbeat,
      maxAttempts: request.maxAttempts,
      maxAttemptWaitTime: request.maxAttemptWaitTime,
    );
    final replicator = FfiReplicator(
      config,
      debugCreator: 'CblService._createReplicator()',
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
      _getReplicatorById(request.replicatorId)
          .isDocumentPending(request.documentId);

  List<String> _replicatorPendingDocumentIds(
    ReplicatorPendingDocumentIds request,
  ) =>
      _getReplicatorById(request.replicatorId).pendingDocumentIds.toList();

  // === Misc ==================================================================

  DatabaseState _createDatabaseState(SyncDatabase database) => DatabaseState(
        id: _objectRegistry.getObjectId(database)!,
        name: database.name,
        path: database.path,
        count: database.count,
        indexes: database.indexes,
      );

  Future<DocumentState> _createDocumentState(
    DelegateDocument document, {
    EncodingFormat? propertiesFormat,
  }) async {
    EncodedData? properties;
    if (propertiesFormat != null) {
      properties = await document.getProperties(format: propertiesFormat);
    }

    return DocumentState(
      id: document.id,
      revisionId: document.revisionId,
      sequence: document.sequence,
      properties: properties,
    );
  }

  MutableDelegateDocument? _getDocumentForUpdate(
    SyncDatabase database,
    DocumentState state,
    ConcurrencyControl concurrencyControl,
  ) {
    // Document is new.
    if (state.revisionId == null) {
      return MutableDocument.withId(state.id) as MutableDelegateDocument;
    }

    // Document to update is not new and needs to be loaded.

    final doc =
        database.document(state.id)?.toMutable() as MutableDelegateDocument?;

    switch (concurrencyControl) {
      case ConcurrencyControl.lastWriteWins:
        return doc ??
            MutableDocument.withId(state.id) as MutableDelegateDocument;
      case ConcurrencyControl.failOnConflict:
        if (doc != null &&
            doc.revisionId == state.revisionId &&
            doc.sequence == state.sequence) {
          return doc;
        }
    }
  }

  ReplicationFilter _createReplicatorFilter(
    int filterId, {
    required EncodingFormat propertiesFormat,
  }) =>
      (document, flags) async {
        final state = await (document as DelegateDocument)
            .getState(propertiesFormat: propertiesFormat);

        return channel.call(CallReplicationFilter(
          filterId: filterId,
          state: state,
          flags: flags,
        ));
      };

  ConflictResolver _createConflictResolver(
    int resolverId, {
    required EncodingFormat propertiesFormat,
  }) =>
      ConflictResolver.from((conflict) async {
        final localState = await (conflict.localDocument as DelegateDocument?)
            ?.getState(propertiesFormat: propertiesFormat);
        final remoteState = await (conflict.remoteDocument as DelegateDocument?)
            ?.getState(propertiesFormat: propertiesFormat);

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
                ProxyDocumentDelegate.fromState(resolvedState),
              );
        }
      });

  // === Objects ===============================================================

  final _objectRegistry = ObjectRegistry();

  FfiDatabase _getDatabaseById(int id) => _objectRegistry.getObjectOrThrow(id);

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
  final EncodingFormat resultEncoding;

  int _nextResultSetId = 0;
  final _resultSets = <int, ResultSet>{};

  Stream<EncodedData> execute() => _resultSetStream(query.execute());

  int _storeResultSet(ResultSet resultSet) {
    final id = _nextResultSetId++;
    _resultSets[id] = resultSet;
    return id;
  }

  Stream<EncodedData> takeResultSet(int id) =>
      _resultSetStream(_resultSets.remove(id)!);

  Stream<EncodedData> _resultSetStream(ResultSet resultSet) =>
      resultSet.asStream().map((result) =>
          (result as ResultImpl).encodeColumnValues(resultEncoding));

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
  Future<DocumentState> getState({
    required EncodingFormat propertiesFormat,
  }) async {
    final properties = await getProperties(format: propertiesFormat);

    return DocumentState(
      id: id,
      revisionId: revisionId,
      sequence: sequence,
      properties: properties,
    );
  }
}
