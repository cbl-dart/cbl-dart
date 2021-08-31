import 'package:cbl/cbl.dart';
import 'package:cbl/src/document/dictionary.dart';
import 'package:cbl/src/fleece/fleece.dart' as fl;
import 'package:cbl/src/fleece/integration/integration.dart';

import '../../test_binding_impl.dart';
import '../fixtures/values.dart';
import '../test_binding.dart';
import '../utils/matchers.dart';

void main() {
  setupTestBinding();

  group('Dictionary', () {
    test('toString', () async {
      final dictionary = immutableDictionary({
        'a': 'b',
        'c': ['d']
      });
      expect(dictionary.toString(), '{a: b, c: [d]}');
    });

    test('==', () {
      expect(immutableDictionary(), equality(immutableDictionary()));
      expect(
        immutableDictionary({'a': 'b'}),
        equality(immutableDictionary({'a': 'b'})),
      );
      expect(
        immutableDictionary(),
        isNot(equality(immutableDictionary({'a': 'b'}))),
      );
      expect(
        immutableDictionary({'a': 'b'}),
        isNot(equality(immutableDictionary({'c': 'd'}))),
      );

      expect(immutableDictionary(), equality(MutableDictionary()));
      expect(
        immutableDictionary({'a': 'b'}),
        equality(MutableDictionary({'a': 'b'})),
      );
      expect(
        immutableDictionary(),
        isNot(equality(MutableDictionary({'a': 'b'}))),
      );
      expect(
        immutableDictionary({'a': 'b'}),
        isNot(equality(MutableDictionary({'c': 'd'}))),
      );
    });

    test('hashCode', () {
      expect(immutableDictionary().hashCode, immutableDictionary().hashCode);
      expect(
        immutableDictionary({'a': 'b'}).hashCode,
        immutableDictionary({'a': 'b'}).hashCode,
      );
      expect(
        immutableDictionary().hashCode,
        isNot(immutableDictionary({'a': 'b'}).hashCode),
      );
      expect(
        immutableDictionary({'a': 'b'}).hashCode,
        isNot(immutableDictionary({'c': 'd'}).hashCode),
      );
    });

    test('length', () {
      expect(immutableDictionary().length, 0);
      expect(immutableDictionary({'a': 'b'}).length, 1);
    });

    test('keys', () {
      final dictionary = immutableDictionary({'a': 'b', 'c': 'd'});
      expect(dictionary.keys, ['a', 'c']);
    });

    test('iterable', () {
      // Iterates over keys.
      final dictionary = immutableDictionary({'a': 'b', 'c': 'd'});
      expect(dictionary.toList(), ['a', 'c']);
    });

    test('toPlainMap', () {
      final dictionary = immutableDictionary({
        'value': 'x',
        'string': 'a',
        'int': 1,
        'float': .2,
        'number': 3,
        'bool': true,
        'date': testDate,
        'blob': testBlob,
        'array': [false],
        'dictionary': {'key': 'value'},
      });
      expect(dictionary.toPlainMap(), {
        'value': 'x',
        'string': 'a',
        'int': 1,
        'float': .2,
        'number': 3,
        'bool': true,
        'date': testDate.toIso8601String(),
        'blob': testBlob,
        'array': [false],
        'dictionary': {'key': 'value'},
      });
    });

    test('toJson', () {
      expect(immutableDictionary().toJson(), '{}');
      expect(
        immutableDictionary({
          'null': null,
          'string': 'a',
          'integer': 1,
          'float': .2,
          'bool': true,
          'date': testDate,
          'blob': testBlob,
          'array': <Object?>[],
          'dictionary': <String, Object?>{},
        }).toJson(),
        json(
          '''
          {
            "null": null, 
            "string": "a", 
            "integer": 1, 
            "float": 0.2, 
            "bool": true, 
            "date": "${testDate.toIso8601String()}", 
            "blob": ${testBlob.toJson()}, 
            "array": [], 
            "dictionary": {}
          }
          ''',
        ),
      );
      expect(MutableDictionary().toJson(), '{}');
      expect(
        MutableDictionary({
          'null': null,
          'string': 'a',
          'integer': 1,
          'float': .2,
          'bool': true,
          'date': testDate,
          'blob': testBlob,
          'array': <Object?>[],
          'dictionary': <String, Object?>{},
        }).toJson(),
        json(
          '''
          {
            "null": null, 
            "string": "a", 
            "integer": 1, 
            "float": 0.2, 
            "bool": true, 
            "date": "${testDate.toIso8601String()}", 
            "blob": ${testBlob.toJson()}, 
            "array": [], 
            "dictionary": {}
          }
          ''',
        ),
      );
    });

    test('get value with matching typed getter', () {
      final dictionary = immutableDictionary({
        'value': 'x',
        'string': 'a',
        'int': 1,
        'float': .2,
        'number': 3,
        'bool': true,
        'date': testDate,
        'blob': testBlob,
        'array': [false],
        'dictionary': {'key': 'value'},
      });

      expect(dictionary.value('value'), 'x');
      expect(dictionary.string('string'), 'a');
      expect(dictionary.integer('int'), 1);
      expect(dictionary.float('float'), .2);
      expect(dictionary.number('number'), 3);
      expect(dictionary.boolean('bool'), true);
      expect(dictionary.date('date'), testDate);
      expect(dictionary.blob('blob'), testBlob);
      expect(dictionary.array('array'), MutableArray([false]));
      expect(
        dictionary.dictionary('dictionary'),
        MutableDictionary({'key': 'value'}),
      );
    });

    test('get value with non-matching typed getter', () {
      final dictionary = immutableDictionary();
      expect(dictionary.value('x'), isNull);
      expect(dictionary.string('x'), isNull);
      expect(dictionary.integer('x'), 0);
      expect(dictionary.float('x'), .0);
      expect(dictionary.number('x'), isNull);
      expect(dictionary.boolean('x'), false);
      expect(dictionary.date('x'), isNull);
      expect(dictionary.blob('x'), isNull);
      expect(dictionary.array('x'), isNull);
      expect(dictionary.dictionary('x'), isNull);
    });

    group('immutable', () {
      test('fragment', () {
        final dictionary = immutableDictionary({'a': true});
        expect(dictionary['a'].value, isTrue);
      });

      test('toMutable', () {
        final dictionary = immutableDictionary({'a': true});
        final mutableDictionary = dictionary.toMutable();
        expect(mutableDictionary, dictionary);
        expect(mutableDictionary, isNot(same(dictionary)));
      });
    });

    group('mutable', () {
      test('fragment', () {
        final dictionary = MutableDictionary({'a': true});
        dictionary['a'].value = false;
        expect(dictionary['a'].value, isFalse);
      });

      test('toMutable', () {
        final dictionary = MutableDictionary({'a': true});
        final mutableDictionary = dictionary.toMutable();
        expect(mutableDictionary, same(dictionary));
      });

      test('set values', () {
        final dictionary = MutableDictionary({'a': true});

        // ignore: cascade_invocations
        dictionary.setValue('x', key: 'a');
        expect(dictionary.value('a'), 'x');
        dictionary.setString('a', key: 'a');
        expect(dictionary.value('a'), 'a');
        dictionary.setInteger(1, key: 'a');
        expect(dictionary.value('a'), 1);
        dictionary.setFloat(.2, key: 'a');
        expect(dictionary.value('a'), .2);
        dictionary.setNumber(3, key: 'a');
        expect(dictionary.value('a'), 3);
        dictionary.setBoolean(true, key: 'a');
        expect(dictionary.value('a'), true);
        dictionary.setDate(testDate, key: 'a');
        expect(dictionary.date('a'), testDate);
        dictionary.setBlob(testBlob, key: 'a');
        expect(dictionary.value('a'), testBlob);
        dictionary.setArray(MutableArray([true]), key: 'a');
        expect(dictionary.value('a'), MutableArray([true]));
        dictionary.setDictionary(MutableDictionary({'key': 'value'}), key: 'a');
        expect(dictionary.value('a'), MutableDictionary({'key': 'value'}));
      });

      test('setData', () {
        final dictionary = MutableDictionary()
          ..setData({
            'value': 'x',
            'string': 'a',
            'int': 1,
            'float': .2,
            'number': 3,
            'bool': true,
            'date': testDate,
            'blob': testBlob,
            'array': [false],
            'dictionary': {'key': 'value'},
          });

        expect(dictionary.toPlainMap(), {
          'value': 'x',
          'string': 'a',
          'int': 1,
          'float': .2,
          'number': 3,
          'bool': true,
          'date': testDate.toIso8601String(),
          'blob': testBlob,
          'array': [false],
          'dictionary': {'key': 'value'},
        });
      });
    });
  });
}

Dictionary immutableDictionary([Map<String, Object?>? data]) {
  final array = MutableDictionary(data) as MutableDictionaryImpl;
  final encoder = fl.FleeceEncoder();
  array.encodeTo(encoder);
  final fleeceData = encoder.finish();
  final root = MRoot.fromData(
    fleeceData,
    context: MContext(),
    isMutable: false,
  );
  // ignore: cast_nullable_to_non_nullable
  return root.asNative as Dictionary;
}
