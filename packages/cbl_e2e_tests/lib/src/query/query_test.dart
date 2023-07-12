// TODO(blaugold): Migrate to collection API.
// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/typed_data_internal.dart';
import 'package:rxdart/rxdart.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/api_variant.dart';
import '../utils/database_utils.dart';
import '../utils/matchers.dart';

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

2|0|0| SCAN _

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

      // Seconds listener gets current results, too.
      await query.addChangeListener(expectAsync1((change) async {
        expect(change.query, query);
        expect(Future.value(change.results.allResults()), completion(isEmpty));
      }));
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
      final db = await openTestDatabase();
      await db.saveDocument(MutableDocument.withId('A'));
      final query = await Query.fromN1ql(
        db,
        r'SELECT META().id FROM _ WHERE META().id = $ID',
      );
      await query.setParameters(Parameters({'ID': 'A'}));

      var changeIndex = 0;

      expect(
        query.changes().asyncMap((change) {
          if (changeIndex == 0) {
            query.setParameters(Parameters({'ID': 'B'}));
          }
          changeIndex++;

          return change.results
              .asStream()
              .map((result) => result.value(0))
              .toList();
        }),
        emitsInOrder(<List<String>>[
          ['A'], // First change is always the initial query result.
          [], // Second change is the result of the parameter change.
        ]),
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

    apiTest('listen to change stream of query created by builder', () async {
      // https://github.com/cbl-dart/cbl-dart/issues/225
      final db = await openTestDatabase();
      final query = const QueryBuilder()
          .select(SelectResult.all())
          .from(DataSource.database(db));

      expect(
        query.changes().asyncMap((change) => change.results.allResults()),
        emitsInOrder(<Object>[isEmpty]),
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

    test('get N1QL source string', () {
      final db = openSyncTestDatabase();
      final n1qlQuery = SyncQuery.fromN1ql(db, 'SELECT * FROM _');
      final jsonQuery = const QueryBuilder()
          .select(SelectResult.all())
          .from(DataSource.database(db));

      expect(n1qlQuery.n1ql, 'SELECT * FROM _');
      expect(jsonQuery.n1ql, isNull);
    });

    apiTest('toString', () async {
      final db = await openTestDatabase();
      expect(
        (await Query.fromN1ql(db, 'SELECT * FROM _')).toString(),
        contains('Query(n1ql: SELECT * FROM _)'),
      );
    });

    group('asTypedStream', () {
      apiTest('throws if database does not support typed data', () async {
        final db = await openTestDatabase();
        final query = await Query.fromN1ql(db, 'SELECT Meta().id FROM _');
        final resultSet = await query.execute();
        expect(
          () => resultSet.asTypedStream<TestTypedDict>(),
          throwsA(
            isTypedDataException
                .havingCode(TypedDataErrorCode.typedDataNotSupported),
          ),
        );
      });

      apiTest('throws if dictionary type is not recognized', () async {
        final db = await openTestDatabase(typedDataAdapter: testAdapter);
        final query = await Query.fromN1ql(db, 'SELECT Meta().id FROM _');
        final resultSet = await query.execute();
        expect(
          () => resultSet.asTypedStream<TestTypedDict2>(),
          throwsA(
            isTypedDataException.havingCode(TypedDataErrorCode.unknownType),
          ),
        );
      });

      apiTest('emits typed dictionaries', () async {
        final db = await openTestDatabase(typedDataAdapter: testAdapter);
        final doc = MutableDocument();
        await db.saveDocument(doc);
        final query = await Query.fromN1ql(db, 'SELECT Meta().id FROM _');
        final resultSet = await query.execute();
        final results = await resultSet.asTypedStream<TestTypedDict>().toList();
        expect(results, hasLength(1));
        expect(results.first.internal.value('id'), doc.id);
      });
    });

    group('allTypedResults', () {
      apiTest('throws if database does not support typed data', () async {
        final db = await openTestDatabase();
        final query = await Query.fromN1ql(db, 'SELECT Meta().id FROM _');
        final resultSet = await query.execute();
        expect(
          () => resultSet.allTypedResults<TestTypedDict>(),
          throwsA(
            isTypedDataException
                .havingCode(TypedDataErrorCode.typedDataNotSupported),
          ),
        );
      });

      apiTest('throws if dictionary type is not recognized', () async {
        final db = await openTestDatabase(typedDataAdapter: testAdapter);
        final query = await Query.fromN1ql(db, 'SELECT Meta().id FROM _');
        final resultSet = await query.execute();
        expect(
          () => resultSet.allTypedResults<TestTypedDict2>(),
          throwsA(
            isTypedDataException.havingCode(TypedDataErrorCode.unknownType),
          ),
        );
      });

      apiTest('returns typed dictionaries', () async {
        final db = await openTestDatabase(typedDataAdapter: testAdapter);
        final doc = MutableDocument();
        await db.saveDocument(doc);
        final query = await Query.fromN1ql(db, 'SELECT Meta().id FROM _');
        final resultSet = await query.execute();
        final results = await resultSet.allTypedResults<TestTypedDict>();
        expect(results, hasLength(1));
        expect(results.first.internal.value('id'), doc.id);
      });
    });

    group('asTypedIterable', () {
      test('throws if database does not support typed data', () {
        final db = openSyncTestDatabase();
        final query = SyncQuery.fromN1ql(db, 'SELECT Meta().id FROM _');
        final resultSet = query.execute();
        expect(
          () => resultSet.asTypedIterable<TestTypedDict>(),
          throwsA(
            isTypedDataException
                .havingCode(TypedDataErrorCode.typedDataNotSupported),
          ),
        );
      });

      test('throws if dictionary type is not recognized', () {
        final db = openSyncTestDatabase(typedDataAdapter: testAdapter);
        final query = SyncQuery.fromN1ql(db, 'SELECT Meta().id FROM _');
        final resultSet = query.execute();
        expect(
          () => resultSet.asTypedIterable<TestTypedDict2>(),
          throwsA(
            isTypedDataException.havingCode(TypedDataErrorCode.unknownType),
          ),
        );
      });

      test('iterates over typed dictionaries', () {
        final db = openSyncTestDatabase(typedDataAdapter: testAdapter);
        final doc = MutableDocument();
        db.saveDocument(doc);
        final query = SyncQuery.fromN1ql(db, 'SELECT Meta().id FROM _');
        final resultSet = query.execute();
        final results = resultSet.asTypedIterable<TestTypedDict>().toList();
        expect(results, hasLength(1));
        expect(results.first.internal.value('id'), doc.id);
      });
    });
  });

  group('QueryChange', () {
    test('toString', () {
      final db = openSyncTestDatabase();
      final query = SyncQuery.fromN1ql(db, 'SELECT * FROM _');
      final results = query.execute();
      final change = QueryChange(query, results);
      expect(
        change.toString(),
        'QueryChange(query: FfiQuery(n1ql: SELECT * FROM _))',
      );
    });
  });
}

class TestTypedDict<I extends Dictionary>
    implements TypedDictionaryObject<MutableTestTypedDoc> {
  TestTypedDict(this.internal);

  @override
  final I internal;

  @override
  MutableTestTypedDoc toMutable() => MutableTestTypedDoc(internal.toMutable());

  @override
  String toString({String? indent}) => super.toString();
}

class MutableTestTypedDoc extends TestTypedDict<MutableDictionary>
    implements
        TypedMutableDictionaryObject<TestTypedDict, MutableTestTypedDoc> {
  MutableTestTypedDoc([MutableDictionary? document])
      : super(document ?? MutableDictionary());
}

class TestTypedDict2 implements TypedDictionaryObject<MutableTestTypedDoc> {
  @override
  Object get internal => throw UnimplementedError();

  @override
  MutableTestTypedDoc toMutable() => throw UnimplementedError();

  @override
  String toString({String? indent}) => super.toString();
}

final testAdapter = TypedDataRegistry(
  types: [
    TypedDictionaryMetadata<TestTypedDict, MutableTestTypedDoc>(
      dartName: 'TestTypedDict',
      factory: TestTypedDict.new,
      mutableFactory: MutableTestTypedDoc.new,
    ),
  ],
);
