import 'dart:typed_data';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/document/array.dart';
import 'package:cbl/src/fleece/fleece.dart' as fl;
import 'package:cbl/src/fleece/integration/integration.dart';
import 'package:cbl/src/query/result.dart';
import 'package:cbl_ffi/cbl_ffi.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/database_utils.dart';

void main() {
  setupTestBinding();

  group('Result', () {
    test('length', () {
      final result = testResult(['a'], ['x']);
      expect(result.length, 1);
    });

    test('keys', () {
      final result = testResult(['a'], ['x']);
      expect(result.keys, ['a']);
    });

    test('get value', () {
      final result = testResult(['a'], ['x']);
      expect(result.value(0), 'x');
      expect(result.value('a'), 'x');
      expect(result.value('b'), isNull);
    });

    test('get string', () {
      final result = testResult(['a'], ['a']);
      expect(result.string(0), 'a');
      expect(result.string('a'), 'a');
      expect(result.string('b'), isNull);
    });

    test('get integer', () {
      final result = testResult(['a'], [1]);
      expect(result.integer(0), 1);
      expect(result.integer('a'), 1);
      expect(result.integer('b'), 0);
    });

    test('get float', () {
      final result = testResult(['a'], [.1]);
      expect(result.float(0), .1);
      expect(result.float('a'), .1);
      expect(result.float('b'), 0);
    });

    test('get number', () {
      final result = testResult(['a'], [1]);
      expect(result.number(0), 1);
      expect(result.number('a'), 1);
      expect(result.number('b'), null);
    });

    test('get boolean', () {
      final result = testResult(['a'], [true]);
      expect(result.boolean(0), isTrue);
      expect(result.boolean('a'), isTrue);
      expect(result.boolean('b'), false);
    });

    test('get date', () {
      final date = DateTime.now();
      final result = testResult(['a'], [date]);
      expect(result.date(0), date);
      expect(result.date('a'), date);
      expect(result.blob('b'), null);
    });

    test('get blob', () {
      final blob = Blob.fromData('', Uint8List(0));
      final result = testResult(['a'], [blob]);
      expect(result.blob(0), blob);
      expect(result.blob('a'), blob);
      expect(result.blob('b'), null);
    });

    test('get array', () {
      final result = testResult([
        'a'
      ], [
        [true]
      ]);
      expect(result.array(0), MutableArray([true]));
      expect(result.array('a'), MutableArray([true]));
      expect(result.array('b'), null);
    });

    test('get dictionary', () {
      final result = testResult([
        'a'
      ], [
        {'a': true}
      ]);
      expect(result.dictionary(0), MutableDictionary({'a': true}));
      expect(result.dictionary('a'), MutableDictionary({'a': true}));
      expect(result.dictionary('b'), null);
    });

    test('contains', () {
      final result = testResult(['a'], [true]);
      expect(result.contains(0), isTrue);
      expect(result.contains(1), isFalse);
      expect(result.contains('a'), isTrue);
      expect(result.contains('b'), isFalse);
    });

    test('get fragment', () {
      final result = testResult(['a'], [true]);
      expect(result[0].value, true);
      expect(result['a'].value, true);
    });

    test('throw if nameOrIndex is not correct type', () {
      final result = testResult([], []);
      expect(() => result.value(true), throwsArgumentError);
      expect(() => result.string(true), throwsArgumentError);
      expect(() => result.integer(true), throwsArgumentError);
      expect(() => result.float(true), throwsArgumentError);
      expect(() => result.number(true), throwsArgumentError);
      expect(() => result.boolean(true), throwsArgumentError);
      expect(() => result.date(true), throwsArgumentError);
      expect(() => result.blob(true), throwsArgumentError);
      expect(() => result.array(true), throwsArgumentError);
      expect(() => result.dictionary(true), throwsArgumentError);
      expect(() => result[true], throwsArgumentError);
    });

    test('toPlainList', () {
      expect(testResult(['a'], [true]).toPlainList(), [true]);
    });

    test('toPlainMap', () {
      expect(testResult(['a'], [true]).toPlainMap(), {'a': true});
    });

    test('toJSON', () {
      expect(testResult(['a'], [true]).toJSON(), '{"a":true}');
    });

    test('==', () {
      Result a;
      Result b;

      a = testResult([], []);
      expect(a, a);

      b = testResult([], []);
      expect(a, b);

      b = testResult(['a'], [true]);
      expect(a, isNot(b));

      a = testResult(['a'], [true]);
      b = testResult(['a'], [true]);
      expect(a, b);
    });

    test('hashCode', () {
      Result a;
      Result b;

      a = testResult([], []);
      expect(a.hashCode, a.hashCode);

      b = testResult([], []);
      expect(a.hashCode, b.hashCode);

      b = testResult(['a'], [true]);
      expect(a.hashCode, isNot(b.hashCode));

      a = testResult(['a'], [true]);
      b = testResult(['a'], [true]);
      expect(a.hashCode, b.hashCode);
    });

    test('toString', () {
      expect(testResult(['a'], [true]).toString(), 'Result(a: true)');
    });

    group('e2e', () {
      late Database db;

      setUpAll(() {
        db = openTestDb('Result|Common');
      });

      test('access column by name', () {
        var doc = MutableDocument.withId('ResultSetColumnByName', {
          'a': {'b': true}
        });
        db.saveDocument(doc);
        final q = Query(
          db,
          r'SELECT a AS alias, a.b, count() FROM _ WHERE META().id = $ID',
        );
        q.parameters = Parameters({'ID': doc.id});

        final result = q.execute().first;
        expect(result.keys, ['alias', 'b', r'$1']);
        expect(result.dictionary('alias')!.toPlainMap(), {'b': true});
        expect(result.value('b'), isTrue);
        expect(result.value(r'$1'), 1);
      });

      test('access column by index', () async {
        final doc = MutableDocument.withId('ResultSetColumnByIndex');
        db.saveDocument(doc);

        final q = Query(db, r'SELECT META().id FROM _ WHERE META().id = $ID');
        q.parameters = Parameters({'ID': doc.id});

        final result = q.execute().first;
        expect(result.string(0), doc.id);
      });
    });
  });
}

Result testResult(List<String> columnNames, List<Object?> columnValues) {
  final values = MutableArray(columnValues) as MutableArrayImpl;
  final encoder = fl.FleeceEncoder();
  final encodingResult = values.encodeTo(encoder);
  assert(encodingResult is! Future);
  final doc =
      fl.Doc.fromResultData(encoder.finish().asUint8List(), FLTrust.trusted);
  return ResultImpl(
    context: MContext(),
    columnNames: columnNames,
    columnValues: doc.root.asArray!,
  );
}
