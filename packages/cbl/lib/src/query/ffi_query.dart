import 'dart:async';
import 'dart:collection';
import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../database/ffi_database.dart';
import '../document/common.dart';
import '../fleece/containers.dart' as fl;
import '../fleece/encoder.dart';
import '../support/async_callback.dart';
import '../support/errors.dart';
import '../support/ffi.dart';
import '../support/listener_token.dart';
import '../support/native_object.dart';
import '../support/resource.dart';
import '../support/streams.dart';
import '../support/tracing.dart';
import '../support/utils.dart';
import '../tracing.dart';
import 'data_source.dart';
import 'expressions/expression.dart';
import 'join.dart';
import 'ordering.dart';
import 'parameters.dart';
import 'query.dart';
import 'query_builder.dart';
import 'query_change.dart';
import 'result.dart';
import 'result_set.dart';
import 'select_result.dart';

late final _bindings = cblBindings.query;

class FfiQuery extends QueryBase
    implements SyncQuery, NativeResource<CBLQuery> {
  FfiQuery({
    required String debugCreator,
    FfiDatabase? database,
    required CBLQueryLanguage language,
    String? definition,
  }) : super(
          typeName: 'FfiQuery',
          debugCreator: debugCreator,
          database: database,
          language: language,
          definition: definition,
        );

  var _isPrepared = false;

  late final _listenerTokens = ListenerTokenRegistry(this);

  @override
  FfiDatabase? get database => super.database as FfiDatabase?;

  @override
  late final NativeObject<CBLQuery> native;

  List<String> get columnNames => useSync(() => _columnNames);
  late final List<String> _columnNames;

  @override
  Parameters? get parameters => _parameters;
  ParametersImpl? _parameters;

  @override
  void setParameters(Parameters? value) => useSync(() {
        if (value == null) {
          _parameters = null;
        } else {
          _parameters = ParametersImpl.from(value);
        }
        _applyParameters();
      });

  @override
  SyncResultSet execute() => syncOperationTracePoint(
        () => ExecuteQueryOp(this),
        () => useSync(
          () {
            final result = FfiResultSet(
              runWithErrorTranslation(() => _bindings.execute(native.pointer)),
              query: this,
              columnNames: _columnNames,
              debugCreator: 'FfiQuery.execute()',
            );
            cblReachabilityFence(native);
            return result;
          },
        ),
      );

  @override
  String explain() => useSync(() {
        final result = _bindings.explain(native.pointer);
        cblReachabilityFence(native);
        return result;
      });

  @override
  ListenerToken addChangeListener(
    QueryChangeListener<SyncResultSet> listener,
  ) =>
      useSync(() => _addChangeListener(listener).also(_listenerTokens.add));

  AbstractListenerToken _addChangeListener(
    QueryChangeListener<SyncResultSet> listener,
  ) {
    late Pointer<CBLListenerToken> listenerToken;

    final callback = AsyncCallback(
      (_) {
        final results = FfiResultSet(
          // The native side sends no arguments. When the native side
          // notifies the listener it has to copy the current query
          // result set.
          _bindings.copyCurrentResults(native.pointer, listenerToken),
          query: this,
          columnNames: _columnNames,
          debugCreator: 'FfiQuery.changes()',
        );
        cblReachabilityFence(native);

        final change = QueryChange(this, results);
        listener(change);
        return null;
      },
      debugName: 'FfiQuery.addChangeListener',
    );

    final callbackNative = callback.native;
    listenerToken =
        _bindings.addChangeListener(native.pointer, callbackNative.pointer);
    cblReachabilityFence(native);
    cblReachabilityFence(callbackNative);

    return FfiListenerToken(callback);
  }

  @override
  void removeChangeListener(ListenerToken token) => useSync(() {
        final result = _listenerTokens.remove(token);
        assert(result is! Future);
      });

  @override
  Stream<QueryChange<SyncResultSet>> changes() => useSync(() => ListenerStream(
        parent: this,
        addListener: _addChangeListener,
      ));

  @override
  T useSync<T>(T Function() f) => super.useSync(() {
        prepare();
        return f();
      });

  void prepare() {
    if (_isPrepared) {
      return;
    }
    _isPrepared = true;
    attachToParentResource();
    _performPrepare();
  }

  void _performPrepare() {
    syncOperationTracePoint(() => PrepareQueryOp(this), () {
      native = CBLObject(
        runWithErrorTranslation(
          () => _bindings.create(database!.pointer, language, definition!),
        ),
        debugName: 'FfiQuery(creator: $debugCreator)',
      );
      cblReachabilityFence(database);

      _columnNames = List.generate(
        _bindings.columnCount(native.pointer),
        (index) => _bindings.columnName(native.pointer, index),
      );
      cblReachabilityFence(native);
    });
  }

  void _applyParameters() {
    final encoder = FleeceEncoder()
      ..extraInfo = FleeceEncoderContext(encodeQueryParameter: true);
    final parameters = _parameters;
    if (parameters != null) {
      final result = parameters.encodeTo(encoder);
      assert(result is! Future);
    } else {
      encoder
        ..beginDict(0)
        ..endDict();
    }
    final data = encoder.finish();
    final doc = fl.Doc.fromResultData(data, FLTrust.trusted);
    final dict = doc.root.asDict!;
    _bindings.setParameters(native.pointer, dict.pointer.cast());
    cblReachabilityFence(native);
    cblReachabilityFence(dict);
  }
}

