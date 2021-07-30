import 'expressions/expression.dart';
import 'group_by.dart';
import 'limit.dart';
import 'order_by.dart';
import 'ordering.dart';
import 'query.dart';
import 'router/group_by_router.dart';
import 'router/limit_router.dart';
import 'router/order_by_router.dart';

/// A query component representing the `WHERE` clause of a [Query].
abstract class Where
    implements Query, GroupByRouter, OrderByRouter, LimitRouter {}

// === Impl ====================================================================

class WhereImpl extends BuilderQuery implements Where {
  WhereImpl({
    required BuilderQuery query,
    required ExpressionInterface expression,
  }) : super(query: query, where: expression);

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
