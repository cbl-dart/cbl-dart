import '../expressions/expression.dart';
import '../limit.dart';
import '../query.dart';

/// Interface for creating and chaining `LIMIT` clauses.
///
/// {@category Query Builder}
// ignore: one_member_abstracts
abstract interface class LimitRouter {
  /// Creates and returns a `LIMIT` clause query component with the given
  /// [limit] and [offset].
  Limit limit(ExpressionInterface limit, {ExpressionInterface? offset});
}

/// Version of [LimitRouter] for building [SyncQuery]s.
///
/// {@category Query Builder}
abstract interface class SyncLimitRouter implements LimitRouter {
  @override
  SyncLimit limit(ExpressionInterface limit, {ExpressionInterface? offset});
}

/// Version of [LimitRouter] for building [AsyncQuery]s.
///
/// {@category Query Builder}
abstract interface class AsyncLimitRouter implements LimitRouter {
  @override
  AsyncLimit limit(ExpressionInterface limit, {ExpressionInterface? offset});
}
