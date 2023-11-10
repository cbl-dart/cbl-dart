// ignore: lines_longer_than_80_chars
// ignore_for_file: non_constant_identifier_names, avoid_redundant_argument_values, avoid_private_typedef_functions, camel_case_types

import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'async_callback.dart';
import 'base.dart';
import 'bindings.dart';
import 'database.dart';
import 'document.dart';
import 'fleece.dart';
import 'global.dart';
import 'query.dart';
import 'tracing.dart';
import 'utils.dart';

final class CBLScope extends Opaque {}

final class CBLCollection extends Opaque {}

typedef _CBLDatabase_ScopeNames_C = Pointer<FLMutableArray> Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLError> errorOut,
);
typedef _CBLDatabase_ScopeNames = Pointer<FLMutableArray> Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLError> errorOut,
);

typedef _CBLDatabase_Scope_C = Pointer<CBLScope> Function(
  Pointer<CBLDatabase> db,
  FLString scopeName,
  Pointer<CBLError> errorOut,
);
typedef _CBLDatabase_Scope = Pointer<CBLScope> Function(
  Pointer<CBLDatabase> db,
  FLString scopeName,
  Pointer<CBLError> errorOut,
);

typedef _CBLScope_CollectionNames_C = Pointer<FLMutableArray> Function(
  Pointer<CBLScope> scope,
  Pointer<CBLError> errorOut,
);
typedef _CBLScope_CollectionNames = Pointer<FLMutableArray> Function(
  Pointer<CBLScope> scope,
  Pointer<CBLError> errorOut,
);

typedef _CBLScope_Collection_C = Pointer<CBLCollection> Function(
  Pointer<CBLScope> scope,
  FLString collectionName,
  Pointer<CBLError> errorOut,
);
typedef _CBLScope_Collection = Pointer<CBLCollection> Function(
  Pointer<CBLScope> scope,
  FLString collectionName,
  Pointer<CBLError> errorOut,
);

typedef _CBLDatabase_CreateCollection_C = Pointer<CBLCollection> Function(
  Pointer<CBLDatabase> db,
  FLString collectionName,
  FLString scopeName,
  Pointer<CBLError> errorOut,
);
typedef _CBLDatabase_CreateCollection = Pointer<CBLCollection> Function(
  Pointer<CBLDatabase> db,
  FLString collectionName,
  FLString scopeName,
  Pointer<CBLError> errorOut,
);

typedef _CBLDatabase_DeleteCollection_C = Bool Function(
  Pointer<CBLDatabase> db,
  FLString collectionName,
  FLString scopeName,
  Pointer<CBLError> errorOut,
);
typedef _CBLDatabase_DeleteCollection = bool Function(
  Pointer<CBLDatabase> db,
  FLString collectionName,
  FLString scopeName,
  Pointer<CBLError> errorOut,
);

typedef _CBLCollection_Count_C = Uint64 Function(
  Pointer<CBLCollection> collection,
);
typedef _CBLCollection_Count = int Function(
  Pointer<CBLCollection> collection,
);

typedef _CBLCollection_GetDocument_C = Pointer<CBLDocument> Function(
  Pointer<CBLCollection> collection,
  FLString docId,
  Pointer<CBLError> errorOut,
);
typedef _CBLCollection_GetDocument = Pointer<CBLDocument> Function(
  Pointer<CBLCollection> collection,
  FLString docId,
  Pointer<CBLError> errorOut,
);

typedef _CBLCollection_SaveDocumentWithConcurrencyControl_C = Bool Function(
  Pointer<CBLCollection> collection,
  Pointer<CBLMutableDocument> doc,
  Uint8 concurrency,
  Pointer<CBLError> errorOut,
);
typedef _CBLCollection_SaveDocumentWithConcurrencyControl = bool Function(
  Pointer<CBLCollection> collection,
  Pointer<CBLMutableDocument> doc,
  int concurrency,
  Pointer<CBLError> errorOut,
);

typedef _CBLCollection_DeleteDocumentWithConcurrencyControl_C = Bool Function(
  Pointer<CBLCollection> db,
  Pointer<CBLDocument> document,
  Uint8 concurrency,
  Pointer<CBLError> errorOut,
);
typedef _CBLCollection_DeleteDocumentWithConcurrencyControl = bool Function(
  Pointer<CBLCollection> db,
  Pointer<CBLDocument> document,
  int concurrency,
  Pointer<CBLError> errorOut,
);

