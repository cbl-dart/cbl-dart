import 'dart:async';
import 'dart:collection';
import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../database/ffi_database.dart';
import '../document/common.dart';
import '../fleece/fleece.dart' as fl;
import '../support/async_callback.dart';
import '../support/ffi.dart';
import '../support/listener_token.dart';
import '../support/native_object.dart';
import '../support/resource.dart';
import '../support/streams.dart';
import '../support/utils.dart';
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
  SyncResultSet execute() => useSync(() => FfiResultSet(
        native.call(_bindings.execute),
        database: database!,
        columnNames: _columnNames,
        debugCreator: 'FfiQuery.execute()',
      ));

  @override
  String explain() => useSync(() => native.call(_bindings.explain));

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
          native.call((pointer) =>
              _bindings.copyCurrentResults(pointer, listenerToken)),
          database: database!,
          columnNames: _columnNames,
          debugCreator: 'FfiQuery.changes()',
        );

        final change = QueryChange(this, results);
        listener(change);
      },
      debugName: 'FfiQuery.addChangeListener',
    );

    listenerToken = runNativeCalls(() => _bindings.addChangeListener(
          native.pointer,
          callback.native.pointer,
        ));

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
  void prepare() => super.prepare();

  @override
  FutureOr<void> performPrepare() {
    native = CBLObject(
      database!.native.call((pointer) => _bindings.create(
            pointer,
            language,
            definition!,
          )),
      debugName: 'FfiQuery(creator: $debugCreator)',
    );

    _columnNames = List.generate(
      native.call(_bindings.columnCount),
      (index) => native.call((pointer) => _bindings.columnName(pointer, index)),
    );
  }

  void _applyParameters() {
    final encoder = fl.FleeceEncoder()
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
    final flDict = doc.root.asDict!;
    runNativeCalls(() => _bindings.setParameters(
          native.pointer,
          flDict.native.pointer.cast(),
        ));
  }
}

class FfiResultSet with IterableMixin<Result> implements SyncResultSet {
  FfiResultSet(
    Pointer<CBLResultSet> pointer, {
    required FfiDatabase database,
    required List<String> columnNames,
    required String debugCreator,
  })  : _context = DatabaseMContext(database),
        _columnNames = columnNames,
        _iterator = ResultSetIterator(
          pointer,
          debugCreator: debugCreator,
        );

  final DatabaseMContext _context;
  final List<String> _columnNames;
  final ResultSetIterator _iterator;
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
    return _current ??=
        fl.Array.fromPointer(native.call(_bindings.resultArray));
  }

  @override
  bool moveNext() {
    if (_isDone) {
      return false;
    }
    _current = null;
    _isDone = !native.call(_bindings.next);
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
