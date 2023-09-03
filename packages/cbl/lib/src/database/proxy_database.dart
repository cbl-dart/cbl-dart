import 'dart:async';
import 'dart:io';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../document.dart';
import '../document/blob.dart';
import '../document/document.dart';
import '../document/fragment.dart';
import '../document/proxy_document.dart';
import '../errors.dart';
import '../fleece/decoder.dart';
import '../fleece/dict_key.dart';
import '../query/index/index.dart';
import '../service/cbl_service.dart';
import '../service/cbl_service_api.dart';
import '../service/cbl_worker.dart';
import '../service/channel.dart';
import '../service/proxy_object.dart';
import '../service/serialization/json_packet_codec.dart';
import '../support/encoding.dart';
import '../support/listener_token.dart';
import '../support/resource.dart';
import '../support/streams.dart';
import '../support/tracing.dart';
import '../support/utils.dart';
import '../tracing.dart';
import '../typed_data.dart';
import '../typed_data/adapter.dart';
import 'blob_store.dart';
import 'collection.dart';
import 'collection_change.dart';
import 'database.dart';
import 'database_base.dart';
import 'database_change.dart';
import 'database_configuration.dart';
import 'document_change.dart';
import 'proxy_blob_store.dart';
import 'scope.dart';

class ProxyDatabase extends ProxyObject
    with DatabaseBase<ProxyDocumentDelegate>, ClosableResourceMixin
    implements AsyncDatabase, BlobStoreHolder {
  ProxyDatabase(
    this.client,
    DatabaseConfiguration config,
    this.typedDataAdapter,
    this.state,
    this.encodingFormat,
  )   : name = state.name,
        path = state.path,
        // Make a copy of config, since it is mutable.
        _config = DatabaseConfiguration.from(config),
        super(client.channel, state.id);

  static Future<void> remove(
    String name, {
    String? directory,
    required CblServiceClient client,
  }) =>
      client.channel.call(RemoveDatabase(name, directory));

  static Future<bool> exists(
    String name, {
    String? directory,
    required CblServiceClient client,
  }) =>
      client.channel.call(DatabaseExists(name, directory));

  static Future<void> copy({
    required String from,
    required String name,
    DatabaseConfiguration? config,
    required CblServiceClient client,
  }) =>
      client.channel.call(CopyDatabase(from, name, config));

  static Future<ProxyDatabase> open({
    required String name,
    required DatabaseConfiguration config,
    required CblServiceClient client,
    TypedDataAdapter? typedDataAdapter,
    required EncodingFormat? encodingFormat,
  }) async {
    final state = await client.channel.call(OpenDatabase(name, config));
    return ProxyDatabase(
      client,
      config,
      typedDataAdapter,
      state,
      encodingFormat,
    );
  }

  @override
  final TypedDataAdapter? typedDataAdapter;

  @override
  final dictKeys = OptimizingDictKeys();

  @override
  final sharedKeysTable = SharedKeysTable();

  var _deleteOnClose = false;

  final CblServiceClient client;

  final EncodingFormat? encodingFormat;

  @override
  late final BlobStore blobStore = ProxyBlobStore(this);

  final _documentFinalizers = <Future<void> Function()>[];

  final DatabaseConfiguration _config;

  DatabaseState state;

  @override
  final String name;

  @override
  String? path;

  @override
  Future<int> get count =>
      defaultCollection.then((collection) => collection.count);

  @override
  DatabaseConfiguration get config => DatabaseConfiguration.from(_config);

  @override
  late final Future<AsyncScope> defaultScope =
      scope(Scope.defaultName).then((scope) => scope!);

  @override
  Future<List<AsyncScope>> get scopes => use(() async {
        final scopeStates = await channel.call(GetScopes(objectId));

        return scopeStates
            .map((state) =>
                ProxyScope(client: client, state: state, database: this))
            .toList();
      });

  @override
  Future<AsyncScope?> scope(String name) => use(() async {
        final scopeState = await channel.call(GetScope(objectId, name));

        if (scopeState == null) {
          return null;
        }

        return ProxyScope(client: client, state: scopeState, database: this);
      });

  @override
  late final Future<AsyncCollection> defaultCollection = defaultScope
      .then((scope) => scope.collection(Collection.defaultName))
      .then((collection) => collection!);

  @override
  Future<AsyncCollection?> collection(
    String name, [
    String scope = Scope.defaultName,
  ]) async =>
      (await this.scope(scope))?.collection(name);

  @override
  Future<List<AsyncCollection>> collections([
    String scope = Scope.defaultName,
  ]) async =>
      (await this.scope(scope))?.collections ?? Future.value([]);

  @override
  Future<AsyncCollection> createCollection(
    String name, [
    String scope = Scope.defaultName,
  ]) =>
      use(() async {
        final state =
            await channel.call(CreateCollection(objectId, scope, name));

        return ProxyCollection(
          client: client,
          state: state,
          scope: (await this.scope(scope))! as ProxyScope,
        );
      });

  @override
  Future<void> deleteCollection(
    String name, [
    String scope = Scope.defaultName,
  ]) =>
      use(() => channel.call(DeleteCollection(objectId, scope, name)));

  @override
  Future<void> beginTransaction() =>
      channel.call(BeginDatabaseTransaction(databaseId: objectId));

  @override
  Future<void> endTransaction({required bool commit}) => channel
      .call(EndDatabaseTransaction(databaseId: objectId, commit: commit));

  @override
  Future<Document?> document(String id) =>
      defaultCollection.then((collection) => collection.document(id));

  @override
  Future<DocumentFragment> operator [](String id) =>
      defaultCollection.then((collection) => collection[id]);

  @override
  Future<D?> typedDocument<D extends TypedDocumentObject>(String id) =>
      // ignore: cast_nullable_to_non_nullable
      super.typedDocument<D>(id) as Future<D?>;

  @override
  Future<bool> saveDocument(
    covariant MutableDelegateDocument document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]) =>
      defaultCollection.then((collection) =>
          collection.saveDocument(document, concurrencyControl));

  @override
  Future<bool> saveDocumentWithConflictHandler(
    covariant MutableDelegateDocument document,
    SaveConflictHandler conflictHandler,
  ) =>
      defaultCollection.then((collection) => collection
          .saveDocumentWithConflictHandler(document, conflictHandler));

  @override
  AsyncSaveTypedDocument<D, MD> saveTypedDocument<D extends TypedDocumentObject,
          MD extends TypedMutableDocumentObject>(
    TypedMutableDocumentObject<D, MD> document,
  ) =>
      _ProxySaveTypedDocument(this, document);

  @override
  Future<bool> deleteDocument(
    covariant DelegateDocument document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]) =>
      defaultCollection.then((collection) =>
          collection.deleteDocument(document, concurrencyControl));

  @override
  Future<bool> deleteTypedDocument(
    TypedDocumentObject document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]) async {
    useWithTypedData();
    return deleteDocument(
      document.internal as DelegateDocument,
      concurrencyControl,
    );
  }

  @override
  Future<void> purgeDocument(covariant DelegateDocument document) =>
      defaultCollection
          .then((collection) => collection.purgeDocument(document));

  @override
  Future<void> purgeTypedDocument(TypedDocumentObject document) async {
    useWithTypedData();
    await purgeDocument(document.internal as DelegateDocument);
  }

  @override
  Future<void> purgeDocumentById(String id) =>
      defaultCollection.then((collection) => collection.purgeDocumentById(id));

  @override
  Future<void> saveBlob(covariant BlobImpl blob) =>
      use(() => blob.ensureIsInstalled(this));

  @override
  Future<Blob?> getBlob(Map<String, Object?> properties) => use(() async {
        checkBlobMetadata(properties);
        if (await blobStore.blobExists(properties)) {
          return BlobImpl.fromProperties(properties, database: this);
        }
        return null;
      });

  @override
  Future<void> inBatch(FutureOr<void> Function() fn) =>
      use(() => runInTransactionAsync(fn, requiresNewTransaction: true));

  @override
  Future<void> setDocumentExpiration(String id, DateTime? expiration) =>
      defaultCollection.then(
        (collection) => collection.setDocumentExpiration(id, expiration),
      );

  @override
  Future<DateTime?> getDocumentExpiration(String id) => defaultCollection
      .then((collection) => collection.getDocumentExpiration(id));

  @override
  Future<ListenerToken> addChangeListener(DatabaseChangeListener listener) =>
      defaultCollection.then((collection) => collection
          .addChangeListener((change) => listener(change.toDatabaseChange())));

  @override
  Future<ListenerToken> addDocumentChangeListener(
    String id,
    DocumentChangeListener listener,
  ) =>
      defaultCollection.then(
          (collection) => collection.addDocumentChangeListener(id, listener));

  @override
  Future<void> removeChangeListener(ListenerToken token) async =>
      defaultCollection
          .then((collection) => collection.removeChangeListener(token));

  @override
  AsyncListenStream<DatabaseChange> changes() => useSync(() => ListenerStream(
        parent: this,
        addListener: (listener) async {
          final collection = (await defaultCollection) as ProxyCollection;
          return collection._addChangeListener(
            (change) => listener(change.toDatabaseChange()),
          );
        },
      ));

  @override
  AsyncListenStream<DocumentChange> documentChanges(String id) =>
      useSync(() => ListenerStream(
            parent: this,
            addListener: (listener) async {
              final collection = (await defaultCollection) as ProxyCollection;
              return collection._addDocumentChangeListener(id, listener);
            },
          ));

  @override
  Future<void> performClose() async {
    await Future.wait<void>(
      _documentFinalizers.map((finalizer) => finalizer()),
    );
    _documentFinalizers.clear();

    if (_deleteOnClose) {
      await channel.call(DeleteDatabase(objectId));
    } else {
      await finalizeEarly();
    }
    path = null;
  }

  @override
  Future<void> close() =>
      asyncOperationTracePoint(() => CloseDatabaseOp(this), super.close);

  @override
  Future<void> delete() {
    _deleteOnClose = true;
    return close();
  }

  @override
  Future<void> performMaintenance(MaintenanceType type) =>
      use(() => channel.call(PerformDatabaseMaintenance(
            databaseId: objectId,
            type: type,
          )));

  @override
  Future<void> changeEncryptionKey(EncryptionKey? newKey) =>
      use(() => channel.call(ChangeDatabaseEncryptionKey(
            databaseId: objectId,
            encryptionKey: newKey,
          )));

  @override
  Future<List<String>> get indexes =>
      defaultCollection.then((collections) => collections.indexes);

  @override
  Future<void> createIndex(String name, covariant IndexImplInterface index) =>
      defaultCollection
          .then((collections) => collections.createIndex(name, index));

  @override
  Future<void> deleteIndex(String name) =>
      defaultCollection.then((collections) => collections.deleteIndex(name));

  @override
  String toString() => 'ProxyDatabase($name)';

  void registerDocumentFinalizer(Future<void> Function() finalizer) {
    assert(!isClosed);
    _documentFinalizers.add(finalizer);
  }

  void unregisterDocumentFinalizer(Future<void> Function() finalizer) {
    _documentFinalizers.remove(finalizer);
  }
}

