import 'dart:async';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../document/document.dart';
import '../document/fragment.dart';
import '../errors.dart';
import '../fleece/fleece.dart' as fl;
import '../log.dart';
import '../log/log.dart';
import '../query/index/index.dart';
import '../replication.dart';
import '../support/ffi.dart';
import '../support/native_object.dart';
import '../support/resource.dart';
import '../support/streams.dart';
import '../support/utils.dart';
import 'blob_store.dart';
import 'database_change.dart';
import 'database_configuration.dart';
import 'document_change.dart';

/// Conflict-handling options when saving or deleting a document.
enum ConcurrencyControl {
  /// The current save/delete will overwrite a conflicting revision if there is
  /// a conflict.
  lastWriteWins,

  /// The current save/delete will fail if there is a conflict.
  failOnConflict,
}

/// The type of maintenance a database can perform.
enum MaintenanceType {
  /// Compact the database file and delete unused attachments.
  compact,

  /// Rebuild the database's indexes.
  reindex,

  /// Check for database corruption.
  integrityCheck,
}

/// Custom conflict handler for saving or deleting a document.
///
/// {@template cbl.SaveConflictHandler}
/// This handler is called if the save would cause a conflict, i.e. if the
/// document in the database has been updated (probably by a pull replicator, or
/// by application code) since it was loaded into the [Document] being saved.
///
/// The [documentBeingSaved] (same as the parameter you passed to
/// [Database.saveDocumentWithConflictHandler].) may be modify by the callback
/// as necessary to resolve the conflict.
///
/// The handler receives the revision of the [conflictingDocument] currently in
/// the database, which has been changed since [documentBeingSaved] was loaded.
/// It can be be `null`, meaning that the document has been deleted.
///
/// The handler has to make a decision by returning `true` to save the document
/// or `false` to abort the save.
///
/// If the handler throws the save will be aborted.
/// {@endtemplate}
///
/// See also:
///
///  * [Database.saveDocumentWithConflictHandler] for saving a [Document] with
///    a custom async conflict handler.
typedef SaveConflictHandler = FutureOr<bool> Function(
  MutableDocument documentBeingSaved,
  Document? conflictingDocument,
);

/// A Couchbase Lite database.
abstract class Database implements ClosableResource {
  /// Configuration of the [ConsoleLogger], [FileLogger] and a custom [Logger].
  static final Log log = LogImpl();

  /// The name of this database.
  String get name;

  /// The path to this database.
  ///
  /// Is `null` if the database is closed or deleted.
  String? get path;

  /// The total number of documents in the database.
  FutureOr<int> get count;

  /// The configuration which was used to open this database.
  DatabaseConfiguration get config;

  /// Returns the [Document] with the given [id], if it exists.
  FutureOr<Document?> document(String id);

  /// Returns the [DocumentFragment] for the [Document] with the given [id].
  FutureOr<DocumentFragment> operator [](String id);

