import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../database.dart';
import '../database/database.dart';
import '../document/common.dart';
import '../fleece/fleece.dart' as fl;
import '../support/ffi.dart';
import '../support/native_object.dart';
import '../support/resource.dart';
import '../support/streams.dart';
import '../support/utils.dart';
import 'data_source.dart';
import 'expressions/expression.dart';
import 'join.dart';
import 'ordering.dart';
import 'parameters.dart';
import 'result.dart';
import 'result_set.dart';
import 'select.dart';
import 'select_result.dart';

/// A [Database] query.
abstract class Query implements Resource {
  /// [Parameters] used for setting values to the query parameters defined
  /// in the query.
  ///
  /// All parameters defined in the query must be given values before running
  /// the query, or the query will fail.
  ///
  /// The returned [Parameters] will be readonly.
  Parameters? get parameters;
  set parameters(Parameters? value);

  /// Executes this query.
  ///
  /// Returns a [ResultSet] that iterates over [Result] rows one at a time. You
  /// can run the query any number of times, and you can have multiple
  /// [ResultSet]s active at once.
  ///
  /// The results come from a snapshot of the database taken at the moment
  /// [execute] is called, so they will not reflect any changes made to the
  /// database afterwards.
  FutureOr<ResultSet> execute();

  /// Returns a string describing the implementation of the compiled query.
  ///
  /// This is intended to be read by a developer for purposes of optimizing the
  /// query, especially to add database indexes. It's not machine-readable and
  /// its format may change.
  ///
  /// As currently implemented, the result has three sections, separated by two
  /// newlines:
  /// * The first section is this query compiled into an SQLite query.
  /// * The second section is the output of SQLite's "EXPLAIN QUERY PLAN"
  ///   command applied to that query; for help interpreting this, see
  ///   https://www.sqlite.org/eqp.html . The most important thing to know is
  ///   that if you see "SCAN TABLE", it means that SQLite is doing a slow
  ///   linear scan of the documents instead of using an index.
  /// * The third sections is this queries JSON representation. This is the data
  ///   structure that is built to describe this query, either by the the query
  ///   builder or when a N1QL query is compiled.
  FutureOr<String> explain();

  /// Returns a [Stream] of [ResultSet]s which emits when the [ResultSet] of
  /// this query changes.
  Stream<ResultSet> changes();

  /// The JSON representation of this query.
  ///
  /// This value can be used to recreate this query with
  /// [SyncQuery.fromJsonRepresentation] or [AsyncQuery.fromJsonRepresentation].
  ///
  /// Is `null`, if this query was created from a N1QL query.
  String? get jsonRepresentation;
}

/// A [Query] with a primarily synchronous API.
abstract class SyncQuery implements Query {
  /// Creates a [SyncQuery] from a N1QL [query].
  factory SyncQuery.fromN1ql(SyncDatabase database, String query) =>
      FfiQuery(database, query, debugCreator: 'SyncQuery.fromN1ql()');

  /// Creates a [SyncQuery] from a JSON representation of the query.
  factory SyncQuery.fromJsonRepresentation(
          SyncDatabase database, String json) =>
      FfiQuery.fromJsonRepresentation(
        database,
        json,
        debugCreator: 'SyncQuery.fromJsonRepresentation()',
      );

  @override
  SyncResultSet execute();

  @override
  String explain();

  @override
  Stream<SyncResultSet> changes();
}

/// A [Query] query with a primarily asynchronous API.
abstract class AsyncQuery implements Query {
  /// Creates an [AsyncQuery] query from a N1QL [query].
  static Future<AsyncQuery> fromN1ql(AsyncDatabase database, String query) =>
      throw UnimplementedError();

  /// Creates a [AsyncQuery] from a JSON representation of the query.
  static Future<AsyncQuery> fromJsonRepresentation(
    AsyncDatabase database,
    String json,
  ) =>
      throw UnimplementedError();

  @override
  Future<ResultSet> execute();

  @override
  Future<String> explain();
}

/// Entry point for building [Query]s through the query builder API.
abstract class QueryBuilder {
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
  ]);

  /// Starts a new query and defines the selected columns.
  Select selectAll(Iterable<SelectResultInterface> results);

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
  ]);

  /// Starts a new query, which returns distinct rows and defines the selected
  /// columns.
  Select selectAllDistinct(Iterable<SelectResultInterface> results);
}

/// The [QueryBuilder] for building [SyncQuery]s.
class SyncQueryBuilder implements QueryBuilder {
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
      SyncSelectImpl(results.cast(), false);

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
      SyncSelectImpl(results.cast(), true);
}

/// The [QueryBuilder] for building [AsyncQuery]s.
class AsyncQueryBuilder implements QueryBuilder {
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
      AsyncSelectImpl(results, false);

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
      AsyncSelectImpl(results, true);
}

// === Impl ====================================================================

late final _bindings = cblBindings.query;

