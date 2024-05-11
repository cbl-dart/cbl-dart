import 'array_expression.dart';
import 'expression.dart';

/// A variable in an [ArrayExpression].
///
/// {@category Query Builder}
abstract final class VariableExpressionInterface
    implements ExpressionInterface {}

// === Impl ====================================================================

final class VariableExpressionImpl extends ExpressionImpl
    implements VariableExpressionInterface {
  VariableExpressionImpl(this.propertyPath);

  final String propertyPath;

  @override
  Object? toJson() => ['?$propertyPath'];
}
