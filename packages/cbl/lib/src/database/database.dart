import 'dart:async';
import 'dart:ffi';

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
/// If the handler throws or returns a [Future] which rejects, the save will be
/// aborted.
///
/// See:
/// - [Database.saveDocumentWithConflictHandler] for saving a [Document] with a
///   custom conflict handler.
typedef SaveConflictHandler = bool Function(
  MutableDocument documentBeingSaved,
  Document? conflictingDocument,
);

/// A Couchbase Lite database.
abstract class Database implements ClosableResource {
  /// Initializes a Couchbase Lite database with a given name and
  /// [configuration].
  ///
  /// If the database does not yet exist, it will be created.
  factory Database(String name, [DatabaseConfiguration? configuration]) =>
      DatabaseImpl(name, configuration);

  /// Configuration of the [ConsoleLogger], [FileLogger] and a custom [Logger].
  static final Log log = LogImpl();

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

  /// The name of this database.
  String get name;

  /// The path to this database.
  ///
  /// Is `null` if the database is closed or deleted.
  String? get path;

  /// The total number of documents in the database.
  int get count;

  /// The configuration which was used to open this database.
  DatabaseConfiguration get config;

  /// Returns the [Document] with the given [id], if it exists.
  Document? document(String id);

  /// Returns the [DocumentFragment] for the [Document] with the given [id].
  DocumentFragment operator [](String id);

  /// Saves a [document] to this database, resolving conflicts through
  /// [ConcurrencyControl].
  ///
  /// When write operations are executed concurrently, the last writer will win
  /// by default. In this case the result is always `true`.
  ///
  /// To fail on conflict instead, pass [ConcurrencyControl.failOnConflict] to
  /// [concurrencyControl]. In this case, if the document could not be saved
  /// the result is `false`. On success it is `true`.
  bool saveDocument(
    MutableDocument document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  /// Saves a [document] to this database, resolving conflicts with a
  /// [conflictHandler].
  ///
  /// When write operations are executed concurrently and if conflicts occur,
  /// the [conflictHandler] will be called. Use the conflict handler to
  /// directly edit the [Document] to resolve the conflict. When the conflict
  /// handler returns `true`, the save method will save the edited document as
  /// the resolved document. If the conflict handler returns `false`, the save
  /// operation will be canceled with `false` as the result. If the conflict
  /// handler returns `true` or there is no conflict the result is `true`.
  ///
  /// [conflictHandler] should not throw to abort the save operation. If the
  /// handler does throw, the save operation is aborted as if the handler had
  /// returned `false`, but errors thrown by the [conflictHandler] __cannot__ be
  /// caught by executing this method in a try-catch block. These errors are
  /// uncaught errors within the current [Zone].
  bool saveDocumentWithConflictHandler(
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
  bool deleteDocument(
    Document document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  /// Purges a [document] from this database.
  ///
  /// This is more drastic than deletion: It removes all traces of the document.
  /// The purge will __not__ be replicated to other databases.
  void purgeDocument(Document document);

  /// Purges a [Document] from this database by its [id].
  ///
  /// This is more drastic than deletion: It removes all traces of the document.
  /// The purge will __not__ be replicated to other databases.
  void purgeDocumentById(String id);

  /// Runs a group of database operations in a batch.
  ///
  /// Use this when performance bulk write operations like multiple
  /// inserts/updates; it saves the overhead of multiple database commits,
  /// greatly improving performance.
  void inBatch(void Function() fn);

  /// Sets an [expiration] date for a [Document] by its [id].
  ///
  /// After the given date the document will be purged from the database
  ///
  /// This is more drastic than deletion: It removes all traces of the document.
  /// The purge will __not__ be replicated to other databases.
  void setDocumentExpiration(String id, DateTime? expiration);

  /// Gets the expiration date of a [Document] by its [id], if it exists.
  DateTime? getDocumentExpiration(String id);

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
  void performMaintenance(MaintenanceType type);

  /// The names of all existing indexes.
  List<String> get indexes;

  /// Creates a value or full-text search [index] with the given [name].
  ///
  /// The name can be used for deleting the index. Creating a new different
  /// index with an existing index name will replace the old index; creating the
  /// same index with the same name is a no-op.
  void createIndex(String name, Index index);

  /// Deletes the [Index] of the given [name].
  void deleteIndex(String name);
}

// === Impl ====================================================================

late final _bindings = cblBindings.database;

class DatabaseImpl extends CblObject<CBLDatabase>
    with ClosableResourceMixin
    implements Database {
  DatabaseImpl(String name, [DatabaseConfiguration? configuration])
      : _config = DatabaseConfiguration.from(
          configuration ?? DatabaseConfiguration(),
        ),
        super(
          _bindings.open(name, configuration?.toCBLDatabaseConfiguration()),
          debugName: 'Database($name)',
        );

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
                debugCreator: 'Database.document()',
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
  bool saveDocumentWithConflictHandler(
    covariant MutableDocumentImpl document,
    SaveConflictHandler conflictHandler,
  ) =>
      useSync(() {
        document.database = this;
        document.flushProperties();

        bool conflictHandlerAdapter(
          Pointer<CBLMutableDocument> _,
          Pointer<CBLDocument>? conflictingDocument,
        ) {
          var saveDocument = false;

          final _conflictingDocument = conflictingDocument?.let(
            (pointer) => DocumentImpl(
              database: this,
              doc: pointer,
              adopt: false,
              debugCreator: 'SaveConflictHandler(conflictingDocument)',
            ),
          );

          saveDocument = conflictHandler(document, _conflictingDocument);
          document.flushProperties();

          return saveDocument;
        }

        final result = _catchConflictException(() {
          runNativeCalls(() => _bindings.saveDocumentWithConflictHandler(
                native.pointer,
                document.native.pointer.cast(),
                conflictHandlerAdapter,
              ));
        });

        return result;
      });

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
  void inBatch(void Function() fn) {
    void endTransaction(bool commit) =>
        call((pointer) => _bindings.endTransaction(pointer, commit));

    return useSync(() {
      call(_bindings.beginTransaction);
      try {
        fn();
        endTransaction(true);
      } catch (e) {
        endTransaction(false);
        rethrow;
      }
    });
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
  String toString() => 'Database($_name)';
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
