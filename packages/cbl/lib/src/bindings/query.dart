import 'dart:ffi';

import 'base.dart';
import 'bindings.dart';
import 'cblite.dart' as cblite;
import 'cblitedart.dart' as cblitedart;
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
  json(cblite.kCBLJSONLanguage),
  n1ql(cblite.kCBLN1QLLanguage);

  const CBLQueryLanguage(this.value);

  final int value;
}

enum CBLDartIndexType {
  value$(cblitedart.CBLDart_IndexType.kCBLDart_IndexTypeValue),
  fullText(cblitedart.CBLDart_IndexType.kCBLDart_IndexTypeFullText),
  vector(cblitedart.CBLDart_IndexType.kCBLDart_IndexTypeVector);

  const CBLDartIndexType(this.value);

  static CBLDartIndexType fromValue(int value) => switch (value) {
        cblitedart.CBLDart_IndexType.kCBLDart_IndexTypeValue => value$,
        cblitedart.CBLDart_IndexType.kCBLDart_IndexTypeFullText => fullText,
        cblitedart.CBLDart_IndexType.kCBLDart_IndexTypeVector => vector,
        _ => throw ArgumentError('Unknown value for CBLDart_IndexType: $value'),
      };

  final int value;
}

final class QueryBindings extends Bindings {
  QueryBindings(super.parent);

  late final _predictiveModelFinalizer = NativeFinalizer(
    cblDart.addresses.CBLDart_PredictiveModel_Delete.cast(),
  );

  Pointer<cblite.CBLQuery> create(
    Pointer<cblite.CBLDatabase> db,
    CBLQueryLanguage language,
    String queryString,
  ) =>
      withGlobalArena(
        () => nativeCallTracePoint(
          TracedNativeCall.queryCreate,
          () => cbl.CBLDatabase_CreateQuery(
            db,
            language.value,
            queryString.makeGlobalFLString(),
            globalErrorPosition,
            globalCBLError,
          ),
        ).checkError(errorSource: queryString),
      );

  void setParameters(Pointer<cblite.CBLQuery> query, cblite.FLDict parameters) {
    cbl.CBLQuery_SetParameters(query, parameters);
  }

  cblite.FLDict parameters(Pointer<cblite.CBLQuery> query) =>
      cbl.CBLQuery_Parameters(query);

  Pointer<cblite.CBLResultSet> execute(Pointer<cblite.CBLQuery> query) =>
      nativeCallTracePoint(
        TracedNativeCall.queryExecute,
        () => cbl.CBLQuery_Execute(query, globalCBLError),
      ).checkError();

  String explain(Pointer<cblite.CBLQuery> query) =>
      cbl.CBLQuery_Explain(query).toDartStringAndRelease()!;

  int columnCount(Pointer<cblite.CBLQuery> query) =>
      cbl.CBLQuery_ColumnCount(query);

  String columnName(Pointer<cblite.CBLQuery> query, int column) =>
      cbl.CBLQuery_ColumnName(query, column).toDartString()!;

  Pointer<cblite.CBLListenerToken> addChangeListener(
    Pointer<cblite.CBLDatabase> db,
    Pointer<cblite.CBLQuery> query,
    cblitedart.CBLDart_AsyncCallback listener,
  ) =>
      cblDart.CBLDart_CBLQuery_AddChangeListener(db, query, listener);

  Pointer<cblite.CBLResultSet> copyCurrentResults(
    Pointer<cblite.CBLQuery> query,
    Pointer<cblite.CBLListenerToken> listenerToken,
  ) =>
      cbl.CBLQuery_CopyCurrentResults(query, listenerToken, globalCBLError)
          .checkError();

  cblitedart.CBLDart_PredictiveModel createPredictiveModel(
    String name,
    cblitedart.CBLDart_PredictiveModel_PredictionSync predictionSync,
    cblitedart.CBLDart_PredictiveModel_PredictionAsync predictionAsync,
    cblitedart.CBLDart_PredictiveModel_Unregistered unregistered,
  ) =>
      runWithSingleFLString(
        name,
        (flName) => cblDart.CBLDart_PredictiveModel_New(
          flName,
          CBLBindings.instance.base.isolateId,
          predictionSync,
          predictionAsync,
          unregistered,
        ),
      );

  void bindCBLDartPredictiveModelToDartObject(
    Finalizable object,
    cblitedart.CBLDart_PredictiveModel model,
  ) =>
      _predictiveModelFinalizer.attach(object, model.cast());

  void unregisterPredictiveModel(String name) =>
      runWithSingleFLString(name, cbl.CBL_UnregisterPredictiveModel);
}

final class ResultSetBindings extends Bindings {
  ResultSetBindings(super.parent);

  bool next(Pointer<cblite.CBLResultSet> resultSet) =>
      cbl.CBLResultSet_Next(resultSet);

  cblite.FLValue valueAtIndex(
    Pointer<cblite.CBLResultSet> resultSet,
    int index,
  ) =>
      cbl.CBLResultSet_ValueAtIndex(resultSet, index);

  cblite.FLValue valueForKey(
    Pointer<cblite.CBLResultSet> resultSet,
    String key,
  ) =>
      runWithSingleFLString(
          key, (flKey) => cbl.CBLResultSet_ValueForKey(resultSet, flKey));

  cblite.FLArray resultArray(Pointer<cblite.CBLResultSet> resultSet) =>
      cbl.CBLResultSet_ResultArray(resultSet);

  cblite.FLDict resultDict(Pointer<cblite.CBLResultSet> resultSet) =>
      cbl.CBLResultSet_ResultDict(resultSet);

  Pointer<cblite.CBLQuery> getQuery(Pointer<cblite.CBLResultSet> resultSet) =>
      cbl.CBLResultSet_GetQuery(resultSet);
}

final class QueryIndexBindings extends Bindings {
  QueryIndexBindings(super.parent);

  Pointer<cblite.CBLIndexUpdater>? beginUpdate(
    Pointer<cblite.CBLQueryIndex> index,
    int limit,
  ) =>
      cbl.CBLQueryIndex_BeginUpdate(
        index,
        limit,
        // TODO(blaugold): Remove reset once bug is fixed.
        // https://github.com/couchbase/couchbase-lite-C/issues/499
        globalCBLError..ref.reset(),
      ).checkError().toNullable();
}

final class IndexUpdaterBindings extends Bindings {
  IndexUpdaterBindings(super.parent);

  cblite.FLValue value(Pointer<cblite.CBLIndexUpdater> updater, int index) =>
      cbl.CBLIndexUpdater_Value(updater, index);

  int count(Pointer<cblite.CBLIndexUpdater> updater) =>
      cbl.CBLIndexUpdater_Count(updater);

  void setVector(
    Pointer<cblite.CBLIndexUpdater> updater,
    int index,
    List<double>? vector,
  ) {
    withGlobalArena(() {
      cbl.CBLIndexUpdater_SetVector(
        updater,
        index,
        switch (vector) {
          final vector? => globalArena<Float>(vector.length)
            ..asTypedList(vector.length).setAll(0, vector),
          null => nullptr,
        },
        vector?.length ?? 0,
        globalCBLError,
      ).checkError();
    });
  }

  void skipVector(
    Pointer<cblite.CBLIndexUpdater> updater,
    int index,
  ) =>
      cbl.CBLIndexUpdater_SkipVector(updater, index);

  void finish(Pointer<cblite.CBLIndexUpdater> updater) =>
      cbl.CBLIndexUpdater_Finish(updater, globalCBLError).checkError();
}
