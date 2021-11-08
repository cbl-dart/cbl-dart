import 'dart:async';

import 'package:cbl_ffi/cbl_ffi.dart';
import 'package:synchronized/synchronized.dart';

import '../../cbl.dart';
import '../database/proxy_database.dart';
import '../document/common.dart';
import '../fleece/fleece.dart';
import '../service/cbl_service_api.dart';
import '../service/proxy_object.dart';
import '../support/encoding.dart';
import '../support/listener_token.dart';
import '../support/streams.dart';
import '../support/utils.dart';
import 'data_source.dart';
import 'parameters.dart';
import 'query.dart';
import 'query_builder.dart';
import 'result.dart';

class ProxyQuery extends QueryBase with ProxyObjectMixin implements AsyncQuery {
  ProxyQuery({
    required String debugCreator,
    ProxyDatabase? database,
    required CBLQueryLanguage language,
    String? definition,
  }) : super(
          typeName: 'ProxyQuery',
          debugCreator: debugCreator,
          database: database,
          language: language,
          definition: definition,
        );

  late final _lock = Lock();
  late final _listenerTokens = ListenerTokenRegistry(this);
  late List<String> _columnNames;

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
  Future<ResultSet> execute() => use(() => ProxyResultSet(
        query: this,
        results: channel!.stream(ExecuteQuery(queryId: objectId!)),
      ));

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
        results: channel!.stream(QueryChangeResultSet(
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
  AsyncListenStream<QueryChange> changes() =>
      // ignore: lines_longer_than_80_chars
      // TODO(blaugold): refactor `QueryBase` so `changes` can be wrapped with `useSync`
      ListenerStream(
        parent: this,
        addListener: _addChangeListener,
      );

  @override
  // ignore: cast_nullable_to_non_nullable
  Future<void> prepare() => super.prepare() as Future<void>;

  @override
  Future<void> performPrepare() async {
    final channel = database!.channel;

    final state = await channel.call(CreateQuery(
      databaseId: database!.objectId,
      language: language,
      queryDefinition: definition!,
      resultEncoding: EncodingFormat.fleece,
    ));

    _columnNames = state.columnNames;

    bindToTargetObject(channel, state.id);
  }

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
  Future<void> performClose() async {
    if (isBoundToTarget) {
      return finalizeEarly();
    }
  }
}

class ProxyResultSet extends ResultSet {
  ProxyResultSet({
    required ProxyQuery query,
    required Stream<EncodedData> results,
  })  : _query = query,
        _results = results;

  final ProxyQuery _query;
  final Stream<EncodedData> _results;

  @override
  Stream<Result> asStream() => _results
      .map((event) => ResultImpl.fromValuesData(
            event.toFleece(),
            // Every result needs its own context, because each result is
            // encoded independently.
            context: DatabaseMContext(_query.database!),
            columnNames: _query._columnNames,
          ))
      .transform(ResourceStreamTransformer(parent: _query, blocking: true));

  @override
  Future<List<Result>> allResults() => asStream().toList();
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
          debugCreator: 'AsyncBuilderQuery()',
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
