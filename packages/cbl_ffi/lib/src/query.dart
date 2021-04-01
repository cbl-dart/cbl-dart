import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'base.dart';
import 'database.dart';
import 'fleece.dart';
import 'libraries.dart';
import 'native_callback.dart';

/// A query language
enum QueryLanguage {
  /// [JSON query schema](https://github.com/couchbase/couchbase-lite-core/wiki/JSON-Query-Schema)
  json,

  /// [N1QL syntax](https://docs.couchbase.com/server/6.0/n1ql/n1ql-language-reference/index.html)
  N1QL
}

extension QueryLanguageIntExt on QueryLanguage {
  int toInt() => QueryLanguage.values.indexOf(this);
}

extension IntQueryLanguageExt on int {
  QueryLanguage toQueryLanguage() => QueryLanguage.values[this];
}

class CBLQuery extends Opaque {}

typedef CBLQuery_New_C = Pointer<CBLQuery> Function(
  Pointer<CBLDatabase> db,
  Uint32 language,
  Pointer<Utf8> queryString,
  Pointer<Int32> errorPos,
  Pointer<CBLError> error,
);
typedef CBLQuery_New = Pointer<CBLQuery> Function(
  Pointer<CBLDatabase> db,
  int language,
  Pointer<Utf8> queryString,
  Pointer<Int32> errorPos,
  Pointer<CBLError> error,
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
  Pointer<CBLError> error,
);

typedef CBLDart_CBLQuery_Explain_C = Void Function(
  Pointer<CBLQuery> query,
  Pointer<FLSlice> result,
);
typedef CBLDart_CBLQuery_Explain = void Function(
  Pointer<CBLQuery> query,
  Pointer<FLSlice> result,
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
  Pointer<CBLError> error,
);

class QueryBindings {
  QueryBindings(Libraries libs)
      : globalErrorPosition = malloc(),
        makeNew = libs.cbl.lookupFunction<CBLQuery_New_C, CBLQuery_New>(
          'CBLQuery_New',
        ),
        setParameters = libs.cbl
            .lookupFunction<CBLQuery_SetParameters_C, CBLQuery_SetParameters>(
          'CBLQuery_SetParameters',
        ),
        parameters =
            libs.cbl.lookupFunction<CBLQuery_Parameters, CBLQuery_Parameters>(
          'CBLQuery_Parameters',
        ),
        execute = libs.cbl.lookupFunction<CBLQuery_Execute, CBLQuery_Execute>(
          'CBLQuery_Execute',
        ),
        explain = libs.cblDart.lookupFunction<CBLDart_CBLQuery_Explain_C,
            CBLDart_CBLQuery_Explain>(
          'CBLDart_CBLQuery_Explain',
        ),
        columnCount = libs.cbl
            .lookupFunction<CBLQuery_ColumnCount_C, CBLQuery_ColumnCount>(
          'CBLQuery_ColumnCount',
        ),
        columnName = libs.cblDart.lookupFunction<CBLDart_CBLQuery_ColumnName_C,
            CBLDart_CBLQuery_ColumnName>(
          'CBLDart_CBLQuery_ColumnName',
        ),
        addChangeListener = libs.cblDart.lookupFunction<
            CBLDart_CBLQuery_AddChangeListener_C,
            CBLDart_CBLQuery_AddChangeListener>(
          'CBLDart_CBLQuery_AddChangeListener',
        ),
        copyCurrentResults = libs.cblDart.lookupFunction<
            CBLQuery_CopyCurrentResults, CBLQuery_CopyCurrentResults>(
          'CBLQuery_CopyCurrentResults',
        );
  final Pointer<Int32> globalErrorPosition;

  final CBLQuery_New makeNew;
  final CBLQuery_SetParameters setParameters;
  final CBLQuery_Parameters parameters;
  final CBLQuery_Execute execute;
  final CBLDart_CBLQuery_Explain explain;
  final CBLQuery_ColumnCount columnCount;
  final CBLDart_CBLQuery_ColumnName columnName;
  final CBLDart_CBLQuery_AddChangeListener addChangeListener;
  final CBLQuery_CopyCurrentResults copyCurrentResults;
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

class ResultSetBindings {
  ResultSetBindings(Libraries libs)
      : next = libs.cbl.lookupFunction<CBLResultSet_Next_C, CBLResultSet_Next>(
          'CBLResultSet_Next',
        ),
        valueAtIndex = libs.cbl.lookupFunction<CBLResultSet_ValueAtIndex_C,
            CBLResultSet_ValueAtIndex>(
          'CBLResultSet_ValueAtIndex',
        ),
        valueForKey = libs.cbl
            .lookupFunction<CBLResultSet_ValueForKey, CBLResultSet_ValueForKey>(
          'CBLResultSet_ValueForKey',
        ),
        rowArray = libs.cbl
            .lookupFunction<CBLResultSet_RowArray, CBLResultSet_RowArray>(
          'CBLResultSet_RowArray',
        ),
        rowDict =
            libs.cbl.lookupFunction<CBLResultSet_RowDict, CBLResultSet_RowDict>(
          'CBLResultSet_RowDict',
        ),
        getQuery = libs.cbl
            .lookupFunction<CBLResultSet_GetQuery, CBLResultSet_GetQuery>(
          'CBLResultSet_GetQuery',
        );

  final CBLResultSet_Next next;
  final CBLResultSet_ValueAtIndex valueAtIndex;
  final CBLResultSet_ValueForKey valueForKey;
  final CBLResultSet_RowArray rowArray;
  final CBLResultSet_RowDict rowDict;
  final CBLResultSet_GetQuery getQuery;
}
