import 'dart:ffi';

import 'base.dart';
import 'bindings.dart';
import 'cblite.dart' as cblite_lib;
import 'cblitedart.dart' as cblitedart_lib;
import 'fleece.dart';
import 'global.dart';
import 'tracing.dart';
import 'utils.dart';

export 'cblite.dart'
    show
        CBLIndexUpdater,
        CBLQuery,
        CBLQueryIndex,
        CBLResultSet,
        DartCBLDistanceMetric,
        DartCBLScalarQuantizerType,
        kCBLDistanceMetricCosine,
        kCBLDistanceMetricDot,
        kCBLDistanceMetricEuclidean,
        kCBLDistanceMetricEuclideanSquared,
        kCBLSQ4,
        kCBLSQ6,
        kCBLSQ8;
export 'cblitedart.dart' show CBLDart_IndexType;

enum CBLQueryLanguage {
  json(cblite_lib.kCBLJSONLanguage),
  n1ql(cblite_lib.kCBLN1QLLanguage);

  const CBLQueryLanguage(this.value);

  final int value;
}

enum CBLDartIndexType {
  value$(cblitedart_lib.CBLDart_IndexType.kCBLDart_IndexTypeValue),
  fullText(cblitedart_lib.CBLDart_IndexType.kCBLDart_IndexTypeFullText),
  vector(cblitedart_lib.CBLDart_IndexType.kCBLDart_IndexTypeVector);

  const CBLDartIndexType(this.value);

  static CBLDartIndexType fromValue(int value) => switch (value) {
    cblitedart_lib.CBLDart_IndexType.kCBLDart_IndexTypeValue => value$,
    cblitedart_lib.CBLDart_IndexType.kCBLDart_IndexTypeFullText => fullText,
    cblitedart_lib.CBLDart_IndexType.kCBLDart_IndexTypeVector => vector,
    _ => throw ArgumentError('Unknown value for CBLDart_IndexType: $value'),
  };

  final int value;
}

final class QueryBindings extends Bindings {
  QueryBindings(super.libraries);

  late final _predictiveModelFinalizer = NativeFinalizer(
    cblitedart.addresses.CBLDart_PredictiveModel_Delete.cast(),
  );

  Pointer<cblite_lib.CBLQuery> create(
    Pointer<cblite_lib.CBLDatabase> db,
    CBLQueryLanguage language,
    String queryString,
  ) => withGlobalArena(
    () => nativeCallTracePoint(
      TracedNativeCall.queryCreate,
      () => cblite.CBLDatabase_CreateQuery(
        db,
        language.value,
        queryString.makeGlobalFLString(),
        globalErrorPosition,
        globalCBLError,
      ),
    ).checkError(errorSource: queryString),
  );

  void setParameters(
    Pointer<cblite_lib.CBLQuery> query,
    cblite_lib.FLDict parameters,
  ) {
    cblite.CBLQuery_SetParameters(query, parameters);
  }

  cblite_lib.FLDict parameters(Pointer<cblite_lib.CBLQuery> query) =>
      cblite.CBLQuery_Parameters(query);

  Pointer<cblite_lib.CBLResultSet> execute(
    Pointer<cblite_lib.CBLQuery> query,
  ) => nativeCallTracePoint(
    TracedNativeCall.queryExecute,
    () => cblite.CBLQuery_Execute(query, globalCBLError),
  ).checkError();

  String explain(Pointer<cblite_lib.CBLQuery> query) =>
      cblite.CBLQuery_Explain(query).toDartStringAndRelease()!;

  int columnCount(Pointer<cblite_lib.CBLQuery> query) =>
      cblite.CBLQuery_ColumnCount(query);

  String columnName(Pointer<cblite_lib.CBLQuery> query, int column) =>
      cblite.CBLQuery_ColumnName(query, column).toDartString()!;

  Pointer<cblite_lib.CBLListenerToken> addChangeListener(
    Pointer<cblite_lib.CBLDatabase> db,
    Pointer<cblite_lib.CBLQuery> query,
    cblitedart_lib.CBLDart_AsyncCallback listener,
  ) => cblitedart.CBLDart_CBLQuery_AddChangeListener(db, query, listener);

