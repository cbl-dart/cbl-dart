import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../document/blob.dart';
import '../document/document.dart';
import '../document/ffi_document.dart';
import '../document/fragment.dart';
import '../errors.dart';
import '../fleece/containers.dart' as fl;
import '../fleece/decoder.dart';
import '../fleece/dict_key.dart';
import '../query/index/index.dart';
import '../support/async_callback.dart';
import '../support/errors.dart';
import '../support/ffi.dart';
import '../support/listener_token.dart';
import '../support/native_object.dart';
import '../support/resource.dart';
import '../support/streams.dart';
import '../support/tracing.dart';
import '../support/utils.dart';
import '../tracing.dart';
import '../typed_data.dart';
import '../typed_data/adapter.dart';
import 'blob_store.dart';
import 'database.dart';
import 'database_base.dart';
import 'database_change.dart';
import 'database_configuration.dart';
import 'document_change.dart';
import 'ffi_blob_store.dart';

final _bindings = cblBindings.database;

class FfiDatabase
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
      pointer: runWithErrorTranslation(
        () => _bindings.open(name, config!.toCBLDatabaseConfiguration()),
      ),
      typedDataAdapter: typedDataAdapter,
    );
  }

  FfiDatabase._({
    required DatabaseConfiguration config,
    required this.pointer,
    required this.typedDataAdapter,
  }) : _config = config {
    bindCBLDatabaseToDartObject(this, pointer: pointer);
    name = _bindings.name(pointer);
    _path = _bindings.path(pointer);
  }

  /// {@macro cbl.Database.removeSync}
  static void remove(String name, {String? directory}) =>
      runWithErrorTranslation(() => _bindings.deleteDatabase(name, directory));

  /// {@macro cbl.Database.existsSync}
  static bool exists(String name, {String? directory}) =>
      runWithErrorTranslation(() => _bindings.databaseExists(name, directory));

  /// {@macro cbl.Database.copySync}
  static void copy({
    required String from,
    required String name,
    DatabaseConfiguration? config,
  }) =>
      runWithErrorTranslation(
        () => _bindings.copyDatabase(
          from,
          name,
          config?.toCBLDatabaseConfiguration(),
        ),
      );

  final Pointer<CBLDatabase> pointer;

  @override
  final TypedDataAdapter? typedDataAdapter;

  @override
  final dictKeys = OptimizingDictKeys();

  @override
  final sharedKeysTable = SharedKeysTable();

  @override
  late final SyncBlobStore blobStore = FfiBlobStore(this);

  late final _listenerTokens = ListenerTokenRegistry(this);

  final DatabaseConfiguration _config;

  var _deleteOnClose = false;

  @override
  late final String name;

  @override
  String? get path => _path;
  String? _path;

  @override
  int get count => useSync(() => _bindings.count(pointer));

  @override
  DatabaseConfiguration get config => DatabaseConfiguration.from(_config);

  @override
  void beginTransaction() {
    runWithErrorTranslation(() => _bindings.beginTransaction(pointer));
  }

  @override
  void endTransaction({required bool commit}) {
    runWithErrorTranslation(
      () => _bindings.endTransaction(pointer, commit: commit),
    );
  }

  @override
  Document? document(String id) => syncOperationTracePoint(
        () => GetDocumentOp(this, id),
        () => useSync(
          () {
            final documentPointer = runWithErrorTranslation(
              () => _bindings.getDocument(pointer, id),
            );

            if (documentPointer == null) {
              return null;
            }

            return DelegateDocument(
              FfiDocumentDelegate.fromPointer(
                documentPointer,
                adopt: true,
              ),
              database: this,
            );
          },
        ),
      );

  @override
  DocumentFragment operator [](String id) => DocumentFragmentImpl(document(id));

  @override
  D? typedDocument<D extends TypedDocumentObject>(String id) =>
      super.typedDocument<D>(id) as D?;

  @override
  bool saveDocument(
    covariant MutableDelegateDocument document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]) =>
      syncOperationTracePoint(
        () => SaveDocumentOp(this, document, concurrencyControl),
        () => useSync(
          () => runInTransactionSync(() {
            final delegate = syncOperationTracePoint(
              () => PrepareDocumentOp(document),
              () => prepareDocument(document) as FfiDocumentDelegate,
            );

            return _catchConflictException(() {
              runWithErrorTranslation(
                () => _bindings.saveDocumentWithConcurrencyControl(
                  pointer,
                  delegate.pointer.cast(),
                  concurrencyControl.toCBLConcurrencyControl(),
                ),
              );
            });
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
  bool saveDocumentWithConflictHandlerSync(
    covariant MutableDelegateDocument document,
    SyncSaveConflictHandler conflictHandler,
  ) =>
      syncOperationTracePoint(
        () => SaveDocumentOp(this, document),
        () => useSync(
            // Because the conflict handler is sync the result of the possibly
            // async method is always sync.
            () => saveDocumentWithConflictHandlerHelper(
                  document,
                  conflictHandler,
                ) as bool),
      );

  @override
  SyncSaveTypedDocument<D, MD> saveTypedDocument<D extends TypedDocumentObject,
          MD extends TypedMutableDocumentObject>(
    TypedMutableDocumentObject<D, MD> document,
  ) =>
      _FfiSaveTypedDocument(this, document);

  @override
  bool deleteDocument(
    covariant DelegateDocument document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]) =>
      syncOperationTracePoint(
        () => DeleteDocumentOp(this, document, concurrencyControl),
        () => useSync(
          () => runInTransactionSync(() {
            final delegate = syncOperationTracePoint(
              () => PrepareDocumentOp(document),
              () => prepareDocument(document, syncProperties: false)
                  as FfiDocumentDelegate,
            );

            return _catchConflictException(() {
              runWithErrorTranslation(
                () => _bindings.deleteDocumentWithConcurrencyControl(
                  pointer,
                  delegate.pointer.cast(),
                  concurrencyControl.toCBLConcurrencyControl(),
                ),
              );
            });
          }),
        ),
      );

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
  void purgeDocument(covariant DelegateDocument document) => useSync(() {
        document.database = this;
        purgeDocumentById(document.id);
      });

  @override
  void purgeTypedDocument(TypedDocumentObject document) {
    useWithTypedData();
    purgeDocument(document.internal as DelegateDocument);
  }

  @override
  void purgeDocumentById(String id) => useSync(
        () => runInTransactionSync(() {
          runWithErrorTranslation(
            () => _bindings.purgeDocumentByID(pointer, id),
          );
        }),
      );

  @override
  Future<void> saveBlob(covariant BlobImpl blob) =>
      use(() => blob.ensureIsInstalled(
            this,
            allowFromStreamForSyncDatabase: true,
          ));

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
  void setDocumentExpiration(String id, DateTime? expiration) => useSync(() {
        runWithErrorTranslation(
          () => _bindings.setDocumentExpiration(pointer, id, expiration),
        );
      });

  @override
  DateTime? getDocumentExpiration(String id) => useSync(
        () => runWithErrorTranslation(
          () => _bindings.getDocumentExpiration(pointer, id),
        ),
      );

  @override
  ListenerToken addChangeListener(DatabaseChangeListener listener) =>
      useSync(() => _addChangeListener(listener).also(_listenerTokens.add));

  AbstractListenerToken _addChangeListener(DatabaseChangeListener listener) {
    final callback = AsyncCallback(
      (arguments) {
        final message = DatabaseChangeCallbackMessage.fromArguments(arguments);
        final change = DatabaseChange(this, message.documentIds);
        listener(change);
        return null;
      },
      debugName: 'FfiDatabase.addChangeListener',
    );

    runWithErrorTranslation(
      () => _bindings.addChangeListener(pointer, callback.pointer),
    );

    return FfiListenerToken(callback);
  }

  @override
  ListenerToken addDocumentChangeListener(
    String id,
    DocumentChangeListener listener,
  ) =>
      useSync(() =>
          _addDocumentChangeListener(id, listener).also(_listenerTokens.add));

  AbstractListenerToken _addDocumentChangeListener(
    String id,
    DocumentChangeListener listener,
  ) {
    final callback = AsyncCallback(
      (_) {
        final change = DocumentChange(this, id);
        listener(change);
        return null;
      },
      debugName: 'FfiDatabase.addDocumentChangeListener',
    );

    runWithErrorTranslation(
      () => _bindings.addDocumentChangeListener(
        pointer,
        id,
        callback.pointer,
      ),
    );

    return FfiListenerToken(callback);
  }

  @override
  void removeChangeListener(ListenerToken token) => useSync(() {
        final result = _listenerTokens.remove(token);
        assert(result is! Future);
      });

  @override
  Stream<DatabaseChange> changes() => useSync(() => ListenerStream(
        parent: this,
        addListener: _addChangeListener,
      ));

  @override
  Stream<DocumentChange> documentChanges(String id) =>
      useSync(() => ListenerStream(
            parent: this,
            addListener: (listener) => _addDocumentChangeListener(id, listener),
          ));

  @override
  Future<void> performClose() async {
    runWithErrorTranslation(() {
      if (_deleteOnClose) {
        _bindings.delete(pointer);
      } else {
        _bindings.close(pointer);
      }
    });
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
        runWithErrorTranslation(
          () => _bindings.performMaintenance(
            pointer,
            type.toCBLMaintenanceType(),
          ),
        );
      });

  @override
  void changeEncryptionKey(EncryptionKey? newKey) => useSync(() {
        runWithErrorTranslation(
          () => _bindings.changeEncryptionKey(
            pointer,
            (newKey as EncryptionKeyImpl?)?.cblKey,
          ),
        );
      });

  @override
  List<String> get indexes => useSync(() =>
      fl.Array.fromPointer(_bindings.indexNames(pointer), adopt: true)
          .toObject()
          .cast<String>());

  @override
  void createIndex(String name, covariant IndexImplInterface index) =>
      useSync(() {
        runWithErrorTranslation(
          () => _bindings.createIndex(pointer, name, index.toCBLIndexSpec()),
        );
      });

  @override
  void deleteIndex(String name) => useSync(() {
        runWithErrorTranslation(() => _bindings.deleteIndex(pointer, name));
      });

  @override
  String toString() => 'FfiDatabase($name)';

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

class _FfiSaveTypedDocument<D extends TypedDocumentObject,
        MD extends TypedMutableDocumentObject>
    extends SaveTypedDocumentBase<D, MD>
    implements SyncSaveTypedDocument<D, MD> {
  _FfiSaveTypedDocument(FfiDatabase super.database, super.document);

  @override
  bool withConcurrencyControl([
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]) =>
      super.withConcurrencyControl(concurrencyControl) as bool;

  @override
  bool withConflictHandlerSync(
    TypedSyncSaveConflictHandler<D, MD> conflictHandler,
  ) =>
      withConflictHandler(conflictHandler) as bool;
}
