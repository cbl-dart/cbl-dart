import 'expressions/expression.dart';
import 'limit.dart';
import 'order_by.dart';
import 'ordering.dart';
import 'query.dart';
import 'router/limit_router.dart';
import 'router/order_by_router.dart';

/// A query component representing the `HAVING` clause of a [Query].
abstract class Having implements Query, OrderByRouter, LimitRouter {}

// === Impl ====================================================================

class HavingImpl extends BuilderQuery implements Having {
  HavingImpl(
      {required BuilderQuery query, required ExpressionInterface expression})
      : super(query: query, having: expression);

  @override
  OrderBy orderByOne(OrderingInterface ordering) => orderBy([ordering]);

  @override
  OrderBy orderBy(Iterable<OrderingInterface> orderings) =>
      OrderByImpl(query: this, orderings: orderings);

  @override
  Limit limit(ExpressionInterface limit, {ExpressionInterface? offset}) =>
      LimitImpl(query: this, limit: limit, offset: offset);
}
