import 'dart:async';
import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import 'document/document.dart';
import 'errors.dart';
import 'fleece/fleece.dart' as fl;
import 'query.dart';
import 'support/native_object.dart';
import 'support/resource.dart';
import 'support/streams.dart';
import 'support/utils.dart';

late final _bindings = CBLBindings.instance.database;

/// Database configuration options.
class DatabaseConfiguration {
  /// Creates a [DatabaseConfiguration].
  DatabaseConfiguration({
    this.directory,
  });

  /// The parent directory of the database.
  final String? directory;

  DatabaseConfiguration copyWith({
    String? directory,
  }) =>
      DatabaseConfiguration(
        directory: directory ?? this.directory,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DatabaseConfiguration &&
          runtimeType == other.runtimeType &&
          directory == other.directory;

  @override
  int get hashCode => directory.hashCode;

  @override
  String toString() => 'DatabaseConfiguration('
      'directory: $directory'
      ')';
}

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
  String get expressions;
}

/// Value indexes speed up queries by making it possible to look up property
/// (or expression) values without scanning every document.
///
/// They're just like regular indexes in SQL or N1QL. Multiple expressions are
/// supported; the first is the primary key, second is secondary. Expressions
/// must evaluate to scalar types (boolean, number, string).
class ValueIndex extends Index {
  ValueIndex(this.expressions);

  @override
  final String expressions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValueIndex &&
          runtimeType == other.runtimeType &&
          expressions == other.expressions;

  @override
  int get hashCode => expressions.hashCode;

  @override
  String toString() => 'ValueIndex($expressions)';
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
    this.expressions, {
    this.ignoreAccents = false,
    this.language,
  });

  @override
  final String expressions;

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
          expressions == other.expressions &&
          ignoreAccents == other.ignoreAccents &&
          language == other.language;

  @override
  int get hashCode =>
      expressions.hashCode ^ ignoreAccents.hashCode ^ language.hashCode;

  @override
  String toString() => 'FullTextIndex($expressions, '
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
typedef SaveConflictHandler = bool Function(
  MutableDocument documentBeingSaved,
  Document? conflictingDocument,
);

/// A database is both a filesystem object and a container for documents.
abstract class Database with ClosableResource {
  /// Returns true if a database with the given [name] exists in the given
  /// [directory].
  ///
  /// [name] is the database name (without the ".cblite2" extension.).
  ///
  /// [directory] is the directory containing the database.
  static bool exists(String name, {required String directory}) =>
      _bindings.databaseExists(name, directory);

  /// Copies a database file to a new location, and assigns it a new internal
  /// UUID to distinguish it from the original database when replicating.
  ///
  /// [fromPath] is the full filesystem path to the original database
  /// (including extension).
  ///
  /// [toName] is the new database name (without the ".cblite2" extension.).
  ///
  /// [directory] is the directory containing the copied database.
  static void copy({
    required String fromPath,
    required String toName,
    String? directory,
  }) =>
      _bindings.copyDatabase(fromPath, toName, directory);

  /// Deletes a database file.
  ///
  /// If the database file is open, an error is thrown.
  ///
  /// [name] is the database name (without the ".cblite2" extension.)
  ///
  /// [directory] is the directory containing the database.
  static bool remove(String name, {required String directory}) =>
      _bindings.deleteDatabase(name, directory);

  /// Opens a database, or creates it if it doesn't exist yet, returning a new
  /// [Database] instance.
  ///
  /// It's OK to open the same database file multiple times. Each [Database]
  /// instance is independent of the others (and must be separately closed and
  /// released.)
  ///
  /// [name] is the database name (without the ".cblite2" extension.).
  ///
  /// [config] contains the database configuration (directory and encryption
  /// option.)
  static Database open(
    String name, {
    DatabaseConfiguration? config,
  }) {
    return DatabaseImpl(name, config, _bindings.open(name, config?.directory));
  }

  // === Database ==============================================================

  /// The database's name.
  String get name;

  /// The database's full filesystem path.
  String get path;

  /// The number of documents in the database.
  int get count;

  /// The database's configuration, as given when it was opened.
  ///
  /// The encryption key is not filled in, for security reasons.
  DatabaseConfiguration get config;

  /// Closes and deletes this database.
  ///
  /// If there are any other connections to the database, an error is thrown.
  Future<void> delete();

  /// Performs database maintenance.
  ///
  /// When [MaintenanceType.integrityCheck] is performed and the check fails,
  /// a [CouchbaseLiteException] with [CouchbaseLiteErrorCode.corruptData] is
  /// thrown.
  ///
  /// See:
  /// - [MaintenanceType] for the types of maintenance the database can perform.
  void performMaintenance(MaintenanceType type);

  /// Begins a batch operation, similar to a transaction.
  ///
  /// You must later call [endBatch] to end (commit) the batch.
  ///
  /// Multiple writes are much faster when grouped inside a single batch.
  /// Changes will not be visible to other CBLDatabase instances on the same
  /// database until the batch operation ends. Batch operations can nest.
  /// Changes are not committed until the outer batch ends.
  void beginBatch();

