import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'base.dart';
import 'cblite.dart' as cblite;
import 'cblitedart.dart' as cblitedart;
import 'database.dart';
import 'global.dart';
import 'query.dart';
import 'tracing.dart';
import 'utils.dart';

export 'cblite.dart' show CBLCollection, CBLScope;

final class CBLIndexSpec {
  CBLIndexSpec({
    required this.type,
    required this.expressionLanguage,
    required this.expressions,
    this.ignoreAccents,
    this.language,
    this.dimensions,
    this.centroids,
    this.lazy,
    this.scalarQuantizerType,
    this.productQuantizerSubQuantizers,
    this.productQuantizerBits,
    this.metric,
    this.minTrainingSize,
    this.maxTrainingSize,
    this.numProbes,
  });

  final CBLDartIndexType type;
  final CBLQueryLanguage expressionLanguage;
  final String expressions;

  // Full text index
  final bool? ignoreAccents;
  final String? language;

  // Vector index
  final int? dimensions;
  final int? centroids;
  final bool? lazy;
  final cblite.DartCBLScalarQuantizerType? scalarQuantizerType;
  final int? productQuantizerSubQuantizers;
  final int? productQuantizerBits;
  final cblite.DartCBLDistanceMetric? metric;
  final int? minTrainingSize;
  final int? maxTrainingSize;
  final int? numProbes;
}

final class CollectionChangeCallbackMessage {
  CollectionChangeCallbackMessage(this.documentIds);

  CollectionChangeCallbackMessage.fromArguments(List<Object?> message)
    : this(message.cast<Uint8List>().map(utf8.decode).toList());

  final List<String> documentIds;
}

final class CollectionBindings {
  static cblite.FLMutableArray databaseScopeNames(
    Pointer<cblite.CBLDatabase> db,
  ) => cblite.CBLDatabase_ScopeNames(db, globalCBLError).checkError();

  static Pointer<cblite.CBLScope>? databaseScope(
    Pointer<cblite.CBLDatabase> db,
    String scopeName,
  ) => runWithSingleFLString(
    scopeName,
    (flScopeName) => cblite.CBLDatabase_Scope(
      db,
      flScopeName,
      // TODO(blaugold): Remove reset once bug is fixed.
      // https://github.com/couchbase/couchbase-lite-C/issues/499
      globalCBLError..ref.reset(),
    ).checkError().toNullable(),
  );

  static cblite.FLMutableArray scopeCollectionNames(
    Pointer<cblite.CBLScope> scope,
  ) => cblite.CBLScope_CollectionNames(scope, globalCBLError).checkError();

  static Pointer<cblite.CBLCollection>? scopeCollection(
    Pointer<cblite.CBLScope> scope,
    String collectionName,
  ) => runWithSingleFLString(
    collectionName,
    (flCollectionName) => cblite.CBLScope_Collection(
      scope,
      flCollectionName,
      // TODO(blaugold): Remove reset once bug is fixed.
      // https://github.com/couchbase/couchbase-lite-C/issues/499
      globalCBLError..ref.reset(),
    ).checkError().toNullable(),
  );

  static Pointer<cblite.CBLCollection> databaseCreateCollection(
    Pointer<cblite.CBLDatabase> db,
    String collectionName,
    String scopeName,
  ) => withGlobalArena(
    () => cblite.CBLDatabase_CreateCollection(
      db,
      collectionName.toFLString(),
      scopeName.toFLString(),
      globalCBLError,
    ).checkError(),
  );

  static void databaseDeleteCollection(
    Pointer<cblite.CBLDatabase> db,
    String collectionName,
    String scopeName,
  ) => withGlobalArena(
    () => cblite.CBLDatabase_DeleteCollection(
      db,
      collectionName.toFLString(),
      scopeName.toFLString(),
      globalCBLError,
    ).checkError(),
  );

  static int count(Pointer<cblite.CBLCollection> collection) =>
      cblite.CBLCollection_Count(collection);

  static Pointer<cblite.CBLDocument>? getDocument(
    Pointer<cblite.CBLCollection> collection,
    String docId,
  ) => runWithSingleFLString(
    docId,
    (flDocId) => nativeCallTracePoint(
      TracedNativeCall.collectionGetDocument,
      () =>
          cblite.CBLCollection_GetDocument(collection, flDocId, globalCBLError),
    ).checkError().toNullable(),
  );

  static void saveDocumentWithConcurrencyControl(
    Pointer<cblite.CBLCollection> collection,
    Pointer<cblite.CBLDocument> doc,
    CBLConcurrencyControl concurrencyControl,
  ) {
    nativeCallTracePoint(
      TracedNativeCall.collectionSaveDocument,
      () => cblite.CBLCollection_SaveDocumentWithConcurrencyControl(
        collection,
        doc,
        concurrencyControl.value,
        globalCBLError,
      ),
    ).checkError();
  }

