import 'array_expression.dart';
import 'array_expression_satisfies.dart';
import 'expression.dart';
import 'variable_expression.dart';

/// Represents the `IN` clause of a range predicate.
///
/// {@category Query Builder}
// ignore: one_member_abstracts
abstract class ArrayExpressionIn {
  /// Specifies the array or the [expression] evaluated as an array of a range
  /// predicate.
  ///
  /// See also:
  ///
  /// - [ArrayExpression] for more information on range predicates.
  // ignore: non_constant_identifier_names
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
  // ignore: non_constant_identifier_names
  ArrayExpressionSatisfies in_(ExpressionInterface expression) =>
      ArrayExpressionSatisfiesImpl(_quantifier, _variable, expression);
}
