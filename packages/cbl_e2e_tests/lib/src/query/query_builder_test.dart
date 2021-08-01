import 'dart:math';

import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/database_utils.dart';

void main() {
  setupTestBinding();

  group('QueryBuilder', () {
    setupEvalExprUtils();

    group('SelectResult', () {
      late final Database db;

      setUpAll(() {
        db = openTestDb('SelectResultCommon');
        db.saveDocument(MutableDocument({'a': true}));
      });

      Object? selectOneResult(SelectResultInterface selectResult) =>
          QueryBuilder.selectOne(selectResult)
              .from(DataSource.database(db))
              .execute()
              .map((result) => result.toPlainMap())
              .first;

      test('SelectResult.all()', () {
        expect(selectOneResult(SelectResult.all()), {
          db.name: {'a': true}
        });
      });

      test('SelectResult.all().from()', () {
        expect(selectOneResult(SelectResult.all().from(db.name)), {
          db.name: {'a': true}
        });
      });

      test('SelectResult.property()', () {
        expect(selectOneResult(SelectResult.property('a')), {'a': true});
      });

      test('SelectResult.property().as()', () {
        expect(
            selectOneResult(SelectResult.property('a').as('b')), {'b': true});
      });

      test('SelectResult.expression()', () {
        expect(
          selectOneResult(SelectResult.expression(valExpr(42))),
          {r'$1': 42},
        );
      });

      test('SelectResult.expression().as()', () {
        expect(
          selectOneResult(SelectResult.expression(valExpr(42)).as('a')),
          {'a': 42},
        );
      });
    });

    group('Query', () {
      test('distinct', () {
        final db = openTestDb('SelectDistinct');
        db.saveDocument(MutableDocument({'a': true}));
        db.saveDocument(MutableDocument({'a': true}));

        final result = QueryBuilder.selectOneDistinct(SelectResult.all())
            .from(DataSource.database(db))
            .execute()
            .map((e) => e.toPlainList()[0])
            .toList();

        expect(result, [
          {'a': true}
        ]);
      });

      test('join', () {
        final db = openTestDb('Join');

        // Inner join without right side
        expect(
          db.evalJoin(type: JoinType.join, docs: [
            leftJoinDoc(id: 'A', on: 'A'),
          ]),
          isEmpty,
        );

        // Inner join with right side
        expect(
          db.evalJoin(type: JoinType.join, docs: [
            leftJoinDoc(id: 'A', on: 'A'),
            rightJoinDoc(id: 'B', on: 'A'),
          ]),
          [
            ['A', 'B']
          ],
        );

        // Left outer join without right side
        expect(
          db.evalJoin(type: JoinType.leftJoin, docs: [
            leftJoinDoc(id: 'A', on: 'A'),
          ]),
          [
            ['A', null]
          ],
        );

        // Left outer join with right side
        expect(
          db.evalJoin(type: JoinType.leftJoin, docs: [
            leftJoinDoc(id: 'A', on: 'A'),
            rightJoinDoc(id: 'B', on: 'A'),
          ]),
          [
            ['A', 'B']
          ],
        );

        // Left outer join without right side
        expect(
          db.evalJoin(type: JoinType.leftOuterJoin, docs: [
            leftJoinDoc(id: 'A', on: 'A'),
          ]),
          [
            ['A', null]
          ],
        );

        // Left outer join with right side
        expect(
          db.evalJoin(type: JoinType.leftOuterJoin, docs: [
            leftJoinDoc(id: 'A', on: 'A'),
            rightJoinDoc(id: 'B', on: 'A'),
          ]),
          [
            ['A', 'B']
          ],
        );

        // Inner join without right side
        expect(
          db.evalJoin(type: JoinType.innerJoin, docs: [
            leftJoinDoc(id: 'A', on: 'A'),
          ]),
          isEmpty,
        );

        // Inner join with right side
        expect(
          db.evalJoin(type: JoinType.innerJoin, docs: [
            leftJoinDoc(id: 'A', on: 'A'),
            rightJoinDoc(id: 'B', on: 'A'),
          ]),
          [
            ['A', 'B']
          ],
        );

        // Cross join without left side
        expect(
          db.evalJoin(type: JoinType.crossJoin, docs: [
            leftJoinDoc(id: 'A'),
            rightJoinDoc(id: 'B'),
          ]),
          [
            ['A', 'A'],
            ['A', 'B']
          ],
        );
      });

      test('orderBy', () {
        final db = openTestDb('QueryBuilderOrderBy');
        final docs = List.generate(5, (_) => MutableDocument());

        db.inBatch(() {
          docs.forEach(db.saveDocument);
        });

        final results = QueryBuilder.selectOne(SelectResult.expression(Meta.id))
            .from(DataSource.database(db))
            .orderByOne(Ordering.expression(Meta.id))
            .execute()
            .map((result) => result.value(0))
            .toList();

        expect(results, docs.map((doc) => doc.id).toList()..sort());
      });

      test('limit', () {
        final db = openTestDb('QueryBuilderLimit');
        final docs = List.generate(5, (_) => MutableDocument());

        db.inBatch(() {
          docs.forEach(db.saveDocument);
        });

        final results = QueryBuilder.selectOne(SelectResult.expression(Meta.id))
            .from(DataSource.database(db))
            .orderByOne(Ordering.expression(Meta.id))
            .limit(Expression.value(3), offset: Expression.value(2))
            .execute()
            .map((result) => result.value(0))
            .toList();

        expect(results, (docs.map((doc) => doc.id).toList()..sort()).skip(2));
      });
    });

    group('ArrayExpression', () {
      test('range predicate ANY', () {
        bool evalAny({
          required Iterable<Object?> values,
          required Object? equalTo,
        }) =>
            evalExpr(rangePredicate(
              quantifier: Quantifier.any,
              values: values,
              equalTo: equalTo,
            )) as bool;

        expect(evalAny(values: [], equalTo: 'a'), false);
        expect(evalAny(values: ['b'], equalTo: 'a'), false);
        expect(evalAny(values: ['a'], equalTo: 'a'), true);
        expect(evalAny(values: ['a', 'b'], equalTo: 'a'), true);
      });

      test('range predicate EVERY', () {
        Object? evalEvery({
          required Iterable<Object?> values,
          required Object? equalTo,
        }) =>
            evalExpr(rangePredicate(
              quantifier: Quantifier.every,
              values: values,
              equalTo: equalTo,
            ));

        expect(evalEvery(values: [], equalTo: 'a'), 1);
        expect(evalEvery(values: ['b'], equalTo: 'a'), 0);
        expect(evalEvery(values: ['a'], equalTo: 'a'), 1);
        expect(evalEvery(values: ['a', 'b'], equalTo: 'a'), 0);
      });

      test('range predicate ANY AND EVERY', () {
        Object? evalAnyAndEvery({
          required Iterable<Object?> values,
          required Object? equalTo,
        }) =>
            evalExpr(
              ArrayExpression.anyAndEvery(ArrayExpression.variable('a'))
                  .in_(Expression.property('array'))
                  .satisfies(
                    ArrayExpression.variable('a').equalTo(valExpr(equalTo)),
                  ),
              doc: MutableDocument({'array': values}),
            );

        expect(evalAnyAndEvery(values: [], equalTo: 'a'), 0);
        expect(evalAnyAndEvery(values: ['b'], equalTo: 'a'), 0);
        expect(evalAnyAndEvery(values: ['a'], equalTo: 'a'), 1);
        expect(evalAnyAndEvery(values: ['a', 'b'], equalTo: 'a'), 0);
      });
    });

    group('Expression', () {
      test('property()', () {
        expect(
          evalExpr(Expression.property('a'), doc: MutableDocument({'a': true})),
          true,
        );

        expect(
          evalExpr(
            Expression.property('a.b'),
            doc: MutableDocument({
              'a': {'b': true}
            }),
          ),
          true,
        );
      });

      test('property().from()', () {
        expect(
          evalExpr(
            Expression.property('a').from('b'),
            doc: MutableDocument({'a': true}),
            dataSourceAlias: 'b',
          ),
          true,
        );
      });

      test('all()', () {
        expect(
          evalExpr(Expression.all(), doc: MutableDocument({'a': true})),
          {'a': true},
        );
      });

      test('all().from()', () {
        expect(
          evalExpr(
            Expression.all().from('b'),
            doc: MutableDocument({'a': true}),
            dataSourceAlias: 'b',
          ),
          {'a': true},
        );
      });

      test('value()', () {
        expect(evalExpr(valExpr('x')), 'x');
      });

      test('string()', () {
        expect(evalExpr(Expression.string('a')), 'a');
      });

      test('integer()', () {
        expect(evalExpr(Expression.integer(1)), 1);
      });

      test('float()', () {
        expect(evalExpr(Expression.float(.2)), .2);
      });

      test('number()', () {
        expect(evalExpr(Expression.number(3)), 3);
      });

      test('boolean()', () {
        expect(evalExpr(Expression.boolean(true)), true);
      });

      test('date()', () {
        final date = DateTime.utc(0);
        expect(evalExpr(Expression.date(date)), date.toIso8601String());
      });

      test('dictionary()', () {
        expect(evalExpr(Expression.dictionary({'a': true})), {'a': true});
      });

      test('array()', () {
        expect(evalExpr(Expression.array(['a'])), ['a']);
      });

      test('parameter()', () {
        expect(
          evalExpr(
            Expression.parameter('a'),
            parameters: Parameters({'a': 'x'}),
          ),
          'x',
        );
      });

      test('negated()', () {
        expect(evalExpr(Expression.negated(valExpr(true))), 0);
      });

      test('not()', () {
        expect(evalExpr(Expression.not(valExpr(true))), 0);
      });

      test('multiply()', () {
        expect(evalExpr(valExpr(2).multiply(valExpr(3))), 6);
      });

      test('divide()', () {
        expect(evalExpr(valExpr(6).divide(valExpr(2))), 3);
      });

      test('modulo()', () {
        expect(evalExpr(valExpr(1).modulo(valExpr(2))), 1);
      });

      test('add()', () {
        expect(evalExpr(valExpr(1).add(valExpr(2))), 3);
      });

      test('subtract()', () {
        expect(evalExpr(valExpr(1).subtract(valExpr(2))), -1);
      });

      test('lessThan()', () {
        expect(evalExpr(valExpr(1).lessThan(valExpr(2))), 1);
        expect(evalExpr(valExpr(1).lessThan(valExpr(1))), 0);
      });

      test('lessThanOrEqualTo()', () {
        expect(evalExpr(valExpr(1).lessThanOrEqualTo(valExpr(2))), 1);
        expect(evalExpr(valExpr(1).lessThanOrEqualTo(valExpr(1))), 1);
        expect(evalExpr(valExpr(1).lessThanOrEqualTo(valExpr(0))), 0);
      });

      test('greaterThan()', () {
        expect(evalExpr(valExpr(1).greaterThan(valExpr(0))), 1);
        expect(evalExpr(valExpr(1).greaterThan(valExpr(1))), 0);
      });

      test('greaterThanOrEqualTo()', () {
        expect(evalExpr(valExpr(1).greaterThanOrEqualTo(valExpr(2))), 0);
        expect(evalExpr(valExpr(1).greaterThanOrEqualTo(valExpr(1))), 1);
        expect(evalExpr(valExpr(1).greaterThanOrEqualTo(valExpr(0))), 1);
      });

      test('equalTo()', () {
        expect(evalExpr(valExpr(1).equalTo(valExpr(0))), 0);
        expect(evalExpr(valExpr(1).equalTo(valExpr(1))), 1);
      });

      test('notEqualTo()', () {
        expect(evalExpr(valExpr(1).notEqualTo(valExpr(0))), 1);
        expect(evalExpr(valExpr(1).notEqualTo(valExpr(1))), 0);
      });

      test('like()', () {
        expect(evalExpr(valExpr('a').like(valExpr('a'))), 1);
        expect(evalExpr(valExpr('ab').like(valExpr('a_'))), 1);
      });

      test('regex()', () {
        expect(evalExpr(valExpr('a').regex(valExpr('a'))), true);
        expect(evalExpr(valExpr('ab').regex(valExpr('a.'))), true);
      });

      test('is_()', () {
        expect(evalExpr(valExpr('a').is_(valExpr('a'))), 1);
        expect(evalExpr(valExpr('a').is_(valExpr('b'))), 0);
      });

      test('isNot()', () {
        expect(evalExpr(valExpr('a').isNot(valExpr('a'))), 0);
        expect(evalExpr(valExpr('a').isNot(valExpr('b'))), 1);
      });

      test('isNullOrMissing()', () {
        expect(evalExpr(valExpr(null).isNullOrMissing()), 1);
        expect(
          evalExpr(valExpr(Expression.property('X')).isNullOrMissing()),
          1,
        );
        expect(evalExpr(valExpr('a').isNullOrMissing()), 0);
      });

      test('notNullOrMissing()', () {
        expect(evalExpr(valExpr(null).notNullOrMissing()), 0);
        expect(
          evalExpr(valExpr(Expression.property('X')).notNullOrMissing()),
          0,
        );
        expect(evalExpr(valExpr('a').notNullOrMissing()), 1);
      });

      test('and()', () {
        expect(evalExpr(valExpr(true).and(valExpr(true))), 1);
        expect(evalExpr(valExpr(true).and(valExpr(false))), 0);
      });

      test('or()', () {
        expect(evalExpr(valExpr(true).or(valExpr(true))), 1);
        expect(evalExpr(valExpr(true).or(valExpr(false))), 1);
        expect(evalExpr(valExpr(false).or(valExpr(false))), 0);
      });

      test('between()', () {
        expect(evalExpr(valExpr(0).between(valExpr(0), and: valExpr(1))), 1);
        expect(evalExpr(valExpr(2).between(valExpr(0), and: valExpr(1))), 0);
      });

      test('in_()', () {
        expect(evalExpr(valExpr('a').in_([valExpr('a')])), 1);
        expect(evalExpr(valExpr('a').in_([valExpr('b')])), 0);
      });

      test('collation()', () {
        expect(
          evalExpr(
            valExpr('A')
                .equalTo(valExpr('a'))
                .collate(Collation.ascii().ignoreCase(true)),
          ),
          1,
        );

        expect(
          evalExpr(
            valExpr('A')
                .equalTo(valExpr('a'))
                .collate(Collation.unicode().ignoreCase(true)),
          ),
          1,
        );
      });
    });

    group('Meta', () {
      final expirationDate = DateTime.utc(3000);
      late final MutableDocument doc;
      late final MutableDocument deletedDoc;
      late final Database db;

      setUpAll(() {
        doc = MutableDocument();
        deletedDoc = MutableDocument();
        db = openTestDb('QueryBuilderMeta');
        db.saveDocument(doc);
        db.setDocumentExpiration(doc.id, expirationDate);
        db.saveDocument(deletedDoc);
        db.deleteDocument(deletedDoc);
      });

      Object? evalMetaExpr(
        ExpressionInterface expression, {
        bool deleted = false,
      }) {
        final id = deleted ? deletedDoc.id : doc.id;
        var where = Meta.id.equalTo(valExpr(id));

        if (deleted) {
          where = where.and(Meta.isDeleted.equalTo(valExpr(1)));
        }

        return QueryBuilder.selectOne(SelectResult.expression(expression))
            .from(DataSource.database(db))
            .where(where)
            .execute()
            .first
            .value(0);
      }

      test('id', () {
        expect(evalMetaExpr(Meta.id), doc.id);
      });

      test('revisionId', () {
        expect(evalMetaExpr(Meta.revisionId), doc.revisionId);
      });

      test('sequence', () {
        expect(evalMetaExpr(Meta.sequence), doc.sequence);
      });

      test('deleted', () {
        expect(evalMetaExpr(Meta.isDeleted), 0);
        expect(evalMetaExpr(Meta.isDeleted, deleted: true), 1);
      });

      test('expiration', () {
        expect(
          evalMetaExpr(Meta.expiration),
          expirationDate.millisecondsSinceEpoch,
        );
      });
    });

    group('Function', () {
      test('aggregate', () {
        final db = openTestDb('QueryBuilderAggregateFunctions');
        db.insertAggNumbers([0, 1, 2, 3, 4, 5]);

        expect(
          db.aggQuery([
            aggNumberResult(Function_.avg),
            aggNumberResult(Function_.count),
            aggNumberResult(Function_.min),
            aggNumberResult(Function_.max),
            aggNumberResult(Function_.sum),
          ]),
          [2.5, 6, 0, 5, 15],
        );
      });

      test('abs', () {
        expect(evalExpr(Function_.abs(valExpr(-1))), 1);
      });

      test('acos', () {
        expect(
          evalExpr(Function_.acos(valExpr(0))),
          closeEnough(1.5707963267948966),
        );
      });

      test('asin', () {
        expect(
          evalExpr(Function_.asin(valExpr(.5))),
          closeEnough(0.5235987755982989),
        );
      });

      test('atan', () {
        expect(
          evalExpr(Function_.atan(valExpr(.5))),
          closeEnough(0.4636476090008061),
        );
      });

      test('atan2', () {
        expect(
          evalExpr(Function_.atan2(x: valExpr(1), y: valExpr(1))),
          closeEnough(0.7853981633974483),
        );
      });

      test('ceil', () {
        expect(evalExpr(Function_.ceil(valExpr(.5))), 1);
      });

      test('cos', () {
        expect(
          evalExpr(Function_.cos(valExpr(.5))),
          closeEnough(0.8775825618903728),
        );
      });

      test('degrees', () {
        expect(evalExpr(Function_.degrees(valExpr(pi))), 180);
      });

      test('e', () {
        expect(evalExpr(Function_.e()), closeEnough(e));
      });

      test('exp', () {
        expect(
          evalExpr(Function_.exp(valExpr(2))),
          closeEnough(7.38905609893065),
        );
      });

      test('floor', () {
        expect(evalExpr(Function_.floor(valExpr(.5))), 0);
      });

      test('ln', () {
        expect(
          evalExpr(Function_.ln(valExpr(.5))),
          closeEnough(-0.6931471805599453),
        );
      });

      test('log', () {
        expect(
          evalExpr(Function_.log(valExpr(.5))),
          closeEnough(-0.3010299956639812),
        );
      });

      test('pi', () {
        expect(evalExpr(Function_.pi()), pi);
      });

      test('power', () {
        expect(
          evalExpr(Function_.power(base: valExpr(.5), exponent: valExpr(.5))),
          closeEnough(0.7071067811865476),
        );
      });

      test('radians', () {
        expect(evalExpr(Function_.radians(valExpr(180))), closeEnough(pi));
      });

      test('round', () {
        expect(
          evalExpr(Function_.round(valExpr(.55), digits: valExpr(1))),
          0.6,
        );
      });

      test('sign', () {
        expect(evalExpr(Function_.sign(valExpr(5))), 1);
        expect(evalExpr(Function_.sign(valExpr(0))), 0);
        expect(evalExpr(Function_.sign(valExpr(-5))), -1);
      });

      test('sin', () {
        expect(
          evalExpr(Function_.sin(valExpr(.5))),
          closeEnough(0.479425538604203),
        );
      });

      test('sqrt', () {
        expect(
          evalExpr(Function_.sqrt(valExpr(.5))),
          closeEnough(0.7071067811865476),
        );
      });

      test('tan', () {
        expect(
          evalExpr(Function_.tan(valExpr(.5))),
          closeEnough(0.5463024898437905),
        );
      });

      test('trunc', () {
        expect(
          evalExpr(Function_.trunc(valExpr(.55), digits: valExpr(1))),
          0.5,
        );
      });

      test('contains', () {
        expect(
          evalExpr(Function_.contains(valExpr('aa'), substring: valExpr('a'))),
          true,
        );
        expect(
          evalExpr(Function_.contains(valExpr('a'), substring: valExpr('b'))),
          false,
        );
      });

      test('length', () {
        expect(evalExpr(Function_.length(valExpr(''))), 0);
        expect(evalExpr(Function_.length(valExpr('a'))), 1);
      });

      test('lower', () {
        expect(evalExpr(Function_.lower(valExpr('A'))), 'a');
      });

      test('ltrim', () {
        expect(evalExpr(Function_.ltrim(valExpr(' a '))), 'a ');
      });

      test('rtrim', () {
        expect(evalExpr(Function_.rtrim(valExpr(' a '))), ' a');
      });

      test('trim', () {
        expect(evalExpr(Function_.trim(valExpr(' a '))), 'a');
      });

      test('upper', () {
        expect(evalExpr(Function_.upper(valExpr('a'))), 'A');
      });

      test('stringToMillis', () {
        expect(
          evalExpr(Function_.stringToMillis(valExpr('1970-01-01T00:00:00Z'))),
          0,
        );
      });

      test('stringToUTC', () {
        expect(
          evalExpr(Function_.stringToUTC(valExpr('1970-01-01T00:00:00Z'))),
          '1970-01-01T00:00:00Z',
        );
      });

      test('millisToString', () {
        var result = evalExpr(Function_.millisToString(valExpr(0))) as String;
        expect(DateTime.parse(result), DateTime.utc(1970));
      });

      test('millisToUTC', () {
        expect(
          evalExpr(Function_.millisToUTC(valExpr(0))),
          '1970-01-01T00:00:00Z',
        );
      });
    });

    group('ArrayFunction', () {
      test('contains', () {
        ExpressionInterface containsExpr(
          Iterable<Object?> values,
          Object? value,
        ) =>
            ArrayFunction.contains(
              valExpr(values),
              value: valExpr(value),
            );

        expect(evalExpr(containsExpr([], 'a')), false);
        expect(evalExpr(containsExpr(['a'], 'a')), true);
        expect(evalExpr(containsExpr(['b'], 'a')), false);
      });

      test('length', () {
        ExpressionInterface lengthExpr(
          Iterable<Object?> values,
        ) =>
            ArrayFunction.length(valExpr(values));

        expect(evalExpr(lengthExpr([])), 0);
        expect(evalExpr(lengthExpr([true])), 1);
        expect(evalExpr(lengthExpr([true, true])), 2);
      });
    });

    group('FullTextFunction', () {
      test('match and rank', () {
        final db = openTestDb('FullTextFunctionRank');
        db.createIndex(
          'a',
          IndexBuilder.fullTextIndex([FullTextIndexItem.property('a')]),
        );
        var docA = MutableDocument({
          'a': 'The quick brown fox',
        });
        db.saveDocument(docA);
        var docB = MutableDocument({
          'a': 'The slow brown fox',
        });
        db.saveDocument(docB);

        final results = QueryBuilder.select([
          SelectResult.expression(Meta.id),
          SelectResult.expression(FullTextFunction.rank('a')),
        ])
            .from(DataSource.database(db))
            .where(FullTextFunction.match(
              indexName: 'a',
              query: 'the OR quick OR brown OR fox',
            ))
            .orderByOne(Ordering.expression(FullTextFunction.rank('a')))
            .execute()
            .map((result) => result.toPlainList())
            .toList();

        expect(results, [
          [docB.id, 1.5],
          [docA.id, 2.5],
        ]);
      });
    });
  });
}

