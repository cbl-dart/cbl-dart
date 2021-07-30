import 'array_expression_in.dart';
import 'variable_expression.dart';

/// Array expression.
///
/// # Quantified `IN`
///
/// Expression for quantified matching of the items of an array.
///
/// ## N1QL syntax
///
/// ```sql
/// ANY | ANY AND EVERY | EVERY <variable> IN <expr> SATISFIES <expr>
/// ```
/// ## Query builder example
///
/// This example shows how to build an expression which evaluates to `true`
/// if at least one of the values of the `guests` array contains "Alice" at the
/// property path `name.first`.
///
/// ```dart
/// ArrayExpression.any(ArrayExpression.variable('name.first'))
///   .in_(Expression.property('guests'))
///   .satisfies(Expression.string('Alice'))
/// ```
class ArrayExpression {
  ArrayExpression._();

  /// Creates a variable expression that represents an item in an array
  /// expression.
  ///
  /// For each array item, the [propertyPath] is evaluated to determine
  /// the value of a variable for that item.
  static VariableExpressionInterface variable(String propertyPath) =>
      VariableExpressionImpl(propertyPath);

  /// Starts an `ANY` quantified `IN` array expression with the given
  /// [variable].
  ///
  /// N1QL syntax:
  /// ```sql
  /// ANY <variable> IN <expr> SATISFIES <expr>
  /// ```
  ///
  /// A `ANY` quantified array expression returns `true` if __at least one__ of
  /// the items in the array matches.
  static ArrayExpressionIn any(VariableExpressionInterface variable) =>
      ArrayExpressionInImpl(Quantifier.any, variable);

  /// Starts an `EVERY` quantified `IN` array expression with the given
  /// [variable].
  ///
  /// N1QL syntax:
  /// ```sql
  /// EVERY <variable> IN <expr> SATISFIES <expr>
  /// ```
  ///
  /// A `EVERY` quantified array expression returns `true` if the array
  /// __is empty__ or __every__ item in the array matches.
  static ArrayExpressionIn every(VariableExpressionInterface variable) =>
      ArrayExpressionInImpl(Quantifier.every, variable);

  /// Starts an `ANY AND EVERY` `IN` quantified array expression with the given
  /// [variable].
  ///
  /// N1QL syntax:
  /// ```sql
  /// ANY AND EVERY <variable> IN <expr> SATISFIES <expr>
  /// ```
  ///
  /// A `ANY AND EVERY` quantified array expression returns `true` if the array
  /// __is NOT empty__ and __at least one__ of the items in the array matches.
  static ArrayExpressionIn anyAndEvery(VariableExpressionInterface variable) =>
      ArrayExpressionInImpl(Quantifier.anyAndEvery, variable);
}

// === Impl ====================================================================

enum Quantifier {
  any,
  every,
  anyAndEvery,
}
