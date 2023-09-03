import 'package:meta/meta.dart';

import '../document.dart';
import 'collection.dart';
import 'database.dart';

/// A [Document] change event.
///
/// {@category Database}
@immutable
class DocumentChange {
  /// Creates a [Document] change event.
  const DocumentChange(this.database, this.collection, this.documentId);

  /// The database that contains the changed [Document].
  final Database database;

  /// The collection that contains the changed [Document].
  final Collection collection;

  /// The id of the [Document] that changed.
  final String documentId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentChange &&
          runtimeType == other.runtimeType &&
          database == other.database &&
          collection == other.collection &&
          documentId == other.documentId;

  @override
  int get hashCode =>
      database.hashCode ^ collection.hashCode ^ documentId.hashCode;

  @override
  String toString() => 'DocumentChange('
      'database: $database, '
      'collection: $collection, '
      'documentId: $documentId'
      ')';
}