class WorkerDatabase extends ProxyDatabase {
  WorkerDatabase._(
    this.worker,
    CblServiceClient client,
    DatabaseConfiguration config,
    TypedDataAdapter? typedDataAdapter,
    DatabaseState state,
  ) : super(client, config, typedDataAdapter, state, null);

  static Future<WorkerDatabase> open(
    String name, [
    DatabaseConfiguration? config,
    TypedDataAdapter? typedDataAdapter,
  ]) async {
    config ??= DatabaseConfiguration();

    final worker = CblWorker(debugName: _databaseName(name));
    await worker.start();

    final client = CblServiceClient(channel: worker.channel);

    await client.channel.call(InstallTracingDelegate(
      currentTracingDelegate.createWorkerDelegate(),
    ));

    try {
      final state = await client.channel.call(OpenDatabase(name, config));
      return WorkerDatabase._(worker, client, config, typedDataAdapter, state);
    } on CouchbaseLiteException {
      await client.channel.call(UninstallTracingDelegate());
      await worker.stop();
      rethrow;
    }
  }

  // TODO(blaugold): use tracing delegates in one-off workers

  static Future<void> remove(String name, {String? directory}) =>
      CblWorker.executeCall(
        RemoveDatabase(name, directory),
        debugName: 'WorkerDatabase.remove',
      );

