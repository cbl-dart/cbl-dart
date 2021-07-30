import '../order_by.dart';
import '../ordering.dart';

/// Interface for creating and chaining `ORDER BY` clauses.
abstract class OrderByRouter {
  /// Creates and returns a `ORDER BY` clause query component with the given
  /// [ordering].
  OrderBy orderByOne(OrderingInterface ordering);

  /// Creates and returns a `ORDER BY` clause query component with the given
  /// [orderings].
  OrderBy orderBy(Iterable<OrderingInterface> orderings);
}
