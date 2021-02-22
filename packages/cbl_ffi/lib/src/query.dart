import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'base.dart';
import 'fleece.dart';
import 'libraries.dart';

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

typedef CBLQuery_New_C = Pointer<Void> Function(
  Pointer<Void> db,
  Uint32 language,
  Pointer<Utf8> queryString,
  Pointer<Int32> errorPos,
  Pointer<CBLError> error,
);
typedef CBLQuery_New = Pointer<Void> Function(
  Pointer<Void> db,
  int language,
  Pointer<Utf8> queryString,
  Pointer<Int32> errorPos,
  Pointer<CBLError> error,
);

typedef CBLQuery_SetParameters_C = Void Function(
  Pointer<Void> query,
  Pointer<Void> parameters,
);
typedef CBLQuery_SetParameters = void Function(
  Pointer<Void> query,
  Pointer<Void> parameters,
);

typedef CBLQuery_Parameters = Pointer<Void> Function(Pointer<Void> query);

typedef CBLQuery_Execute = Pointer<Void> Function(
  Pointer<Void> query,
  Pointer<CBLError> error,
);

typedef CBLDart_CBLQuery_Explain_C = Void Function(
  Pointer<Void> query,
  Pointer<FLSlice> result,
);
typedef CBLDart_CBLQuery_Explain = void Function(
  Pointer<Void> query,
  Pointer<FLSlice> result,
);

typedef CBLQuery_ColumnCount_C = Uint32 Function(Pointer<Void> query);
typedef CBLQuery_ColumnCount = int Function(Pointer<Void> query);

typedef CBLDart_CBLQuery_ColumnName_C = Void Function(
  Pointer<Void> query,
  Uint32 columnIndex,
  Pointer<FLSlice> name,
);
typedef CBLDart_CBLQuery_ColumnName = void Function(
  Pointer<Void> query,
  int columnIndex,
  Pointer<FLSlice> name,
);

typedef CBLDart_CBLQuery_AddChangeListener_C = Pointer<Void> Function(
  Pointer<Void> query,
  Int64 listener,
);
typedef CBLDart_CBLQuery_AddChangeListener = Pointer<Void> Function(
  Pointer<Void> query,
  int listener,
);
typedef CBLQuery_CopyCurrentResults = Pointer<Void> Function(
  Pointer<Void> query,
  Pointer<Void> listenerToken,
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

typedef CBLResultSet_Next_C = Uint8 Function(Pointer<Void> query);
typedef CBLResultSet_Next = int Function(Pointer<Void> query);

typedef CBLResultSet_ValueAtIndex_C = Pointer<Void> Function(
  Pointer<Void> resultSet,
  Uint32 index,
);
typedef CBLResultSet_ValueAtIndex = Pointer<Void> Function(
  Pointer<Void> resultSet,
  int index,
);
typedef CBLResultSet_ValueForKey = Pointer<Void> Function(
  Pointer<Void> resultSet,
  Pointer<Utf8> key,
);
typedef CBLResultSet_RowArray = Pointer<Void> Function(
  Pointer<Void> resultSet,
);

typedef CBLResultSet_RowDict = Pointer<Void> Function(
  Pointer<Void> resultSet,
);
typedef CBLResultSet_GetQuery = Pointer<Void> Function(
  Pointer<Void> resultSet,
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
