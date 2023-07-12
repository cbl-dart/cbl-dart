import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../document.dart';
import 'collection.dart';
import 'database_base.dart';
import 'database_change.dart';

/// A [Collection] change event.
///
/// {@category Database}
@immutable
class CollectionChange {
  /// Creates a [Collection] change event.
  const CollectionChange(this.collection, this.documentIds);

  /// The collection that changed.
  final Collection collection;

  /// The ids of the [Document]s that changed.
  final List<String> documentIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectionChange &&
          runtimeType == other.runtimeType &&
          collection == other.collection &&
          const DeepCollectionEquality().equals(documentIds, other.documentIds);

  @override
  int get hashCode =>
      collection.hashCode ^ const DeepCollectionEquality().hash(documentIds);

  @override
  String toString() =>
      'CollectionChange(database: $collection, documentIds: $documentIds)';
}

extension InternalCollectionChange on CollectionChange {
  DatabaseChange toDatabaseChange() => DatabaseChange(
        (collection as CollectionBase).database,
        documentIds,
      );
}
