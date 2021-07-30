import 'array_expression.dart';
import 'array_expression_satisfies.dart';
import 'expression.dart';
import 'variable_expression.dart';

/// Represents the `IN` clause in a quantified `IN` array expression.
///
/// The `IN` clause is used to specify the array or the expression evaluated as
/// an array.
abstract class ArrayExpressionIn {
  /// Specifies the array or the [expression] evaluated as an array in a
  /// quantified `IN` array expression.
  ArrayExpressionSatisfies in_(ExpressionInterface expression);
}

// === Impl ====================================================================

class ArrayExpressionInImpl implements ArrayExpressionIn {
  ArrayExpressionInImpl(
      Quantifier quantifier, VariableExpressionInterface variable)
      : _quantifier = quantifier,
        _variable = variable as VariableExpressionImpl;

  final Quantifier _quantifier;
  final VariableExpressionImpl _variable;

  @override
  ArrayExpressionSatisfies in_(ExpressionInterface expression) =>
      ArrayExpressionSatisfiesImpl(_quantifier, _variable, expression);
}