class FfiResultSet with IterableMixin<Result> implements SyncResultSet {
  FfiResultSet(
    Pointer<CBLResultSet> pointer, {
    required FfiQuery query,
    required List<String> columnNames,
    required String debugCreator,
  })  : _columnNames = columnNames,
        _iterator = ResultSetIterator(
          pointer,
          debugCreator: debugCreator,
        ),
        _context = createResultSetMContext(query.database!);

  final List<String> _columnNames;
  final ResultSetIterator _iterator;
  final DatabaseMContext _context;
  Result? _current;

  @override
  Stream<Result> asStream() => Stream.fromIterable(this);

  @override
  FutureOr<List<Result>> allResults() => toList();

  @override
  Iterator<Result> get iterator => this;

  @override
  Result get current => _current ??= ResultImpl.fromValuesArray(
        _iterator.current,
        // Results from the same result set can share the same context, because
        // in CBL C, a result set is encoded in a single Fleece doc.
        context: _context,
        columnNames: _columnNames,
      );

  @override
  bool moveNext() {
    _current = null;
    return _iterator.moveNext();
  }

  @override
  String toString() => 'FfiResultSet()';
}

class ResultSetIterator extends CBLObject<CBLResultSet>
    with IterableMixin<fl.Array>
    implements Iterator<fl.Array> {
  ResultSetIterator(
    Pointer<CBLResultSet> pointer, {
    this.encodeArray = false,
    required String debugCreator,
  }) : super(
          pointer,
          debugName: 'ResultSetIterator(creator: $debugCreator)',
        );

  static late final _bindings = cblBindings.resultSet;

  final bool encodeArray;
  var _isDone = false;
  fl.Array? _current;

  @override
  Iterator<fl.Array> get iterator => this;

  @override
  fl.Array get current {
    assert(_current != null || !_isDone);
    final result =
        _current ??= fl.Array.fromPointer(_bindings.resultArray(pointer));
    cblReachabilityFence(this);
    return result;
  }

  @override
  bool moveNext() {
    if (_isDone) {
      return false;
    }
    _current = null;
    _isDone = !_bindings.next(pointer);
    cblReachabilityFence(this);
    return !_isDone;
  }
}

abstract class SyncBuilderQuery extends FfiQuery with BuilderQueryMixin {
  SyncBuilderQuery({
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
  }) : super(
          debugCreator: 'SyncBuilderQuery()',
          database: (from as DataSourceImpl?)?.database as FfiDatabase? ??
              query?.database as FfiDatabase?,
          language: CBLQueryLanguage.json,
        ) {
    initBuilderQuery(
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
}
