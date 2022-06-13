import 'expressions/expression.dart';

/// Factory for creating function expressions.
///
/// {@category Query Builder}
// ignore: camel_case_types
class Function_ {
  Function_._();

  /// Creates an aggregate function expression which averages the given values
  /// of the numeric [expression].
  static ExpressionInterface avg(ExpressionInterface expression) =>
      UnaryExpression('avg()', expression);

  /// Creates an aggregate function expression which counts the values of the
  /// given [expression].
  static ExpressionInterface count(ExpressionInterface expression) =>
      UnaryExpression('count()', expression);

  /// Creates an aggregate function expression which evaluates to the smallest
  /// value of the given numeric [expression].
  static ExpressionInterface min(ExpressionInterface expression) =>
      UnaryExpression('min()', expression);

  /// Creates an aggregate function expression which evaluates to the greatest
  /// value of the given numeric [expression].
  static ExpressionInterface max(ExpressionInterface expression) =>
      UnaryExpression('max()', expression);

  /// Creates an aggregate function expression which evaluates to sum of the
  /// values of the given numeric [expression].
  static ExpressionInterface sum(ExpressionInterface expression) =>
      UnaryExpression('sum()', expression);

  /// Creates a function expression which evaluates to the absolute value of the
  /// given numeric [expression].
  static ExpressionInterface abs(ExpressionInterface expression) =>
      UnaryExpression('abs()', expression);

  /// Creates a function expression which evaluates to the inverse cosine of the
  /// given numeric [expression].
  static ExpressionInterface acos(ExpressionInterface expression) =>
      UnaryExpression('acos()', expression);

  /// Creates a function expression which evaluates to the inverse sine of the
  /// given numeric [expression].
  static ExpressionInterface asin(ExpressionInterface expression) =>
      UnaryExpression('asin()', expression);

  /// Creates a function expression which evaluates to the inverse tangent of
  /// the given numeric [expression].
  static ExpressionInterface atan(ExpressionInterface expression) =>
      UnaryExpression('atan()', expression);

  /// Creates a function expression which evaluates to the arctangent of
  /// [y]/[x].
  static ExpressionInterface atan2({
    required ExpressionInterface y,
    required ExpressionInterface x,
  }) =>
      BinaryExpression('atan2()', y, x);

  /// Creates a function expression which evaluates to the ceiling of the given
  /// numeric [expression].
  static ExpressionInterface ceil(ExpressionInterface expression) =>
      UnaryExpression('ceil()', expression);

  /// Creates a function expression which evaluates to the cosine of the given
  /// numeric [expression].
  static ExpressionInterface cos(ExpressionInterface expression) =>
      UnaryExpression('cos()', expression);

  /// Creates a function expression which evaluates to the degree value of the
  /// given radians numeric [expression].
  static ExpressionInterface degrees(ExpressionInterface expression) =>
      UnaryExpression('degrees()', expression);

  /// Creates a function expression which evaluates to the mathematical constant
  /// `e`.
  static ExpressionInterface e() => NullaryExpression('e()');

  /// Creates a function expression which evaluates [e] to the power of the
  /// given numeric [expression].
  static ExpressionInterface exp(ExpressionInterface expression) =>
      UnaryExpression('exp()', expression);

  /// Creates a function expression which evaluates to the floor of the given
  /// numeric [expression].
  static ExpressionInterface floor(ExpressionInterface expression) =>
      UnaryExpression('floor()', expression);

  /// Creates a function expression which evaluates to the natural log of the
  /// given numeric [expression].
  static ExpressionInterface ln(ExpressionInterface expression) =>
      UnaryExpression('ln()', expression);

  /// Creates a function expression which evaluates to the base 10 log of the
  /// given numeric [expression].
  static ExpressionInterface log(ExpressionInterface expression) =>
      UnaryExpression('log()', expression);

  /// Creates a function expression which evaluates to the mathematical constant
  /// `Pi`.
  static ExpressionInterface pi() => NullaryExpression('pi()');

  /// Creates a function expression which evaluates to value of the [base] to
  /// the power of the [exponent].
  static ExpressionInterface power({
    required ExpressionInterface base,
    required ExpressionInterface exponent,
  }) =>
      BinaryExpression('power()', base, exponent);

  /// Creates a function expression which evaluates to the radians value of the
  /// given degree numeric [expression].
  static ExpressionInterface radians(ExpressionInterface expression) =>
      UnaryExpression('radians()', expression);

  /// Creates a function expression which rounds the given numeric [expression]
  /// to the given number of [digits].
  static ExpressionInterface round(
    ExpressionInterface expression, {
    ExpressionInterface? digits,
  }) =>
      BinaryExpression('round()', expression, digits);

  /// Creates a function expression which evaluates to the sing (1: positive,
  /// -1: negative, 0: zero) of the given degree numeric [expression].
  static ExpressionInterface sign(ExpressionInterface expression) =>
      UnaryExpression('sign()', expression);

