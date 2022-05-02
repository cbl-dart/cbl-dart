import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../fixtures/values.dart';
import '../test_binding.dart';
import '../utils/matchers.dart';
import 'document_test_utils.dart';

void main() {
  setupTestBinding();

  group('Array', () {
    test('toString', () async {
      final array = immutableArray([
        'a',
        {'b': 'c'}
      ]);
      expect(array.toString(), '[a, {b: c}]');
    });

    test('==', () {
      expect(immutableArray(), equality(immutableArray()));
      expect(immutableArray([1]), equality(immutableArray([1])));
      expect(immutableArray(), isNot(equality(immutableArray([1]))));
      expect(immutableArray([0, 1]), isNot(equality(immutableArray([1, 0]))));

      expect(immutableArray(), equality(MutableArray()));
      expect(immutableArray([1]), equality(MutableArray([1])));
      expect(immutableArray(), isNot(equality(MutableArray([1]))));
      expect(immutableArray([0, 1]), isNot(equality(MutableArray([1, 0]))));
    });

    test('hashCode', () {
      expect(immutableArray().hashCode, immutableArray().hashCode);
      expect(immutableArray([1]).hashCode, immutableArray([1]).hashCode);
      expect(immutableArray().hashCode, isNot(immutableArray([1]).hashCode));
      expect(
        immutableArray([0, 1]).hashCode,
        isNot(immutableArray([1, 0]).hashCode),
      );
    });

    test('length', () {
      expect(immutableArray().length, 0);
      expect(immutableArray([null]).length, 1);
    });

    test('toPlainList', () {
      final array = immutableArray([
        'x',
        'a',
        1,
        .2,
        3,
        true,
        testDate,
        testBlob,
        <Object?>[],
        <String, Object>{},
      ]);
      expect(array.toPlainList(), [
        'x',
        'a',
        1,
        .2,
        3,
        true,
        testDate.toIso8601String(),
        testBlob,
        <Object?>[],
        <String, Object?>{},
      ]);
    });

    test('toJson', () {
      expect(immutableArray().toJson(), '[]');
      expect(
        immutableArray([
          null,
          'a',
          1,
          .2,
          true,
          testDate,
          testBlob,
          <Object?>[],
          <String, Object?>{},
        ]).toJson(),
        json(
          '''
          [
            null,
            "a",
            1,
            0.2,
            true,
            "${testDate.toIso8601String()}",
            ${testBlob.toJson()},
            [],
            {}
          ]
          ''',
        ),
      );
      expect(MutableArray().toJson(), '[]');
      expect(
        MutableArray([
          null,
          'a',
          1,
          .2,
          true,
          testDate,
          testBlob,
          <Object?>[],
          <String, Object?>{},
        ]).toJson(),
        json(
          '''
          [
            null,
            "a",
            1,
            0.2,
            true,
            "${testDate.toIso8601String()}",
            ${testBlob.toJson()},
            [],
            {}
          ]
          ''',
        ),
      );
    });

    test('iterable', () {
      // Iterates over elements without conversion to plain objects.
      final array = immutableArray([MutableArray()]);
      expect(array.toList()[0], isA<Array>());
    });

    test('get value with matching typed getter', () {
      final array = immutableArray([
        'x',
        'a',
        1,
        .2,
        3,
        true,
        testDate,
        testBlob,
        <Object?>[],
        <String, Object>{},
      ]);

      expect(array.value(0), 'x');
      expect(array.string(1), 'a');
      expect(array.integer(2), 1);
      expect(array.float(3), .2);
      expect(array.number(4), 3);
      expect(array.boolean(5), true);
      expect(array.date(6), testDate);
      expect(array.blob(7), testBlob);
      expect(array.array(8), MutableArray());
      expect(array.dictionary(9), MutableDictionary());
    });

    test('get value with non-matching typed getter', () {
      final array = immutableArray([null]);
      expect(array.value(0), isNull);
      expect(array.string(0), isNull);
      expect(array.integer(0), 0);
      expect(array.float(0), .0);
      expect(array.number(0), isNull);
      expect(array.boolean(0), false);
      expect(array.date(0), isNull);
      expect(array.blob(0), isNull);
      expect(array.array(0), isNull);
      expect(array.dictionary(0), isNull);
    });

    test('get null value with typed getter', () {
      final array = immutableArray([null]);
      expect(array.value(0), isNull);
      expect(array.value<int>(0), isNull);
      expect(array.value<double>(0), isNull);
      expect(array.value<num>(0), isNull);
      expect(array.value<bool>(0), isNull);
      expect(array.string(0), isNull);
      expect(array.integer(0), 0);
      expect(array.float(0), .0);
      expect(array.number(0), isNull);
      expect(array.boolean(0), false);
      expect(array.date(0), isNull);
      expect(array.blob(0), isNull);
      expect(array.array(0), isNull);
      expect(array.dictionary(0), isNull);
    });

    test('getters throw RangeError is index is out of bounds', () {
      final array = immutableArray();
      expect(() => array.value(0), throwsRangeError);
      expect(() => array.string(0), throwsRangeError);
      expect(() => array.integer(0), throwsRangeError);
      expect(() => array.float(0), throwsRangeError);
      expect(() => array.number(0), throwsRangeError);
      expect(() => array.boolean(0), throwsRangeError);
      expect(() => array.date(0), throwsRangeError);
      expect(() => array.blob(0), throwsRangeError);
      expect(() => array.array(0), throwsRangeError);
      expect(() => array.dictionary(0), throwsRangeError);
    });

    group('immutable', () {
      test('fragment', () {
        final array = immutableArray([true]);
        expect(array[0].value, isTrue);
      });

      test('toMutable', () {
        final array = immutableArray([true]);
        final mutableArray = array.toMutable();
        expect(mutableArray, array);
        expect(mutableArray, isNot(same(array)));
      });
    });

    group('mutable', () {
      test('fragment', () {
        final array = MutableArray([true]);
        array[0].value = false;
        expect(array[0].value, isFalse);
      });

      test('toMutable', () {
        final array = MutableArray([true]);
        final mutableArray = array.toMutable();
        expect(mutableArray, array);
        expect(mutableArray, isNot(same(array)));
      });

      test('set values', () {
        setValuesTest(
          build: MutableArray.new,
          initialValue: 'a',
        );
        setValuesTest(
          build: (state) => immutableArray(state).toMutable(),
          initialValue: 'a',
        );
        setValuesTest(
          build: MutableArray.new,
          initialValue: <Object?>[],
        );
        setValuesTest(
          build: (state) => immutableArray(state).toMutable(),
          initialValue: <Object?>[],
        );
      });

      test('setter throw when index is out of range', () {
        final array = MutableArray();
        expect(() => array.setValue(null, at: 0), throwsRangeError);
        expect(() => array.setString('', at: 0), throwsRangeError);
        expect(() => array.setInteger(1, at: 0), throwsRangeError);
        expect(() => array.setFloat(0, at: 0), throwsRangeError);
        expect(() => array.setNumber(0, at: 0), throwsRangeError);
        expect(() => array.setBoolean(true, at: 0), throwsRangeError);
        expect(() => array.setDate(testDate, at: 0), throwsRangeError);
        expect(() => array.setBlob(testBlob, at: 0), throwsRangeError);
        expect(() => array.setArray(MutableArray(), at: 0), throwsRangeError);
        expect(() => array.setDictionary(MutableDictionary(), at: 0),
            throwsRangeError);
      });

      test('append values', () {
        final array = MutableArray()
          ..addValue('x')
          ..addString('a')
          ..addInteger(1)
          ..addFloat(.2)
          ..addNumber(3)
          ..addBoolean(true)
          ..addDate(testDate)
          ..addBlob(testBlob)
          ..addArray(MutableArray([true]))
          ..addDictionary(MutableDictionary({'key': 'value'}));

        expect(array.toPlainList(), [
          'x',
          'a',
          1,
          .2,
          3,
          true,
          testDate.toIso8601String(),
          testBlob,
          [true],
          {'key': 'value'},
        ]);
      });

      test('insert values', () {
        final array = MutableArray()
          ..insertValue('x', at: 0)
          ..insertString('a', at: 0)
          ..insertInteger(1, at: 0)
          ..insertFloat(.2, at: 0)
          ..insertNumber(3, at: 0)
          ..insertBoolean(true, at: 0)
          ..insertDate(testDate, at: 0)
          ..insertBlob(testBlob, at: 0)
          ..insertArray(MutableArray([true]), at: 0)
          ..insertDictionary(MutableDictionary({'key': 'value'}), at: 0);

        expect(array.toPlainList(), [
          {'key': 'value'},
          [true],
          testBlob,
          testDate.toIso8601String(),
          true,
          3,
          .2,
          1,
          'a',
          'x',
        ]);
      });

      test('setData', () {
        final array = MutableArray()
          ..setData([
            'x',
            'a',
            1,
            .2,
            3,
            true,
            testDate,
            testBlob,
            <Object?>[],
            <String, Object>{},
          ]);

        expect(array.toPlainList(), [
          'x',
          'a',
          1,
          .2,
          3,
          true,
          testDate.toIso8601String(),
          testBlob,
          <Object?>[],
          <String, Object>{},
        ]);
      });

      test('removeValue throws when index is out of range', () {
        final array = MutableArray();
        expect(() => array.removeValue(0), throwsRangeError);
      });

      group('from immutable', () {
        test('share child collection', () {
          final a = immutableArray([
            ['a']
          ]).toMutable();
          final b = MutableArray([a.value(0)]);

          expect(a.toPlainList(), [
            ['a']
          ]);
          expect(b.toPlainList(), [
            ['a']
          ]);
        });

        test('move child collection', () {
          final a = immutableArray([
            ['a']
          ]).toMutable();
          final b = MutableArray([a.value(0)]);
          a.removeValue(0);

          expect(a.toPlainList(), isEmpty);
          expect(b.toPlainList(), [
            ['a']
          ]);
        });
      });
    });
  });
}