  /// Ends a batch operation.
  ///
  /// This must be called after [beginBatch].
  void endBatch();

  // === Documents =============================================================

  /// Reads a document from the database, creating a new (immutable) [Document]
  /// object.
  ///
  /// Returns `null` if no document with [id] exists.
  Document? getDocument(String id);

  /// Reads a document from the database, in mutable form that can be updated
  /// and saved.
  ///
  /// This function is otherwise identical to [getDocument].
  MutableDocument? getMutableDocument(String id);

  /// Saves a (mutable) document to the database.
  ///
  /// If a conflicting revision has been saved since doc was loaded, the
  /// concurrency parameter specifies whether the save should fail, or the
  /// conflicting revision should be overwritten with the revision being saved.
  /// If you need finer-grained control, call [saveDocumentResolving]
  /// instead.
  void saveDocument(
    MutableDocument doc, {
    ConcurrencyControl concurrency = ConcurrencyControl.failOnConflict,
  });

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
  void saveDocumentResolving(
    MutableDocument doc,
    SaveConflictHandler conflictHandler,
  );

  /// Deletes this document from the database.
  ///
  /// Deletions are replicated.
  void deleteDocument(
    Document doc, [
    ConcurrencyControl concurrency = ConcurrencyControl.failOnConflict,
  ]);

  /// Purges a document, given only its [id].
  ///
  /// This removes all traces of the document from the database. Purges are not
  /// replicated. If the document is changed on a server, it will be re-created
  /// when pulled.
  ///
  /// To delete a [Document], use [deleteDocument] method.
  bool purgeDocumentById(String id);

  /// Returns the time, if any, at which a given document will expire and be
  /// purged.
  ///
  /// Documents don't normally expire; you have to call [setDocumentExpiration]
  /// to set a document's expiration time.
  DateTime? getDocumentExpiration(String id);

  /// Sets or clears the expiration time of a document.
  ///
  /// When [time] is `null` the document will never expire.
  void setDocumentExpiration(String id, DateTime? time);

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
  Stream<void> changesOfDocument(String id);

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
  Stream<List<String>> changesOfAllDocuments();

  // === Queries ===============================================================

  /// Creates a new query by compiling the [queryDefinition].
  ///
  /// This is fast, but not instantaneous. If you need to run the same query
  /// many times, keep the [Query] around instead of compiling it each time. If
  /// you need to run related queries with only some values different, create
  /// one query with placeholder parameter(s), and substitute the desired
  /// value(s) with [Query.parameters] each time you run the query.
  ///
  /// See:
  /// - [Query] for how to write and use queries.
  Query query(QueryDefinition queryDefinition);

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
  void createIndex(String name, Index index);

  /// Deletes an index given its name.
  void deleteIndex(String name);

  /// Returns the names of the indexes on this database, as an array of strings.
  List<String> indexNames();
}

