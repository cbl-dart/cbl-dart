import 'dart:async';
import 'dart:math';

import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/api_variant.dart';
import '../utils/database_utils.dart';
import '../utils/matchers.dart';

void main() {
  setupTestBinding();

  group('QueryBuilder', () {
    setupEvalExprUtils();

    apiTest('throws when query is used without FROM clause', () async {
      final query = await runWithApi(
        sync: () => QueryBuilder.createSync().select(SelectResult.all()),
        async: () => QueryBuilder.createAsync().select(SelectResult.all()),
      );
      expect(query.execute, throwsA(isA<StateError>()));
    });

    apiTest('from throws when data source has wrong type', () async {
      final db = await openTestDatabase();
      final collection = await db.defaultCollection;

      final query = await runWithApi(
        sync: () => const AsyncQueryBuilder(),
        async: () => const SyncQueryBuilder(),
      );

      expect(
        () => query
            .select(SelectResult.all())
            .from(DataSource.collection(collection)),
        throwsA(isA<ArgumentError>()),
      );
    });

    apiTest('routers', () async {
      final db = await openTestDatabase();
      final collection = await db.defaultCollection;
      final builder = await runWithApi(
        sync: QueryBuilder.createSync,
        async: QueryBuilder.createAsync,
      );

      void expectBuilderQuery(Query query, Map<String, Object?> selectQuery) {
        expect(query.jsonRepresentation, json(['SELECT', selectQuery]));
      }

      void exploreBuilderQuery(Query query, Map<String, Object?> selectQuery) {
        if (query is FromRouter) {
          final fromRouter = query as FromRouter;
          exploreBuilderQuery(
            fromRouter.from(DataSource.collection(collection)),
            {
              ...selectQuery,
              'FROM': [
                {'COLLECTION': '_default._default'},
              ],
            },
          );
          return;
        }

        expectBuilderQuery(query, selectQuery);

        if (query is JoinRouter) {
          final joinRouter = query as JoinRouter;
          exploreBuilderQuery(
            joinRouter.join(
              Join.join(
                DataSource.collection(collection),
              ).on(Expression.property('a')),
            ),
            {
              ...selectQuery,
              'FROM': <Object>[
                ...selectQuery['FROM']! as List<Object>,
                {
                  'COLLECTION': '_default._default',
                  'JOIN': 'INNER',
                  'ON': ['.a'],
                },
              ],
            },
          );
          exploreBuilderQuery(
            joinRouter.joinAll([
              Join.join(
                DataSource.collection(collection),
              ).on(Expression.property('a')),
            ]),
            {
              ...selectQuery,
              'FROM': <Object>[
                ...selectQuery['FROM']! as List<Object>,
                {
                  'COLLECTION': '_default._default',
                  'JOIN': 'INNER',
                  'ON': ['.a'],
                },
              ],
            },
          );
        }

        if (query is WhereRouter) {
          final whereRouter = query as WhereRouter;
          exploreBuilderQuery(whereRouter.where(Expression.value(true)), {
            ...selectQuery,
            'WHERE': true,
          });
        }

        if (query is GroupByRouter) {
          final groupByRouter = query as GroupByRouter;
          exploreBuilderQuery(groupByRouter.groupBy(Expression.property('a')), {
            ...selectQuery,
            'GROUP_BY': [
              ['.a'],
            ],
          });
          exploreBuilderQuery(
            groupByRouter.groupByAll([Expression.property('a')]),
            {
              ...selectQuery,
              'GROUP_BY': [
                ['.a'],
              ],
            },
          );
        }

        if (query is HavingRouter) {
          final havingRouter = query as HavingRouter;
          exploreBuilderQuery(havingRouter.having(Expression.value(true)), {
            ...selectQuery,
            'HAVING': true,
          });
        }

        if (query is OrderByRouter) {
          final orderByRouter = query as OrderByRouter;
          exploreBuilderQuery(orderByRouter.orderBy(Ordering.property('a')), {
            ...selectQuery,
            'ORDER_BY': [
              ['.a'],
            ],
          });
          exploreBuilderQuery(
            orderByRouter.orderByAll([Ordering.property('a')]),
            {
              ...selectQuery,
              'ORDER_BY': [
                ['.a'],
              ],
            },
          );
        }

        if (query is LimitRouter) {
          final limitRouter = query as LimitRouter;
          exploreBuilderQuery(
            limitRouter.limit(Expression.value(1), offset: Expression.value(0)),
            {...selectQuery, 'LIMIT': 1, 'OFFSET': 0},
          );
        }
      }

      exploreBuilderQuery(builder.select(SelectResult.all()), {
        'WHAT': [
          ['.'],
        ],
        'DISTINCT': false,
      });
      exploreBuilderQuery(builder.selectAll([SelectResult.all()]), {
        'WHAT': [
          ['.'],
        ],
        'DISTINCT': false,
      });
      exploreBuilderQuery(builder.selectDistinct(SelectResult.all()), {
        'WHAT': [
          ['.'],
        ],
        'DISTINCT': true,
      });
      exploreBuilderQuery(builder.selectAllDistinct([SelectResult.all()]), {
        'WHAT': [
          ['.'],
        ],
        'DISTINCT': true,
      });
    });

    group('SelectResult', () {
      setUpAll(
        runWithApiValues(() async {
          final db = await getSharedTestDatabase();
          final collection = await db.defaultCollection;
          final doc = MutableDocument.withId('SelectOneResult', {'a': true});
          await collection.saveDocument(doc);
        }),
      );

      Future<Object?> selectOneResult(
        SelectResultInterface selectResult, {
        DataSourceInterface? dataSource,
      }) => Future.value(getSharedTestDatabase()).then((db) async {
        final collection = await db.defaultCollection;
        final resultSet = await const QueryBuilder()
            .select(selectResult)
            .from(dataSource ?? DataSource.collection(collection))
            .where(Meta.id.equalTo(Expression.string('SelectOneResult')))
            .execute();

        return resultSet.plainMapStream().first;
      });

      apiTest('SelectResult.all()', () async {
        expect(await selectOneResult(SelectResult.all()), {
          '_default': {'a': true},
        });
      });

      apiTest('SelectResult.all().from()', () async {
        final db = await getSharedTestDatabase();
        final collection = await db.defaultCollection;
        const alias = 'myAlias';

        expect(
          await selectOneResult(
            SelectResult.all().from(alias),
            dataSource: DataSource.collection(collection).as(alias),
          ),
          {
            alias: {'a': true},
          },
        );
      });

      apiTest('SelectResult.property()', () async {
        expect(await selectOneResult(SelectResult.property('a')), {'a': true});
      });

      apiTest('SelectResult.property().as()', () async {
        expect(await selectOneResult(SelectResult.property('a').as('b')), {
          'b': true,
        });
      });

      apiTest('SelectResult.expression()', () async {
        expect(await selectOneResult(SelectResult.expression(valExpr(42))), {
          r'$1': 42,
        });
      });

      apiTest('SelectResult.expression().as()', () async {
        expect(
          await selectOneResult(SelectResult.expression(valExpr(42)).as('a')),
          {'a': 42},
        );
      });
    });

    group('Query', () {
      apiTest('distinct', () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;
        await collection.saveDocument(MutableDocument({'a': true}));
        await collection.saveDocument(MutableDocument({'a': true}));

        final resultSet = await const QueryBuilder()
            .selectDistinct(SelectResult.all())
            .from(DataSource.collection(collection))
            .execute();

        final result = await resultSet
            .asStream()
            .map((result) => result.toPlainList()[0])
            .toList();

        expect(result, [
          {'a': true},
        ]);
      });

      apiTest('join', () async {
        final db = await openTestDatabase();

        // Inner join without right side
        expect(
          await db.evalJoin(
            type: JoinType.join,
            docs: [leftJoinDoc(id: 'A', on: 'A')],
          ),
          isEmpty,
        );

        // Inner join with right side
        expect(
          await db.evalJoin(
            type: JoinType.join,
            docs: [
              leftJoinDoc(id: 'A', on: 'A'),
              rightJoinDoc(id: 'B', on: 'A'),
            ],
          ),
          [
            ['A', 'B'],
          ],
        );

        // Left outer join without right side
        expect(
          await db.evalJoin(
            type: JoinType.leftJoin,
            docs: [leftJoinDoc(id: 'A', on: 'A')],
          ),
          [
            ['A', null],
          ],
        );

        // Left outer join with right side
        expect(
          await db.evalJoin(
            type: JoinType.leftJoin,
            docs: [
              leftJoinDoc(id: 'A', on: 'A'),
              rightJoinDoc(id: 'B', on: 'A'),
            ],
          ),
          [
            ['A', 'B'],
          ],
        );

        // Left outer join without right side
        expect(
          await db.evalJoin(
            type: JoinType.leftOuterJoin,
            docs: [leftJoinDoc(id: 'A', on: 'A')],
          ),
          [
            ['A', null],
          ],
        );

        // Left outer join with right side
        expect(
          await db.evalJoin(
            type: JoinType.leftOuterJoin,
            docs: [
              leftJoinDoc(id: 'A', on: 'A'),
              rightJoinDoc(id: 'B', on: 'A'),
            ],
          ),
          [
            ['A', 'B'],
          ],
        );

        // Inner join without right side
        expect(
          await db.evalJoin(
            type: JoinType.innerJoin,
            docs: [leftJoinDoc(id: 'A', on: 'A')],
          ),
          isEmpty,
        );

        // Inner join with right side
        expect(
          await db.evalJoin(
            type: JoinType.innerJoin,
            docs: [
              leftJoinDoc(id: 'A', on: 'A'),
              rightJoinDoc(id: 'B', on: 'A'),
            ],
          ),
          [
            ['A', 'B'],
          ],
        );

        // Cross join without left side
        expect(
          await db.evalJoin(
            type: JoinType.crossJoin,
            docs: [
              leftJoinDoc(id: 'A'),
              rightJoinDoc(id: 'B'),
            ],
          ),
          [
            ['A', 'A'],
            ['A', 'B'],
          ],
        );
      });

      apiTest('orderBy', () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;
        final docs = List.generate(5, (_) => MutableDocument());

        await db.saveAllDocuments(docs);

        final resultSet = await const QueryBuilder()
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.collection(collection))
            .orderBy(Ordering.expression(Meta.id))
            .execute();

        final results = await resultSet
            .asStream()
            .map((result) => result.value(0))
            .toList();

        expect(results, docs.map((doc) => doc.id).toList()..sort());
      });

      apiTest('limit', () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;
        final docs = List.generate(5, (_) => MutableDocument());

        await db.saveAllDocuments(docs);

        final resultSet = await const QueryBuilder()
            .select(SelectResult.expression(Meta.id))
            .from(DataSource.collection(collection))
            .orderBy(Ordering.expression(Meta.id))
            .limit(Expression.value(3), offset: Expression.value(2))
            .execute();

        final results = await resultSet
            .asStream()
            .map((result) => result.value(0))
            .toList();

        expect(results, (docs.map((doc) => doc.id).toList()..sort()).skip(2));
      });
    });

    group('ArrayExpression', () {
      apiTest('range predicate ANY', () async {
        Future<bool> evalAny({
          required Iterable<Object?> values,
          required Object? equalTo,
        }) => evalExpr(
          rangePredicate(
            quantifier: Quantifier.any,
            values: values,
            equalTo: equalTo,
          ),
        );

        expect(await evalAny(values: [], equalTo: 'a'), false);
        expect(await evalAny(values: ['b'], equalTo: 'a'), false);
        expect(await evalAny(values: ['a'], equalTo: 'a'), true);
        expect(await evalAny(values: ['a', 'b'], equalTo: 'a'), true);
      });

      apiTest('range predicate EVERY', () async {
        Future<Object?> evalEvery({
          required Iterable<Object?> values,
          required Object? equalTo,
        }) => evalExpr(
          rangePredicate(
            quantifier: Quantifier.every,
            values: values,
            equalTo: equalTo,
          ),
        );

        expect(await evalEvery(values: [], equalTo: 'a'), true);
        expect(await evalEvery(values: ['b'], equalTo: 'a'), false);
        expect(await evalEvery(values: ['a'], equalTo: 'a'), true);
        expect(await evalEvery(values: ['a', 'b'], equalTo: 'a'), false);
      });

      apiTest('range predicate ANY AND EVERY', () async {
        Future<Object?> evalAnyAndEvery({
          required Iterable<Object?> values,
          required Object? equalTo,
        }) => evalExpr(
          ArrayExpression.anyAndEvery(ArrayExpression.variable('a'))
              .in_(Expression.property('array'))
              .satisfies(
                ArrayExpression.variable('a').equalTo(valExpr(equalTo)),
              ),
          doc: MutableDocument({'array': values}),
        );

        expect(await evalAnyAndEvery(values: [], equalTo: 'a'), false);
        expect(await evalAnyAndEvery(values: ['b'], equalTo: 'a'), false);
        expect(await evalAnyAndEvery(values: ['a'], equalTo: 'a'), true);
        expect(await evalAnyAndEvery(values: ['a', 'b'], equalTo: 'a'), false);
      });
    });

    group('Expression', () {
      apiTest('property()', () async {
        expect(
          await evalExpr(
            Expression.property('a'),
            doc: MutableDocument({'a': true}),
          ),
          true,
        );

        expect(
          await evalExpr(
            Expression.property('a.b'),
            doc: MutableDocument({
              'a': {'b': true},
            }),
          ),
          true,
        );
      });

      apiTest('property().from()', () async {
        expect(
          await evalExpr(
            Expression.property('a').from('b'),
            doc: MutableDocument({'a': true}),
            dataSourceAlias: 'b',
          ),
          true,
        );
      });

      apiTest('all()', () async {
        expect(
          await evalExpr(Expression.all(), doc: MutableDocument({'a': true})),
          {'a': true},
        );
      });

      apiTest('all().from()', () async {
        expect(
          await evalExpr(
            Expression.all().from('b'),
            doc: MutableDocument({'a': true}),
            dataSourceAlias: 'b',
          ),
          {'a': true},
        );
      });

      apiTest('value()', () async {
        expect(await evalExpr(valExpr('x')), 'x');
      });

      apiTest('string()', () async {
        expect(await evalExpr(Expression.string('a')), 'a');
      });

      apiTest('integer()', () async {
        expect(await evalExpr(Expression.integer(1)), 1);
      });

      apiTest('float()', () async {
        expect(await evalExpr(Expression.float(.2)), .2);
      });

      apiTest('number()', () async {
        expect(await evalExpr(Expression.number(3)), 3);
      });

      apiTest('boolean()', () async {
        expect(await evalExpr(Expression.boolean(true)), true);
      });

      apiTest('date()', () async {
        final date = DateTime.utc(0);
        expect(await evalExpr(Expression.date(date)), date.toIso8601String());
      });

      apiTest('dictionary()', () async {
        expect(await evalExpr(Expression.dictionary({'a': true})), {'a': true});
      });

      apiTest('array()', () async {
        expect(await evalExpr(Expression.array(['a'])), ['a']);
      });

      apiTest('parameter()', () async {
        expect(
          await evalExpr(
            Expression.parameter('a'),
            parameters: Parameters({'a': 'x'}),
          ),
          'x',
        );
      });

      apiTest('negated()', () async {
        expect(await evalExpr(Expression.negated(valExpr(true))), false);
      });

      apiTest('not()', () async {
        expect(await evalExpr(Expression.not(valExpr(true))), false);
      });

      apiTest('multiply()', () async {
        expect(await evalExpr(valExpr(2).multiply(valExpr(3))), 6);
      });

      apiTest('divide()', () async {
        expect(await evalExpr(valExpr(6).divide(valExpr(2))), 3);
      });

      apiTest('modulo()', () async {
        expect(await evalExpr(valExpr(1).modulo(valExpr(2))), 1);
      });

      apiTest('add()', () async {
        expect(await evalExpr(valExpr(1).add(valExpr(2))), 3);
      });

      apiTest('subtract()', () async {
        expect(await evalExpr(valExpr(1).subtract(valExpr(2))), -1);
      });

      apiTest('lessThan()', () async {
        expect(await evalExpr(valExpr(1).lessThan(valExpr(2))), true);
        expect(await evalExpr(valExpr(1).lessThan(valExpr(1))), false);
      });

      apiTest('lessThanOrEqualTo()', () async {
        expect(await evalExpr(valExpr(1).lessThanOrEqualTo(valExpr(2))), true);
        expect(await evalExpr(valExpr(1).lessThanOrEqualTo(valExpr(1))), true);
        expect(await evalExpr(valExpr(1).lessThanOrEqualTo(valExpr(0))), false);
      });

      apiTest('greaterThan()', () async {
        expect(await evalExpr(valExpr(1).greaterThan(valExpr(0))), true);
        expect(await evalExpr(valExpr(1).greaterThan(valExpr(1))), false);
      });

      apiTest('greaterThanOrEqualTo()', () async {
        expect(
          await evalExpr(valExpr(1).greaterThanOrEqualTo(valExpr(2))),
          false,
        );
        expect(
          await evalExpr(valExpr(1).greaterThanOrEqualTo(valExpr(1))),
          true,
        );
        expect(
          await evalExpr(valExpr(1).greaterThanOrEqualTo(valExpr(0))),
          true,
        );
      });

      apiTest('equalTo()', () async {
        expect(await evalExpr(valExpr(1).equalTo(valExpr(0))), false);
        expect(await evalExpr(valExpr(1).equalTo(valExpr(1))), true);
      });

      apiTest('notEqualTo()', () async {
        expect(await evalExpr(valExpr(1).notEqualTo(valExpr(0))), true);
        expect(await evalExpr(valExpr(1).notEqualTo(valExpr(1))), false);
      });

      apiTest('like()', () async {
        expect(await evalExpr(valExpr('a').like(valExpr('a'))), true);
        expect(await evalExpr(valExpr('ab').like(valExpr('a_'))), true);
      });

      apiTest('regex()', () async {
        expect(await evalExpr(valExpr('a').regex(valExpr('a'))), true);
        expect(await evalExpr(valExpr('ab').regex(valExpr('a.'))), true);
      });

      apiTest('is_()', () async {
        expect(await evalExpr(valExpr('a').is_(valExpr('a'))), true);
        expect(await evalExpr(valExpr('a').is_(valExpr('b'))), false);
      });

      apiTest('isNot()', () async {
        expect(await evalExpr(valExpr('a').isNot(valExpr('a'))), false);
        expect(await evalExpr(valExpr('a').isNot(valExpr('b'))), true);
      });

      apiTest('isNullOrMissing()', () async {
        expect(await evalExpr(valExpr(null).isNullOrMissing()), true);
        expect(
          await evalExpr(valExpr(Expression.property('X')).isNullOrMissing()),
          true,
        );
        expect(await evalExpr(valExpr('a').isNullOrMissing()), false);
      });

      apiTest('notNullOrMissing()', () async {
        expect(await evalExpr(valExpr(null).notNullOrMissing()), false);
        expect(
          await evalExpr(valExpr(Expression.property('X')).notNullOrMissing()),
          false,
        );
        expect(await evalExpr(valExpr('a').notNullOrMissing()), true);
      });

      apiTest('and()', () async {
        expect(await evalExpr(valExpr(true).and(valExpr(true))), true);
        expect(await evalExpr(valExpr(true).and(valExpr(false))), false);
      });

      apiTest('or()', () async {
        expect(await evalExpr(valExpr(true).or(valExpr(true))), true);
        expect(await evalExpr(valExpr(true).or(valExpr(false))), true);
        expect(await evalExpr(valExpr(false).or(valExpr(false))), false);
      });

      apiTest('between()', () async {
        expect(
          await evalExpr(valExpr(0).between(valExpr(0), and: valExpr(1))),
          true,
        );
        expect(
          await evalExpr(valExpr(2).between(valExpr(0), and: valExpr(1))),
          false,
        );
      });

      apiTest('in_()', () async {
        expect(await evalExpr(valExpr('a').in_([valExpr('a')])), true);
        expect(await evalExpr(valExpr('a').in_([valExpr('b')])), false);
      });

      apiTest('collation()', () async {
        expect(
          await evalExpr(
            valExpr(
              'A',
            ).equalTo(valExpr('a')).collate(Collation.ascii().ignoreCase(true)),
          ),
          true,
        );

        expect(
          await evalExpr(
            valExpr('A')
                .equalTo(valExpr('a'))
                .collate(Collation.unicode().ignoreCase(true)),
          ),
          true,
        );
      });
    });

    group('Meta', () {
      final expirationDate = DateTime.now().add(const Duration(days: 1));
      final doc = apiProvider((_) => MutableDocument());
      final deletedDoc = apiProvider((_) => MutableDocument());

      setUpAll(
        runWithApiValues(() async {
          final db = await getSharedTestDatabase();
          final collection = await db.defaultCollection;
          await collection.saveDocument(doc());
          await collection.setDocumentExpiration(doc().id, expirationDate);
          await collection.saveDocument(deletedDoc());
          await collection.deleteDocument(deletedDoc());
        }),
      );

      Future<Object?> evalMetaExpr(
        ExpressionInterface expression, {
        bool deleted = false,
      }) async {
        final db = await getSharedTestDatabase();
        final collection = await db.defaultCollection;

        final id = deleted ? deletedDoc().id : doc().id;
        var where = Meta.id.equalTo(valExpr(id));

        if (deleted) {
          where = where.and(Meta.isDeleted.equalTo(valExpr(1)));
        }

        final resultSet = await const QueryBuilder()
            .select(SelectResult.expression(expression))
            .from(DataSource.collection(collection))
            .where(where)
            .execute();

        return resultSet.asStream().map((result) => result.value(0)).first;
      }

      apiTest('id', () async {
        expect(await evalMetaExpr(Meta.id), doc().id);
      });

      apiTest('revisionId', () async {
        expect(await evalMetaExpr(Meta.revisionId), doc().revisionId);
      });

      apiTest('sequence', () async {
        expect(await evalMetaExpr(Meta.sequence), doc().sequence);
      });

      apiTest('deleted', () async {
        expect(await evalMetaExpr(Meta.isDeleted), false);
        expect(await evalMetaExpr(Meta.isDeleted, deleted: true), true);
      });

      apiTest('expiration', () async {
        expect(
          await evalMetaExpr(Meta.expiration),
          expirationDate.millisecondsSinceEpoch,
        );
      });
    });

    group('Function', () {
      apiTest('aggregate', () async {
        final db = await openTestDatabase();
        await db.insertAggNumbers([0, 1, 2, 3, 4, 5]);

        expect(
          await db.aggQuery([
            aggNumberResult(Function_.avg),
            aggNumberResult(Function_.count),
            aggNumberResult(Function_.min),
            aggNumberResult(Function_.max),
            aggNumberResult(Function_.sum),
          ]),
          [2.5, 6, 0, 5, 15],
        );
      });

      apiTest('abs', () async {
        expect(await evalExpr(Function_.abs(valExpr(-1))), 1);
      });

      apiTest('acos', () async {
        expect(
          await evalExpr(Function_.acos(valExpr(0))),
          closeEnough(1.5707963267948966),
        );
      });

      apiTest('asin', () async {
        expect(
          await evalExpr(Function_.asin(valExpr(.5))),
          closeEnough(0.5235987755982989),
        );
      });

      apiTest('atan', () async {
        expect(
          await evalExpr(Function_.atan(valExpr(.5))),
          closeEnough(0.4636476090008061),
        );
      });

      apiTest('atan2', () async {
        expect(
          await evalExpr(Function_.atan2(x: valExpr(1), y: valExpr(1))),
          closeEnough(0.7853981633974483),
        );
      });

      apiTest('ceil', () async {
        expect(await evalExpr(Function_.ceil(valExpr(.5))), 1);
      });

      apiTest('cos', () async {
        expect(
          await evalExpr(Function_.cos(valExpr(.5))),
          closeEnough(0.8775825618903728),
        );
      });

      apiTest('degrees', () async {
        expect(await evalExpr(Function_.degrees(valExpr(pi))), 180);
      });

      apiTest('e', () async {
        expect(await evalExpr(Function_.e()), closeEnough(e));
      });

      apiTest('exp', () async {
        expect(
          await evalExpr(Function_.exp(valExpr(2))),
          closeEnough(7.38905609893065),
        );
      });

      apiTest('floor', () async {
        expect(await evalExpr(Function_.floor(valExpr(.5))), 0);
      });

      apiTest('ln', () async {
        expect(
          await evalExpr(Function_.ln(valExpr(.5))),
          closeEnough(-0.6931471805599453),
        );
      });

      apiTest('log', () async {
        expect(
          await evalExpr(Function_.log(valExpr(.5))),
          closeEnough(-0.3010299956639812),
        );
      });

      apiTest('pi', () async {
        expect(await evalExpr(Function_.pi()), pi);
      });

      apiTest('power', () async {
        expect(
          await evalExpr(
            Function_.power(base: valExpr(.5), exponent: valExpr(.5)),
          ),
          closeEnough(0.7071067811865476),
        );
      });

      apiTest('radians', () async {
        expect(
          await evalExpr(Function_.radians(valExpr(180))),
          closeEnough(pi),
        );
      });

      apiTest('round', () async {
        expect(
          await evalExpr(Function_.round(valExpr(.55), digits: valExpr(1))),
          0.6,
        );
      });

      apiTest('sign', () async {
        expect(await evalExpr(Function_.sign(valExpr(5))), 1);
        expect(await evalExpr(Function_.sign(valExpr(0))), 0);
        expect(await evalExpr(Function_.sign(valExpr(-5))), -1);
      });

      apiTest('sin', () async {
        expect(
          await evalExpr(Function_.sin(valExpr(.5))),
          closeEnough(0.479425538604203),
        );
      });

      apiTest('sqrt', () async {
        expect(
          await evalExpr(Function_.sqrt(valExpr(.5))),
          closeEnough(0.7071067811865476),
        );
      });

      apiTest('tan', () async {
        expect(
          await evalExpr(Function_.tan(valExpr(.5))),
          closeEnough(0.5463024898437905),
        );
      });

      apiTest('trunc', () async {
        expect(
          await evalExpr(Function_.trunc(valExpr(.55), digits: valExpr(1))),
          0.5,
        );
      });

      apiTest('contains', () async {
        expect(
          await evalExpr(
            Function_.contains(valExpr('aa'), substring: valExpr('a')),
          ),
          true,
        );
        expect(
          await evalExpr(
            Function_.contains(valExpr('a'), substring: valExpr('b')),
          ),
          false,
        );
      });

      apiTest('length', () async {
        expect(await evalExpr(Function_.length(valExpr(''))), 0);
        expect(await evalExpr(Function_.length(valExpr('a'))), 1);
      });

      apiTest('lower', () async {
        expect(await evalExpr(Function_.lower(valExpr('A'))), 'a');
      });

      apiTest('ltrim', () async {
        expect(await evalExpr(Function_.ltrim(valExpr(' a '))), 'a ');
      });

      apiTest('rtrim', () async {
        expect(await evalExpr(Function_.rtrim(valExpr(' a '))), ' a');
      });

      apiTest('trim', () async {
        expect(await evalExpr(Function_.trim(valExpr(' a '))), 'a');
      });

      apiTest('upper', () async {
        expect(await evalExpr(Function_.upper(valExpr('a'))), 'A');
      });

      apiTest('stringToMillis', () async {
        expect(
          await evalExpr(
            Function_.stringToMillis(valExpr('1970-01-01T00:00:00Z')),
          ),
          0,
        );
      });

      apiTest('stringToUTC', () async {
        expect(
          await evalExpr(
            Function_.stringToUTC(valExpr('1970-01-01T00:00:00Z')),
          ),
          '1970-01-01T00:00:00Z',
        );
      });

      apiTest('millisToString', () async {
        final result = await evalExpr(Function_.millisToString(valExpr(0)));
        expect(DateTime.parse(result! as String), DateTime.utc(1970));
      });

      apiTest('millisToUTC', () async {
        expect(
          await evalExpr(Function_.millisToUTC(valExpr(0))),
          '1970-01-01T00:00:00Z',
        );
      });

      apiTest('prediction', () async {
        Database.prediction.registerModel('uppercase', UppercaseModel());
        addTearDown(() => Database.prediction.unregisterModel('uppercase'));
        expect(
          await evalExpr(
            Function_.prediction(
              'uppercase',
              Expression.dictionary({'in': 'a'}),
            ),
          ),
          {'out': 'A'},
        );

        expect(
          await evalExpr(
            Function_.prediction(
              'uppercase',
              Expression.dictionary({'in': 'a'}),
            ).property('out'),
          ),
          'A',
        );
      });

      apiTest('ifMissingOrNull', () async {
        // Test with NULL and non-NULL values
        expect(
          await evalExpr(
            Function_.ifMissingOrNull(valExpr(null), valExpr('a')),
          ),
          'a',
        );

        // Test with non-NULL value first
        expect(
          await evalExpr(Function_.ifMissingOrNull(valExpr('a'), valExpr('b'))),
          'a',
        );

        // Test with all NULL values
        expect(
          await evalExpr(
            Function_.ifMissingOrNull(valExpr(null), valExpr(null)),
          ),
          null,
        );

        // Test with MISSING value (non-existent property)
        expect(
          await evalExpr(
            Function_.ifMissingOrNull(
              Expression.property('nonexistent'),
              valExpr('fallback'),
            ),
          ),
          'fallback',
        );

        // Test with multiple expressions
        expect(
          await evalExpr(
            Function_.ifMissingOrNull(
              valExpr(null),
              Expression.property('nonexistent'),
              valExpr('result'),
            ),
          ),
          'result',
        );

        // Test ifMissingOrNullAll with list
        expect(
          await evalExpr(
            Function_.ifMissingOrNullAll([
              valExpr(null),
              Expression.property('nonexistent'),
              valExpr('list_result'),
            ]),
          ),
          'list_result',
        );
      });
    });

    group('ArrayFunction', () {
      apiTest('contains', () async {
        ExpressionInterface containsExpr(
          Iterable<Object?> values,
          Object? value,
        ) => ArrayFunction.contains(valExpr(values), value: valExpr(value));

        expect(await evalExpr(containsExpr([], 'a')), false);
        expect(await evalExpr(containsExpr(['a'], 'a')), true);
        expect(await evalExpr(containsExpr(['b'], 'a')), false);
      });

      apiTest('length', () async {
        ExpressionInterface lengthExpr(Iterable<Object?> values) =>
            ArrayFunction.length(valExpr(values));

        expect(await evalExpr(lengthExpr([])), 0);
        expect(await evalExpr(lengthExpr([true])), 1);
        expect(await evalExpr(lengthExpr([true, true])), 2);
      });
    });

    group('FullTextFunction', () {
      apiTest('language enables stemming', () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;

        // English stemming: searching for "run" should match "running".
        await collection.createIndex(
          'english',
          IndexBuilder.fullTextIndex([
            FullTextIndexItem.property('a'),
          ]).language(FullTextLanguage.english),
        );

        // French stemming does not know English word roots, so searching
        // for "run" should not match "running".
        await collection.createIndex(
          'french',
          IndexBuilder.fullTextIndex([
            FullTextIndexItem.property('a'),
          ]).language(FullTextLanguage.french),
        );

        await collection.saveDocument(
          MutableDocument({'a': 'He is running fast'}),
        );

        Future<int> matchCount(String indexName, String query) async {
          final resultSet = await const QueryBuilder()
              .select(SelectResult.expression(Meta.id))
              .from(DataSource.collection(collection))
              .where(FullTextFunction.match(indexName: indexName, query: query))
              .execute();
          return (await resultSet.allPlainListResults()).length;
        }

        // English stemmer reduces "running" to "run", so this matches.
        expect(await matchCount('english', 'run'), 1);

        // French stemmer does not reduce "running" to "run".
        expect(await matchCount('french', 'run'), 0);
      });

      apiTest('match and rank', () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;
        await collection.createIndex(
          'a',
          IndexBuilder.fullTextIndex([FullTextIndexItem.property('a')]),
        );

        final docA = MutableDocument({'a': 'The quick brown fox'});
        await collection.saveDocument(docA);

        final docB = MutableDocument({'a': 'The slow brown fox'});
        await collection.saveDocument(docB);

        final resultSet = await const QueryBuilder()
            .selectAll([
              SelectResult.expression(Meta.id),
              SelectResult.expression(FullTextFunction.rank('a')),
            ])
            .from(DataSource.collection(collection))
            .where(
              FullTextFunction.match(
                indexName: 'a',
                query: 'the OR quick OR brown OR fox',
              ),
            )
            .orderBy(Ordering.expression(FullTextFunction.rank('a')))
            .execute();

        final results = await resultSet.allPlainListResults();

        expect(results, [
          [docB.id, 1.5],
          [docA.id, 2.5],
        ]);
      });
    });
  });
}

