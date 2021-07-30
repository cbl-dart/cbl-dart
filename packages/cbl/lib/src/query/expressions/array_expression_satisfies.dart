import 'array_expression.dart';
import 'expression.dart';
import 'variable_expression.dart';

/// Represents the expression array items are matched against, in a quantified
/// `IN` array expression.
abstract class ArrayExpressionSatisfies {
  /// Specifies the [expression] against which array items in a quantified `IN`
  /// array expression are matched.
  ///
  /// Returns the complete quantified `IN` array expression.
  ExpressionInterface satisfies(ExpressionInterface expression);
}

// === Impl ====================================================================

class ArrayExpressionSatisfiesImpl implements ArrayExpressionSatisfies {
  ArrayExpressionSatisfiesImpl(
    Quantifier quantifier,
    VariableExpressionInterface variable,
    ExpressionInterface array,
  )   : _quantifier = quantifier,
        _variable = variable as VariableExpressionImpl,
        _array = array as ExpressionImpl;

  final Quantifier _quantifier;
  final VariableExpressionImpl _variable;
  final ExpressionImpl _array;

  @override
  ExpressionInterface satisfies(ExpressionInterface expression) {
    String operator;
    switch (_quantifier) {
      case Quantifier.any:
        operator = 'ANY';
        break;
      case Quantifier.every:
        operator = 'EVERY';
        break;
      case Quantifier.anyAndEvery:
        operator = 'ANY AND EVERY';
        break;
    }
    return TertiaryExpression(operator, _variable, _array, expression);
  }
}
