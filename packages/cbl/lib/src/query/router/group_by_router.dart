import '../expressions/expression.dart';
import '../group_by.dart';

/// Interface for creating and chaining `GROUP BY` clauses.
abstract class GroupByRouter {
  /// Creates and returns a `GROUP BY` clause query component with the given
  /// [expression].
  GroupBy groupBy(ExpressionInterface expression);

  /// Creates and returns a `GROUP BY` clause query component with the given
  /// [expressions].
  GroupBy groupByMany(Iterable<ExpressionInterface> expressions);
}