// === Eval expression utils ===================================================

void setupEvalExprUtils() {
  setUpAll(
    runWithApiValues(() async {
      final db = await getSharedTestDatabase();
      final collection = await db.defaultCollection;
      await collection.saveDocument(MutableDocument.withId('EvalExpr'));
    }),
  );
}

ExpressionInterface valExpr(Object? value) => Expression.value(value);

Future<T> evalExpr<T extends Object?>(
  ExpressionInterface expression, {
  MutableDocument? doc,
  String? dataSourceAlias,
  Parameters? parameters,
}) async {
  final db = await getSharedTestDatabase();
  final collection = await db.defaultCollection;
  if (doc != null) {
    await collection.saveDocument(doc);
  }

  DataSourceInterface dataSource = DataSource.collection(collection);
  if (dataSourceAlias != null) {
    dataSource = (dataSource as DataSourceAs).as(dataSourceAlias);
  }

  // Giving the select result an alias prevents interpreting top level string
  // literals as property paths.
  final selectResult = SelectResult.expression(expression).as('_');
  final query = const QueryBuilder()
      .select(selectResult)
      .from(dataSource)
      .where(Meta.id.equalTo(Expression.string(doc?.id ?? 'EvalExpr')));

  await query.setParameters(parameters);

  final resultSet = await query.execute();

  return resultSet
      .asStream()
      .map((result) => result.toPlainList()[0] as T)
      .first;
}

