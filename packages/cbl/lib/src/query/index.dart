import 'query.dart';

/// Indexes are used to speed up queries by allowing fast -- O(log n) -- lookup
/// of documents that have specific values or ranges of values. The values may
/// be properties, or expressions based on properties.
///
/// An index will speed up queries that use the expression it indexes, but it
/// takes up space in the database file, and it slows down document saves
/// slightly because it needs to be kept up to date when documents change.
///
/// Tuning a database with indexes can be a tricky task. Fortunately, a lot has
/// been written about it in the relational-database (SQL) realm, and much of
/// that advice holds for Couchbase Lite. You may find SQLite's documentation
/// particularly helpful since Couchbase Lite's querying is based on SQLite.
///
/// Two types of indexes are currently supported:
/// - [ValueIndex]
/// - [FullTextIndex]
///
/// See:
/// - [Query.explain] for tuning performance with indexes.
abstract class Index {
  /// A JSON array describing each column of the index.
  ///
  /// The language to describe an index in, is a subset of the
  /// JSON query language [schema](https://github.com/couchbase/couchbase-lite-core/wiki/JSON-Query-Schema).
  ///
  /// See:
  /// - [JSON Query - Indexes](https://github.com/couchbase/couchbase-lite-core/wiki/JSON-Query-Schema#9-indexes)
  String get expressions;
}

/// Value indexes speed up queries by making it possible to look up property
/// (or expression) values without scanning every document.
///
/// They're just like regular indexes in SQL or N1QL. Multiple expressions are
/// supported; the first is the primary key, second is secondary. Expressions
/// must evaluate to scalar types (boolean, number, string).
class ValueIndex extends Index {
  ValueIndex(this.expressions);

  @override
  final String expressions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValueIndex &&
          runtimeType == other.runtimeType &&
          expressions == other.expressions;

  @override
  int get hashCode => expressions.hashCode;

  @override
  String toString() => 'ValueIndex($expressions)';
}

/// Full-Text Search (FTS) indexes enable fast search of natural-language words
/// or phrases by using the `MATCH` operator in a query.
///
/// A FTS index is **required** for full-text search: a query with a `MATCH`
/// operator will fail to compile unless there is already a FTS index for the
/// property/expression being matched. Only a single expression is currently
/// allowed, and it must evaluate to a string.
class FullTextIndex extends Index {
  FullTextIndex(
    this.expressions, {
    this.ignoreAccents = false,
    this.language,
  });

  @override
  final String expressions;

  /// Should diacritical marks (accents) be ignored?
  /// Defaults to `false`. Generally this should be left `false` for non-English
  /// text.
  final bool ignoreAccents;

  /// The dominant language.
  ///
  /// Setting this enables word stemming, i.e. matching different cases of the
  /// same word ("big" and "bigger", for instance) and ignoring common
  /// "stop-words" ("the", "a", "of", etc.)
  ///
  /// Can be an ISO-639 language code or a lowercase (English) language name;
  /// supported languages are: da/danish, nl/dutch, en/english, fi/finnish,
  /// fr/french, de/german, hu/hungarian, it/italian, no/norwegian,
  /// pt/portuguese, ro/romanian, ru/russian, es/spanish, sv/swedish,
  /// tr/turkish.
  ///
  /// If left `null`,  or set to an unrecognized language, no language-specific
  /// behaviors such as stemming and stop-word removal occur.
  final String? language;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FullTextIndex &&
          runtimeType == other.runtimeType &&
          expressions == other.expressions &&
          ignoreAccents == other.ignoreAccents &&
          language == other.language;

  @override
  int get hashCode =>
      expressions.hashCode ^ ignoreAccents.hashCode ^ language.hashCode;

  @override
  String toString() => 'FullTextIndex($expressions, '
      'ignoreAccents: $ignoreAccents, '
      'language: $language)';
}
