import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:cbl_ffi/cbl_ffi.dart';
import 'package:collection/collection.dart';

import 'blob.dart';
import 'document.dart';
import 'fleece.dart';
import 'native_callbacks.dart';
import 'native_object.dart';
import 'query.dart';
import 'replicator.dart';
import 'replicator.dart' as repl;
import 'utils.dart';
import 'worker/cbl_worker.dart';

export 'package:cbl_ffi/cbl_ffi.dart'
    show EncryptionAlgorithm, DatabaseFlag, ConcurrencyControl;

// region Internal API

Database createDatabase({
  required String debugName,
  required Pointer<Void> pointer,
  required Worker worker,
}) =>
    Database._fromPointer(debugName, pointer, worker);

// endregion

/// Encryption key specified in a [DatabaseConfiguration].
class EncryptionKey {
  static const keyByteLength = 32;

  /// Creates an [EncryptionKey].
  EncryptionKey({
    this.algorithm = EncryptionAlgorithm.none,
    Uint8List? bytes,
  })  : bytes = bytes ?? Uint8List(keyByteLength),
        assert(bytes == null || bytes.lengthInBytes == keyByteLength);

  /// The encryption algorithm to use.
  final EncryptionAlgorithm algorithm;

  /// The raw key data.
  final Uint8List bytes;

  EncryptionKey copyWith({
    EncryptionAlgorithm? algorithm,
    Uint8List? bytes,
  }) =>
      EncryptionKey(
        algorithm: algorithm ?? this.algorithm,
        bytes: bytes ?? this.bytes,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EncryptionKey &&
          runtimeType == other.runtimeType &&
          algorithm == other.algorithm &&
          bytes == other.bytes;

  @override
  int get hashCode => algorithm.hashCode ^ bytes.hashCode;

  @override
  String toString() => 'EncryptionKey(algorithm: $algorithm, bytes: REDACTED)';
}

/// Database configuration options.
class DatabaseConfiguration {
  /// Creates a [DatabaseConfiguration].
  DatabaseConfiguration({
    this.directory,
    this.flags = const {DatabaseFlag.create},
    this.encryptionKey,
  });

  /// The parent directory of the database.
  final String? directory;

  /// Options for opening the database.
  final Set<DatabaseFlag> flags;

  /// The database's encryption key (if any).
  final EncryptionKey? encryptionKey;

  DatabaseConfiguration copyWith({
    String? directory,
    Set<DatabaseFlag>? flags,
    EncryptionKey? encryptionKey,
  }) =>
      DatabaseConfiguration(
        directory: directory ?? this.directory,
        flags: flags ?? this.flags,
        encryptionKey: encryptionKey ?? this.encryptionKey,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DatabaseConfiguration &&
          runtimeType == other.runtimeType &&
          directory == other.directory &&
          const SetEquality<DatabaseFlag>().equals(flags, other.flags) &&
          encryptionKey == other.encryptionKey;

  @override
  int get hashCode =>
      directory.hashCode ^ flags.hashCode ^ encryptionKey.hashCode;

  @override
  String toString() => 'DatabaseConfiguration('
      'directory: $directory, '
      'flags: $flags, '
      'encryptionKey: $encryptionKey'
      ')';
}

/// Indexes are used to speed up queries by allowing fast -- O(log n) -- lookup
/// of documents that have specific values or ranges of values. The values may
/// be properties, or expressions based on properties.
///
/// An index will speed up queries that use the expression it indexes, but it
/// takes up space in the database file, and it slows down document saves
/// slightly because it needs to be kept up to date when documents change.
///
/// Tuning a database with indexes can be a tricky task. Fortunately, a lot has
/// been written about it in the relational-database (SQL) realm, and much of
/// that advice holds for Couchbase Lite. You may find SQLite's documentation
/// particularly helpful since Couchbase Lite's querying is based on SQLite.
///
/// Two types of indexes are currently supported:
/// - [ValueIndex]
/// - [FullTextIndex]
///
/// See:
/// - [Query.explain] for tuning performance with indexes.
abstract class Index {
  /// A JSON array describing each column of the index.
  ///
  /// The language to describe an index in, is a subset of the
  /// JSON query language [schema](https://github.com/couchbase/couchbase-lite-core/wiki/JSON-Query-Schema).
  ///
  /// See:
  /// - [JSON Query - Indexes](https://github.com/couchbase/couchbase-lite-core/wiki/JSON-Query-Schema#9-indexes)
  String get keyExpressions;
}

/// Value indexes speed up queries by making it possible to look up property
/// (or expression) values without scanning every document.
///
/// They're just like regular indexes in SQL or N1QL. Multiple expressions are
/// supported; the first is the primary key, second is secondary. Expressions
/// must evaluate to scalar types (boolean, number, string).
class ValueIndex extends Index {
  ValueIndex(this.keyExpressions);

