import '../document.dart';

/// A conflict between changes in a local and remote [Document].
abstract class Conflict {
  /// The id of the conflicting [Document].
  String get documentId;

  /// The [Document] in the local database, or `null` if deleted.
  Document? get localDocument;

  /// The [Document] replicated from the remote database, or `null` if deleted.
  Document? get remoteDocument;
}

class ConflictImpl implements Conflict {
  ConflictImpl(this.documentId, this.localDocument, this.remoteDocument);

  @override
  final String documentId;

  @override
  final Document? localDocument;

  @override
  final Document? remoteDocument;

  @override
  String toString() => 'Conflict('
      'local: $localDocument, '
      'remote: $remoteDocument'
      ')';
}
