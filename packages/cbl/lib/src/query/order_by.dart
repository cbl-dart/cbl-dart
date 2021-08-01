import 'expressions/expression.dart';
import 'limit.dart';
import 'ordering.dart';
import 'query.dart';
import 'router/limit_router.dart';

/// A query component representing the `ORDER BY` clause of a [Query].
abstract class OrderBy implements Query, LimitRouter {}

// === Impl ====================================================================

class OrderByImpl extends BuilderQuery implements OrderBy {
  OrderByImpl({
    required BuilderQuery query,
    required Iterable<OrderingInterface> orderings,
  }) : super(query: query, orderings: orderings);

  @override
  Limit limit(ExpressionInterface limit, {ExpressionInterface? offset}) =>
      LimitImpl(query: this, limit: limit, offset: offset);
}
