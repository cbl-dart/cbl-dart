import 'package:cbl/cbl.dart';
import 'package:rxdart/rxdart.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/api_variant.dart';
import '../utils/database_utils.dart';

void main() {
  setupTestBinding();

  group('Query', () {
    apiTest('execute simple query', () async {
      final db = await openTestDatabase();
      await db.saveDocument(MutableDocument({'a': 0}));
      await db.saveDocument(MutableDocument({'a': 1}));

      final q = await Query.fromN1ql(db, 'SELECT a FROM _ ORDER BY a');
      final resultSet = await q.execute();

      expect(
        await resultSet
            .asStream()
            .map((result) => result.toPlainMap())
            .toList(),
        [
          {'a': 0},
          {'a': 1}
        ],
      );
    });

    apiTest('execute query with parameters', () async {
      final db = await openTestDatabase();
      final q =
          await Query.fromN1ql(db, r'SELECT doc FROM _ WHERE META().id = $ID');
      await db.saveDocument(MutableDocument.withId('A'));

      q.parameters = Parameters({'ID': 'A'});
      var resultSet = await q.execute();
      expect(await resultSet.allResults(), isNotEmpty);

      q.parameters = Parameters({'ID': 'B'});
      resultSet = await q.execute();
      expect(await resultSet.allResults(), isEmpty);
    });

    apiTest('listen to query with parameters', () async {
      final db = await openTestDatabase();
      final q =
          await Query.fromN1ql(db, r'SELECT doc FROM _ WHERE META().id = $ID');
      await db.saveDocument(MutableDocument.withId('A'));

      q.parameters = Parameters({'ID': 'A'});
      expect(
        await q.changes().map((result) => result.allResults()).first,
        isNotEmpty,
      );

      q.parameters = Parameters({'ID': 'B'});
      expect(
        await q.changes().map((result) => result.allResults()).first,
        isEmpty,
      );
    });

    apiTest('explain returns the query plan explanation', () async {
      final db = await openTestDatabase();
      final q = await Query.fromN1ql(db, 'SELECT doc FROM _');

      expect(
        await q.explain(),
        '''
SELECT fl_result(fl_value(_.body, 'doc')) FROM kv_default AS _ WHERE (_.flags & 1 = 0)

2|0|0| SCAN TABLE kv_default AS _

{"FROM":[{"COLLECTION":"_"}],"WHAT":[[".doc"]]}
''',
      );
    });

    apiTest('listener is notified of changes', () async {
      final db = await openTestDatabase();
      final q =
          await Query.fromN1ql(db, 'SELECT a FROM _ AS a WHERE a.b = "c"');

      final doc = MutableDocument({'b': 'c'});
      final result = {'a': doc.toPlainMap()};
      final stream = q
          .changes()
          .asyncMap((resultSet) => resultSet.allPlainMapResults())
          .shareReplay();

      expect(
        stream,
        emitsInOrder(<dynamic>[
          isEmpty,
          [result],
        ]),
      );

      await stream.first.then((_) => db.saveDocument(doc));
    });

    apiTest('bad query: error position highlighting', () async {
      final db = await openTestDatabase();
      expect(
        () => Query.fromN1ql(db, 'SELECT foo()'),
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

    apiTest('toString', () async {
      final db = await openTestDatabase();
      expect(
        (await Query.fromN1ql(db, 'SELECT * FROM _')).toString(),
        contains('Query(n1ql: SELECT * FROM _)'),
      );
    });
  });
}
