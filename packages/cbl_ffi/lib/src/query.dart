import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'async_callback.dart';
import 'base.dart';
import 'bindings.dart';
import 'database.dart';
import 'fleece.dart';
import 'global.dart';
import 'utils.dart';

enum CBLQueryLanguage {
  json,
  n1ql,
}

extension CBLQueryLanguageExt on CBLQueryLanguage {
  int toInt() => CBLQueryLanguage.values.indexOf(this);
}

class CBLQuery extends Opaque {}

typedef _CBLDart_CBLDatabase_CreateQuery_C = Pointer<CBLQuery> Function(
  Pointer<CBLDatabase> db,
  Uint32 language,
  FLString queryString,
  Pointer<Int32> errorPosOut,
  Pointer<CBLError> errorOut,
);
typedef _CBLDart_CBLDatabase_CreateQuery = Pointer<CBLQuery> Function(
  Pointer<CBLDatabase> db,
  int language,
  FLString queryString,
  Pointer<Int32> errorPosOut,
  Pointer<CBLError> errorOut,
);

typedef _CBLQuery_SetParameters_C = Void Function(
  Pointer<CBLQuery> query,
  Pointer<FLDict> parameters,
);
typedef _CBLQuery_SetParameters = void Function(
  Pointer<CBLQuery> query,
  Pointer<FLDict> parameters,
);

typedef _CBLQuery_Parameters = Pointer<FLDict> Function(
  Pointer<CBLQuery> query,
);

typedef _CBLQuery_Execute = Pointer<CBLResultSet> Function(
  Pointer<CBLQuery> query,
  Pointer<CBLError> errorOut,
);

typedef _CBLDart_CBLQuery_Explain_C = FLStringResult Function(
  Pointer<CBLQuery> query,
);
typedef _CBLDart_CBLQuery_Explain = FLStringResult Function(
  Pointer<CBLQuery> query,
);

typedef _CBLQuery_ColumnCount_C = Uint32 Function(Pointer<CBLQuery> query);
typedef _CBLQuery_ColumnCount = int Function(Pointer<CBLQuery> query);

typedef _CBLDart_CBLQuery_ColumnName_C = FLString Function(
  Pointer<CBLQuery> query,
  Uint32 columnIndex,
);
typedef _CBLDart_CBLQuery_ColumnName = FLString Function(
  Pointer<CBLQuery> query,
  int columnIndex,
);

typedef _CBLDart_CBLQuery_AddChangeListener_C = Pointer<CBLListenerToken>
    Function(
  Pointer<CBLQuery> query,
  Pointer<CBLDartAsyncCallback> listener,
);
typedef _CBLDart_CBLQuery_AddChangeListener = Pointer<CBLListenerToken>
    Function(
  Pointer<CBLQuery> query,
  Pointer<CBLDartAsyncCallback> listener,
);
typedef _CBLQuery_CopyCurrentResults = Pointer<CBLResultSet> Function(
  Pointer<CBLQuery> query,
  Pointer<CBLListenerToken> listenerToken,
  Pointer<CBLError> errorOut,
);

class QueryBindings extends Bindings {
  QueryBindings(Bindings parent) : super(parent) {
    _createQuery = libs.cblDart.lookupFunction<
        _CBLDart_CBLDatabase_CreateQuery_C, _CBLDart_CBLDatabase_CreateQuery>(
      'CBLDart_CBLDatabase_CreateQuery',
    );
    _setParameters = libs.cbl
        .lookupFunction<_CBLQuery_SetParameters_C, _CBLQuery_SetParameters>(
      'CBLQuery_SetParameters',
    );
    _parameters =
        libs.cbl.lookupFunction<_CBLQuery_Parameters, _CBLQuery_Parameters>(
      'CBLQuery_Parameters',
    );
    _execute = libs.cbl.lookupFunction<_CBLQuery_Execute, _CBLQuery_Execute>(
      'CBLQuery_Execute',
    );
    _explain = libs.cblDart
        .lookupFunction<_CBLDart_CBLQuery_Explain_C, _CBLDart_CBLQuery_Explain>(
      'CBLDart_CBLQuery_Explain',
    );
    _columnCount =
        libs.cbl.lookupFunction<_CBLQuery_ColumnCount_C, _CBLQuery_ColumnCount>(
      'CBLQuery_ColumnCount',
    );
    _columnName = libs.cblDart.lookupFunction<_CBLDart_CBLQuery_ColumnName_C,
        _CBLDart_CBLQuery_ColumnName>(
      'CBLDart_CBLQuery_ColumnName',
    );
    _addChangeListener = libs.cblDart.lookupFunction<
        _CBLDart_CBLQuery_AddChangeListener_C,
        _CBLDart_CBLQuery_AddChangeListener>(
      'CBLDart_CBLQuery_AddChangeListener',
    );
    _copyCurrentResults = libs.cbl.lookupFunction<_CBLQuery_CopyCurrentResults,
        _CBLQuery_CopyCurrentResults>(
      'CBLQuery_CopyCurrentResults',
    );
  }

  late final _CBLDart_CBLDatabase_CreateQuery _createQuery;
  late final _CBLQuery_SetParameters _setParameters;
  late final _CBLQuery_Parameters _parameters;
  late final _CBLQuery_Execute _execute;
  late final _CBLDart_CBLQuery_Explain _explain;
  late final _CBLQuery_ColumnCount _columnCount;
  late final _CBLDart_CBLQuery_ColumnName _columnName;
  late final _CBLDart_CBLQuery_AddChangeListener _addChangeListener;
  late final _CBLQuery_CopyCurrentResults _copyCurrentResults;

