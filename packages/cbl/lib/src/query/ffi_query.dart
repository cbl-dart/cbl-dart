import 'dart:async';
import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../database.dart';
import '../database/database.dart';
import '../database/ffi_database.dart';
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
import 'query.dart';
import 'query_builder.dart';
import 'result_set.dart';
import 'select_result.dart';

late final _bindings = cblBindings.query;

class FfiQuery
    with NativeResourceMixin<CBLQuery>, DelegatingResourceMixin
    implements SyncQuery {
  FfiQuery(
    SyncDatabase database,
    String query, {
    required String debugCreator,
  }) : this._(
          database: database,
          language: CBLQueryLanguage.n1ql,
          query: _normalizeN1qlQuery(query),
          debugCreator: debugCreator,
        );

  FfiQuery.fromJsonRepresentation(
    SyncDatabase database,
    String json, {
    required String debugCreator,
  }) : this._(
          database: database,
          language: CBLQueryLanguage.json,
          query: json,
          debugCreator: debugCreator,
        );

  FfiQuery._({
    SyncDatabase? database,
    required CBLQueryLanguage language,
    String? query,
    required String debugCreator,
  })  : _database = database as FfiDatabase?,
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
              // The native side sends no arguments. When the native side
              // notfies the listener it has to copy the current query
              // result set.
              native.call((pointer) =>
                  _bindings.copyCurrentResults(pointer, listenerToken)),
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
    final doc = fl.Doc.fromResultData(data.asUint8List(), FLTrust.trusted);
    final flDict = doc.root.asDict!;
    runNativeCalls(() => _bindings.setParameters(
          native.pointer,
          flDict.native.pointer.cast(),
        ));
  }

  List<String> _prepareColumnNames() => List.generate(
        native.call(_bindings.columnCount),
        (index) =>
            native.call((pointer) => _bindings.columnName(pointer, index)),
      );

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