void setValuesTest({
  required MutableArray Function(List<Object?> state) build,
  Object? initialValue,
}) {
  const index = 0;
  final initialData = [initialValue];
  void check(void Function(MutableArray array) fn) => fn(build(initialData));

  check((array) {
    array.setValue('x', at: index);
    expect(array.value(index), 'x');
  });

  check((array) {
    array.setString('a', at: index);
    expect(array.value(index), 'a');
  });

  check((array) {
    array.setInteger(1, at: index);
    expect(array.value(index), 1);
  });

  check((array) {
    array.setFloat(.2, at: index);
    expect(array.value(index), .2);
  });

  check((array) {
    array.setNumber(3, at: index);
    expect(array.value(index), 3);
  });

  check((array) {
    array.setBoolean(true, at: index);
    expect(array.value(index), true);
  });

  check((array) {
    array.setDate(testDate, at: index);
    expect(array.date(index), testDate);
  });

  check((array) {
    array.setBlob(testBlob, at: index);
    expect(array.value(index), testBlob);
  });

  check((array) {
    array.setArray(MutableArray([true]), at: index);
    expect(array.value(index), MutableArray([true]));
  });

  check((array) {
    array.setDictionary(MutableDictionary({'key': 'value'}), at: index);
    expect(array.value(index), MutableDictionary({'key': 'value'}));
  });
}
