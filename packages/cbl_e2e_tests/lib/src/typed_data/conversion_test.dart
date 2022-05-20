// ignore_for_file: invalid_use_of_internal_member

import 'package:cbl/cbl.dart' hide TypeMatcher;
import 'package:cbl/src/typed_data/collection.dart';
import 'package:cbl/src/typed_data/conversion.dart';

import '../../test_binding_impl.dart';
import '../document/document_test_utils.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('NonPromotingDataConverter', () {
    test('promote returns value as is', () {
      // ignore: unnecessary_type_check
      assert(const IdentityConverter<String>() is NonPromotingDataConverter);
      expect(const IdentityConverter<String>().promote('a'), 'a');
    });
  });

  group('UnexpectedTypeException', () {
    test('message', () {
      expect(
        const UnexpectedTypeException(value: null, expectedTypes: [String])
            .message,
        'Expected a value of type String, but got a Null.',
      );
      expect(
        const UnexpectedTypeException(
          value: null,
          expectedTypes: [String, int],
        ).message,
        'Expected a value of type String or int, but got a Null.',
      );
    });
  });

  group('IdentityConverter', () {
    group('toTyped', () {
      test('returns value of expected type as is', () {
        expect(const IdentityConverter<String>().toTyped('a'), 'a');
      });

      test('throws if value is of unexpected type', () {
        expect(
          () => const IdentityConverter<String>().toTyped(1),
          throwsA(
            isUnexpectedTypeException
                .havingExpectedTypes([String]).havingValue(1),
          ),
        );
      });
    });

    group('toUntyped', () {
      test('returns value as is', () {
        expect(const IdentityConverter<String>().toUntyped('a'), 'a');
      });
    });
  });

  group('DateTimeConverter', () {
    group('toTyped', () {
      test('parses String to DateTime', () {
        final now = DateTime.now();
        expect(const DateTimeConverter().toTyped(now.toIso8601String()), now);
      });

      test('throws if value is not a String', () {
        expect(
          () => const DateTimeConverter().toTyped(1),
          throwsA(
            isUnexpectedTypeException
                .havingExpectedTypes([String]).havingValue(1),
          ),
        );
      });
    });

    group('toUntyped', () {
      test('returns ISO8601 string', () {
        final now = DateTime.now();
        expect(const DateTimeConverter().toUntyped(now), now.toIso8601String());
      });
    });
  });

  group('TypedDictionaryConverter', () {
    group('toTyped', () {
      test('creates and returns typed dictionary', () {
        final dict = MutableDictionary();
        final typedDict =
            const TypedDictionaryConverter(ConverterTestDict.new).toTyped(dict);
        expect(typedDict.internal, same(dict));
      });

      test('throws if value is not a of the expected type', () {
        const converter = TypedDictionaryConverter(ConverterTestDict.new);
        expect(
          () => converter.toTyped(1),
          throwsA(
            isUnexpectedTypeException
                .havingExpectedTypes([MutableDictionary]).havingValue(1),
          ),
        );
      });
    });

    group('toUntyped', () {
      test('returns internal container', () {
        final dict = MutableDictionary();
        final typedDict = ConverterTestDict(dict);
        const converter = TypedDictionaryConverter(ConverterTestDict.new);
        expect(converter.toUntyped(typedDict), same(dict));
      });
    });

    group('promote', () {
      test('returns value as is if it is the mutable variant', () {
        final typedDict = MutableConverterTestDict(MutableDictionary());
        const converter =
            TypedDictionaryConverter(MutableConverterTestDict.new);
        expect(converter.promote(typedDict), same(typedDict));
      });

      test('returns mutable copy if value is immutable variant', () {
        final typedDict = ConverterTestDict(MutableDictionary());
        const converter =
            TypedDictionaryConverter(MutableConverterTestDict.new);
        final promoted = converter.promote(typedDict);
        expect(promoted, isNot(same(typedDict)));
        expect(promoted.internal, same(typedDict.internal));
      });
    });
  });

  group('TypedListConverter', () {
    group('toTyped', () {
      test('creates ImmutableTypedDataList from Array', () {
        const converter = TypedListConverter(
          converter: TypedDataHelpers.stringConverter,
          isCached: false,
          isNullable: false,
        );
        final array = immutableArray();
        final list = converter.toTyped(array);
        expect(list.internal, same(array));
        expect(list, isA<ImmutableTypedDataList>());
      });

      test('creates MutableTypedDataList from MutableArray', () {
        const converter = TypedListConverter(
          converter: TypedDataHelpers.stringConverter,
          isCached: false,
          isNullable: false,
        );
        final array = MutableArray();
        final list = converter.toTyped(array);
        expect(list.internal, same(array));
        expect(list, isA<MutableTypedDataList>());
      });

      test('creates CachedTypedDataList when isCached is true', () {
        const converter = TypedListConverter(
          converter: TypedDataHelpers.stringConverter,
          isCached: true,
          isNullable: false,
        );
        expect(converter.toTyped(immutableArray()), isA<CachedTypedDataList>());
        expect(converter.toTyped(MutableArray()), isA<CachedTypedDataList>());
      });

      test('throws if value is not a of the expected type', () {
        const converter = TypedListConverter(
          converter: TypedDataHelpers.stringConverter,
          isCached: false,
          isNullable: false,
        );
        expect(
          () => converter.toTyped(1),
          throwsA(
            isUnexpectedTypeException
                .havingExpectedTypes([Array, MutableArray]).havingValue(1),
          ),
        );
      });
    });

    group('toUntyped', () {
      test('returns internal container', () {
        const converter = TypedListConverter(
          converter: TypedDataHelpers.stringConverter,
          isCached: false,
          isNullable: false,
        );
        final internal = MutableArray();
        final list = ImmutableTypedDataList(
          internal: internal,
          converter: TypedDataHelpers.stringConverter,
          isNullable: false,
        );
        expect(converter.toUntyped(list), same(internal));
      });
    });

    group('promote', () {
      test('returns mutable copy if list is not mutable', () {
        const converter = TypedListConverter(
          converter: TypedDataHelpers.stringConverter,
          isCached: false,
          isNullable: false,
        );
        final list = ImmutableTypedDataList(
          internal: immutableArray(['a']),
          converter: TypedDataHelpers.stringConverter,
          isNullable: false,
        );
        final promoted = converter.promote(list);
        expect(promoted, isNot(same(list)));
        expect(promoted.internal, isNot(same(list.internal)));
        expect(promoted, list);
      });

      test('returns mutable copy if list is not a TypedDataList', () {
        const converter = TypedListConverter(
          converter: TypedDataHelpers.stringConverter,
          isCached: false,
          isNullable: false,
        );
        final list = ['a'];
        final promoted = converter.promote(list);
        expect(promoted, list);
      });
    });
  });

  group('ScalarConverterAdapter', () {
    group('toTyped', () {
      test('passes Dictionary as plain map to scalar converter', () {
        const converter = ScalarConverterAdapter(TestScalarConverter());
        expect(converter.toTyped(immutableDictionary()), isMap);
      });

      test('passes Array as plain list to scalar converter', () {
        const converter = ScalarConverterAdapter(TestScalarConverter());
        expect(converter.toTyped(immutableArray()), isList);
      });
    });

    group('toUntyped', () {
      test('passes value to scalar converter as is and returns results', () {
        const converter = ScalarConverterAdapter(TestScalarConverter());
        expect(converter.toUntyped('a'), 'a');
      });
    });
  });

  group('EnumNameConverter', () {
    group('fromData', () {
      test('returns enum value with by name', () {
        const converter = EnumNameConverter(EnumConverterTestEnum.values);
        expect(converter.fromData('a'), EnumConverterTestEnum.a);
      });

      test('throws if value is not a String', () {
        const converter = EnumNameConverter(EnumConverterTestEnum.values);
        expect(
          () => converter.fromData(1),
          throwsA(
            isUnexpectedTypeException
                .havingExpectedTypes([String]).havingValue(1),
          ),
        );
      });

      test('throws if value is not a valid name for enum', () {
        const converter = EnumNameConverter(EnumConverterTestEnum.values);
        expect(() => converter.fromData('b'), throwsA(isArgumentError));
      });
    });

    group('toData', () {
      test('returns name of enum value', () {
        const converter = EnumNameConverter(EnumConverterTestEnum.values);
        expect(converter.toData(EnumConverterTestEnum.a), 'a');
      });
    });
  });

  group('EnumIndexConverter', () {
    group('fromData', () {
      test('returns enum value by index', () {
        const converter = EnumIndexConverter(EnumConverterTestEnum.values);
        expect(converter.fromData(0), EnumConverterTestEnum.a);
      });

      test('throws if value is not an int', () {
        const converter = EnumIndexConverter(EnumConverterTestEnum.values);
        expect(
          () => converter.fromData(true),
          throwsA(
            isUnexpectedTypeException
                .havingExpectedTypes([int]).havingValue(true),
          ),
        );
      });

      test('throws if value is not a valid index for enum', () {
        const converter = EnumIndexConverter(EnumConverterTestEnum.values);
        expect(() => converter.fromData(1), throwsA(isArgumentError));
      });
    });

    group('toData', () {
      test('returns index of enum value', () {
        const converter = EnumIndexConverter(EnumConverterTestEnum.values);
        expect(converter.toData(EnumConverterTestEnum.a), 0);
      });
    });
  });
}

