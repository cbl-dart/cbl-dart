// ignore_for_file: invalid_use_of_internal_member, cascade_invocations

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

  group('MutableTypedDataList', () {
    group('set length', () {
      test('reduce size', () {
        final list = MutableTypedDataList(
          internal: MutableArray(['a', 'b']),
          isNullable: false,
          converter: const IdentityConverter<String>(),
        );
        list.length = 1;
        expect(list, hasLength(1));
        expect(list, ['a']);
      });

      test('increase size', () {
        final list = MutableTypedDataList<String?, String?>(
          internal: MutableArray(['a']),
          isNullable: true,
          converter: const IdentityConverter<String>(),
        );
        list.length = 2;
        expect(list, hasLength(2));
        expect(list, ['a', null]);
      });

      test('throws when increasing size of non-nullable list', () {
        final list = MutableTypedDataList<String?, String?>(
          internal: MutableArray(),
          isNullable: false,
          converter: const IdentityConverter<String>(),
        );
        expect(() => list.length = 1, throwsA(isUnsupportedError));
      });
    });

    test('[]=', () {
      final list = MutableTypedDataList(
        internal: MutableArray(['a']),
        isNullable: false,
        converter: const IdentityConverter<String>(),
      );
      list[0] = 'b';
      expect(list, ['b']);
    });

    test('add', () {
      final list = MutableTypedDataList(
        internal: MutableArray(),
        isNullable: false,
        converter: const IdentityConverter<String>(),
      );
      list.add('a');
      expect(list, ['a']);
    });

    test('addAll', () {
      final list = MutableTypedDataList(
        internal: MutableArray(),
        isNullable: false,
        converter: const IdentityConverter<String>(),
      );
      list.addAll(['a']);
      expect(list, ['a']);
    });

    test('fillRange', () {
      final list = MutableTypedDataList(
        internal: MutableArray(['a', 'b']),
        isNullable: false,
        converter: const IdentityConverter<String>(),
      );
      list.fillRange(0, 2, 'c');
      expect(list, ['c', 'c']);
    });

    test('insert', () {
      final list = MutableTypedDataList(
        internal: MutableArray(['a', 'b']),
        isNullable: false,
        converter: const IdentityConverter<String>(),
      );
      list.insert(1, 'c');
      expect(list, ['a', 'c', 'b']);
    });

    test('insertAll', () {
      final list = MutableTypedDataList(
        internal: MutableArray(['a', 'b']),
        isNullable: false,
        converter: const IdentityConverter<String>(),
      );
      list.insertAll(1, ['c']);
      expect(list, ['a', 'c', 'b']);
    });

    test('replaceRange', () {
      final list = MutableTypedDataList(
        internal: MutableArray(['a', 'b']),
        isNullable: false,
        converter: const IdentityConverter<String>(),
      );
      list.replaceRange(0, 1, ['c']);
      expect(list, ['c', 'b']);
    });

    test('setAll', () {
      final list = MutableTypedDataList(
        internal: MutableArray(['a', 'b', 'c']),
        isNullable: false,
        converter: const IdentityConverter<String>(),
      );
      list.setAll(1, ['d']);
      expect(list, ['a', 'd', 'c']);
    });

    test('setRange', () {
      final list = MutableTypedDataList(
        internal: MutableArray(['a', 'b', 'c']),
        isNullable: false,
        converter: const IdentityConverter<String>(),
      );
      list.setRange(1, 2, ['d']);
      expect(list, ['a', 'd', 'c']);
    });
  });

  group('CachedTypedDataList', () {
    test('caches values', () {
      final list = CachedTypedDataList<DateTime?, DateTime?>(
        MutableTypedDataList(
          internal: MutableArray([null]),
          isNullable: true,
          converter: const DateTimeConverter(),
        ),
        growable: true,
      );
      final now = DateTime.now();

      list[0] = now;
      expect(list.first, same(now));

      list.clear();
      list.add(now);
      expect(list.first, same(now));

      list.clear();
      list.addAll([now]);
      expect(list.first, same(now));
    });

    test('set length', () {
      final list = CachedTypedDataList(
        MutableTypedDataList(
          internal: MutableArray(['a', 'b']),
          isNullable: false,
          converter: const IdentityConverter<String>(),
        ),
        growable: true,
      );
      list.length = 1;
      expect(list, hasLength(1));
      expect(list, ['a']);
    });

    test('[]=', () {
      final list = CachedTypedDataList(
        MutableTypedDataList(
          internal: MutableArray(['a']),
          isNullable: false,
          converter: const IdentityConverter<String>(),
        ),
        growable: true,
      );
      list[0] = 'b';
      expect(list, ['b']);
    });

    test('add', () {
      final list = CachedTypedDataList(
        MutableTypedDataList(
          internal: MutableArray(),
          isNullable: false,
          converter: const IdentityConverter<String>(),
        ),
        growable: true,
      );
      list.add('a');
      expect(list, ['a']);
    });

    test('addAll', () {
      final list = CachedTypedDataList(
        MutableTypedDataList(
          internal: MutableArray(),
          isNullable: false,
          converter: const IdentityConverter<String>(),
        ),
        growable: true,
      );
      list.addAll(['a']);
      expect(list, ['a']);
    });

    test('fillRange', () {
      final list = CachedTypedDataList(
        MutableTypedDataList(
          internal: MutableArray(['a', 'b']),
          isNullable: false,
          converter: const IdentityConverter<String>(),
        ),
        growable: true,
      );
      list.fillRange(0, 2, 'c');
      expect(list, ['c', 'c']);
    });

    test('insert', () {
      final list = CachedTypedDataList(
        MutableTypedDataList(
          internal: MutableArray(['a', 'b']),
          isNullable: false,
          converter: const IdentityConverter<String>(),
        ),
        growable: true,
      );
      list.insert(1, 'c');
      expect(list, ['a', 'c', 'b']);
    });

    test('insertAll', () {
      final list = CachedTypedDataList(
        MutableTypedDataList(
          internal: MutableArray(['a', 'b']),
          isNullable: false,
          converter: const IdentityConverter<String>(),
        ),
        growable: true,
      );
      list.insertAll(1, ['c']);
      expect(list, ['a', 'c', 'b']);
    });

    test('replaceRange', () {
      final list = CachedTypedDataList(
        MutableTypedDataList(
          internal: MutableArray(['a', 'b']),
          isNullable: false,
          converter: const IdentityConverter<String>(),
        ),
        growable: true,
      );
      list.replaceRange(0, 1, ['c']);
      expect(list, ['c', 'b']);
    });

    test('setAll', () {
      final list = CachedTypedDataList(
        MutableTypedDataList(
          internal: MutableArray(['a', 'b', 'c']),
          isNullable: false,
          converter: const IdentityConverter<String>(),
        ),
        growable: true,
      );
      list.setAll(1, ['d']);
      expect(list, ['a', 'd', 'c']);
    });

    test('setRange', () {
      final list = CachedTypedDataList(
        MutableTypedDataList(
          internal: MutableArray(['a', 'b', 'c']),
          isNullable: false,
          converter: const IdentityConverter<String>(),
        ),
        growable: true,
      );
      list.setRange(1, 2, ['d']);
      expect(list, ['a', 'd', 'c']);
    });
  });
}
