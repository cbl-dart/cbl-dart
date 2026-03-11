import '../database.dart';
import '../database/database_base.dart';
import 'configuration.dart';

(ID, Map<IC, CollectionConfiguration>) resolveReplicatorCollections<
  D extends Database,
  C extends Collection,
  ID extends D,
  IC extends C
>(ReplicatorConfiguration config) {
  config.validate();

  final baseCollections = config.collections
      .cast<CollectionBase, CollectionConfiguration>();

  final firstCollectionDatabase = baseCollections.entries.first.key.database;
  if (firstCollectionDatabase is! D) {
    throw ArgumentError(
      'All collections in this ReplicatorConfiguration must belong to a '
      'database of type $D.',
    );
  }
  final database = firstCollectionDatabase as ID;

  for (final collection in baseCollections.keys) {
    if (collection is! C) {
      throw ArgumentError(
        'All collections in this ReplicatorConfiguration must of type $C.',
      );
    }
    if (collection.database != database) {
      throw ArgumentError(
        'All collections in a ReplicatorConfiguration must belong to the '
        'same database.',
      );
    }
  }

  final collections = config.collections.cast<IC, CollectionConfiguration>();

  final adapter = (database as DatabaseBase).typedDataAdapter;
  final resolvedCollections = collections.map(
    (collection, config) => MapEntry(collection, config.resolve(adapter)),
  );
  return (database, resolvedCollections);
}