typedef _CBLCollection_PurgeDocumentByID_C = Bool Function(
  Pointer<CBLCollection> collection,
  FLString docId,
  Pointer<CBLError> errorOut,
);
typedef _CBLCollection_PurgeDocumentByID = bool Function(
  Pointer<CBLCollection> collection,
  FLString docId,
  Pointer<CBLError> errorOut,
);

typedef _CBLCollection_GetDocumentExpiration_C = Int64 Function(
  Pointer<CBLCollection> db,
  FLString docId,
  Pointer<CBLError> errorOut,
);
typedef _CBLCollection_GetDocumentExpiration = int Function(
  Pointer<CBLCollection> db,
  FLString docId,
  Pointer<CBLError> errorOut,
);

typedef _CBLCollection_SetDocumentExpiration_C = Bool Function(
  Pointer<CBLCollection> db,
  FLString docId,
  Int64 expiration,
  Pointer<CBLError> errorOut,
);
typedef _CBLCollection_SetDocumentExpiration = bool Function(
  Pointer<CBLCollection> db,
  FLString docId,
  int expiration,
  Pointer<CBLError> errorOut,
);

typedef _CBLCollection_GetIndexNames = Pointer<FLArray> Function(
  Pointer<CBLCollection> collection,
);

typedef _CBLDart_CBLCollection_CreateIndex_C = Bool Function(
  Pointer<CBLCollection> collection,
  FLString name,
  _CBLDart_CBLIndexSpec indexSpec,
  Pointer<CBLError> errorOut,
);
typedef _CBLDart_CBLCollection_CreateIndex = bool Function(
  Pointer<CBLCollection> collection,
  FLString name,
  _CBLDart_CBLIndexSpec indexSpec,
  Pointer<CBLError> errorOut,
);

typedef _CBLCollection_DeleteIndex_C = Bool Function(
  Pointer<CBLCollection> collection,
  FLString name,
  Pointer<CBLError> errorOut,
);
typedef _CBLCollection_DeleteIndex = bool Function(
  Pointer<CBLCollection> collection,
  FLString name,
  Pointer<CBLError> errorOut,
);

class CBLIndexSpec {
  CBLIndexSpec({
    required this.type,
    required this.expressionLanguage,
    required this.expressions,
    this.ignoreAccents,
    this.language,
  });

  final CBLIndexType type;
  final CBLQueryLanguage expressionLanguage;
  final String expressions;
  final bool? ignoreAccents;
  final String? language;
}

enum CBLIndexType {
  value,
  fullText,
}

extension on CBLIndexType {
  int toInt() => CBLIndexType.values.indexOf(this);
}

final class _CBLDart_CBLIndexSpec extends Struct {
  @Uint8()
  // ignore: unused_field
  external int _type;

  @Uint32()
  // ignore: unused_field
  external int _expressionLanguage;

  external FLString expressions;

  @Bool()
  external bool ignoreAccents;

  external FLString language;
}

// ignore: camel_case_extensions
extension on _CBLDart_CBLIndexSpec {
  set type(CBLIndexType value) => _type = value.toInt();
  set expressionLanguage(CBLQueryLanguage value) =>
      _expressionLanguage = value.toInt();
}

typedef _CBLDart_CBLCollection_AddDocumentChangeListener_C = Void Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLCollection> collection,
  FLString docId,
  Pointer<CBLDartAsyncCallback> listener,
);
typedef _CBLDart_CBLCollection_AddDocumentChangeListener = void Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLCollection> collection,
  FLString docId,
  Pointer<CBLDartAsyncCallback> listener,
);

typedef _CBLDart_CBLCollection_AddChangeListener_C = Void Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLCollection> collection,
  Pointer<CBLDartAsyncCallback> listener,
);
typedef _CBLDart_CBLCollection_AddChangeListener = void Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLCollection> collection,
  Pointer<CBLDartAsyncCallback> listener,
);

class CollectionChangeCallbackMessage {
  CollectionChangeCallbackMessage(this.documentIds);

