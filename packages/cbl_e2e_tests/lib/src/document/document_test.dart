import 'dart:typed_data';

import 'package:cbl/cbl.dart';
import 'package:test/test.dart';

import '../../test_binding_impl.dart';
import '../utils/database_utils.dart';

void main() {
  setupTestBinding();

  late Database db;

  setUpAll(() async {
    db = await openTestDb('Document-Common');
  });

  Future<Document> savedDocument([Map<String, Object?>? data]) async {
    var doc = MutableDocument(data);
    await db.saveDocument(doc);
    return (await db.getDocument(doc.id))!;
  }

  group('Document', () {
    test('properties', () async {
      var revisionId = '1-581ad726ee407c8376fc94aad966051d013893c4';
      final doc = MutableDocument.withId('id');

      expect(doc.id, 'id');
      expect(doc.revisionId, isNull);
      expect(doc.sequence, 0);

      await db.saveDocument(doc);

      expect(doc.revisionId, revisionId);
      expect(doc.sequence, 1);

      final loadedDoc = (await db.getDocument(doc.id))!;

      expect(loadedDoc.id, 'id');
      expect(loadedDoc.revisionId, revisionId);
      expect(loadedDoc.sequence, 1);
    });

    test('==', () async {
      final doc = await savedDocument({'type': 'immutable'});

      // Identical docs are equal.
      expect(doc, doc);

      // Two instances at the same revision are equal.
      expect(await db.getDocument(doc.id), doc);

      final mutableDoc = doc.toMutable();

      // Unmutated mutable copy is equal to original.
      expect(mutableDoc, doc);

      mutableDoc['a'].value = 'b';

      // Mutated mutable copy is not equal.
      expect(mutableDoc, isNot(doc));

      await db.saveDocument(mutableDoc);

      // Two instances at different revision are not equal.
      expect(await db.getDocument(doc.id), isNot(doc));
    });

    test('hashCode', () async {
      final doc = await savedDocument({'type': 'immutable'});

      // Identical docs have the same hashCode.
      expect(doc.hashCode, doc.hashCode);

      // Two instances at the same revision have the same hashCode.
      expect((await db.getDocument(doc.id)).hashCode, doc.hashCode);

      final mutableDoc = doc.toMutable();

      // Unmutated mutable copy has the same hashCode.
      expect(mutableDoc.hashCode, doc.hashCode);

      mutableDoc['a'].value = 'b';

      // Mutated mutable copy has different hashCode.
      expect(mutableDoc.hashCode, isNot(doc.hashCode));

      await db.saveDocument(mutableDoc);

      // Two instances at different revision do not have the same hashCode.
      expect((await db.getDocument(doc.id)).hashCode, isNot(doc.hashCode));
    });

    group('immutable', () {
      test('implements DictionaryInterface for properties', () async {
        final date = DateTime.now();
        final blob = Blob.fromData('', Uint8List(0));
        final doc = await savedDocument({
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

      test('toMutable', () async {
        final doc = await savedDocument({'type': 'immutable'});
        expect(doc, isNot(isA<MutableDocument>()));
        final mutableDoc = doc.toMutable();
        expect(mutableDoc, doc);
      });

      test('toString', () async {
        final db = await openTestDb('Document-toString');
        final doc = MutableDocument();
        await db.saveDocument(doc);
        final loadedDoc = await db.getDocument(doc.id);
        expect(
          loadedDoc.toString(),
          'Document('
          'id: ${doc.id}, '
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
        expect(doc.id, startsWith('~'));
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
      final doc = MutableDocument();

      doc
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

      doc.setData({'array': <dynamic>[], 'dictionary': <String, dynamic>{}});
      expect(doc.array('array'), MutableArray());
      expect(doc.dictionary('dictionary'), MutableDictionary());

      doc['value'].value = 'x';
      expect(doc['value'].value, 'x');
    });

    test('toMutable', () {
      final doc = MutableDocument();
      expect(doc.toMutable(), same(doc));
    });

    test('toString', () async {
      final mutableDoc = MutableDocument();
      expect(
        mutableDoc.toString(),
        'MutableDocument('
        'id: ${mutableDoc.id}, '
        'revisionId: ${mutableDoc.revisionId}'
        ')',
      );
    });
  });
}
