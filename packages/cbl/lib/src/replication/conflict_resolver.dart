import 'dart:async';

import '../document/document.dart';
import 'configuration.dart';
import 'conflict.dart';
import 'replicator.dart';

/// An object which is able to resolve a [Conflict] between the local and remote
/// versions of a replicated [Document].
abstract class ConflictResolver {
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
