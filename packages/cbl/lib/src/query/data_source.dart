import '../database.dart';
import '../database/database_base.dart';
import 'query.dart';

/// A [Query] data source.
///
/// {@category Query Builder}
abstract final class DataSourceInterface {}

/// A [Query] data source, with the ability to assign it an alias.
///
/// {@category Query Builder}
abstract final class DataSourceAs extends DataSourceInterface {
  /// Specifies an [alias] for this data source.
  DataSourceInterface as(String alias);
}

/// Factory for creating data sources.
///
/// {@category Query Builder}
abstract final class DataSource {
  /// Creates a data source from a [Collection].
  static DataSourceAs collection(Collection collection) =>
      DataSourceAsImpl(source: collection);
}

// === Impl ====================================================================

final class DataSourceImpl implements DataSourceInterface {
  DataSourceImpl({required this.source, this.alias});

  final Collection source;
  final String? alias;

  Database get database => (source as CollectionBase).database;

  Map<String, Object?> toJson() {
    final fullName = (source as CollectionBase).fullName;
    return {if (alias != null) 'AS': alias, 'COLLECTION': fullName};
  }
}

final class DataSourceAsImpl extends DataSourceImpl implements DataSourceAs {
  DataSourceAsImpl({required super.source, super.alias});

  @override
  DataSourceInterface as(String alias) =>
      DataSourceImpl(source: source, alias: alias);
}