  @override
  final String keyExpressions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValueIndex &&
          runtimeType == other.runtimeType &&
          keyExpressions == other.keyExpressions;

  @override
  int get hashCode => super.hashCode ^ keyExpressions.hashCode;

  @override
  String toString() => 'ValueIndex($keyExpressions)';
}

/// Full-Text Search (FTS) indexes enable fast search of natural-language words
/// or phrases by using the `MATCH` operator in a query.
///
/// A FTS index is **required** for full-text search: a query with a `MATCH`
/// operator will fail to compile unless there is already a FTS index for the
/// property/expression being matched. Only a single expression is currently
/// allowed, and it must evaluate to a string.
class FullTextIndex extends Index {
  FullTextIndex(
    this.keyExpressions, {
    this.ignoreAccents = false,
    this.language,
  });

  @override
  final String keyExpressions;

  /// Should diacritical marks (accents) be ignored?
  /// Defaults to `false`. Generally this should be left `false` for non-English
  /// text.
  final bool ignoreAccents;

  /// The dominant language.
  ///
  /// Setting this enables word stemming, i.e. matching different cases of the
  /// same word ("big" and "bigger", for instance) and ignoring common
  /// "stop-words" ("the", "a", "of", etc.)
  ///
  /// Can be an ISO-639 language code or a lowercase (English) language name;
  /// supported languages are: da/danish, nl/dutch, en/english, fi/finnish,
  /// fr/french, de/german, hu/hungarian, it/italian, no/norwegian,
  /// pt/portuguese, ro/romanian, ru/russian, es/spanish, sv/swedish,
  /// tr/turkish.
  ///
  /// If left `null`,  or set to an unrecognized language, no language-specific
  /// behaviors such as stemming and stop-word removal occur.
  final String? language;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FullTextIndex &&
          runtimeType == other.runtimeType &&
          keyExpressions == other.keyExpressions &&
          ignoreAccents == other.ignoreAccents &&
          language == other.language;

  @override
  int get hashCode =>
      super.hashCode ^
      keyExpressions.hashCode ^
      ignoreAccents.hashCode ^
      language.hashCode;

  @override
  String toString() => 'FullTextIndex($keyExpressions, '
      'ignoreAccents: $ignoreAccents, '
      'language: $language)';
}

/// Custom conflict handler for saving or deleting a document.
///
/// This handler is called if the save would cause a conflict, i.e. if the
/// document in the database has been updated (probably by a pull replicator, or
/// by application code) since it was loaded into the [Document] being saved.
///
/// The [documentBeingSaved] (same as the parameter you passed to
/// [Database.saveDocumentResolving].) may be modify by the callback as
/// necessary to resolve the conflict.
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
/// - [Database.saveDocumentResolving] for saving a [Document] with a custom
///   conflict handler.
typedef SaveConflictHandler = FutureOr<bool> Function(
  MutableDocument documentBeingSaved,
  Document? conflictingDocument,
);

/// A database is both a filesystem object and a container for documents.
class Database extends NativeResource<WorkerObject<Void>> {
  static late final _callbacks = NativeCallbacks.instance;

  Database._fromPointer(this._debugName, Pointer<Void> pointer, Worker worker)
      : super(CblRefCountedWorkerObject(
          pointer,
          worker,
          release: true,
          retain: false,
        ));

  final String _debugName;

  // === Database ==============================================================

  /// The database's name.
  Future<String> get name =>
      native.execute((address) => GetDatabaseName(address));

  /// The database's full filesystem path.
  Future<String> get path =>
      native.execute((address) => GetDatabasePath(address));

  /// The number of documents in the database.
  Future<int> get count =>
      native.execute((address) => GetDatabaseCount(address));

  /// The database's configuration, as given when it was opened.
  ///
  /// The encryption key is not filled in, for security reasons.
  Future<DatabaseConfiguration> get config =>
      native.execute((address) => GetDatabaseConfiguration(address));

  /// Closes this database.
  Future<void> close() async {
    await native.execute((address) => CloseDatabase(address));
    await native.worker.stop();
  }

  /// Closes and deletes this database.
  ///
  /// If there are any other connections to the database, an error is thrown.
  Future<void> delete() async {
    await native.execute((address) => DeleteDatabase(address));
    await native.worker.stop();
  }

  /// Compacts the database file.
  Future<void> compact() =>
      native.execute((address) => CompactDatabase(address));

