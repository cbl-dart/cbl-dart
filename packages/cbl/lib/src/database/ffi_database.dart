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
import '../support/ffi.dart';
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
  FfiDatabase({
    required String name,
    DatabaseConfiguration? config,
    required String debugCreator,
  })  : _config = DatabaseConfiguration.from(
          config ?? DatabaseConfiguration(),
        ),
        super(
          runNativeCalls(
              () => _bindings.open(name, config?.toCBLDatabaseConfiguration())),
          debugName: 'FfiDatabase($name, creator: $debugCreator)',
        ) {
    this.name = call(_bindings.name);
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
  Stream<DatabaseChange> changes() =>
      useSync(() => CallbackStreamController<DatabaseChange, void>(
            parent: this,
            startStream: (callback) => _bindings.addChangeListener(
              native.pointer,
              callback.native.pointer,
            ),
            createEvent: (_, arguments) {
              final message =
                  DatabaseChangeCallbackMessage.fromArguments(arguments);
              return DatabaseChange(this, message.documentIds);
            },
          ).stream);

  @override
  Stream<DocumentChange> documentChanges(String id) =>
      useSync(() => CallbackStreamController<DocumentChange, void>(
            parent: this,
            startStream: (callback) => _bindings.addDocumentChangeListener(
              native.pointer,
              id,
              callback.native.pointer,
            ),
            createEvent: (_, __) => DocumentChange(this, id),
          ).stream);

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
      CBLDatabaseConfiguration(directory: directory);
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
