import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:path/path.dart' as path_lib;

import '../bindings.dart';
import '../document/blob.dart';
import '../document/document.dart';
import '../document/ffi_document.dart';
import '../document/fragment.dart';
import '../errors.dart';
import '../fleece/containers.dart' as fl;
import '../fleece/decoder.dart';
import '../fleece/dict_key.dart';
import '../query.dart';
import '../query/ffi_query.dart';
import '../query/index/ffi_query_index.dart';
import '../query/index/index.dart';
import '../support/async_callback.dart';
import '../support/edition.dart';
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
import 'ffi_blob_store.dart';
import 'scope.dart';

final _bindings = CBLBindings.instance.database;

final class FfiDatabase
    with DatabaseBase<FfiDocumentDelegate>, ClosableResourceMixin
    implements SyncDatabase, BlobStoreHolder, Finalizable {
  factory FfiDatabase({
    required String name,
    DatabaseConfiguration? config,
    TypedDataAdapter? typedDataAdapter,
  }) {
    config ??= DatabaseConfiguration();

    // Ensure the directory exists, in which to create the database,
    Directory(config.directory).createSync(recursive: true);

    return FfiDatabase._(
      // Make a copy of the configuration, since its mutable.
      config: DatabaseConfiguration.from(config),
      pointer: _bindings.open(name, config.toCBLDatabaseConfiguration()),
      typedDataAdapter: typedDataAdapter,
    );
  }

  FfiDatabase._({
    required DatabaseConfiguration config,
    required this.pointer,
    required this.typedDataAdapter,
  }) : _config = config {
    _bindings.bindToDartObject(this, pointer);
    name = _bindings.name(pointer);
    _path = _bindings.path(pointer);
  }

  static void remove(String name, {String? directory}) =>
      _bindings.deleteDatabase(name, directory);

  static bool exists(String name, {String? directory}) =>
      _bindings.databaseExists(name, directory);

  static void copy({
    required String from,
    required String name,
    DatabaseConfiguration? config,
  }) => _bindings.copyDatabase(
    _formatCopyFromPath(from),
    name,
    config?.toCBLDatabaseConfiguration(),
  );

  /// Ensures that the path ends with a separator to signal that it is a
  /// directory.
  ///
  /// This is currently required by the native implementation.
  ///
  /// https://github.com/cbl-dart/cbl-dart/issues/444
  // TODO(blaugold): remove workaround once the CBL C SDK is fixed
  static String _formatCopyFromPath(String from) =>
      path_lib.normalize(from) + path_lib.separator;

  final Pointer<CBLDatabase> pointer;

  @override
  final TypedDataAdapter? typedDataAdapter;

  @override
  final dictKeys = OptimizingDictKeys();

  @override
  final sharedKeysTable = SharedKeysTable();

  @override
  late final SyncBlobStore blobStore = FfiBlobStore(this);

  final DatabaseConfiguration _config;

  var _deleteOnClose = false;

  @override
  late final String name;

  @override
  String? get path => _path;
  String? _path;

  @override
  int get count => defaultCollection.count;

  @override
  DatabaseConfiguration get config => DatabaseConfiguration.from(_config);

  @override
  late final SyncScope defaultScope = scope(Scope.defaultName)!;

  @override
  List<SyncScope> get scopes => useSync(() {
    final scopeNames = fl.MutableArray.fromPointer(
      _collectionBindings.databaseScopeNames(pointer),
      adopt: true,
    );
    return scopeNames.map((name) => scope(name.asString!)).nonNulls.toList();
  });

  @override
  SyncScope? scope(String name) => useSync(() {
    final scopePointer = _collectionBindings.databaseScope(pointer, name);

    if (scopePointer == null) {
      return null;
    }

    return FfiScope._(name: name, pointer: scopePointer, database: this);
  });

  @override
  late final SyncCollection defaultCollection = defaultScope.collection(
    Collection.defaultName,
  )!;

  @override
  SyncCollection? collection(String name, [String scope = Scope.defaultName]) =>
      this.scope(scope)?.collection(name);

  @override
  List<SyncCollection> collections([String scope = Scope.defaultName]) =>
      this.scope(scope)?.collections ?? [];

  @override
  SyncCollection createCollection(
    String name, [
    String scope = Scope.defaultName,
  ]) => useSync(() {
    final collectionPointer = _collectionBindings.databaseCreateCollection(
      pointer,
      name,
      scope,
    );
    return FfiCollection._(
      name: name,
      pointer: collectionPointer,
      scope: this.scope(scope)! as FfiScope,
    );
  });

  @override
  void deleteCollection(String name, [String scope = Scope.defaultName]) =>
      useSync(
        () =>
            _collectionBindings.databaseDeleteCollection(pointer, name, scope),
      );

  @override
  void beginTransaction() => _bindings.beginTransaction(pointer);

  @override
  void endTransaction({required bool commit}) =>
      _bindings.endTransaction(pointer, commit: commit);

  @override
  Document? document(String id) => defaultCollection.document(id);

  @override
  DocumentFragment operator [](String id) => defaultCollection[id];

  @override
  D? typedDocument<D extends TypedDocumentObject>(String id) =>
      super.typedDocument<D>(id) as D?;

  @override
  bool saveDocument(
    covariant MutableDelegateDocument document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]) => defaultCollection.saveDocument(document, concurrencyControl);

  @override
  FutureOr<bool> saveDocumentWithConflictHandler(
    covariant MutableDelegateDocument document,
    SaveConflictHandler conflictHandler,
  ) => defaultCollection.saveDocumentWithConflictHandler(
    document,
    conflictHandler,
  );

  @override
  bool saveDocumentWithConflictHandlerSync(
    covariant MutableDelegateDocument document,
    SyncSaveConflictHandler conflictHandler,
  ) => defaultCollection.saveDocumentWithConflictHandlerSync(
    document,
    conflictHandler,
  );

  @override
  SyncSaveTypedDocument<D, MD> saveTypedDocument<
    D extends TypedDocumentObject,
    MD extends TypedMutableDocumentObject
  >(TypedMutableDocumentObject<D, MD> document) =>
      _FfiSaveTypedDocument(this, () => defaultCollection, document);

  @override
  bool deleteDocument(
    covariant DelegateDocument document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]) => defaultCollection.deleteDocument(document, concurrencyControl);

  @override
  bool deleteTypedDocument(
    TypedDocumentObject document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]) {
    useWithTypedData();
    return deleteDocument(
      document.internal as DelegateDocument,
      concurrencyControl,
    );
  }

  @override
  void purgeDocument(covariant DelegateDocument document) =>
      defaultCollection.purgeDocument(document);

  @override
  void purgeTypedDocument(TypedDocumentObject document) {
    useWithTypedData();
    purgeDocument(document.internal as DelegateDocument);
  }

  @override
  void purgeDocumentById(String id) => defaultCollection.purgeDocumentById(id);

  @override
  Future<void> saveBlob(covariant BlobImpl blob) => use(
    () => blob.ensureIsInstalled(this, allowFromStreamForSyncDatabase: true),
  );

  @override
  Blob? getBlob(Map<String, Object?> properties) => useSync(() {
    checkBlobMetadata(properties);
    if (blobStore.blobExists(properties)) {
      return BlobImpl.fromProperties(properties, database: this);
    }
    return null;
  });

  @override
  Future<void> inBatch(FutureOr<void> Function() fn) =>
      use(() => runInTransactionAsync(fn, requiresNewTransaction: true));

  @override
  void inBatchSync(void Function() fn) =>
      useSync(() => runInTransactionSync(fn, requiresNewTransaction: true));

  @override
  void setDocumentExpiration(String id, DateTime? expiration) =>
      defaultCollection.setDocumentExpiration(id, expiration);

  @override
  DateTime? getDocumentExpiration(String id) =>
      defaultCollection.getDocumentExpiration(id);

  @override
  ListenerToken addChangeListener(DatabaseChangeListener listener) =>
      defaultCollection.addChangeListener(
        (change) => listener(change.toDatabaseChange()),
      );

  @override
  ListenerToken addDocumentChangeListener(
    String id,
    DocumentChangeListener listener,
  ) => defaultCollection.addDocumentChangeListener(id, listener);

  @override
  void removeChangeListener(ListenerToken token) =>
      defaultCollection.removeChangeListener(token);

  @override
  Stream<DatabaseChange> changes() =>
      defaultCollection.changes().map((change) => change.toDatabaseChange());

  @override
  Stream<DocumentChange> documentChanges(String id) =>
      defaultCollection.documentChanges(id);

  @override
  Future<void> performClose() async {
    if (_deleteOnClose) {
      _bindings.delete(pointer);
    } else {
      _bindings.close(pointer);
    }
  }

  @override
  Future<void> close() =>
      asyncOperationTracePoint(() => CloseDatabaseOp(this), super.close);

  @override
  Future<void> delete() => use(() {
    _deleteOnClose = true;
    return close();
  });

  @override
  void performMaintenance(MaintenanceType type) => useSync(() {
    _bindings.performMaintenance(pointer, type.toCBLMaintenanceType());
  });

  @override
  void changeEncryptionKey(EncryptionKey? newKey) => useSync(() {
    _bindings.changeEncryptionKey(
      pointer,
      (newKey as EncryptionKeyImpl?)?.cblKey,
    );
  });

  @override
  List<String> get indexes => defaultCollection.indexes;

  @override
  void createIndex(String name, covariant IndexImplInterface index) =>
      defaultCollection.createIndex(name, index);

  @override
  void deleteIndex(String name) => defaultCollection.deleteIndex(name);

  @override
  SyncQuery createQuery(String query, {bool json = false}) => FfiQuery(
    database: this,
    definition: query,
    language: json ? CBLQueryLanguage.json : CBLQueryLanguage.n1ql,
  )..prepare();

  @override
  String toString() => 'FfiDatabase($name)';
}

