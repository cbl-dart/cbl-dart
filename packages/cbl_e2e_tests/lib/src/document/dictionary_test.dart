import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../fixtures/values.dart';
import '../test_binding.dart';
import '../utils/matchers.dart';
import 'document_test_utils.dart';

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

    test('get null value with typed getter', () {
      final dictionary = immutableDictionary({'a': null});
      expect(dictionary.value('a'), isNull);
      expect(dictionary.value<int>('a'), isNull);
      expect(dictionary.value<double>('a'), isNull);
      expect(dictionary.value<num>('a'), isNull);
      expect(dictionary.value<bool>('a'), isNull);
      expect(dictionary.string('a'), isNull);
      expect(dictionary.integer('a'), 0);
      expect(dictionary.float('a'), .0);
      expect(dictionary.number('a'), isNull);
      expect(dictionary.boolean('a'), false);
      expect(dictionary.date('a'), isNull);
      expect(dictionary.blob('a'), isNull);
      expect(dictionary.array('a'), isNull);
      expect(dictionary.dictionary('a'), isNull);
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
        expect(mutableDictionary, dictionary);
        expect(mutableDictionary, isNot(same(dictionary)));
      });

      test('set values', () {
        setValuesTest(
          build: MutableDictionary.new,
          initialValue: 'a',
        );
        setValuesTest(
          build: (state) => immutableDictionary(state).toMutable(),
          initialValue: 'a',
        );
        setValuesTest(
          build: MutableDictionary.new,
          initialValue: <Object?>{},
        );
        setValuesTest(
          build: (state) => immutableDictionary(state).toMutable(),
          initialValue: <Object?>{},
        );
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

      group('from immutable', () {
        test('share child collection', () {
          final a = immutableDictionary({
            'a': {'k': 'v'}
          }).toMutable();
          final b = MutableDictionary({'b': a.value('a')});

          expect(a.toPlainMap(), {
            'a': {'k': 'v'}
          });
          expect(b.toPlainMap(), {
            'b': {'k': 'v'}
          });
        });

        test('move child collection', () {
          final a = immutableDictionary({
            'a': {'k': 'v'}
          }).toMutable();
          final b = MutableDictionary({'b': a.value('a')});
          a.removeValue('a');

          expect(a.toPlainMap(), isEmpty);
          expect(b.toPlainMap(), {
            'b': {'k': 'v'}
          });
        });
      });
    });
  });
}

void setValuesTest({
  required MutableDictionary Function(Map<String, Object?> state) build,
  Object? initialValue,
}) {
  const key = 'a';
  final initialData = {key: initialValue};
  void check(void Function(MutableDictionary dictionary) fn) =>
      fn(build(initialData));

  check((dictionary) {
    dictionary.setValue('x', key: key);
    expect(dictionary.value(key), 'x');
  });
  check((dictionary) {
    dictionary.setString('a', key: key);
    expect(dictionary.value(key), 'a');
  });

  check((dictionary) {
    dictionary.setInteger(1, key: key);
    expect(dictionary.value(key), 1);
  });

  check((dictionary) {
    dictionary.setFloat(.2, key: key);
    expect(dictionary.value(key), .2);
  });

  check((dictionary) {
    dictionary.setNumber(3, key: key);
    expect(dictionary.value(key), 3);
  });

  check((dictionary) {
    dictionary.setBoolean(true, key: key);
    expect(dictionary.value(key), true);
  });

  check((dictionary) {
    dictionary.setDate(testDate, key: key);
    expect(dictionary.date(key), testDate);
  });

  check((dictionary) {
    dictionary.setBlob(testBlob, key: key);
    expect(dictionary.value(key), testBlob);
  });

  check((dictionary) {
    dictionary.setArray(MutableArray([true]), key: key);
    expect(dictionary.value(key), MutableArray([true]));
  });

  check((dictionary) {
    dictionary.setDictionary(MutableDictionary({'key': 'value'}), key: key);
    expect(dictionary.value(key), MutableDictionary({'key': 'value'}));
  });
}
