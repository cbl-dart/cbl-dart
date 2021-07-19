import 'dart:typed_data';

import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  test('subscript access', () {
    final dict = MutableDictionary({
      'a': [
        {'b': true}
      ]
    });

    expect(dict['x'].exists, isFalse);
    expect(dict['x'][0].exists, isFalse);
    expect(dict['x'][0]['x'].exists, isFalse);

    expect(dict['a'].exists, isTrue);
    expect(dict['a'][0].exists, isTrue);
    expect(dict['a'][0]['b'].exists, isTrue);

    expect(dict['a'][0]['b'].value, true);
  });

  test('getters for values in array', () {
    final date = DateTime.now();
    final blob = Blob.fromData('', Uint8List(0));
    final array = MutableArray([
      'x',
      'a',
      1,
      .2,
      3,
      true,
      date,
      blob,
      <Object?>[true],
      <String, Object>{'key': 'value'},
    ]);

    expect(array[0].valueAs(), 'x');
    expect(array[0].value, 'x');
    expect(array[1].string, 'a');
    expect(array[2].integer, 1);
    expect(array[3].float, .2);
    expect(array[4].number, 3);
    expect(array[5].boolean, true);
    expect(array[6].date, date);
    expect(array[7].blob, blob);
    expect(array[8].array, MutableArray([true]));
    expect(array[9].dictionary, MutableDictionary({'key': 'value'}));
  });

  test('getters for values in dictionary', () {
    final date = DateTime.now();
    final blob = Blob.fromData('', Uint8List(0));
    final dictionary = MutableDictionary({
      'value': 'x',
      'string': 'a',
      'int': 1,
      'float': .2,
      'number': 3,
      'bool': true,
      'date': date,
      'blob': blob,
      'array': [true],
      'dictionary': {'key': 'value'},
    });

    expect(dictionary['value'].valueAs(), 'x');
    expect(dictionary['value'].value, 'x');
    expect(dictionary['string'].string, 'a');
    expect(dictionary['int'].integer, 1);
    expect(dictionary['float'].float, .2);
    expect(dictionary['number'].number, 3);
    expect(dictionary['bool'].boolean, true);
    expect(dictionary['date'].date, date);
    expect(dictionary['blob'].blob, blob);
    expect(dictionary['array'].array, MutableArray([true]));
    expect(
      dictionary['dictionary'].dictionary,
      MutableDictionary({'key': 'value'}),
    );
  });

  test('getters return null/default if Fragment does not exist', () {
    final array = MutableArray();

    expect(array[0].valueAs(), isNull);
    expect(array[0].value, isNull);
    expect(array[0].string, isNull);
    expect(array[0].integer, 0);
    expect(array[0].float, .0);
    expect(array[0].number, isNull);
    expect(array[0].boolean, false);
    expect(array[0].date, isNull);
    expect(array[0].blob, isNull);
    expect(array[0].array, isNull);
    expect(array[0].dictionary, isNull);

    final dictionary = MutableDictionary();

    expect(dictionary['x'].valueAs(), isNull);
    expect(dictionary['x'].value, isNull);
    expect(dictionary['x'].string, isNull);
    expect(dictionary['x'].integer, 0);
    expect(dictionary['x'].float, .0);
    expect(dictionary['x'].number, isNull);
    expect(dictionary['x'].boolean, false);
    expect(dictionary['x'].date, isNull);
    expect(dictionary['x'].blob, isNull);
    expect(dictionary['x'].array, isNull);
    expect(dictionary['x'].dictionary, isNull);
  });

  test('setters for index in array set value', () {
    final date = DateTime.now();
    final blob = Blob.fromData('', Uint8List(0));
    final array = MutableArray([null]);

    array[0].value = 'x';
    expect(array.value(0), 'x');
    array[0].string = 'a';
    expect(array.value(0), 'a');
    array[0].integer = 1;
    expect(array.value(0), 1);
    array[0].float = .2;
    expect(array.value(0), .2);
    array[0].number = 3;
    expect(array.value(0), 3);
    array[0].boolean = true;
    expect(array.value(0), true);
    array[0].date = date;
    expect(array.date(0), date);
    array[0].blob = blob;
    expect(array.value(0), blob);
    array[0].array = MutableArray([true]);
    expect(array.value(0), MutableArray([true]));
    array[0].dictionary = MutableDictionary({'key': 'value'});
    expect(array.value(0), MutableDictionary({'key': 'value'}));
  });

  test('setters for keys in dictionary set value', () {
    final date = DateTime.now();
    final blob = Blob.fromData('', Uint8List(0));
    final dictionary = MutableDictionary({'x': null});

    dictionary['x'].value = 'x';
    expect(dictionary.value('x'), 'x');
    dictionary['x'].string = 'a';
    expect(dictionary.value('x'), 'a');
    dictionary['x'].integer = 1;
    expect(dictionary.value('x'), 1);
    dictionary['x'].float = .2;
    expect(dictionary.value('x'), .2);
    dictionary['x'].number = 3;
    expect(dictionary.value('x'), 3);
    dictionary['x'].boolean = true;
    expect(dictionary.value('x'), true);
    dictionary['x'].date = date;
    expect(dictionary.date('x'), date);
    dictionary['x'].blob = blob;
    expect(dictionary.value('x'), blob);
    dictionary['x'].array = MutableArray([true]);
    expect(dictionary.value('x'), MutableArray([true]));
    dictionary['x'].dictionary = MutableDictionary({'key': 'value'});
    expect(dictionary.value('x'), MutableDictionary({'key': 'value'}));
  });

  test('setters throw if Fragment index is out of range', () {
    final date = DateTime.now();
    final blob = Blob.fromData('', Uint8List(0));
    final array = MutableArray();

    expect(() => array[0].value = 'x', throwsRangeError);
    expect(() => array[0].string = 'x', throwsRangeError);
    expect(() => array[0].integer = 0, throwsRangeError);
    expect(() => array[0].float = 0, throwsRangeError);
    expect(() => array[0].number = 0, throwsRangeError);
    expect(() => array[0].boolean = false, throwsRangeError);
    expect(() => array[0].date = date, throwsRangeError);
    expect(() => array[0].blob = blob, throwsRangeError);
    expect(() => array[0].array = MutableArray(), throwsRangeError);
    expect(() => array[0].dictionary = MutableDictionary(), throwsRangeError);
  });

  test('setters throw if Fragment path is outside existing collection', () {
    final date = DateTime.now();
    final blob = Blob.fromData('', Uint8List(0));
    final array = MutableArray();

    expect(() => array[0][0].value = 'x', throwsStateError);
    expect(() => array[0][0].string = 'x', throwsStateError);
    expect(() => array[0][0].integer = 0, throwsStateError);
    expect(() => array[0][0].float = 0, throwsStateError);
    expect(() => array[0][0].number = 0, throwsStateError);
    expect(() => array[0][0].boolean = false, throwsStateError);
    expect(() => array[0][0].date = date, throwsStateError);
    expect(() => array[0][0].blob = blob, throwsStateError);
    expect(() => array[0][0].array = MutableArray(), throwsStateError);
    expect(
        () => array[0][0].dictionary = MutableDictionary(), throwsStateError);
  });
}
