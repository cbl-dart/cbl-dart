import 'dart:ffi';

import 'base.dart';
import 'cblite.dart' as cblite;
import 'cblitedart.dart' as cblitedart;
import 'database.dart';
import 'fleece.dart';
import 'global.dart';
import 'tracing.dart';
import 'utils.dart';

enum CBLQueryLanguage {
  json,
  n1ql,
}

extension CBLQueryLanguageExt on CBLQueryLanguage {
  int toInt() => CBLQueryLanguage.values.indexOf(this);
}

typedef CBLQuery = cblite.CBLQuery;

final class QueryBindings {
  const QueryBindings();

  Pointer<CBLQuery> create(
    Pointer<CBLDatabase> db,
    CBLQueryLanguage language,
    String queryString,
  ) =>
      withGlobalArena(() {
        final flQueryString = queryString.makeGlobalFLString();
        final languageInt = language.toInt();
        return nativeCallTracePoint(
          TracedNativeCall.queryCreate,
          () => cblite.CBLDatabase_CreateQuery(
            db,
            languageInt,
            flQueryString,
            globalErrorPosition,
            globalCBLError,
          ),
        ).checkCBLError(errorSource: queryString);
      });

  void setParameters(Pointer<CBLQuery> query, FLDict parameters) {
    cblite.CBLQuery_SetParameters(query, parameters);
  }

  FLDict parameters(Pointer<CBLQuery> query) =>
      cblite.CBLQuery_Parameters(query);

  Pointer<CBLResultSet> execute(Pointer<CBLQuery> query) =>
      nativeCallTracePoint(
        TracedNativeCall.queryExecute,
        () => cblite.CBLQuery_Execute(query, globalCBLError),
      ).checkCBLError();

  String explain(Pointer<CBLQuery> query) =>
      cblite.CBLQuery_Explain(query).toDartStringAndRelease()!;

  int columnCount(Pointer<CBLQuery> query) =>
      cblite.CBLQuery_ColumnCount(query);

  String columnName(Pointer<CBLQuery> query, int column) =>
      cblite.CBLQuery_ColumnName(query, column).toDartString()!;

  Pointer<CBLListenerToken> addChangeListener(
    Pointer<CBLDatabase> db,
    Pointer<CBLQuery> query,
    cblitedart.CBLDart_AsyncCallback listener,
  ) =>
      cblitedart.CBLDart_CBLQuery_AddChangeListener(db, query, listener);

  Pointer<CBLResultSet> copyCurrentResults(
    Pointer<CBLQuery> query,
    Pointer<CBLListenerToken> listenerToken,
  ) =>
      cblite.CBLQuery_CopyCurrentResults(query, listenerToken, globalCBLError)
          .checkCBLError();
}

typedef CBLResultSet = cblite.CBLResultSet;

final class ResultSetBindings {
  const ResultSetBindings();

  bool next(Pointer<CBLResultSet> resultSet) =>
      cblite.CBLResultSet_Next(resultSet);

  FLValue valueAtIndex(Pointer<CBLResultSet> resultSet, int index) =>
      cblite.CBLResultSet_ValueAtIndex(resultSet, index);

  FLValue valueForKey(
    Pointer<CBLResultSet> resultSet,
    String key,
  ) =>
      runWithSingleFLString(
          key, (flKey) => cblite.CBLResultSet_ValueForKey(resultSet, flKey));

  FLArray resultArray(Pointer<CBLResultSet> resultSet) =>
      cblite.CBLResultSet_ResultArray(resultSet);

  FLDict resultDict(Pointer<CBLResultSet> resultSet) =>
      cblite.CBLResultSet_ResultDict(resultSet);

  Pointer<CBLQuery> getQuery(Pointer<CBLResultSet> resultSet) =>
      cblite.CBLResultSet_GetQuery(resultSet);
}
