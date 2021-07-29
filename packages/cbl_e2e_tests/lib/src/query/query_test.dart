import 'package:cbl/cbl.dart';
import 'package:rxdart/rxdart.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/database_utils.dart';

void main() {
  setupTestBinding();

  group('Query', () {
    late Database db;

    setUp(() {
      db = openTestDb('Query|Common');
    });

    test('execute simple query', () {
      final db = openTestDb('ExecuteSimpleQuery');
      db.saveDocument(MutableDocument({'a': 0}));
      db.saveDocument(MutableDocument({'a': 1}));

      final q = Query(db, 'SELECT a FROM _ ORDER BY a');

      expect(q.execute().map((e) => e.toPlainMap()).toList(), [
        {'a': 0},
        {'a': 1}
      ]);
    });

    test('execute query with parameters', () {
      final q = Query(db, r'SELECT doc FROM _ WHERE META().id = $ID');
      db.saveDocument(MutableDocument.withId('A'));

      q.parameters = Parameters({'ID': 'A'});
      expect((q.execute()), isNotEmpty);

      q.parameters = Parameters({'ID': 'B'});
      expect((q.execute()), isEmpty);
    });

    test('listen to query with parameters', () async {
      final q = Query(db, r'SELECT doc FROM _ WHERE META().id = $ID');
      db.saveDocument(MutableDocument.withId('A'));

      q.parameters = Parameters({'ID': 'A'});
      expect((await q.changes().first), isNotEmpty);

      q.parameters = Parameters({'ID': 'B'});
      expect((await q.changes().first), isEmpty);
    });

    test('explain returns the query plan explanation', () {
      final q = Query(db, 'SELECT doc FROM _');

      expect(
        q.explain(),
        '''
SELECT fl_result(fl_value(_.body, 'doc')) FROM kv_default AS _ WHERE (_.flags & 1 = 0)

2|0|0| SCAN TABLE kv_default AS _

{"FROM":[{"COLLECTION":"_"}],"WHAT":[[".doc"]]}
''',
      );
    });

    test('listener is notified of changes', () {
      final q = Query(db, 'SELECT a FROM _ AS a WHERE a.b = "c"');

      final doc = MutableDocument({'b': 'c'});
      final result = {'a': doc.toPlainMap()};
      final stream = q
          .changes()
          .map((resultSet) =>
              resultSet.map((dict) => dict.toPlainMap()).toList())
          .shareReplay();

      // ignore: unawaited_futures
      stream.first.then((_) => db.saveDocument(doc));

      expect(
        stream,
        emitsInOrder(<dynamic>[
          isEmpty,
          [result],
        ]),
      );
    });

    test('bad query: error position highlighting', () {
      expect(
        () => Query(db, 'SELECT foo()'),
        throwsA(isA<DatabaseException>().having(
          (it) => it.toString(),
          'toString()',
          '''
DatabaseException(query syntax error, code: invalidQuery)
SELECT foo()
          ^
''',
        )),
      );
    });

    test('toString', () {
      expect(
        Query(db, 'SELECT * FROM _').toString(),
        'Query(n1ql: SELECT * FROM _)',
      );
    });
  });
}
