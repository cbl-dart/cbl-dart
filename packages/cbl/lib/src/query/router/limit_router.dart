import '../expressions/expression.dart';
import '../limit.dart';
import '../query.dart';

/// Interface for creating and chaining `LIMIT` clauses.
// ignore: one_member_abstracts
abstract class LimitRouter {
  /// Creates and returns a `LIMIT` clause query component with the given
  /// [limit] and [offset].
  Limit limit(
    ExpressionInterface limit, {
    ExpressionInterface? offset,
  });
}

/// Version of [LimitRouter] for building [SyncQuery]s.
abstract class SyncLimitRouter implements LimitRouter {
  @override
  SyncLimit limit(ExpressionInterface limit, {ExpressionInterface? offset});
}

/// Version of [LimitRouter] for building [AsyncQuery]s.
abstract class AsyncLimitRouter implements LimitRouter {
  @override
  AsyncLimit limit(ExpressionInterface limit, {ExpressionInterface? offset});
}
