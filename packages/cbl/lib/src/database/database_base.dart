import 'dart:async';

import '../document/document.dart';
import '../fleece/dict_key.dart';
import '../support/utils.dart';
import 'database.dart';

/// Base that is mixed into all implementations of [Database].
mixin DatabaseBase<T extends DocumentDelegate> implements Database {
  /// The [DictKey]s that should be used when looking up properties in
  /// [Document]s that are stored in this database.
  ///
  /// It is important to use the database specific [DictKey]s when accessing
  /// Fleece data from this database because each database has its own set
  /// of shared keys. [DictKey]s are optimized to make use of these keys and
  /// will lookup the wrong or no entries if used with the wrong set of shared
  /// keys.
  DictKeys get dictKeys;

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
}
