import 'array_expression.dart';
import 'expression.dart';
import 'variable_expression.dart';

/// Represents the `SATISFIES` clause of a range predicate.
///
/// {@category Query Builder}
// ignore: one_member_abstracts
abstract class ArrayExpressionSatisfies {
  /// Specifies the condition that array elements are matched against, in a
  /// range predicate.
  ///
  /// See also:
  ///
  /// - [ArrayExpression] for more information on range predicates.
  ExpressionInterface satisfies(ExpressionInterface expression);
}

// === Impl ====================================================================

class ArrayExpressionSatisfiesImpl implements ArrayExpressionSatisfies {
  ArrayExpressionSatisfiesImpl(
    Quantifier quantifier,
    VariableExpressionInterface variable,
    ExpressionInterface array,
  )   : _quantifier = quantifier,
        _variable = variable,
        _array = array;

  final Quantifier _quantifier;
  final VariableExpressionInterface _variable;
  final ExpressionInterface _array;

  @override
  ExpressionInterface satisfies(ExpressionInterface expression) =>
      RangePredicateExpression(_quantifier, _variable, _array, expression);
}
