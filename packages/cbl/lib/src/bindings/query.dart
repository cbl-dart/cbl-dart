import 'dart:convert';
import 'dart:ffi';

import '../support/isolate.dart';
import 'base.dart';
import 'cblite.dart' as cblite;
import 'cblitedart.dart' as cblitedart;
import 'fleece.dart';
import 'global.dart';
import 'slice.dart';
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

final class QueryBindings {
  static final _predictiveModelFinalizer = NativeFinalizer(
    cblitedart.addresses.CBLDart_PredictiveModel_Delete.cast(),
  );

  static Pointer<cblite.CBLQuery> create(
    Pointer<cblite.CBLDatabase> db,
    CBLQueryLanguage language,
    String queryString,
  ) {
    final encoded = utf8.encode(queryString);
    return nativeCallTracePoint(TracedNativeCall.queryCreate, () {
      final capturedEncoded = encoded;
      return cblitedart.CBLDart_CBLDatabase_CreateQuery(
        db,
        language.value,
        capturedEncoded.address.cast(),
        capturedEncoded.length,
        globalErrorPosition,
        globalCBLError,
      );
    }).checkError(errorSource: queryString);
  }

  static void setParameters(
    Pointer<cblite.CBLQuery> query,
    cblite.FLDict parameters,
  ) {
    cblite.CBLQuery_SetParameters(query, parameters);
  }

  static cblite.FLDict parameters(Pointer<cblite.CBLQuery> query) =>
      cblite.CBLQuery_Parameters(query);

  static Pointer<cblite.CBLResultSet> execute(Pointer<cblite.CBLQuery> query) =>
      nativeCallTracePoint(
        TracedNativeCall.queryExecute,
        () => cblite.CBLQuery_Execute(query, globalCBLError),
      ).checkError();

  static String explain(Pointer<cblite.CBLQuery> query) =>
      cblite.CBLQuery_Explain(query).toDartStringAndRelease()!;

  static int columnCount(Pointer<cblite.CBLQuery> query) =>
      cblite.CBLQuery_ColumnCount(query);

  static String columnName(Pointer<cblite.CBLQuery> query, int column) =>
      cblite.CBLQuery_ColumnName(query, column).toDartString()!;

  static Pointer<cblite.CBLListenerToken> addChangeListener(
    Pointer<cblite.CBLDatabase> db,
    Pointer<cblite.CBLQuery> query,
    cblitedart.CBLDart_AsyncCallback listener,
  ) => cblitedart.CBLDart_CBLQuery_AddChangeListener(db, query, listener);

  static Pointer<cblite.CBLResultSet> copyCurrentResults(
    Pointer<cblite.CBLQuery> query,
    Pointer<cblite.CBLListenerToken> listenerToken,
  ) => cblite.CBLQuery_CopyCurrentResults(
    query,
    listenerToken,
    globalCBLError,
  ).checkError();

  static cblitedart.CBLDart_PredictiveModel createPredictiveModel(
    String name,
    cblitedart.CBLDart_PredictiveModel_PredictionSync predictionSync,
    cblitedart.CBLDart_PredictiveModel_PredictionAsync predictionAsync,
    cblitedart.CBLDart_PredictiveModel_Unregistered unregistered,
  ) {
    ensureInitializedForCurrentIsolate();
    final encoded = utf8.encode(name);
    return cblitedart.CBLDart_PredictiveModel_New(
      encoded.address.cast(),
      encoded.length,
      BaseBindings.isolateId,
      predictionSync,
      predictionAsync,
      unregistered,
    );
  }

  static void bindCBLDartPredictiveModelToDartObject(
    Finalizable object,
    cblitedart.CBLDart_PredictiveModel model,
  ) => _predictiveModelFinalizer.attach(object, model.cast());

  static void unregisterPredictiveModel(String name) {
    ensureInitializedForCurrentIsolate();
    final nameSlice = SliceResult.fromString(name);
    cblitedart.CBLDart_CBL_UnregisterPredictiveModel(
      nameSlice.buf,
      nameSlice.size,
    );
  }
}

final class ResultSetBindings {
  static bool next(Pointer<cblite.CBLResultSet> resultSet) =>
      cblite.CBLResultSet_Next(resultSet);

  static cblite.FLValue valueAtIndex(
    Pointer<cblite.CBLResultSet> resultSet,
    int index,
  ) => cblite.CBLResultSet_ValueAtIndex(resultSet, index);

  static cblite.FLValue valueForKey(
    Pointer<cblite.CBLResultSet> resultSet,
    String key,
  ) {
    final encoded = utf8.encode(key);
    return cblitedart.CBLDart_CBLResultSet_ValueForKey(
      resultSet,
      encoded.address.cast(),
      encoded.length,
    );
  }

  static cblite.FLArray resultArray(Pointer<cblite.CBLResultSet> resultSet) =>
      cblite.CBLResultSet_ResultArray(resultSet);

  static cblite.FLDict resultDict(Pointer<cblite.CBLResultSet> resultSet) =>
      cblite.CBLResultSet_ResultDict(resultSet);

  static Pointer<cblite.CBLQuery> getQuery(
    Pointer<cblite.CBLResultSet> resultSet,
  ) => cblite.CBLResultSet_GetQuery(resultSet);
}

final class QueryIndexBindings {
  static Pointer<cblite.CBLIndexUpdater>? beginUpdate(
    Pointer<cblite.CBLQueryIndex> index,
    int limit,
  ) => cblite.CBLQueryIndex_BeginUpdate(
    index,
    limit,
    // TODO(blaugold): Remove reset once bug is fixed.
    // https://github.com/couchbase/couchbase-lite-C/issues/499
    globalCBLError..ref.reset(),
  ).checkError().toNullable();
}

final class IndexUpdaterBindings {
  static cblite.FLValue value(
    Pointer<cblite.CBLIndexUpdater> updater,
    int index,
  ) => cblite.CBLIndexUpdater_Value(updater, index);

  static int count(Pointer<cblite.CBLIndexUpdater> updater) =>
      cblite.CBLIndexUpdater_Count(updater);

  static void setVector(
    Pointer<cblite.CBLIndexUpdater> updater,
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

  static void skipVector(Pointer<cblite.CBLIndexUpdater> updater, int index) =>
      cblite.CBLIndexUpdater_SkipVector(updater, index);

  static void finish(Pointer<cblite.CBLIndexUpdater> updater) =>
      cblite.CBLIndexUpdater_Finish(updater, globalCBLError).checkError();
}
