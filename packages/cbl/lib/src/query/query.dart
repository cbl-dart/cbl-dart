import 'dart:convert';
import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../database.dart';
import '../database/database.dart';
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
abstract class Query {
  /// Creates a [Database] query from a N1QL [query].
  factory Query(Database database, String query) =>
      QueryImpl(database, query, debugCreator: 'Query()');

  /// Creates a [Database] query from a JSON representation of the query.
  factory Query.fromJsonRepresentation(Database database, String json) =>
      QueryImpl.fromJsonRepresentation(
        database,
        json,
        debugCreator: 'Query.fromJsonRepresentation()',
      );

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
  /// Returns a [ResultSet] that iterates over [Result] rows one at a time.
  /// You can run the query any number of times, and you can have multiple
  /// [ResultSet]s active at once.
  ///
  /// The results come from a snapshot of the database taken at the moment
  /// [execute] is called, so they will not reflect any changes made to the
  /// database afterwards.
  ResultSet execute();

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
  String explain();

  /// Returns a [Stream] of [ResultSet]s which emits when the [ResultSet] of
  /// this query changes.
  Stream<ResultSet> changes();

  /// The JSON representation of this query.
  ///
  /// This value can be used to recreate this query with
  /// [Query.fromJsonRepresentation].
  ///
  /// Is `null`, if this query was created from a N1QL query.
  String? get jsonRepresentation;
}

class QueryBuilder {
  QueryBuilder._();

  static Select selectOne(SelectResultInterface result) => select([result]);

  static Select select(Iterable<SelectResultInterface> results) =>
      SelectImpl(results.cast(), false);

  static Select selectOneDistinct(SelectResultInterface result) =>
      selectDistinct([result]);

  static Select selectDistinct(Iterable<SelectResultInterface> results) =>
      SelectImpl(results.cast(), true);
}

// === Impl ====================================================================

late final _bindings = cblBindings.query;

class QueryImpl
    with NativeResourceMixin<CBLQuery>, DelegatingResourceMixin
    implements Query {
  QueryImpl(Database database, String query, {required String debugCreator})
      : this._(
          database: database as DatabaseImpl,
          language: CBLQueryLanguage.n1ql,
          query: _normalizeN1qlQuery(query),
          debugCreator: debugCreator,
        );

  QueryImpl.fromJsonRepresentation(
    Database database,
    String json, {
    required String debugCreator,
  }) : this._(
          database: database as DatabaseImpl,
          language: CBLQueryLanguage.json,
          query: json,
          debugCreator: debugCreator,
        );

  QueryImpl._({
    DatabaseImpl? database,
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
  final DatabaseImpl? _database;
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
  ResultSet execute() => useSync(() => ResultSetImpl(
        native.call(_bindings.execute),
        database: _database!,
        columnNames: _columnNames,
        debugCreator: 'Query.execute()',
      ));

  @override
  String explain() => useSync(() => native.call(_bindings.explain));

  @override
  Stream<ResultSet> changes() => useSync(
      () => CallbackStreamController<ResultSet, Pointer<CBLListenerToken>>(
            parent: this,
            startStream: (callback) => _bindings.addChangeListener(
              native.pointer,
              callback.native.pointer,
            ),
            createEvent: (listenerToken, _) => ResultSetImpl(
              native.call((pointer) {
                // The native side sends no arguments. When the native side
                // notfies the listener it has to copy the current query
                // result set.
                return _bindings.copyCurrentResults(pointer, listenerToken);
              }),
              database: _database!,
              columnNames: _columnNames,
              debugCreator: 'Query.changes()',
            ),
          ).stream);

  CblObject<CBLQuery> _prepareQuery() => CblObject(
        _database!.native.call((pointer) => _bindings.create(
              pointer,
              _language,
              _definition!,
            )),
        debugName: 'Query(creator: $_debugCreator)',
      );

  @override
  String? get jsonRepresentation =>
      _language == CBLQueryLanguage.json ? _definition : null;

  void _applyParameters() {
    final encoder = fl.FleeceEncoder();
    final parameters = _parameters;
    if (parameters != null) {
      final result = parameters.encodeTo(encoder);
      assert(result is! Future);
    } else {
      encoder.beginDict(0);
      encoder.endDict();
    }
    final data = encoder.finish();
    final doc = fl.Doc.fromResultData(data, FLTrust.trusted);
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

class BuilderQuery extends QueryImpl {
  BuilderQuery({
    BuilderQuery? query,
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
  })  : _selects = selects?.toList().cast() ?? query?._selects,
        _distinct = distinct ?? query?._distinct,
        _from = from as DataSourceImpl? ?? query?._from,
        _joins = joins?.toList().cast() ?? query?._joins,
        _where = where as ExpressionImpl? ?? query?._where,
        _groupBys = groupBys?.toList().cast() ?? query?._groupBys,
        _having = having as ExpressionImpl? ?? query?._having,
        _orderings = orderings?.toList().cast() ?? query?._orderings,
        _limit = limit as ExpressionImpl? ?? query?._limit,
        _offset = offset as ExpressionImpl? ?? query?._offset,
        super._(
          database: from?.database ?? query?._database,
          language: CBLQueryLanguage.json,
          debugCreator: 'BuilderQuery()',
        );

  final List<SelectResultImpl>? _selects;
  final bool? _distinct;
  final DataSourceImpl? _from;
  final List<JoinImpl>? _joins;
  final ExpressionImpl? _where;
  final List<ExpressionImpl>? _groupBys;
  final ExpressionImpl? _having;
  final List<OrderingImpl>? _orderings;
  final ExpressionImpl? _limit;
  final ExpressionImpl? _offset;

  @override
  String? get jsonRepresentation =>
      _definition ?? jsonEncode(_buildJsonRepresentation());

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
    if (_from == null) {
      throw StateError(
        'Ensure that a query has a FROM clause before using it.',
      );
    }
    return super.useSync(f);
  }

  @override
  CblObject<CBLQuery> _prepareQuery() {
    _definition = jsonEncode(_buildJsonRepresentation());
    return super._prepareQuery();
  }

  @override
  String toString() => 'Query(json: $jsonRepresentation)';
}
