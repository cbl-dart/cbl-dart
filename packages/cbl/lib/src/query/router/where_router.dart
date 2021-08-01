import '../expressions/expression.dart';
import '../where.dart';

/// Interface for creating and chaining `WHERE` clauses.
abstract class WhereRouter {
  /// Creates and returns a `WHERE` clause query component with the given
  /// [expression].
  Where where(ExpressionInterface expression);
}
