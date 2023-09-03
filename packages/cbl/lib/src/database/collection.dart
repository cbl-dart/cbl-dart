// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import '../document.dart';
import '../errors.dart';
import '../query/index/index.dart';
import '../support/listener_token.dart';
import '../support/streams.dart';
import 'collection_change.dart';
import 'database.dart';
import 'database_change.dart';
import 'document_change.dart';
import 'scope.dart';

/// Custom conflict handler for saving a document.
///
/// {@template cbl.SaveConflictHandler}
/// This handler is called if the save would cause a conflict, i.e. if the
/// document in the database has been updated (probably by a pull replicator, or
/// by application code) since it was loaded into the [Document] being saved.
///
/// The [documentBeingSaved] (same as the parameter you passed to
/// [Collection.saveDocumentWithConflictHandler].) may be modify by the callback
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
/// - [Collection.saveDocumentWithConflictHandler] for saving a [Document] with
///   a custom conflict handler.
///
/// {@category Database}
typedef SaveConflictHandler = FutureOr<bool> Function(
  MutableDocument documentBeingSaved,
  Document? conflictingDocument,
);

/// Custom sync conflict handler for saving a document.
///
/// {@macro cbl.SaveConflictHandler}
///
/// See also:
///
/// - [SyncCollection.saveDocumentWithConflictHandlerSync] for saving a
///   [Document] with a custom sync conflict handler.
///
/// {@category Database}
typedef SyncSaveConflictHandler = bool Function(
  MutableDocument documentBeingSaved,
  Document? conflictingDocument,
);

/// Listener which is called when one or more [Document]s in a [Collection] have
/// changed.
///
/// {@category Database}
typedef CollectionChangeListener = void Function(CollectionChange change);

/// Listener which is called when one or more [Document]s in a [Database] have
/// changed.
///
/// {@category Database}
typedef DatabaseChangeListener = void Function(DatabaseChange change);

/// Listener which is called when a single [Document] has changed.
///
/// {@category Database}
typedef DocumentChangeListener = void Function(DocumentChange change);

/// A container for [Document]s.
///
/// A collection can be thought as a table in the relational database. Each
/// collection belongs to a [Scope] which is simply a namespace, and has a name
/// which is unique within its [Scope].
///
/// When a new [Database] is created, a default collection named `_default` will
/// be automatically created. The default collection is created under the
/// default scope named `_default`. The name of the default collection and scope
/// can be referenced by using [Collection.defaultName] and [Scope.defaultName]
/// constant.
///
/// **Note**: The default collection cannot be deleted.
///
/// When creating a new collection, the collection name, and the scope name are
/// required. The naming rules of collections and scopes are as follows:
///
/// - Must be between 1 and 251 characters in length.
/// - Can only contain the characters A-Z, a-z, 0-9, and the symbols \_, -, and
///   %.
/// - Cannot start with \_ or %.
/// - Both scope and collection names are case sensitive.
///
/// ## Lifecycle
///
/// A collection and its reference remain valid until either the database is
/// closed or the collection itself is deleted. Once deleted [Collection] will
/// throw a [DatabaseException] with the [DatabaseErrorCode.notOpen] code when
/// accessing its APIs.
///
/// ## Legacy Database and API
///
/// When opening a pre-collection database, the existing documents and indexes
/// in the database will be automatically migrated to the default collection.
///
/// Any pre-collection database APIs that refer to documents, listeners, and
/// indexes without specifying a collection such as [Database.document] will
/// implicitly operate on the default collection. In other words, they behave
/// exactly the way they used to, but collection-aware code should avoid them
/// and use the new collection APIs instead. These legacy APIs are deprecated
/// and will be removed eventually.
abstract class Collection {
  /// The name of the default collection.
  static const defaultName = '_default';

  /// The name of this collection.
  String get name;

  /// The [Scope] this collection belongs to.
  Scope get scope;

  /// The total number of documents in this collection.
  FutureOr<int> get count;

  /// Returns the [Document] with the given [id], if it exists.
  FutureOr<Document?> document(String id);

  /// Returns the [DocumentFragment] for the [Document] with the given [id].
  FutureOr<DocumentFragment> operator [](String id);