  static bool deleteDocumentWithConcurrencyControl(
    Pointer<cblite.CBLCollection> collection,
    Pointer<cblite.CBLDocument> document,
    CBLConcurrencyControl concurrencyControl,
  ) => nativeCallTracePoint(
    TracedNativeCall.collectionDeleteDocument,
    () => cblite.CBLCollection_DeleteDocumentWithConcurrencyControl(
      collection,
      document,
      concurrencyControl.value,
      globalCBLError,
    ),
  ).checkError();

  static bool purgeDocumentByID(
    Pointer<cblite.CBLCollection> db,
    String docId,
  ) => runWithSingleFLString(
    docId,
    (flDocId) => cblite.CBLCollection_PurgeDocumentByID(
      db,
      flDocId,
      globalCBLError,
    ).checkError(),
  );

  static DateTime? getDocumentExpiration(
    Pointer<cblite.CBLCollection> collection,
    String docId,
  ) => runWithSingleFLString(docId, (flDocId) {
    final result = cblite.CBLCollection_GetDocumentExpiration(
      collection,
      flDocId,
      globalCBLError,
    );

    if (result == -1) {
      checkError();
    }

    return result == 0 ? null : DateTime.fromMillisecondsSinceEpoch(result);
  });

  static void setDocumentExpiration(
    Pointer<cblite.CBLCollection> collection,
    String docId,
    DateTime? expiration,
  ) => runWithSingleFLString(docId, (flDocId) {
    cblite.CBLCollection_SetDocumentExpiration(
      collection,
      flDocId,
      expiration?.millisecondsSinceEpoch ?? 0,
      globalCBLError,
    ).checkError();
  });

  static cblite.FLArray indexNames(Pointer<cblite.CBLCollection> collection) =>
      cblite.CBLCollection_GetIndexNames(
        collection,
        globalCBLError,
      ).checkError();

  static Pointer<cblite.CBLQueryIndex>? index(
    Pointer<cblite.CBLCollection> collection,
    String name,
  ) => runWithSingleFLString(
    name,
    (flName) => cblite.CBLCollection_GetIndex(
      collection,
      flName,
      globalCBLError,
    ).checkError().toNullable(),
  );

  static void createIndex(
    Pointer<cblite.CBLCollection> collection,
    String name,
    CBLIndexSpec spec,
  ) {
    withGlobalArena(() {
      cblitedart.CBLDart_CBLCollection_CreateIndex(
        collection,
        name.toFLString(),
        _createIndexSpec(spec).ref,
        globalCBLError,
      ).checkError();
    });
  }

  static void deleteIndex(
    Pointer<cblite.CBLCollection> collection,
    String name,
  ) {
    runWithSingleFLString(name, (flName) {
      cblite.CBLCollection_DeleteIndex(
        collection,
        flName,
        globalCBLError,
      ).checkError();
    });
  }

  static Pointer<cblitedart.CBLDart_CBLIndexSpec> _createIndexSpec(
    CBLIndexSpec spec,
  ) {
    final result = globalArena<cblitedart.CBLDart_CBLIndexSpec>();
    final ref = result.ref
      ..type = spec.type.value
      ..expressionLanguage = spec.expressionLanguage.value
      ..expressions = spec.expressions.toFLString();

    switch (spec.type) {
      case CBLDartIndexType.value$:
        break;
      case CBLDartIndexType.fullText:
        ref
          ..ignoreAccents = spec.ignoreAccents!
          ..language = spec.language.toFLString();
      case CBLDartIndexType.vector:
        final encoding = switch (spec) {
          CBLIndexSpec(:final scalarQuantizerType?) =>
            cblite.CBLVectorEncoding_CreateScalarQuantizer(scalarQuantizerType),
          CBLIndexSpec(
            :final productQuantizerSubQuantizers?,
            :final productQuantizerBits?,
          ) =>
            cblite.CBLVectorEncoding_CreateProductQuantizer(
              productQuantizerSubQuantizers,
              productQuantizerBits,
            ),
          _ => cblite.CBLVectorEncoding_CreateNone(),
        };

        globalArena.onReleaseAll(() => cblite.CBLVectorEncoding_Free(encoding));

        ref
          ..dimensions = spec.dimensions!
          ..centroids = spec.centroids!
          ..isLazy = spec.lazy!
          ..encoding = encoding.cast()
          ..metric = spec.metric!
          ..minTrainingSize = spec.minTrainingSize ?? 0
          ..maxTrainingSize = spec.maxTrainingSize ?? 0
          ..numProbes = spec.numProbes ?? 0;
    }

    return result;
  }

  static void addDocumentChangeListener(
    Pointer<cblite.CBLDatabase> db,
    Pointer<cblite.CBLCollection> collection,
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

  static void addChangeListener(
    Pointer<cblite.CBLDatabase> db,
    Pointer<cblite.CBLCollection> collection,
    cblitedart.CBLDart_AsyncCallback listener,
  ) {
    cblitedart.CBLDart_CBLCollection_AddChangeListener(
      db,
      collection,
      listener,
    );
  }
}