  CollectionChangeCallbackMessage.fromArguments(List<Object?> message)
      : this(message.cast<Uint8List>().map(utf8.decode).toList());

  final List<String> documentIds;
}

class CollectionBindings extends Bindings {
  CollectionBindings(super.parent) {
    _database_scopeNames = libs.cbl
        .lookupFunction<_CBLDatabase_ScopeNames_C, _CBLDatabase_ScopeNames>(
      'CBLDatabase_ScopeNames',
      isLeaf: useIsLeaf,
    );
    _database_scope =
        libs.cbl.lookupFunction<_CBLDatabase_Scope_C, _CBLDatabase_Scope>(
      'CBLDatabase_Scope',
      isLeaf: useIsLeaf,
    );
    _scope_collectionNames = libs.cbl
        .lookupFunction<_CBLScope_CollectionNames_C, _CBLScope_CollectionNames>(
      'CBLScope_CollectionNames',
      isLeaf: useIsLeaf,
    );
    _scope_collection =
        libs.cbl.lookupFunction<_CBLScope_Collection_C, _CBLScope_Collection>(
      'CBLScope_Collection',
      isLeaf: useIsLeaf,
    );
    _database_createCollection = libs.cbl.lookupFunction<
        _CBLDatabase_CreateCollection_C, _CBLDatabase_CreateCollection>(
      'CBLDatabase_CreateCollection',
      isLeaf: useIsLeaf,
    );
    _database_deleteCollection = libs.cbl.lookupFunction<
        _CBLDatabase_DeleteCollection_C, _CBLDatabase_DeleteCollection>(
      'CBLDatabase_DeleteCollection',
      isLeaf: useIsLeaf,
    );
    _count =
        libs.cbl.lookupFunction<_CBLCollection_Count_C, _CBLCollection_Count>(
      'CBLCollection_Count',
      isLeaf: useIsLeaf,
    );
    _getDocument = libs.cbl.lookupFunction<_CBLCollection_GetDocument_C,
        _CBLCollection_GetDocument>(
      'CBLCollection_GetDocument',
      isLeaf: useIsLeaf,
    );
    _saveDocumentWithConcurrencyControl = libs.cbl.lookupFunction<
        _CBLCollection_SaveDocumentWithConcurrencyControl_C,
        _CBLCollection_SaveDocumentWithConcurrencyControl>(
      'CBLCollection_SaveDocumentWithConcurrencyControl',
      isLeaf: useIsLeaf,
    );
    _deleteDocumentWithConcurrencyControl = libs.cbl.lookupFunction<
        _CBLCollection_DeleteDocumentWithConcurrencyControl_C,
        _CBLCollection_DeleteDocumentWithConcurrencyControl>(
      'CBLCollection_DeleteDocumentWithConcurrencyControl',
      isLeaf: useIsLeaf,
    );
    _purgeDocumentByID = libs.cbl.lookupFunction<
        _CBLCollection_PurgeDocumentByID_C, _CBLCollection_PurgeDocumentByID>(
      'CBLCollection_PurgeDocumentByID',
      isLeaf: useIsLeaf,
    );
    _getDocumentExpiration = libs.cbl.lookupFunction<
        _CBLCollection_GetDocumentExpiration_C,
        _CBLCollection_GetDocumentExpiration>(
      'CBLCollection_GetDocumentExpiration',
      isLeaf: useIsLeaf,
    );
    _setDocumentExpiration = libs.cbl.lookupFunction<
        _CBLCollection_SetDocumentExpiration_C,
        _CBLCollection_SetDocumentExpiration>(
      'CBLCollection_SetDocumentExpiration',
      isLeaf: useIsLeaf,
    );
    _indexNames = libs.cbl.lookupFunction<_CBLCollection_GetIndexNames,
        _CBLCollection_GetIndexNames>(
      'CBLCollection_GetIndexNames',
      isLeaf: useIsLeaf,
    );
    _createIndex = libs.cblDart.lookupFunction<
        _CBLDart_CBLCollection_CreateIndex_C,
        _CBLDart_CBLCollection_CreateIndex>(
      'CBLDart_CBLCollection_CreateIndex',
      isLeaf: useIsLeaf,
    );
    _deleteIndex = libs.cbl.lookupFunction<_CBLCollection_DeleteIndex_C,
        _CBLCollection_DeleteIndex>(
      'CBLCollection_DeleteIndex',
      isLeaf: useIsLeaf,
    );
    _addDocumentChangeListener = libs.cblDart.lookupFunction<
        _CBLDart_CBLCollection_AddDocumentChangeListener_C,
        _CBLDart_CBLCollection_AddDocumentChangeListener>(
      'CBLDart_CBLCollection_AddDocumentChangeListener',
      isLeaf: useIsLeaf,
    );
    _addChangeListener = libs.cblDart.lookupFunction<
        _CBLDart_CBLCollection_AddChangeListener_C,
        _CBLDart_CBLCollection_AddChangeListener>(
      'CBLDart_CBLCollection_AddChangeListener',
      isLeaf: useIsLeaf,
    );
  }

