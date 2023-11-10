import 'dart:async';

import 'package:synchronized/synchronized.dart';

import '../bindings.dart';
import '../database/proxy_database.dart';
import '../fleece/encoder.dart';
import '../service/cbl_service_api.dart';
import '../service/proxy_object.dart';
import '../support/encoding.dart';
import '../support/listener_token.dart';
import '../support/resource.dart';
import '../support/streams.dart';
import '../support/tracing.dart';
import '../support/utils.dart';
import '../tracing.dart';
import '../typed_data.dart';
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

class ProxyQuery extends QueryBase with ProxyObjectMixin implements AsyncQuery {
  ProxyQuery({
    ProxyDatabase? super.database,
    required super.language,
    super.definition,
  }) : super(typeName: 'ProxyQuery');

  Future<void>? _preparation;
  late final _lock = Lock();
  late final _listenerTokens = ListenerTokenRegistry(this);
  late List<String> _columnNames;
  _ProxyQueryEarlyFinalizer? _earlyFinalizer;

  @override
  ProxyDatabase? get database => super.database as ProxyDatabase?;

  @override
  Parameters? get parameters => _parameters;
  Parameters? _parameters;

  @override
  Future<void> setParameters(Parameters? parameters) =>
      use(() => _lock.synchronized(() async {
            await _applyParameters(parameters);
            _parameters = parameters;
          }));

  @override
  Future<ResultSet> execute() => asyncOperationTracePoint(
        () => ExecuteQueryOp(this),
        () => use(() async {
          final resultSetId =
              await channel!.call(ExecuteQuery(queryId: objectId!));

          return ProxyResultSet(
            query: this,
            results: channel!.stream(GetQueryResultSet(
              queryId: objectId!,
              resultSetId: resultSetId,
            )),
          );
        }),
      );

  @override
  Future<String> explain() =>
      use(() => channel!.call(ExplainQuery(queryId: objectId!)));

  @override
  Future<ListenerToken> addChangeListener(QueryChangeListener listener) =>
      use(() async {
        final token = await _addChangeListener(listener);
        return token.also(_listenerTokens.add);
      });

  Future<AbstractListenerToken> _addChangeListener(
    QueryChangeListener listener,
  ) async {
    final client = database!.client;
    late final ProxyListenerToken<QueryChange> token;

    final listenerId = client.registerQueryChangeListener((resultSetId) {
      final results = ProxyResultSet(
        query: this,
        results: channel!.stream(GetQueryResultSet(
          queryId: objectId!,
          resultSetId: resultSetId,
        )),
      );
      final change = QueryChange(this, results);
      token.callListener(change);
    });

    await channel!.call(AddQueryChangeListener(
      queryId: objectId!,
      listenerId: listenerId,
    ));

    return token = ProxyListenerToken(client, this, listenerId, listener);
  }

  @override
  Future<void> removeChangeListener(ListenerToken token) =>
      use(() => _listenerTokens.remove(token));

  @override
  AsyncListenStream<QueryChange> changes() => useSync(() => ListenerStream(
        parent: this,
        addListener: (listener) => use(() => _addChangeListener(listener)),
      ));

  @override
  Future<T> use<T>(FutureOr<T> Function() f) => super.use(() async {
        await prepare();
        return f();
      });

  Future<void> prepare() {
    attachToParentResource();
    return _preparation ??= _performPrepare();
  }

  Future<void> _performPrepare() =>
      asyncOperationTracePoint(() => PrepareQueryOp(this), () async {
        final database = this.database!;
        final channel = database.channel;

        final state = await channel.call(CreateQuery(
          databaseId: database.objectId,
          language: language,
          queryDefinition: definition!,
          resultEncoding: database.encodingFormat,
        ));

        _columnNames = state.columnNames;

        // We need this so we don't capture `this` in the closure of
        // proxyFinalizer.
        late final _ProxyQueryEarlyFinalizer earlyFinalizer;

        bindToTargetObject(
          channel,
          state.id,
          // ignore: unnecessary_lambdas
          proxyFinalizer: () => earlyFinalizer.deactivate(),
        );

        _earlyFinalizer =
            earlyFinalizer = _ProxyQueryEarlyFinalizer(database, finalizeEarly);
      });

  Future<void> _applyParameters(Parameters? parameters) {
    EncodedData? encodedParameters;

    if (parameters != null) {
      final encoder = FleeceEncoder();
      (parameters as ParametersImpl).encodeTo(encoder);
      encodedParameters = EncodedData.fleece(encoder.finish());
    }

    return channel!.call(SetQueryParameters(
      queryId: objectId!,
      parameters: encodedParameters,
    ));
  }

  @override
  FutureOr<void> performClose() => _earlyFinalizer?.close();
}

class _ProxyQueryEarlyFinalizer with ClosableResourceMixin {
  _ProxyQueryEarlyFinalizer(ProxyDatabase database, this._finalizerEarly) {
    // We need to attach to the database and not to the query. Otherwise,
    // the query could never be garbage collected.
    attachTo(database);
  }

  final Future<void> Function() _finalizerEarly;

  @override
  FutureOr<void> performClose() => _finalizerEarly();

  /// Deactivates this finalizer if it has not been closed yet.
  void deactivate() {
    if (!isClosed) {
      needsToBeClosedByParent = false;
    }
  }
}

class ProxyResultSet extends AsyncResultSet {
  ProxyResultSet({
    required ProxyQuery query,
    required Stream<TransferableValue> results,
  })  : _query = query,
        _results = results;

  final ProxyQuery _query;
  final Stream<TransferableValue> _results;

  Stream<ResultImpl> _asStream() => _results
      .map((event) => ResultImpl.fromTransferableValue(
            event,
            // Every result needs its own context, because each result is
            // encoded independently.
            context: createResultSetMContext(_query.database!),
            columnNames: _query._columnNames,
          ))
      .transform(ResourceStreamTransformer(parent: _query, blocking: true));

  @override
  Stream<Result> asStream() => _asStream();

  @override
  Stream<D> asTypedStream<D extends TypedDictionaryObject>() {
    final adapter = _query.database!.useWithTypedData();
    return _asStream()
        .map((result) => result.asDictionary)
        .map(adapter.dictionaryFactoryForType<D>());
  }

  @override
  Future<List<Result>> allResults() => asStream().toList();

  @override
  Future<List<D>> allTypedResults<D extends TypedDictionaryObject>() =>
      asTypedStream<D>().toList();
}

class AsyncBuilderQuery extends ProxyQuery with BuilderQueryMixin {
  AsyncBuilderQuery({
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
          database: (from as DataSourceImpl?)?.database as ProxyDatabase? ??
              query?.database as ProxyDatabase?,
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
