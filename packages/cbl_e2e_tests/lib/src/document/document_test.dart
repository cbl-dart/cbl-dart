import 'dart:typed_data';

import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/database_utils.dart';
import '../utils/matchers.dart';

void main() {
  setupTestBinding();

  late SyncDatabase db;

  setUpAll(() async {
    db = openSyncTestDb('Document-Common');
  });

  Document savedDocument([Map<String, Object?>? data]) {
    final doc = MutableDocument(data);
    db.saveDocument(doc);
    return db.document(doc.id)!;
  }

  group('Document', () {
    test('properties', () {
      const revisionId = '1-581ad726ee407c8376fc94aad966051d013893c4';
      final doc = MutableDocument.withId('id');

      expect(doc.id, 'id');
      expect(doc.revisionId, isNull);
      expect(doc.sequence, 0);

      db.saveDocument(doc);

      expect(doc.revisionId, revisionId);
      expect(doc.sequence, 1);

      final loadedDoc = db.document(doc.id)!;

      expect(loadedDoc.id, 'id');
      expect(loadedDoc.revisionId, revisionId);
      expect(loadedDoc.sequence, 1);
    });

    test('==', () {
      final doc = savedDocument({'type': 'immutable'});

      // Identical docs are equal.
      expect(doc, equality(doc));

      // Two instances at the same revision are equal.
      expect(db.document(doc.id), equality(doc));

      final mutableDoc = doc.toMutable();

      // Unmutated mutable copy is equal to original.
      expect(mutableDoc, equality(doc));

      mutableDoc['a'].value = 'b';

      // Mutated mutable copy is not equal.
      expect(mutableDoc, isNot(equality(doc)));

      expect(
        MutableDocument.withId('a'),
        equality(MutableDocument.withId('a')),
      );
      expect(
        MutableDocument.withId('a'),
        isNot(equality(MutableDocument.withId('b'))),
      );

      expect(
        MutableDocument.withId('a', {'a': true}),
        equality(MutableDocument.withId('a', {'a': true})),
      );
      expect(
        MutableDocument.withId('a', {'a': true}),
        isNot(equality(MutableDocument.withId('b', {'a': false}))),
      );
    });

    test('hashCode', () {
      final doc = savedDocument({'type': 'immutable'});

      expect(doc.hashCode, doc.hashCode);
      expect((db.document(doc.id)).hashCode, doc.hashCode);

      expect(
        MutableDocument.withId('a').hashCode,
        MutableDocument.withId('a').hashCode,
      );
      expect(
        MutableDocument.withId('a').hashCode,
        isNot(MutableDocument.withId('b').hashCode),
      );

      expect(
        MutableDocument.withId('a', {'a': true}).hashCode,
        MutableDocument.withId('a', {'a': true}).hashCode,
      );
      expect(
        MutableDocument.withId('a', {'a': true}).hashCode,
        isNot(MutableDocument.withId('b', {'a': false}).hashCode),
      );
    });

    group('immutable', () {
      test('implements DictionaryInterface for properties', () {
        final date = DateTime.now();
        final blob = Blob.fromData('', Uint8List(0));
        final doc = savedDocument({
          'value': 'x',
          'string': 'a',
          'int': 1,
          'float': .2,
          'number': 3,
          'bool': true,
          'date': date,
          'blob': blob,
          'array': [false],
          'dictionary': {'key': 'value'},
        });

        expect(doc.length, 10);
        expect(
          doc.keys,
          unorderedEquals(<dynamic>[
            'value',
            'string',
            'int',
            'float',
            'number',
            'bool',
            'date',
            'blob',
            'array',
            'dictionary',
          ]),
        );
        expect(doc.value('value'), 'x');
        expect(doc.string('string'), 'a');
        expect(doc.integer('int'), 1);
        expect(doc.float('float'), .2);
        expect(doc.number('number'), 3);
        expect(doc.boolean('bool'), true);
        expect(doc.date('date'), date);
        expect(doc.blob('blob'), blob);
        expect(doc.array('array'), MutableArray([false]));
        expect(
          doc.dictionary('dictionary'),
          MutableDictionary({'key': 'value'}),
        );
        expect(doc.contains('value'), isTrue);
        expect(doc.contains('foo'), isFalse);
        expect(doc.toPlainMap(), {
          'value': 'x',
          'string': 'a',
          'int': 1,
          'float': .2,
          'number': 3,
          'bool': true,
          'date': date.toIso8601String(),
          'blob': blob,
          'array': [false],
          'dictionary': {'key': 'value'},
        });

        expect(doc['value'].value, 'x');
      });

      test('implements Iterable<String> for keys', () {
        final doc = MutableDocument({'a': null, 'b': null, 'c': null});
        expect(doc.toList(), ['a', 'b', 'c']);
      });

      test('toMutable', () {
        final doc = savedDocument({'type': 'immutable'});
        expect(doc, isNot(isA<MutableDocument>()));
        final mutableDoc = doc.toMutable();
        expect(mutableDoc, doc);
      });

      test('toString', () {
        final db = openSyncTestDb('Document-toString');
        final doc = MutableDocument();
        db.saveDocument(doc);
        final loadedDoc = db.document(doc.id);
        expect(
          loadedDoc.toString(),
          'Document('
          'id: ${doc.id}, '
          // ignore: missing_whitespace_between_adjacent_strings
          'revisionId: ${doc.revisionId}'
          ')',
        );
      });
    });

    group('mutable', () {
      test('create with id', () {
        final doc = MutableDocument.withId('id');
        expect(doc.id, 'id');
      });

      test('create with generated it', () {
        final doc = MutableDocument();
        expect(doc.id, startsWith('-'));
      });

      test('initialize with data', () {
        final data = {
          'null': null,
          'int': 1,
          'float': 3.1,
          'string': 'a',
          'bool': true,
          'array': [false],
          'dictionary': {'key': 'value'},
          'blob': Blob.fromData('', Uint8List(0)),
        };
        final doc = MutableDocument(data);
        expect(doc.toPlainMap(), data);
      });
    });

    test('implements MutableDictionaryInterface for properties', () {
      final date = DateTime.now();
      final blob = Blob.fromData('', Uint8List(0));
      final doc = MutableDocument()
        ..setValue('x', key: 'value')
        ..setString('a', key: 'string')
        ..setInteger(1, key: 'int')
        ..setFloat(.2, key: 'float')
        ..setNumber(3, key: 'number')
        ..setBoolean(true, key: 'bool')
        ..setDate(date, key: 'date')
        ..setBlob(blob, key: 'blob')
        ..setArray(MutableArray([true]), key: 'array')
        ..setDictionary(MutableDictionary({'key': 'value'}), key: 'dictionary');

      expect(doc.toPlainMap(), {
        'value': 'x',
        'string': 'a',
        'int': 1,
        'float': .2,
        'number': 3,
        'bool': true,
        'date': date.toIso8601String(),
        'blob': blob,
        'array': [true],
        'dictionary': {'key': 'value'},
      });

      doc.setData({'data': 'data'});
      expect(doc.toPlainMap(), {'data': 'data'});

      doc.removeValue('data');
      expect(doc, isEmpty);

      doc.setData({'array': <Object?>[], 'dictionary': <String, Object?>{}});
      expect(doc.array('array'), MutableArray());
      expect(doc.dictionary('dictionary'), MutableDictionary());

      doc['value'].value = 'x';
      expect(doc['value'].value, 'x');
    });

    test('toMutable', () {
      final doc = MutableDocument();
      expect(doc.toMutable(), same(doc));
    });

    test('toString', () {
      final mutableDoc = MutableDocument();
      expect(
        mutableDoc.toString(),
        'MutableDocument('
        'id: ${mutableDoc.id}, '
        // ignore: missing_whitespace_between_adjacent_strings
        'revisionId: ${mutableDoc.revisionId}'
        ')',
      );
    });
  });
}