final isUnexpectedTypeException = isA<UnexpectedTypeException>();

extension on TypeMatcher<UnexpectedTypeException> {
  TypeMatcher<UnexpectedTypeException> havingExpectedTypes(
    Object expectedTypes,
  ) =>
      having((it) => it.expectedTypes, 'expectedTypes', expectedTypes);

  TypeMatcher<UnexpectedTypeException> havingValue(
    Object value,
  ) =>
      having((it) => it.value, 'value', value);
}

class ConverterTestDict
    extends TypedDictionaryObject<MutableConverterTestDict> {
  ConverterTestDict(this.internal);

  @override
  final MutableDictionary internal;

  @override
  MutableConverterTestDict toMutable() => MutableConverterTestDict(internal);

  @override
  String toString({String? indent}) => 'ConverterTestDict';
}

class MutableConverterTestDict extends ConverterTestDict
    implements
        TypedMutableDictionaryObject<ConverterTestDict,
            MutableConverterTestDict> {
  MutableConverterTestDict(super.internal);

  @override
  MutableConverterTestDict toMutable() => this;

  @override
  String toString({String? indent}) => 'MutableConverterTestDict';
}

class TestScalarConverter extends ScalarConverter<Object> {
  const TestScalarConverter();

  @override
  Object fromData(Object value) => value;

  @override
  Object toData(Object value) => value;
}

enum EnumConverterTestEnum { a }
