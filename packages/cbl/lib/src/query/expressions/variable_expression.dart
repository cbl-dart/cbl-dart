import 'array_expression.dart';
import 'expression.dart';

/// A variable in an [ArrayExpression].
///
/// {@category Query Builder}
abstract class VariableExpressionInterface extends ExpressionInterface {}

// === Impl ====================================================================

class VariableExpressionImpl extends ExpressionImpl
    implements VariableExpressionInterface {
  VariableExpressionImpl(this.propertyPath);

  final String propertyPath;

  @override
  Object? toJson() => ['?$propertyPath'];
}
