import '../collation.dart';
import '../query.dart';
import '../query_builder.dart';
import 'property_expression.dart';
import 'variable_expression.dart';

/// Represents an expression when building a [Query] through the [QueryBuilder].
///
/// {@category Query Builder}
abstract class ExpressionInterface {
  /// Returns a new expression which multiplies this expression with the given
  /// [expression].
  ExpressionInterface multiply(ExpressionInterface expression);

  /// Returns a new expression which divides this expression by the given
  /// [expression].
  ExpressionInterface divide(ExpressionInterface expression);

  /// Returns a new expression to modulo this expression by the given
  /// [expression].
  ExpressionInterface modulo(ExpressionInterface expression);

  /// Returns a new expression wich adds this expression to the given
  /// [expression].
  ExpressionInterface add(ExpressionInterface expression);

  /// Returns a new expression which subtracts the given [expression] from this
  /// expression.
  ExpressionInterface subtract(ExpressionInterface expression);

  /// Returns a new expression which evaluates whether this expression is less
  /// than the given [expression].
  ExpressionInterface lessThan(ExpressionInterface expression);

  /// Returns a new expression which evaluates whether this expression is less
  /// or equal to than the given [expression].
  ExpressionInterface lessThanOrEqualTo(ExpressionInterface expression);

  /// Returns a new expression which evaluates whether this expression is
  /// greater than the given [expression].
  ExpressionInterface greaterThan(ExpressionInterface expression);

  /// Returns a new expression which evaluates whether this expression is less
  /// grater than or equal to the given [expression].
  ExpressionInterface greaterThanOrEqualTo(ExpressionInterface expression);

  /// Returns a new expression which evaluates whether this expression is equal
  /// to the given [expression].
  ExpressionInterface equalTo(ExpressionInterface expression);

  /// Returns a new expression which evaluates whether this expression is not
  /// equal to the given [expression].
  ExpressionInterface notEqualTo(ExpressionInterface expression);

  /// Returns a new expression which evaluates whether this expression is LIKE
  /// the the given [expression].
  ExpressionInterface like(ExpressionInterface expression);

  /// Returns a new expression which evaluates whether this expression regex
  /// matches the the given [expression].
  ExpressionInterface regex(ExpressionInterface expression);

  /// Returns a new expression which evaluates whether this expression `IS`
  /// equal to given [expression].
  // ignore: non_constant_identifier_names
  ExpressionInterface is_(ExpressionInterface expression);

  /// Returns a new expression which evaluates whether this expression `IS NOT`
  /// equal to given [expression].
  ExpressionInterface isNot(ExpressionInterface expression);

  /// Returns a new expression which evaluates whether this expression is `null`
  /// or missing.
  ExpressionInterface isNullOrMissing();

  /// Returns a new expression which evaluates whether this expression is not
  /// `null` nor missing.
  ExpressionInterface notNullOrMissing();

  /// Returns a new expression which performs a logical `AND` of this expression
  /// and the given [expression].
  ExpressionInterface and(ExpressionInterface expression);

  /// Returns a new expression which performs a logical `OR` of this expression
  /// and the given [expression].
  ExpressionInterface or(ExpressionInterface expression);

  /// Returns a new expression which evaluates to whether this expression is
  /// between the two given expressions inclusively.
  ExpressionInterface between(
    ExpressionInterface expression, {
    required ExpressionInterface and,
  });

  /// Returns a new expression which evaluates to whether this expression is in
  /// the given [expressions].
  // ignore: non_constant_identifier_names
  ExpressionInterface in_(Iterable<ExpressionInterface> expressions);

  /// Returns a new expression which applies the given [collation] to this
  /// expression.
  ///
  /// Commonly the collate expression is used in the `ORDER BY` clause or the
  /// string comparison expression (e.g. [equalTo] or [lessThan]) to specify how
  /// the two strings are compared.
  ExpressionInterface collate(CollationInterface collation);
}

/// Factory for creating expressions when building [Query]s through the
/// [QueryBuilder].
///
/// {@category Query Builder}
class Expression {
  Expression._();

  /// Creates a property expression representing the value at the given
  /// [propertyPath].
  static PropertyExpressionInterface property(String propertyPath) =>
      PropertyExpressionImpl(propertyPath);

  /// Creates the `*` expression.
  static PropertyExpressionInterface all() => PropertyExpressionImpl.all();

