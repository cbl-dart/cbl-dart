import '../data_source.dart';
import '../from.dart';
import '../query.dart';

/// Interface for creating and chaining `FROM` clauses.
///
/// {@category Query Builder}
// ignore: one_member_abstracts
abstract class FromRouter {
  /// Creates and returns a `FROM` clause query component with the given
  /// [dataSource].
  From from(DataSourceInterface dataSource);
}

/// Version of [FromRouter] for building [SyncQuery]s.
///
/// {@category Query Builder}
abstract class SyncFromRouter implements FromRouter {
  @override
  SyncFrom from(DataSourceInterface dataSource);
}

/// Version of [FromRouter] for building [AsyncQuery]s.
///
/// {@category Query Builder}
abstract class AsyncFromRouter implements FromRouter {
  @override
  AsyncFrom from(DataSourceInterface dataSource);
}
