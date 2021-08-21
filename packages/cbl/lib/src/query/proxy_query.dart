import 'dart:async';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../../cbl.dart';
import '../database/proxy_database.dart';
import '../document/common.dart';
import '../fleece/fleece.dart';
import '../fleece/integration/context.dart';
import '../service/cbl_service_api.dart';
import '../service/proxy_object.dart';
import '../support/encoding.dart';
import '../support/resource.dart';
import '../support/streams.dart';
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

  @override
  ProxyDatabase? get database => super.database as ProxyDatabase?;

  late List<String> _columnNames;

  Future<void>? _parametersAreSet = Future.value();

  @override
  Parameters? get parameters => _parameters;
  Parameters? _parameters;

  @override
  set parameters(Parameters? parameters) {
    _parameters = parameters;
    _parametersAreSet = null;
  }

  @override
  Future<ResultSet> execute() => use(() => ProxyResultSet(
        query: this,
        results: database!.channel.stream(ExecuteQuery(queryId: objectId!)),
      ));

  @override
  Future<String> explain() =>
      use(() => database!.channel.call(ExplainQuery(queryId: objectId!)));

  @override
  Stream<ResultSet> changes() =>
      use(() => database!.channel.stream(QueryChanges(queryId: objectId!)))
          .asStream()
          .asyncExpand((changes) => changes.map((resultSetId) => ProxyResultSet(
                query: this,
                results: database!.channel.stream(QueryChangeResultSet(
                  queryId: objectId!,
                  resultSetId: resultSetId,
                )),
              )))
          .toClosableResourceStream(this);

  @override
  // ignore: cast_nullable_to_non_nullable
  Future<void> prepare() => super.prepare() as Future<void>;

  @override
  Future<void> performPrepare() async {
    final state = await database!.channel.call(CreateQuery(
      databaseId: database!.objectId,
      language: language,
      queryDefinition: definition!,
      resultEncoding: EncodingFormat.fleece,
    ));

    _columnNames = state.columnNames;

    bindToTargetObject(database!.channel, state.objectId);
    registerChildResource(_ProxyQueryFinalizer(finalizeEarly));
  }

  Future<void> _setParameters() {
    EncodedData? encodedParameters;

    final parameters = _parameters;
    if (parameters != null) {
      final encoder = FleeceEncoder();
      (parameters as ParametersImpl).encodeTo(encoder);
      encodedParameters = EncodedData.fleece(encoder.finish());
    }

    return database!.channel.call(SetQueryParameters(
      queryId: objectId!,
      parameters: encodedParameters,
    ));
  }

  @override
  Future<T> use<T>(FutureOr<T> Function() f) => super.use(() async {
        await (_parametersAreSet ??= _setParameters());
        return f();
      });
}

class _ProxyQueryFinalizer with ClosableResourceMixin {
  _ProxyQueryFinalizer(this.finalize);

  final void Function() finalize;

  @override
  Future<void> performClose() async => finalize();
}

class ProxyResultSet extends ResultSet {
  ProxyResultSet({
    required this.query,
    required Stream<EncodedData> results,
  })  : _results = results,
        _context = DatabaseMContext(query.database!);

  final ProxyQuery query;
  final Stream<EncodedData> _results;
  final MContext _context;

  @override
  Stream<Result> asStream() => _results
      .map((event) => ResultImpl.fromValuesData(
            event.toFleece(),
            context: _context,
            columnNames: query._columnNames,
          ))
      .toClosableResourceStream(query);

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
