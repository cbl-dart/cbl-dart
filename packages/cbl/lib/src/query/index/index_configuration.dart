// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:collection/collection.dart';

import '../../bindings.dart';
import 'index.dart';

/// A specification of an [Index] through a list of N1QL [expressions].
///
/// {@category Query}
abstract class IndexConfiguration extends Index {
  /// The N1QL expressions to use to create the index.
  List<String> get expressions;
  set expressions(List<String> value);
}

/// A specification of a value [Index] through a list of N1QL [expressions].
///
/// {@category Query}
abstract class ValueIndexConfiguration extends IndexConfiguration {
  /// Creates a specification of a value [Index] through a list of N1QL
  /// [expressions].
  factory ValueIndexConfiguration(List<String> expressions) =>
      _ValueIndexConfiguration(expressions);
}

/// A specification of a full text [Index] through a list of N1QL [expressions].
///
/// {@category Query}
abstract class FullTextIndexConfiguration extends IndexConfiguration {
  /// Creates a specification of a full text [Index] through a list of N1QL
  /// [expressions].
  factory FullTextIndexConfiguration(
    List<String> expressions, {
    bool? ignoreAccents,
    FullTextLanguage? language,
  }) =>
      _FullTextIndexConfiguration(expressions, ignoreAccents, language);

  /// Whether the index should ignore accents and diacritical marks.
  ///
  /// The default is `false`.
  bool get ignoreAccents;
  set ignoreAccents(bool value);

  /// The dominant language.
  ///
  /// Setting this enables word stemming, i.e. matching different cases of the
  /// same word ("big" and "bigger", for instance) and ignoring common
  /// "stop-words" ("the", "a", "of", etc.)
  ///
  /// If left `null` no language-specific behaviors such as stemming and
  /// stop-word removal occur.
  FullTextLanguage? get language;
  set language(FullTextLanguage? value);
}

// === Impl ====================================================================

abstract class _IndexConfiguration extends IndexConfiguration {
  _IndexConfiguration(List<String> expressions) {
    this.expressions = expressions;
  }

  List<String> _expressions = [];

  @override
  List<String> get expressions => _expressions;

  @override
  set expressions(List<String> expressions) {
    if (expressions.isEmpty) {
      throw ArgumentError.value(
        expressions,
        'expressions',
        'must not be empty',
      );
    }
    _expressions = expressions;
  }
}

class _ValueIndexConfiguration extends _IndexConfiguration
    implements ValueIndexConfiguration, IndexImplInterface {
  _ValueIndexConfiguration(super.expressions);

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
          runtimeType == other.runtimeType &&
          const DeepCollectionEquality().equals(expressions, other.expressions);

  @override
  int get hashCode => const DeepCollectionEquality().hash(expressions);

  @override
  String toString() => 'ValueIndexConfiguration(${expressions.join(', ')})';
}

class _FullTextIndexConfiguration extends _IndexConfiguration
    implements FullTextIndexConfiguration, IndexImplInterface {
  _FullTextIndexConfiguration(
    super.expressions,
    // ignore: avoid_positional_boolean_parameters
    bool? ignoreAccents,
    this.language,
  ) : ignoreAccents = ignoreAccents ?? false;

  @override
  bool ignoreAccents;

  @override
  FullTextLanguage? language;

  @override
  CBLIndexSpec toCBLIndexSpec() => CBLIndexSpec(
        expressionLanguage: CBLQueryLanguage.n1ql,
        expressions: expressions.join(', '),
        type: CBLIndexType.fullText,
        ignoreAccents: ignoreAccents,
        language: language?.name,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _FullTextIndexConfiguration &&
          runtimeType == other.runtimeType &&
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
      if (language != null) 'language: ${language!.name}',
    ];

    return [
      'FullTextIndexConfiguration(',
      expressions.join(', '),
      if (properties.isNotEmpty) ' | ',
      properties.join(', '),
      ')'
    ].join();
  }
}
