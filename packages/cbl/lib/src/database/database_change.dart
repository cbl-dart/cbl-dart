import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../document.dart';
import 'database.dart';

/// A [Database] change event.
///
/// {@category Database}
@immutable
class DatabaseChange {
  /// Creates a [Database] change event.
  const DatabaseChange(this.database, this.documentIds);

  /// The database that changed.
  final Database database;

  /// The ids of the [Document]s that changed.
  final List<String> documentIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DatabaseChange &&
          runtimeType == other.runtimeType &&
          database == other.database &&
          const DeepCollectionEquality().equals(documentIds, other.documentIds);

  @override
  int get hashCode =>
      database.hashCode ^ const DeepCollectionEquality().hash(documentIds);

  @override
  String toString() =>
      'DatabaseChange(database: $database, documentIds: $documentIds)';
}