  /// Creates a literal value expression.
  ///
  /// The supported value types are [String], [num], [int], [double], [bool],
  /// [DateTime], [Map] (Map<String, Object?>) and [Iterable]
  /// (Iterable<String?>).
  static ExpressionInterface value(Object? value) => ValueExpression(value);

  /// Creates a literal [String] expression.
  static ExpressionInterface string(String? value) => Expression.value(value);

  /// Creates a literal integer number expression.
  static ExpressionInterface integer(int value) => Expression.value(value);

  /// Creates a literal floating point number expression.
  static ExpressionInterface float(double value) => Expression.value(value);

  /// Creates a literal [num] expression.
  static ExpressionInterface number(num? value) => Expression.value(value);

  /// Creates a literal [bool] expression.
  // ignore: avoid_positional_boolean_parameters
  static ExpressionInterface boolean(bool value) => Expression.value(value);

  /// Creates a literal [DateTime] expression.
  static ExpressionInterface date(DateTime? value) => Expression.value(value);

  /// Creates a literal dictionary expression.
  static ExpressionInterface dictionary(Map<String, Object?>? value) =>
      Expression.value(value);

  /// Creates a literal array expression.
  static ExpressionInterface array(Iterable<Object?>? value) =>
      Expression.value(value);

  /// Creates a parameter expression with the given [name].
  static ExpressionInterface parameter(String name) =>
      UnaryExpression(r'$', string(name));

  /// Creates an expression negating the given [expression].
  static ExpressionInterface negated(ExpressionInterface expression) =>
      UnaryExpression('NOT', expression);

  /// Creates an expression negating the given [expression].
  static ExpressionInterface not(ExpressionInterface expression) =>
      negated(expression);
}

// === Impl ====================================================================

abstract class ExpressionImpl implements ExpressionInterface {
  static final missing = NullaryExpression('MISSING');

  @override
  ExpressionInterface multiply(ExpressionInterface expression) =>
      BinaryExpression('*', this, expression);

  @override
  ExpressionInterface divide(ExpressionInterface expression) =>
      BinaryExpression('/', this, expression);

  @override
  ExpressionInterface modulo(ExpressionInterface expression) =>
      BinaryExpression('%', this, expression);

  @override
  ExpressionInterface add(ExpressionInterface expression) =>
      BinaryExpression('+', this, expression);

  @override
  ExpressionInterface subtract(ExpressionInterface expression) =>
      BinaryExpression('-', this, expression);

  @override
  ExpressionInterface lessThan(ExpressionInterface expression) =>
      BinaryExpression('<', this, expression);

  @override
  ExpressionInterface lessThanOrEqualTo(ExpressionInterface expression) =>
      BinaryExpression('<=', this, expression);

  @override
  ExpressionInterface greaterThan(ExpressionInterface expression) =>
      BinaryExpression('>', this, expression);

  @override
  ExpressionInterface greaterThanOrEqualTo(ExpressionInterface expression) =>
      BinaryExpression('>=', this, expression);

  @override
  ExpressionInterface equalTo(ExpressionInterface expression) =>
      BinaryExpression('=', this, expression);

  @override
  ExpressionInterface notEqualTo(ExpressionInterface expression) =>
      BinaryExpression('!=', this, expression);

  @override
  ExpressionInterface like(ExpressionInterface expression) =>
      BinaryExpression('LIKE', this, expression);

  @override
  ExpressionInterface regex(ExpressionInterface expression) =>
      BinaryExpression('regexp_like()', this, expression);

  @override
  // ignore: non_constant_identifier_names
  ExpressionInterface is_(ExpressionInterface expression) =>
      BinaryExpression('IS', this, expression);

  @override
  ExpressionInterface isNot(ExpressionInterface expression) =>
      BinaryExpression('IS NOT', this, expression);

  @override
  ExpressionInterface isNullOrMissing() =>
      is_(Expression.value(null)).or(is_(missing));

  @override
  ExpressionInterface notNullOrMissing() => Expression.not(isNullOrMissing());

  @override
  ExpressionInterface and(ExpressionInterface expression) =>
      BinaryExpression('AND', this, expression);

  @override
  ExpressionInterface or(ExpressionInterface expression) =>
      BinaryExpression('OR', this, expression);

  @override
  ExpressionInterface between(
    ExpressionInterface expression, {
    required ExpressionInterface and,
  }) =>
      TernaryExpression('BETWEEN', this, expression, and);

