import 'dart:async';

import '../document.dart';
import 'configuration.dart';
import 'conflict.dart';
import 'replicator.dart';

/// Functional version of [ConflictResolver].
typedef ConflictResolverFunction = FutureOr<Document?> Function(
  Conflict conflict,
);

/// An object which is able to resolve a [Conflict] between the local and remote
/// versions of a replicated [Document].
abstract class ConflictResolver {
  /// Creates a [ConflictResolver] from a function which is called to resolve
  /// the conflict.
  factory ConflictResolver.from(
    ConflictResolverFunction resolve,
  ) =>
      _FunctionConflictResolver(resolve);

  /// Resolves the [conflict] between the local and the remote version of
  /// a [Document].
  ///
  /// This method will be invoked when the [Replicator] finds a newer
  /// server-side revision of a document that also has local changes. The local
  /// and remote changes must be resolved before the document can be pushed to
  /// the server.
  ///
  /// Unlike a [ReplicationFilter], it does not need to return quickly. If it
  /// needs to prompt for user input, that's OK.
  ///
  /// Inside of [conflict] this method receives the id of the conflicted
  /// document, the local revision of the document in the database, or `null` if
  /// the local document has been deleted and the the remote revision of the
  /// document found on the server or `null` if the document has been deleted
  /// on the server.
  ///
  /// Return the resolved document to save locally (and push, if the replicator
  /// is pushing.) This can be the same as [Conflict.localDocument] or
  /// [Conflict.remoteDocument], or you can create a mutable copy of either one
  /// and modify it appropriately. Alternatively return `null` if the resolution
  /// is to delete the document.
  FutureOr<Document?> resolve(Conflict conflict);
}

class _FunctionConflictResolver implements ConflictResolver {
  _FunctionConflictResolver(this._resolve);

  final ConflictResolverFunction _resolve;

  @override
  FutureOr<Document?> resolve(Conflict conflict) => _resolve(conflict);
}

/// The default [ConflictResolver].
///
/// This resolver can be used, in a custom [ConflictResolver], to use the
/// default strategy for some documents and a custom strategy for others.
class DefaultConflictResolver implements ConflictResolver {
  const DefaultConflictResolver();

  @override
  FutureOr<Document?> resolve(Conflict conflict) {
    final remoteDocument = conflict.remoteDocument;
    final localDocument = conflict.localDocument;

    // If the document has been deleted (either locally or remotely), delete it.
    if (remoteDocument == null || localDocument == null) {
      return null;
    }

    // Resolve to the most recently changed document.
    if (localDocument.revisionId!.compareTo(remoteDocument.revisionId!) > 0) {
      return localDocument;
    } else {
      return remoteDocument;
    }
  }
}
