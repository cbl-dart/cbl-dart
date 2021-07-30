import '../expressions/expression.dart';
import '../limit.dart';

/// Interface for creating and chaining `LIMIT` clauses.
abstract class LimitRouter {
  /// Creates and returns a `LIMIT` clause query component with the given
  /// [limit] and [offset].
  Limit limit(ExpressionInterface limit, {ExpressionInterface? offset});
}