class DatabaseImpl extends CblObject<CBLDatabase>
    with ClosableResourceMixin
    implements Database {
  DatabaseImpl(
    this._debugName,
    DatabaseConfiguration? config,
    Pointer<CBLDatabase> pointer,
  )   : _config = config,
        super(
          pointer,
          debugName: 'Database($_debugName)',
        );

  final String _debugName;

  final DatabaseConfiguration? _config;

  var _deleteWhenClosing = false;

  // === Database ==============================================================

  @override
  String get name => useSync(() => native.call(_bindings.name));

  @override
  String get path => useSync(() => native.call(_bindings.path));

  @override
  int get count => useSync(() => native.call(_bindings.count));

  @override
  DatabaseConfiguration get config =>
      _config ??
      (throw StateError('Database was created without configuration.'));

  @override
  Future<void> delete() async {
    _deleteWhenClosing = true;
    await close();
  }

  @override
  void performMaintenance(MaintenanceType type) =>
      useSync(() => native.call((pointer) => _bindings.performMaintenance(
            pointer,
            type.toCBLMaintenanceType(),
          )));

  @override
  void beginBatch() => useSync(() => native.call(_bindings.beginTransaction));

  @override
  void endBatch() => useSync(
      () => native.call((pointer) => _bindings.endTransaction(pointer, true)));

  @override
  Future<void> performClose() async {
    if (_deleteWhenClosing) {
      native.call(_bindings.delete);
    }
  }

  // === Documents =============================================================

  @override
  Document? getDocument(String id) => useSync(() => native
      .call((pointer) => _bindings.getDocument(pointer, id))
      ?.let((pointer) => DocumentImpl(
            database: this,
            doc: pointer,
            debugCreator: 'Database.getDocument()',
          )));

  @override
  MutableDocument? getMutableDocument(String id) => useSync(() => native
      .call((pointer) => _bindings.getMutableDocument(pointer, id))
      ?.let((pointer) => MutableDocumentImpl(
            database: this,
            doc: pointer,
            debugCreator: 'Database.getMutableDocument()',
          )));

  @override
  void saveDocument(
    covariant MutableDocumentImpl doc, {
    ConcurrencyControl concurrency = ConcurrencyControl.failOnConflict,
  }) =>
      useSync(() {
        doc.database = this;
        doc.flushProperties();
        runNativeCalls(() {
          _bindings.saveDocumentWithConcurrencyControl(
            native.pointer,
            doc.native.pointer.cast(),
            concurrency.toCBLConcurrencyControl(),
          );
        });
      });

  @override
  void saveDocumentResolving(
    covariant MutableDocumentImpl doc,
    SaveConflictHandler conflictHandler,
  ) =>
      useSync(() {
        doc.database = this;
        doc.flushProperties();

        bool _conflictHandler(
          Pointer<CBLMutableDocument> _,
          Pointer<CBLDocument>? conflictingDocument,
        ) {
          final _conflictingDocument = conflictingDocument?.let(
            (pointer) => DocumentImpl(
              database: this,
              doc: pointer,
              adopt: false,
              debugCreator: 'SaveConflictHandler(conflictingDocument)',
            ),
          );

          final decision = conflictHandler(doc, _conflictingDocument);

          doc.flushProperties();

          return decision;
        }

        runNativeCalls(() => _bindings.saveDocumentWithConflictHandler(
              native.pointer,
              doc.native.pointer.cast(),
              _conflictHandler,
            ));
      });

  @override
  void deleteDocument(
    covariant DocumentImpl doc, [
    ConcurrencyControl concurrency = ConcurrencyControl.failOnConflict,
  ]) =>
      useSync(() => runNativeCalls(() {
            _bindings.deleteDocumentWithConcurrencyControl(
              native.pointer,
              doc.native.pointer,
              concurrency.toCBLConcurrencyControl(),
            );
          }));

  @override
  bool purgeDocumentById(String id) => useSync(
      () => native.call((pointer) => _bindings.purgeDocumentByID(pointer, id)));

  @override
  DateTime? getDocumentExpiration(String id) => useSync(() =>
      native.call((pointer) => _bindings.getDocumentExpiration(pointer, id)));

  @override
  void setDocumentExpiration(String id, DateTime? time) => useSync(() => native
      .call((pointer) => _bindings.setDocumentExpiration(pointer, id, time)));

  // === Changes ===============================================================

  @override
  Stream<void> changesOfDocument(String id) =>
      useSync(() => CallbackStreamController<void, void>(
            parent: this,
            startStream: (callback) => _bindings.addDocumentChangeListener(
              native.pointer,
              id,
              callback.native.pointer,
            ),
            createEvent: (_, arguments) => null,
          ).stream);

  @override
  Stream<List<String>> changesOfAllDocuments() =>
      useSync(() => CallbackStreamController<List<String>, void>(
            parent: this,
            startStream: (callback) => _bindings.addChangeListener(
              native.pointer,
              callback.native.pointer,
            ),
            createEvent: (_, arguments) =>
                DatabaseChangeCallbackMessage.fromArguments(arguments)
                    .documentIds,
          ).stream);

  // === Queries ===============================================================

  @override
  Query query(QueryDefinition queryDefinition) => useSync(() => QueryImpl(
        database: this,
        language: queryDefinition.language,
        query: queryDefinition.queryString,
        debugCreator: 'Database.query()',
      ));

  // === Indexes ===============================================================

  @override
  void createIndex(String name, Index index) =>
      useSync(() => native.call((pointer) {
            if (index is ValueIndex) {
              _bindings.createIndex(
                pointer,
                name,
                CBLdart_IndexType.value,
                CBLQueryLanguage.json,
                index.expressions,
                null,
                null,
              );
            } else if (index is FullTextIndex) {
              _bindings.createIndex(
                pointer,
                name,
                CBLdart_IndexType.fullText,
                CBLQueryLanguage.json,
                index.expressions,
                index.ignoreAccents,
                index.language,
              );
            } else {
              throw UnimplementedError(
                '${index.runtimeType} is not implemented',
              );
            }
          }));

  @override
  void deleteIndex(String name) => useSync(
      () => native.call((pointer) => _bindings.deleteIndex(pointer, name)));

  @override
  List<String> indexNames() => useSync(() {
        return fl.Array.fromPointer(
          native.call(_bindings.indexNames),
          adopt: true,
        ).map((it) => it.asString!).toList();
      });

  // === Object ================================================================

  @override
  String toString() => 'Database($_debugName)';
}

extension on MaintenanceType {
  CBLMaintenanceType toCBLMaintenanceType() => CBLMaintenanceType.values[index];
}

extension on ConcurrencyControl {
  CBLConcurrencyControl toCBLConcurrencyControl() =>
      CBLConcurrencyControl.values[index];
}
