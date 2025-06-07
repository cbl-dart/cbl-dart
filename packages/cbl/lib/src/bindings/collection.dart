import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'base.dart';
import 'bindings.dart';
import 'cblite.dart' as cblite_lib;
import 'cblitedart.dart' as cblitedart_lib;
import 'database.dart';
import 'global.dart';
import 'query.dart';
import 'tracing.dart';
import 'utils.dart';

export 'cblite.dart' show CBLScope, CBLCollection;

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
  final cblite_lib.DartCBLScalarQuantizerType? scalarQuantizerType;
  final int? productQuantizerSubQuantizers;
  final int? productQuantizerBits;
  final cblite_lib.DartCBLDistanceMetric? metric;
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

final class CollectionBindings extends Bindings {
  CollectionBindings(super.libraries);

  cblite_lib.FLMutableArray databaseScopeNames(
    Pointer<cblite_lib.CBLDatabase> db,
  ) => cblite.CBLDatabase_ScopeNames(db, globalCBLError).checkError();

  Pointer<cblite_lib.CBLScope>? databaseScope(
    Pointer<cblite_lib.CBLDatabase> db,
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

  cblite_lib.FLMutableArray scopeCollectionNames(
    Pointer<cblite_lib.CBLScope> scope,
  ) => cblite.CBLScope_CollectionNames(scope, globalCBLError).checkError();

  Pointer<cblite_lib.CBLCollection>? scopeCollection(
    Pointer<cblite_lib.CBLScope> scope,
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

  Pointer<cblite_lib.CBLCollection> databaseCreateCollection(
    Pointer<cblite_lib.CBLDatabase> db,
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

  void databaseDeleteCollection(
    Pointer<cblite_lib.CBLDatabase> db,
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

  int count(Pointer<cblite_lib.CBLCollection> collection) =>
      cblite.CBLCollection_Count(collection);

  Pointer<cblite_lib.CBLDocument>? getDocument(
    Pointer<cblite_lib.CBLCollection> collection,
    String docId,
  ) => runWithSingleFLString(
    docId,
    (flDocId) => nativeCallTracePoint(
      TracedNativeCall.collectionGetDocument,
      () =>
          cblite.CBLCollection_GetDocument(collection, flDocId, globalCBLError),
    ).checkError().toNullable(),
  );

  void saveDocumentWithConcurrencyControl(
    Pointer<cblite_lib.CBLCollection> collection,
    Pointer<cblite_lib.CBLDocument> doc,
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

  bool deleteDocumentWithConcurrencyControl(
    Pointer<cblite_lib.CBLCollection> collection,
    Pointer<cblite_lib.CBLDocument> document,
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

  bool purgeDocumentByID(Pointer<cblite_lib.CBLCollection> db, String docId) =>
      runWithSingleFLString(
        docId,
        (flDocId) => cblite.CBLCollection_PurgeDocumentByID(
          db,
          flDocId,
          globalCBLError,
        ).checkError(),
      );

  DateTime? getDocumentExpiration(
    Pointer<cblite_lib.CBLCollection> collection,
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

  void setDocumentExpiration(
    Pointer<cblite_lib.CBLCollection> collection,
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

  cblite_lib.FLArray indexNames(Pointer<cblite_lib.CBLCollection> collection) =>
      cblite.CBLCollection_GetIndexNames(
        collection,
        globalCBLError,
      ).checkError();

  Pointer<cblite_lib.CBLQueryIndex>? index(
    Pointer<cblite_lib.CBLCollection> collection,
    String name,
  ) => runWithSingleFLString(
    name,
    (flName) => cblite.CBLCollection_GetIndex(
      collection,
      flName,
      globalCBLError,
    ).checkError().toNullable(),
  );

  void createIndex(
    Pointer<cblite_lib.CBLCollection> collection,
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

  void deleteIndex(Pointer<cblite_lib.CBLCollection> collection, String name) {
    runWithSingleFLString(name, (flName) {
      cblite.CBLCollection_DeleteIndex(
        collection,
        flName,
        globalCBLError,
      ).checkError();
    });
  }

  Pointer<cblitedart_lib.CBLDart_CBLIndexSpec> _createIndexSpec(
    CBLIndexSpec spec,
  ) {
    final result = globalArena<cblitedart_lib.CBLDart_CBLIndexSpec>();
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

  void addDocumentChangeListener(
    Pointer<cblite_lib.CBLDatabase> db,
    Pointer<cblite_lib.CBLCollection> collection,
    String docId,
    cblitedart_lib.CBLDart_AsyncCallback listener,
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
    Pointer<cblite_lib.CBLDatabase> db,
    Pointer<cblite_lib.CBLCollection> collection,
    cblitedart_lib.CBLDart_AsyncCallback listener,
  ) {
    cblitedart.CBLDart_CBLCollection_AddChangeListener(
      db,
      collection,
      listener,
    );
  }
}
