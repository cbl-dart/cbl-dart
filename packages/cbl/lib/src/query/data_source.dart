import '../database/database.dart';
import 'query.dart';

/// A [Query] data source.
abstract class DataSourceInterface {}

/// A [Query] data source, with the ability to assign it an alias.
abstract class DataSourceAs extends DataSourceInterface {
  /// Specifies an [alias] for this data source.
  DataSourceInterface as(String alias);
}

/// Factory for creating data sources.
class DataSource {
  DataSource._();

  /// Creates a data source from a [database].
  static DataSourceAs database(Database database) =>
      DataSourceAsImpl(database: database);
}

// === Impl ====================================================================

class DataSourceImpl implements DataSourceInterface {
  DataSourceImpl({required Database database, String? alias})
      : database = database,
        _alias = alias;

  final Database database;
  final String? _alias;

  Map<String, Object?> toJson() => {
        if (_alias != null) 'AS': _alias,
        'COLLECTION': database.name,
      };
}

class DataSourceAsImpl extends DataSourceImpl implements DataSourceAs {
  DataSourceAsImpl({required Database database, String? alias})
      : super(database: database, alias: alias);

  @override
  DataSourceInterface as(String alias) =>
      DataSourceImpl(database: database, alias: alias);
}