  Pointer<CBLQuery> create(
    Pointer<CBLDatabase> db,
    CBLQueryLanguage language,
    String queryString,
  ) =>
      withZoneArena(() => _createQuery(
            db,
            language.toInt(),
            queryString.toFLStringInArena().ref,
            globalErrorPosition,
            globalCBLError,
          ).checkCBLError(errorSource: queryString));

  void setParameters(Pointer<CBLQuery> query, Pointer<FLDict> parameters) {
    _setParameters(query, parameters);
  }

  Pointer<FLDict> parameters(Pointer<CBLQuery> query) => _parameters(query);

  Pointer<CBLResultSet> execute(Pointer<CBLQuery> query) =>
      _execute(query, globalCBLError).checkCBLError();

  String explain(Pointer<CBLQuery> query) =>
      _explain(query).toDartStringAndRelease()!;

  int columnCount(Pointer<CBLQuery> query) => _columnCount(query);

  String columnName(Pointer<CBLQuery> query, int column) =>
      _columnName(query, column).toDartString()!;

  Pointer<CBLListenerToken> addChangeListener(
    Pointer<CBLQuery> query,
    Pointer<CBLDartAsyncCallback> listener,
  ) =>
      _addChangeListener(query, listener);

  Pointer<CBLResultSet> copyCurrentResults(
    Pointer<CBLQuery> query,
    Pointer<CBLListenerToken> listenerToken,
  ) =>
      _copyCurrentResults(query, listenerToken, globalCBLError).checkCBLError();
}

class CBLResultSet extends Opaque {}

typedef _CBLResultSet_Next_C = Bool Function(Pointer<CBLResultSet> resultSet);
typedef _CBLResultSet_Next = bool Function(Pointer<CBLResultSet> resultSet);

typedef _CBLResultSet_ValueAtIndex_C = Pointer<FLValue> Function(
  Pointer<CBLResultSet> resultSet,
  Uint32 index,
);
typedef _CBLResultSet_ValueAtIndex = Pointer<FLValue> Function(
  Pointer<CBLResultSet> resultSet,
  int index,
);

typedef _CBLDart_CBLResultSet_ValueForKey = Pointer<FLValue> Function(
  Pointer<CBLResultSet> resultSet,
  FLString key,
);

typedef _CBLResultSet_ResultArray = Pointer<FLArray> Function(
  Pointer<CBLResultSet> resultSet,
);

typedef _CBLResultSet_ResultDict = Pointer<FLDict> Function(
  Pointer<CBLResultSet> resultSet,
);

typedef _CBLResultSet_GetQuery = Pointer<CBLQuery> Function(
  Pointer<CBLResultSet> resultSet,
);

class ResultSetBindings extends Bindings {
  ResultSetBindings(Bindings parent) : super(parent) {
    _next = libs.cbl.lookupFunction<_CBLResultSet_Next_C, _CBLResultSet_Next>(
      'CBLResultSet_Next',
    );
    _valueAtIndex = libs.cbl.lookupFunction<_CBLResultSet_ValueAtIndex_C,
        _CBLResultSet_ValueAtIndex>(
      'CBLResultSet_ValueAtIndex',
    );
    _valueForKey = libs.cblDart.lookupFunction<
        _CBLDart_CBLResultSet_ValueForKey, _CBLDart_CBLResultSet_ValueForKey>(
      'CBLDart_CBLResultSet_ValueForKey',
    );
    _resultArray = libs.cbl
        .lookupFunction<_CBLResultSet_ResultArray, _CBLResultSet_ResultArray>(
      'CBLResultSet_ResultArray',
    );
    _resultDict = libs.cbl
        .lookupFunction<_CBLResultSet_ResultDict, _CBLResultSet_ResultDict>(
      'CBLResultSet_ResultDict',
    );
    _getQuery =
        libs.cbl.lookupFunction<_CBLResultSet_GetQuery, _CBLResultSet_GetQuery>(
      'CBLResultSet_GetQuery',
    );
  }

  late final _CBLResultSet_Next _next;
  late final _CBLResultSet_ValueAtIndex _valueAtIndex;
  late final _CBLDart_CBLResultSet_ValueForKey _valueForKey;
  late final _CBLResultSet_ResultArray _resultArray;
  late final _CBLResultSet_ResultDict _resultDict;
  late final _CBLResultSet_GetQuery _getQuery;

  bool next(Pointer<CBLResultSet> resultSet) => _next(resultSet);

  Pointer<FLValue> valueAtIndex(Pointer<CBLResultSet> resultSet, int index) =>
      _valueAtIndex(resultSet, index);

  Pointer<FLValue> valueForKey(
    Pointer<CBLResultSet> resultSet,
    String key,
  ) =>
      withZoneArena(() => _valueForKey(
            resultSet,
            key.toFLStringInArena().ref,
          ));

  Pointer<FLArray> resultArray(Pointer<CBLResultSet> resultSet) =>
      _resultArray(resultSet);

  Pointer<FLDict> resultDict(Pointer<CBLResultSet> resultSet) =>
      _resultDict(resultSet);

  Pointer<CBLQuery> getQuery(Pointer<CBLResultSet> resultSet) =>
      _getQuery(resultSet);
}
