import 'array_expression_in.dart';
import 'expression.dart';
import 'variable_expression.dart';

/// Array expression.
///
/// # Range predicates
///
/// A range predicate tests a Boolean condition over the elements of an array.
///
/// A predicate has a quantifier which determines the number of elements that
/// need to match the condition, for the predicate to evaluate to `true`.
///
/// The `ANY` quantifier requires at least one of the array elements to match
/// the condition.
///
/// The `EVERY` quantifier requires all of of the array elements to match the
/// condition, or for the array to be empty.
///
/// The `ANY AND EVERY` quantifier requires all of of the array elements to
/// match the condition, and for the array **not** to be empty.
///
/// Here is how to build a range predicate expression:
///
/// ```dart
/// final expr = ArrayExpression
///         // To build a range predicate you start by selecting one the
///         // quantifiers and defining the variable to which the array elements
///         // will be assigned.
///         .any(ArrayExpression.variable('myVar'))
///     // Next, you specify the array expression to evaluate the range
///     // predicate against.
///     .in_(Expression.property('myArray'))
///     // And lastly, you specify the condition which is evaluated for each
///     // array element, which should reference the previously defined variable.
///     .satisfies(
///       ArrayExpression.variable('myVar').equalTo(Expression.value(true)),
///     );
/// ```
///
/// In the condition given to `satisfies`, you can use a variable expression
/// which specifies a property path, if the array contains nested collections:
///
/// ```dart
/// final expr = ArrayExpression.variable('myVar.property')
///     .equalTo(Expression.value(true));
/// ```
///
/// {@category Query Builder}
class ArrayExpression {
  ArrayExpression._();

  /// Creates a variable expression that is a placeholder for an element in an
  /// array.
  static VariableExpressionInterface variable(String propertyPath) =>
      VariableExpressionImpl(propertyPath);

  /// Starts an `ANY` quantified range predicate and defines a [variable].
  ///
  /// An `ANY` quantified range predicate returns `true` if **at least one** of
  /// the elements in the array matches.
  static ArrayExpressionIn any(VariableExpressionInterface variable) =>
      ArrayExpressionInImpl(Quantifier.any, variable);

  /// Starts an `EVERY` quantified range predicate and defines a [variable].
  ///
  /// An `EVERY` quantified array expression returns `true` if the array **is
  /// empty** or **every** element in the array matches.
  static ArrayExpressionIn every(VariableExpressionInterface variable) =>
      ArrayExpressionInImpl(Quantifier.every, variable);

  /// Starts an `ANY AND EVERY` quantified range predicate and defines a
  /// [variable].
  ///
  /// An `ANY AND EVERY` quantified array expression returns `true` if the array
  /// **is NOT empty** and **at least one** of the elements in the array
  /// matches.
  static ArrayExpressionIn anyAndEvery(VariableExpressionInterface variable) =>
      ArrayExpressionInImpl(Quantifier.anyAndEvery, variable);
}
