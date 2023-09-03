import 'dart:async';

import 'package:synchronized/synchronized.dart';

import '../document/document.dart';
import '../errors.dart';
import '../fleece/decoder.dart';
import '../fleece/dict_key.dart';
import '../support/utils.dart';
import '../typed_data.dart';
import '../typed_data/adapter.dart';
import 'collection.dart';
import 'database.dart';
import 'scope.dart';

/// Base that is mixed into all implementations of [Database].
mixin DatabaseBase<T extends DocumentDelegate> implements Database {
  /// The [TypedDataAdapter] of this database, if it is a typed database.
  ///
  /// It is configured with the types that are supported by this database.
  ///
  /// To safely access the adapter, you can use [useWithTypedData].
  TypedDataAdapter? get typedDataAdapter;

  TypedDataAdapter useWithTypedData() {
    final adapter = typedDataAdapter;
    if (adapter == null) {
      throw TypedDataException(
        'The database does not support typed data.',
        TypedDataErrorCode.typedDataNotSupported,
      );
    }
    return adapter;
  }

  /// The [DictKey]s that should be used when looking up properties in
  /// [Document]s that are stored in this database.
  ///
  /// Note: It is important to use the database specific [DictKey]s when
  /// accessing Fleece data from this database because each database has its own
  /// set of shared keys. [DictKey]s are optimized to make use of these keys and
  /// will lookup the wrong or no entries if used with the wrong set of shared
  /// keys.
  DictKeys get dictKeys;

  /// The [SharedKeysTable] that should be used when iterating over dictionaries
  /// in [Document]s that are stored in this database.
  ///
  /// The same note as for [dictKeys] applies here.
  SharedKeysTable get sharedKeysTable;

  /// Lock under which asynchronous transactions are executed.
  final asyncTransactionLock = Lock();

  /// Prepares [document] for being used with this database.
  ///
  /// If [syncProperties] is `true`, the [document]s properties are synced with
  /// its delegate.
  FutureOr<T> prepareDocument(
    DelegateDocument document, {
    bool syncProperties = true,
  }) =>
      defaultCollection
          .then((value) => (value as CollectionBase<T>).prepareDocument(
                document,
                syncProperties: syncProperties,
              ));

  @override
  FutureOr<D?> typedDocument<D extends TypedDocumentObject>(String id) {
    final adapter = useWithTypedData();

    // We resolve the factory before loading the actual document to check that
    // D is a recognized type early.
    final Factory<Document, D> factory;
    final bool isDynamic;
    if (D == TypedDocumentObject || D == TypedMutableDocumentObject) {
      final dynamicFactory = adapter.dynamicDocumentFactoryForType<D>(
        allowUnmatchedDocument: false,
      );
      factory = (document) => dynamicFactory(document)!;
      isDynamic = true;
    } else {
      factory = adapter.documentFactoryForType<D>();
      isDynamic = false;
    }

    return defaultCollection
        .then((collection) => collection.document(id))
        .then((doc) {
      if (doc == null) {
        return null;
      }

      if (!isDynamic) {
        // Check that the loaded document is of the correct type.
        adapter.checkDocumentIsOfType<D>(doc);
      }

      return factory(doc);
    });
  }

  /// Whether the current transaction belongs to this database, if one exists.
  bool get ownsCurrentTransaction => _Transaction.current?.database == this;

  /// Method to implement by by [Database] implementations to begin a new
  /// transaction.
  FutureOr<void> beginTransaction();

  /// Method to implement by by [Database] implementations to commit the current
  /// transaction.
  FutureOr<void> endTransaction({required bool commit});

  /// Runs [fn] in a synchronous transaction.
  ///
  /// If [requiresNewTransaction] is `true` any preexisting transaction causes
  /// an exception to be thrown.
  R runInTransactionSync<R>(
    R Function() fn, {
    bool requiresNewTransaction = false,
  }) =>
      _runInTransaction(
        fn,
        async: false,
        requiresNewTransaction: requiresNewTransaction,
      ) as R;

  /// Runs [fn] in an asynchronous transaction.
  ///
  /// If [requiresNewTransaction] is `true` any preexisting transaction causes
  /// an exception to be thrown.
  Future<R> runInTransactionAsync<R>(
    FutureOr<R> Function() fn, {
    bool requiresNewTransaction = false,
  }) =>
      _runInTransaction(
        fn,
        async: true,
        requiresNewTransaction: requiresNewTransaction,
      ) as Future<R>;

  FutureOr<R> _runInTransaction<R>(
    FutureOr<R> Function() fn, {
    bool requiresNewTransaction = false,
    required bool async,
  }) {
    final currentTransaction = _Transaction.current;
    if (currentTransaction != null) {
      if (requiresNewTransaction) {
        throw DatabaseException(
          'Cannot start a new transaction while another is already active.',
          DatabaseErrorCode.transactionNotClosed,
        );
      }

      currentTransaction
        // Check that the current transaction is for the correct database.
        ..checkDatabase(this)
        // Check that the current transaction is still open.
        ..checkIsActive();

      return fn();
    }

    if (!async && asyncTransactionLock.locked) {
      throw DatabaseException(
        'Cannot start a new synchronous transaction while an asynchronous '
        'transaction is still active.',
        DatabaseErrorCode.transactionNotClosed,
      );
    }

    final transaction = _Transaction(this);

    var commit = false;
    if (async) {
      return asyncTransactionLock.synchronized(() async {
        await beginTransaction();
        try {
          final result = await transaction.runWith(fn);
          commit = true;
          return result;
          // ignore: avoid_catches_without_on_clauses
        } finally {
          transaction.end();
          await endTransaction(commit: commit);
        }
      });
    } else {
      final startTransactionResult = beginTransaction();
      assert(startTransactionResult is! Future);
      try {
        final result = transaction.runWith(fn);
        commit = true;
        return result;
        // ignore: avoid_catches_without_on_clauses
      } finally {
        transaction.end();
        final endTransactionResult = endTransaction(commit: commit);
        assert(endTransactionResult is! Future);
      }
    }
  }
}

