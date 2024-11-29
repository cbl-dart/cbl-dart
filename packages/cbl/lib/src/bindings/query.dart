import 'dart:ffi';

import 'base.dart';
import 'bindings.dart';
import 'cblite.dart' as cblite;
import 'cblitedart.dart' as cblitedart;
import 'fleece.dart';
import 'global.dart';
import 'tracing.dart';
import 'utils.dart';

export 'cblite.dart' show CBLQuery, CBLResultSet;

enum CBLQueryLanguage {
  json,
  n1ql,
}

extension CBLQueryLanguageExt on CBLQueryLanguage {
  int toInt() => CBLQueryLanguage.values.indexOf(this);
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
      withGlobalArena(() {
        final flQueryString = queryString.makeGlobalFLString();
        final languageInt = language.toInt();
        return nativeCallTracePoint(
          TracedNativeCall.queryCreate,
          () => cbl.CBLDatabase_CreateQuery(
            db,
            languageInt,
            flQueryString,
            globalErrorPosition,
            globalCBLError,
          ),
        ).checkCBLError(errorSource: queryString);
      });

  void setParameters(Pointer<cblite.CBLQuery> query, cblite.FLDict parameters) {
    cbl.CBLQuery_SetParameters(query, parameters);
  }

  cblite.FLDict parameters(Pointer<cblite.CBLQuery> query) =>
      cbl.CBLQuery_Parameters(query);

  Pointer<cblite.CBLResultSet> execute(Pointer<cblite.CBLQuery> query) =>
      nativeCallTracePoint(
        TracedNativeCall.queryExecute,
        () => cbl.CBLQuery_Execute(query, globalCBLError),
      ).checkCBLError();

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
          .checkCBLError();

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
      cbl.CBLQueryIndex_BeginUpdate(index, limit, globalCBLError)
          .checkCBLError()
          .toNullable();
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
      ).checkCBLError();
    });
  }

  void skipVector(
    Pointer<cblite.CBLIndexUpdater> updater,
    int index,
  ) =>
      cbl.CBLIndexUpdater_SkipVector(updater, index);

  void finish(Pointer<cblite.CBLIndexUpdater> updater) =>
      cbl.CBLIndexUpdater_Finish(updater, globalCBLError).checkCBLError();
}