  static Future<bool> exists(String name, {String? directory}) =>
      CblWorker.executeCall(
        DatabaseExists(name, directory),
        debugName: 'WorkerDatabase.exists',
      );

  static Future<void> copy({
    required String from,
    required String name,
    DatabaseConfiguration? config,
  }) =>
      CblWorker.executeCall(
        CopyDatabase(from, name, config),
        debugName: 'WorkerDatabase.copy',
      );

  final CblWorker worker;

  @override
  Future<void> performClose() async {
    await super.performClose();
    await client.channel.call(UninstallTracingDelegate());
    await worker.stop();
  }
}

class RemoteDatabase extends ProxyDatabase {
  RemoteDatabase._(
    CblServiceClient client,
    DatabaseConfiguration config,
    TypedDataAdapter? typedDataAdapter,
    DatabaseState state,
  ) : super(client, config, typedDataAdapter, state, EncodingFormat.fleece);

  static Future<RemoteDatabase> open(
    Uri uri,
    String name,
    DatabaseConfiguration config, [
    TypedDataAdapter? typedDataAdapter,
  ]) async {
    final channel = Channel(
      transport: WebSocketChannel.connect(uri),
      packetCodec: JsonPacketCodec(),
      serializationRegistry: cblServiceSerializationRegistry(),
    );
    final client = CblServiceClient(channel: channel);
    final state = await channel.call(OpenDatabase(name, config));
    return RemoteDatabase._(client, config, typedDataAdapter, state);
  }

