import '../expressions/expression.dart';

/// Factory for creating full-text search function expressions.
///
/// {@category Query Builder}
class FullTextFunction {
  FullTextFunction._();

  /// Creates an expression which evaluates to the rank of a result when
  /// matching against the full-text index with given [indexName].
  ///
  /// The rank indicates how well a result matches the full-text query.
  static ExpressionInterface rank(String indexName) =>
      UnaryExpression('rank()', Expression.string(indexName));

  /// Creates a full-text match expression against the full-text index of the
  /// given [indexName] and with the given full-text [query].
  static ExpressionInterface match({
    required String indexName,
    required String query,
  }) =>
      BinaryExpression(
        'match()',
        Expression.string(indexName),
        Expression.string(query),
      );
}
