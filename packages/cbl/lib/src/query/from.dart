import 'data_source.dart';
import 'expressions/expression.dart';
import 'group_by.dart';
import 'join.dart';
import 'joins.dart';
import 'limit.dart';
import 'order_by.dart';
import 'ordering.dart';
import 'query.dart';
import 'router/group_by_router.dart';
import 'router/join_router.dart';
import 'router/limit_router.dart';
import 'router/order_by_router.dart';
import 'router/where_router.dart';
import 'where.dart';

/// A query component representing the `FROM` clause of a [Query].
abstract class From
    implements
        Query,
        JoinRouter,
        WhereRouter,
        GroupByRouter,
        OrderByRouter,
        LimitRouter {}

// === Impl ====================================================================

class FromImpl extends BuilderQuery implements From {
  FromImpl({
    required BuilderQuery query,
    required DataSourceInterface from,
  }) : super(query: query, from: from);

  @override
  Joins join(JoinInterface join) => joinMany([join]);

  @override
  Joins joinMany(Iterable<JoinInterface> joins) =>
      JoinsImpl(query: this, joins: joins);

  @override
  Where where(ExpressionInterface expression) =>
      WhereImpl(query: this, expression: expression);

  @override
  GroupBy groupBy(ExpressionInterface expression) => groupByMany([expression]);

  @override
  GroupBy groupByMany(Iterable<ExpressionInterface> expressions) =>
      GroupByImpl(query: this, expressions: expressions);

  @override
  OrderBy orderByOne(OrderingInterface ordering) => orderBy([ordering]);

  @override
  OrderBy orderBy(Iterable<OrderingInterface> orderings) =>
      OrderByImpl(query: this, orderings: orderings);

  @override
  Limit limit(ExpressionInterface limit, {ExpressionInterface? offset}) =>
      LimitImpl(query: this, limit: limit, offset: offset);
}
