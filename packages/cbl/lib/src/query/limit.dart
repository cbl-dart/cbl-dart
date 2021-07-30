import 'expressions/expression.dart';
import 'query.dart';

/// A query component representing the `LIMIT` clause of a [Query].
abstract class Limit implements Query {}

// === Impl ====================================================================

class LimitImpl extends BuilderQuery implements Limit {
  LimitImpl({
    required BuilderQuery query,
    required ExpressionInterface limit,
    ExpressionInterface? offset,
  }) : super(query: query, limit: limit, offset: offset);
}
