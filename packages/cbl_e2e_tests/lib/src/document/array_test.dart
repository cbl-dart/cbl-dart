import 'dart:typed_data';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/document/array.dart';
import 'package:cbl/src/document/common.dart';
import 'package:cbl/src/fleece/fleece.dart' as fl;
import 'package:cbl/src/fleece/integration/integration.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

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
      expect(immutableArray(), immutableArray());
      expect(immutableArray([1]), immutableArray([1]));
      expect(immutableArray(), isNot(immutableArray([1])));
      expect(immutableArray([0, 1]), isNot(immutableArray([1, 0])));
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
      final date = DateTime.now();
      final blob = Blob.fromData('', Uint8List(0));
      final array = immutableArray([
        'x',
        'a',
        1,
        .2,
        3,
        true,
        date,
        blob,
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
        date.toIso8601String(),
        blob,
        <Object?>[],
        <String, Object?>{},
      ]);
    });

    test('iterable', () {
      // Iterates over elements without conversion to plain objects.
      final array = immutableArray([MutableArray()]);
      expect(array.toList()[0], isA<Array>());
    });

    test('get value with matching typed getter', () {
      final date = DateTime.now();
      final blob = Blob.fromData('', Uint8List(0));
      final array = immutableArray([
        'x',
        'a',
        1,
        .2,
        3,
        true,
        date,
        blob,
        <Object?>[],
        <String, Object>{},
      ]);

      expect(array.value(0), 'x');
      expect(array.string(1), 'a');
      expect(array.integer(2), 1);
      expect(array.float(3), .2);
      expect(array.number(4), 3);
      expect(array.boolean(5), true);
      expect(array.date(6), date);
      expect(array.blob(7), blob);
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
        expect(mutableArray, same(array));
      });

      test('set values', () {
        final array = MutableArray([null]);
        array.setValue('x', at: 0);
        expect(array.value(0), 'x');
        array.setString('a', at: 0);
        expect(array.value(0), 'a');
        array.setInteger(1, at: 0);
        expect(array.value(0), 1);
        array.setFloat(.2, at: 0);
        expect(array.value(0), .2);
        array.setNumber(3, at: 0);
        expect(array.value(0), 3);
        array.setBoolean(true, at: 0);
        expect(array.value(0), true);
        array.setDate(DateTime(0), at: 0);
        expect(array.date(0), DateTime(0));
        final blob = Blob.fromData('', Uint8List(0));
        array.setBlob(blob, at: 0);
        expect(array.value(0), blob);
        array.setArray(MutableArray([true]), at: 0);
        expect(array.value(0), MutableArray([true]));
        array.setDictionary(MutableDictionary({'key': 'value'}), at: 0);
        expect(array.value(0), MutableDictionary({'key': 'value'}));
      });

      test('setter throw when index is out of range', () {
        final array = MutableArray();
        expect(() => array.setValue(null, at: 0), throwsRangeError);
        expect(() => array.setString('', at: 0), throwsRangeError);
        expect(() => array.setInteger(1, at: 0), throwsRangeError);
        expect(() => array.setFloat(0, at: 0), throwsRangeError);
        expect(() => array.setNumber(0, at: 0), throwsRangeError);
        expect(() => array.setBoolean(true, at: 0), throwsRangeError);
        expect(() => array.setDate(DateTime.now(), at: 0), throwsRangeError);
        expect(() => array.setBlob(Blob.fromData('', Uint8List(0)), at: 0),
            throwsRangeError);
        expect(() => array.setArray(MutableArray(), at: 0), throwsRangeError);
        expect(() => array.setDictionary(MutableDictionary(), at: 0),
            throwsRangeError);
      });

      test('append values', () {
        final date = DateTime(0);
        final blob = Blob.fromData('', Uint8List(0));
        final array = MutableArray();

        array
          ..addValue('x')
          ..addString('a')
          ..addInteger(1)
          ..addFloat(.2)
          ..addNumber(3)
          ..addBoolean(true)
          ..addDate(date)
          ..addBlob(blob)
          ..addArray(MutableArray([true]))
          ..addDictionary(MutableDictionary({'key': 'value'}));

        expect(array.toPlainList(), [
          'x',
          'a',
          1,
          .2,
          3,
          true,
          date.toIso8601String(),
          blob,
          [true],
          {'key': 'value'},
        ]);
      });

      test('insert values', () {
        final date = DateTime(0);
        final blob = Blob.fromData('', Uint8List(0));
        final array = MutableArray();

        array
          ..insertValue('x', at: 0)
          ..insertString('a', at: 0)
          ..insertInteger(1, at: 0)
          ..insertFloat(.2, at: 0)
          ..insertNumber(3, at: 0)
          ..insertBoolean(true, at: 0)
          ..insertDate(date, at: 0)
          ..insertBlob(blob, at: 0)
          ..insertArray(MutableArray([true]), at: 0)
          ..insertDictionary(MutableDictionary({'key': 'value'}), at: 0);

        expect(array.toPlainList(), [
          {'key': 'value'},
          [true],
          blob,
          date.toIso8601String(),
          true,
          3,
          .2,
          1,
          'a',
          'x',
        ]);
      });

      test('setData', () {
        final date = DateTime.now();
        final blob = Blob.fromData('', Uint8List(0));
        final array = MutableArray();

        array.setData([
          'x',
          'a',
          1,
          .2,
          3,
          true,
          date,
          blob,
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
          date.toIso8601String(),
          blob,
          <Object?>[],
          <String, Object>{},
        ]);
      });

      test('removeValue throws when index is out of range', () {
        final array = MutableArray();
        expect(() => array.removeValue(0), throwsRangeError);
      });
    });
  });
}

Array immutableArray([List<Object?>? data]) {
  final array = MutableArray(data) as MutableArrayImpl;
  final encoder = fl.FleeceEncoder();
  // FleeceEncoderContext is needed to compare unsaved Blobs in test.
  encoder.extraInfo = FleeceEncoderContext(encodeQueryParameter: true);
  array.encodeTo(encoder);
  final fleeceData = encoder.finish();
  final root = MRoot.fromData(
    fleeceData.asUint8List(),
    context: MContext(),
    isMutable: false,
  );
  return root.asNative as Array;
}
