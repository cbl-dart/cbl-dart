import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../document/document.dart';
import '../document/ffi_document.dart';
import '../document/fragment.dart';
import '../errors.dart';
import '../fleece/fleece.dart' as fl;
import '../query/index/index.dart';
import '../support/async_callback.dart';
import '../support/ffi.dart';
import '../support/listener_token.dart';
import '../support/native_object.dart';
import '../support/resource.dart';
import '../support/streams.dart';
import '../support/utils.dart';
import 'blob_store.dart';
import 'database.dart';
import 'database_change.dart';
import 'database_configuration.dart';
import 'database_helper.dart';
import 'document_change.dart';
import 'ffi_blob_store.dart';

late final _bindings = cblBindings.database;

class FfiDatabase extends CBLDatabaseObject
    with DatabaseHelper<FfiDocumentDelegate>, ClosableResourceMixin
    implements SyncDatabase, BlobStoreHolder {
  factory FfiDatabase({
    required String name,
    DatabaseConfiguration? config,
    required String debugCreator,
  }) {
    config ??= DatabaseConfiguration();

    // Ensure the directory exists, in which to create the database,
    Directory(config.directory).createSync(recursive: true);

    final pointer = runNativeCalls(() => _bindings.open(
          name,
          config!.toCBLDatabaseConfiguration(),
        ));

    return FfiDatabase._(
      // Make a copy of the configuration, since its mutable.
      config: DatabaseConfiguration.from(config),
      pointer: pointer,
      debugName: 'FfiDatabase($name, creator: $debugCreator)',
    );
  }

  FfiDatabase._({
    required DatabaseConfiguration config,
    required Pointer<CBLDatabase> pointer,
    required String debugName,
  })  : _config = config,
        super(pointer, debugName: debugName) {
    name = call(_bindings.name);
    _path = call(_bindings.path);
  }

  /// {@macro cbl.Database.removeSync}
  static void remove(String name, {String? directory}) => runNativeCalls(() {
        _bindings.deleteDatabase(name, directory);
      });

  /// {@macro cbl.Database.existsSync}
  static bool exists(String name, {String? directory}) =>
      runNativeCalls(() => _bindings.databaseExists(name, directory));

  /// {@macro cbl.Database.copySync}
  static void copy({
    required String from,
    required String name,
    DatabaseConfiguration? config,
  }) =>
      runNativeCalls(() {
        _bindings.copyDatabase(
          from,
          name,
          config?.toCBLDatabaseConfiguration(),
        );
      });

  @override
  late final blobStore = FfiBlobStore(this);

  late final _listenerTokens = ListenerTokenRegistry(this);

  final DatabaseConfiguration _config;

  var _deleteOnClose = false;

  @override
  late final String name;

  @override
  String? get path => _path;
  String? _path;

  @override
  int get count => useSync(() => call(_bindings.count));

  @override
  DatabaseConfiguration get config => DatabaseConfiguration.from(_config);

  @override
  Document? document(String id) =>
      useSync(() => call((pointer) => _bindings.getDocument(pointer, id))
          ?.let((pointer) => DelegateDocument(
                FfiDocumentDelegate.fromPointer(
                  doc: pointer,
                  debugCreator: 'FfiDatabase.document()',
                ),
                database: this,
              )));

  @override
  DocumentFragment operator [](String id) => DocumentFragmentImpl(document(id));

  @override
  bool saveDocument(
    covariant MutableDelegateDocument document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]) =>
      useSync(() {
        final delegate = prepareDocument(document) as FfiDocumentDelegate;

        return _catchConflictException(() {
          runNativeCalls(() {
            _bindings.saveDocumentWithConcurrencyControl(
              native.pointer,
              delegate.native.pointer.cast(),
              concurrencyControl.toCBLConcurrencyControl(),
            );
          });
        });
      });

  @override
  Future<bool> saveDocumentWithConflictHandler(
    covariant MutableDelegateDocument document,
    SaveConflictHandler conflictHandler,
  ) =>
      use(() => saveDocumentWithConflictHandlerHelper(
            document,
            conflictHandler,
          ));

  @override
  bool saveDocumentWithConflictHandlerSync(
    covariant MutableDelegateDocument document,
    SyncSaveConflictHandler conflictHandler,
  ) =>
      useSync(
          // Because the conflict handler is sync the result of the maybe async
          // method is always sync.
          () => saveDocumentWithConflictHandlerHelper(
                document,
                conflictHandler,
              ) as bool);

  @override
  bool deleteDocument(
    covariant DelegateDocument document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]) =>
      useSync(() {
        final delegate = prepareDocument(document, syncProperties: false)
            as FfiDocumentDelegate;

        return _catchConflictException(() {
          runNativeCalls(() {
            _bindings.deleteDocumentWithConcurrencyControl(
              native.pointer,
              delegate.native.pointer.cast(),
              concurrencyControl.toCBLConcurrencyControl(),
            );
          });
        });
      });

  @override
  void purgeDocument(covariant DelegateDocument document) => useSync(() {
        document.database = this;
        purgeDocumentById(document.id);
      });

  @override
  void purgeDocumentById(String id) => useSync(() {
        call((pointer) => _bindings.purgeDocumentByID(pointer, id));
      });

  @override
  Future<void> inBatch(FutureOr<void> Function() fn) => use(() => _inBatch(fn));

  @override
  void inBatchSync(void Function() fn) => useSync(() {
        // Since fn is sync the result must also be sync.
        final result = _inBatch(fn);
        assert(result is! Future<void>);
      });

  FutureOr<void> _inBatch(FutureOr<void> Function() fn) {
    beginTransaction();
    return finallySyncOrAsync(
      (didThrow) => endTransaction(commit: !didThrow),
      fn,
    );
  }

  void beginTransaction() => call(_bindings.beginTransaction);

  void endTransaction({required bool commit}) =>
      call((pointer) => _bindings.endTransaction(pointer, commit: commit));

  @override
  void setDocumentExpiration(String id, DateTime? expiration) => useSync(() {
        call((pointer) =>
            _bindings.setDocumentExpiration(pointer, id, expiration));
      });

  @override
  DateTime? getDocumentExpiration(String id) => useSync(
      () => call((pointer) => _bindings.getDocumentExpiration(pointer, id)));

  @override
  ListenerToken addChangeListener(DatabaseChangeListener listener) =>
      useSync(() => _addChangeListener(listener).also(_listenerTokens.add));

  AbstractListenerToken _addChangeListener(DatabaseChangeListener listener) {
    final callback = AsyncCallback(
      (arguments) {
        final message = DatabaseChangeCallbackMessage.fromArguments(arguments);
        final change = DatabaseChange(this, message.documentIds);
        listener(change);
      },
      debugName: 'FfiDatabase.addChangeListener',
    );

    runNativeCalls(() => _bindings.addChangeListener(
          native.pointer,
          callback.native.pointer,
        ));

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
      },
      debugName: 'FfiDatabase.addDocumentChangeListener',
    );

    runNativeCalls(() => _bindings.addDocumentChangeListener(
          native.pointer,
          id,
          callback.native.pointer,
        ));

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
    if (_deleteOnClose) {
      call(_bindings.delete);
    } else {
      call(_bindings.close);
    }
  }

  @override
  Future<void> delete() => use(() {
        _deleteOnClose = true;
        return close();
      });

  @override
  void performMaintenance(MaintenanceType type) => useSync(() {
        call((pointer) =>
            _bindings.performMaintenance(pointer, type.toCBLMaintenanceType()));
      });

  @override
  void changeEncryptionKey(EncryptionKey? newKey) => useSync(() {
        call((pointer) => _bindings.changeEncryptionKey(
              pointer,
              (newKey as EncryptionKeyImpl?)?.cblKey,
            ));
      });

  @override
  List<String> get indexes => useSync(() => fl.Array.fromPointer(
        native.call(_bindings.indexNames),
        adopt: true,
      ).toObject().cast<String>());

  @override
  void createIndex(String name, covariant IndexImplInterface index) =>
      useSync(() => native.call((pointer) {
            _bindings.createIndex(pointer, name, index.toCBLIndexSpec());
          }));

  @override
  void deleteIndex(String name) => useSync(() {
        call((pointer) => _bindings.deleteIndex(pointer, name));
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
