import 'expressions/expression.dart';
import 'having.dart';
import 'limit.dart';
import 'order_by.dart';
import 'ordering.dart';
import 'query.dart';
import 'router/having_router.dart';
import 'router/limit_router.dart';
import 'router/order_by_router.dart';

/// A query component representing the `GROUP BY` clause of a [Query].
abstract class GroupBy
    implements Query, HavingRouter, OrderByRouter, LimitRouter {}

// === Impl ====================================================================

class GroupByImpl extends BuilderQuery implements GroupBy {
  GroupByImpl({
    required BuilderQuery query,
    required Iterable<ExpressionInterface> expressions,
  }) : super(query: query, groupBys: expressions);

  @override
  Having having(ExpressionInterface expression) =>
      HavingImpl(query: this, expression: expression);

  @override
  OrderBy orderByOne(OrderingInterface ordering) => orderBy([ordering]);

  @override
  OrderBy orderBy(Iterable<OrderingInterface> orderings) =>
      OrderByImpl(query: this, orderings: orderings);

  @override
  Limit limit(ExpressionInterface limit, {ExpressionInterface? offset}) =>
      LimitImpl(query: this, limit: limit, offset: offset);
}