class FfiQuery
    with NativeResourceMixin<CBLQuery>, DelegatingResourceMixin
    implements SyncQuery {
  FfiQuery(Database database, String query, {required String debugCreator})
      : this._(
          database: database as FfiDatabase,
          language: CBLQueryLanguage.n1ql,
          query: _normalizeN1qlQuery(query),
          debugCreator: debugCreator,
        );

  FfiQuery.fromJsonRepresentation(
    Database database,
    String json, {
    required String debugCreator,
  }) : this._(
          database: database as FfiDatabase,
          language: CBLQueryLanguage.json,
          query: json,
          debugCreator: debugCreator,
        );

  FfiQuery._({
    FfiDatabase? database,
    required CBLQueryLanguage language,
    String? query,
    required String debugCreator,
  })  : _database = database,
        _language = language,
        _definition = query,
        _debugCreator = debugCreator {
    database?.registerChildResource(this);
  }

  final String _debugCreator;
  final CBLQueryLanguage _language;
  final FfiDatabase? _database;
  String? _definition;
  late final _columnNames = _prepareColumnNames();

  @override
  late final CblObject<CBLQuery> native = _prepareQuery();

  @override
  Parameters? get parameters => _parameters;
  ParametersImpl? _parameters;

  @override
  set parameters(Parameters? value) {
    if (value == null) {
      _parameters = null;
    } else {
      _parameters = ParametersImpl.from(value);
    }
    _applyParameters();
  }

  @override
  SyncResultSet execute() => useSync(() => FfiResultSet(
        native.call(_bindings.execute),
        database: _database!,
        columnNames: _columnNames,
        debugCreator: 'FfiQuery.execute()',
      ));

  @override
  String explain() => useSync(() => native.call(_bindings.explain));

  @override
  Stream<SyncResultSet> changes() => useSync(
      () => CallbackStreamController<SyncResultSet, Pointer<CBLListenerToken>>(
            parent: this,
            startStream: (callback) => _bindings.addChangeListener(
              native.pointer,
              callback.native.pointer,
            ),
            createEvent: (listenerToken, _) => FfiResultSet(
              native.call((pointer) {
                // The native side sends no arguments. When the native side
                // notfies the listener it has to copy the current query
                // result set.
                return _bindings.copyCurrentResults(pointer, listenerToken);
              }),
              database: _database!,
              columnNames: _columnNames,
              debugCreator: 'FfiQuery.changes()',
            ),
          ).stream);

  CblObject<CBLQuery> _prepareQuery() => CblObject(
        _database!.native.call((pointer) => _bindings.create(
              pointer,
              _language,
              _definition!,
            )),
        debugName: 'FfiQuery(creator: $_debugCreator)',
      );

  @override
  String? get jsonRepresentation =>
      _language == CBLQueryLanguage.json ? _definition : null;

  void _applyParameters() {
    final encoder = fl.FleeceEncoder();
    encoder.extraInfo = FleeceEncoderContext(encodeQueryParameter: true);
    final parameters = _parameters;
    if (parameters != null) {
      final result = parameters.encodeTo(encoder);
      assert(result is! Future);
    } else {
      encoder.beginDict(0);
      encoder.endDict();
    }
    final data = encoder.finish();
    final doc = fl.Doc.fromResultData(data.asUint8List(), FLTrust.trusted);
    final flDict = doc.root.asDict!;
    runNativeCalls(() => _bindings.setParameters(
          native.pointer,
          flDict.native.pointer.cast(),
        ));
  }

  List<String> _prepareColumnNames() =>
      List.generate(native.call(_bindings.columnCount), (index) {
        return native.call((pointer) => _bindings.columnName(pointer, index));
      });

  @override
  String toString() => 'Query(${describeEnum(_language)}: $_definition)';
}

String _normalizeN1qlQuery(String query) => query
    // Collapse whitespace.
    .replaceAll(RegExp(r'\s+'), ' ');

abstract class SyncBuilderQuery extends FfiQuery with BuilderQueryMixin {
  SyncBuilderQuery({
    SyncBuilderQuery? query,
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
  }) : super._(
          database: (from as DataSourceImpl?)?.database as FfiDatabase? ??
              query?._database,
          language: CBLQueryLanguage.json,
          debugCreator: 'BuilderQuery()',
        ) {
    init(
      query: query,
      selects: selects,
      distinct: distinct,
      from: from,
      joins: joins,
      where: where,
      groupBys: groupBys,
      having: having,
      orderings: orderings,
      limit: limit,
      offset: offset,
    );
  }

  @override
  String? get jsonRepresentation => _definition ?? super.jsonRepresentation;

  @override
  CblObject<CBLQuery> _prepareQuery() {
    _definition = super.jsonRepresentation;
    return super._prepareQuery();
  }
}

abstract class AsyncBuilderQuery implements AsyncQuery {
  AsyncBuilderQuery({
    AsyncBuilderQuery? query,
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
  });

  @override
  Parameters? parameters;

  @override
  Future<ResultSet> execute() => throw UnimplementedError();

  @override
  Future<String> explain() => throw UnimplementedError();

  @override
  Stream<ResultSet> changes() => throw UnimplementedError();

  @override
  String? get jsonRepresentation => throw UnimplementedError();

  @override
  bool get isClosed => throw UnimplementedError();
}

mixin BuilderQueryMixin on AbstractResource {
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

  void init({
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

  String? get jsonRepresentation => jsonEncode(_buildJsonRepresentation());

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
  String toString() => 'Query(json: $jsonRepresentation)';

  void _checkHasFrom() {
    if (_from == null) {
      throw StateError(
        'Ensure that a query has a FROM clause before using it.',
      );
    }
  }
}