  /// Saves a [document] to this database, resolving conflicts through
  /// [ConcurrencyControl].
  ///
  /// When write operations are executed concurrently, the last writer will win
  /// by default. In this case the result is always `true`.
  ///
  /// To fail on conflict instead, pass [ConcurrencyControl.failOnConflict] to
  /// [concurrencyControl]. In this case, if the document could not be saved
  /// the result is `false`. On success it is `true`.
  FutureOr<bool> saveDocument(
    MutableDocument document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  /// Saves a [document] to this database, resolving conflicts with a
  /// [conflictHandler].
  ///
  /// {@template cbl.Database.saveDocumentWithConflictHandler}
  /// When write operations are executed concurrently and if conflicts occur,
  /// the [conflictHandler] will be called. Use the conflict handler to
  /// directly edit the [Document] to resolve the conflict. When the conflict
  /// handler returns `true`, the save method will save the edited document as
  /// the resolved document. If the conflict handler returns `false`, the save
  /// operation will be canceled with `false` as the result. If the conflict
  /// handler returns `true` or there is no conflict the result is `true`.
  /// {@endtemplate}
  FutureOr<bool> saveDocumentWithConflictHandler(
    MutableDocument document,
    SaveConflictHandler conflictHandler,
  );

  /// Deletes a [document] from this database, resolving conflicts through
  /// [ConcurrencyControl].
  ///
  /// When write operations are executed concurrently, the last writer will win
  /// by default. In this case the result is always `true`.
  ///
  /// To fail on conflict instead, pass [ConcurrencyControl.failOnConflict] to
  /// [concurrencyControl]. In this case, if the document could not be deleted
  /// the result is `false`. On success it is `true`.
  FutureOr<bool> deleteDocument(
    Document document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  /// Purges a [document] from this database.
  ///
  /// This is more drastic than deletion: It removes all traces of the document.
  /// The purge will __not__ be replicated to other databases.
  FutureOr<void> purgeDocument(Document document);

  /// Purges a [Document] from this database by its [id].
  ///
  /// This is more drastic than deletion: It removes all traces of the document.
  /// The purge will __not__ be replicated to other databases.
  FutureOr<void> purgeDocumentById(String id);

  /// Runs a group of database operations in a batch.
  ///
  /// {@template cbl.Database.inBatch}
  /// Use this when performance bulk write operations like multiple
  /// inserts/updates; it saves the overhead of multiple database commits,
  /// greatly improving performance.
  /// {@endtemplate}
  FutureOr<void> inBatch(FutureOr<void> Function() fn);

  /// Sets an [expiration] date for a [Document] by its [id].
  ///
  /// After the given date the document will be purged from the database
  ///
  /// This is more drastic than deletion: It removes all traces of the document.
  /// The purge will __not__ be replicated to other databases.
  FutureOr<void> setDocumentExpiration(String id, DateTime? expiration);

  /// Gets the expiration date of a [Document] by its [id], if it exists.
  FutureOr<DateTime?> getDocumentExpiration(String id);

  /// Returns a [Stream] that emits [DatabaseChange] events when [Document]s
  /// are inserted, updated or deleted in this database.
  Stream<DatabaseChange> changes();

  /// Returns a [Stream] that emits [DocumentChange] events when a specific
  /// [Document] is inserted, updated or deleted in this database.
  Stream<DocumentChange> documentChanges(String id);

  /// Closes this database.
  ///
  /// Before closing this database, [Replicator]s and change streams are closed.
  @override
  Future<void> close();

  /// Closes and deletes this database.
  ///
  /// Before closing this database, [Replicator]s and change streams are closed.
  Future<void> delete();

  /// Performs database maintenance.
  FutureOr<void> performMaintenance(MaintenanceType type);

  /// The names of all existing indexes.
  FutureOr<List<String>> get indexes;

  /// Creates a value or full-text search [index] with the given [name].
  ///
  /// The name can be used for deleting the index. Creating a new different
  /// index with an existing index name will replace the old index; creating the
  /// same index with the same name is a no-op.
  FutureOr<void> createIndex(String name, Index index);

  /// Deletes the [Index] of the given [name].
  FutureOr<void> deleteIndex(String name);
}

/// Custom sync conflict handler for saving or deleting a document.
///
/// {@macro cbl.SaveConflictHandler}
///
/// See also:
///
///  * [SyncDatabase.saveDocumentWithConflictHandlerSync] for saving a
///    [Document] with a custom sync conflict handler.
typedef SyncSaveConflictHandler = bool Function(
  MutableDocument documentBeingSaved,
  Document? conflictingDocument,
);

/// A [Database] with a primarily synchronous API.
abstract class SyncDatabase implements Database {
  /// Opens a Couchbase Lite database with a given name and [configuration].
  ///
  /// If the database does not yet exist, it will be created.
  factory SyncDatabase(String name, [DatabaseConfiguration? configuration]) =>
      FfiDatabase(
        name: name,
        configuration: configuration,
        debugCreator: 'SyncDatabase()',
      );

  /// Deletes a database of the given [name] in the given [directory].
  static void remove(String name, {String? directory}) => runNativeCalls(() {
        _bindings.deleteDatabase(name, directory);
      });

  /// Checks whether a database of the given [name] exists in the given
  /// [directory] or not.
  static bool exists(String name, {String? directory}) => runNativeCalls(() {
        return _bindings.databaseExists(name, directory);
      });

  /// Copies a canned database [from] the given path to a new database with the
  /// given [name] and [configuration].
  ///
  /// The new database will be created at the directory specified in the
  /// [configuration].
  static void copy({
    required String from,
    required String name,
    DatabaseConfiguration? configuration,
  }) =>
      runNativeCalls(() {
        _bindings.copyDatabase(
          from,
          name,
          configuration?.toCBLDatabaseConfiguration(),
        );
      });

  @override
  int get count;

  @override
  Document? document(String id);

  @override
  DocumentFragment operator [](String id);

  @override
  bool saveDocument(
    MutableDocument document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  /// Saves a [document] to this database, resolving conflicts with an sync
  /// [conflictHandler].
  ///
  /// {@macro cbl.Database.saveDocumentWithConflictHandler}
  bool saveDocumentWithConflictHandlerSync(
    MutableDocument document,
    SyncSaveConflictHandler conflictHandler,
  );

  @override
  bool deleteDocument(
    Document document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  @override
  void purgeDocument(Document document);

  @override
  void purgeDocumentById(String id);

  /// Runs a group of database operations in a batch, synchronously.
  ///
  /// {@macro cbl.Database.inBatch}
  void inBatchSync(void Function() fn);

  @override
  void setDocumentExpiration(String id, DateTime? expiration);

  @override
  DateTime? getDocumentExpiration(String id);

  @override
  void performMaintenance(MaintenanceType type);

  @override
  List<String> get indexes;

  @override
  void createIndex(String name, Index index);

  @override
  void deleteIndex(String name);
}

/// A [Database] with a primarily asynchronous API.

abstract class AsyncDatabase implements Database {
  /// Opens a Couchbase Lite database with a given name and [configuration].
  ///
  /// If the database does not yet exist, it will be created.
  static Future<AsyncDatabase> open(
    String name, [
    DatabaseConfiguration? configuration,
  ]) =>
      throw UnimplementedError();

  /// Deletes a database of the given [name] in the given [directory].
  static Future<void> remove(String name, {String? directory}) =>
      throw UnimplementedError();

  /// Checks whether a database of the given [name] exists in the given
  /// [directory] or not.
  static Future<bool> exists(String name, {String? directory}) =>
      throw UnimplementedError();

  /// Copies a canned database [from] the given path to a new database with the
  /// given [name] and [configuration].
  ///
  /// The new database will be created at the directory specified in the
  /// [configuration].
  static Future<void> copy({
    required String from,
    required String name,
    DatabaseConfiguration? configuration,
  }) =>
      throw UnimplementedError();

  @override
  Future<int> get count;

  @override
  Future<Document?> document(String id);

  @override
  Future<DocumentFragment> operator [](String id);

  @override
  Future<bool> saveDocument(
    MutableDocument document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  @override
  Future<bool> saveDocumentWithConflictHandler(
    MutableDocument document,
    SaveConflictHandler conflictHandler,
  );

  @override
  Future<bool> deleteDocument(
    Document document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  @override
  Future<void> purgeDocument(Document document);

  @override
  Future<void> purgeDocumentById(String id);

  @override
  Future<void> inBatch(FutureOr<void> Function() fn);

  @override
  Future<void> setDocumentExpiration(String id, DateTime? expiration);

  @override
  Future<DateTime?> getDocumentExpiration(String id);

  @override
  Future<void> performMaintenance(MaintenanceType type);

  @override
  Future<List<String>> get indexes;

  @override
  Future<void> createIndex(String name, Index index);

  @override
  Future<void> deleteIndex(String name);
}

// === Impl ====================================================================

late final _bindings = cblBindings.database;

class FfiDatabase extends CBLDatabaseObject
    with ClosableResourceMixin
    implements SyncDatabase, BlobStoreHolder {
  FfiDatabase({
    required String name,
    DatabaseConfiguration? configuration,
    required String debugCreator,
  })  : _config = DatabaseConfiguration.from(
          configuration ?? DatabaseConfiguration(),
        ),
        super(
          _bindings.open(name, configuration?.toCBLDatabaseConfiguration()),
          debugName: 'FfiDatabase($name, creator: $debugCreator)',
        );

  @override
  late final blobStore = FfiBlobStore(this);

  final DatabaseConfiguration _config;

  var _deleteOnClose = false;

  @override
  String get name => useSync(() => _name);

  String get _name => call(_bindings.name);

  @override
  String? get path => useSync(() => call(_bindings.path));

  @override
  int get count => useSync(() => call(_bindings.count));

  @override
  DatabaseConfiguration get config =>
      useSync(() => DatabaseConfiguration.from(_config));

  @override
  Document? document(String id) =>
      useSync(() => call((pointer) => _bindings.getDocument(pointer, id))
          ?.let((pointer) => DocumentImpl(
                database: this,
                doc: pointer,
                debugCreator: 'FfiDatabase.document()',
              )));

  @override
  DocumentFragment operator [](String id) => DocumentFragmentImpl(document(id));

  @override
  bool saveDocument(
    covariant MutableDocumentImpl document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]) =>
      useSync(() {
        document.database = this;
        document.flushProperties();
        return _catchConflictException(() {
          runNativeCalls(() {
            _bindings.saveDocumentWithConcurrencyControl(
              native.pointer,
              document.native.pointer.cast(),
              concurrencyControl.toCBLConcurrencyControl(),
            );
          });
        });
      });

  @override
  Future<bool> saveDocumentWithConflictHandler(
    covariant MutableDocumentImpl document,
    SaveConflictHandler conflictHandler,
  ) =>
      use(() => _saveDocumentWithConflictHandler(
            document,
            conflictHandler,
          ));

  @override
  bool saveDocumentWithConflictHandlerSync(
    covariant MutableDocumentImpl document,
    SyncSaveConflictHandler conflictHandler,
  ) =>
      useSync(() {
        // Because the conflict handler is sync the result of the maybe async
        // method is always sync.
        return _saveDocumentWithConflictHandler(
          document,
          conflictHandler,
        ) as bool;
      });

  FutureOr<bool> _saveDocumentWithConflictHandler(
    covariant MutableDocumentImpl document,
    SaveConflictHandler conflictHandler,
  ) {
    // Implementing the conflict resolution in Dart, instead of using
    // the C implementation, allows us to make the conflict handler
    // asynchronous.

    var success = false;

    final done = iterateMaybeAsync(() sync* {
      var retry = false;
      var documentBeingSaved = document;

      do {
        if (saveDocument(
          documentBeingSaved,
          ConcurrencyControl.failOnConflict,
        )) {
          success = true;
          retry = false;
        } else {
          // Load the conflicting document.
          final conflictingDocument =
              this.document(document.id) as DocumentImpl?;

          // Let conflict handler try resolving the conflict.
          final handlerDescision = conflictHandler(
            documentBeingSaved,
            conflictingDocument,
          );

          if (handlerDescision is Future<bool>) {
            yield handlerDescision.then((it) => retry = it);
          } else {
            retry = handlerDescision;
          }

          if (retry) {
            mergeConflictingDocuments(
              documentBeingSaved,
              conflictingDocument,
            );
          }
        }
      } while (retry);
    }());

    if (done is Future<void>) {
      return done.then((_) => success);
    }
    return success;
  }

  @override
  bool deleteDocument(
    covariant DocumentImpl document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]) =>
      useSync(() {
        document.database = this;
        return _catchConflictException(() {
          runNativeCalls(() {
            _bindings.deleteDocumentWithConcurrencyControl(
              native.pointer,
              document.native.pointer.cast(),
              concurrencyControl.toCBLConcurrencyControl(),
            );
          });
        });
      });

  @override
  void purgeDocument(covariant DocumentImpl document) => useSync(() {
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
    void endTransaction(bool commit) =>
        call((pointer) => _bindings.endTransaction(pointer, commit));

    call(_bindings.beginTransaction);
    try {
      final result = fn();
      if (result is Future<void>) {
        return result.then(
          (_) => endTransaction(true),
          onError: (Object error) {
            endTransaction(false);
            throw error;
          },
        );
      } else {
        endTransaction(true);
      }
    } catch (e) {
      endTransaction(false);
      rethrow;
    }
  }

  @override
  void setDocumentExpiration(String id, DateTime? expiration) => useSync(() {
        call((pointer) =>
            _bindings.setDocumentExpiration(pointer, id, expiration));
      });

  @override
  DateTime? getDocumentExpiration(String id) => useSync(() {
        return call((pointer) => _bindings.getDocumentExpiration(pointer, id));
      });

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
  List<String> get indexes => useSync(() {
        return fl.Array.fromPointer(
          native.call(_bindings.indexNames),
          adopt: true,
        ).toObject().cast<String>();
      });

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
  String toString() => 'FfiDatabase($_name)';
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
      CBLDatabaseConfiguration(directory);
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

void mergeConflictingDocuments(
  MutableDocumentImpl documentBeingSaved,
  DocumentImpl? conflictingDocument,
) {
  // Make a copy of the resolved properties.
  final resolvedProperties = {
    for (final key in documentBeingSaved.keys)
      key: documentBeingSaved.value(key),
  };

  // If the document was deleted it has to be recreated.
  conflictingDocument ??=
      MutableDocument.withId(documentBeingSaved.id) as MutableDocumentImpl;

  // Replace the underlying native document of the document being saved with
  // that of the conflicting document.
  documentBeingSaved
    ..replaceNativeFrom(conflictingDocument)
    ..setData(resolvedProperties);
}
