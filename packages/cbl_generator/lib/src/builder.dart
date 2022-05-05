import 'package:build/build.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

import 'generator.dart';

class TypedDataBuilder extends PartBuilder {
  TypedDataBuilder({BuilderOptions? options})
      : super(
          [
            TypedDocumentGenerator(),
            TypedDictionaryGenerator(),
          ],
          '.cbl.type.g.dart',
          header: header,
          options: options,
        );

  static const _ignoredLints = [
    'avoid_positional_boolean_parameters',
    'lines_longer_than_80_chars',
    'invalid_use_of_internal_member',
    'parameter_assignments',
    'unnecessary_const',
    'prefer_relative_imports',
    'avoid_equals_and_hash_code_on_mutable_classes',
  ];

  @visibleForTesting
  static final header = '''
$defaultFileHeader
// ignore_for_file: ${_ignoredLints.join(', ')}
''';
}

class TypedDatabaseBuilder extends LibraryBuilder {
  TypedDatabaseBuilder({BuilderOptions? options})
      : super(
          TypedDatabaseGenerator(),
          generatedExtension: '.cbl.database.g.dart',
          header: header,
          options: options,
        );

  static const _ignoredLints = [
    'avoid_classes_with_only_static_members',
    'lines_longer_than_80_chars',
    'directives_ordering',
    'avoid_redundant_argument_values',
  ];

  @visibleForTesting
  static final header = '''
$defaultFileHeader
// ignore_for_file: ${_ignoredLints.join(', ')}
''';
}
