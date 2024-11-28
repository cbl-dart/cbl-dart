import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'base.dart';
import 'bindings.dart';
import 'cblite.dart' as cblite;
import 'cblitedart.dart' as cblitedart;
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

  final CBLIndexType type;
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

enum CBLIndexType {
  value,
  fullText,
  vector,
}

extension on CBLIndexType {
  int toInt() => CBLIndexType.values.indexOf(this);
}

final class CollectionChangeCallbackMessage {
  CollectionChangeCallbackMessage(this.documentIds);

  CollectionChangeCallbackMessage.fromArguments(List<Object?> message)
      : this(message.cast<Uint8List>().map(utf8.decode).toList());

  final List<String> documentIds;
}

final class CollectionBindings extends Bindings {
  CollectionBindings(super.parent);

  cblite.FLMutableArray databaseScopeNames(Pointer<cblite.CBLDatabase> db) =>
      cbl.CBLDatabase_ScopeNames(db, globalCBLError).checkCBLError();

  Pointer<cblite.CBLScope>? databaseScope(
          Pointer<cblite.CBLDatabase> db, String scopeName) =>
      runWithSingleFLString(
        scopeName,
        (flScopeName) => cbl.CBLDatabase_Scope(
          db,
          flScopeName,
          // TODO(blaugold): Remove reset once bug is fixed.
          // https://github.com/couchbase/couchbase-lite-C/issues/499
          globalCBLError..ref.reset(),
        ).checkCBLError().toNullable(),
      );

  cblite.FLMutableArray scopeCollectionNames(Pointer<cblite.CBLScope> scope) =>
      cbl.CBLScope_CollectionNames(scope, globalCBLError).checkCBLError();

  Pointer<cblite.CBLCollection>? scopeCollection(
    Pointer<cblite.CBLScope> scope,
    String collectionName,
  ) =>
      runWithSingleFLString(
        collectionName,
        (flCollectionName) => cbl.CBLScope_Collection(
          scope,
          flCollectionName,
          // TODO(blaugold): Remove reset once bug is fixed.
          // https://github.com/couchbase/couchbase-lite-C/issues/499
          globalCBLError..ref.reset(),
        ).checkCBLError().toNullable(),
      );

  Pointer<cblite.CBLCollection> databaseCreateCollection(
    Pointer<cblite.CBLDatabase> db,
    String collectionName,
    String scopeName,
  ) =>
      withGlobalArena(() => cbl.CBLDatabase_CreateCollection(
            db,
            collectionName.toFLString(),
            scopeName.toFLString(),
            globalCBLError,
          ).checkCBLError());

  void databaseDeleteCollection(
    Pointer<cblite.CBLDatabase> db,
    String collectionName,
    String scopeName,
  ) =>
      withGlobalArena(() => cbl.CBLDatabase_DeleteCollection(
            db,
            collectionName.toFLString(),
            scopeName.toFLString(),
            globalCBLError,
          ).checkCBLError());

  int count(Pointer<cblite.CBLCollection> collection) =>
      cbl.CBLCollection_Count(collection);

  Pointer<cblite.CBLDocument>? getDocument(
    Pointer<cblite.CBLCollection> collection,
    String docId,
  ) =>
      runWithSingleFLString(
        docId,
        (flDocId) => nativeCallTracePoint(
          TracedNativeCall.collectionGetDocument,
          () => cbl.CBLCollection_GetDocument(
              collection, flDocId, globalCBLError),
        ).checkCBLError().toNullable(),
      );

  void saveDocumentWithConcurrencyControl(
    Pointer<cblite.CBLCollection> collection,
    Pointer<cblite.CBLDocument> doc,
    CBLConcurrencyControl concurrencyControl,
  ) {
    final concurrencyControlInt = concurrencyControl.toInt();
    nativeCallTracePoint(
      TracedNativeCall.collectionSaveDocument,
      () => cbl.CBLCollection_SaveDocumentWithConcurrencyControl(
        collection,
        doc,
        concurrencyControlInt,
        globalCBLError,
      ),
    ).checkCBLError();
  }

