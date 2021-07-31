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
      test('SelectResult.all()', () {
        final db = openTestDb('SelectResultAll');

        db.saveDocument(MutableDocument({'a': true}));

        final result = QueryBuilder.selectOne(SelectResult.all())
            .from(DataSource.database(db))
            .execute()
            .map((result) => result.toPlainMap())
            .toList();

        expect(result, [
          {
            db.name: {'a': true}
          }
        ]);
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
        final db = openTestDb('ArrayFunctionContains');
        var doc = MutableDocument({
          'a': [42]
        });
        db.saveDocument(doc);

        List<String> findByArrayContains(Object? value) =>
            QueryBuilder.selectOne(SelectResult.expression(Meta.id))
                .from(DataSource.database(db))
                .where(ArrayFunction.contains(
                  Expression.property('a'),
                  value: Expression.value(value),
                ))
                .execute()
                .map((result) => result.string(0)!)
                .toList();

        expect(findByArrayContains(42), [doc.id]);
        expect(findByArrayContains(0), isEmpty);
      });

      test('length', () {
        final db = openTestDb('ArrayFunctionLength');
        var doc = MutableDocument({
          'a': [42],
          'b': <void>[]
        });
        db.saveDocument(doc);

        SelectResultAs selectLength(String propertyPath) =>
            SelectResult.expression(
                ArrayFunction.length(Expression.property(propertyPath)));

        final lengths = QueryBuilder.select([
          selectLength('a'),
          selectLength('b'),
        ])
            .from(DataSource.database(db))
            .execute()
            .map((e) => e.toPlainList())
            .first;

        expect(lengths, [1, 0]);
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

Object? evalExpr(ExpressionInterface expression) =>
    QueryBuilder.selectOne(SelectResult.expression(expression))
        .from(DataSource.database(evalExprDb))
        .execute()
        .first
        .value(0);

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

// === Misc utils ==============================================================

/// Matches numbers which are close to [value].
///
/// This matcher is necessary because the results of database functions vary
/// slightly between different platforms, usually only in the leas significant
/// decimal point. We just want to confirm we are using the right function.
Matcher closeEnough(num value) => closeTo(value, .00000000001);