enum Quantifier { any, every, anyAndEvery }

ExpressionInterface rangePredicate({
  required Quantifier quantifier,
  required Iterable<Object?> values,
  required Object? equalTo,
}) {
  final variable = ArrayExpression.variable('a');
  ArrayExpressionIn quantified;
  switch (quantifier) {
    case .any:
      quantified = ArrayExpression.any(variable);
    case .every:
      quantified = ArrayExpression.every(variable);
    case .anyAndEvery:
      quantified = ArrayExpression.anyAndEvery(variable);
  }
  return quantified
      .in_(Expression.array(values))
      .satisfies(variable.equalTo(valExpr(equalTo)));
}

// === Aggregate query utils ===================================================

const aggNumberProperty = 'number';
const aggGroupProperty = 'group';
final aggNumberExpression = Expression.property(aggNumberProperty);

SelectResultInterface aggNumberResult(
  ExpressionInterface Function(ExpressionInterface number) fn,
) => SelectResult.expression(fn(aggNumberExpression));

extension on Database {
  FutureOr<void> insertAggNumbers(Iterable<num> numbers) => saveAllDocuments(
    numbers.map(
      (number) =>
          MutableDocument({aggGroupProperty: '0', aggNumberProperty: number}),
    ),
  );

  Future<List<Object?>> aggQuery(
    Iterable<SelectResultInterface> selectResults,
  ) async {
    final collection = await defaultCollection;
    final resultSet = await const QueryBuilder()
        .selectAll(selectResults.toList())
        .from(DataSource.collection(collection))
        .groupBy(Expression.property(aggGroupProperty))
        .execute();

    return resultSet.plainListStream().first;
  }
}

