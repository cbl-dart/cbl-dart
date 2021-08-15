import 'dart:async';

import '../document/document.dart';
import '../document/fragment.dart';
import '../log.dart';
import '../log/log.dart';
import '../query/index/index.dart';
import '../replication.dart';
import '../support/resource.dart';
import 'database_change.dart';
import 'database_configuration.dart';
import 'document_change.dart';
import 'ffi_database.dart';

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
  /// {@template cbl.Database.open}
  /// Opens a Couchbase Lite database with the given [name] and [configuration],
  /// which executes in a separate worker isolate.
  ///
  /// If the database does not yet exist, it will be created.
  /// {@endtemplate}
  static Future<AsyncDatabase> open(
    String name, [
    DatabaseConfiguration? configuration,
  ]) =>
      AsyncDatabase.open(name, configuration);

  /// {@template cbl.Database.openSync}
  /// Opens a Couchbase Lite database with the given [name] and [configuration],
  /// which executes in the current isolate.
  ///
  /// If the database does not yet exist, it will be created.
  /// {@endtemplate}
  static SyncDatabase openSync(
    String name, [
    DatabaseConfiguration? configuration,
  ]) =>
      SyncDatabase(name, configuration);

  /// {@template cbl.Database.remove}
  /// Deletes a database of the given [name] in the given [directory].
  /// {@endtemplate}
  static Future<void> remove(String name, {String? directory}) =>
      AsyncDatabase.remove(name, directory: directory);

  /// {@template cbl.Database.removeSync}
  /// Deletes a database of the given [name] in the given [directory].
  /// {@endtemplate}
  static void removeSync(String name, {String? directory}) =>
      SyncDatabase.remove(name, directory: directory);

  /// {@template cbl.Database.exists}
  /// Checks whether a database of the given [name] exists in the given
  /// [directory] or not.
  /// {@endtemplate}
  static Future<bool> exists(String name, {String? directory}) =>
      AsyncDatabase.exists(name, directory: directory);

  /// {@template cbl.Database.existsSync}
  /// Checks whether a database of the given [name] exists in the given
  /// [directory] or not.
  /// {@endtemplate}
  static bool existsSync(String name, {String? directory}) =>
      SyncDatabase.exists(name, directory: directory);

  /// {@template cbl.Database.copy}
  /// Copies a canned database [from] the given path to a new database with the
  /// given [name] and [configuration].
  ///
  /// The new database will be created at the directory specified in the
  /// [configuration].
  /// {@endtemplate}
  static Future<void> copy({
    required String from,
    required String name,
    DatabaseConfiguration? configuration,
  }) =>
      AsyncDatabase.copy(from: from, name: name, configuration: configuration);

  /// {@template cbl.Database.copySync}
  /// Copies a canned database [from] the given path to a new database with the
  /// given [name] and [configuration].
  ///
  /// The new database will be created at the directory specified in the
  /// [configuration].
  /// {@endtemplate}
  static void copySync({
    required String from,
    required String name,
    DatabaseConfiguration? configuration,
  }) =>
      SyncDatabase.copy(from: from, name: name, configuration: configuration);

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
  /// {@macro cbl.Database.openSync}
  factory SyncDatabase(String name, [DatabaseConfiguration? configuration]) =>
      FfiDatabase(
        name: name,
        configuration: configuration,
        debugCreator: 'SyncDatabase()',
      );

  /// {@macro cbl.Database.removeSync}
  static void remove(String name, {String? directory}) =>
      FfiDatabase.remove(name, directory: directory);

  /// {@macro cbl.Database.existsSync}
  static bool exists(String name, {String? directory}) =>
      FfiDatabase.exists(name, directory: directory);

  /// {@macro cbl.Database.copySync}
  static void copy({
    required String from,
    required String name,
    DatabaseConfiguration? configuration,
  }) =>
      FfiDatabase.copy(from: from, name: name, configuration: configuration);

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
  /// {@macro cbl.Database.open}
  static Future<AsyncDatabase> open(
    String name, [
    DatabaseConfiguration? configuration,
  ]) =>
      throw UnimplementedError();

  /// {@macro cbl.Database.remove}
  static Future<void> remove(String name, {String? directory}) =>
      throw UnimplementedError();

  /// {@macro cbl.Database.exists}
  static Future<bool> exists(String name, {String? directory}) =>
      throw UnimplementedError();

  /// {@macro cbl.Database.copy}
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