// === Eval expression utils ===================================================

late Database evalExprDb;

void setupEvalExprUtils() {
  setUpAll(() {
    evalExprDb = openTestDb('EvalExpr');
    // Insert exactly one document.
    evalExprDb.saveDocument(MutableDocument());
  });
}

ExpressionInterface valExpr(Object? value) => Expression.value(value);

Object? evalExpr(
  ExpressionInterface expression, {
  MutableDocument? doc,
  String? dataSourceAlias,
  Parameters? parameters,
}) {
  if (doc != null) {
    evalExprDb.deleteAllDocuments();
    evalExprDb.saveDocument(doc);
  }

  DataSourceInterface dataSource = DataSource.database(evalExprDb);
  if (dataSourceAlias != null) {
    dataSource = (dataSource as DataSourceAs).as(dataSourceAlias);
  }

  // Giving the select result an alias prevents interpreting top level string
  // literals as property paths.
  final selectResult = SelectResult.expression(expression).as('_');
  final query = QueryBuilder.selectOne(selectResult).from(dataSource);

  // print(query.explain());

  query.parameters = parameters;

  return query.execute().first.toPlainList()[0];
}

enum Quantifier {
  any,
  every,
  anyAndEvery,
}

ExpressionInterface rangePredicate({
  required Quantifier quantifier,
  required Iterable<Object?> values,
  required Object? equalTo,
}) {
  final variable = ArrayExpression.variable('a');
  ArrayExpressionIn quantified;
  switch (quantifier) {
    case Quantifier.any:
      quantified = ArrayExpression.any(variable);
      break;
    case Quantifier.every:
      quantified = ArrayExpression.every(variable);
      break;
    case Quantifier.anyAndEvery:
      quantified = ArrayExpression.anyAndEvery(variable);
      break;
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
) =>
    SelectResult.expression(fn(aggNumberExpression));

extension on Database {
  void insertAggNumbers(Iterable<num> numbers) => inBatch(() {
        numbers.forEach((number) {
          saveDocument(MutableDocument({
            aggGroupProperty: '0',
            aggNumberProperty: number,
          }));
        });
      });

  List<Object?> aggQuery(Iterable<SelectResultInterface> selectResults) =>
      QueryBuilder.select(selectResults.toList())
          .from(DataSource.database(this))
          .groupBy(Expression.property(aggGroupProperty))
          .execute()
          .first
          .toPlainList();
}

// === Join utils ==============================================================

enum JoinType {
  join,
  leftJoin,
  leftOuterJoin,
  innerJoin,
  crossJoin,
}

MutableDocument leftJoinDoc({
  required String id,
  String? on,
}) =>
    MutableDocument.withId(id, {'side': 'left', if (on != null) 'on': on});

MutableDocument rightJoinDoc({
  required String id,
  String? on,
}) =>
    MutableDocument.withId(id, {'side': 'right', if (on != null) 'on': on});

extension on Database {
  Object? evalJoin({
    required JoinType type,
    required Iterable<MutableDocument> docs,
  }) {
    deleteAllDocuments();
    inBatch(() {
      docs.forEach(saveDocument);
    });
    final leftSide = 'left';
    final rightSide = 'right';

    final sideProp = Expression.property('side');
    final joinProp = Expression.property('on');

    final joinFrom = DataSource.database(this).as(rightSide);

    final joinOn = joinProp
        .from(rightSide)
        .equalTo(joinProp.from(leftSide))
        .and(sideProp.from(rightSide).equalTo(valExpr(rightSide)));

    JoinInterface join;
    switch (type) {
      case JoinType.join:
        join = Join.join(joinFrom).on(joinOn);
        break;
      case JoinType.leftJoin:
        join = Join.leftJoin(joinFrom).on(joinOn);
        break;
      case JoinType.leftOuterJoin:
        join = Join.leftOuterJoin(joinFrom).on(joinOn);
        break;
      case JoinType.innerJoin:
        join = Join.innerJoin(joinFrom).on(joinOn);
        break;
      case JoinType.crossJoin:
        join = Join.crossJoin(joinFrom);
        break;
    }

    return QueryBuilder.select([
      SelectResult.expression(Meta.id.from(leftSide)),
      SelectResult.expression(Meta.id.from(rightSide)),
    ])
        .from(DataSource.database(this).as(leftSide))
        .join(join)
        .where(sideProp.from(leftSide).equalTo(valExpr(leftSide)))
        .execute()
        .map((e) => e.toPlainList())
        .toList();
  }
}

// === Misc utils ==============================================================

/// Matches numbers which are close to [value].
///
/// This matcher is necessary because the results of database functions vary
/// slightly between different platforms, usually only in the leas significant
/// decimal point. We just want to confirm we are using the right function.
Matcher closeEnough(num value) => closeTo(value, .00000000001);