  late final _CBLDatabase_ScopeNames _database_scopeNames;
  late final _CBLDatabase_Scope _database_scope;
  late final _CBLScope_CollectionNames _scope_collectionNames;
  late final _CBLScope_Collection _scope_collection;
  late final _CBLDatabase_CreateCollection _database_createCollection;
  late final _CBLDatabase_DeleteCollection _database_deleteCollection;
  late final _CBLCollection_Count _count;
  late final _CBLCollection_GetDocument _getDocument;
  late final _CBLCollection_SaveDocumentWithConcurrencyControl
      _saveDocumentWithConcurrencyControl;
  late final _CBLCollection_DeleteDocumentWithConcurrencyControl
      _deleteDocumentWithConcurrencyControl;
  late final _CBLCollection_PurgeDocumentByID _purgeDocumentByID;
  late final _CBLCollection_GetDocumentExpiration _getDocumentExpiration;
  late final _CBLCollection_SetDocumentExpiration _setDocumentExpiration;
  late final _CBLCollection_GetIndexNames _indexNames;
  late final _CBLDart_CBLCollection_CreateIndex _createIndex;
  late final _CBLCollection_DeleteIndex _deleteIndex;
  late final _CBLDart_CBLCollection_AddDocumentChangeListener
      _addDocumentChangeListener;
  late final _CBLDart_CBLCollection_AddChangeListener _addChangeListener;

  Pointer<FLMutableArray> databaseScopeNames(Pointer<CBLDatabase> db) =>
      _database_scopeNames(db, globalCBLError).checkCBLError();

  Pointer<CBLScope>? databaseScope(Pointer<CBLDatabase> db, String scopeName) =>
      runWithSingleFLString(
        scopeName,
        (flScopeName) => _database_scope(
          db,
          flScopeName,
          // TODO(blaugold): Remove reset once bug is fixed.
          // https://github.com/couchbase/couchbase-lite-C/issues/499
          globalCBLError..ref.reset(),
        ).checkCBLError().toNullable(),
      );

  Pointer<FLMutableArray> scopeCollectionNames(Pointer<CBLScope> scope) =>
      _scope_collectionNames(scope, globalCBLError).checkCBLError();

  Pointer<CBLCollection>? scopeCollection(
    Pointer<CBLScope> scope,
    String collectionName,
  ) =>
      runWithSingleFLString(
        collectionName,
        (flCollectionName) => _scope_collection(
          scope,
          flCollectionName,
          // TODO(blaugold): Remove reset once bug is fixed.
          // https://github.com/couchbase/couchbase-lite-C/issues/499
          globalCBLError..ref.reset(),
        ).checkCBLError().toNullable(),
      );

  Pointer<CBLCollection> databaseCreateCollection(
    Pointer<CBLDatabase> db,
    String collectionName,
    String scopeName,
  ) =>
      withGlobalArena(() => _database_createCollection(
            db,
            collectionName.toFLString(),
            scopeName.toFLString(),
            globalCBLError,
          ).checkCBLError());

  void databaseDeleteCollection(
    Pointer<CBLDatabase> db,
    String collectionName,
    String scopeName,
  ) =>
      withGlobalArena(() => _database_deleteCollection(
            db,
            collectionName.toFLString(),
            scopeName.toFLString(),
            globalCBLError,
          ).checkCBLError());

