import 'package:meta/meta.dart';

import '../document.dart';
import '../typed_data.dart';

/// A conflict between changes in a local and remote [Document].
///
/// {@category Replication}
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
      // ignore: missing_whitespace_between_adjacent_strings
      'remote: $remoteDocument'
      ')';
}

/// A conflict between changes in a local and remote [Document], providing typed
/// representations of the documents.
///
/// {@category Replication}
/// {@category Typed Data}
@experimental
abstract class TypedConflict {
  /// The id of the conflicting [Document].
  String get documentId;

  /// The typed representation of the [Document] in the local database, or
  /// `null` if deleted.
  TypedDocumentObject? get localDocument;

  /// The typed representation of the [Document] replicated from the remote
  /// database, or `null` if deleted.
  TypedDocumentObject? get remoteDocument;
}

class TypedConflictImpl implements TypedConflict {
  TypedConflictImpl(this.documentId, this.localDocument, this.remoteDocument);

  @override
  final String documentId;

  @override
  final TypedDocumentObject? localDocument;

  @override
  final TypedDocumentObject? remoteDocument;

  @override
  String toString() => 'TypedConflict('
      'local: $localDocument, '
      // ignore: missing_whitespace_between_adjacent_strings
      'remote: $remoteDocument'
      ')';
}