  @override
  Future<void> performClose() async {
    await super.performClose();
    await channel.close();
  }
}

String _databaseName(String path) => path.split(Platform.pathSeparator).last;

class _ProxySaveTypedDocument<D extends TypedDocumentObject,
        MD extends TypedMutableDocumentObject>
    extends SaveTypedDocumentBase<D, MD>
    implements AsyncSaveTypedDocument<D, MD> {
  _ProxySaveTypedDocument(ProxyDatabase super.database, super.document);

  @override
  Future<bool> withConcurrencyControl([
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]) =>
      super.withConcurrencyControl(concurrencyControl) as Future<bool>;

  @override
  Future<bool> withConflictHandler(
    TypedSaveConflictHandler<D, MD> conflictHandler,
  ) =>
      super.withConflictHandler(conflictHandler) as Future<bool>;
}

class ProxyScope extends ProxyObject
    with ScopeBase, ClosableResourceMixin
    implements AsyncScope {
  ProxyScope({
    required this.client,
    required ScopeState state,
    required this.database,
  })  : name = state.name,
        super(client.channel, state.id) {
    needsToBeClosedByParent = false;
    attachTo(database);
  }

  @override
  final ProxyDatabase database;

  final CblServiceClient client;

  @override
  final String name;

  @override
  Future<List<AsyncCollection>> get collections => use(() async {
        final states = await channel.call(GetCollections(objectId));
        return states
            .map((state) =>
                ProxyCollection(client: client, state: state, scope: this))
            .toList();
      });

  @override
  Future<AsyncCollection?> collection(String name) => use(() async {
        final state = await channel.call(GetCollection(objectId, name));

        if (state == null) {
          return null;
        }

        return ProxyCollection(client: client, state: state, scope: this);
      });

  @override
  String toString() => 'ProxyScope($name)';
}

