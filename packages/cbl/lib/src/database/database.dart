import 'dart:async';

import 'package:meta/meta.dart';

import '../document/blob.dart';
import '../document/document.dart';
import '../document/fragment.dart';
import '../log.dart';
import '../log/log.dart';
import '../query/index/index.dart';
import '../replication.dart';
import '../support/listener_token.dart';
import '../support/resource.dart';
import '../support/streams.dart';
import '../support/tracing.dart';
import '../tracing.dart';
import '../typed_data.dart';
import '../typed_data/adapter.dart';
import 'database_change.dart';
import 'database_configuration.dart';
import 'document_change.dart';
import 'ffi_database.dart';
import 'proxy_database.dart';

/// Conflict-handling options when saving or deleting a document.
///
/// {@category Database}
enum ConcurrencyControl {
  /// The current save/delete will overwrite a conflicting revision if there is
  /// a conflict.
  lastWriteWins,

  /// The current save/delete will fail if there is a conflict.
  failOnConflict,
}

/// The type of maintenance a database can perform.
///
/// {@category Database}
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
///
/// {@category Database}
typedef SaveConflictHandler = FutureOr<bool> Function(
  MutableDocument documentBeingSaved,
  Document? conflictingDocument,
);

/// {@category Database}
/// {@category Typed Data}
abstract class SaveTypedDocument<D extends TypedDocumentObject,
    MD extends TypedMutableDocumentObject> {
  FutureOr<bool> withConcurrencyControl([
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  FutureOr<bool> withConflictHandler(
    TypedSaveConflictHandler<D, MD> handler,
  );
}

/// {@category Database}
/// {@category Typed Data}
typedef TypedSaveConflictHandler<D extends TypedDocumentObject,
        MD extends TypedMutableDocumentObject>
    = FutureOr<bool> Function(
  MD documentBeingSaved,
  D? conflictingDocument,
);

/// Listener which is called when one or more [Document]s in a [Database] have
/// changed.
///
/// {@category Database}
typedef DatabaseChangeListener = void Function(DatabaseChange change);

/// Listener which is called when a single [Document] has changed.
///
/// {@category Database}
typedef DocumentChangeListener = void Function(DocumentChange change);

/// A Couchbase Lite database.
///
/// {@category Database}
abstract class Database implements ClosableResource {
  /// {@template cbl.Database.openAsync}
  /// Opens a Couchbase Lite database with the given [name] and [config],
  /// which executes in a separate worker isolate.
  ///
  /// If the database does not yet exist, it will be created.
  /// {@endtemplate}
  static Future<AsyncDatabase> openAsync(
    String name, [
    DatabaseConfiguration? config,
  ]) =>
      AsyncDatabase.open(name, config);

  /// {@template cbl.Database.openSync}
  /// Opens a Couchbase Lite database with the given [name] and [config],
  /// which executes in the current isolate.
  ///
  /// If the database does not yet exist, it will be created.
  /// {@endtemplate}
  // ignore: prefer_constructors_over_static_methods
  static SyncDatabase openSync(
    String name, [
    DatabaseConfiguration? config,
  ]) =>
      SyncDatabase(name, config);

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
  /// given [name] and [config].
  ///
  /// The new database will be created at the directory specified in the
  /// [config].
  /// {@endtemplate}
  static Future<void> copy({
    required String from,
    required String name,
    DatabaseConfiguration? config,
  }) =>
      AsyncDatabase.copy(from: from, name: name, config: config);

  /// {@template cbl.Database.copySync}
  /// Copies a canned database [from] the given path to a new database with the
  /// given [name] and [config].
  ///
  /// The new database will be created at the directory specified in the
  /// [config].
  /// {@endtemplate}
  static void copySync({
    required String from,
    required String name,
    DatabaseConfiguration? config,
  }) =>
      SyncDatabase.copy(from: from, name: name, config: config);

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

  FutureOr<D?> typedDocument<D extends TypedDocumentObject>(String id);

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

  @useResult
  SaveTypedDocument<D, MD> saveTypedDocument<D extends TypedDocumentObject,
      MD extends TypedMutableDocumentObject>(
    TypedMutableDocumentObject<D, MD> document,
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

  FutureOr<bool> deleteTypedDocument(
    TypedDocumentObject document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  /// Purges a [document] from this database.
  ///
  /// This is more drastic than deletion: It removes all traces of the document.
  /// The purge will __not__ be replicated to other databases.
  FutureOr<void> purgeDocument(Document document);

  FutureOr<void> purgeTypedDocument(TypedDocumentObject document);

  /// Purges a [Document] from this database by its [id].
  ///
  /// This is more drastic than deletion: It removes all traces of the document.
  /// The purge will __not__ be replicated to other databases.
  FutureOr<void> purgeDocumentById(String id);

  /// Saves a [Blob] directly into this database without associating it with any
  /// [Document]s.
  ///
  /// Note: Blobs that are not associated with any document will be removed
  /// from the database when compacting the database.
  FutureOr<void> saveBlob(Blob blob);

  /// Gets a [Blob] using its metadata.
  ///
  /// If the blob with the specified metadata doesn’t exist, returns `null`.
  ///
  /// If the provided [properties] don't contain valid metadata, an
  /// [ArgumentError] is thrown.
  ///
  /// {@macro cbl.Blob.metadataTable}
  ///
  /// See also:
  ///
  ///   - [Blob.isBlob] to check if a [Map] contains valid Blob metadata.
  FutureOr<Blob?> getBlob(Map<String, Object?> properties);

  /// Runs a group of database operations in a batch.
  ///
  /// {@template cbl.Database.inBatch}
  /// Use this when performing bulk write operations like multiple
  /// inserts/updates; it saves the overhead of multiple database commits,
  /// greatly improving performance.
  ///
  /// Calls to [inBatch] must not be nested.
  ///
  /// Any asynchronous tasks launched from inside a [inBatch] block must finish
  /// writing to the database before the [inBatch] block completes.
  /// {@endtemplate}
  Future<void> inBatch(FutureOr<void> Function() fn);

  /// Sets an [expiration] date for a [Document] by its [id].
  ///
  /// After the given date the document will be purged from the database
  ///
  /// This is more drastic than deletion: It removes all traces of the document.
  /// The purge will __not__ be replicated to other databases.
  FutureOr<void> setDocumentExpiration(String id, DateTime? expiration);

  /// Gets the expiration date of a [Document] by its [id], if it exists.
  FutureOr<DateTime?> getDocumentExpiration(String id);

  /// Adds a [listener] to be notified of all changes to [Document]s in this
  /// database.
  ///
  /// {@template cbl.Database.addChangeListener}
  /// ## Adding a listener
  ///
  /// If a [Future] is returned, the listener will only start listening after
  /// the [Future] has completed. Otherwise the listener is listening
  /// immediately after this method returns.
  ///
  /// ## Removing a listener
  ///
  /// The returned [ListenerToken] needs to be provided to
  /// [removeChangeListener], to remove the given listener.
  /// Regardless of whether a [Future] is returned or not, the listener
  /// immediately stops being called.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///   - [DatabaseChange] for the change event given to [listener].
  ///   - [changes] for alternatively listening to changes through a [Stream].
  ///   - [addDocumentChangeListener] for listening for changes to a single
  ///     [Document].
  ///   - [removeChangeListener] for removing a previously added listener.
  FutureOr<ListenerToken> addChangeListener(DatabaseChangeListener listener);

  /// Adds a [listener] to be notified of changes to the [Document] with the
  /// given [id].
  ///
  /// {@macro cbl.Database.addChangeListener}
  ///
  /// See also:
  ///
  ///   - [DocumentChange] for the change event given to [listener].
  ///   - [documentChanges] for alternatively listening to changes through a
  ///     [Stream].
  ///   - [addChangeListener] for listening for changes to this database.
  ///   - [removeChangeListener] for removing a previously added listener.
  FutureOr<ListenerToken> addDocumentChangeListener(
    String id,
    DocumentChangeListener listener,
  );

  /// {@template cbl.Database.removeChangeListener}
  /// Removes a previously added change listener.
  ///
  /// Pass in the [token] that was handed out when adding the listener.
  ///
  /// Regardless of whether a [Future] is returned or not, the listener
  /// immediately stops being called.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///   - [addChangeListener] for listening for changes to this database.
  ///   - [addDocumentChangeListener] for listening for changes to a single
  ///     [Document].
  FutureOr<void> removeChangeListener(ListenerToken token);

  /// Returns a [Stream] to be notified of all changes to [Document]s in this
  /// database.
  ///
  /// This is an alternative stream based API for the [addChangeListener] API.
  ///
  /// {@template cbl.Database.AsyncListenStream}
  /// ## AsyncListenStream
  ///
  /// If the stream is missing changes, check if the returned stream is an
  /// [AsyncListenStream]. This type of stream needs to perform some async work
  /// to be fully listening. You can wait for that moment by awaiting
  /// [AsyncListenStream.listening].
  /// {@endtemplate}
  Stream<DatabaseChange> changes();

  /// Returns a [Stream] to be notified of changes to the [Document] with the
  /// given [id].
  ///
  /// This is an alternative stream based API for the
  /// [addDocumentChangeListener] API.
  ///
  /// {@macro cbl.Database.AsyncListenStream}
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

  /// Encrypts or decrypts a [Database], or changes its [EncryptionKey].
  ///
  /// {@macro cbl.EncryptionKey.enterpriseFeature}
  ///
  /// If [newKey] is `null`, the database will be decrypted.
  /// Otherwise the database will be encrypted with that key; if it was already
  /// encrypted, it will be re-encrypted with the new key.
  FutureOr<void> changeEncryptionKey(EncryptionKey? newKey);

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
///
/// {@category Database}
typedef SyncSaveConflictHandler = bool Function(
  MutableDocument documentBeingSaved,
  Document? conflictingDocument,
);

/// {@category Database}
/// {@category Typed Data}
abstract class SyncSaveTypedDocument<D extends TypedDocumentObject,
    MD extends TypedMutableDocumentObject> extends SaveTypedDocument<D, MD> {
  @override
  bool withConcurrencyControl([
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  @override
  FutureOr<bool> withConflictHandler(
    TypedSaveConflictHandler<D, MD> handler,
  );

  bool withConflictHandlerSync(
    TypedSyncSaveConflictHandler<D, MD> handler,
  );
}

/// {@category Database}
/// {@category Typed Data}
typedef TypedSyncSaveConflictHandler<D extends TypedDocumentObject,
        MD extends TypedMutableDocumentObject>
    = bool Function(
  MD documentBeingSaved,
  D? conflictingDocument,
);

/// A [Database] with a primarily synchronous API.
///
/// {@category Database}
abstract class SyncDatabase implements Database {
  /// {@macro cbl.Database.openSync}
  factory SyncDatabase(String name, [DatabaseConfiguration? config]) =>
      SyncDatabase.internal(name, config);

  /// @nodoc
  @internal
  factory SyncDatabase.internal(
    String name, [
    DatabaseConfiguration? config,
    TypedDataAdapter? typedDataAdapter,
  ]) =>
      syncOperationTracePoint(
        () => OpenDatabaseOp(name, config),
        () => FfiDatabase(
          name: name,
          config: config,
          typedDataAdapter: typedDataAdapter,
          debugCreator: 'SyncDatabase.internal()',
        ),
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
    DatabaseConfiguration? config,
  }) =>
      FfiDatabase.copy(from: from, name: name, config: config);

  @override
  int get count;

  @override
  Document? document(String id);

  @override
  DocumentFragment operator [](String id);

  @override
  D? typedDocument<D extends TypedDocumentObject>(String id);

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
  @useResult
  SyncSaveTypedDocument<D, MD> saveTypedDocument<D extends TypedDocumentObject,
      MD extends TypedMutableDocumentObject>(
    TypedMutableDocumentObject<D, MD> document,
  );

  @override
  bool deleteDocument(
    Document document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  @override
  bool deleteTypedDocument(
    TypedDocumentObject document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  @override
  void purgeDocument(Document document);

  @override
  void purgeTypedDocument(TypedDocumentObject document);

  @override
  void purgeDocumentById(String id);

  @override
  Future<void> saveBlob(Blob blob);

  @override
  Blob? getBlob(Map<String, Object?> properties);

  /// Runs a group of database operations in a batch, synchronously.
  ///
  /// {@macro cbl.Database.inBatch}
  void inBatchSync(void Function() fn);

  @override
  void setDocumentExpiration(String id, DateTime? expiration);

  @override
  DateTime? getDocumentExpiration(String id);

  @override
  ListenerToken addChangeListener(DatabaseChangeListener listener);

  @override
  ListenerToken addDocumentChangeListener(
    String id,
    DocumentChangeListener listener,
  );

  @override
  void removeChangeListener(ListenerToken token);

  @override
  void performMaintenance(MaintenanceType type);

  @override
  void changeEncryptionKey(EncryptionKey? newKey);

  @override
  List<String> get indexes;

  @override
  void createIndex(String name, Index index);

  @override
  void deleteIndex(String name);
}

/// {@category Database}
/// {@category Typed Data}
abstract class AsyncSaveTypedDocument<D extends TypedDocumentObject,
    MD extends TypedMutableDocumentObject> extends SaveTypedDocument<D, MD> {
  @override
  Future<bool> withConcurrencyControl([
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  @override
  Future<bool> withConflictHandler(
    TypedSaveConflictHandler<D, MD> handler,
  );
}

/// A [Database] with a primarily asynchronous API.
///
/// {@category Database}
abstract class AsyncDatabase implements Database {
  /// {@macro cbl.Database.openAsync}
  static Future<AsyncDatabase> open(
    String name, [
    DatabaseConfiguration? config,
  ]) =>
      openInternal(name, config);

  /// @nodoc
  @internal
  static Future<AsyncDatabase> openInternal(
    String name, [
    DatabaseConfiguration? config,
    TypedDataAdapter? typedDataAdapter,
  ]) =>
      asyncOperationTracePoint(
        () => OpenDatabaseOp(name, config),
        () => WorkerDatabase.open(name, config, typedDataAdapter),
      );

  /// {@macro cbl.Database.remove}
  static Future<void> remove(String name, {String? directory}) =>
      WorkerDatabase.remove(name, directory: directory);

  /// {@macro cbl.Database.exists}
  static Future<bool> exists(String name, {String? directory}) =>
      WorkerDatabase.exists(name, directory: directory);

  /// {@macro cbl.Database.copy}
  static Future<void> copy({
    required String from,
    required String name,
    DatabaseConfiguration? config,
  }) =>
      WorkerDatabase.copy(from: from, name: name, config: config);

  @override
  Future<int> get count;

  @override
  Future<Document?> document(String id);

  @override
  Future<DocumentFragment> operator [](String id);

  @override
  Future<D?> typedDocument<D extends TypedDocumentObject>(String id);

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
  @useResult
  AsyncSaveTypedDocument<D, MD> saveTypedDocument<D extends TypedDocumentObject,
      MD extends TypedMutableDocumentObject>(
    TypedMutableDocumentObject<D, MD> document,
  );

  @override
  Future<bool> deleteDocument(
    Document document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  @override
  Future<bool> deleteTypedDocument(
    TypedDocumentObject document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  @override
  Future<void> purgeDocument(Document document);

  @override
  Future<void> purgeTypedDocument(TypedDocumentObject document);

  @override
  Future<void> purgeDocumentById(String id);

  @override
  Future<void> saveBlob(Blob blob);

  @override
  Future<Blob?> getBlob(Map<String, Object?> properties);

  @override
  Future<void> inBatch(FutureOr<void> Function() fn);

  @override
  Future<void> setDocumentExpiration(String id, DateTime? expiration);

  @override
  Future<DateTime?> getDocumentExpiration(String id);

  @override
  Future<ListenerToken> addChangeListener(DatabaseChangeListener listener);

  @override
  Future<ListenerToken> addDocumentChangeListener(
    String id,
    DocumentChangeListener listener,
  );

  @override
  Future<void> removeChangeListener(ListenerToken token);

  @override
  AsyncListenStream<DatabaseChange> changes();

  @override
  AsyncListenStream<DocumentChange> documentChanges(String id);

  @override
  Future<void> performMaintenance(MaintenanceType type);

  @override
  Future<void> changeEncryptionKey(EncryptionKey? newKey);

  @override
  Future<List<String>> get indexes;

  @override
  Future<void> createIndex(String name, Index index);

  @override
  Future<void> deleteIndex(String name);
}