// === Join utils ==============================================================

enum JoinType { join, leftJoin, leftOuterJoin, innerJoin, crossJoin }

MutableDocument leftJoinDoc({required String id, String? on}) =>
    MutableDocument.withId(id, {'side': 'left', 'on': ?on});

MutableDocument rightJoinDoc({required String id, String? on}) =>
    MutableDocument.withId(id, {'side': 'right', 'on': ?on});

extension on Database {
  Future<Object?> evalJoin({
    required JoinType type,
    required Iterable<MutableDocument> docs,
  }) async {
    await deleteAllDocuments();
    await saveAllDocuments(docs);
    final collection = await defaultCollection;
    const leftSide = 'left';
    const rightSide = 'right';

    final sideProp = Expression.property('side');
    final joinProp = Expression.property('on');

    final joinFrom = DataSource.collection(collection).as(rightSide);

    final joinOn = joinProp
        .from(rightSide)
        .equalTo(joinProp.from(leftSide))
        .and(sideProp.from(rightSide).equalTo(valExpr(rightSide)));

    JoinInterface join;
    switch (type) {
      case .join:
        join = Join.join(joinFrom).on(joinOn);
      case .leftJoin:
        join = Join.leftJoin(joinFrom).on(joinOn);
      case .leftOuterJoin:
        join = Join.leftOuterJoin(joinFrom).on(joinOn);
      case .innerJoin:
        join = Join.innerJoin(joinFrom).on(joinOn);
      case .crossJoin:
        join = Join.crossJoin(joinFrom);
    }

    final resultSet = await const QueryBuilder()
        .selectAll([
          SelectResult.expression(Meta.id.from(leftSide)),
          SelectResult.expression(Meta.id.from(rightSide)),
        ])
        .from(DataSource.collection(collection).as(leftSide))
        .join(join)
        .where(sideProp.from(leftSide).equalTo(valExpr(leftSide)))
        .execute();

    return resultSet.allPlainListResults();
  }
}

// === Misc utils ==============================================================

/// Matches numbers which are close to [value].
///
/// This matcher is necessary because the results of database functions vary
/// slightly between different platforms, usually only in the leas significant
/// decimal point. We just want to confirm we are using the right function.
Matcher closeEnough(num value) => closeTo(value, .00000000001);

class UppercaseModel implements PredictiveModel {
  @override
  Dictionary? predict(Dictionary input) =>
      MutableDictionary({'out': input.string('in')!.toUpperCase()});
}
