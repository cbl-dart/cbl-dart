// AUTO GENERATED FILE, DO NOT EDIT.
//
// ignore_for_file: type=lint, unused_import
import 'dart:ffi' as ffi;

import 'package:cbl/src/bindings/cblite.dart';
import 'package:cbl/src/bindings/cblite.dart' as imp$1;
import './cblite.dart' as native;

class cbliteNative implements cblite {
  const cbliteNative();

  @override
  final addresses = const SymbolAddressesNative();

  @override
  FLSliceResult CBLError_Message(
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLError_Message(
        outError,
      );

  @override
  int CBL_Now() => native.CBL_Now();

  @override
  ffi.Pointer<CBLRefCounted> CBL_Retain(
    ffi.Pointer<CBLRefCounted> arg0,
  ) =>
      native.CBL_Retain(
        arg0,
      );

  @override
  void CBL_Release(
    ffi.Pointer<CBLRefCounted> arg0,
  ) =>
      native.CBL_Release(
        arg0,
      );

  @override
  int CBL_InstanceCount() => native.CBL_InstanceCount();

  @override
  void CBL_DumpInstances() => native.CBL_DumpInstances();

  @override
  void CBLListener_Remove(
    ffi.Pointer<CBLListenerToken> arg0,
  ) =>
      native.CBLListener_Remove(
        arg0,
      );

  @override
  FLSlice get kCBLBlobType => native.kCBLBlobType;

  @override
  FLSlice get kCBLBlobDigestProperty => native.kCBLBlobDigestProperty;

  @override
  FLSlice get kCBLBlobLengthProperty => native.kCBLBlobLengthProperty;

  @override
  FLSlice get kCBLBlobContentTypeProperty => native.kCBLBlobContentTypeProperty;

  @override
  bool FLDict_IsBlob(
    FLDict arg0,
  ) =>
      native.FLDict_IsBlob(
        arg0,
      );

  @override
  ffi.Pointer<CBLBlob> FLDict_GetBlob(
    FLDict blobDict,
  ) =>
      native.FLDict_GetBlob(
        blobDict,
      );

  @override
  int CBLBlob_Length(
    ffi.Pointer<CBLBlob> arg0,
  ) =>
      native.CBLBlob_Length(
        arg0,
      );

  @override
  FLString CBLBlob_ContentType(
    ffi.Pointer<CBLBlob> arg0,
  ) =>
      native.CBLBlob_ContentType(
        arg0,
      );

  @override
  FLString CBLBlob_Digest(
    ffi.Pointer<CBLBlob> arg0,
  ) =>
      native.CBLBlob_Digest(
        arg0,
      );

  @override
  FLDict CBLBlob_Properties(
    ffi.Pointer<CBLBlob> arg0,
  ) =>
      native.CBLBlob_Properties(
        arg0,
      );

  @override
  FLStringResult CBLBlob_CreateJSON(
    ffi.Pointer<CBLBlob> blob,
  ) =>
      native.CBLBlob_CreateJSON(
        blob,
      );

  @override
  FLSliceResult CBLBlob_Content(
    ffi.Pointer<CBLBlob> blob,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLBlob_Content(
        blob,
        outError,
      );

  @override
  ffi.Pointer<CBLBlobReadStream> CBLBlob_OpenContentStream(
    ffi.Pointer<CBLBlob> blob,
    ffi.Pointer<CBLError> arg1,
  ) =>
      native.CBLBlob_OpenContentStream(
        blob,
        arg1,
      );

  @override
  int CBLBlobReader_Read(
    ffi.Pointer<CBLBlobReadStream> stream,
    ffi.Pointer<ffi.Void> dst,
    int maxLength,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLBlobReader_Read(
        stream,
        dst,
        maxLength,
        outError,
      );

  @override
  int CBLBlobReader_Seek(
    ffi.Pointer<CBLBlobReadStream> stream,
    int offset,
    int base,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLBlobReader_Seek(
        stream,
        offset,
        base,
        outError,
      );

  @override
  int CBLBlobReader_Position(
    ffi.Pointer<CBLBlobReadStream> stream,
  ) =>
      native.CBLBlobReader_Position(
        stream,
      );

  @override
  void CBLBlobReader_Close(
    ffi.Pointer<CBLBlobReadStream> arg0,
  ) =>
      native.CBLBlobReader_Close(
        arg0,
      );

  @override
  bool CBLBlob_Equals(
    ffi.Pointer<CBLBlob> blob,
    ffi.Pointer<CBLBlob> anotherBlob,
  ) =>
      native.CBLBlob_Equals(
        blob,
        anotherBlob,
      );

  @override
  ffi.Pointer<CBLBlob> CBLBlob_CreateWithData(
    FLString contentType,
    FLSlice contents,
  ) =>
      native.CBLBlob_CreateWithData(
        contentType,
        contents,
      );

  @override
  ffi.Pointer<CBLBlobWriteStream> CBLBlobWriter_Create(
    ffi.Pointer<CBLDatabase> db,
    ffi.Pointer<CBLError> arg1,
  ) =>
      native.CBLBlobWriter_Create(
        db,
        arg1,
      );

  @override
  void CBLBlobWriter_Close(
    ffi.Pointer<CBLBlobWriteStream> arg0,
  ) =>
      native.CBLBlobWriter_Close(
        arg0,
      );

  @override
  bool CBLBlobWriter_Write(
    ffi.Pointer<CBLBlobWriteStream> writer,
    ffi.Pointer<ffi.Void> data,
    int length,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLBlobWriter_Write(
        writer,
        data,
        length,
        outError,
      );

  @override
  ffi.Pointer<CBLBlob> CBLBlob_CreateWithStream(
    FLString contentType,
    ffi.Pointer<CBLBlobWriteStream> writer,
  ) =>
      native.CBLBlob_CreateWithStream(
        contentType,
        writer,
      );

  @override
  void FLSlot_SetBlob(
    FLSlot slot,
    ffi.Pointer<CBLBlob> blob,
  ) =>
      native.FLSlot_SetBlob(
        slot,
        blob,
      );

  @override
  ffi.Pointer<CBLBlob> CBLDatabase_GetBlob(
    ffi.Pointer<CBLDatabase> db,
    FLDict properties,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_GetBlob(
        db,
        properties,
        outError,
      );

  @override
  bool CBLDatabase_SaveBlob(
    ffi.Pointer<CBLDatabase> db,
    ffi.Pointer<CBLBlob> blob,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_SaveBlob(
        db,
        blob,
        outError,
      );

  @override
  FLSlice get kCBLTypeProperty => native.kCBLTypeProperty;

  @override
  ffi.Pointer<CBLDocument> CBLDatabase_GetDocument(
    ffi.Pointer<CBLDatabase> database,
    FLString docID,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_GetDocument(
        database,
        docID,
        outError,
      );

  @override
  bool CBLDatabase_SaveDocument(
    ffi.Pointer<CBLDatabase> db,
    ffi.Pointer<CBLDocument> doc,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_SaveDocument(
        db,
        doc,
        outError,
      );

  @override
  bool CBLDatabase_SaveDocumentWithConcurrencyControl(
    ffi.Pointer<CBLDatabase> db,
    ffi.Pointer<CBLDocument> doc,
    int concurrency,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_SaveDocumentWithConcurrencyControl(
        db,
        doc,
        concurrency,
        outError,
      );

  @override
  bool CBLDatabase_SaveDocumentWithConflictHandler(
    ffi.Pointer<CBLDatabase> db,
    ffi.Pointer<CBLDocument> doc,
    CBLConflictHandler conflictHandler,
    ffi.Pointer<ffi.Void> context,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_SaveDocumentWithConflictHandler(
        db,
        doc,
        conflictHandler,
        context,
        outError,
      );

  @override
  bool CBLDatabase_DeleteDocument(
    ffi.Pointer<CBLDatabase> db,
    ffi.Pointer<CBLDocument> document,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_DeleteDocument(
        db,
        document,
        outError,
      );

  @override
  bool CBLDatabase_DeleteDocumentWithConcurrencyControl(
    ffi.Pointer<CBLDatabase> db,
    ffi.Pointer<CBLDocument> document,
    int concurrency,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_DeleteDocumentWithConcurrencyControl(
        db,
        document,
        concurrency,
        outError,
      );

  @override
  bool CBLDatabase_PurgeDocument(
    ffi.Pointer<CBLDatabase> db,
    ffi.Pointer<CBLDocument> document,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_PurgeDocument(
        db,
        document,
        outError,
      );

  @override
  bool CBLDatabase_PurgeDocumentByID(
    ffi.Pointer<CBLDatabase> database,
    FLString docID,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_PurgeDocumentByID(
        database,
        docID,
        outError,
      );

  @override
  ffi.Pointer<CBLDocument> CBLDatabase_GetMutableDocument(
    ffi.Pointer<CBLDatabase> database,
    FLString docID,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_GetMutableDocument(
        database,
        docID,
        outError,
      );

  @override
  ffi.Pointer<CBLDocument> CBLDocument_Create() => native.CBLDocument_Create();

  @override
  ffi.Pointer<CBLDocument> CBLDocument_CreateWithID(
    FLString docID,
  ) =>
      native.CBLDocument_CreateWithID(
        docID,
      );

  @override
  ffi.Pointer<CBLDocument> CBLDocument_MutableCopy(
    ffi.Pointer<CBLDocument> original,
  ) =>
      native.CBLDocument_MutableCopy(
        original,
      );

  @override
  FLString CBLDocument_ID(
    ffi.Pointer<CBLDocument> arg0,
  ) =>
      native.CBLDocument_ID(
        arg0,
      );

  @override
  FLString CBLDocument_RevisionID(
    ffi.Pointer<CBLDocument> arg0,
  ) =>
      native.CBLDocument_RevisionID(
        arg0,
      );

  @override
  int CBLDocument_Sequence(
    ffi.Pointer<CBLDocument> arg0,
  ) =>
      native.CBLDocument_Sequence(
        arg0,
      );

  @override
  ffi.Pointer<CBLCollection> CBLDocument_Collection(
    ffi.Pointer<CBLDocument> arg0,
  ) =>
      native.CBLDocument_Collection(
        arg0,
      );

  @override
  FLDict CBLDocument_Properties(
    ffi.Pointer<CBLDocument> arg0,
  ) =>
      native.CBLDocument_Properties(
        arg0,
      );

  @override
  FLMutableDict CBLDocument_MutableProperties(
    ffi.Pointer<CBLDocument> arg0,
  ) =>
      native.CBLDocument_MutableProperties(
        arg0,
      );

  @override
  void CBLDocument_SetProperties(
    ffi.Pointer<CBLDocument> arg0,
    FLMutableDict properties,
  ) =>
      native.CBLDocument_SetProperties(
        arg0,
        properties,
      );

  @override
  FLSliceResult CBLDocument_CreateJSON(
    ffi.Pointer<CBLDocument> arg0,
  ) =>
      native.CBLDocument_CreateJSON(
        arg0,
      );

  @override
  bool CBLDocument_SetJSON(
    ffi.Pointer<CBLDocument> arg0,
    FLSlice json,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDocument_SetJSON(
        arg0,
        json,
        outError,
      );

  @override
  int CBLDatabase_GetDocumentExpiration(
    ffi.Pointer<CBLDatabase> db,
    FLSlice docID,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_GetDocumentExpiration(
        db,
        docID,
        outError,
      );

  @override
  bool CBLDatabase_SetDocumentExpiration(
    ffi.Pointer<CBLDatabase> db,
    FLSlice docID,
    int expiration,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_SetDocumentExpiration(
        db,
        docID,
        expiration,
        outError,
      );

  @override
  ffi.Pointer<CBLListenerToken> CBLDatabase_AddDocumentChangeListener(
    ffi.Pointer<CBLDatabase> db,
    FLString docID,
    CBLDocumentChangeListener listener,
    ffi.Pointer<ffi.Void> context,
  ) =>
      native.CBLDatabase_AddDocumentChangeListener(
        db,
        docID,
        listener,
        context,
      );

  @override
  ffi.Pointer<CBLVectorEncoding> CBLVectorEncoding_CreateNone() =>
      native.CBLVectorEncoding_CreateNone();

  @override
  ffi.Pointer<CBLVectorEncoding> CBLVectorEncoding_CreateScalarQuantizer(
    int type,
  ) =>
      native.CBLVectorEncoding_CreateScalarQuantizer(
        type,
      );

  @override
  ffi.Pointer<CBLVectorEncoding> CBLVectorEncoding_CreateProductQuantizer(
    int subquantizers,
    int bits,
  ) =>
      native.CBLVectorEncoding_CreateProductQuantizer(
        subquantizers,
        bits,
      );

  @override
  void CBLVectorEncoding_Free(
    ffi.Pointer<CBLVectorEncoding> arg0,
  ) =>
      native.CBLVectorEncoding_Free(
        arg0,
      );

  @override
  FLString get kCBLDefaultCollectionName => native.kCBLDefaultCollectionName;

  @override
  FLMutableArray CBLDatabase_ScopeNames(
    ffi.Pointer<CBLDatabase> db,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_ScopeNames(
        db,
        outError,
      );

  @override
  FLMutableArray CBLDatabase_CollectionNames(
    ffi.Pointer<CBLDatabase> db,
    FLString scopeName,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_CollectionNames(
        db,
        scopeName,
        outError,
      );

  @override
  ffi.Pointer<CBLScope> CBLDatabase_Scope(
    ffi.Pointer<CBLDatabase> db,
    FLString scopeName,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_Scope(
        db,
        scopeName,
        outError,
      );

  @override
  ffi.Pointer<CBLCollection> CBLDatabase_Collection(
    ffi.Pointer<CBLDatabase> db,
    FLString collectionName,
    FLString scopeName,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_Collection(
        db,
        collectionName,
        scopeName,
        outError,
      );

  @override
  ffi.Pointer<CBLCollection> CBLDatabase_CreateCollection(
    ffi.Pointer<CBLDatabase> db,
    FLString collectionName,
    FLString scopeName,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_CreateCollection(
        db,
        collectionName,
        scopeName,
        outError,
      );

  @override
  bool CBLDatabase_DeleteCollection(
    ffi.Pointer<CBLDatabase> db,
    FLString collectionName,
    FLString scopeName,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_DeleteCollection(
        db,
        collectionName,
        scopeName,
        outError,
      );

  @override
  ffi.Pointer<CBLScope> CBLDatabase_DefaultScope(
    ffi.Pointer<CBLDatabase> db,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_DefaultScope(
        db,
        outError,
      );

  @override
  ffi.Pointer<CBLCollection> CBLDatabase_DefaultCollection(
    ffi.Pointer<CBLDatabase> db,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_DefaultCollection(
        db,
        outError,
      );

  @override
  ffi.Pointer<CBLScope> CBLCollection_Scope(
    ffi.Pointer<CBLCollection> collection,
  ) =>
      native.CBLCollection_Scope(
        collection,
      );

  @override
  FLString CBLCollection_Name(
    ffi.Pointer<CBLCollection> collection,
  ) =>
      native.CBLCollection_Name(
        collection,
      );

  @override
  FLString CBLCollection_FullName(
    ffi.Pointer<CBLCollection> collection,
  ) =>
      native.CBLCollection_FullName(
        collection,
      );

  @override
  ffi.Pointer<CBLDatabase> CBLCollection_Database(
    ffi.Pointer<CBLCollection> collection,
  ) =>
      native.CBLCollection_Database(
        collection,
      );

  @override
  int CBLCollection_Count(
    ffi.Pointer<CBLCollection> collection,
  ) =>
      native.CBLCollection_Count(
        collection,
      );

  @override
  ffi.Pointer<CBLDocument> CBLCollection_GetDocument(
    ffi.Pointer<CBLCollection> collection,
    FLString docID,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLCollection_GetDocument(
        collection,
        docID,
        outError,
      );

  @override
  bool CBLCollection_SaveDocument(
    ffi.Pointer<CBLCollection> collection,
    ffi.Pointer<CBLDocument> doc,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLCollection_SaveDocument(
        collection,
        doc,
        outError,
      );

  @override
  bool CBLCollection_SaveDocumentWithConcurrencyControl(
    ffi.Pointer<CBLCollection> collection,
    ffi.Pointer<CBLDocument> doc,
    int concurrency,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLCollection_SaveDocumentWithConcurrencyControl(
        collection,
        doc,
        concurrency,
        outError,
      );

  @override
  bool CBLCollection_SaveDocumentWithConflictHandler(
    ffi.Pointer<CBLCollection> collection,
    ffi.Pointer<CBLDocument> doc,
    CBLConflictHandler conflictHandler,
    ffi.Pointer<ffi.Void> context,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLCollection_SaveDocumentWithConflictHandler(
        collection,
        doc,
        conflictHandler,
        context,
        outError,
      );

  @override
  bool CBLCollection_DeleteDocument(
    ffi.Pointer<CBLCollection> collection,
    ffi.Pointer<CBLDocument> document,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLCollection_DeleteDocument(
        collection,
        document,
        outError,
      );

  @override
  bool CBLCollection_DeleteDocumentWithConcurrencyControl(
    ffi.Pointer<CBLCollection> collection,
    ffi.Pointer<CBLDocument> document,
    int concurrency,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLCollection_DeleteDocumentWithConcurrencyControl(
        collection,
        document,
        concurrency,
        outError,
      );

  @override
  bool CBLCollection_PurgeDocument(
    ffi.Pointer<CBLCollection> collection,
    ffi.Pointer<CBLDocument> document,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLCollection_PurgeDocument(
        collection,
        document,
        outError,
      );

  @override
  bool CBLCollection_PurgeDocumentByID(
    ffi.Pointer<CBLCollection> collection,
    FLString docID,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLCollection_PurgeDocumentByID(
        collection,
        docID,
        outError,
      );

  @override
  int CBLCollection_GetDocumentExpiration(
    ffi.Pointer<CBLCollection> collection,
    FLSlice docID,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLCollection_GetDocumentExpiration(
        collection,
        docID,
        outError,
      );

  @override
  bool CBLCollection_SetDocumentExpiration(
    ffi.Pointer<CBLCollection> collection,
    FLSlice docID,
    int expiration,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLCollection_SetDocumentExpiration(
        collection,
        docID,
        expiration,
        outError,
      );

  @override
  ffi.Pointer<CBLDocument> CBLCollection_GetMutableDocument(
    ffi.Pointer<CBLCollection> collection,
    FLString docID,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLCollection_GetMutableDocument(
        collection,
        docID,
        outError,
      );

  @override
  bool CBLCollection_CreateValueIndex(
    ffi.Pointer<CBLCollection> collection,
    FLString name,
    CBLValueIndexConfiguration config,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLCollection_CreateValueIndex(
        collection,
        name,
        config,
        outError,
      );

  @override
  bool CBLCollection_CreateFullTextIndex(
    ffi.Pointer<CBLCollection> collection,
    FLString name,
    CBLFullTextIndexConfiguration config,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLCollection_CreateFullTextIndex(
        collection,
        name,
        config,
        outError,
      );

  @override
  bool CBLCollection_CreateArrayIndex(
    ffi.Pointer<CBLCollection> collection,
    FLString name,
    CBLArrayIndexConfiguration config,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLCollection_CreateArrayIndex(
        collection,
        name,
        config,
        outError,
      );

  @override
  bool CBLCollection_CreateVectorIndex(
    ffi.Pointer<CBLCollection> collection,
    FLString name,
    CBLVectorIndexConfiguration config,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLCollection_CreateVectorIndex(
        collection,
        name,
        config,
        outError,
      );

  @override
  bool CBLCollection_DeleteIndex(
    ffi.Pointer<CBLCollection> collection,
    FLString name,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLCollection_DeleteIndex(
        collection,
        name,
        outError,
      );

  @override
  FLMutableArray CBLCollection_GetIndexNames(
    ffi.Pointer<CBLCollection> collection,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLCollection_GetIndexNames(
        collection,
        outError,
      );

  @override
  ffi.Pointer<CBLQueryIndex> CBLCollection_GetIndex(
    ffi.Pointer<CBLCollection> collection,
    FLString name,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLCollection_GetIndex(
        collection,
        name,
        outError,
      );

  @override
  ffi.Pointer<CBLListenerToken> CBLCollection_AddChangeListener(
    ffi.Pointer<CBLCollection> collection,
    CBLCollectionChangeListener listener,
    ffi.Pointer<ffi.Void> context,
  ) =>
      native.CBLCollection_AddChangeListener(
        collection,
        listener,
        context,
      );

  @override
  ffi.Pointer<CBLListenerToken> CBLCollection_AddDocumentChangeListener(
    ffi.Pointer<CBLCollection> collection,
    FLString docID,
    CBLCollectionDocumentChangeListener listener,
    ffi.Pointer<ffi.Void> context,
  ) =>
      native.CBLCollection_AddDocumentChangeListener(
        collection,
        docID,
        listener,
        context,
      );

  @override
  bool CBL_EnableVectorSearch(
    FLString path,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBL_EnableVectorSearch(
        path,
        outError,
      );

  @override
  CBLDatabaseConfiguration CBLDatabaseConfiguration_Default() =>
      native.CBLDatabaseConfiguration_Default();

  @override
  bool CBLEncryptionKey_FromPassword(
    ffi.Pointer<CBLEncryptionKey> key,
    FLString password,
  ) =>
      native.CBLEncryptionKey_FromPassword(
        key,
        password,
      );

  @override
  bool CBLEncryptionKey_FromPasswordOld(
    ffi.Pointer<CBLEncryptionKey> key,
    FLString password,
  ) =>
      native.CBLEncryptionKey_FromPasswordOld(
        key,
        password,
      );

  @override
  bool CBL_DatabaseExists(
    FLString name,
    FLString inDirectory,
  ) =>
      native.CBL_DatabaseExists(
        name,
        inDirectory,
      );

  @override
  bool CBL_CopyDatabase(
    FLString fromPath,
    FLString toName,
    ffi.Pointer<CBLDatabaseConfiguration> config,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBL_CopyDatabase(
        fromPath,
        toName,
        config,
        outError,
      );

  @override
  bool CBL_DeleteDatabase(
    FLString name,
    FLString inDirectory,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBL_DeleteDatabase(
        name,
        inDirectory,
        outError,
      );

  @override
  ffi.Pointer<CBLDatabase> CBLDatabase_Open(
    FLSlice name,
    ffi.Pointer<CBLDatabaseConfiguration> config,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_Open(
        name,
        config,
        outError,
      );

  @override
  bool CBLDatabase_Close(
    ffi.Pointer<CBLDatabase> arg0,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_Close(
        arg0,
        outError,
      );

  @override
  bool CBLDatabase_Delete(
    ffi.Pointer<CBLDatabase> arg0,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_Delete(
        arg0,
        outError,
      );

  @override
  bool CBLDatabase_BeginTransaction(
    ffi.Pointer<CBLDatabase> arg0,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_BeginTransaction(
        arg0,
        outError,
      );

  @override
  bool CBLDatabase_EndTransaction(
    ffi.Pointer<CBLDatabase> arg0,
    bool commit,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_EndTransaction(
        arg0,
        commit,
        outError,
      );

  @override
  bool CBLDatabase_ChangeEncryptionKey(
    ffi.Pointer<CBLDatabase> arg0,
    ffi.Pointer<CBLEncryptionKey> newKey,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_ChangeEncryptionKey(
        arg0,
        newKey,
        outError,
      );

  @override
  bool CBLDatabase_PerformMaintenance(
    ffi.Pointer<CBLDatabase> db,
    int type,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_PerformMaintenance(
        db,
        type,
        outError,
      );

  @override
  FLString CBLDatabase_Name(
    ffi.Pointer<CBLDatabase> arg0,
  ) =>
      native.CBLDatabase_Name(
        arg0,
      );

  @override
  FLStringResult CBLDatabase_Path(
    ffi.Pointer<CBLDatabase> arg0,
  ) =>
      native.CBLDatabase_Path(
        arg0,
      );

  @override
  int CBLDatabase_Count(
    ffi.Pointer<CBLDatabase> arg0,
  ) =>
      native.CBLDatabase_Count(
        arg0,
      );

  @override
  CBLDatabaseConfiguration CBLDatabase_Config(
    ffi.Pointer<CBLDatabase> arg0,
  ) =>
      native.CBLDatabase_Config(
        arg0,
      );

  @override
  bool CBLDatabase_CreateValueIndex(
    ffi.Pointer<CBLDatabase> db,
    FLString name,
    CBLValueIndexConfiguration config,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_CreateValueIndex(
        db,
        name,
        config,
        outError,
      );

  @override
  bool CBLDatabase_CreateFullTextIndex(
    ffi.Pointer<CBLDatabase> db,
    FLString name,
    CBLFullTextIndexConfiguration config,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_CreateFullTextIndex(
        db,
        name,
        config,
        outError,
      );

  @override
  bool CBLDatabase_DeleteIndex(
    ffi.Pointer<CBLDatabase> db,
    FLString name,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_DeleteIndex(
        db,
        name,
        outError,
      );

  @override
  FLArray CBLDatabase_GetIndexNames(
    ffi.Pointer<CBLDatabase> db,
  ) =>
      native.CBLDatabase_GetIndexNames(
        db,
      );

  @override
  ffi.Pointer<CBLListenerToken> CBLDatabase_AddChangeListener(
    ffi.Pointer<CBLDatabase> db,
    CBLDatabaseChangeListener listener,
    ffi.Pointer<ffi.Void> context,
  ) =>
      native.CBLDatabase_AddChangeListener(
        db,
        listener,
        context,
      );

  @override
  void CBLDatabase_BufferNotifications(
    ffi.Pointer<CBLDatabase> db,
    CBLNotificationsReadyCallback callback,
    ffi.Pointer<ffi.Void> context,
  ) =>
      native.CBLDatabase_BufferNotifications(
        db,
        callback,
        context,
      );

  @override
  void CBLDatabase_SendNotifications(
    ffi.Pointer<CBLDatabase> db,
  ) =>
      native.CBLDatabase_SendNotifications(
        db,
      );

  @override
  FLString get kCBLAuthDefaultCookieName => native.kCBLAuthDefaultCookieName;

  @override
  ffi.Pointer<CBLEndpoint> CBLEndpoint_CreateWithURL(
    FLString url,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLEndpoint_CreateWithURL(
        url,
        outError,
      );

  @override
  ffi.Pointer<CBLEndpoint> CBLEndpoint_CreateWithLocalDB(
    ffi.Pointer<CBLDatabase> arg0,
  ) =>
      native.CBLEndpoint_CreateWithLocalDB(
        arg0,
      );

  @override
  void CBLEndpoint_Free(
    ffi.Pointer<CBLEndpoint> arg0,
  ) =>
      native.CBLEndpoint_Free(
        arg0,
      );

  @override
  ffi.Pointer<CBLAuthenticator> CBLAuth_CreatePassword(
    FLString username,
    FLString password,
  ) =>
      native.CBLAuth_CreatePassword(
        username,
        password,
      );

  @override
  ffi.Pointer<CBLAuthenticator> CBLAuth_CreateSession(
    FLString sessionID,
    FLString cookieName,
  ) =>
      native.CBLAuth_CreateSession(
        sessionID,
        cookieName,
      );

  @override
  void CBLAuth_Free(
    ffi.Pointer<CBLAuthenticator> arg0,
  ) =>
      native.CBLAuth_Free(
        arg0,
      );

  @override
  CBLConflictResolver get CBLDefaultConflictResolver =>
      native.CBLDefaultConflictResolver;

  @override
  void set CBLDefaultConflictResolver(
    CBLConflictResolver value,
  ) =>
      native.CBLDefaultConflictResolver = value;

  @override
  ffi.Pointer<CBLReplicator> CBLReplicator_Create(
    ffi.Pointer<CBLReplicatorConfiguration> arg0,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLReplicator_Create(
        arg0,
        outError,
      );

  @override
  ffi.Pointer<CBLReplicatorConfiguration> CBLReplicator_Config(
    ffi.Pointer<CBLReplicator> arg0,
  ) =>
      native.CBLReplicator_Config(
        arg0,
      );

  @override
  void CBLReplicator_Start(
    ffi.Pointer<CBLReplicator> replicator,
    bool resetCheckpoint,
  ) =>
      native.CBLReplicator_Start(
        replicator,
        resetCheckpoint,
      );

  @override
  void CBLReplicator_Stop(
    ffi.Pointer<CBLReplicator> arg0,
  ) =>
      native.CBLReplicator_Stop(
        arg0,
      );

  @override
  void CBLReplicator_SetHostReachable(
    ffi.Pointer<CBLReplicator> arg0,
    bool reachable,
  ) =>
      native.CBLReplicator_SetHostReachable(
        arg0,
        reachable,
      );

  @override
  void CBLReplicator_SetSuspended(
    ffi.Pointer<CBLReplicator> repl,
    bool suspended,
  ) =>
      native.CBLReplicator_SetSuspended(
        repl,
        suspended,
      );

  @override
  CBLReplicatorStatus CBLReplicator_Status(
    ffi.Pointer<CBLReplicator> arg0,
  ) =>
      native.CBLReplicator_Status(
        arg0,
      );

  @override
  FLDict CBLReplicator_PendingDocumentIDs(
    ffi.Pointer<CBLReplicator> arg0,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLReplicator_PendingDocumentIDs(
        arg0,
        outError,
      );

  @override
  bool CBLReplicator_IsDocumentPending(
    ffi.Pointer<CBLReplicator> repl,
    FLString docID,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLReplicator_IsDocumentPending(
        repl,
        docID,
        outError,
      );

  @override
  FLDict CBLReplicator_PendingDocumentIDs2(
    ffi.Pointer<CBLReplicator> arg0,
    ffi.Pointer<CBLCollection> collection,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLReplicator_PendingDocumentIDs2(
        arg0,
        collection,
        outError,
      );

  @override
  bool CBLReplicator_IsDocumentPending2(
    ffi.Pointer<CBLReplicator> repl,
    FLString docID,
    ffi.Pointer<CBLCollection> collection,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLReplicator_IsDocumentPending2(
        repl,
        docID,
        collection,
        outError,
      );

  @override
  ffi.Pointer<CBLListenerToken> CBLReplicator_AddChangeListener(
    ffi.Pointer<CBLReplicator> arg0,
    CBLReplicatorChangeListener arg1,
    ffi.Pointer<ffi.Void> context,
  ) =>
      native.CBLReplicator_AddChangeListener(
        arg0,
        arg1,
        context,
      );

  @override
  ffi.Pointer<CBLListenerToken> CBLReplicator_AddDocumentReplicationListener(
    ffi.Pointer<CBLReplicator> arg0,
    CBLDocumentReplicationListener arg1,
    ffi.Pointer<ffi.Void> context,
  ) =>
      native.CBLReplicator_AddDocumentReplicationListener(
        arg0,
        arg1,
        context,
      );

  @override
  bool get kCBLDefaultDatabaseFullSync => native.kCBLDefaultDatabaseFullSync;

  @override
  bool get kCBLDefaultDatabaseMmapDisabled =>
      native.kCBLDefaultDatabaseMmapDisabled;

  @override
  bool get kCBLDefaultLogFileUsePlaintext =>
      native.kCBLDefaultLogFileUsePlaintext;

  @override
  bool get kCBLDefaultLogFileUsePlainText =>
      native.kCBLDefaultLogFileUsePlainText;

  @override
  int get kCBLDefaultLogFileMaxSize => native.kCBLDefaultLogFileMaxSize;

  @override
  int get kCBLDefaultLogFileMaxRotateCount =>
      native.kCBLDefaultLogFileMaxRotateCount;

  @override
  bool get kCBLDefaultFileLogSinkUsePlaintext =>
      native.kCBLDefaultFileLogSinkUsePlaintext;

  @override
  int get kCBLDefaultFileLogSinkMaxSize => native.kCBLDefaultFileLogSinkMaxSize;

  @override
  int get kCBLDefaultFileLogSinkMaxKeptFiles =>
      native.kCBLDefaultFileLogSinkMaxKeptFiles;

  @override
  bool get kCBLDefaultFullTextIndexIgnoreAccents =>
      native.kCBLDefaultFullTextIndexIgnoreAccents;

  @override
  DartCBLReplicatorType get kCBLDefaultReplicatorType =>
      native.kCBLDefaultReplicatorType;

  @override
  bool get kCBLDefaultReplicatorContinuous =>
      native.kCBLDefaultReplicatorContinuous;

  @override
  int get kCBLDefaultReplicatorHeartbeat =>
      native.kCBLDefaultReplicatorHeartbeat;

  @override
  int get kCBLDefaultReplicatorMaxAttemptsSingleShot =>
      native.kCBLDefaultReplicatorMaxAttemptsSingleShot;

  @override
  int get kCBLDefaultReplicatorMaxAttemptsContinuous =>
      native.kCBLDefaultReplicatorMaxAttemptsContinuous;

  @override
  int get kCBLDefaultReplicatorMaxAttemptsWaitTime =>
      native.kCBLDefaultReplicatorMaxAttemptsWaitTime;

  @override
  int get kCBLDefaultReplicatorMaxAttemptWaitTime =>
      native.kCBLDefaultReplicatorMaxAttemptWaitTime;

  @override
  bool get kCBLDefaultReplicatorDisableAutoPurge =>
      native.kCBLDefaultReplicatorDisableAutoPurge;

  @override
  bool get kCBLDefaultReplicatorAcceptParentCookies =>
      native.kCBLDefaultReplicatorAcceptParentCookies;

  @override
  bool get kCBLDefaultVectorIndexLazy => native.kCBLDefaultVectorIndexLazy;

  @override
  DartCBLDistanceMetric get kCBLDefaultVectorIndexDistanceMetric =>
      native.kCBLDefaultVectorIndexDistanceMetric;

  @override
  int get kCBLDefaultVectorIndexMinTrainingSize =>
      native.kCBLDefaultVectorIndexMinTrainingSize;

  @override
  int get kCBLDefaultVectorIndexMaxTrainingSize =>
      native.kCBLDefaultVectorIndexMaxTrainingSize;

  @override
  int get kCBLDefaultVectorIndexNumProbes =>
      native.kCBLDefaultVectorIndexNumProbes;

  @override
  FLSlice get kCBLEncryptableType => native.kCBLEncryptableType;

  @override
  FLSlice get kCBLEncryptableValueProperty =>
      native.kCBLEncryptableValueProperty;

  @override
  ffi.Pointer<CBLEncryptable> CBLEncryptable_CreateWithNull() =>
      native.CBLEncryptable_CreateWithNull();

  @override
  ffi.Pointer<CBLEncryptable> CBLEncryptable_CreateWithBool(
    bool value,
  ) =>
      native.CBLEncryptable_CreateWithBool(
        value,
      );

  @override
  ffi.Pointer<CBLEncryptable> CBLEncryptable_CreateWithInt(
    int value,
  ) =>
      native.CBLEncryptable_CreateWithInt(
        value,
      );

  @override
  ffi.Pointer<CBLEncryptable> CBLEncryptable_CreateWithUInt(
    int value,
  ) =>
      native.CBLEncryptable_CreateWithUInt(
        value,
      );

  @override
  ffi.Pointer<CBLEncryptable> CBLEncryptable_CreateWithFloat(
    double value,
  ) =>
      native.CBLEncryptable_CreateWithFloat(
        value,
      );

  @override
  ffi.Pointer<CBLEncryptable> CBLEncryptable_CreateWithDouble(
    double value,
  ) =>
      native.CBLEncryptable_CreateWithDouble(
        value,
      );

  @override
  ffi.Pointer<CBLEncryptable> CBLEncryptable_CreateWithString(
    FLString value,
  ) =>
      native.CBLEncryptable_CreateWithString(
        value,
      );

  @override
  ffi.Pointer<CBLEncryptable> CBLEncryptable_CreateWithValue(
    FLValue value,
  ) =>
      native.CBLEncryptable_CreateWithValue(
        value,
      );

  @override
  ffi.Pointer<CBLEncryptable> CBLEncryptable_CreateWithArray(
    FLArray value,
  ) =>
      native.CBLEncryptable_CreateWithArray(
        value,
      );

  @override
  ffi.Pointer<CBLEncryptable> CBLEncryptable_CreateWithDict(
    FLDict value,
  ) =>
      native.CBLEncryptable_CreateWithDict(
        value,
      );

  @override
  FLValue CBLEncryptable_Value(
    ffi.Pointer<CBLEncryptable> encryptable,
  ) =>
      native.CBLEncryptable_Value(
        encryptable,
      );

  @override
  FLDict CBLEncryptable_Properties(
    ffi.Pointer<CBLEncryptable> encryptable,
  ) =>
      native.CBLEncryptable_Properties(
        encryptable,
      );

  @override
  bool FLDict_IsEncryptableValue(
    FLDict arg0,
  ) =>
      native.FLDict_IsEncryptableValue(
        arg0,
      );

  @override
  ffi.Pointer<CBLEncryptable> FLDict_GetEncryptableValue(
    FLDict encryptableDict,
  ) =>
      native.FLDict_GetEncryptableValue(
        encryptableDict,
      );

  @override
  void FLSlot_SetEncryptableValue(
    FLSlot slot,
    ffi.Pointer<CBLEncryptable> encryptable,
  ) =>
      native.FLSlot_SetEncryptableValue(
        slot,
        encryptable,
      );

  @override
  void CBLLogSinks_SetConsole(
    CBLConsoleLogSink sink,
  ) =>
      native.CBLLogSinks_SetConsole(
        sink,
      );

  @override
  CBLConsoleLogSink CBLLogSinks_Console() => native.CBLLogSinks_Console();

  @override
  void CBLLogSinks_SetCustom(
    CBLCustomLogSink sink,
  ) =>
      native.CBLLogSinks_SetCustom(
        sink,
      );

  @override
  CBLCustomLogSink CBLLogSinks_CustomSink() => native.CBLLogSinks_CustomSink();

  @override
  void CBLLogSinks_SetFile(
    CBLFileLogSink sink,
  ) =>
      native.CBLLogSinks_SetFile(
        sink,
      );

  @override
  CBLFileLogSink CBLLogSinks_File() => native.CBLLogSinks_File();

  @override
  void CBL_Log(
    int domain,
    int level,
    ffi.Pointer<ffi.Char> format,
  ) =>
      native.CBL_Log(
        domain,
        level,
        format,
      );

  @override
  void CBL_LogMessage(
    int domain,
    int level,
    FLSlice message,
  ) =>
      native.CBL_LogMessage(
        domain,
        level,
        message,
      );

  @override
  int CBLLog_ConsoleLevel() => native.CBLLog_ConsoleLevel();

  @override
  void CBLLog_SetConsoleLevel(
    int arg0,
  ) =>
      native.CBLLog_SetConsoleLevel(
        arg0,
      );

  @override
  int CBLLog_CallbackLevel() => native.CBLLog_CallbackLevel();

  @override
  void CBLLog_SetCallbackLevel(
    int arg0,
  ) =>
      native.CBLLog_SetCallbackLevel(
        arg0,
      );

  @override
  CBLLogCallback CBLLog_Callback() => native.CBLLog_Callback();

  @override
  void CBLLog_SetCallback(
    CBLLogCallback callback,
  ) =>
      native.CBLLog_SetCallback(
        callback,
      );

  @override
  ffi.Pointer<CBLLogFileConfiguration> CBLLog_FileConfig() =>
      native.CBLLog_FileConfig();

  @override
  bool CBLLog_SetFileConfig(
    CBLLogFileConfiguration arg0,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLLog_SetFileConfig(
        arg0,
        outError,
      );

  @override
  void CBL_RegisterPredictiveModel(
    FLString name,
    CBLPredictiveModel model,
  ) =>
      native.CBL_RegisterPredictiveModel(
        name,
        model,
      );

  @override
  void CBL_UnregisterPredictiveModel(
    FLString name,
  ) =>
      native.CBL_UnregisterPredictiveModel(
        name,
      );

  @override
  ffi.Pointer<CBLQuery> CBLDatabase_CreateQuery(
    ffi.Pointer<CBLDatabase> db,
    int language,
    FLString queryString,
    ffi.Pointer<ffi.Int> outErrorPos,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDatabase_CreateQuery(
        db,
        language,
        queryString,
        outErrorPos,
        outError,
      );

  @override
  void CBLQuery_SetParameters(
    ffi.Pointer<CBLQuery> query,
    FLDict parameters,
  ) =>
      native.CBLQuery_SetParameters(
        query,
        parameters,
      );

  @override
  FLDict CBLQuery_Parameters(
    ffi.Pointer<CBLQuery> query,
  ) =>
      native.CBLQuery_Parameters(
        query,
      );

  @override
  ffi.Pointer<CBLResultSet> CBLQuery_Execute(
    ffi.Pointer<CBLQuery> arg0,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLQuery_Execute(
        arg0,
        outError,
      );

  @override
  FLSliceResult CBLQuery_Explain(
    ffi.Pointer<CBLQuery> arg0,
  ) =>
      native.CBLQuery_Explain(
        arg0,
      );

  @override
  int CBLQuery_ColumnCount(
    ffi.Pointer<CBLQuery> arg0,
  ) =>
      native.CBLQuery_ColumnCount(
        arg0,
      );

  @override
  FLSlice CBLQuery_ColumnName(
    ffi.Pointer<CBLQuery> arg0,
    int columnIndex,
  ) =>
      native.CBLQuery_ColumnName(
        arg0,
        columnIndex,
      );

  @override
  bool CBLResultSet_Next(
    ffi.Pointer<CBLResultSet> arg0,
  ) =>
      native.CBLResultSet_Next(
        arg0,
      );

  @override
  FLValue CBLResultSet_ValueAtIndex(
    ffi.Pointer<CBLResultSet> arg0,
    int index,
  ) =>
      native.CBLResultSet_ValueAtIndex(
        arg0,
        index,
      );

  @override
  FLValue CBLResultSet_ValueForKey(
    ffi.Pointer<CBLResultSet> arg0,
    FLString key,
  ) =>
      native.CBLResultSet_ValueForKey(
        arg0,
        key,
      );

  @override
  FLArray CBLResultSet_ResultArray(
    ffi.Pointer<CBLResultSet> arg0,
  ) =>
      native.CBLResultSet_ResultArray(
        arg0,
      );

  @override
  FLDict CBLResultSet_ResultDict(
    ffi.Pointer<CBLResultSet> arg0,
  ) =>
      native.CBLResultSet_ResultDict(
        arg0,
      );

  @override
  ffi.Pointer<CBLQuery> CBLResultSet_GetQuery(
    ffi.Pointer<CBLResultSet> rs,
  ) =>
      native.CBLResultSet_GetQuery(
        rs,
      );

  @override
  ffi.Pointer<CBLListenerToken> CBLQuery_AddChangeListener(
    ffi.Pointer<CBLQuery> query,
    CBLQueryChangeListener listener,
    ffi.Pointer<ffi.Void> context,
  ) =>
      native.CBLQuery_AddChangeListener(
        query,
        listener,
        context,
      );

  @override
  ffi.Pointer<CBLResultSet> CBLQuery_CopyCurrentResults(
    ffi.Pointer<CBLQuery> query,
    ffi.Pointer<CBLListenerToken> listener,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLQuery_CopyCurrentResults(
        query,
        listener,
        outError,
      );

  @override
  FLString CBLQueryIndex_Name(
    ffi.Pointer<CBLQueryIndex> index,
  ) =>
      native.CBLQueryIndex_Name(
        index,
      );

  @override
  ffi.Pointer<CBLCollection> CBLQueryIndex_Collection(
    ffi.Pointer<CBLQueryIndex> index,
  ) =>
      native.CBLQueryIndex_Collection(
        index,
      );

  @override
  ffi.Pointer<CBLIndexUpdater> CBLQueryIndex_BeginUpdate(
    ffi.Pointer<CBLQueryIndex> index,
    int limit,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLQueryIndex_BeginUpdate(
        index,
        limit,
        outError,
      );

  @override
  int CBLIndexUpdater_Count(
    ffi.Pointer<CBLIndexUpdater> updater,
  ) =>
      native.CBLIndexUpdater_Count(
        updater,
      );

  @override
  FLValue CBLIndexUpdater_Value(
    ffi.Pointer<CBLIndexUpdater> updater,
    int index,
  ) =>
      native.CBLIndexUpdater_Value(
        updater,
        index,
      );

  @override
  bool CBLIndexUpdater_SetVector(
    ffi.Pointer<CBLIndexUpdater> updater,
    int index,
    ffi.Pointer<ffi.Float> vector,
    int dimension,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLIndexUpdater_SetVector(
        updater,
        index,
        vector,
        dimension,
        outError,
      );

  @override
  void CBLIndexUpdater_SkipVector(
    ffi.Pointer<CBLIndexUpdater> updater,
    int index,
  ) =>
      native.CBLIndexUpdater_SkipVector(
        updater,
        index,
      );

  @override
  bool CBLIndexUpdater_Finish(
    ffi.Pointer<CBLIndexUpdater> updater,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLIndexUpdater_Finish(
        updater,
        outError,
      );

  @override
  FLString get kCBLDefaultScopeName => native.kCBLDefaultScopeName;

  @override
  FLString CBLScope_Name(
    ffi.Pointer<CBLScope> scope,
  ) =>
      native.CBLScope_Name(
        scope,
      );

  @override
  ffi.Pointer<CBLDatabase> CBLScope_Database(
    ffi.Pointer<CBLScope> scope,
  ) =>
      native.CBLScope_Database(
        scope,
      );

  @override
  FLMutableArray CBLScope_CollectionNames(
    ffi.Pointer<CBLScope> scope,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLScope_CollectionNames(
        scope,
        outError,
      );

  @override
  ffi.Pointer<CBLCollection> CBLScope_Collection(
    ffi.Pointer<CBLScope> scope,
    FLString collectionName,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLScope_Collection(
        scope,
        collectionName,
        outError,
      );

  @override
  bool FLSlice_Equal(
    FLSlice a,
    FLSlice b,
  ) =>
      native.FLSlice_Equal(
        a,
        b,
      );

  @override
  int FLSlice_Compare(
    FLSlice arg0,
    FLSlice arg1,
  ) =>
      native.FLSlice_Compare(
        arg0,
        arg1,
      );

  @override
  int FLSlice_Hash(
    FLSlice s,
  ) =>
      native.FLSlice_Hash(
        s,
      );

  @override
  bool FLSlice_ToCString(
    FLSlice s,
    ffi.Pointer<ffi.Char> buffer,
    int capacity,
  ) =>
      native.FLSlice_ToCString(
        s,
        buffer,
        capacity,
      );

  @override
  FLSliceResult FLSliceResult_New(
    int arg0,
  ) =>
      native.FLSliceResult_New(
        arg0,
      );

  @override
  FLSliceResult FLSlice_Copy(
    FLSlice arg0,
  ) =>
      native.FLSlice_Copy(
        arg0,
      );

  @override
  void FLBuf_Retain(
    ffi.Pointer<ffi.Void> arg0,
  ) =>
      native.FLBuf_Retain(
        arg0,
      );

  @override
  void FLBuf_Release(
    ffi.Pointer<ffi.Void> arg0,
  ) =>
      native.FLBuf_Release(
        arg0,
      );

  @override
  void FL_WipeMemory(
    ffi.Pointer<ffi.Void> dst,
    int size,
  ) =>
      native.FL_WipeMemory(
        dst,
        size,
      );

  @override
  int FLTimestamp_Now() => native.FLTimestamp_Now();

  @override
  FLStringResult FLTimestamp_ToString(
    int timestamp,
    bool asUTC,
  ) =>
      native.FLTimestamp_ToString(
        timestamp,
        asUTC,
      );

  @override
  int FLTimestamp_FromString(
    FLString str,
  ) =>
      native.FLTimestamp_FromString(
        str,
      );

  @override
  FLArray get kFLEmptyArray => native.kFLEmptyArray;

  @override
  void set kFLEmptyArray(
    FLArray value,
  ) =>
      native.kFLEmptyArray = value;

  @override
  int FLArray_Count(
    FLArray arg0,
  ) =>
      native.FLArray_Count(
        arg0,
      );

  @override
  bool FLArray_IsEmpty(
    FLArray arg0,
  ) =>
      native.FLArray_IsEmpty(
        arg0,
      );

  @override
  FLMutableArray FLArray_AsMutable(
    FLArray arg0,
  ) =>
      native.FLArray_AsMutable(
        arg0,
      );

  @override
  FLValue FLArray_Get(
    FLArray arg0,
    int index,
  ) =>
      native.FLArray_Get(
        arg0,
        index,
      );

  @override
  void FLArrayIterator_Begin(
    FLArray arg0,
    ffi.Pointer<FLArrayIterator> arg1,
  ) =>
      native.FLArrayIterator_Begin(
        arg0,
        arg1,
      );

  @override
  FLValue FLArrayIterator_GetValue(
    ffi.Pointer<FLArrayIterator> arg0,
  ) =>
      native.FLArrayIterator_GetValue(
        arg0,
      );

  @override
  FLValue FLArrayIterator_GetValueAt(
    ffi.Pointer<FLArrayIterator> arg0,
    int offset,
  ) =>
      native.FLArrayIterator_GetValueAt(
        arg0,
        offset,
      );

  @override
  int FLArrayIterator_GetCount(
    ffi.Pointer<FLArrayIterator> arg0,
  ) =>
      native.FLArrayIterator_GetCount(
        arg0,
      );

  @override
  bool FLArrayIterator_Next(
    ffi.Pointer<FLArrayIterator> arg0,
  ) =>
      native.FLArrayIterator_Next(
        arg0,
      );

  @override
  FLDict get kFLEmptyDict => native.kFLEmptyDict;

  @override
  void set kFLEmptyDict(
    FLDict value,
  ) =>
      native.kFLEmptyDict = value;

  @override
  int FLDict_Count(
    FLDict arg0,
  ) =>
      native.FLDict_Count(
        arg0,
      );

  @override
  bool FLDict_IsEmpty(
    FLDict arg0,
  ) =>
      native.FLDict_IsEmpty(
        arg0,
      );

  @override
  FLMutableDict FLDict_AsMutable(
    FLDict arg0,
  ) =>
      native.FLDict_AsMutable(
        arg0,
      );

  @override
  FLValue FLDict_Get(
    FLDict arg0,
    FLSlice keyString,
  ) =>
      native.FLDict_Get(
        arg0,
        keyString,
      );

  @override
  void FLDictIterator_Begin(
    FLDict arg0,
    ffi.Pointer<FLDictIterator> arg1,
  ) =>
      native.FLDictIterator_Begin(
        arg0,
        arg1,
      );

  @override
  FLValue FLDictIterator_GetKey(
    ffi.Pointer<FLDictIterator> arg0,
  ) =>
      native.FLDictIterator_GetKey(
        arg0,
      );

  @override
  FLString FLDictIterator_GetKeyString(
    ffi.Pointer<FLDictIterator> arg0,
  ) =>
      native.FLDictIterator_GetKeyString(
        arg0,
      );

  @override
  FLValue FLDictIterator_GetValue(
    ffi.Pointer<FLDictIterator> arg0,
  ) =>
      native.FLDictIterator_GetValue(
        arg0,
      );

  @override
  int FLDictIterator_GetCount(
    ffi.Pointer<FLDictIterator> arg0,
  ) =>
      native.FLDictIterator_GetCount(
        arg0,
      );

  @override
  bool FLDictIterator_Next(
    ffi.Pointer<FLDictIterator> arg0,
  ) =>
      native.FLDictIterator_Next(
        arg0,
      );

  @override
  void FLDictIterator_End(
    ffi.Pointer<FLDictIterator> arg0,
  ) =>
      native.FLDictIterator_End(
        arg0,
      );

  @override
  FLDictKey FLDictKey_Init(
    FLSlice string,
  ) =>
      native.FLDictKey_Init(
        string,
      );

  @override
  FLString FLDictKey_GetString(
    ffi.Pointer<FLDictKey> arg0,
  ) =>
      native.FLDictKey_GetString(
        arg0,
      );

  @override
  FLValue FLDict_GetWithKey(
    FLDict arg0,
    ffi.Pointer<FLDictKey> arg1,
  ) =>
      native.FLDict_GetWithKey(
        arg0,
        arg1,
      );

  @override
  FLDeepIterator FLDeepIterator_New(
    FLValue arg0,
  ) =>
      native.FLDeepIterator_New(
        arg0,
      );

  @override
  void FLDeepIterator_Free(
    FLDeepIterator arg0,
  ) =>
      native.FLDeepIterator_Free(
        arg0,
      );

  @override
  FLValue FLDeepIterator_GetValue(
    FLDeepIterator arg0,
  ) =>
      native.FLDeepIterator_GetValue(
        arg0,
      );

  @override
  FLValue FLDeepIterator_GetParent(
    FLDeepIterator arg0,
  ) =>
      native.FLDeepIterator_GetParent(
        arg0,
      );

  @override
  FLSlice FLDeepIterator_GetKey(
    FLDeepIterator arg0,
  ) =>
      native.FLDeepIterator_GetKey(
        arg0,
      );

  @override
  int FLDeepIterator_GetIndex(
    FLDeepIterator arg0,
  ) =>
      native.FLDeepIterator_GetIndex(
        arg0,
      );

  @override
  int FLDeepIterator_GetDepth(
    FLDeepIterator arg0,
  ) =>
      native.FLDeepIterator_GetDepth(
        arg0,
      );

  @override
  void FLDeepIterator_SkipChildren(
    FLDeepIterator arg0,
  ) =>
      native.FLDeepIterator_SkipChildren(
        arg0,
      );

  @override
  bool FLDeepIterator_Next(
    FLDeepIterator arg0,
  ) =>
      native.FLDeepIterator_Next(
        arg0,
      );

  @override
  void FLDeepIterator_GetPath(
    FLDeepIterator arg0,
    ffi.Pointer<ffi.Pointer<FLPathComponent>> outPath,
    ffi.Pointer<ffi.Size> outDepth,
  ) =>
      native.FLDeepIterator_GetPath(
        arg0,
        outPath,
        outDepth,
      );

  @override
  FLSliceResult FLDeepIterator_GetPathString(
    FLDeepIterator arg0,
  ) =>
      native.FLDeepIterator_GetPathString(
        arg0,
      );

  @override
  FLSliceResult FLDeepIterator_GetJSONPointer(
    FLDeepIterator arg0,
  ) =>
      native.FLDeepIterator_GetJSONPointer(
        arg0,
      );

  @override
  FLDoc FLDoc_FromResultData(
    FLSliceResult data,
    int arg1,
    FLSharedKeys arg2,
    FLSlice externData,
  ) =>
      native.FLDoc_FromResultData(
        data,
        arg1,
        arg2,
        externData,
      );

  @override
  void FLDoc_Release(
    FLDoc arg0,
  ) =>
      native.FLDoc_Release(
        arg0,
      );

  @override
  FLDoc FLDoc_Retain(
    FLDoc arg0,
  ) =>
      native.FLDoc_Retain(
        arg0,
      );

  @override
  FLSlice FLDoc_GetData(
    FLDoc arg0,
  ) =>
      native.FLDoc_GetData(
        arg0,
      );

  @override
  FLSliceResult FLDoc_GetAllocedData(
    FLDoc arg0,
  ) =>
      native.FLDoc_GetAllocedData(
        arg0,
      );

  @override
  FLValue FLDoc_GetRoot(
    FLDoc arg0,
  ) =>
      native.FLDoc_GetRoot(
        arg0,
      );

  @override
  FLSharedKeys FLDoc_GetSharedKeys(
    FLDoc arg0,
  ) =>
      native.FLDoc_GetSharedKeys(
        arg0,
      );

  @override
  FLDoc FLValue_FindDoc(
    FLValue arg0,
  ) =>
      native.FLValue_FindDoc(
        arg0,
      );

  @override
  bool FLDoc_SetAssociated(
    FLDoc doc,
    ffi.Pointer<ffi.Void> pointer,
    ffi.Pointer<ffi.Char> type,
  ) =>
      native.FLDoc_SetAssociated(
        doc,
        pointer,
        type,
      );

  @override
  ffi.Pointer<ffi.Void> FLDoc_GetAssociated(
    FLDoc doc,
    ffi.Pointer<ffi.Char> type,
  ) =>
      native.FLDoc_GetAssociated(
        doc,
        type,
      );

  @override
  FLEncoder FLEncoder_New() => native.FLEncoder_New();

  @override
  FLEncoder FLEncoder_NewWithOptions(
    int format,
    int reserveSize,
    bool uniqueStrings,
  ) =>
      native.FLEncoder_NewWithOptions(
        format,
        reserveSize,
        uniqueStrings,
      );

  @override
  FLEncoder FLEncoder_NewWritingToFile(
    ffi.Pointer<FILE> arg0,
    bool uniqueStrings,
  ) =>
      native.FLEncoder_NewWritingToFile(
        arg0,
        uniqueStrings,
      );

  @override
  void FLEncoder_Free(
    FLEncoder arg0,
  ) =>
      native.FLEncoder_Free(
        arg0,
      );

  @override
  void FLEncoder_SetSharedKeys(
    FLEncoder arg0,
    FLSharedKeys arg1,
  ) =>
      native.FLEncoder_SetSharedKeys(
        arg0,
        arg1,
      );

  @override
  void FLEncoder_SetExtraInfo(
    FLEncoder arg0,
    ffi.Pointer<ffi.Void> info,
  ) =>
      native.FLEncoder_SetExtraInfo(
        arg0,
        info,
      );

  @override
  ffi.Pointer<ffi.Void> FLEncoder_GetExtraInfo(
    FLEncoder arg0,
  ) =>
      native.FLEncoder_GetExtraInfo(
        arg0,
      );

  @override
  void FLEncoder_Reset(
    FLEncoder arg0,
  ) =>
      native.FLEncoder_Reset(
        arg0,
      );

  @override
  int FLEncoder_BytesWritten(
    FLEncoder arg0,
  ) =>
      native.FLEncoder_BytesWritten(
        arg0,
      );

  @override
  bool FLEncoder_WriteNull(
    FLEncoder arg0,
  ) =>
      native.FLEncoder_WriteNull(
        arg0,
      );

  @override
  bool FLEncoder_WriteUndefined(
    FLEncoder arg0,
  ) =>
      native.FLEncoder_WriteUndefined(
        arg0,
      );

  @override
  bool FLEncoder_WriteBool(
    FLEncoder arg0,
    bool arg1,
  ) =>
      native.FLEncoder_WriteBool(
        arg0,
        arg1,
      );

  @override
  bool FLEncoder_WriteInt(
    FLEncoder arg0,
    int arg1,
  ) =>
      native.FLEncoder_WriteInt(
        arg0,
        arg1,
      );

  @override
  bool FLEncoder_WriteUInt(
    FLEncoder arg0,
    int arg1,
  ) =>
      native.FLEncoder_WriteUInt(
        arg0,
        arg1,
      );

  @override
  bool FLEncoder_WriteFloat(
    FLEncoder arg0,
    double arg1,
  ) =>
      native.FLEncoder_WriteFloat(
        arg0,
        arg1,
      );

  @override
  bool FLEncoder_WriteDouble(
    FLEncoder arg0,
    double arg1,
  ) =>
      native.FLEncoder_WriteDouble(
        arg0,
        arg1,
      );

  @override
  bool FLEncoder_WriteString(
    FLEncoder arg0,
    FLString arg1,
  ) =>
      native.FLEncoder_WriteString(
        arg0,
        arg1,
      );

  @override
  bool FLEncoder_WriteDateString(
    FLEncoder encoder,
    int ts,
    bool asUTC,
  ) =>
      native.FLEncoder_WriteDateString(
        encoder,
        ts,
        asUTC,
      );

  @override
  bool FLEncoder_WriteData(
    FLEncoder arg0,
    FLSlice arg1,
  ) =>
      native.FLEncoder_WriteData(
        arg0,
        arg1,
      );

  @override
  bool FLEncoder_WriteValue(
    FLEncoder arg0,
    FLValue arg1,
  ) =>
      native.FLEncoder_WriteValue(
        arg0,
        arg1,
      );

  @override
  bool FLEncoder_BeginArray(
    FLEncoder arg0,
    int reserveCount,
  ) =>
      native.FLEncoder_BeginArray(
        arg0,
        reserveCount,
      );

  @override
  bool FLEncoder_EndArray(
    FLEncoder arg0,
  ) =>
      native.FLEncoder_EndArray(
        arg0,
      );

  @override
  bool FLEncoder_BeginDict(
    FLEncoder arg0,
    int reserveCount,
  ) =>
      native.FLEncoder_BeginDict(
        arg0,
        reserveCount,
      );

  @override
  bool FLEncoder_WriteKey(
    FLEncoder arg0,
    FLString arg1,
  ) =>
      native.FLEncoder_WriteKey(
        arg0,
        arg1,
      );

  @override
  bool FLEncoder_WriteKeyValue(
    FLEncoder arg0,
    FLValue arg1,
  ) =>
      native.FLEncoder_WriteKeyValue(
        arg0,
        arg1,
      );

  @override
  bool FLEncoder_EndDict(
    FLEncoder arg0,
  ) =>
      native.FLEncoder_EndDict(
        arg0,
      );

  @override
  bool FLEncoder_WriteRaw(
    FLEncoder arg0,
    FLSlice arg1,
  ) =>
      native.FLEncoder_WriteRaw(
        arg0,
        arg1,
      );

  @override
  FLDoc FLEncoder_FinishDoc(
    FLEncoder arg0,
    ffi.Pointer<ffi.UnsignedInt> outError,
  ) =>
      native.FLEncoder_FinishDoc(
        arg0,
        outError,
      );

  @override
  FLSliceResult FLEncoder_Finish(
    FLEncoder arg0,
    ffi.Pointer<ffi.UnsignedInt> outError,
  ) =>
      native.FLEncoder_Finish(
        arg0,
        outError,
      );

  @override
  int FLEncoder_GetError(
    FLEncoder arg0,
  ) =>
      native.FLEncoder_GetError(
        arg0,
      );

  @override
  ffi.Pointer<ffi.Char> FLEncoder_GetErrorMessage(
    FLEncoder arg0,
  ) =>
      native.FLEncoder_GetErrorMessage(
        arg0,
      );

  @override
  FLStringResult FLValue_ToJSON(
    FLValue arg0,
  ) =>
      native.FLValue_ToJSON(
        arg0,
      );

  @override
  FLStringResult FLValue_ToJSON5(
    FLValue arg0,
  ) =>
      native.FLValue_ToJSON5(
        arg0,
      );

  @override
  FLStringResult FLValue_ToJSONX(
    FLValue v,
    bool json5,
    bool canonicalForm,
  ) =>
      native.FLValue_ToJSONX(
        v,
        json5,
        canonicalForm,
      );

  @override
  FLDoc FLDoc_FromJSON(
    FLSlice json,
    ffi.Pointer<ffi.UnsignedInt> outError,
  ) =>
      native.FLDoc_FromJSON(
        json,
        outError,
      );

  @override
  FLMutableArray FLMutableArray_NewFromJSON(
    FLString json,
    ffi.Pointer<ffi.UnsignedInt> outError,
  ) =>
      native.FLMutableArray_NewFromJSON(
        json,
        outError,
      );

  @override
  FLMutableDict FLMutableDict_NewFromJSON(
    FLString json,
    ffi.Pointer<ffi.UnsignedInt> outError,
  ) =>
      native.FLMutableDict_NewFromJSON(
        json,
        outError,
      );

  @override
  bool FLEncoder_ConvertJSON(
    FLEncoder arg0,
    FLSlice json,
  ) =>
      native.FLEncoder_ConvertJSON(
        arg0,
        json,
      );

  @override
  FLKeyPath FLKeyPath_New(
    FLSlice specifier,
    ffi.Pointer<ffi.UnsignedInt> outError,
  ) =>
      native.FLKeyPath_New(
        specifier,
        outError,
      );

  @override
  void FLKeyPath_Free(
    FLKeyPath arg0,
  ) =>
      native.FLKeyPath_Free(
        arg0,
      );

  @override
  FLValue FLKeyPath_Eval(
    FLKeyPath arg0,
    FLValue root,
  ) =>
      native.FLKeyPath_Eval(
        arg0,
        root,
      );

  @override
  FLValue FLKeyPath_EvalOnce(
    FLSlice specifier,
    FLValue root,
    ffi.Pointer<ffi.UnsignedInt> outError,
  ) =>
      native.FLKeyPath_EvalOnce(
        specifier,
        root,
        outError,
      );

  @override
  FLStringResult FLKeyPath_ToString(
    FLKeyPath path,
  ) =>
      native.FLKeyPath_ToString(
        path,
      );

  @override
  bool FLKeyPath_Equals(
    FLKeyPath path1,
    FLKeyPath path2,
  ) =>
      native.FLKeyPath_Equals(
        path1,
        path2,
      );

  @override
  bool FLKeyPath_GetElement(
    FLKeyPath arg0,
    int i,
    ffi.Pointer<FLSlice> outDictKey,
    ffi.Pointer<ffi.Int32> outArrayIndex,
  ) =>
      native.FLKeyPath_GetElement(
        arg0,
        i,
        outDictKey,
        outArrayIndex,
      );

  @override
  FLValue get kFLNullValue => native.kFLNullValue;

  @override
  void set kFLNullValue(
    FLValue value,
  ) =>
      native.kFLNullValue = value;

  @override
  FLValue get kFLUndefinedValue => native.kFLUndefinedValue;

  @override
  void set kFLUndefinedValue(
    FLValue value,
  ) =>
      native.kFLUndefinedValue = value;

  @override
  int FLValue_GetType(
    FLValue arg0,
  ) =>
      native.FLValue_GetType(
        arg0,
      );

  @override
  bool FLValue_IsInteger(
    FLValue arg0,
  ) =>
      native.FLValue_IsInteger(
        arg0,
      );

  @override
  bool FLValue_IsUnsigned(
    FLValue arg0,
  ) =>
      native.FLValue_IsUnsigned(
        arg0,
      );

  @override
  bool FLValue_IsDouble(
    FLValue arg0,
  ) =>
      native.FLValue_IsDouble(
        arg0,
      );

  @override
  bool FLValue_AsBool(
    FLValue arg0,
  ) =>
      native.FLValue_AsBool(
        arg0,
      );

  @override
  int FLValue_AsInt(
    FLValue arg0,
  ) =>
      native.FLValue_AsInt(
        arg0,
      );

  @override
  int FLValue_AsUnsigned(
    FLValue arg0,
  ) =>
      native.FLValue_AsUnsigned(
        arg0,
      );

  @override
  double FLValue_AsFloat(
    FLValue arg0,
  ) =>
      native.FLValue_AsFloat(
        arg0,
      );

  @override
  double FLValue_AsDouble(
    FLValue arg0,
  ) =>
      native.FLValue_AsDouble(
        arg0,
      );

  @override
  FLString FLValue_AsString(
    FLValue arg0,
  ) =>
      native.FLValue_AsString(
        arg0,
      );

  @override
  int FLValue_AsTimestamp(
    FLValue arg0,
  ) =>
      native.FLValue_AsTimestamp(
        arg0,
      );

  @override
  FLSlice FLValue_AsData(
    FLValue arg0,
  ) =>
      native.FLValue_AsData(
        arg0,
      );

  @override
  FLArray FLValue_AsArray(
    FLValue arg0,
  ) =>
      native.FLValue_AsArray(
        arg0,
      );

  @override
  FLDict FLValue_AsDict(
    FLValue arg0,
  ) =>
      native.FLValue_AsDict(
        arg0,
      );

  @override
  FLStringResult FLValue_ToString(
    FLValue arg0,
  ) =>
      native.FLValue_ToString(
        arg0,
      );

  @override
  bool FLValue_IsEqual(
    FLValue v1,
    FLValue v2,
  ) =>
      native.FLValue_IsEqual(
        v1,
        v2,
      );

  @override
  bool FLValue_IsMutable(
    FLValue arg0,
  ) =>
      native.FLValue_IsMutable(
        arg0,
      );

  @override
  FLValue FLValue_Retain(
    FLValue arg0,
  ) =>
      native.FLValue_Retain(
        arg0,
      );

  @override
  void FLValue_Release(
    FLValue arg0,
  ) =>
      native.FLValue_Release(
        arg0,
      );

  @override
  FLMutableArray FLArray_MutableCopy(
    FLArray arg0,
    int arg1,
  ) =>
      native.FLArray_MutableCopy(
        arg0,
        arg1,
      );

  @override
  FLMutableArray FLMutableArray_New() => native.FLMutableArray_New();

  @override
  FLArray FLMutableArray_GetSource(
    FLMutableArray arg0,
  ) =>
      native.FLMutableArray_GetSource(
        arg0,
      );

  @override
  bool FLMutableArray_IsChanged(
    FLMutableArray arg0,
  ) =>
      native.FLMutableArray_IsChanged(
        arg0,
      );

  @override
  void FLMutableArray_SetChanged(
    FLMutableArray arg0,
    bool changed,
  ) =>
      native.FLMutableArray_SetChanged(
        arg0,
        changed,
      );

  @override
  void FLMutableArray_Insert(
    FLMutableArray array,
    int firstIndex,
    int count,
  ) =>
      native.FLMutableArray_Insert(
        array,
        firstIndex,
        count,
      );

  @override
  void FLMutableArray_Remove(
    FLMutableArray array,
    int firstIndex,
    int count,
  ) =>
      native.FLMutableArray_Remove(
        array,
        firstIndex,
        count,
      );

  @override
  void FLMutableArray_Resize(
    FLMutableArray array,
    int size,
  ) =>
      native.FLMutableArray_Resize(
        array,
        size,
      );

  @override
  FLMutableArray FLMutableArray_GetMutableArray(
    FLMutableArray arg0,
    int index,
  ) =>
      native.FLMutableArray_GetMutableArray(
        arg0,
        index,
      );

  @override
  FLMutableDict FLMutableArray_GetMutableDict(
    FLMutableArray arg0,
    int index,
  ) =>
      native.FLMutableArray_GetMutableDict(
        arg0,
        index,
      );

  @override
  FLMutableDict FLDict_MutableCopy(
    FLDict source,
    int arg1,
  ) =>
      native.FLDict_MutableCopy(
        source,
        arg1,
      );

  @override
  FLMutableDict FLMutableDict_New() => native.FLMutableDict_New();

  @override
  FLDict FLMutableDict_GetSource(
    FLMutableDict arg0,
  ) =>
      native.FLMutableDict_GetSource(
        arg0,
      );

  @override
  bool FLMutableDict_IsChanged(
    FLMutableDict arg0,
  ) =>
      native.FLMutableDict_IsChanged(
        arg0,
      );

  @override
  void FLMutableDict_SetChanged(
    FLMutableDict arg0,
    bool arg1,
  ) =>
      native.FLMutableDict_SetChanged(
        arg0,
        arg1,
      );

  @override
  void FLMutableDict_Remove(
    FLMutableDict arg0,
    FLString key,
  ) =>
      native.FLMutableDict_Remove(
        arg0,
        key,
      );

  @override
  void FLMutableDict_RemoveAll(
    FLMutableDict arg0,
  ) =>
      native.FLMutableDict_RemoveAll(
        arg0,
      );

  @override
  FLMutableArray FLMutableDict_GetMutableArray(
    FLMutableDict arg0,
    FLString key,
  ) =>
      native.FLMutableDict_GetMutableArray(
        arg0,
        key,
      );

  @override
  FLMutableDict FLMutableDict_GetMutableDict(
    FLMutableDict arg0,
    FLString key,
  ) =>
      native.FLMutableDict_GetMutableDict(
        arg0,
        key,
      );

  @override
  FLValue FLValue_NewString(
    FLString arg0,
  ) =>
      native.FLValue_NewString(
        arg0,
      );

  @override
  FLValue FLValue_NewData(
    FLSlice arg0,
  ) =>
      native.FLValue_NewData(
        arg0,
      );

  @override
  FLSlot FLMutableArray_Set(
    FLMutableArray arg0,
    int index,
  ) =>
      native.FLMutableArray_Set(
        arg0,
        index,
      );

  @override
  FLSlot FLMutableArray_Append(
    FLMutableArray arg0,
  ) =>
      native.FLMutableArray_Append(
        arg0,
      );

  @override
  FLSlot FLMutableDict_Set(
    FLMutableDict arg0,
    FLString key,
  ) =>
      native.FLMutableDict_Set(
        arg0,
        key,
      );

  @override
  void FLSlot_SetNull(
    FLSlot arg0,
  ) =>
      native.FLSlot_SetNull(
        arg0,
      );

  @override
  void FLSlot_SetBool(
    FLSlot arg0,
    bool arg1,
  ) =>
      native.FLSlot_SetBool(
        arg0,
        arg1,
      );

  @override
  void FLSlot_SetInt(
    FLSlot arg0,
    int arg1,
  ) =>
      native.FLSlot_SetInt(
        arg0,
        arg1,
      );

  @override
  void FLSlot_SetUInt(
    FLSlot arg0,
    int arg1,
  ) =>
      native.FLSlot_SetUInt(
        arg0,
        arg1,
      );

  @override
  void FLSlot_SetFloat(
    FLSlot arg0,
    double arg1,
  ) =>
      native.FLSlot_SetFloat(
        arg0,
        arg1,
      );

  @override
  void FLSlot_SetDouble(
    FLSlot arg0,
    double arg1,
  ) =>
      native.FLSlot_SetDouble(
        arg0,
        arg1,
      );

  @override
  void FLSlot_SetString(
    FLSlot arg0,
    FLString arg1,
  ) =>
      native.FLSlot_SetString(
        arg0,
        arg1,
      );

  @override
  void FLSlot_SetData(
    FLSlot arg0,
    FLSlice arg1,
  ) =>
      native.FLSlot_SetData(
        arg0,
        arg1,
      );

  @override
  void FLSlot_SetValue(
    FLSlot arg0,
    FLValue arg1,
  ) =>
      native.FLSlot_SetValue(
        arg0,
        arg1,
      );

  @override
  FLSliceResult FLCreateJSONDelta(
    FLValue old,
    FLValue nuu,
  ) =>
      native.FLCreateJSONDelta(
        old,
        nuu,
      );

  @override
  bool FLEncodeJSONDelta(
    FLValue old,
    FLValue nuu,
    FLEncoder jsonEncoder,
  ) =>
      native.FLEncodeJSONDelta(
        old,
        nuu,
        jsonEncoder,
      );

  @override
  FLSliceResult FLApplyJSONDelta(
    FLValue old,
    FLSlice jsonDelta,
    ffi.Pointer<ffi.UnsignedInt> outError,
  ) =>
      native.FLApplyJSONDelta(
        old,
        jsonDelta,
        outError,
      );

  @override
  bool FLEncodeApplyingJSONDelta(
    FLValue old,
    FLSlice jsonDelta,
    FLEncoder encoder,
  ) =>
      native.FLEncodeApplyingJSONDelta(
        old,
        jsonDelta,
        encoder,
      );

  @override
  FLSharedKeys FLSharedKeys_New() => native.FLSharedKeys_New();

  @override
  FLSharedKeys FLSharedKeys_NewWithRead(
    FLSharedKeysReadCallback arg0,
    ffi.Pointer<ffi.Void> context,
  ) =>
      native.FLSharedKeys_NewWithRead(
        arg0,
        context,
      );

  @override
  FLSliceResult FLSharedKeys_GetStateData(
    FLSharedKeys arg0,
  ) =>
      native.FLSharedKeys_GetStateData(
        arg0,
      );

  @override
  bool FLSharedKeys_LoadStateData(
    FLSharedKeys arg0,
    FLSlice arg1,
  ) =>
      native.FLSharedKeys_LoadStateData(
        arg0,
        arg1,
      );

  @override
  void FLSharedKeys_WriteState(
    FLSharedKeys arg0,
    FLEncoder arg1,
  ) =>
      native.FLSharedKeys_WriteState(
        arg0,
        arg1,
      );

  @override
  bool FLSharedKeys_LoadState(
    FLSharedKeys arg0,
    FLValue arg1,
  ) =>
      native.FLSharedKeys_LoadState(
        arg0,
        arg1,
      );

  @override
  int FLSharedKeys_Encode(
    FLSharedKeys arg0,
    FLString arg1,
    bool add,
  ) =>
      native.FLSharedKeys_Encode(
        arg0,
        arg1,
        add,
      );

  @override
  FLString FLSharedKeys_Decode(
    FLSharedKeys arg0,
    int key,
  ) =>
      native.FLSharedKeys_Decode(
        arg0,
        key,
      );

  @override
  int FLSharedKeys_Count(
    FLSharedKeys arg0,
  ) =>
      native.FLSharedKeys_Count(
        arg0,
      );

  @override
  void FLSharedKeys_RevertToCount(
    FLSharedKeys arg0,
    int oldCount,
  ) =>
      native.FLSharedKeys_RevertToCount(
        arg0,
        oldCount,
      );

  @override
  void FLSharedKeys_DisableCaching(
    FLSharedKeys arg0,
  ) =>
      native.FLSharedKeys_DisableCaching(
        arg0,
      );

  @override
  FLSharedKeys FLSharedKeys_Retain(
    FLSharedKeys arg0,
  ) =>
      native.FLSharedKeys_Retain(
        arg0,
      );

  @override
  void FLSharedKeys_Release(
    FLSharedKeys arg0,
  ) =>
      native.FLSharedKeys_Release(
        arg0,
      );

  @override
  FLSharedKeyScope FLSharedKeyScope_WithRange(
    FLSlice range,
    FLSharedKeys arg1,
  ) =>
      native.FLSharedKeyScope_WithRange(
        range,
        arg1,
      );

  @override
  void FLSharedKeyScope_Free(
    FLSharedKeyScope arg0,
  ) =>
      native.FLSharedKeyScope_Free(
        arg0,
      );

  @override
  FLValue FLValue_FromData(
    FLSlice data,
    int trust,
  ) =>
      native.FLValue_FromData(
        data,
        trust,
      );

  @override
  FLStringResult FLJSON5_ToJSON(
    FLString json5,
    ffi.Pointer<FLStringResult> outErrorMessage,
    ffi.Pointer<ffi.Size> outErrorPos,
    ffi.Pointer<ffi.UnsignedInt> outError,
  ) =>
      native.FLJSON5_ToJSON(
        json5,
        outErrorMessage,
        outErrorPos,
        outError,
      );

  @override
  FLSliceResult FLData_ConvertJSON(
    FLSlice json,
    ffi.Pointer<ffi.UnsignedInt> outError,
  ) =>
      native.FLData_ConvertJSON(
        json,
        outError,
      );

  @override
  void FLEncoder_Amend(
    FLEncoder e,
    FLSlice base,
    bool reuseStrings,
    bool externPointers,
  ) =>
      native.FLEncoder_Amend(
        e,
        base,
        reuseStrings,
        externPointers,
      );

  @override
  FLSlice FLEncoder_GetBase(
    FLEncoder arg0,
  ) =>
      native.FLEncoder_GetBase(
        arg0,
      );

  @override
  void FLEncoder_SuppressTrailer(
    FLEncoder arg0,
  ) =>
      native.FLEncoder_SuppressTrailer(
        arg0,
      );

  @override
  int FLEncoder_GetNextWritePos(
    FLEncoder arg0,
  ) =>
      native.FLEncoder_GetNextWritePos(
        arg0,
      );

  @override
  int FLEncoder_LastValueWritten(
    FLEncoder arg0,
  ) =>
      native.FLEncoder_LastValueWritten(
        arg0,
      );

  @override
  bool FLEncoder_WriteValueAgain(
    FLEncoder arg0,
    int preWrittenValue,
  ) =>
      native.FLEncoder_WriteValueAgain(
        arg0,
        preWrittenValue,
      );

  @override
  FLSliceResult FLEncoder_Snip(
    FLEncoder arg0,
  ) =>
      native.FLEncoder_Snip(
        arg0,
      );

  @override
  int FLEncoder_FinishItem(
    FLEncoder arg0,
  ) =>
      native.FLEncoder_FinishItem(
        arg0,
      );

  @override
  void FLJSONEncoder_NextDocument(
    FLEncoder arg0,
  ) =>
      native.FLJSONEncoder_NextDocument(
        arg0,
      );

  @override
  ffi.Pointer<ffi.Char> FLDump(
    FLValue arg0,
  ) =>
      native.FLDump(
        arg0,
      );

  @override
  ffi.Pointer<ffi.Char> FLDumpData(
    FLSlice data,
  ) =>
      native.FLDumpData(
        data,
      );

  @override
  FLStringResult FLData_Dump(
    FLSlice data,
  ) =>
      native.FLData_Dump(
        data,
      );
}

class SymbolAddressesNative implements SymbolAddresses {
  const SymbolAddressesNative();

  @override
  ffi.Pointer<ffi.NativeFunction<NativeCBL_Release>> get CBL_Release =>
      native.addresses.CBL_Release;

  @override
  ffi.Pointer<ffi.NativeFunction<NativeCBLBlobReader_Close>>
      get CBLBlobReader_Close => native.addresses.CBLBlobReader_Close;

  @override
  ffi.Pointer<ffi.NativeFunction<NativeFLDoc_Release>> get FLDoc_Release =>
      native.addresses.FLDoc_Release;

  @override
  ffi.Pointer<ffi.NativeFunction<NativeFLEncoder_Free>> get FLEncoder_Free =>
      native.addresses.FLEncoder_Free;

  @override
  ffi.Pointer<ffi.NativeFunction<NativeFLValue_Release>> get FLValue_Release =>
      native.addresses.FLValue_Release;

  @override
  ffi.Pointer<ffi.NativeFunction<NativeFLSharedKeys_Release>>
      get FLSharedKeys_Release => native.addresses.FLSharedKeys_Release;
}
