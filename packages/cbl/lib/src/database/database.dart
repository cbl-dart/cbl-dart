// ignore_for_file: unused_result

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
import 'collection.dart';
import 'database_change.dart';
import 'database_configuration.dart';
import 'document_change.dart';
import 'ffi_database.dart';
import 'proxy_database.dart';
import 'scope.dart';

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

/// The result of [Database.saveTypedDocument], which needs to be used to
/// actually save the document.
///
/// See also:
///
/// - [SyncSaveTypedDocument] for the synchronous version of this class, which
///   is returned from [SyncDatabase.saveTypedDocument].
/// - [AsyncSaveTypedDocument] for the asynchronous version of this class, which
///   is returned from [AsyncDatabase.saveTypedDocument].
///
/// {@category Database}
/// {@category Typed Data}
@experimental
abstract class SaveTypedDocument<D extends TypedDocumentObject,
    MD extends TypedMutableDocumentObject> {
  /// Saves the document to the database, resolving conflicts through
  /// [ConcurrencyControl].
  ///
  /// When write operations are executed concurrently, the last writer will win
  /// by default. In this case the result is always `true`.
  ///
  /// To fail on conflict instead, pass [ConcurrencyControl.failOnConflict] to
  /// [concurrencyControl]. In this case, if the document could not be saved the
  /// result is `false`. On success it is `true`.
  FutureOr<bool> withConcurrencyControl([
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  /// Saves the document to the database, resolving conflicts with a
  /// [conflictHandler].
  ///
  /// {@macro cbl.Database.saveDocumentWithConflictHandler}
  FutureOr<bool> withConflictHandler(
    TypedSaveConflictHandler<D, MD> conflictHandler,
  );
}

/// Custom conflict handler for saving a typed document.
///
/// {@template cbl.TypedSaveConflictHandler}
/// This handler is called if the save would cause a conflict, i.e. if the
/// document in the database has been updated (probably by a pull replicator, or
/// by application code) since it was loaded into the document being saved.
///
/// The [documentBeingSaved] (same as the parameter you passed to
/// [SaveTypedDocument.withConflictHandler].) may be modify by the callback as
/// necessary to resolve the conflict.
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
/// - [SaveTypedDocument.withConflictHandler] for saving a typed document with a
///   custom conflict handler.
///
/// {@category Database}
/// {@category Typed Data}
@experimental
typedef TypedSaveConflictHandler<D extends TypedDocumentObject,
        MD extends TypedMutableDocumentObject>
    = FutureOr<bool> Function(
  MD documentBeingSaved,
  D? conflictingDocument,
);

/// A Couchbase Lite database.
///
/// {@category Database}
abstract class Database implements ClosableResource {
  /// {@template cbl.Database.openAsync}
  /// Opens a Couchbase Lite database with the given [name] and [config], which
  /// executes in a separate worker isolate.
  ///
  /// If the database does not yet exist, it will be created.
  /// {@endtemplate}
  static Future<AsyncDatabase> openAsync(
    String name, [
    DatabaseConfiguration? config,
  ]) =>
      AsyncDatabase.open(name, config);

  /// {@template cbl.Database.openSync}
  /// Opens a Couchbase Lite database with the given [name] and [config], which
  /// executes in the current isolate.
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
  @Deprecated('Use defaultCollection.count instead.')
  FutureOr<int> get count;

  /// The configuration which was used to open this database.
  DatabaseConfiguration get config;

  /// The default [Scope] of this database.
  FutureOr<Scope> get defaultScope;

  /// The [Scope]s of this database.
  ///
  /// Every returned scope contains at least one collection.
  FutureOr<List<Scope>> get scopes;

  /// Returns the [Scope] with the given [name].
  ///
  /// Returns `null` if there is not at least one collection in the scope.
  FutureOr<Scope?> scope(String name);

  /// The default [Collection] of this database.
  FutureOr<Collection> get defaultCollection;

  /// Returns the [Collection] with the given [name] in the given [scope].
  ///
  /// Returns `null` if the collection does not exist.
  FutureOr<Collection?> collection(
    String name, [
    String scope = Scope.defaultName,
  ]);

  /// Returns all the [Collection]s in the given [scope].
  FutureOr<List<Collection>> collections([String scope = Scope.defaultName]);

  /// Creates a [Collection] with the given [name] in the specified [scope].
  ///
  /// If the [Collection] already exists, the existing collection will be
  /// returned.
  FutureOr<Collection> createCollection(
    String name, [
    String scope = Scope.defaultName,
  ]);

  /// Deletes the [Collection] with the given [name] in the given [scope].
  FutureOr<void> deleteCollection(
    String name, [
    String scope = Scope.defaultName,
  ]);

  /// Returns the [Document] with the given [id], if it exists.
  @Deprecated('Use defaultCollection.document instead.')
  FutureOr<Document?> document(String id);

  /// Returns the [DocumentFragment] for the [Document] with the given [id].
  @Deprecated('Use defaultCollection[] instead.')
  FutureOr<DocumentFragment> operator [](String id);

  /// Returns the typed document, with type [D] and the given [id], if it
  /// exists.
  @experimental
  FutureOr<D?> typedDocument<D extends TypedDocumentObject>(String id);

  /// Saves a [document] to this database, resolving conflicts through
  /// [ConcurrencyControl].
  ///
  /// When write operations are executed concurrently, the last writer will win
  /// by default. In this case the result is always `true`.
  ///
  /// To fail on conflict instead, pass [ConcurrencyControl.failOnConflict] to
  /// [concurrencyControl]. In this case, if the document could not be saved the
  /// result is `false`. On success it is `true`.
  @Deprecated('Use defaultCollection.saveDocument instead.')
  FutureOr<bool> saveDocument(
    MutableDocument document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  /// Saves a [document] to this database, resolving conflicts with a
  /// [conflictHandler].
  ///
  /// {@template cbl.Database.saveDocumentWithConflictHandler}
  /// When write operations are executed concurrently and if conflicts occur,
  /// the [conflictHandler] will be called. Use the conflict handler to directly
  /// edit the [Document] to resolve the conflict. When the conflict handler
  /// returns `true`, the save method will save the edited document as the
  /// resolved document. If the conflict handler returns `false`, the save
  /// operation will be canceled with `false` as the result. If the conflict
  /// handler returns `true` or there is no conflict the result is `true`.
  /// {@endtemplate}
  @Deprecated('Use defaultCollection.saveDocumentWithConflictHandler instead.')
  FutureOr<bool> saveDocumentWithConflictHandler(
    MutableDocument document,
    SaveConflictHandler conflictHandler,
  );

  /// Creates and returns an object, which can be used to save a typed
  /// [document] to this database.
  ///
  /// A call to this method will not save the document to the database. Call one
  /// of the methods of the returned object to finally save the [document].
  ///
  /// See also:
  ///
  /// - [SaveTypedDocument] for the object used to save typed documents.
  @experimental
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
  @Deprecated('Use defaultCollection.deleteDocument instead.')
  FutureOr<bool> deleteDocument(
    Document document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  /// Deletes a typed [document] from this database, resolving conflicts through
  /// [ConcurrencyControl].
  ///
  /// When write operations are executed concurrently, the last writer will win
  /// by default. In this case the result is always `true`.
  ///
  /// To fail on conflict instead, pass [ConcurrencyControl.failOnConflict] to
  /// [concurrencyControl]. In this case, if the document could not be deleted
  /// the result is `false`. On success it is `true`.
  @experimental
  FutureOr<bool> deleteTypedDocument(
    TypedDocumentObject document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  /// Purges a [document] from this database.
  ///
  /// This is more drastic than deletion: It removes all traces of the document.
  /// The purge will **not** be replicated to other databases.
  @Deprecated('Use defaultCollection.purgeDocument instead.')
  FutureOr<void> purgeDocument(Document document);

  /// Purges a typed [document] from this database.
  ///
  /// This is more drastic than deletion: It removes all traces of the document.
  /// The purge will **not** be replicated to other databases.
  @experimental
  FutureOr<void> purgeTypedDocument(TypedDocumentObject document);

  /// Purges a [Document] from this database by its [id].
  ///
  /// This is more drastic than deletion: It removes all traces of the document.
  /// The purge will **not** be replicated to other databases.
  @Deprecated('Use defaultCollection.purgeDocumentById instead.')
  FutureOr<void> purgeDocumentById(String id);

  /// Saves a [Blob] directly into this database without associating it with any
  /// [Document]s.
  ///
  /// Note: Blobs that are not associated with any document will be removed from
  /// the database when compacting the database.
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
  /// - [Blob.isBlob] to check if a [Map] contains valid Blob metadata.
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
  /// The purge will **not** be replicated to other databases.
  @Deprecated('Use defaultCollection.setDocumentExpiration instead.')
  FutureOr<void> setDocumentExpiration(String id, DateTime? expiration);

  /// Gets the expiration date of a [Document] by its [id], if it exists.
  @Deprecated('Use defaultCollection.getDocumentExpiration instead.')
  FutureOr<DateTime?> getDocumentExpiration(String id);

  /// Adds a [listener] to be notified of all changes to [Document]s in this
  /// database.
  ///
  /// {@macro cbl.Collection.addChangeListener}
  ///
  /// See also:
  ///
  /// - [DatabaseChange] for the change event given to [listener].
  /// - [changes] for alternatively listening to changes through a [Stream].
  /// - [addDocumentChangeListener] for listening for changes to a single
  ///   [Document].
  /// - [removeChangeListener] for removing a previously added listener.
  @Deprecated('Use defaultCollection.addChangeListener instead.')
  FutureOr<ListenerToken> addChangeListener(DatabaseChangeListener listener);

  /// Adds a [listener] to be notified of changes to the [Document] with the
  /// given [id].
  ///
  /// {@macro cbl.Collection.addChangeListener}
  ///
  /// See also:
  ///
  /// - [DocumentChange] for the change event given to [listener].
  /// - [documentChanges] for alternatively listening to changes through a
  ///   [Stream].
  /// - [addChangeListener] for listening for changes to this database.
  /// - [removeChangeListener] for removing a previously added listener.
  @Deprecated('Use defaultCollection.addDocumentChangeListener instead.')
  FutureOr<ListenerToken> addDocumentChangeListener(
    String id,
    DocumentChangeListener listener,
  );

  /// {@macro cbl.Collection.removeChangeListener}
  ///
  /// See also:
  ///
  /// - [addChangeListener] for listening for changes to this database.
  /// - [addDocumentChangeListener] for listening for changes to a single
  ///   [Document].
  @Deprecated('Use defaultCollection.removeChangeListener instead.')
  FutureOr<void> removeChangeListener(ListenerToken token);

  /// Returns a [Stream] to be notified of all changes to [Document]s in this
  /// database.
  ///
  /// This is an alternative stream based API for the [addChangeListener] API.
  ///
  /// {@macro cbl.Collection.AsyncListenStream}
  @Deprecated('Use defaultCollection.changes instead.')
  Stream<DatabaseChange> changes();

  /// Returns a [Stream] to be notified of changes to the [Document] with the
  /// given [id].
  ///
  /// This is an alternative stream based API for the
  /// [addDocumentChangeListener] API.
  ///
  /// {@macro cbl.Collection.AsyncListenStream}
  @Deprecated('Use defaultCollection.documentChanges instead.')
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
  /// If [newKey] is `null`, the database will be decrypted. Otherwise the
  /// database will be encrypted with that key; if it was already encrypted, it
  /// will be re-encrypted with the new key.
  FutureOr<void> changeEncryptionKey(EncryptionKey? newKey);

  /// The names of all existing indexes.
  @Deprecated('Use defaultCollection.indexes instead.')
  FutureOr<List<String>> get indexes;

  /// Creates a value or full-text search [index] with the given [name].
  ///
  /// The name can be used for deleting the index. Creating a new different
  /// index with an existing index name will replace the old index; creating the
  /// same index with the same name is a no-op.
  @Deprecated('Use defaultCollection.createIndex instead.')
  FutureOr<void> createIndex(String name, Index index);

  /// Deletes the [Index] of the given [name].
  @Deprecated('Use defaultCollection.deleteIndex instead.')
  FutureOr<void> deleteIndex(String name);
}

/// The result of [SyncDatabase.saveTypedDocument], which needs to be used to
/// actually save the document.
///
/// {@category Database}
/// {@category Typed Data}
@experimental
abstract class SyncSaveTypedDocument<D extends TypedDocumentObject,
    MD extends TypedMutableDocumentObject> extends SaveTypedDocument<D, MD> {
  @override
  bool withConcurrencyControl([
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  @override
  FutureOr<bool> withConflictHandler(
    TypedSaveConflictHandler<D, MD> conflictHandler,
  );

  /// Saves the document to the database, resolving conflicts with a sync
  /// [conflictHandler].
  ///
  /// {@macro cbl.Database.saveDocumentWithConflictHandler}
  bool withConflictHandlerSync(
    TypedSyncSaveConflictHandler<D, MD> conflictHandler,
  );
}

/// Custom sync conflict handler for saving a typed document.
///
/// {@macro cbl.TypedSaveConflictHandler}
///
/// See also:
///
/// - [SyncSaveTypedDocument.withConflictHandlerSync] for saving a typed
///   document with a custom sync conflict handler.
///
/// {@category Database}
/// {@category Typed Data}
@experimental
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

  @Deprecated('Use defaultCollection.count instead.')
  @override
  int get count;

  @override
  SyncScope get defaultScope;

  @override
  List<SyncScope> get scopes;

  @override
  SyncScope? scope(String name);

  @override
  SyncCollection get defaultCollection;

  @override
  SyncCollection? collection(
    String name, [
    String scope = Scope.defaultName,
  ]);

  @override
  List<SyncCollection> collections([String scope = Scope.defaultName]);

  @override
  SyncCollection createCollection(
    String name, [
    String scope = Scope.defaultName,
  ]);

  @override
  void deleteCollection(
    String name, [
    String scope = Scope.defaultName,
  ]);

  @Deprecated('Use defaultCollection.document instead.')
  @override
  Document? document(String id);

  @Deprecated('Use defaultCollection[] instead.')
  @override
  DocumentFragment operator [](String id);

  @override
  @experimental
  D? typedDocument<D extends TypedDocumentObject>(String id);

  @Deprecated('Use defaultCollection.saveDocument instead.')
  @override
  bool saveDocument(
    MutableDocument document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  /// Saves a [document] to this database, resolving conflicts with an sync
  /// [conflictHandler].
  ///
  /// {@macro cbl.Database.saveDocumentWithConflictHandler}
  @Deprecated(
    'Use defaultCollection.saveDocumentWithConflictHandlerSync instead.',
  )
  bool saveDocumentWithConflictHandlerSync(
    MutableDocument document,
    SyncSaveConflictHandler conflictHandler,
  );

  @override
  @experimental
  @useResult
  SyncSaveTypedDocument<D, MD> saveTypedDocument<D extends TypedDocumentObject,
      MD extends TypedMutableDocumentObject>(
    TypedMutableDocumentObject<D, MD> document,
  );

  @Deprecated('Use defaultCollection.deleteDocument instead.')
  @override
  bool deleteDocument(
    Document document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  @override
  @experimental
  bool deleteTypedDocument(
    TypedDocumentObject document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  @Deprecated('Use defaultCollection.purgeDocument instead.')
  @override
  void purgeDocument(Document document);

  @override
  @experimental
  void purgeTypedDocument(TypedDocumentObject document);

  @Deprecated('Use defaultCollection.purgeDocumentById instead.')
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

  @Deprecated('Use defaultCollection.setDocumentExpiration instead.')
  @override
  void setDocumentExpiration(String id, DateTime? expiration);

  @Deprecated('Use defaultCollection.getDocumentExpiration instead.')
  @override
  DateTime? getDocumentExpiration(String id);

  @Deprecated('Use defaultCollection.addChangeListener instead.')
  @override
  ListenerToken addChangeListener(DatabaseChangeListener listener);

  @Deprecated('Use defaultCollection.addDocumentChangeListener instead.')
  @override
  ListenerToken addDocumentChangeListener(
    String id,
    DocumentChangeListener listener,
  );

  @Deprecated('Use defaultCollection.removeChangeListener instead.')
  @override
  void removeChangeListener(ListenerToken token);

  @override
  void performMaintenance(MaintenanceType type);

  @override
  void changeEncryptionKey(EncryptionKey? newKey);

  @Deprecated('Use defaultCollection.indexes instead.')
  @override
  List<String> get indexes;

  @Deprecated('Use defaultCollection.createIndex instead.')
  @override
  void createIndex(String name, Index index);

  @Deprecated('Use defaultCollection.deleteIndex instead.')
  @override
  void deleteIndex(String name);
}

/// The result of [AsyncDatabase.saveTypedDocument], which needs to be used to
/// actually save the document.
///
/// {@category Database}
/// {@category Typed Data}
@experimental
abstract class AsyncSaveTypedDocument<D extends TypedDocumentObject,
    MD extends TypedMutableDocumentObject> extends SaveTypedDocument<D, MD> {
  @override
  Future<bool> withConcurrencyControl([
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  @override
  Future<bool> withConflictHandler(
    TypedSaveConflictHandler<D, MD> conflictHandler,
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

  @Deprecated('Use defaultCollection.count instead.')
  @override
  Future<int> get count;

  @override
  Future<AsyncScope> get defaultScope;

  @override
  Future<List<AsyncScope>> get scopes;

  @override
  Future<AsyncScope?> scope(String name);

  @override
  Future<AsyncCollection> get defaultCollection;

  @override
  Future<AsyncCollection?> collection(
    String name, [
    String scope = Scope.defaultName,
  ]);

  @override
  Future<List<AsyncCollection>> collections([String scope = Scope.defaultName]);

  @override
  Future<AsyncCollection> createCollection(
    String name, [
    String scope = Scope.defaultName,
  ]);

  @override
  Future<void> deleteCollection(
    String name, [
    String scope = Scope.defaultName,
  ]);

  @Deprecated('Use defaultCollection.document instead.')
  @override
  Future<Document?> document(String id);

  @Deprecated('Use defaultCollection[] instead.')
  @override
  Future<DocumentFragment> operator [](String id);

  @override
  @experimental
  Future<D?> typedDocument<D extends TypedDocumentObject>(String id);

  @Deprecated('Use defaultCollection.saveDocument instead.')
  @override
  Future<bool> saveDocument(
    MutableDocument document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  @Deprecated('Use defaultCollection.saveDocumentWithConflictHandler instead.')
  @override
  Future<bool> saveDocumentWithConflictHandler(
    MutableDocument document,
    SaveConflictHandler conflictHandler,
  );

  @override
  @experimental
  @useResult
  AsyncSaveTypedDocument<D, MD> saveTypedDocument<D extends TypedDocumentObject,
      MD extends TypedMutableDocumentObject>(
    TypedMutableDocumentObject<D, MD> document,
  );

  @Deprecated('Use defaultCollection.deleteDocument instead.')
  @override
  Future<bool> deleteDocument(
    Document document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  @override
  @experimental
  Future<bool> deleteTypedDocument(
    TypedDocumentObject document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  @Deprecated('Use defaultCollection.purgeDocument instead.')
  @override
  Future<void> purgeDocument(Document document);

  @override
  @experimental
  Future<void> purgeTypedDocument(TypedDocumentObject document);

  @Deprecated('Use defaultCollection.purgeDocumentById instead.')
  @override
  Future<void> purgeDocumentById(String id);

  @override
  Future<void> saveBlob(Blob blob);

  @override
  Future<Blob?> getBlob(Map<String, Object?> properties);

  @override
  Future<void> inBatch(FutureOr<void> Function() fn);

  @Deprecated('Use defaultCollection.setDocumentExpiration instead.')
  @override
  Future<void> setDocumentExpiration(String id, DateTime? expiration);

  @Deprecated('Use defaultCollection.getDocumentExpiration instead.')
  @override
  Future<DateTime?> getDocumentExpiration(String id);

  @Deprecated('Use defaultCollection.addChangeListener instead.')
  @override
  Future<ListenerToken> addChangeListener(DatabaseChangeListener listener);

  @Deprecated('Use defaultCollection.addDocumentChangeListener instead.')
  @override
  Future<ListenerToken> addDocumentChangeListener(
    String id,
    DocumentChangeListener listener,
  );

  @Deprecated('Use defaultCollection.removeChangeListener instead.')
  @override
  Future<void> removeChangeListener(ListenerToken token);

  @Deprecated('Use defaultCollection.changes instead.')
  @override
  AsyncListenStream<DatabaseChange> changes();

  @Deprecated('Use defaultCollection.documentChanges instead.')
  @override
  AsyncListenStream<DocumentChange> documentChanges(String id);

  @override
  Future<void> performMaintenance(MaintenanceType type);

  @override
  Future<void> changeEncryptionKey(EncryptionKey? newKey);

  @Deprecated('Use defaultCollection.indexes instead.')
  @override
  Future<List<String>> get indexes;

  @Deprecated('Use defaultCollection.createIndex instead.')
  @override
  Future<void> createIndex(String name, Index index);

  @Deprecated('Use defaultCollection.deleteIndex instead.')
  @override
  Future<void> deleteIndex(String name);
}
