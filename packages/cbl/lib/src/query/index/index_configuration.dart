import 'package:cbl_ffi/cbl_ffi.dart';
import 'package:collection/collection.dart';

import 'index.dart';

/// A specification of an [Index] through a list of N1QL [expressions].
abstract class IndexConfiguration extends Index {
  /// The N1QL expressions to use to create the index.
  List<String> get expressions;
  set expressions(List<String> value);
}

/// A specification of a value [Index] through a list of N1QL [expressions].
abstract class ValueIndexConfiguration extends IndexConfiguration {
  /// Creates a specification of a value [Index] through a list of N1QL
  /// [expressions].
  factory ValueIndexConfiguration(List<String> expressions) =>
      _ValueIndexConfiguration(expressions);
}

/// A specification of a full text [Index] through a list of N1QL [expressions].
abstract class FullTextIndexConfiguration extends IndexConfiguration {
  /// Creates a specification of a full text [Index] through a list of N1QL
  /// [expressions].
  factory FullTextIndexConfiguration(
    List<String> expressions, {
    bool? ignoreAccents,
    String? language,
  }) =>
      _FullTextIndexConfiguration(expressions, ignoreAccents, language);

  /// Whether the index should ignore accents and diacritical marks.
  ///
  /// The default is `false`.
  bool get ignoreAccents;
  set ignoreAccents(bool value);

  /// The dominant language. Setting this enables word stemming, i.e.
  /// matching different cases of the same word ("big" and "bigger", for
  /// instance) and ignoring common "stop-words" ("the", "a", "of", etc.)
  ///
  /// Can be an ISO-639 language code or a lowercase (English) language name;
  /// supported languages are: da/danish, nl/dutch, en/english, fi/finnish,
  /// fr/french, de/german, hu/hungarian, it/italian, no/norwegian,
  /// pt/portuguese, ro/romanian, ru/russian, es/spanish, sv/swedish,
  /// tr/turkish.
  ///
  /// If left `null`, or set to an unrecognized language, no language-specific
  /// behaviors such as stemming and stop-word removal occur.
  String? get language;
  set language(String? value);
}

// === Impl ====================================================================

class _ValueIndexConfiguration
    implements ValueIndexConfiguration, IndexImplInterface {
  _ValueIndexConfiguration(this.expressions);

  @override
  List<String> expressions;

  @override
  CBLIndexSpec toCBLIndexSpec() => CBLIndexSpec(
        expressionLanguage: CBLQueryLanguage.n1ql,
        expressions: expressions.join(', '),
        type: CBLIndexType.value,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ValueIndexConfiguration &&
          const DeepCollectionEquality().equals(expressions, other.expressions);

  @override
  int get hashCode => const DeepCollectionEquality().hash(expressions);

  @override
  String toString() => 'ValueIndexConfiguration(${expressions.join(', ')})';
}

class _FullTextIndexConfiguration
    implements FullTextIndexConfiguration, IndexImplInterface {
  _FullTextIndexConfiguration(
    this.expressions,
    bool? ignoreAccents,
    this.language,
  ) : ignoreAccents = ignoreAccents ?? false;

  @override
  List<String> expressions;

  @override
  bool ignoreAccents;

  @override
  String? language;

  @override
  CBLIndexSpec toCBLIndexSpec() => CBLIndexSpec(
        expressionLanguage: CBLQueryLanguage.n1ql,
        expressions: expressions.join(', '),
        type: CBLIndexType.fullText,
        ignoreAccents: ignoreAccents,
        language: language,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _FullTextIndexConfiguration &&
          const DeepCollectionEquality()
              .equals(expressions, other.expressions) &&
          ignoreAccents == other.ignoreAccents &&
          language == other.language;

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(expressions) ^
      ignoreAccents.hashCode ^
      language.hashCode;

  @override
  String toString() {
    final properties = [
      if (ignoreAccents) 'IGNORE-ACCENTS',
      if (language != null) 'language: $language',
    ];

    return [
      'FullTextIndexConfiguration(',
      '${expressions.join(', ')}',
      if (properties.isNotEmpty) '| ',
      properties.join(', '),
      ')'
    ].join('');
  }
}