final _collectionBindings = CBLBindings.instance.collection;

final class FfiScope
    with ScopeBase, ClosableResourceMixin
    implements SyncScope, Finalizable {
  FfiScope._({
    required this.name,
    required this.pointer,
    required this.database,
  }) {
    CBLBindings.instance.base.bindCBLRefCountedToDartObject(
      this,
      pointer.cast(),
    );
    needsToBeClosedByParent = false;
    attachTo(database);
  }

  @override
  final FfiDatabase database;

  final Pointer<CBLScope> pointer;

  @override
  final String name;

  @override
  List<SyncCollection> get collections => useSync(() {
    final collectionNames = fl.MutableArray.fromPointer(
      _collectionBindings.scopeCollectionNames(pointer),
      adopt: true,
    );
    return collectionNames
        .map((name) => collection(name.asString!))
        .nonNulls
        .toList();
  });

  @override
  SyncCollection? collection(String name) => useSync(() {
    final collectionPointer = _collectionBindings.scopeCollection(
      pointer,
      name,
    );

    if (collectionPointer == null) {
      return null;
    }

    return FfiCollection._(name: name, pointer: collectionPointer, scope: this);
  });

  @override
  String toString() => 'FfiScope($name)';
}

final class FfiCollection
    with CollectionBase<FfiDocumentDelegate>, ClosableResourceMixin
    implements SyncCollection, Finalizable {
  FfiCollection._({
    required this.name,
    required this.pointer,
    required this.scope,
  }) {
    CBLBindings.instance.base.bindCBLRefCountedToDartObject(
      this,
      pointer.cast(),
    );
    needsToBeClosedByParent = false;
    attachTo(scope);
  }

  final Pointer<CBLCollection> pointer;

  late final _listenerTokens = ListenerTokenRegistry(this);

  @override
  final String name;

  @override
  final FfiScope scope;

  @override
  FfiDatabase get database => scope.database;

  @override
  int get count => useSync(() => _collectionBindings.count(pointer));

  @override
  Document? document(String id) => syncOperationTracePoint(
    () => GetDocumentOp(this, id),
    () => useSync(() {
      final documentPointer = _collectionBindings.getDocument(pointer, id);

      if (documentPointer == null) {
        return null;
      }

      return DelegateDocument(
        FfiDocumentDelegate.fromPointer(documentPointer, adopt: true),
        collection: this,
      );
    }),
  );

  @override
  DocumentFragment operator [](String id) => DocumentFragmentImpl(document(id));

  @override
  D? typedDocument<D extends TypedDocumentObject<Object>>(String id) =>
      super.typedDocument<D>(id) as D?;

  @override
  bool saveDocument(
    covariant MutableDelegateDocument document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]) => syncOperationTracePoint(
    () => SaveDocumentOp(this, document, concurrencyControl),
    () => useSync(
      () => database.runInTransactionSync(() {
        final delegate = syncOperationTracePoint(
          () => PrepareDocumentOp(document),
          () => prepareDocument(document) as FfiDocumentDelegate,
        );

        return _catchConflictException(() {
          _collectionBindings.saveDocumentWithConcurrencyControl(
            pointer,
            delegate.pointer.cast(),
            concurrencyControl.toCBLConcurrencyControl(),
          );
        });
      }),
    ),
  );

  @override
  FutureOr<bool> saveDocumentWithConflictHandler(
    covariant MutableDelegateDocument document,
    SaveConflictHandler conflictHandler,
  ) => asyncOperationTracePoint(
    () => SaveDocumentOp(this, document),
    () => use(
      () => saveDocumentWithConflictHandlerHelper(document, conflictHandler),
    ),
  );

  @override
  bool saveDocumentWithConflictHandlerSync(
    covariant MutableDelegateDocument document,
    SyncSaveConflictHandler conflictHandler,
  ) => syncOperationTracePoint(
    () => SaveDocumentOp(this, document),
    () => useSync(
      // Because the conflict handler is sync the result of the possibly
      // async method is always sync.
      () =>
          saveDocumentWithConflictHandlerHelper(document, conflictHandler)
              as bool,
    ),
  );

  @override
  SyncSaveTypedDocument<D, MD> saveTypedDocument<
    D extends TypedDocumentObject<Object>,
    MD extends TypedMutableDocumentObject
  >(TypedMutableDocumentObject<D, MD> document) =>
      _FfiSaveTypedDocument(database, () => this, document);

  @override
  bool deleteDocument(
    covariant DelegateDocument document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]) => syncOperationTracePoint(
    () => DeleteDocumentOp(this, document, concurrencyControl),
    () => useSync(
      () => database.runInTransactionSync(() {
        final delegate = syncOperationTracePoint(
          () => PrepareDocumentOp(document),
          () =>
              prepareDocument(document, updateEncodedProperties: false)
                  as FfiDocumentDelegate,
        );

        return _catchConflictException(() {
          _collectionBindings.deleteDocumentWithConcurrencyControl(
            pointer,
            delegate.pointer.cast(),
            concurrencyControl.toCBLConcurrencyControl(),
          );
        });
      }),
    ),
  );

  @override
  Future<bool> deleteTypedDocument(
    TypedDocumentObject<Object> document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]) async {
    database.useWithTypedData();
    return deleteDocument(
      document.internal as DelegateDocument,
      concurrencyControl,
    );
  }

  @override
  void purgeDocument(covariant DelegateDocument document) => useSync(() {
    document.setCollection(this);
    purgeDocumentById(document.id);
  });

  @override
  void purgeTypedDocument(TypedDocumentObject document) {
    database.useWithTypedData();
    purgeDocument(document.internal as DelegateDocument);
  }

  @override
  void purgeDocumentById(String id) => useSync(
    () => database.runInTransactionSync(() {
      _collectionBindings.purgeDocumentByID(pointer, id);
    }),
  );

  @override
  void setDocumentExpiration(String id, DateTime? expiration) => useSync(() {
    _collectionBindings.setDocumentExpiration(pointer, id, expiration);
  });

  @override
  DateTime? getDocumentExpiration(String id) =>
      useSync(() => _collectionBindings.getDocumentExpiration(pointer, id));

  @override
  List<String> get indexes => useSync(
    () => fl.Array.fromPointer(
      _collectionBindings.indexNames(pointer),
      adopt: true,
    ).toObject().cast<String>(),
  );

  @override
  QueryIndex? index(String name) => useSync(
    () => _collectionBindings
        .index(pointer, name)
        ?.let(
          (pointer) =>
              FfiQueryIndex.fromPointer(pointer, collection: this, name: name),
        ),
  );

  @override
  void createIndex(String name, covariant IndexImplInterface index) {
    if (index is VectorIndexConfiguration) {
      useEnterpriseFeature(EnterpriseFeature.vectorIndex);
    }

    useSync(() {
      _collectionBindings.createIndex(pointer, name, index.toCBLIndexSpec());
    });
  }

  @override
  void deleteIndex(String name) =>
      useSync(() => _collectionBindings.deleteIndex(pointer, name));

  @override
  ListenerToken addChangeListener(CollectionChangeListener listener) =>
      useSync(() => _addChangeListener(listener).also(_listenerTokens.add));

  AbstractListenerToken _addChangeListener(CollectionChangeListener listener) {
    final callback = AsyncCallback((arguments) {
      final message = CollectionChangeCallbackMessage.fromArguments(arguments);
      final change = CollectionChange(this, message.documentIds);
      listener(change);
      return null;
    }, debugName: 'FfiCollection.addChangeListener');

    _collectionBindings.addChangeListener(
      database.pointer,
      pointer,
      callback.pointer,
    );

    return FfiListenerToken(callback);
  }

  @override
  ListenerToken addDocumentChangeListener(
    String id,
    DocumentChangeListener listener,
  ) => useSync(
    () => _addDocumentChangeListener(id, listener).also(_listenerTokens.add),
  );

  AbstractListenerToken _addDocumentChangeListener(
    String id,
    DocumentChangeListener listener,
  ) {
    final callback = AsyncCallback((_) {
      final change = DocumentChange(database, this, id);
      listener(change);
      return null;
    }, debugName: 'FfiCollection.addDocumentChangeListener');

    _collectionBindings.addDocumentChangeListener(
      database.pointer,
      pointer,
      id,
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
  Stream<CollectionChange> changes() => useSync(
    () => ListenerStream(parent: this, addListener: _addChangeListener),
  );

  @override
  Stream<DocumentChange> documentChanges(String id) => useSync(
    () => ListenerStream(
      parent: this,
      addListener: (listener) => _addDocumentChangeListener(id, listener),
    ),
  );

  @override
  String toString() => 'FfiCollection($fullName)';

  @override
  FfiDocumentDelegate createNewDocumentDelegate(DocumentDelegate oldDelegate) =>
      FfiDocumentDelegate.create(oldDelegate.id);
}

extension on MaintenanceType {
  CBLMaintenanceType toCBLMaintenanceType() => CBLMaintenanceType.values[index];
}

extension on ConcurrencyControl {
  CBLConcurrencyControl toCBLConcurrencyControl() =>
      CBLConcurrencyControl.values[index];
}

extension on DatabaseConfiguration {
  CBLDatabaseConfiguration toCBLDatabaseConfiguration() =>
      CBLDatabaseConfiguration(
        directory: directory,
        encryptionKey: (encryptionKey as EncryptionKeyImpl?)?.cblKey,
        fullSync: fullSync,
      );
}

bool _catchConflictException(void Function() fn) {
  try {
    fn();
    return true;
  } on DatabaseException catch (e) {
    if (e.code == DatabaseErrorCode.conflict) {
      return false;
    }
    rethrow;
  }
}

final class _FfiSaveTypedDocument<
  D extends TypedDocumentObject,
  MD extends TypedMutableDocumentObject
>
    extends SaveTypedDocumentBase<D, MD>
    implements SyncSaveTypedDocument<D, MD> {
  _FfiSaveTypedDocument(
    FfiDatabase super.database,
    super.collection,
    super.document,
  );

  @override
  bool withConcurrencyControl([
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]) => super.withConcurrencyControl(concurrencyControl) as bool;

  @override
  bool withConflictHandlerSync(
    TypedSyncSaveConflictHandler<D, MD> conflictHandler,
  ) => withConflictHandler(conflictHandler) as bool;
}