class _Transaction {
  _Transaction(this.database);

  static _Transaction? get current =>
      Zone.current[#_transaction] as _Transaction?;

  final Database database;

  bool get isActive => _isActive;
  var _isActive = true;

  T runWith<T>(T Function() fn) =>
      runZoned(fn, zoneValues: {#_transaction: this});

  void end() {
    _isActive = false;
  }

  void checkIsActive() {
    if (!isActive) {
      throw DatabaseException(
        'The associated transaction is not active anymore.',
        DatabaseErrorCode.notInTransaction,
      );
    }
  }

  void checkDatabase(Database other) {
    if (database != other) {
      throw DatabaseException(
        'The current transaction is for a different database.',
        DatabaseErrorCode.notInTransaction,
      );
    }
  }
}

abstract class SaveTypedDocumentBase<D extends TypedDocumentObject,
    MD extends TypedMutableDocumentObject> extends SaveTypedDocument<D, MD> {
  SaveTypedDocumentBase(this.database, this.document)
      :
        // This call ensures that the document type D is registered with the
        // database. This is why we call it, even though we may never need to
        // use the returned factory.
        // By calling useWithTypedData we also assert that database supports
        // typed data.
        _documentFactory =
            database.useWithTypedData().documentFactoryForType<D>();

  final DatabaseBase database;
  final TypedMutableDocumentObject<D, MD> document;
  final D Function(Document) _documentFactory;

  @override
  FutureOr<bool> withConcurrencyControl([
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]) {
    database.typedDataAdapter!.willSaveDocument(document);
    return database.defaultCollection
        .then((collection) => collection.saveDocument(
              document.internal as MutableDelegateDocument,
              concurrencyControl,
            ));
  }

  @override
  FutureOr<bool> withConflictHandler(
    TypedSaveConflictHandler<D, MD> conflictHandler,
  ) {
    database.typedDataAdapter!.willSaveDocument(document);
    return database.defaultCollection.then((collection) =>
        (collection as CollectionBase).saveDocumentWithConflictHandlerHelper(
          document.internal as MutableDelegateDocument,
          (documentBeingSaved, conflictingDocument) {
            assert(identical(documentBeingSaved, document.internal));
            return conflictHandler(
              document as MD,
              conflictingDocument?.let(_documentFactory),
            );
          },
        ));
  }
}

mixin ScopeBase implements Scope {
  DatabaseBase get database;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScopeBase &&
          runtimeType == other.runtimeType &&
          database.path == other.database.path &&
          name == other.name;

  @override
  int get hashCode => database.path.hashCode ^ name.hashCode;
}

mixin CollectionBase<T extends DocumentDelegate> implements Collection {
  @override
  ScopeBase get scope;

  DatabaseBase get database => scope.database;

  String get fullName => '${scope.name}.$name';

  /// Creates a [DocumentDelegate] from [oldDelegate] for a new document which
  /// is being used with this collection for the first time.
  ///
  /// The returned delegate implementation usually is specific to this
  /// implementation of [Collection].
  T createNewDocumentDelegate(DocumentDelegate oldDelegate);

  /// Prepares [document] for being used with this collection.
  ///
  /// If [syncProperties] is `true`, the [document]s properties are synced with
  /// its delegate.
  FutureOr<T> prepareDocument(
    DelegateDocument document, {
    bool syncProperties = true,
  }) {
    var delegate = document.delegate;
    if (delegate is! NewDocumentDelegate && delegate is! T) {
      throw ArgumentError.value(
        document,
        'document',
        'has already been used with another incompatible database',
      );
    }

    // Assign document to this collection.
    document.setCollection(this);

    // If document is new init delegate with collection specific implementation.
    if (delegate is NewDocumentDelegate) {
      document.setDelegate(
        createNewDocumentDelegate(delegate),
        updateProperties: false,
      );
    }

    delegate = document.delegate as T;

    // If required, sync document properties with delegate.
    if (syncProperties) {
      return document.writePropertiesToDelegate().then((_) => delegate as T);
    }

    return delegate;
  }

  /// Implements the algorithm to save a document with a [SaveConflictHandler].
  ///
  /// If the [conflictHandler] is synchronous and this collection is synchronous
  /// the result is also synchronous.
  FutureOr<bool> saveDocumentWithConflictHandlerHelper(
    MutableDelegateDocument documentBeingSaved,
    SaveConflictHandler conflictHandler,
  ) {
    // Implementing the conflict resolution in Dart, instead of using
    // the C implementation, allows us to make the conflict handler
    // asynchronous.

    var success = false;

    final done = syncOrAsync(() sync* {
      var retry = false;

      do {
        late bool noConflict;

        yield saveDocument(
          documentBeingSaved,
          ConcurrencyControl.failOnConflict,
        ).then((value) => noConflict = value);

        if (noConflict) {
          success = true;
          retry = false;
        } else {
          // Load the conflicting document.
          late DelegateDocument? conflictingDocument;
          yield document(documentBeingSaved.id).then(
              (value) => conflictingDocument = value as DelegateDocument?);

          // Call the conflict handler.
          yield conflictHandler(
            documentBeingSaved,
            conflictingDocument,
          ).then((value) => retry = value);

          if (retry) {
            // If the document was deleted it has to be recreated.
            // ignore: parameter_assignments
            conflictingDocument ??=
                MutableDelegateDocument.withId(documentBeingSaved.id);

            // Replace the delegate of documentBeingSaved with a copy of that of
            // conflictingDocument. After this call, documentBeingSaved is at
            // the same revision as conflictingDocument.
            documentBeingSaved.setDelegate(
              conflictingDocument!.delegate.toMutable(),
              // The documentBeingSaved contains the resolved properties.
              updateProperties: false,
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectionBase &&
          runtimeType == other.runtimeType &&
          scope == other.scope &&
          name == other.name;

  @override
  int get hashCode => scope.hashCode ^ name.hashCode;
}
