import 'array_expression.dart';
import 'expression.dart';

/// A variable in an [ArrayExpression].
abstract class VariableExpressionInterface extends ExpressionInterface {}

// === Impl ====================================================================

class VariableExpressionImpl extends VariableOperandsExpression
    implements VariableExpressionInterface {
  VariableExpressionImpl(String propertyPath)
      : super('?', propertyPath.split('.').map(Expression.string));
}