class ProxyCollection extends ProxyObject
    with CollectionBase<ProxyDocumentDelegate>, ClosableResourceMixin
    implements AsyncCollection {
  ProxyCollection({
    required this.client,
    required CollectionState state,
    required this.scope,
  })  : name = state.name,
        super(client.channel, state.id) {
    needsToBeClosedByParent = false;
    attachTo(scope);
  }

  final CblServiceClient client;

  @override
  final String name;

  @override
  final ProxyScope scope;

  @override
  ProxyDatabase get database => scope.database;

  EncodingFormat? get encodingFormat => database.encodingFormat;

  late final _listenerTokens = ListenerTokenRegistry(this);

  @override
  Future<int> get count =>
      use(() => channel.call(GetCollectionCount(objectId)));

  @override
  Future<Document?> document(String id) => asyncOperationTracePoint(
        () => GetDocumentOp(this, id),
        () => use(() async {
          final state =
              await channel.call(GetDocument(objectId, id, encodingFormat));

          if (state == null) {
            return null;
          }

          return DelegateDocument(
            ProxyDocumentDelegate.fromState(state, database: database),
            collection: this,
          );
        }),
      );

  @override
  Future<DocumentFragment> operator [](String id) async =>
      DocumentFragmentImpl(await document(id));

  @override
  Future<bool> saveDocument(
    covariant MutableDelegateDocument document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]) =>
      asyncOperationTracePoint(
        () => SaveDocumentOp(this, document, concurrencyControl),
        () => use(
          () => database.runInTransactionAsync(() async {
            final delegate = await asyncOperationTracePoint(
              () => PrepareDocumentOp(document),
              () async => prepareDocument(document),
            );

            final state = await channel.call(SaveDocument(
              objectId,
              delegate.getState(),
              concurrencyControl,
            ));

            if (state == null) {
              return false;
            }

            delegate.updateMetadata(state, database: database);

            return true;
          }),
        ),
      );

  @override
  Future<bool> saveDocumentWithConflictHandler(
    covariant MutableDelegateDocument document,
    SaveConflictHandler conflictHandler,
  ) =>
      asyncOperationTracePoint(
        () => SaveDocumentOp(this, document),
        () => use(() => saveDocumentWithConflictHandlerHelper(
              document,
              conflictHandler,
            )),
      );

  @override
  Future<bool> deleteDocument(
    covariant DelegateDocument document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]) =>
      asyncOperationTracePoint(
        () => DeleteDocumentOp(this, document, concurrencyControl),
        () => use(
          () => database.runInTransactionAsync(() async {
            final delegate = await asyncOperationTracePoint(
              () => PrepareDocumentOp(document),
              () async => prepareDocument(document, syncProperties: false),
            );

            final state = await channel.call(DeleteDocument(
              objectId,
              delegate.getState(withProperties: false),
              concurrencyControl,
            ));

            if (state == null) {
              return false;
            }

            delegate.updateMetadata(state, database: database);

            return true;
          }),
        ),
      );

  @override
  Future<void> purgeDocument(covariant DelegateDocument document) async {
    await asyncOperationTracePoint(
      () => PrepareDocumentOp(document),
      () async => prepareDocument(document, syncProperties: false),
    );
    return purgeDocumentById(document.id);
  }

  @override
  Future<void> purgeDocumentById(String id) => use(
        () => database.runInTransactionAsync(
          () => channel.call(PurgeDocument(objectId, id)),
        ),
      );

  @override
  Future<void> setDocumentExpiration(String id, DateTime? expiration) =>
      use(() => channel.call(SetDocumentExpiration(
            collectionId: objectId,
            documentId: id,
            expiration: expiration,
          )));

  @override
  Future<DateTime?> getDocumentExpiration(String id) => use(() => channel
      .call(GetDocumentExpiration(collectionId: objectId, documentId: id)));

  @override
  Future<List<String>> get indexes =>
      use(() => channel.call(GetCollectionIndexes(objectId)));

  @override
  Future<void> createIndex(String name, covariant IndexImplInterface index) =>
      use(() => channel.call(CreateIndex(
            collectionId: objectId,
            name: name,
            spec: index.toCBLIndexSpec(),
          )));

  @override
  Future<void> deleteIndex(String name) =>
      use(() => channel.call(DeleteIndex(collectionId: objectId, name: name)));

  @override
  Future<ListenerToken> addChangeListener(CollectionChangeListener listener) =>
      use(() async {
        final token = await _addChangeListener(listener);
        return token.also(_listenerTokens.add);
      });

  Future<AbstractListenerToken> _addChangeListener(
    CollectionChangeListener listener,
  ) async {
    late final ProxyListenerToken<CollectionChange> token;
    final listenerId = client.registerCollectionChangeListener((documentIds) {
      token.callListener(CollectionChange(this, documentIds));
    });

    await channel.call(AddCollectionChangeListener(
      collectionId: objectId,
      listenerId: listenerId,
    ));

    return token = ProxyListenerToken(client, this, listenerId, listener);
  }

  @override
  Future<ListenerToken> addDocumentChangeListener(
    String id,
    DocumentChangeListener listener,
  ) =>
      use(() async {
        final token = await _addDocumentChangeListener(id, listener);
        return token.also(_listenerTokens.add);
      });

  Future<AbstractListenerToken> _addDocumentChangeListener(
    String id,
    DocumentChangeListener listener,
  ) async {
    late final ProxyListenerToken<DocumentChange> token;
    final listenerId = client.registerDocumentChangeListener(() {
      token.callListener(DocumentChange(database, this, id));
    });

    await channel.call(AddDocumentChangeListener(
      collectionId: objectId,
      documentId: id,
      listenerId: listenerId,
    ));

    return token = ProxyListenerToken(client, this, listenerId, listener);
  }

  @override
  Future<void> removeChangeListener(ListenerToken token) async =>
      use(() => _listenerTokens.remove(token));

  @override
  AsyncListenStream<CollectionChange> changes() => useSync(() => ListenerStream(
        parent: this,
        addListener: _addChangeListener,
      ));

  @override
  AsyncListenStream<DocumentChange> documentChanges(String id) =>
      useSync(() => ListenerStream(
            parent: this,
            addListener: (listener) => _addDocumentChangeListener(id, listener),
          ));

  @override
  String toString() => 'ProxyCollection($fullName)';

  @override
  ProxyDocumentDelegate createNewDocumentDelegate(
    DocumentDelegate oldDelegate,
  ) =>
      ProxyDocumentDelegate.fromDelegate(oldDelegate);
}
