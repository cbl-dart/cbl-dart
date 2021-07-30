import '../data_source.dart';
import '../from.dart';

/// Interface for creating and chaining `FROM` clauses.
abstract class FromRouter {
  /// Creates and returns a `FROM` clause query component with the given
  /// [dataSource].
  From from(DataSourceInterface dataSource);
}
