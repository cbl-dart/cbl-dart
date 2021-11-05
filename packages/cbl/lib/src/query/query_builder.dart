import 'dart:async';
import 'dart:convert';

import 'data_source.dart';
import 'expressions/expression.dart';
import 'join.dart';
import 'ordering.dart';
import 'query.dart';
import 'select.dart';
import 'select_result.dart';

/// Entry point for building [Query]s through the query builder API.
///
/// {@category Query Builder}
class QueryBuilder {
  const QueryBuilder();

  /// {@template cbl.QueryBuilder.createAsync}
  /// Creates an [AsyncQueryBuilder] for building [AsyncQuery]s.
  /// {@endtemplate}
  // ignore: prefer_constructors_over_static_methods
  static AsyncQueryBuilder createAsync() => const AsyncQueryBuilder();

  /// {@template cbl.QueryBuilder.createSync}
  /// Creates a [SyncQueryBuilder] for building [SyncQuery]s.
  /// {@endtemplate}
  // ignore: prefer_constructors_over_static_methods
  static SyncQueryBuilder createSync() => const SyncQueryBuilder();

  /// Starts a new query and defines the selected columns.
  Select select(
    SelectResultInterface result0, [
    SelectResultInterface? result1,
    SelectResultInterface? result2,
    SelectResultInterface? result3,
    SelectResultInterface? result4,
    SelectResultInterface? result5,
    SelectResultInterface? result6,
    SelectResultInterface? result7,
    SelectResultInterface? result8,
    SelectResultInterface? result9,
  ]) =>
      selectAll([
        result0,
        result1,
        result2,
        result3,
        result4,
        result5,
        result6,
        result7,
        result8,
        result9,
      ].whereType());

  /// Starts a new query and defines the selected columns.
  Select selectAll(Iterable<SelectResultInterface> results) =>
      SelectImpl(results, distinct: false);

  /// Starts a new query, which returns distinct rows and defines the selected
  /// columns.
  Select selectDistinct(
    SelectResultInterface result0, [
    SelectResultInterface? result1,
    SelectResultInterface? result2,
    SelectResultInterface? result3,
    SelectResultInterface? result4,
    SelectResultInterface? result5,
    SelectResultInterface? result6,
    SelectResultInterface? result7,
    SelectResultInterface? result8,
    SelectResultInterface? result9,
  ]) =>
      selectAllDistinct([
        result0,
        result1,
        result2,
        result3,
        result4,
        result5,
        result6,
        result7,
        result8,
        result9,
      ].whereType());

  /// Starts a new query, which returns distinct rows and defines the selected
  /// columns.
  Select selectAllDistinct(Iterable<SelectResultInterface> results) =>
      SelectImpl(results, distinct: true);
}

/// The [QueryBuilder] for building [SyncQuery]s.
///
/// {@category Query Builder}
class SyncQueryBuilder implements QueryBuilder {
  /// {@macro cbl.QueryBuilder.createSync}
  const SyncQueryBuilder();

  @override
  SyncSelect select(
    SelectResultInterface result0, [
    SelectResultInterface? result1,
    SelectResultInterface? result2,
    SelectResultInterface? result3,
    SelectResultInterface? result4,
    SelectResultInterface? result5,
    SelectResultInterface? result6,
    SelectResultInterface? result7,
    SelectResultInterface? result8,
    SelectResultInterface? result9,
  ]) =>
      selectAll([
        result0,
        result1,
        result2,
        result3,
        result4,
        result5,
        result6,
        result7,
        result8,
        result9,
      ].whereType());

  @override
  SyncSelect selectAll(Iterable<SelectResultInterface> results) =>
      SyncSelectImpl(results.cast(), distinct: false);

  @override
  SyncSelect selectDistinct(
    SelectResultInterface result0, [
    SelectResultInterface? result1,
    SelectResultInterface? result2,
    SelectResultInterface? result3,
    SelectResultInterface? result4,
    SelectResultInterface? result5,
    SelectResultInterface? result6,
    SelectResultInterface? result7,
    SelectResultInterface? result8,
    SelectResultInterface? result9,
  ]) =>
      selectAllDistinct([
        result0,
        result1,
        result2,
        result3,
        result4,
        result5,
        result6,
        result7,
        result8,
        result9,
      ].whereType());

  @override
  SyncSelect selectAllDistinct(Iterable<SelectResultInterface> results) =>
      SyncSelectImpl(results.cast(), distinct: true);
}

/// The [QueryBuilder] for building [AsyncQuery]s.
///
/// {@category Query Builder}
class AsyncQueryBuilder implements QueryBuilder {
  /// {@macro cbl.QueryBuilder.createAsync}
  const AsyncQueryBuilder();

