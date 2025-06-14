import '../expressions/expression.dart';

// ignore: avoid_classes_with_only_static_members
/// Factory for creating array function expressions.
///
/// {@category Query Builder}
abstract final class ArrayFunction {
  /// Creates an expression which evaluates to whether the array [expression]
  /// contains the given [value].
  static ExpressionInterface contains(
    ExpressionInterface expression, {
    required ExpressionInterface value,
  }) => BinaryExpression('array_contains()', expression, value);

  /// Creates an expression which evaluates to the length of the given array
  /// [expression].
  static ExpressionInterface length(ExpressionInterface expression) =>
      UnaryExpression('array_length()', expression);
}