  Pointer<cblite_lib.CBLResultSet> copyCurrentResults(
    Pointer<cblite_lib.CBLQuery> query,
    Pointer<cblite_lib.CBLListenerToken> listenerToken,
  ) => cblite.CBLQuery_CopyCurrentResults(
    query,
    listenerToken,
    globalCBLError,
  ).checkError();

  cblitedart_lib.CBLDart_PredictiveModel createPredictiveModel(
    String name,
    cblitedart_lib.CBLDart_PredictiveModel_PredictionSync predictionSync,
    cblitedart_lib.CBLDart_PredictiveModel_PredictionAsync predictionAsync,
    cblitedart_lib.CBLDart_PredictiveModel_Unregistered unregistered,
  ) => runWithSingleFLString(
    name,
    (flName) => cblitedart.CBLDart_PredictiveModel_New(
      flName,
      CBLBindings.instance.base.isolateId,
      predictionSync,
      predictionAsync,
      unregistered,
    ),
  );

  void bindCBLDartPredictiveModelToDartObject(
    Finalizable object,
    cblitedart_lib.CBLDart_PredictiveModel model,
  ) => _predictiveModelFinalizer.attach(object, model.cast());

  void unregisterPredictiveModel(String name) =>
      runWithSingleFLString(name, cblite.CBL_UnregisterPredictiveModel);
}

final class ResultSetBindings extends Bindings {
  ResultSetBindings(super.libraries);

  bool next(Pointer<cblite_lib.CBLResultSet> resultSet) =>
      cblite.CBLResultSet_Next(resultSet);

  cblite_lib.FLValue valueAtIndex(
    Pointer<cblite_lib.CBLResultSet> resultSet,
    int index,
  ) => cblite.CBLResultSet_ValueAtIndex(resultSet, index);

  cblite_lib.FLValue valueForKey(
    Pointer<cblite_lib.CBLResultSet> resultSet,
    String key,
  ) => runWithSingleFLString(
    key,
    (flKey) => cblite.CBLResultSet_ValueForKey(resultSet, flKey),
  );

  cblite_lib.FLArray resultArray(Pointer<cblite_lib.CBLResultSet> resultSet) =>
      cblite.CBLResultSet_ResultArray(resultSet);

  cblite_lib.FLDict resultDict(Pointer<cblite_lib.CBLResultSet> resultSet) =>
      cblite.CBLResultSet_ResultDict(resultSet);

  Pointer<cblite_lib.CBLQuery> getQuery(
    Pointer<cblite_lib.CBLResultSet> resultSet,
  ) => cblite.CBLResultSet_GetQuery(resultSet);
}

final class QueryIndexBindings extends Bindings {
  QueryIndexBindings(super.libraries);

  Pointer<cblite_lib.CBLIndexUpdater>? beginUpdate(
    Pointer<cblite_lib.CBLQueryIndex> index,
    int limit,
  ) => cblite.CBLQueryIndex_BeginUpdate(
    index,
    limit,
    // TODO(blaugold): Remove reset once bug is fixed.
    // https://github.com/couchbase/couchbase-lite-C/issues/499
    globalCBLError..ref.reset(),
  ).checkError().toNullable();
}

final class IndexUpdaterBindings extends Bindings {
  IndexUpdaterBindings(super.libraries);

  cblite_lib.FLValue value(
    Pointer<cblite_lib.CBLIndexUpdater> updater,
    int index,
  ) => cblite.CBLIndexUpdater_Value(updater, index);

  int count(Pointer<cblite_lib.CBLIndexUpdater> updater) =>
      cblite.CBLIndexUpdater_Count(updater);

  void setVector(
    Pointer<cblite_lib.CBLIndexUpdater> updater,
    int index,
    List<double>? vector,
  ) {
    withGlobalArena(() {
      cblite.CBLIndexUpdater_SetVector(
        updater,
        index,
        switch (vector) {
          final vector? => globalArena<Float>(
            vector.length,
          )..asTypedList(vector.length).setAll(0, vector),
          null => nullptr,
        },
        vector?.length ?? 0,
        globalCBLError,
      ).checkError();
    });
  }

  void skipVector(Pointer<cblite_lib.CBLIndexUpdater> updater, int index) =>
      cblite.CBLIndexUpdater_SkipVector(updater, index);

  void finish(Pointer<cblite_lib.CBLIndexUpdater> updater) =>
      cblite.CBLIndexUpdater_Finish(updater, globalCBLError).checkError();
}