  bool deleteDocumentWithConcurrencyControl(
    Pointer<cblite.CBLCollection> collection,
    Pointer<cblite.CBLDocument> document,
    CBLConcurrencyControl concurrencyControl,
  ) {
    final concurrencyControlInt = concurrencyControl.toInt();
    return nativeCallTracePoint(
      TracedNativeCall.collectionDeleteDocument,
      () => cbl.CBLCollection_DeleteDocumentWithConcurrencyControl(
        collection,
        document,
        concurrencyControlInt,
        globalCBLError,
      ),
    ).checkCBLError();
  }

  bool purgeDocumentByID(Pointer<cblite.CBLCollection> db, String docId) =>
      runWithSingleFLString(
        docId,
        (flDocId) =>
            cbl.CBLCollection_PurgeDocumentByID(db, flDocId, globalCBLError)
                .checkCBLError(),
      );

  DateTime? getDocumentExpiration(
    Pointer<cblite.CBLCollection> collection,
    String docId,
  ) =>
      runWithSingleFLString(docId, (flDocId) {
        final result = cbl.CBLCollection_GetDocumentExpiration(
            collection, flDocId, globalCBLError);

        if (result == -1) {
          checkCBLError();
        }

        return result == 0 ? null : DateTime.fromMillisecondsSinceEpoch(result);
      });

  void setDocumentExpiration(
    Pointer<cblite.CBLCollection> collection,
    String docId,
    DateTime? expiration,
  ) =>
      runWithSingleFLString(docId, (flDocId) {
        cbl.CBLCollection_SetDocumentExpiration(
          collection,
          flDocId,
          expiration?.millisecondsSinceEpoch ?? 0,
          globalCBLError,
        ).checkCBLError();
      });

  cblite.FLArray indexNames(Pointer<cblite.CBLCollection> collection) =>
      cbl.CBLCollection_GetIndexNames(collection, globalCBLError)
          .checkCBLError();

  void createIndex(
    Pointer<cblite.CBLCollection> collection,
    String name,
    CBLIndexSpec spec,
  ) {
    withGlobalArena(() {
      cblDart.CBLDart_CBLCollection_CreateIndex(
        collection,
        name.toFLString(),
        _createIndexSpec(spec).ref,
        globalCBLError,
      ).checkCBLError();
    });
  }

  void deleteIndex(Pointer<cblite.CBLCollection> collection, String name) {
    runWithSingleFLString(name, (flName) {
      cbl.CBLCollection_DeleteIndex(collection, flName, globalCBLError)
          .checkCBLError();
    });
  }

  Pointer<cblitedart.CBLDart_CBLIndexSpec> _createIndexSpec(CBLIndexSpec spec) {
    final result = globalArena<cblitedart.CBLDart_CBLIndexSpec>();
    final ref = result.ref
      ..typeAsInt = spec.type.toInt()
      ..expressionLanguage = spec.expressionLanguage.toInt()
      ..expressions = spec.expressions.toFLString();

    switch (spec.type) {
      case CBLIndexType.value:
        break;
      case CBLIndexType.fullText:
        ref
          ..ignoreAccents = spec.ignoreAccents!
          ..language = spec.language.toFLString();
      case CBLIndexType.vector:
        final encoding = switch (spec) {
          CBLIndexSpec(:final scalarQuantizerType?) =>
            cbl.CBLVectorEncoding_CreateScalarQuantizer(scalarQuantizerType),
          CBLIndexSpec(
            :final productQuantizerSubQuantizers?,
            :final productQuantizerBits?
          ) =>
            cbl.CBLVectorEncoding_CreateProductQuantizer(
                productQuantizerSubQuantizers, productQuantizerBits),
          _ => cbl.CBLVectorEncoding_CreateNone(),
        };

        globalArena.onReleaseAll(() => cbl.CBLVectorEncoding_Free(encoding));

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
    Pointer<cblite.CBLDatabase> db,
    Pointer<cblite.CBLCollection> collection,
    String docId,
    cblitedart.CBLDart_AsyncCallback listener,
  ) {
    runWithSingleFLString(docId, (flDocId) {
      cblDart.CBLDart_CBLCollection_AddDocumentChangeListener(
          db, collection, flDocId, listener);
    });
  }

  void addChangeListener(
    Pointer<cblite.CBLDatabase> db,
    Pointer<cblite.CBLCollection> collection,
    cblitedart.CBLDart_AsyncCallback listener,
  ) {
    cblDart.CBLDart_CBLCollection_AddChangeListener(db, collection, listener);
  }
}
