// ignore_for_file: invalid_use_of_internal_member

import 'package:cbl/cbl.dart';
import 'package:cbl/src/typed_data/collection.dart';
import 'package:cbl/src/typed_data/conversion.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/matchers.dart';

void main() {
  setupTestBinding();

  group('ImmutableTypedDataList', () {
    test('return length of internal array', () {
      expect(
        ImmutableTypedDataList(
          internal: MutableArray(),
          isNullable: false,
          converter: const IdentityConverter<String>(),
        ).length,
        0,
      );
      expect(
        ImmutableTypedDataList(
          internal: MutableArray(['a']),
          isNullable: false,
          converter: const IdentityConverter<String>(),
        ).length,
        1,
      );
    });

    group('[]', () {
      test('return value at index', () {
        expect(
          ImmutableTypedDataList(
            internal: MutableArray(['a']),
            isNullable: false,
            converter: const IdentityConverter<String>(),
          )[0],
          'a',
        );
      });

      test('return null if value is null and list is nullable', () {
        expect(
          ImmutableTypedDataList<String?, String?>(
            internal: MutableArray([null]),
            isNullable: true,
            converter: const IdentityConverter<String>(),
          )[0],
          null,
        );
      });

      test('throws if value is null and list is not nullable', () {
        expect(
          () => ImmutableTypedDataList(
            internal: MutableArray([null]),
            isNullable: false,
            converter: const IdentityConverter<String>(),
          )[0],
          throwsA(
            isTypedDataException
                .havingCode(TypedDataErrorCode.dataMismatch)
                .havingMessage(
                  'Expected a value for element 0 but found "null" in the '
                  'underlying data.',
                ),
          ),
        );
      });

      test('throws if value has unexpected type', () {
        expect(
          () => ImmutableTypedDataList(
            internal: MutableArray([0]),
            isNullable: false,
            converter: const IdentityConverter<String>(),
          )[0],
          throwsA(
            isTypedDataException
                .havingCode(TypedDataErrorCode.dataMismatch)
                .havingMessage(
                  'Type error at index 0: UnexpectedTypeException: Expected a '
                  'value of type String, but got a int.',
                ),
          ),
        );
      });
    });

    test('throws from mutating methods', () {
      final list = ImmutableTypedDataList(
        internal: MutableArray(),
        isNullable: false,
        converter: const IdentityConverter<String>(),
      );

      expect(() => list[0] = '', throwsA(isUnsupportedError));
      expect(() => list.length = 0, throwsA(isUnsupportedError));
      expect(() => list.first = '', throwsA(isUnsupportedError));
      expect(() => list.last = '', throwsA(isUnsupportedError));
      expect(() => list.setAll(0, []), throwsA(isUnsupportedError));
      expect(() => list.add(''), throwsA(isUnsupportedError));
      expect(() => list.insert(0, ''), throwsA(isUnsupportedError));
      expect(() => list.insertAll(0, []), throwsA(isUnsupportedError));
      expect(() => list.addAll([]), throwsA(isUnsupportedError));
      expect(() => list.remove(''), throwsA(isUnsupportedError));
      expect(() => list.removeWhere((_) => true), throwsA(isUnsupportedError));
      expect(() => list.retainWhere((_) => true), throwsA(isUnsupportedError));
      expect(list.sort, throwsA(isUnsupportedError));
      expect(list.shuffle, throwsA(isUnsupportedError));
      expect(list.clear, throwsA(isUnsupportedError));
      expect(() => list.removeAt(0), throwsA(isUnsupportedError));
      expect(list.removeLast, throwsA(isUnsupportedError));
      expect(() => list.setRange(0, 0, []), throwsA(isUnsupportedError));
      expect(() => list.removeRange(0, 0), throwsA(isUnsupportedError));
      expect(() => list.replaceRange(0, 0, []), throwsA(isUnsupportedError));
      expect(() => list.fillRange(0, 0), throwsA(isUnsupportedError));
    });
  });

  group('MutableTypedDataList', () {});

  group('CachedTypedDataList', () {});
}
