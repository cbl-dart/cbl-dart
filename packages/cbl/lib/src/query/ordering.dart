import 'expressions/expression.dart';

/// Represents on of the expressions in the `ORDER BY` query clause.
///
/// {@category Query Builder}
abstract final class OrderingInterface {}

/// Allows the specification of the direction of an ordering expression.
///
/// {@category Query Builder}
abstract final class SortOrder extends OrderingInterface {
  /// Specifies ascending sort order.
  OrderingInterface ascending();

  /// Specifies descending sort order.
  OrderingInterface descending();
}

// ignore: avoid_classes_with_only_static_members
/// Factory for ordering expressions of the `ORDER BY` clause of a query.
///
/// {@category Query Builder}
abstract final class Ordering {
  /// Creates an ordering expression from the given [propertyPath].
  static SortOrder property(String propertyPath) =>
      expression(Expression.property(propertyPath));

  /// Creates an ordering expression from the given [expression].
  static SortOrder expression(ExpressionInterface expression) =>
      SortOrderImpl(expression: expression);
}

// === Impl ====================================================================

enum Order { ascending, descending }

final class OrderingImpl implements OrderingInterface {
  OrderingImpl({required ExpressionInterface expression, bool? isAscending})
    : _expression = expression as ExpressionImpl,
      _isAscending = isAscending ?? true;

  final ExpressionImpl _expression;
  final bool _isAscending;

  Object? toJson() =>
      _isAscending ? _expression.toJson() : ['DESC', _expression.toJson()];
}

final class SortOrderImpl extends OrderingImpl implements SortOrder {
  SortOrderImpl({required super.expression, super.isAscending});

  @override
  OrderingInterface ascending() =>
      OrderingImpl(expression: _expression, isAscending: true);

  @override
  OrderingInterface descending() =>
      OrderingImpl(expression: _expression, isAscending: false);
}
