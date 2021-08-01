import 'expressions/expression.dart';
import 'join.dart';
import 'limit.dart';
import 'order_by.dart';
import 'ordering.dart';
import 'query.dart';
import 'router/limit_router.dart';
import 'router/order_by_router.dart';
import 'router/where_router.dart';
import 'where.dart';

/// A query component representing the `JOIN` clauses of a [Query].
abstract class Joins implements Query, WhereRouter, OrderByRouter, LimitRouter {
}

// === Impl ====================================================================

class JoinsImpl extends BuilderQuery implements Joins {
  JoinsImpl({
    required BuilderQuery query,
    required Iterable<JoinInterface> joins,
  }) : super(query: query, joins: joins);

  @override
  Where where(ExpressionInterface expression) =>
      WhereImpl(query: this, expression: expression);

  @override
  OrderBy orderByOne(OrderingInterface ordering) => orderBy([ordering]);

  @override
  OrderBy orderBy(Iterable<OrderingInterface> orderings) =>
      OrderByImpl(query: this, orderings: orderings);

  @override
  Limit limit(ExpressionInterface limit, {ExpressionInterface? offset}) =>
      LimitImpl(query: this, limit: limit, offset: offset);
}
