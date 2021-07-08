import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'base.dart';
import 'bindings.dart';
import 'database.dart';
import 'fleece.dart';
import 'native_callback.dart';
import 'utils.dart';

enum CBLQueryLanguage {
  json,
  N1QL,
}

extension on CBLQueryLanguage {
  int toInt() => CBLQueryLanguage.values.indexOf(this);
}

class CBLQuery extends Opaque {}

typedef CBLQuery_New_C = Pointer<CBLQuery> Function(
  Pointer<CBLDatabase> db,
  Uint32 language,
  Pointer<Utf8> queryString,
  Pointer<Int32> errorPos,
  Pointer<CBLError> errorOut,
);
typedef CBLQuery_New = Pointer<CBLQuery> Function(
  Pointer<CBLDatabase> db,
  int language,
  Pointer<Utf8> queryString,
  Pointer<Int32> errorPos,
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

typedef CBLDart_CBLQuery_Explain_C = Void Function(
  Pointer<CBLQuery> query,
  Pointer<FLSliceResult> result,
);
typedef CBLDart_CBLQuery_Explain = void Function(
  Pointer<CBLQuery> query,
  Pointer<FLSliceResult> result,
);

typedef CBLQuery_ColumnCount_C = Uint32 Function(Pointer<CBLQuery> query);
typedef CBLQuery_ColumnCount = int Function(Pointer<CBLQuery> query);

typedef CBLDart_CBLQuery_ColumnName_C = Void Function(
  Pointer<CBLQuery> query,
  Uint32 columnIndex,
  Pointer<FLSlice> name,
);
typedef CBLDart_CBLQuery_ColumnName = void Function(
  Pointer<CBLQuery> query,
  int columnIndex,
  Pointer<FLSlice> name,
);

typedef CBLDart_CBLQuery_AddChangeListener_C = Pointer<CBLListenerToken>
    Function(
  Pointer<CBLQuery> query,
  Pointer<Callback> listener,
);
typedef CBLDart_CBLQuery_AddChangeListener = Pointer<CBLListenerToken> Function(
  Pointer<CBLQuery> query,
  Pointer<Callback> listener,
);
typedef CBLQuery_CopyCurrentResults = Pointer<CBLResultSet> Function(
  Pointer<CBLQuery> query,
  Pointer<CBLListenerToken> listenerToken,
  Pointer<CBLError> errorOut,
);

class QueryBindings extends Bindings {
  QueryBindings(Bindings parent) : super(parent) {
    _new = libs.cbl.lookupFunction<CBLQuery_New_C, CBLQuery_New>(
      'CBLQuery_New',
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

  late final CBLQuery_New _new;
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
    return stringTable.autoFree(() {
      return _new(
        db,
        language.toInt(),
        stringTable.cString(queryString),
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
    _explain(query, globalFLSliceResult);
    return globalFLSliceResult.toDartStringAndRelease()!;
  }

  int columnCount(Pointer<CBLQuery> query) {
    return _columnCount(query);
  }

  String columnName(Pointer<CBLQuery> query, int column) {
    _columnName(query, column, globalFLSlice);
    return globalFLSlice.ref.toDartString()!;
  }

  Pointer<CBLListenerToken> addChangeListener(
    Pointer<CBLQuery> query,
    Pointer<Callback> listener,
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

typedef CBLResultSet_ValueForKey = Pointer<FLValue> Function(
  Pointer<CBLResultSet> resultSet,
  Pointer<Utf8> key,
);

typedef CBLResultSet_RowArray = Pointer<FLArray> Function(
  Pointer<CBLResultSet> resultSet,
);

typedef CBLResultSet_RowDict = Pointer<FLDict> Function(
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
    _valueForKey = libs.cbl
        .lookupFunction<CBLResultSet_ValueForKey, CBLResultSet_ValueForKey>(
      'CBLResultSet_ValueForKey',
    );
    _rowArray =
        libs.cbl.lookupFunction<CBLResultSet_RowArray, CBLResultSet_RowArray>(
      'CBLResultSet_RowArray',
    );
    _rowDict =
        libs.cbl.lookupFunction<CBLResultSet_RowDict, CBLResultSet_RowDict>(
      'CBLResultSet_RowDict',
    );
    _getQuery =
        libs.cbl.lookupFunction<CBLResultSet_GetQuery, CBLResultSet_GetQuery>(
      'CBLResultSet_GetQuery',
    );
  }

  late final CBLResultSet_Next _next;
  late final CBLResultSet_ValueAtIndex _valueAtIndex;
  late final CBLResultSet_ValueForKey _valueForKey;
  late final CBLResultSet_RowArray _rowArray;
  late final CBLResultSet_RowDict _rowDict;
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
    return stringTable
        .autoFree(() => _valueForKey(resultSet, stringTable.cString(key)));
  }

  Pointer<FLArray> rowArray(Pointer<CBLResultSet> resultSet) {
    return _rowArray(resultSet);
  }

  Pointer<FLDict> rowDict(Pointer<CBLResultSet> resultSet) {
    return _rowDict(resultSet);
  }

  Pointer<CBLQuery> getQuery(Pointer<CBLResultSet> resultSet) {
    return _getQuery(resultSet);
  }
}
