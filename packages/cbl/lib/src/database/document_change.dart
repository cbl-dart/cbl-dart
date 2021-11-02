import 'package:meta/meta.dart';

import '../document.dart';
import 'database.dart';

/// A [Document] change event.
///
/// {@category Database}
@immutable
class DocumentChange {
  /// Creates a [Document] change event.
  const DocumentChange(this.database, this.documentId);

  /// The database that changed.
  final Database database;

  /// The id of the [Document] that changed.
  final String documentId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentChange &&
          runtimeType == other.runtimeType &&
          database == other.database &&
          documentId == other.documentId;

  @override
  int get hashCode => database.hashCode ^ documentId.hashCode;

  @override
  String toString() =>
      'DocumentChange(database: $database, documentId: $documentId)';
}
