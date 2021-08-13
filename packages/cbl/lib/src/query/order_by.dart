import 'expressions/expression.dart';
import 'limit.dart';
import 'ordering.dart';
import 'query.dart';
import 'router/limit_router.dart';

/// A query component representing the `ORDER BY` clause of a [Query].
abstract class OrderBy implements Query, LimitRouter {}

/// Version of [OrderBy] for building [SyncQuery]s.
abstract class SyncOrderBy implements OrderBy, SyncQuery, SyncLimitRouter {}

/// Version of [OrderBy] for building [AsyncQuery]s.
abstract class AsyncOrderBy implements OrderBy, AsyncQuery, AsyncLimitRouter {}

// === Impl ====================================================================

class SyncOrderByImpl extends SyncBuilderQuery implements SyncOrderBy {
  SyncOrderByImpl({
    required SyncBuilderQuery query,
    required Iterable<OrderingInterface> orderings,
  }) : super(query: query, orderings: orderings);

  @override
  SyncLimit limit(ExpressionInterface limit, {ExpressionInterface? offset}) =>
      SyncLimitImpl(query: this, limit: limit, offset: offset);
}

class AsyncOrderByImpl extends AsyncBuilderQuery implements AsyncOrderBy {
  AsyncOrderByImpl({
    required AsyncBuilderQuery query,
    required Iterable<OrderingInterface> orderings,
  }) : super(query: query, orderings: orderings);

  @override
  AsyncLimit limit(ExpressionInterface limit, {ExpressionInterface? offset}) =>
      AsyncLimitImpl(query: this, limit: limit, offset: offset);
}
