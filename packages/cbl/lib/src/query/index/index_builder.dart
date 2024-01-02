import 'dart:convert';

import '../../bindings.dart';
import '../../support/utils.dart';
import '../expressions/expression.dart';
import 'index.dart';

/// A value index for regular queries.
///
/// {@category Query}
class ValueIndex extends Index {
  /// Creates a value index from the [ValueIndexItem]s to index.
  factory ValueIndex(Iterable<ValueIndexItem> items) => ValueIndexImpl(items);
}

/// An item in a [ValueIndex].
///
/// {@category Query}
class ValueIndexItem {
  /// Creates a value index item from a [propertyPath] to index.
  factory ValueIndexItem.property(String propertyPath) =>
      ValueIndexItem.expression(Expression.property(propertyPath));

  /// Creates a value index item from an [expression] to index.
  ValueIndexItem.expression(ExpressionInterface expression)
      : _expression = expression as ExpressionImpl;

  final ExpressionImpl _expression;
}

/// A full-text search index for full-text search queries with the `MATCH`
/// operator.
///
/// {@category Query}
abstract class FullTextIndex extends Index {
  /// Creates a full text index from the [FullTextIndexItem]s to index.
  factory FullTextIndex(Iterable<FullTextIndexItem> items) =>
      FullTextIndexImpl(items: items);

  /// Specifies whether the index ignores accents and diacritical marks.
  ///
  /// The default value is `false`.
  // ignore: avoid_positional_boolean_parameters
  FullTextIndex ignoreAccents(bool ignoreAccents);

  /// Specifies the dominant language of the index.
  ///
  /// Specifying this enables word stemming, i.e. matching different cases of
  /// the same word ("big" and "bigger", for instance) and ignoring common
  /// "stop-words" ("the", "a", "of", etc.)
  ///
  /// If left unspecified, no language-specific behaviors such as stemming and
  /// stop-word removal occur.
  FullTextIndex langauge(FullTextLanguage language);
}

/// An item in a [FullTextIndexItem].
///
/// {@category Query}
class FullTextIndexItem {
  /// Creates a full-text index item from a [propertyPath] to index.
  FullTextIndexItem.property(String propertyPath)
      : _expression = Expression.property(propertyPath) as ExpressionImpl;

  final ExpressionImpl _expression;
}

/// Factor to create query indexes.
///
/// {@category Query}
class IndexBuilder {
  IndexBuilder._();

  /// Creates a value index with the given value index [items].
  ///
  /// The index items are a list of the properties or expression to be indexed.
  static ValueIndex valueIndex(Iterable<ValueIndexItem> items) =>
      ValueIndex(items);

  /// Creates a full-text index with the given full-text index [items].
  ///
  /// Typically the index items are the properties that are used to perform the
  /// match operation against.
  static FullTextIndex fullTextIndex(Iterable<FullTextIndexItem> items) =>
      FullTextIndex(items);
}

// === Impl ====================================================================

class ValueIndexImpl implements IndexImplInterface, ValueIndex {
  ValueIndexImpl(Iterable<ValueIndexItem> items) : _items = items.toList();

  final List<ValueIndexItem> _items;

  @override
  CBLIndexSpec toCBLIndexSpec() => CBLIndexSpec(
        expressionLanguage: CBLQueryLanguage.json,
        type: CBLIndexType.value,
        expressions: _items
            .map((item) => item._expression.toJson())
            .toList()
            .let(jsonEncode),
      );
}

class FullTextIndexImpl implements IndexImplInterface, FullTextIndex {
  FullTextIndexImpl({
    required Iterable<FullTextIndexItem> items,
    bool ignoreAccents = false,
    FullTextLanguage? language,
  })  : _items = items.toList(),
        _ignoreAccents = ignoreAccents,
        _language = language;

  final List<FullTextIndexItem> _items;
  final bool _ignoreAccents;
  final FullTextLanguage? _language;

  @override
  FullTextIndex ignoreAccents(bool ignoreAccents) => FullTextIndexImpl(
        items: _items,
        ignoreAccents: ignoreAccents,
        language: _language,
      );

  @override
  FullTextIndex langauge(FullTextLanguage language) => FullTextIndexImpl(
        items: _items,
        ignoreAccents: _ignoreAccents,
        language: language,
      );

  @override
  CBLIndexSpec toCBLIndexSpec() => CBLIndexSpec(
        expressionLanguage: CBLQueryLanguage.json,
        type: CBLIndexType.fullText,
        expressions: _items
            .map((item) => item._expression.toJson())
            .toList()
            .let(jsonEncode),
        ignoreAccents: _ignoreAccents,
        language: _language?.name,
      );
}
