import '../expressions/expression.dart';
import '../having.dart';
import '../query.dart';

/// Interface for creating and chaining `HAVING` clauses.
///
/// {@category Query Builder}
// ignore: one_member_abstracts
abstract class HavingRouter {
  /// Creates and returns a `HAVING` clause query component with the given
  /// [expression].
  Having having(ExpressionInterface expression);
}

/// Version of [HavingRouter] for building [SyncQuery]s.
///
/// {@category Query Builder}
abstract class SyncHavingRouter implements HavingRouter {
  @override
  SyncHaving having(ExpressionInterface expression);
}

/// Version of [HavingRouter] for building [AsyncQuery]s.
///
/// {@category Query Builder}
abstract class AsyncHavingRouter implements HavingRouter {
  @override
  AsyncHaving having(ExpressionInterface expression);
}