  /// Creates a function expression which evaluates to the sine of the given
  /// numeric [expression].
  static ExpressionInterface sin(ExpressionInterface expression) =>
      UnaryExpression('sin()', expression);

  /// Creates a function expression which evaluates to the square root of the
  /// given numeric [expression].
  static ExpressionInterface sqrt(ExpressionInterface expression) =>
      UnaryExpression('sqrt()', expression);

  /// Creates a function expression which evaluates to the tangent of the given
  /// numeric [expression].
  static ExpressionInterface tan(ExpressionInterface expression) =>
      UnaryExpression('tan()', expression);

  /// Creates a function expression which truncates the given numeric
  /// [expression] to the given number of decimal [digits].
  static ExpressionInterface trunc(
    ExpressionInterface expression, {
    ExpressionInterface? digits,
  }) =>
      BinaryExpression('trunc()', expression, digits);

  /// Creates a function expression which evaluates to whether the given string
  /// [expression] contains the given [substring].
  static ExpressionInterface contains(
    ExpressionInterface expression, {
    required ExpressionInterface substring,
  }) =>
      BinaryExpression('contains()', expression, substring);

  /// Creates a function expression which evaluates to the length of the given
  /// string [expression].
  static ExpressionInterface length(ExpressionInterface expression) =>
      UnaryExpression('length()', expression);

  /// Creates a function expression which evaluates to the lower case string of
  /// the given string [expression].
  static ExpressionInterface lower(ExpressionInterface expression) =>
      UnaryExpression('lower()', expression);

  /// Creates a function expression which evaluates to the given string
  /// [expression] with the whitespace on the left side removed.
  static ExpressionInterface ltrim(ExpressionInterface expression) =>
      UnaryExpression('ltrim()', expression);

  /// Creates a function expression which evaluates to the given string
  /// [expression] with the whitespace on the right side removed.
  static ExpressionInterface rtrim(ExpressionInterface expression) =>
      UnaryExpression('rtrim()', expression);

  /// Creates a function expression which evaluates to the given string
  /// [expression] with the whitespace on the bose sides removed.
  static ExpressionInterface trim(ExpressionInterface expression) =>
      UnaryExpression('trim()', expression);

  /// Creates a function expression which evaluates to the upper case string of
  /// the given string [expression].
  static ExpressionInterface upper(ExpressionInterface expression) =>
      UnaryExpression('upper()', expression);

  /// Creates a function expression which evaluates to the number of
  /// milliseconds since the unix epoch of the given ISO 8601 date string
  /// [expression].
  ///
  /// Valid date strings must start with a date in the form `YYYY-MM-DD` (time
  /// only string are not supported).
  ///
  /// Times can be of the form `HH:MM`, `HH:MM:SS`, or `HH:MM:SS.FFF`. The
  /// leading zero is not optional (i.e. 02 is ok, 2 is not). Hours are in
  /// 24-hour format. `FFF` represent milliseconds, and _trailing_ zeros are
  /// optional (i.e. 5 == 500).
  ///
  /// The time zone can be in one of three forms: `(+/-)HH:MM`, `(+/-)HHMM` and
  /// `Z` which represents UTC.
  ///
  /// If no time zone is present the the device local time zone is used.
  static ExpressionInterface stringToMillis(ExpressionInterface expression) =>
      UnaryExpression('str_to_millis()', expression);

  /// Creates a function expression which evaluates to the ISO 8601 UTC date
  /// time string of the given ISO 8601 date string [expression].
  ///
  /// Valid date strings must start with a date in the form `YYYY-MM-DD` (time
  /// only string are not supported).
  ///
  /// Times can be of the form `HH:MM`, `HH:MM:SS`, or `HH:MM:SS.FFF`. The
  /// leading zero is not optional (i.e. 02 is ok, 2 is not). Hours are in
  /// 24-hour format. `FFF` represent milliseconds, and _trailing_ zeros are
  /// optional (i.e. 5 == 500).
  ///
  /// The time zone can be in one of three forms: `(+/-)HH:MM`, `(+/-)HHMM` and
  /// `Z` which represents UTC.
  ///
  /// If no time zone is present the the device local time zone is used.
  static ExpressionInterface stringToUTC(ExpressionInterface expression) =>
      UnaryExpression('str_to_utc()', expression);

  /// Creates a function expression which evaluates to the ISO 8601 date string
  /// in the device local timezone of the given milliseconds since the unix
  /// epoch [expression].
  static ExpressionInterface millisToString(ExpressionInterface expression) =>
      UnaryExpression('millis_to_str()', expression);

  /// Creates a function expression which evaluates to the UTC ISO 8601 date
  /// string of the given milliseconds since the unix epoch [expression].
  static ExpressionInterface millisToUTC(ExpressionInterface expression) =>
      UnaryExpression('millis_to_utc()', expression);
}
