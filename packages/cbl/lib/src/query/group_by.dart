import 'expressions/expression.dart';
import 'ffi_query.dart';
import 'having.dart';
import 'limit.dart';
import 'order_by.dart';
import 'ordering.dart';
import 'proxy_query.dart';
import 'query.dart';
import 'router/having_router.dart';
import 'router/limit_router.dart';
import 'router/order_by_router.dart';

/// A query component representing the `GROUP BY` clause of a [Query].
///
/// {@category Query Builder}
abstract class GroupBy
    implements Query, HavingRouter, OrderByRouter, LimitRouter {}

/// Version of [GroupBy] for building [SyncQuery]s.
///
/// {@category Query Builder}
abstract class SyncGroupBy
    implements
        GroupBy,
        SyncQuery,
        SyncHavingRouter,
        SyncOrderByRouter,
        SyncLimitRouter {}

/// Version of [GroupBy] for building [AsyncQuery]s.
///
/// {@category Query Builder}
abstract class AsyncGroupBy
    implements
        GroupBy,
        AsyncQuery,
        AsyncHavingRouter,
        AsyncOrderByRouter,
        AsyncLimitRouter {}

// === Impl ====================================================================

class SyncGroupByImpl extends SyncBuilderQuery implements SyncGroupBy {
  SyncGroupByImpl({
    required SyncBuilderQuery query,
    required Iterable<ExpressionInterface> expressions,
  }) : super(query: query, groupBys: expressions);

  @override
  SyncHaving having(ExpressionInterface expression) =>
      SyncHavingImpl(query: this, expression: expression);

  @override
  SyncOrderBy orderBy(
    OrderingInterface ordering0, [
    OrderingInterface? ordering1,
    OrderingInterface? ordering2,
    OrderingInterface? ordering3,
    OrderingInterface? ordering4,
    OrderingInterface? ordering5,
    OrderingInterface? ordering6,
    OrderingInterface? ordering7,
    OrderingInterface? ordering8,
    OrderingInterface? ordering9,
  ]) =>
      orderByAll([
        ordering0,
        ordering1,
        ordering2,
        ordering3,
        ordering4,
        ordering5,
        ordering6,
        ordering7,
        ordering8,
        ordering9,
      ].whereType());

  @override
  SyncOrderBy orderByAll(Iterable<OrderingInterface> orderings) =>
      SyncOrderByImpl(query: this, orderings: orderings);

  @override
  SyncLimit limit(ExpressionInterface limit, {ExpressionInterface? offset}) =>
      SyncLimitImpl(query: this, limit: limit, offset: offset);
}

class AsyncGroupByImpl extends AsyncBuilderQuery implements AsyncGroupBy {
  AsyncGroupByImpl({
    required AsyncBuilderQuery query,
    required Iterable<ExpressionInterface> expressions,
  }) : super(query: query, groupBys: expressions);

  @override
  AsyncHaving having(ExpressionInterface expression) =>
      AsyncHavingImpl(query: this, expression: expression);

  @override
  AsyncOrderBy orderBy(
    OrderingInterface ordering0, [
    OrderingInterface? ordering1,
    OrderingInterface? ordering2,
    OrderingInterface? ordering3,
    OrderingInterface? ordering4,
    OrderingInterface? ordering5,
    OrderingInterface? ordering6,
    OrderingInterface? ordering7,
    OrderingInterface? ordering8,
    OrderingInterface? ordering9,
  ]) =>
      orderByAll([
        ordering0,
        ordering1,
        ordering2,
        ordering3,
        ordering4,
        ordering5,
        ordering6,
        ordering7,
        ordering8,
        ordering9,
      ].whereType());

  @override
  AsyncOrderBy orderByAll(Iterable<OrderingInterface> orderings) =>
      AsyncOrderByImpl(query: this, orderings: orderings);

  @override
  AsyncLimit limit(ExpressionInterface limit, {ExpressionInterface? offset}) =>
      AsyncLimitImpl(query: this, limit: limit, offset: offset);
}
