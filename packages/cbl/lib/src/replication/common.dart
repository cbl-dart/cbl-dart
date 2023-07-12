// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import '../database.dart';
import '../database/database_base.dart';
import '../support/errors.dart';
import 'configuration.dart';

Future<(ID, Map<IC, CollectionConfiguration>)> resolveReplicatorCollections<
    D extends Database, C extends Collection, ID extends D, IC extends C>(
  ReplicatorConfiguration config,
) async {
  config.validate();

  final ID database;
  final Map<IC, CollectionConfiguration> collections;

  if (config.database != null) {
    database = assertArgumentType<D>(config.database, 'config.database') as ID;
    collections = {
      (await database.defaultCollection) as IC:
          config.legacyCollectionConfiguration
    };
  } else {
    final baseCollections =
        config.collections.cast<CollectionBase, CollectionConfiguration>();

    final firstCollectionDatabase = baseCollections.entries.first.key.database;
    if (firstCollectionDatabase is! D) {
      throw ArgumentError(
        'All collections in this ReplicatorConfiguration must belong to a '
        'database of type $D.',
      );
    } else {
      database = firstCollectionDatabase as ID;
    }

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

    collections = config.collections.cast<IC, CollectionConfiguration>();
  }

  return (database, collections);
}