  /// Saves a [document] to this collection, resolving conflicts through
  /// [ConcurrencyControl].
  ///
  /// When write operations are executed concurrently, the last writer will win
  /// by default. In this case the result is always `true`.
  ///
  /// To fail on conflict instead, pass [ConcurrencyControl.failOnConflict] to
  /// [concurrencyControl]. In this case, if the document could not be saved the
  /// result is `false`. On success it is `true`.
  FutureOr<bool> saveDocument(
    MutableDocument document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]);

  /// Saves a [document] to this collection, resolving conflicts with a
  /// [conflictHandler].
  ///
  /// {@template cbl.Collection.saveDocumentWithConflictHandler}
  /// When write operations are executed concurrently and if conflicts occur,
  /// the [conflictHandler] will be called. Use the conflict handler to directly
  /// edit the [Document] to resolve the conflict. When the conflict handler
  /// returns `true`, the save method will save the edited document as the
  /// resolved document. If the conflict handler returns `false`, the save
  /// operation will be canceled with `false` as the result. If the conflict
  /// handler returns `true` or there is no conflict the result is `true`.
  /// {@endtemplate}
  FutureOr<bool> saveDocumentWithConflictHandler(
    MutableDocument document,
    SaveConflictHandler conflictHandler,
  );

  /// Deletes a [document] from this collection, resolving conflicts through
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

  /// Purges a [document] from this collection.
  ///
  /// This is more drastic than deletion: It removes all traces of the document.
  /// The purge will **not** be replicated to other databases.
  FutureOr<void> purgeDocument(Document document);

  /// Purges a [Document] from this collection by its [id].
  ///
  /// This is more drastic than deletion: It removes all traces of the document.
  /// The purge will **not** be replicated to other databases.
  FutureOr<void> purgeDocumentById(String id);

  /// Sets an [expiration] date for a [Document] by its [id].
  ///
  /// After the given date the document will be purged from the database.
  ///
  /// This is more drastic than deletion: It removes all traces of the document.
  /// The purge will **not** be replicated to other databases.
  FutureOr<void> setDocumentExpiration(String id, DateTime? expiration);

  /// Gets the expiration date of a [Document] by its [id], if it exists.
  FutureOr<DateTime?> getDocumentExpiration(String id);

  /// The names of all existing indexes for this collection.
  FutureOr<List<String>> get indexes;

  /// Creates a value or full-text search [index] with the given [name] for the
  /// documents in this collection.
  ///
  /// The name can be used for deleting the index. Creating a new different
  /// index with an existing index name will replace the old index; creating the
  /// same index with the same name is a no-op.
  FutureOr<void> createIndex(String name, Index index);

  /// Deletes the [Index] of the given [name].
  FutureOr<void> deleteIndex(String name);

  /// Adds a [listener] to be notified of all changes to [Document]s in this
  /// collection.
  ///
  /// {@template cbl.Collection.addChangeListener}
  ///
  /// ## Adding a listener
  ///
  /// If a [Future] is returned, the listener will only start listening after
  /// the [Future] has completed. Otherwise the listener is listening
  /// immediately after this method returns.
  ///
  /// ## Removing a listener
  ///
  /// The returned [ListenerToken] needs to be provided to
  /// [removeChangeListener], to remove the given listener. Regardless of
  /// whether a [Future] is returned or not, the listener immediately stops
  /// being called.
  ///
  /// {@endtemplate}
  ///
  /// See also:
  ///
  /// - [CollectionChange] for the change event given to [listener].
  /// - [changes] for alternatively listening to changes through a [Stream].
  /// - [addDocumentChangeListener] for listening for changes to a single
  ///   [Document].
  /// - [removeChangeListener] for removing a previously added listener.
  FutureOr<ListenerToken> addChangeListener(CollectionChangeListener listener);

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
  /// - [addChangeListener] for listening for changes to this collection.
  /// - [removeChangeListener] for removing a previously added listener.
  FutureOr<ListenerToken> addDocumentChangeListener(
    String id,
    DocumentChangeListener listener,
  );

  /// {@template cbl.Collection.removeChangeListener}
  /// Removes a previously added change listener.
  ///
  /// Pass in the [token] that was handed out when adding the listener.
  ///
  /// Regardless of whether a [Future] is returned or not, the listener
  /// immediately stops being called.
  ///
  /// {@endtemplate}
  ///
  /// See also:
  ///
  /// - [addChangeListener] for listening for changes to this collection.
  /// - [addDocumentChangeListener] for listening for changes to a single
  ///   [Document].
  FutureOr<void> removeChangeListener(ListenerToken token);

  /// Returns a [Stream] to be notified of all changes to [Document]s in this
  /// collection.
  ///
  /// This is an alternative stream based API for the [addChangeListener] API.
  ///
  /// {@template cbl.Collection.AsyncListenStream}
  ///
  /// ## AsyncListenStream
  ///
  /// If the stream is missing changes, check if the returned stream is an
  /// [AsyncListenStream]. This type of stream needs to perform some async work
  /// to be fully listening. You can wait for that moment by awaiting
  /// [AsyncListenStream.listening].
  ///
  /// {@endtemplate}
  Stream<CollectionChange> changes();

  /// Returns a [Stream] to be notified of changes to the [Document] with the
  /// given [id].
  ///
  /// This is an alternative stream based API for the
  /// [addDocumentChangeListener] API.
  ///
  /// {@macro cbl.Collection.AsyncListenStream}
  Stream<DocumentChange> documentChanges(String id);
}

/// A [Collection] with a primarily synchronous API.
///
/// {@category Database}
abstract class SyncCollection extends Collection {
  @override
  SyncScope get scope;

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
  /// {@macro cbl.Collection.saveDocumentWithConflictHandler}
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

  @override
  void setDocumentExpiration(String id, DateTime? expiration);

  @override
  DateTime? getDocumentExpiration(String id);

  @override
  List<String> get indexes;

  @override
  void createIndex(String name, Index index);

  @override
  void deleteIndex(String name);

  @override
  ListenerToken addChangeListener(CollectionChangeListener listener);

  @override
  ListenerToken addDocumentChangeListener(
    String id,
    DocumentChangeListener listener,
  );

  @override
  void removeChangeListener(ListenerToken token);
}

/// A [Collection] with a primarily asynchronous API.
///
/// {@category Database}
abstract class AsyncCollection extends Collection {
  @override
  AsyncScope get scope;

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
  Future<void> setDocumentExpiration(String id, DateTime? expiration);

  @override
  Future<DateTime?> getDocumentExpiration(String id);

  @override
  Future<List<String>> get indexes;

  @override
  Future<void> createIndex(String name, Index index);

  @override
  Future<void> deleteIndex(String name);

  @override
  Future<ListenerToken> addChangeListener(CollectionChangeListener listener);

  @override
  Future<ListenerToken> addDocumentChangeListener(
    String id,
    DocumentChangeListener listener,
  );

  @override
  Future<void> removeChangeListener(ListenerToken token);

  @override
  AsyncListenStream<CollectionChange> changes();

  @override
  AsyncListenStream<DocumentChange> documentChanges(String id);
}
