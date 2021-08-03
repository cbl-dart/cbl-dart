import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'async_callback.dart';
import 'base.dart';
import 'bindings.dart';
import 'database.dart';
import 'fleece.dart';
import 'utils.dart';

enum CBLQueryLanguage {
  json,
  n1ql,
}

extension CBLQueryLanguageExt on CBLQueryLanguage {
  int toInt() => CBLQueryLanguage.values.indexOf(this);
}

class CBLQuery extends Opaque {}

typedef CBLDart_CBLDatabase_CreateQuery_C = Pointer<CBLQuery> Function(
  Pointer<CBLDatabase> db,
  Uint32 language,
  FLString queryString,
  Pointer<Int32> errorPosOut,
  Pointer<CBLError> errorOut,
);
typedef CBLDart_CBLDatabase_CreateQuery = Pointer<CBLQuery> Function(
  Pointer<CBLDatabase> db,
  int language,
  FLString queryString,
  Pointer<Int32> errorPosOut,
  Pointer<CBLError> errorOut,
);

typedef CBLQuery_SetParameters_C = Void Function(
  Pointer<CBLQuery> query,
  Pointer<FLDict> parameters,
);
typedef CBLQuery_SetParameters = void Function(
  Pointer<CBLQuery> query,
  Pointer<FLDict> parameters,
);

typedef CBLQuery_Parameters = Pointer<FLDict> Function(Pointer<CBLQuery> query);

typedef CBLQuery_Execute = Pointer<CBLResultSet> Function(
  Pointer<CBLQuery> query,
  Pointer<CBLError> errorOut,
);

typedef CBLDart_CBLQuery_Explain_C = FLStringResult Function(
  Pointer<CBLQuery> query,
);
typedef CBLDart_CBLQuery_Explain = FLStringResult Function(
  Pointer<CBLQuery> query,
);

typedef CBLQuery_ColumnCount_C = Uint32 Function(Pointer<CBLQuery> query);
typedef CBLQuery_ColumnCount = int Function(Pointer<CBLQuery> query);

typedef CBLDart_CBLQuery_ColumnName_C = FLString Function(
  Pointer<CBLQuery> query,
  Uint32 columnIndex,
);
typedef CBLDart_CBLQuery_ColumnName = FLString Function(
  Pointer<CBLQuery> query,
  int columnIndex,
);

typedef CBLDart_CBLQuery_AddChangeListener_C = Pointer<CBLListenerToken>
    Function(
  Pointer<CBLQuery> query,
  Pointer<CBLDartAsyncCallback> listener,
);
typedef CBLDart_CBLQuery_AddChangeListener = Pointer<CBLListenerToken> Function(
  Pointer<CBLQuery> query,
  Pointer<CBLDartAsyncCallback> listener,
);
typedef CBLQuery_CopyCurrentResults = Pointer<CBLResultSet> Function(
  Pointer<CBLQuery> query,
  Pointer<CBLListenerToken> listenerToken,
  Pointer<CBLError> errorOut,
);

class QueryBindings extends Bindings {
  QueryBindings(Bindings parent) : super(parent) {
    _createQuery = libs.cblDart.lookupFunction<
        CBLDart_CBLDatabase_CreateQuery_C, CBLDart_CBLDatabase_CreateQuery>(
      'CBLDart_CBLDatabase_CreateQuery',
    );
    _setParameters = libs.cbl
        .lookupFunction<CBLQuery_SetParameters_C, CBLQuery_SetParameters>(
      'CBLQuery_SetParameters',
    );
    _parameters =
        libs.cbl.lookupFunction<CBLQuery_Parameters, CBLQuery_Parameters>(
      'CBLQuery_Parameters',
    );
    _execute = libs.cbl.lookupFunction<CBLQuery_Execute, CBLQuery_Execute>(
      'CBLQuery_Execute',
    );
    _explain = libs.cblDart
        .lookupFunction<CBLDart_CBLQuery_Explain_C, CBLDart_CBLQuery_Explain>(
      'CBLDart_CBLQuery_Explain',
    );
    _columnCount =
        libs.cbl.lookupFunction<CBLQuery_ColumnCount_C, CBLQuery_ColumnCount>(
      'CBLQuery_ColumnCount',
    );
    _columnName = libs.cblDart.lookupFunction<CBLDart_CBLQuery_ColumnName_C,
        CBLDart_CBLQuery_ColumnName>(
      'CBLDart_CBLQuery_ColumnName',
    );
    _addChangeListener = libs.cblDart.lookupFunction<
        CBLDart_CBLQuery_AddChangeListener_C,
        CBLDart_CBLQuery_AddChangeListener>(
      'CBLDart_CBLQuery_AddChangeListener',
    );
    _copyCurrentResults = libs.cblDart.lookupFunction<
        CBLQuery_CopyCurrentResults, CBLQuery_CopyCurrentResults>(
      'CBLQuery_CopyCurrentResults',
    );
  }

  late final CBLDart_CBLDatabase_CreateQuery _createQuery;
  late final CBLQuery_SetParameters _setParameters;
  late final CBLQuery_Parameters _parameters;
  late final CBLQuery_Execute _execute;
  late final CBLDart_CBLQuery_Explain _explain;
  late final CBLQuery_ColumnCount _columnCount;
  late final CBLDart_CBLQuery_ColumnName _columnName;
  late final CBLDart_CBLQuery_AddChangeListener _addChangeListener;
  late final CBLQuery_CopyCurrentResults _copyCurrentResults;

