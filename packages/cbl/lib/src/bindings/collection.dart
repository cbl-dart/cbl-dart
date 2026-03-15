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
  ) {
    final encoded = utf8.encode(scopeName);
    return cblitedart.CBLDart_CBLDatabase_Scope(
      db,
      encoded.address.cast(),
      encoded.length,
      // TODO(blaugold): Remove reset once bug is fixed.
      // https://github.com/couchbase/couchbase-lite-C/issues/499
      globalCBLError..ref.reset(),
    ).checkError().toNullable();
  }

  static cblite.FLMutableArray scopeCollectionNames(
    Pointer<cblite.CBLScope> scope,
  ) => cblite.CBLScope_CollectionNames(scope, globalCBLError).checkError();

  static Pointer<cblite.CBLCollection>? scopeCollection(
    Pointer<cblite.CBLScope> scope,
    String collectionName,
  ) {
    final encoded = utf8.encode(collectionName);
    return cblitedart.CBLDart_CBLScope_Collection(
      scope,
      encoded.address.cast(),
      encoded.length,
      // TODO(blaugold): Remove reset once bug is fixed.
      // https://github.com/couchbase/couchbase-lite-C/issues/499
      globalCBLError..ref.reset(),
    ).checkError().toNullable();
  }

  static Pointer<cblite.CBLCollection> databaseCreateCollection(
    Pointer<cblite.CBLDatabase> db,
    String collectionName,
    String scopeName,
  ) {
    final colName = utf8.encode(collectionName);
    final scopeNm = utf8.encode(scopeName);
    return cblitedart.CBLDart_CBLDatabase_CreateCollection(
      db,
      colName.address.cast(),
      colName.length,
      scopeNm.address.cast(),
      scopeNm.length,
      globalCBLError,
    ).checkError();
  }

  static void databaseDeleteCollection(
    Pointer<cblite.CBLDatabase> db,
    String collectionName,
    String scopeName,
  ) {
    final colName = utf8.encode(collectionName);
    final scopeNm = utf8.encode(scopeName);
    cblitedart.CBLDart_CBLDatabase_DeleteCollection(
      db,
      colName.address.cast(),
      colName.length,
      scopeNm.address.cast(),
      scopeNm.length,
      globalCBLError,
    ).checkError();
  }

  static int count(Pointer<cblite.CBLCollection> collection) =>
      cblite.CBLCollection_Count(collection);

  static Pointer<cblite.CBLDocument>? getDocument(
    Pointer<cblite.CBLCollection> collection,
    String docId,
  ) {
    final encoded = utf8.encode(docId);
    return nativeCallTracePoint(TracedNativeCall.collectionGetDocument, () {
      final capturedEncoded = encoded;
      return cblitedart.CBLDart_CBLCollection_GetDocument(
        collection,
        capturedEncoded.address.cast(),
        capturedEncoded.length,
        globalCBLError,
      );
    }).checkError().toNullable();
  }

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
  ) {
    final encoded = utf8.encode(docId);
    return cblitedart.CBLDart_CBLCollection_PurgeDocumentByID(
      db,
      encoded.address.cast(),
      encoded.length,
      globalCBLError,
    ).checkError();
  }

  static DateTime? getDocumentExpiration(
    Pointer<cblite.CBLCollection> collection,
    String docId,
  ) {
    final encoded = utf8.encode(docId);
    final result = cblitedart.CBLDart_CBLCollection_GetDocumentExpiration(
      collection,
      encoded.address.cast(),
      encoded.length,
      globalCBLError,
    );

    if (result == -1) {
      checkError();
    }

    return result == 0 ? null : DateTime.fromMillisecondsSinceEpoch(result);
  }

  static void setDocumentExpiration(
    Pointer<cblite.CBLCollection> collection,
    String docId,
    DateTime? expiration,
  ) {
    final encoded = utf8.encode(docId);
    cblitedart.CBLDart_CBLCollection_SetDocumentExpiration(
      collection,
      encoded.address.cast(),
      encoded.length,
      expiration?.millisecondsSinceEpoch ?? 0,
      globalCBLError,
    ).checkError();
  }

  static cblite.FLArray indexNames(Pointer<cblite.CBLCollection> collection) =>
      cblite.CBLCollection_GetIndexNames(
        collection,
        globalCBLError,
      ).checkError();

  static Pointer<cblite.CBLQueryIndex>? index(
    Pointer<cblite.CBLCollection> collection,
    String name,
  ) {
    final encoded = utf8.encode(name);
    return cblitedart.CBLDart_CBLCollection_GetIndex(
      collection,
      encoded.address.cast(),
      encoded.length,
      globalCBLError,
    ).checkError().toNullable();
  }

  static void createIndex(
    Pointer<cblite.CBLCollection> collection,
    String name,
    CBLIndexSpec spec,
  ) {
    withGlobalArena(() {
      final (:buf, :size) = encodeStringToArena(name, globalArena);
      cblitedart.CBLDart_CBLCollection_CreateIndex(
        collection,
        buf.cast(),
        size,
        _createIndexSpec(spec).ref,
        globalCBLError,
      ).checkError();
    });
  }

  static void deleteIndex(
    Pointer<cblite.CBLCollection> collection,
    String name,
  ) {
    final encoded = utf8.encode(name);
    cblitedart.CBLDart_CBLCollection_DeleteIndex(
      collection,
      encoded.address.cast(),
      encoded.length,
      globalCBLError,
    ).checkError();
  }

  static Pointer<cblitedart.CBLDart_CBLIndexSpec> _createIndexSpec(
    CBLIndexSpec spec,
  ) {
    final result = globalArena<cblitedart.CBLDart_CBLIndexSpec>();
    final (:buf, :size) = encodeStringToArena(spec.expressions, globalArena);
    final ref = result.ref
      ..type = spec.type.value
      ..expressionLanguage = spec.expressionLanguage.value
      ..expressionsBuf = buf.cast()
      ..expressionsSize = size;

    switch (spec.type) {
      case CBLDartIndexType.value$:
        break;
      case CBLDartIndexType.fullText:
        ref.ignoreAccents = spec.ignoreAccents!;
        if (spec.language != null) {
          final (:buf, :size) = encodeStringToArena(
            spec.language!,
            globalArena,
          );
          ref
            ..languageBuf = buf.cast()
            ..languageSize = size;
        } else {
          ref
            ..languageBuf = nullptr
            ..languageSize = 0;
        }
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
    final encoded = utf8.encode(docId);
    cblitedart.CBLDart_CBLCollection_AddDocumentChangeListener(
      db,
      collection,
      encoded.address.cast(),
      encoded.length,
      listener,
    );
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
