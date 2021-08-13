import '../expressions/expression.dart';
import '../group_by.dart';
import '../query.dart';

/// Interface for creating and chaining `GROUP BY` clauses.
abstract class GroupByRouter {
  /// Creates and returns a `GROUP BY` clause query component with the given
  /// expressions.
  GroupBy groupBy(
    ExpressionInterface expression0, [
    ExpressionInterface? expression1,
    ExpressionInterface? expression2,
    ExpressionInterface? expression3,
    ExpressionInterface? expression4,
    ExpressionInterface? expression5,
    ExpressionInterface? expression6,
    ExpressionInterface? expression7,
    ExpressionInterface? expression8,
    ExpressionInterface? expression9,
  ]);

  /// Creates and returns a `GROUP BY` clause query component with the given
  /// [expressions].
  GroupBy groupByAll(Iterable<ExpressionInterface> expressions);
}

/// Version of [GroupByRouter] for building [SyncQuery]s.
abstract class SyncGroupByRouter implements GroupByRouter {
  @override
  SyncGroupBy groupBy(
    ExpressionInterface expression0, [
    ExpressionInterface? expression1,
    ExpressionInterface? expression2,
    ExpressionInterface? expression3,
    ExpressionInterface? expression4,
    ExpressionInterface? expression5,
    ExpressionInterface? expression6,
    ExpressionInterface? expression7,
    ExpressionInterface? expression8,
    ExpressionInterface? expression9,
  ]);

  @override
  SyncGroupBy groupByAll(Iterable<ExpressionInterface> expressions);
}

/// Version of [GroupByRouter] for building [AsyncQuery]s.
abstract class AsyncGroupByRouter implements GroupByRouter {
  @override
  AsyncGroupBy groupBy(
    ExpressionInterface expression0, [
    ExpressionInterface? expression1,
    ExpressionInterface? expression2,
    ExpressionInterface? expression3,
    ExpressionInterface? expression4,
    ExpressionInterface? expression5,
    ExpressionInterface? expression6,
    ExpressionInterface? expression7,
    ExpressionInterface? expression8,
    ExpressionInterface? expression9,
  ]);

  @override
  AsyncGroupBy groupByAll(Iterable<ExpressionInterface> expressions);
}
