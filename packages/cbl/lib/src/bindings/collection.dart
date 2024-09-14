import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'base.dart';
import 'cblite.dart' as cblite;
import 'cblitedart.dart' as cblitedart;
import 'database.dart';
import 'document.dart';
import 'fleece.dart';
import 'global.dart';
import 'query.dart';
import 'tracing.dart';
import 'utils.dart';

typedef CBLScope = cblite.CBLScope;

typedef CBLCollection = cblite.CBLCollection;

final class CBLIndexSpec {
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

// ignore: camel_case_extensions
extension on cblitedart.CBLDart_CBLIndexSpec {
  set dartType(CBLIndexType value) => type = value.toInt();
  set dartExpressionLanguage(CBLQueryLanguage value) =>
      expressionLanguage = value.toInt();
}

final class CollectionChangeCallbackMessage {
  CollectionChangeCallbackMessage(this.documentIds);

  CollectionChangeCallbackMessage.fromArguments(List<Object?> message)
      : this(message.cast<Uint8List>().map(utf8.decode).toList());

  final List<String> documentIds;
}

final class CollectionBindings {
  const CollectionBindings();

  FLMutableArray databaseScopeNames(Pointer<CBLDatabase> db) =>
      cblite.CBLDatabase_ScopeNames(db, globalCBLError).checkCBLError();

  Pointer<CBLScope>? databaseScope(Pointer<CBLDatabase> db, String scopeName) =>
      runWithSingleFLString(
        scopeName,
        (flScopeName) => cblite.CBLDatabase_Scope(
          db,
          flScopeName,
          // TODO(blaugold): Remove reset once bug is fixed.
          // https://github.com/couchbase/couchbase-lite-C/issues/499
          globalCBLError..ref.reset(),
        ).checkCBLError().toNullable(),
      );

  FLMutableArray scopeCollectionNames(Pointer<CBLScope> scope) =>
      cblite.CBLScope_CollectionNames(scope, globalCBLError).checkCBLError();

  Pointer<CBLCollection>? scopeCollection(
    Pointer<CBLScope> scope,
    String collectionName,
  ) =>
      runWithSingleFLString(
        collectionName,
        (flCollectionName) => cblite.CBLScope_Collection(
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
      withGlobalArena(() => cblite.CBLDatabase_CreateCollection(
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
      withGlobalArena(() => cblite.CBLDatabase_DeleteCollection(
            db,
            collectionName.toFLString(),
            scopeName.toFLString(),
            globalCBLError,
          ).checkCBLError());

  int count(Pointer<CBLCollection> collection) =>
      cblite.CBLCollection_Count(collection);

  Pointer<CBLDocument>? getDocument(
    Pointer<CBLCollection> collection,
    String docId,
  ) =>
      runWithSingleFLString(
        docId,
        (flDocId) => nativeCallTracePoint(
          TracedNativeCall.collectionGetDocument,
          () => cblite.CBLCollection_GetDocument(
            collection,
            flDocId,
            globalCBLError,
          ),
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
      () => cblite.CBLCollection_SaveDocumentWithConcurrencyControl(
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
      () => cblite.CBLCollection_DeleteDocumentWithConcurrencyControl(
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
            cblite.CBLCollection_PurgeDocumentByID(db, flDocId, globalCBLError)
                .checkCBLError(),
      );

  DateTime? getDocumentExpiration(
    Pointer<CBLCollection> collection,
    String docId,
  ) =>
      runWithSingleFLString(docId, (flDocId) {
        final result = cblite.CBLCollection_GetDocumentExpiration(
          collection,
          flDocId,
          globalCBLError,
        );

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
        cblite.CBLCollection_SetDocumentExpiration(
          collection,
          flDocId,
          expiration?.millisecondsSinceEpoch ?? 0,
          globalCBLError,
        ).checkCBLError();
      });

  FLArray indexNames(Pointer<CBLCollection> collection) =>
      cblite.CBLCollection_GetIndexNames(collection, globalCBLError)
          .checkCBLError();

  void createIndex(
    Pointer<CBLCollection> collection,
    String name,
    CBLIndexSpec spec,
  ) {
    withGlobalArena(() {
      cblitedart.CBLDart_CBLCollection_CreateIndex(
        collection,
        name.toFLString(),
        _createIndexSpec(spec).ref,
        globalCBLError,
      ).checkCBLError();
    });
  }

  void deleteIndex(Pointer<CBLCollection> collection, String name) {
    runWithSingleFLString(name, (flName) {
      cblite.CBLCollection_DeleteIndex(collection, flName, globalCBLError)
          .checkCBLError();
    });
  }

  Pointer<cblitedart.CBLDart_CBLIndexSpec> _createIndexSpec(CBLIndexSpec spec) {
    final result = globalArena<cblitedart.CBLDart_CBLIndexSpec>();

    result.ref
      ..dartType = spec.type
      ..dartExpressionLanguage = spec.expressionLanguage
      ..expressions = spec.expressions.toFLString()
      ..ignoreAccents = spec.ignoreAccents ?? false
      ..language = spec.language.toFLString();

    return result;
  }

  void addDocumentChangeListener(
    Pointer<CBLDatabase> db,
    Pointer<CBLCollection> collection,
    String docId,
    cblitedart.CBLDart_AsyncCallback listener,
  ) {
    runWithSingleFLString(docId, (flDocId) {
      cblitedart.CBLDart_CBLCollection_AddDocumentChangeListener(
        db,
        collection,
        flDocId,
        listener,
      );
    });
  }

  void addChangeListener(
    Pointer<CBLDatabase> db,
    Pointer<CBLCollection> collection,
    cblitedart.CBLDart_AsyncCallback listener,
  ) {
    cblitedart.CBLDart_CBLCollection_AddChangeListener(
      db,
      collection,
      listener,
    );
  }
}
