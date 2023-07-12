import '../database.dart';
import '../database/database_base.dart';
import 'query.dart';

/// A [Query] data source.
///
/// {@category Query Builder}
abstract class DataSourceInterface {}

/// A [Query] data source, with the ability to assign it an alias.
///
/// {@category Query Builder}
abstract class DataSourceAs extends DataSourceInterface {
  /// Specifies an [alias] for this data source.
  DataSourceInterface as(String alias);
}

/// Factory for creating data sources.
///
/// {@category Query Builder}
class DataSource {
  DataSource._();

  /// Creates a data source from a [Database].
  @Deprecated('Use DataSource.collection(database.defaultCollection) instead.')
  static DataSourceAs database(Database database) =>
      DataSourceAsImpl(source: database);

  /// Creates a data source from a [Collection].
  static DataSourceAs collection(Collection collection) =>
      DataSourceAsImpl(source: collection);
}

// === Impl ====================================================================

class DataSourceImpl implements DataSourceInterface {
  DataSourceImpl({required this.source, this.alias});

  final Object source;
  final String? alias;

  Database get database => switch (source) {
        final Database database => database,
        CollectionBase(:final database) => database,
        _ => throw UnimplementedError(),
      };

  Map<String, Object?> toJson() => switch (source) {
        Database(:final name) => {'AS': alias ?? name},
        CollectionBase(:final fullName) => {
            if (alias != null) 'AS': alias,
            'COLLECTION': fullName
          },
        _ => throw UnimplementedError(),
      };
}

class DataSourceAsImpl extends DataSourceImpl implements DataSourceAs {
  DataSourceAsImpl({required super.source, super.alias});

  @override
  DataSourceInterface as(String alias) =>
      DataSourceImpl(source: source, alias: alias);
}
