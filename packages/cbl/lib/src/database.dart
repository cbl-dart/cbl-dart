import 'dart:ffi';
import 'dart:typed_data';

import 'package:collection/collection.dart';

import 'bindings/bindings.dart';
import 'document.dart';
import 'ffi_utils.dart';
import 'fleece.dart';
import 'native_callbacks.dart';
import 'query.dart';
import 'utils.dart';
import 'worker/handlers.dart';
import 'worker/worker.dart';

export 'bindings/bindings.dart'
    show EncryptionAlgorithm, DatabaseFlag, ConcurrencyControl;

// region Internal API

Database createDatabase({
  required Pointer<Void> pointer,
  required Worker worker,
}) =>
    Database._(pointer, worker);

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
typedef SaveConflictHandler = Future<bool> Function(
  MutableDocument documentBeingSaved,
  Document? conflictingDocument,
);

/// A document change listener lets you detect changes made to a specific
/// document after they are persisted to the database.
///
/// If there are multiple [Database] instances on the same database file, each
/// one's document listeners will be notified of changes made by other database
/// instances.
///
/// The listener receives the [database] containing the document and the [id]
/// of the document which changed.
typedef DocumentChangeListener = void Function(
  Database database,
  String id,
);

/// A database change listener lets you detect changes made to all documents in
/// a database. (If you only want to observe specific documents, use a
/// [Database.addDocumentChangeListener] instead.)
///
/// If there are multiple [Database] instances on the same database file, each
/// one's listeners will be notified of changes made by other database
/// instances.
///
/// Changes made to the database file by other processes will __not__ be
/// notified.
///
/// The listener receives the [database] containing the document and the [ids]
/// of the documents which changed.
typedef DatabaseChangeListener = void Function(
  Database database,
  List<String> ids,
);

/// A database is both a filesystem object and a container for documents.
class Database {
  static late final _bindings = CBLBindings.instance.database;
  static late final _callbacks = NativeCallbacks.instance;

  Database._(this._pointer, this._worker) {
    _bindings.bindToDartObject(this, _pointer);
  }

  final Pointer<Void> _pointer;
  late final int _address = _pointer.address;

  final Worker _worker;

  // === Database ==============================================================

  /// The database's name.
  Future<String> get name => _worker.makeRequest(GetDatabaseName(_address));

  /// The database's full filesystem path.
  Future<String> get path => _worker.makeRequest(GetDatabasePath(_address));

  /// The number of documents in the database.
  Future<int> get count => _worker.makeRequest(GetDatabaseCount(_address));

  /// The database's configuration, as given when it was opened.
  ///
  /// The encryption key is not filled in, for security reasons.
  Future<DatabaseConfiguration> get config =>
      _worker.makeRequest(GetDatabaseConfiguration(_address));

  /// Closes this database.
  Future<void> close() => _worker.makeRequest<void>(CloseDatabase(_address));

  /// Closes and deletes this database.
  ///
  /// If there are any other connections to the database, an error is thrown.
  Future<void> delete() => _worker.makeRequest<void>(DeleteDatabase(_address));

  /// Compacts the database file.
  Future<void> compact() =>
      _worker.makeRequest<void>(CompactDatabase(_address));

  /// Begins a batch operation, similar to a transaction.
  ///
  /// You must later call [endBatch] to end (commit) the batch.
  ///
  /// Multiple writes are much faster when grouped inside a single batch.
  /// Changes will not be visible to other CBLDatabase instances on the same
  /// database until the batch operation ends. Batch operations can nest.
  /// Changes are not committed until the outer batch ends.
  Future<void> beginBatch() =>
      _worker.makeRequest<void>(BeginDatabaseBatch(_address));

  /// Ends a batch operation.
  ///
  /// This must be called after [beginBatch].
  Future<void> endBatch() =>
      _worker.makeRequest<void>(EndDatabaseBatch(_address));

  /// Encrypts or decrypts a database, or changes its encryption key.
  ///
  /// If [encryptionKey] is `null`, or its [EncryptionKey.algorithm] is
  /// [EncryptionAlgorithm.none], the database will be decrypted.
  /// Otherwise the database will be encrypted with that key; if it was already
  /// encrypted, it will be re-encrypted with the new key.
  Future<void> rekey([EncryptionKey? encryptionKey]) =>
      _worker.makeRequest<void>(RekeyDatabase(_address, encryptionKey));

  // === Documents =============================================================