  int count(Pointer<CBLCollection> collection) => _count(collection);

  Pointer<CBLDocument>? getDocument(
    Pointer<CBLCollection> collection,
    String docId,
  ) =>
      runWithSingleFLString(
        docId,
        (flDocId) => nativeCallTracePoint(
          TracedNativeCall.collectionGetDocument,
          () => _getDocument(collection, flDocId, globalCBLError),
        ).checkCBLError().toNullable(),
      );

  void saveDocumentWithConcurrencyControl(
    Pointer<CBLCollection> collection,
    Pointer<CBLMutableDocument> doc,
    CBLConcurrencyControl concurrencyControl,
  ) {
    final concurrencyControlInt = concurrencyControl.toInt();
    nativeCallTracePoint(
      TracedNativeCall.collectionSaveDocument,
      () => _saveDocumentWithConcurrencyControl(
        collection,
        doc,
        concurrencyControlInt,
        globalCBLError,
      ),
    ).checkCBLError();
  }

  bool deleteDocumentWithConcurrencyControl(
    Pointer<CBLCollection> collection,
    Pointer<CBLDocument> document,
    CBLConcurrencyControl concurrencyControl,
  ) {
    final concurrencyControlInt = concurrencyControl.toInt();
    return nativeCallTracePoint(
      TracedNativeCall.collectionDeleteDocument,
      () => _deleteDocumentWithConcurrencyControl(
        collection,
        document,
        concurrencyControlInt,
        globalCBLError,
      ),
    ).checkCBLError();
  }

  bool purgeDocumentByID(Pointer<CBLCollection> db, String docId) =>
      runWithSingleFLString(
        docId,
        (flDocId) =>
            _purgeDocumentByID(db, flDocId, globalCBLError).checkCBLError(),
      );

  DateTime? getDocumentExpiration(
    Pointer<CBLCollection> collection,
    String docId,
  ) =>
      runWithSingleFLString(docId, (flDocId) {
        final result =
            _getDocumentExpiration(collection, flDocId, globalCBLError);

        if (result == -1) {
          checkCBLError();
        }

        return result == 0 ? null : DateTime.fromMillisecondsSinceEpoch(result);
      });

  void setDocumentExpiration(
    Pointer<CBLCollection> collection,
    String docId,
    DateTime? expiration,
  ) =>
      runWithSingleFLString(docId, (flDocId) {
        _setDocumentExpiration(
          collection,
          flDocId,
          expiration?.millisecondsSinceEpoch ?? 0,
          globalCBLError,
        ).checkCBLError();
      });

  Pointer<FLArray> indexNames(Pointer<CBLCollection> collection) =>
      _indexNames(collection);

  void createIndex(
    Pointer<CBLCollection> collection,
    String name,
    CBLIndexSpec spec,
  ) {
    withGlobalArena(() {
      _createIndex(
        collection,
        name.toFLString(),
        _createIndexSpec(spec).ref,
        globalCBLError,
      ).checkCBLError();
    });
  }

  void deleteIndex(Pointer<CBLCollection> collection, String name) {
    runWithSingleFLString(name, (flName) {
      _deleteIndex(collection, flName, globalCBLError).checkCBLError();
    });
  }

  Pointer<_CBLDart_CBLIndexSpec> _createIndexSpec(CBLIndexSpec spec) {
    final result = globalArena<_CBLDart_CBLIndexSpec>();

    result.ref
      ..type = spec.type
      ..expressionLanguage = spec.expressionLanguage
      ..expressions = spec.expressions.toFLString()
      ..ignoreAccents = spec.ignoreAccents ?? false
      ..language = spec.language.toFLString();

    return result;
  }

  void addDocumentChangeListener(
    Pointer<CBLDatabase> db,
    Pointer<CBLCollection> collection,
    String docId,
    Pointer<CBLDartAsyncCallback> listener,
  ) {
    runWithSingleFLString(docId, (flDocId) {
      _addDocumentChangeListener(db, collection, flDocId, listener);
    });
  }

  void addChangeListener(
    Pointer<CBLDatabase> db,
    Pointer<CBLCollection> collection,
    Pointer<CBLDartAsyncCallback> listener,
  ) {
    _addChangeListener(db, collection, listener);
  }
}
