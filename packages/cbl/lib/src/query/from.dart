import 'data_source.dart';
import 'expressions/expression.dart';
import 'ffi_query.dart';
import 'group_by.dart';
import 'join.dart';
import 'joins.dart';
import 'limit.dart';
import 'order_by.dart';
import 'ordering.dart';
import 'proxy_query.dart';
import 'query.dart';
import 'query_builder.dart';
import 'router/group_by_router.dart';
import 'router/join_router.dart';
import 'router/limit_router.dart';
import 'router/order_by_router.dart';
import 'router/where_router.dart';
import 'where.dart';

/// A query component representing the `FROM` clause of a [Query].
///
/// {@category Query Builder}
abstract class From
    implements
        Query,
        JoinRouter,
        WhereRouter,
        GroupByRouter,
        OrderByRouter,
        LimitRouter {}

/// Version of [From] for building [SyncQuery]s.
///
/// {@category Query Builder}
abstract class SyncFrom
    implements
        From,
        SyncQuery,
        SyncJoinRouter,
        SyncWhereRouter,
        SyncGroupByRouter,
        SyncOrderByRouter,
        SyncLimitRouter {}

/// Version of [From] for building [AsyncQuery]s.
///
/// {@category Query Builder}
abstract class AsyncFrom
    implements
        From,
        AsyncQuery,
        AsyncJoinRouter,
        AsyncWhereRouter,
        AsyncGroupByRouter,
        AsyncOrderByRouter,
        AsyncLimitRouter {}

// === Impl ====================================================================

class SyncFromImpl extends SyncBuilderQuery implements SyncFrom {
  SyncFromImpl({
    required BuilderQueryMixin query,
    required DataSourceInterface from,
  }) : super(query: query, from: from);

  @override
  SyncJoins join(
    JoinInterface join0, [
    JoinInterface? join1,
    JoinInterface? join2,
    JoinInterface? join3,
    JoinInterface? join4,
    JoinInterface? join5,
    JoinInterface? join6,
    JoinInterface? join7,
    JoinInterface? join8,
    JoinInterface? join9,
  ]) =>
      joinAll([
        join0,
        join1,
        join2,
        join3,
        join4,
        join5,
        join6,
        join7,
        join8,
        join9,
      ].whereType());

  @override
  SyncJoins joinAll(Iterable<JoinInterface> joins) =>
      SyncJoinsImpl(query: this, joins: joins);

  @override
  SyncWhere where(ExpressionInterface expression) =>
      SyncWhereImpl(query: this, expression: expression);

  @override
  SyncGroupBy groupBy(
    ExpressionInterface expression0, [
    ExpressionInterface? expression1,
    ExpressionInterface? expression2,
    ExpressionInterface? expression3,
    ExpressionInterface? expression4,
    ExpressionInterface? expression5,
    ExpressionInterface? expression6,
    ExpressionInterface? expression7,
    ExpressionInterface? expression8,
    ExpressionInterface? expression9,
  ]) =>
      groupByAll([
        expression0,
        expression1,
        expression2,
        expression3,
        expression4,
        expression5,
        expression6,
        expression7,
        expression8,
        expression9,
      ].whereType());

  @override
  SyncGroupBy groupByAll(Iterable<ExpressionInterface> expressions) =>
      SyncGroupByImpl(query: this, expressions: expressions);

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

class AsyncFromImpl extends AsyncBuilderQuery implements AsyncFrom {
  AsyncFromImpl({
    required BuilderQueryMixin query,
    required DataSourceInterface from,
  }) : super(query: query, from: from);

  @override
  AsyncJoins join(
    JoinInterface join0, [
    JoinInterface? join1,
    JoinInterface? join2,
    JoinInterface? join3,
    JoinInterface? join4,
    JoinInterface? join5,
    JoinInterface? join6,
    JoinInterface? join7,
    JoinInterface? join8,
    JoinInterface? join9,
  ]) =>
      joinAll([
        join0,
        join1,
        join2,
        join3,
        join4,
        join5,
        join6,
        join7,
        join8,
        join9,
      ].whereType());

  @override
  AsyncJoins joinAll(Iterable<JoinInterface> joins) =>
      AsyncJoinsImpl(query: this, joins: joins);

  @override
  AsyncWhere where(ExpressionInterface expression) =>
      AsyncWhereImpl(query: this, expression: expression);

  @override
  AsyncGroupBy groupBy(
    ExpressionInterface expression0, [
    ExpressionInterface? expression1,
    ExpressionInterface? expression2,
    ExpressionInterface? expression3,
    ExpressionInterface? expression4,
    ExpressionInterface? expression5,
    ExpressionInterface? expression6,
    ExpressionInterface? expression7,
    ExpressionInterface? expression8,
    ExpressionInterface? expression9,
  ]) =>
      groupByAll([
        expression0,
        expression1,
        expression2,
        expression3,
        expression4,
        expression5,
        expression6,
        expression7,
        expression8,
        expression9,
      ].whereType());

  @override
  AsyncGroupBy groupByAll(Iterable<ExpressionInterface> expressions) =>
      AsyncGroupByImpl(query: this, expressions: expressions);

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