  /// Reads a document from the database, creating a new (immutable) [Document]
  /// object.
  ///
  /// Returns `null` if no document with [id] exists.
  Future<Document?> getDocument(String id) => _worker
      .makeRequest<int?>(GetDatabaseDocument(_address, id))
      .then((address) => address?.toPointer
          .let((it) => createDocument(pointer: it, worker: _worker)));

  /// Reads a document from the database, in mutable form that can be updated
  /// and saved.
  ///
  /// This function is otherwise identical to [getDocument].
  Future<MutableDocument?> getMutableDocument(String id) => _worker
      .makeRequest<int?>(GetDatabaseMutableDocument(_address, id))
      .then((address) => address?.toPointer
          .let((it) => createMutableDocument(pointer: it, worker: _worker)));

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
      _worker
          .makeRequest<int>(
              SaveDatabaseDocument(_address, doc.pointer.address, concurrency))
          .then((address) => address.toPointer
              .let((it) => createDocument(pointer: it, worker: _worker)));

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
        final documentBeingSavedPointer = (arguments[0] as int).toPointer;
        final conflictingDocumentPointer = (arguments[1] as int?)?.toPointer;

        final documentBeingSaved = createMutableDocument(
          pointer: documentBeingSavedPointer,
          retain: true,
        );
        final conflictingDocument = conflictingDocumentPointer?.let(
          (pointer) => createDocument(pointer: pointer, retain: true),
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

    return _worker
        .makeRequest<int>(SaveDatabaseDocumentResolving(
          _address,
          doc.pointer.address,
          conflictHandlerId,
        ))
        .then((address) =>
            createDocument(pointer: address.toPointer, worker: _worker))
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
      _worker.makeRequest(PurgeDatabaseDocumentById(_address, id));

  /// Returns the time, if any, at which a given document will expire and be
  /// purged.
  ///
  /// Documents don't normally expire; you have to call [setDocumentExpiration]
  /// to set a document's expiration time.
  Future<DateTime?> getDocumentExpiration(String id) =>
      _worker.makeRequest(GetDatabaseDocumentExpiration(_address, id));

  /// Sets or clears the expiration time of a document.
  ///
  /// When [time] is `null` the document will never expire.
  Future<void> setDocumentExpiration(String id, DateTime? time) => _worker
      .makeRequest<void>(SetDatabaseDocumentExpiration(_address, id, time));

  // === Listeners =============================================================

  /// Registers a document change [listener]. It will be called after the
  /// document with the given [id] has changed on disk.
  Future<void> addDocumentChangeListener(
    String id,
    DocumentChangeListener listener,
  ) {
    final listenerId = _callbacks.registerCallback<DocumentChangeListener>(
        listener, (listener, arguments, _) {
      final docId = arguments[0] as String;
      listener(this, docId);
    });

    return _worker
        .makeRequest(AddDocumentChangeListener(_address, id, listenerId));
  }

  /// Removes the document change [listener] so that it won't be called any
  /// more.
  Future<void> removeDocumentChangeListener(
      DocumentChangeListener listener) async {
    _callbacks.unregisterCallback(listener, runFinalizer: true);
  }

  /// Registers a database change [listener]. It will be called after one or
  /// more documents are changed on disk.
  Future<void> addChangeListener(DatabaseChangeListener listener) {
    int? listenerId;
    listenerId = _callbacks.registerCallback<DatabaseChangeListener>(listener,
        (listener, arguments, _) {
      listener(this, List.from(arguments));
    });

    return _worker.makeRequest(AddDatabaseChangeListener(_address, listenerId));
  }

  /// Removes the database change [listener] so that it won't be called any
  /// more.
  Future<void> removeChangeListener(DatabaseChangeListener listener) async {
    _callbacks.unregisterCallback(listener, runFinalizer: true);
  }

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
  }) async {
    if (language == QueryLanguage.N1QL) {
      queryString = removeWhiteSpaceFromQuery(queryString);
    }

    final address = await _worker
        .makeRequest<int>(CreateDatabaseQuery(_address, queryString, language));
    return createQuery(pointer: address.toPointer, worker: _worker);
  }

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
      _worker.makeRequest(CreateDatabaseIndex(_address, name, index));

  /// Deletes an index given its name.
  Future<void> deleteIndex(String name) async =>
      _worker.makeRequest(DeleteDatabaseIndex(_address, name));

  /// Returns the names of the indexes on this database, as an array of strings.
  Future<List<String>> indexNames() async => _worker
      .makeRequest<int>(GetDatabaseIndexNames(_address))
      .then((address) =>
          MutableArray.fromPointer(address.toPointer, retain: false)
              .map((it) => it.asString)
              .toList());
}