  Pointer<CBLQuery> create(
    Pointer<CBLDatabase> db,
    CBLQueryLanguage language,
    String queryString,
  ) {
    return withZoneArena(() {
      return _createQuery(
        db,
        language.toInt(),
        queryString.toFLStringInArena().ref,
        globalErrorPosition,
        globalCBLError,
      ).checkCBLError(errorSource: queryString);
    });
  }

  void setParameters(Pointer<CBLQuery> query, Pointer<FLDict> parameters) {
    _setParameters(query, parameters);
  }

  Pointer<FLDict> parameters(Pointer<CBLQuery> query) {
    return _parameters(query);
  }

  Pointer<CBLResultSet> execute(Pointer<CBLQuery> query) {
    return _execute(query, globalCBLError).checkCBLError();
  }

  String explain(Pointer<CBLQuery> query) {
    return _explain(query).toDartStringAndRelease()!;
  }

  int columnCount(Pointer<CBLQuery> query) {
    return _columnCount(query);
  }

  String columnName(Pointer<CBLQuery> query, int column) {
    return _columnName(query, column).toDartString()!;
  }

  Pointer<CBLListenerToken> addChangeListener(
    Pointer<CBLQuery> query,
    Pointer<CBLDartAsyncCallback> listener,
  ) {
    return _addChangeListener(query, listener);
  }

  Pointer<CBLResultSet> copyCurrentResults(
    Pointer<CBLQuery> query,
    Pointer<CBLListenerToken> listenerToken,
  ) {
    return _copyCurrentResults(query, listenerToken, globalCBLError)
        .checkCBLError();
  }
}

class CBLResultSet extends Opaque {}

typedef CBLResultSet_Next_C = Uint8 Function(Pointer<CBLResultSet> resultSet);
typedef CBLResultSet_Next = int Function(Pointer<CBLResultSet> resultSet);

typedef CBLResultSet_ValueAtIndex_C = Pointer<FLValue> Function(
  Pointer<CBLResultSet> resultSet,
  Uint32 index,
);
typedef CBLResultSet_ValueAtIndex = Pointer<FLValue> Function(
  Pointer<CBLResultSet> resultSet,
  int index,
);

typedef CBLDart_CBLResultSet_ValueForKey = Pointer<FLValue> Function(
  Pointer<CBLResultSet> resultSet,
  FLString key,
);

typedef CBLResultSet_ResultArray = Pointer<FLArray> Function(
  Pointer<CBLResultSet> resultSet,
);

typedef CBLResultSet_ResultDict = Pointer<FLDict> Function(
  Pointer<CBLResultSet> resultSet,
);

typedef CBLResultSet_GetQuery = Pointer<CBLQuery> Function(
  Pointer<CBLResultSet> resultSet,
);

class ResultSetBindings extends Bindings {
  ResultSetBindings(Bindings parent) : super(parent) {
    _next = libs.cbl.lookupFunction<CBLResultSet_Next_C, CBLResultSet_Next>(
      'CBLResultSet_Next',
    );
    _valueAtIndex = libs.cbl
        .lookupFunction<CBLResultSet_ValueAtIndex_C, CBLResultSet_ValueAtIndex>(
      'CBLResultSet_ValueAtIndex',
    );
    _valueForKey = libs.cblDart.lookupFunction<CBLDart_CBLResultSet_ValueForKey,
        CBLDart_CBLResultSet_ValueForKey>(
      'CBLDart_CBLResultSet_ValueForKey',
    );
    _resultArray = libs.cbl
        .lookupFunction<CBLResultSet_ResultArray, CBLResultSet_ResultArray>(
      'CBLResultSet_ResultArray',
    );
    _resultDict = libs.cbl
        .lookupFunction<CBLResultSet_ResultDict, CBLResultSet_ResultDict>(
      'CBLResultSet_ResultDict',
    );
    _getQuery =
        libs.cbl.lookupFunction<CBLResultSet_GetQuery, CBLResultSet_GetQuery>(
      'CBLResultSet_GetQuery',
    );
  }

  late final CBLResultSet_Next _next;
  late final CBLResultSet_ValueAtIndex _valueAtIndex;
  late final CBLDart_CBLResultSet_ValueForKey _valueForKey;
  late final CBLResultSet_ResultArray _resultArray;
  late final CBLResultSet_ResultDict _resultDict;
  late final CBLResultSet_GetQuery _getQuery;

  bool next(Pointer<CBLResultSet> resultSet) {
    return _next(resultSet).toBool();
  }

  Pointer<FLValue> valueAtIndex(Pointer<CBLResultSet> resultSet, int index) {
    return _valueAtIndex(resultSet, index);
  }

  Pointer<FLValue> valueForKey(
    Pointer<CBLResultSet> resultSet,
    String key,
  ) {
    return withZoneArena(() => _valueForKey(
          resultSet,
          key.toFLStringInArena().ref,
        ));
  }

  Pointer<FLArray> resultArray(Pointer<CBLResultSet> resultSet) {
    return _resultArray(resultSet);
  }

  Pointer<FLDict> resultDict(Pointer<CBLResultSet> resultSet) {
    return _resultDict(resultSet);
  }

  Pointer<CBLQuery> getQuery(Pointer<CBLResultSet> resultSet) {
    return _getQuery(resultSet);
  }
}