  @override
  // ignore: non_constant_identifier_names
  ExpressionInterface in_(Iterable<ExpressionInterface> expressions) =>
      BinaryExpression('IN', this, Expression.value(expressions));

  @override
  ExpressionInterface collate(CollationInterface collation) =>
      CollateExpression(collation, this);

  Object? toJson();
}

class ValueExpression extends ExpressionImpl {
  ValueExpression(Object? value) : _value = value;

  final Object? _value;

  @override
  Object? toJson() => _valueToJson(_value);

  static Object? _valueToJson(Object? value) {
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is Map<String, Object?>) {
      return _mapToJson(value);
    }
    if (value is Iterable<Object?>) {
      return _iterableToJson(value);
    }
    if (value is ExpressionImpl) {
      return value.toJson();
    }
    return value;
  }

  static Object? _mapToJson(Map<String, Object?> map) =>
      {for (final entry in map.entries) entry.key: _valueToJson(entry.value)};

  static Object? _iterableToJson(Iterable<Object?> iterable) =>
      ['[]', ...iterable.map(_valueToJson)];
}

class NullaryExpression extends ExpressionImpl {
  NullaryExpression(String operator) : _operator = operator;

  final String _operator;

  @override
  Object? toJson() => [_operator];
}

class UnaryExpression extends ExpressionImpl {
  UnaryExpression(String operator, ExpressionInterface operand)
      : _operator = operator,
        _operand = operand as ExpressionImpl;

  final String _operator;
  final ExpressionImpl _operand;

  @override
  Object? toJson() => [_operator, _operand.toJson()];
}

class BinaryExpression extends ExpressionImpl {
  BinaryExpression(
      String operator, ExpressionInterface left, ExpressionInterface? right)
      : _operator = operator,
        _left = left as ExpressionImpl,
        _right = right as ExpressionImpl?;

  final String _operator;
  final ExpressionImpl _left;
  final ExpressionImpl? _right;

  @override
  Object? toJson() =>
      [_operator, _left.toJson(), if (_right != null) _right!.toJson()];
}

class TernaryExpression extends ExpressionImpl {
  TernaryExpression(
    String operator,
    ExpressionInterface operand0,
    ExpressionInterface operand1,
    ExpressionInterface operand2,
  )   : _operator = operator,
        _operand0 = operand0 as ExpressionImpl,
        _operand1 = operand1 as ExpressionImpl,
        _operand2 = operand2 as ExpressionImpl;

  final String _operator;
  final ExpressionImpl _operand0;
  final ExpressionImpl _operand1;
  final ExpressionImpl _operand2;

  @override
  Object? toJson() =>
      [_operator, _operand0.toJson(), _operand1.toJson(), _operand2.toJson()];
}

class VariadicExpression extends ExpressionImpl {
  VariadicExpression(
    String operator,
    Iterable<ExpressionInterface> operands,
  )   : _operator = operator,
        _operands = operands.toList().cast();

  final String _operator;
  final List<ExpressionImpl> _operands;

  @override
  Object? toJson() =>
      [_operator, ..._operands.map((operand) => operand.toJson())];
}

class CollateExpression extends ExpressionImpl {
  CollateExpression(
    CollationInterface collation,
    ExpressionInterface expression,
  )   : _collation = collation as CollationImpl,
        _expression = expression as ExpressionImpl;

  final CollationImpl _collation;
  final ExpressionImpl _expression;

  @override
  Object? toJson() => ['COLLATE', _collation.toJson(), _expression.toJson()];
}

enum Quantifier {
  any,
  every,
  anyAndEvery,
}

class RangePredicateExpression extends ExpressionImpl {
  RangePredicateExpression(
    Quantifier quantifier,
    VariableExpressionInterface variable,
    // ignore: non_constant_identifier_names
    ExpressionInterface in_,
    ExpressionInterface satisfies,
  )   : _quantifier = quantifier,
        _variable = variable as VariableExpressionImpl,
        _in = in_ as ExpressionImpl,
        _satisfies = satisfies as ExpressionImpl;

  final Quantifier _quantifier;
  final VariableExpressionImpl _variable;
  final ExpressionImpl _in;
  final ExpressionImpl _satisfies;

  @override
  Object? toJson() {
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
    return [
      operator,
      _variable.propertyPath,
      _in.toJson(),
      _satisfies.toJson()
    ];
  }
}
