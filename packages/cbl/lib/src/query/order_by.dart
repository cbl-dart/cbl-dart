import 'expressions/expression.dart';
import 'ffi_query.dart';
import 'limit.dart';
import 'ordering.dart';
import 'proxy_query.dart';
import 'query.dart';
import 'router/limit_router.dart';

/// A query component representing the `ORDER BY` clause of a [Query].
///
/// {@category Query Builder}
abstract class OrderBy implements Query, LimitRouter {}

/// Version of [OrderBy] for building [SyncQuery]s.
///
/// {@category Query Builder}
abstract class SyncOrderBy implements OrderBy, SyncQuery, SyncLimitRouter {}

/// Version of [OrderBy] for building [AsyncQuery]s.
///
/// {@category Query Builder}
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
