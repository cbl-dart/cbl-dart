import 'dart:async';

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

    apiTest('execute query from JSON representation', () async {
      final db = await openTestDatabase();
      await db.saveDocument(MutableDocument({'a': 0}));
      await db.saveDocument(MutableDocument({'a': 1}));

      final builderQuery = const QueryBuilder()
          .select(SelectResult.property('a'))
          .from(DataSource.database(db))
          .orderBy(Ordering.property('a'));

      final query = await Query.fromJsonRepresentation(
        db,
        builderQuery.jsonRepresentation!,
      );
      final resultSet = await query.execute();

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

      await q.setParameters(Parameters({'ID': 'A'}));
      var resultSet = await q.execute();
      expect(await resultSet.allResults(), isNotEmpty);

      await q.setParameters(Parameters({'ID': 'B'}));
      resultSet = await q.execute();
      expect(await resultSet.allResults(), isEmpty);
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

    apiTest('change listener is called with current results on registration',
        () async {
      final db = await openTestDatabase();
      final query = await Query.fromN1ql(db, 'SELECT * FROM _');

      // First listener gets current results.
      await query.addChangeListener(expectAsync1((change) async {
        expect(change.query, query);
        expect(Future.value(change.results.allResults()), completion(isEmpty));
      }));

      markTestSkipped(
        'TODO(blaugold): enable full query listener tests '
        'This part is disabled because of an issue in CBL C. '
        'https://issues.couchbase.com/projects/CBL/issues/CBL-2459',
      );
      // Seconds listener gets current results, too.
      // await query.addChangeListener(expectAsync1((change) async {
      //   expect(change.query, query);
      //   expect(Future.value(change.results.allResults()),
      // completion(isEmpty));
      // }));
    });

    apiTest('change listener is notified while listening', () async {
      final db = await openTestDatabase();
      final query = await Query.fromN1ql(db, 'SELECT META().id FROM _');
      final doc = MutableDocument();
      var call = 0;
      final callsDone = Completer<void>();

      late final ListenerToken token;
      token = await query.addChangeListener(expectAsync1((change) async {
        expect(change.query, query);
        final results = await change.results
            .asStream()
            .map((result) => result.string(0))
            .toList();

        switch (call++) {
          case 0:
            expect(results, isEmpty);
            await db.saveDocument(doc);
            break;
          case 1:
            expect(results, [doc.id]);
            await query.removeChangeListener(token);
            callsDone.complete();
            break;
        }
      }, count: 2));

      // Wait for expected calls to listener.
      await callsDone.future;

      // Change the database to trigger another change, which the listener
      // should not be called for.
      await db.saveDocument(MutableDocument());
    });

    apiTest('listeners receive change when parameters change', () async {
      markTestSkipped(
        'TODO: Blocked until fix is available '
        'https://issues.couchbase.com/browse/CBL-2458',
      );
    });

    apiTest('change stream emits when results change', () async {
      final db = await openTestDatabase();
      final query = await Query.fromN1ql(db, 'SELECT META().id FROM _');
      final doc = MutableDocument();

      expect(
        query
            .changes()
            .asyncMap((change) => change.results
                .asStream()
                .map((result) => result.string(0))
                .toList())
            .doOnData((results) {
          if (results.isEmpty) {
            db.saveDocument(doc);
          }
        }),
        emitsInOrder(<Object>[
          isEmpty,
          [doc.id],
        ]),
      );
    });

    apiTest('bad query: error position highlighting', () async {
      final db = await openTestDatabase();
      expect(
        () => Query.fromN1ql(db, 'SELECT foo()'),
        throwsA(isA<DatabaseException>().having(
          (it) => it.toString(),
          'toString()',
          '''
DatabaseException(N1QL syntax error near character 11, code: invalidQuery)
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
