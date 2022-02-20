import 'dart:async';

import 'package:synchronized/synchronized.dart';

import '../document/document.dart';
import '../errors.dart';
import '../fleece/decoder.dart';
import '../fleece/dict_key.dart';
import '../support/utils.dart';
import 'database.dart';

/// Base that is mixed into all implementations of [Database].
mixin DatabaseBase<T extends DocumentDelegate> implements Database {
  /// The [DictKey]s that should be used when looking up properties in
  /// [Document]s that are stored in this database.
  ///
  ///
  /// Note:
  /// It is important to use the database specific [DictKey]s when accessing
  /// Fleece data from this database because each database has its own set
  /// of shared keys. [DictKey]s are optimized to make use of these keys and
  /// will lookup the wrong or no entries if used with the wrong set of shared
  /// keys.
  DictKeys get dictKeys;

  /// The [SharedKeysTable] that should be used when iterating over
  /// dictionaries in [Document]s that are stored in this database.
  ///
  /// The same note as for [dictKeys] applies here.
  SharedKeysTable get sharedKeysTable;

  final _asyncTransactionLock = Lock();

  /// Creates a [DocumentDelegate] from [oldDelegate] for a new document which
  /// is being used with this database for the first time.
  ///
  /// The returned delegate implementation usually is specific to this
  /// implementation of [Database].
  T createNewDocumentDelegate(DocumentDelegate oldDelegate);

  /// Prepares [document] for being used with this database.
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

    // Assign document to this database.
    document.database = this;

    // If document is new init delegate with database specific implementation.
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
  /// If the [conflictHandler] is synchronous and this database is synchronous
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
    final currentTransaction = Zone.current[#_transaction] as _Transaction?;
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

    if (!async && _asyncTransactionLock.locked) {
      throw DatabaseException(
        'Cannot start a new synchronous transaction while an asynchronous '
        'transaction is still active.',
        DatabaseErrorCode.transactionNotClosed,
      );
    }

    final transaction = _Transaction(this);

    FutureOr<R> invokeFn() =>
        runZoned(fn, zoneValues: {#_transaction: transaction});

    return beginTransaction().then((_) {
      if (async) {
        return _asyncTransactionLock.synchronized(
          () => Future.sync(invokeFn).then((value) async {
            transaction.end();
            await endTransaction(commit: true);
            return value;
            // ignore: avoid_types_on_closure_parameters
          }, onError: (Object error) async {
            transaction.end();
            await endTransaction(commit: false);
            // ignore: only_throw_errors
            throw error;
          }),
        );
      } else {
        try {
          final result = invokeFn();
          transaction.end();
          final endTransactionResult = endTransaction(commit: true);
          assert(endTransactionResult is! Future);
          return result;
          // ignore: avoid_catches_without_on_clauses
        } catch (e) {
          transaction.end();
          final endTransactionResult = endTransaction(commit: false);
          assert(endTransactionResult is! Future);
          rethrow;
        }
      }
    });
  }
}

class _Transaction {
  _Transaction(this.database);

  final Database database;

  bool get isActive => _isActive;
  var _isActive = true;

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
