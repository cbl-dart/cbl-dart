// ignore_for_file: invalid_use_of_internal_member

import 'package:cbl/cbl.dart';
import 'package:cbl/src/typed_data/collection.dart';

import '../../test_binding_impl.dart';
import '../fixtures/values.dart';
import '../test_binding.dart' hide TypeMatcher;
import '../utils/matchers.dart';

void main() {
  setupTestBinding();

  group('TypedDataHelpers', () {
    test('converters for builtin types exist', () {
      expect(TypedDataHelpers.stringConverter.toTyped('a'), 'a');
      expect(TypedDataHelpers.intConverter.toTyped(1), 1);
      expect(TypedDataHelpers.doubleConverter.toTyped(1.0), 1.0);
      expect(TypedDataHelpers.numConverter.toTyped(1), 1);
      expect(TypedDataHelpers.numConverter.toTyped(1.0), 1.0);
      expect(TypedDataHelpers.boolConverter.toTyped(true), true);
      expect(TypedDataHelpers.blobConverter.toTyped(testBlob), testBlob);
      final now = DateTime.now();
      expect(
        TypedDataHelpers.dateTimeConverter.toTyped(now.toIso8601String()),
        now,
      );
    });

    group('readProperty', () {
      test('can ready property', () {
        expect(
          TypedDataHelpers.readProperty(
            internal: MutableDictionary({'a': 'b'}),
            name: 'a',
            key: 'a',
            converter: TypedDataHelpers.stringConverter,
          ),
          'b',
        );
      });

      test('throws when property does not exists', () {
        expect(
          () => TypedDataHelpers.readProperty(
            internal: MutableDictionary(),
            name: 'name',
            key: 'a',
            converter: TypedDataHelpers.stringConverter,
          ),
          throwsA(
            isTypedDataException
                .havingCode(TypedDataErrorCode.dataMismatch)
                .havingMessage(
                  'Expected a value for property "name" but there is none in '
                  'the underlying data at key "a".',
                ),
          ),
        );
      });

      test('throws when property is null', () {
        expect(
          () => TypedDataHelpers.readProperty(
            internal: MutableDictionary({'a': null}),
            name: 'name',
            key: 'a',
            converter: TypedDataHelpers.stringConverter,
          ),
          throwsA(
            isTypedDataException
                .havingCode(TypedDataErrorCode.dataMismatch)
                .havingMessage(
                  'Expected a value for property "name" but found "null" in '
                  'the underlying data at key "a".',
                ),
          ),
        );
      });

      test('throws when underlying data has unexpected type', () {
        expect(
          () => TypedDataHelpers.readProperty(
            internal: MutableDictionary({'a': false}),
            name: 'name',
            key: 'a',
            converter: TypedDataHelpers.stringConverter,
          ),
          throwsA(
            isTypedDataException
                .havingCode(TypedDataErrorCode.dataMismatch)
                .havingMessage(
                  'Type error for property "name" at key "a": '
                  'UnexpectedTypeException: Expected a value of type String, '
                  'but got a bool.',
                ),
          ),
        );
      });
    });

    group('readNullableProperty', () {
      test('can ready property', () {
        expect(
          TypedDataHelpers.readNullableProperty(
            internal: MutableDictionary({'a': 'b'}),
            name: 'a',
            key: 'a',
            converter: TypedDataHelpers.stringConverter,
          ),
          'b',
        );
      });

      test('returns null if property has null as value', () {
        expect(
          TypedDataHelpers.readNullableProperty(
            internal: MutableDictionary({'a': null}),
            name: 'a',
            key: 'a',
            converter: TypedDataHelpers.stringConverter,
          ),
          isNull,
        );
      });

      test('returns null if property does not exists', () {
        expect(
          TypedDataHelpers.readNullableProperty(
            internal: MutableDictionary(),
            name: 'a',
            key: 'a',
            converter: TypedDataHelpers.stringConverter,
          ),
          isNull,
        );
      });

      test('throws when underlying data has unexpected type', () {
        expect(
          () => TypedDataHelpers.readNullableProperty(
            internal: MutableDictionary({'a': false}),
            name: 'name',
            key: 'a',
            converter: TypedDataHelpers.stringConverter,
          ),
          throwsA(
            isTypedDataException
                .havingCode(TypedDataErrorCode.dataMismatch)
                .havingMessage(
                  'Type error for property "name" at key "a": '
                  'UnexpectedTypeException: Expected a value of type String, '
                  'but got a bool.',
                ),
          ),
        );
      });
    });

    group('writeProperty', () {
      test('can write property', () {
        final dict = MutableDictionary();
        TypedDataHelpers.writeProperty(
          internal: dict,
          key: 'a',
          value: 'b',
          converter: TypedDataHelpers.stringConverter,
        );
        expect(dict.toPlainMap(), {'a': 'b'});
      });
    });

    group('writeNullableProperty', () {
      test('can write property', () {
        final dict = MutableDictionary();
        TypedDataHelpers.writeNullableProperty(
          internal: dict,
          key: 'a',
          value: 'b',
          converter: TypedDataHelpers.stringConverter,
        );
        expect(dict.toPlainMap(), {'a': 'b'});
      });

      test('removes property when value is null', () {
        final dict = MutableDictionary({'a': 'b'});
        TypedDataHelpers.writeNullableProperty(
          internal: dict,
          key: 'a',
          value: null,
          converter: TypedDataHelpers.stringConverter,
        );
        expect(dict.toPlainMap(), isEmpty);
      });
    });

    group('renderString', () {
      test('without indentation', () {
        expect(
          TypedDataHelpers.renderString(
            indent: null,
            className: 'A',
            fields: {},
          ),
          'A()',
        );
        expect(
          TypedDataHelpers.renderString(
            indent: null,
            className: 'A',
            fields: {'a': 'b'},
          ),
          'A(a: b)',
        );
        expect(
          TypedDataHelpers.renderString(
            indent: null,
            className: 'A',
            fields: {'a': null},
          ),
          'A(a: null)',
        );
        expect(
          TypedDataHelpers.renderString(
            indent: null,
            className: 'A',
            fields: {'a': RenderStringTestDict()},
          ),
          'A(a: RenderStringTestDict(a: b))',
        );
        expect(
          TypedDataHelpers.renderString(
            indent: null,
            className: 'A',
            fields: {
              'a': ImmutableTypedDataList(
                internal: MutableArray([]),
                isNullable: false,
                converter: TypedDataHelpers.stringConverter,
              )
            },
          ),
          'A(a: [])',
        );
        expect(
          TypedDataHelpers.renderString(
            indent: null,
            className: 'A',
            fields: {
              'a': ImmutableTypedDataList(
                internal: MutableArray(['a']),
                isNullable: false,
                converter: TypedDataHelpers.stringConverter,
              )
            },
          ),
          'A(a: [a])',
        );
        expect(
          TypedDataHelpers.renderString(
            indent: null,
            className: 'A',
            fields: {
              'a': ImmutableTypedDataList(
                internal: MutableArray([
                  ['a']
                ]),
                isNullable: false,
                converter: const TypedListConverter(
                  converter: TypedDataHelpers.stringConverter,
                  isNullable: false,
                  isCached: false,
                ),
              )
            },
          ),
          'A(a: [[a]])',
        );
      });

      test('with indentation', () {
        expect(
          TypedDataHelpers.renderString(
            indent: '  ',
            className: 'A',
            fields: {},
          ),
          'A()',
        );
        expect(
          TypedDataHelpers.renderString(
            indent: '  ',
            className: 'A',
            fields: {'a': 'b'},
          ),
          '''
A(
  a: b,
)''',
        );
        expect(
          TypedDataHelpers.renderString(
            indent: '  ',
            className: 'A',
            fields: {'a': 'b'},
          ),
          '''
A(
  a: b,
)''',
        );
        expect(
          TypedDataHelpers.renderString(
            indent: '  ',
            className: 'A',
            fields: {'a': null},
          ),
          '''
A(
  a: null,
)''',
        );
        expect(
          TypedDataHelpers.renderString(
            indent: '  ',
            className: 'A',
            fields: {'a': RenderStringTestDict()},
          ),
          '''
A(
  a: RenderStringTestDict(
    a: b,
  ),
)''',
        );
        expect(
          TypedDataHelpers.renderString(
            indent: '  ',
            className: 'A',
            fields: {
              'a': ImmutableTypedDataList(
                internal: MutableArray([]),
                isNullable: false,
                converter: TypedDataHelpers.stringConverter,
              )
            },
          ),
          '''
A(
  a: [],
)''',
        );
        expect(
          TypedDataHelpers.renderString(
            indent: '  ',
            className: 'A',
            fields: {
              'a': ImmutableTypedDataList(
                internal: MutableArray(['a']),
                isNullable: false,
                converter: TypedDataHelpers.stringConverter,
              )
            },
          ),
          '''
A(
  a: [
    a,
  ],
)''',
        );
        expect(
          TypedDataHelpers.renderString(
            indent: '  ',
            className: 'A',
            fields: {
              'a': ImmutableTypedDataList(
                internal: MutableArray([
                  ['a']
                ]),
                isNullable: false,
                converter: const TypedListConverter(
                  converter: TypedDataHelpers.stringConverter,
                  isNullable: false,
                  isCached: false,
                ),
              )
            },
          ),
          '''
A(
  a: [
    [
      a,
    ],
  ],
)''',
        );
      });
    });
  });
}

class RenderStringTestDict extends TypedDictionaryObject {
  @override
  dynamic noSuchMethod(Invocation invocation) {}

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'RenderStringTestDict',
        fields: {
          'a': 'b',
        },
      );
}