  /// Begins a batch operation, similar to a transaction.
  ///
  /// You must later call [endBatch] to end (commit) the batch.
  ///
  /// Multiple writes are much faster when grouped inside a single batch.
  /// Changes will not be visible to other CBLDatabase instances on the same
  /// database until the batch operation ends. Batch operations can nest.
  /// Changes are not committed until the outer batch ends.
  Future<void> beginBatch() =>
      native.execute((address) => BeginDatabaseBatch(address));

  /// Ends a batch operation.
  ///
  /// This must be called after [beginBatch].
  Future<void> endBatch() =>
      native.execute((address) => EndDatabaseBatch(address));

  /// Encrypts or decrypts a database, or changes its encryption key.
  ///
  /// If [encryptionKey] is `null`, or its [EncryptionKey.algorithm] is
  /// [EncryptionAlgorithm.none], the database will be decrypted.
  /// Otherwise the database will be encrypted with that key; if it was already
  /// encrypted, it will be re-encrypted with the new key.
  Future<void> rekey([EncryptionKey? encryptionKey]) =>
      native.execute((address) => RekeyDatabase(address, encryptionKey));

  // === Documents =============================================================

  /// Reads a document from the database, creating a new (immutable) [Document]
  /// object.
  ///
  /// Returns `null` if no document with [id] exists.
  Future<Document?> getDocument(String id) => native
      .execute((address) => GetDatabaseDocument(address, id))
      .then((address) => address?.let((it) => createDocument(
            pointer: it.toPointer(),
            worker: native.worker,
            retain: false,
          )));

  /// Reads a document from the database, in mutable form that can be updated
  /// and saved.
  ///
  /// This function is otherwise identical to [getDocument].
  Future<MutableDocument?> getMutableDocument(String id) => native
      .execute((address) => GetDatabaseMutableDocument(address, id))
      .then((address) => address?.let((it) => createMutableDocument(
            pointer: it.toPointer(),
            worker: native.worker,
            retain: false,
            isNew: false,
          )));

  /// Saves a (mutable) document to the database.
  ///
  /// If a conflicting revision has been saved since doc was loaded, the
  /// concurrency parameter specifies whether the save should fail, or the
  /// conflicting revision should be overwritten with the revision being saved.
  /// If you need finer-grained control, call [saveDocumentResolving]
  /// instead.
  Future<Document> saveDocument(
    MutableDocument doc, {
    ConcurrencyControl concurrency = ConcurrencyControl.failOnConflict,
  }) =>
      native
          .execute((address) => SaveDatabaseDocument(
                address,
                doc.native.pointer.address,
                concurrency,
              ))
          .then((address) => createDocument(
                pointer: address.toPointer(),
                worker: native.worker,
                retain: false,
              ));

  /// This function is the same as [saveDocument], except that it allows for
  /// custom conflict handling in the event that the document has been updated
  /// since [doc] was loaded.
  ///
  /// In case of a conflict the provided [conflictHandler] is asked to resolve
  /// the conflict.
  ///
  /// The method returns an updated document reflecting the saved changes.
  ///
  /// See:
  /// - [SaveConflictHandler] for implementing the conflict handler.
  Future<Document> saveDocumentResolving(
    MutableDocument doc,
    SaveConflictHandler conflictHandler,
  ) async {
    // Couchbase crashes when a document that has not been pulled out of the
    // database is used with conflict resolution.
    assert(!doc.isNew, 'new documents must be saved with `saveDocument`');

    final conflictHandlerId = _callbacks.registerCallback<SaveConflictHandler>(
      conflictHandler,
      (handler, arguments, result) {
        // Build arguments
        final documentBeingSavedPointer = (arguments[0] as int).toPointer();
        final conflictingDocumentPointer = (arguments[1] as int?)?.toPointer();

        final documentBeingSaved = createMutableDocument(
          pointer: documentBeingSavedPointer,
          retain: true,
          isNew: false,
          worker: null,
        );
        final conflictingDocument = conflictingDocumentPointer?.let(
          (pointer) => createDocument(
            pointer: pointer,
            retain: true,
            worker: null,
          ),
        );

        Future<void> invokeHandler() async {
          // In case the handler throws an error we are canceling the save.
          var decision = false;

          // We don't swallow exceptions because handlers should not throw and
          // this way the they are visible to the developer as an unhandled
          // exception.
          try {
            decision = await handler(documentBeingSaved, conflictingDocument);
          } finally {
            result!(decision);
          }
        }

        invokeHandler();
      },
    );

    return native
        .execute((address) => SaveDatabaseDocumentResolving(
              address,
              doc.native.pointer.address,
              conflictHandlerId,
            ))
        .then((address) => createDocument(
              pointer: address.toPointer(),
              worker: native.worker,
              retain: false,
            ))
        .whenComplete(() => _callbacks.unregisterCallback(conflictHandler));
  }

