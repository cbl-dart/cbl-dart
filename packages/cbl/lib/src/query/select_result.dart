import 'expressions/expression.dart';
import 'result.dart';

/// Represents a single return value of a `SELECT` statement.
///
/// {@category Query Builder}
abstract final class SelectResultInterface {}

/// Allows the specification of an alias for a select result value.
///
/// {@category Query Builder}
abstract final class SelectResultAs extends SelectResultInterface {
  /// Specifies the [alias] of the select result value.
  SelectResultInterface as(String? alias);
}

/// Allows the specification of the data source of a select result value.
///
/// {@category Query Builder}
abstract final class SelectResultFrom extends SelectResultInterface {
  /// Specifies the [alias] of the data source to query for the select result
  /// value.
  SelectResultInterface from(String alias);
}

// ignore: avoid_classes_with_only_static_members
/// Factory for select results.
///
/// {@category Query Builder}
abstract final class SelectResult {
  /// Creates a select result from the given [propertyPath].
  static SelectResultAs property(String propertyPath) =>
      expression(Expression.property(propertyPath));

  /// Creates a select result from the given [expression].
  static SelectResultAs expression(ExpressionInterface expression) =>
      SelectResultAsImpl(expression: expression);

  /// Creates a select result that returns all document properties.
  ///
  /// The value will be available as a dictionary, under the name of the data
  /// source in the query [Result].
  static SelectResultFrom all() =>
      SelectResultFromImpl(expression: Expression.all());
}

// === Impl ====================================================================

final class SelectResultImpl implements SelectResultInterface {
  SelectResultImpl({required ExpressionInterface expression, String? alias})
      : _expression = expression as ExpressionImpl,
        _alias = alias;

  final ExpressionImpl _expression;
  final String? _alias;

  Object? toJson() => _alias == null
      ? _expression.toJson()
      : ['AS', _expression.toJson(), _alias];
}

final class SelectResultAsImpl extends SelectResultImpl
    implements SelectResultAs {
  SelectResultAsImpl({required super.expression, super.alias});

  @override
  SelectResultInterface as(String? alias) =>
      SelectResultImpl(expression: _expression, alias: alias);
}

final class SelectResultFromImpl extends SelectResultImpl
    implements SelectResultFrom {
  SelectResultFromImpl({required super.expression, super.alias});

  @override
  SelectResultInterface from(String alias) => SelectResultImpl(
        expression: Expression.all().from(alias),
      );
}
