import '../expressions/expression.dart';
import '../having.dart';

/// Interface for creating and chaining `HAVING` clauses.
abstract class HavingRouter {
  /// Creates and returns a `HAVING` clause query component with the given
  /// [expression].
  Having having(ExpressionInterface expression);
}