  @override
  AsyncSelect select(
    SelectResultInterface result0, [
    SelectResultInterface? result1,
    SelectResultInterface? result2,
    SelectResultInterface? result3,
    SelectResultInterface? result4,
    SelectResultInterface? result5,
    SelectResultInterface? result6,
    SelectResultInterface? result7,
    SelectResultInterface? result8,
    SelectResultInterface? result9,
  ]) =>
      selectAll([
        result0,
        result1,
        result2,
        result3,
        result4,
        result5,
        result6,
        result7,
        result8,
        result9,
      ].whereType());

  @override
  AsyncSelect selectAll(Iterable<SelectResultInterface> results) =>
      AsyncSelectImpl(results, distinct: false);

  @override
  AsyncSelect selectDistinct(
    SelectResultInterface result0, [
    SelectResultInterface? result1,
    SelectResultInterface? result2,
    SelectResultInterface? result3,
    SelectResultInterface? result4,
    SelectResultInterface? result5,
    SelectResultInterface? result6,
    SelectResultInterface? result7,
    SelectResultInterface? result8,
    SelectResultInterface? result9,
  ]) =>
      selectAllDistinct([
        result0,
        result1,
        result2,
        result3,
        result4,
        result5,
        result6,
        result7,
        result8,
        result9,
      ].whereType());

  @override
  AsyncSelect selectAllDistinct(Iterable<SelectResultInterface> results) =>
      AsyncSelectImpl(results, distinct: true);
}

mixin BuilderQueryMixin on QueryBase {
  late final List<SelectResultImpl>? _selects;
  late final bool? _distinct;
  late final DataSourceImpl? _from;
  late final List<JoinImpl>? _joins;
  late final ExpressionImpl? _where;
  late final List<ExpressionImpl>? _groupBys;
  late final ExpressionImpl? _having;
  late final List<OrderingImpl>? _orderings;
  late final ExpressionImpl? _limit;
  late final ExpressionImpl? _offset;

  void initBuilderQuery({
    BuilderQueryMixin? query,
    Iterable<SelectResultInterface>? selects,
    bool? distinct,
    DataSourceInterface? from,
    Iterable<JoinInterface>? joins,
    ExpressionInterface? where,
    Iterable<ExpressionInterface>? groupBys,
    ExpressionInterface? having,
    Iterable<OrderingInterface>? orderings,
    ExpressionInterface? limit,
    ExpressionInterface? offset,
  }) {
    _selects = selects?.toList().cast() ?? query?._selects;
    _distinct = distinct ?? query?._distinct;
    _from = from as DataSourceImpl? ?? query?._from;
    _joins = joins?.toList().cast() ?? query?._joins;
    _where = where as ExpressionImpl? ?? query?._where;
    _groupBys = groupBys?.toList().cast() ?? query?._groupBys;
    _having = having as ExpressionImpl? ?? query?._having;
    _orderings = orderings?.toList().cast() ?? query?._orderings;
    _limit = limit as ExpressionImpl? ?? query?._limit;
    _offset = offset as ExpressionImpl? ?? query?._offset;
  }

  @override
  String get definition => jsonRepresentation;

  @override
  late String jsonRepresentation = jsonEncode(_buildJsonRepresentation());

  Object _buildJsonRepresentation() => [
        'SELECT',
        {
          if (_selects != null)
            'WHAT': _selects!.map((select) => select.toJson()).toList(),
          if (_distinct != null) 'DISTINCT': _distinct,
          if (_from != null || _joins != null)
            'FROM': [
              if (_from != null) _from!.toJson(),
              if (_joins != null) ..._joins!.map((join) => join.toJson())
            ],
          if (_where != null) 'WHERE': _where!.toJson(),
          if (_having != null) 'HAVING': _having!.toJson(),
          if (_groupBys != null)
            'GROUP_BY': _groupBys!.map((groupBy) => groupBy.toJson()).toList(),
          if (_orderings != null)
            'ORDER_BY': _orderings!.map((e) => e.toJson()).toList(),
          if (_limit != null) 'LIMIT': _limit!.toJson(),
          if (_offset != null) 'OFFSET': _offset!.toJson()
        }
      ];

  @override
  T useSync<T>(T Function() f) {
    _checkHasFrom();
    return super.useSync(f);
  }

  @override
  Future<T> use<T>(FutureOr<T> Function() f) {
    _checkHasFrom();
    return super.use(f);
  }

  @override
  String toString() => '$typeName(json: $jsonRepresentation)';

  void _checkHasFrom() {
    if (_from == null) {
      throw StateError('Query has no FROM clause.');
    }
  }
}