  /// Purges a document, given only its ID.
  ///
  /// This removes all traces of the document from the database. Purges are not
  /// replicated. If the document is changed on a server, it will be re-created
  /// when pulled.
  ///
  /// To delete a [Document], load it and call its [Document.delete] method.
  Future<bool> purgeDocumentById(String id) =>
      native.execute((address) => PurgeDatabaseDocumentById(address, id));

  /// Returns the time, if any, at which a given document will expire and be
  /// purged.
  ///
  /// Documents don't normally expire; you have to call [setDocumentExpiration]
  /// to set a document's expiration time.
  Future<DateTime?> getDocumentExpiration(String id) =>
      native.execute((address) => GetDatabaseDocumentExpiration(address, id));

  /// Sets or clears the expiration time of a document.
  ///
  /// When [time] is `null` the document will never expire.
  Future<void> setDocumentExpiration(String id, DateTime? time) => native
      .execute((address) => SetDatabaseDocumentExpiration(address, id, time));

  // === Changes ===============================================================

  /// Creates a stream that emits an event for each change made to a specific
  /// document after the change has been persisted to the database.
  ///
  /// The stream is as single subscription stream and buffers events when
  /// paused.
  ///
  /// If there are multiple [Database] instances on the same database file,
  /// subscribers from one database will be notified of changes made by other
  /// database instances.
  ///
  /// Changes made to the database file by other processes will __not__ be
  /// notified.
  Stream<void> changesOfDocument(String id) => callbackStream<void, void>(
        worker: native.worker,
        createWorkerRequest: (callbackId) => AddDocumentChangeListener(
          native.pointerUnsafe.address,
          id,
          callbackId,
        ),
        createEvent: (_, arguments) => null,
      );

  /// Creates a stream that emits a list of document ids each time documents
  /// in this databse have changed.
  ///
  /// If you only want to observe specific documents, use a [changesOfDocument]
  /// instead.
  ///
  /// If there are multiple [Database] instances on the same database file, each
  /// one's listeners will be notified of changes made by other database
  /// instances.
  ///
  /// Changes made to the database file by other processes will __not__ be
  /// notified.
  Stream<List<String>> changesOfAllDocuments() =>
      callbackStream<List<String>, void>(
        worker: native.worker,
        createWorkerRequest: (callbackId) =>
            AddDatabaseChangeListener(native.pointerUnsafe.address, callbackId),
        createEvent: (_, arguments) => List.from(arguments),
      );

  // === Queries ===============================================================

  /// Creates a new query by compiling the [queryString].
  ///
  /// This is fast, but not instantaneous. If you need to run the same query
  /// many times, keep the [Query] around instead of compiling it each time. If
  /// you need to run related queries with only some values different, create
  /// one query with placeholder parameter(s), and substitute the desired
  /// value(s) with [Query.setParameters] each time you run the query.
  ///
  /// {@macro cbl.Query.language}
  ///
  /// See:
  /// - [QueryLanguage] for the available query languages.
  /// - [Query] for how to write and use queries.
  Future<Query> query(
    String queryString, {
    QueryLanguage language = QueryLanguage.N1QL,
  }) async =>
      createQuery(
        db: native,
        queryString: queryString,
        language: language,
      );

  // === Indexes ===============================================================

  /// Creates a database index.
  ///
  /// Indexes are persistent.
  ///
  /// If an identical index with that name already exists, nothing happens (and
  /// no error is thrown.)
  ///
  /// If a non-identical index with that name already exists, it is deleted and
  /// re-created.
  Future<void> createIndex(String name, Index index) =>
      native.execute((address) => CreateDatabaseIndex(address, name, index));

  /// Deletes an index given its name.
  Future<void> deleteIndex(String name) async =>
      native.execute((address) => DeleteDatabaseIndex(address, name));

  /// Returns the names of the indexes on this database, as an array of strings.
  Future<List<String>> indexNames() async => native
      .execute((address) => GetDatabaseIndexNames(address))
      .then((address) => MutableArray.fromPointer(
            address.toPointer(),
            release: true,
            retain: false,
          ).map((it) => it.asString).toList());

  // === Blobs =================================================================

  /// The [BlobManager] associated with this Database.
  ///
  /// See:
  /// - [Blob] for more about what a Blob is.
  late BlobManager blobManager = createBlobManager(db: native);

  // === Replicator ============================================================

  /// Creates a [Replicator] for this database, with the given configuration.
  Future<Replicator> createReplicator(
    ReplicatorConfiguration config,
  ) =>
      repl.createReplicator(db: native, config: config);

  // === Object ================================================================

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Database &&
          other.runtimeType == other.runtimeType &&
          native == other.native;

  @override
  int get hashCode => super.hashCode ^ native.hashCode;

  @override
  String toString() => 'Database(name: $_debugName)';
}
