// AUTO GENERATED FILE, DO NOT EDIT.
//
// ignore_for_file: type=lint, unused_import
import 'dart:ffi' as ffi;

import 'package:cbl/src/bindings/cblitedart.dart';
import 'package:cbl/src/bindings/cblite.dart' as imp$1;
import './cblitedart.dart' as native;

class cblitedartNative implements cblitedart {
  const cblitedartNative();

  @override
  final addresses = const SymbolAddressesNative();

  @override
  void CBLDart_FLSliceResult_RetainByBuf(
    ffi.Pointer<ffi.Void> buf,
  ) =>
      native.CBLDart_FLSliceResult_RetainByBuf(
        buf,
      );

  @override
  void CBLDart_FLSliceResult_ReleaseByBuf(
    ffi.Pointer<ffi.Void> buf,
  ) =>
      native.CBLDart_FLSliceResult_ReleaseByBuf(
        buf,
      );

  @override
  ffi.Pointer<KnownSharedKeys> CBLDart_KnownSharedKeys_New() =>
      native.CBLDart_KnownSharedKeys_New();

  @override
  void CBLDart_KnownSharedKeys_Delete(
    ffi.Pointer<KnownSharedKeys> keys,
  ) =>
      native.CBLDart_KnownSharedKeys_Delete(
        keys,
      );

  @override
  void CBLDart_GetLoadedFLValue(
    imp$1.FLValue value,
    ffi.Pointer<CBLDart_LoadedFLValue> out,
  ) =>
      native.CBLDart_GetLoadedFLValue(
        value,
        out,
      );

  @override
  void CBLDart_FLArray_GetLoadedFLValue(
    imp$1.FLArray array,
    int index,
    ffi.Pointer<CBLDart_LoadedFLValue> out,
  ) =>
      native.CBLDart_FLArray_GetLoadedFLValue(
        array,
        index,
        out,
      );

  @override
  void CBLDart_FLDict_GetLoadedFLValue(
    imp$1.FLDict dict,
    imp$1.FLString key,
    ffi.Pointer<CBLDart_LoadedFLValue> out,
  ) =>
      native.CBLDart_FLDict_GetLoadedFLValue(
        dict,
        key,
        out,
      );

  @override
  ffi.Pointer<CBLDart_FLDictIterator> CBLDart_FLDictIterator_Begin(
    imp$1.FLDict dict,
    ffi.Pointer<KnownSharedKeys> knownSharedKeys,
    ffi.Pointer<CBLDart_LoadedDictKey> keyOut,
    ffi.Pointer<CBLDart_LoadedFLValue> valueOut,
    bool deleteOnDone,
    bool preLoad,
  ) =>
      native.CBLDart_FLDictIterator_Begin(
        dict,
        knownSharedKeys,
        keyOut,
        valueOut,
        deleteOnDone,
        preLoad,
      );

  @override
  void CBLDart_FLDictIterator_Delete(
    ffi.Pointer<CBLDart_FLDictIterator> iterator,
  ) =>
      native.CBLDart_FLDictIterator_Delete(
        iterator,
      );

  @override
  bool CBLDart_FLDictIterator_Next(
    ffi.Pointer<CBLDart_FLDictIterator> iterator,
  ) =>
      native.CBLDart_FLDictIterator_Next(
        iterator,
      );

  @override
  ffi.Pointer<CBLDart_FLArrayIterator> CBLDart_FLArrayIterator_Begin(
    imp$1.FLArray array,
    ffi.Pointer<CBLDart_LoadedFLValue> valueOut,
    bool deleteOnDone,
  ) =>
      native.CBLDart_FLArrayIterator_Begin(
        array,
        valueOut,
        deleteOnDone,
      );

  @override
  void CBLDart_FLArrayIterator_Delete(
    ffi.Pointer<CBLDart_FLArrayIterator> iterator,
  ) =>
      native.CBLDart_FLArrayIterator_Delete(
        iterator,
      );

  @override
  bool CBLDart_FLArrayIterator_Next(
    ffi.Pointer<CBLDart_FLArrayIterator> iterator,
  ) =>
      native.CBLDart_FLArrayIterator_Next(
        iterator,
      );

  @override
  bool CBLDart_FLEncoder_WriteArrayValue(
    imp$1.FLEncoder encoder,
    imp$1.FLArray array,
    int index,
  ) =>
      native.CBLDart_FLEncoder_WriteArrayValue(
        encoder,
        array,
        index,
      );

  @override
  bool CBLDart_CpuSupportsAVX2() => native.CBLDart_CpuSupportsAVX2();

  @override
  int CBLDart_Initialize(
    ffi.Pointer<ffi.Void> dartInitializeDlData,
    ffi.Pointer<ffi.Void> cblInitContext,
    ffi.Pointer<CBLError> errorOut,
  ) =>
      native.CBLDart_Initialize(
        dartInitializeDlData,
        cblInitContext,
        errorOut,
      );

  @override
  CBLDart_AsyncCallback CBLDart_AsyncCallback_New(
    int id,
    int sendPort,
    bool debug,
  ) =>
      native.CBLDart_AsyncCallback_New(
        id,
        sendPort,
        debug,
      );

  @override
  void CBLDart_AsyncCallback_Delete(
    CBLDart_AsyncCallback callback,
  ) =>
      native.CBLDart_AsyncCallback_Delete(
        callback,
      );

  @override
  void CBLDart_AsyncCallback_Close(
    CBLDart_AsyncCallback callback,
  ) =>
      native.CBLDart_AsyncCallback_Close(
        callback,
      );

  @override
  void CBLDart_AsyncCallback_CallForTest(
    CBLDart_AsyncCallback callback,
    int argument,
  ) =>
      native.CBLDart_AsyncCallback_CallForTest(
        callback,
        argument,
      );

  @override
  void CBLDart_Completer_Complete(
    CBLDart_Completer completer,
    ffi.Pointer<ffi.Void> result,
  ) =>
      native.CBLDart_Completer_Complete(
        completer,
        result,
      );

  @override
  int CBLDart_AllocateIsolateId() => native.CBLDart_AllocateIsolateId();

  @override
  void CBLDart_SetCurrentIsolateId(
    int isolateId,
  ) =>
      native.CBLDart_SetCurrentIsolateId(
        isolateId,
      );

  @override
  int CBLDart_GetCurrentIsolateId() => native.CBLDart_GetCurrentIsolateId();

  @override
  bool CBLDart_CBLLog_SetCallback(
    CBLDart_AsyncCallback callback,
  ) =>
      native.CBLDart_CBLLog_SetCallback(
        callback,
      );

  @override
  void CBLDart_CBLLog_SetCallbackLevel(
    imp$1.DartCBLLogLevel level,
  ) =>
      native.CBLDart_CBLLog_SetCallbackLevel(
        level,
      );

  @override
  bool CBLDart_CBLLog_SetFileConfig(
    ffi.Pointer<CBLLogFileConfiguration> config,
    ffi.Pointer<CBLError> errorOut,
  ) =>
      native.CBLDart_CBLLog_SetFileConfig(
        config,
        errorOut,
      );

  @override
  ffi.Pointer<CBLLogFileConfiguration> CBLDart_CBLLog_GetFileConfig() =>
      native.CBLDart_CBLLog_GetFileConfig();

  @override
  bool CBLDart_CBLLog_SetSentryBreadcrumbs(
    bool enabled,
  ) =>
      native.CBLDart_CBLLog_SetSentryBreadcrumbs(
        enabled,
      );

  @override
  CBLDart_CBLDatabaseConfiguration CBLDart_CBLDatabaseConfiguration_Default() =>
      native.CBLDart_CBLDatabaseConfiguration_Default();

  @override
  bool CBLDart_CBL_CopyDatabase(
    imp$1.FLString fromPath,
    imp$1.FLString toName,
    ffi.Pointer<CBLDart_CBLDatabaseConfiguration> config,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDart_CBL_CopyDatabase(
        fromPath,
        toName,
        config,
        outError,
      );

  @override
  ffi.Pointer<CBLDatabase> CBLDart_CBLDatabase_Open(
    imp$1.FLString name,
    ffi.Pointer<CBLDart_CBLDatabaseConfiguration> config,
    ffi.Pointer<CBLError> errorOut,
  ) =>
      native.CBLDart_CBLDatabase_Open(
        name,
        config,
        errorOut,
      );

  @override
  void CBLDart_CBLDatabase_Release(
    ffi.Pointer<CBLDatabase> database,
  ) =>
      native.CBLDart_CBLDatabase_Release(
        database,
      );

  @override
  bool CBLDart_CBLDatabase_Close(
    ffi.Pointer<CBLDatabase> database,
    bool andDelete,
    ffi.Pointer<CBLError> errorOut,
  ) =>
      native.CBLDart_CBLDatabase_Close(
        database,
        andDelete,
        errorOut,
      );

  @override
  void CBLDart_CBLCollection_AddDocumentChangeListener(
    ffi.Pointer<CBLDatabase> db,
    ffi.Pointer<CBLCollection> collection,
    imp$1.FLString docID,
    CBLDart_AsyncCallback listener,
  ) =>
      native.CBLDart_CBLCollection_AddDocumentChangeListener(
        db,
        collection,
        docID,
        listener,
      );

  @override
  void CBLDart_CBLCollection_AddChangeListener(
    ffi.Pointer<CBLDatabase> db,
    ffi.Pointer<CBLCollection> collection,
    CBLDart_AsyncCallback listener,
  ) =>
      native.CBLDart_CBLCollection_AddChangeListener(
        db,
        collection,
        listener,
      );

  @override
  bool CBLDart_CBLCollection_CreateIndex(
    ffi.Pointer<CBLCollection> collection,
    imp$1.FLString name,
    CBLDart_CBLIndexSpec indexSpec,
    ffi.Pointer<CBLError> errorOut,
  ) =>
      native.CBLDart_CBLCollection_CreateIndex(
        collection,
        name,
        indexSpec,
        errorOut,
      );

  @override
  ffi.Pointer<CBLListenerToken> CBLDart_CBLQuery_AddChangeListener(
    ffi.Pointer<CBLDatabase> db,
    ffi.Pointer<CBLQuery> query,
    CBLDart_AsyncCallback listener,
  ) =>
      native.CBLDart_CBLQuery_AddChangeListener(
        db,
        query,
        listener,
      );

  @override
  CBLDart_PredictiveModel CBLDart_PredictiveModel_New(
    imp$1.FLString name,
    int isolateId,
    CBLDart_PredictiveModel_PredictionSync predictionSync,
    CBLDart_PredictiveModel_PredictionAsync predictionAsync,
    CBLDart_PredictiveModel_Unregistered unregistered,
  ) =>
      native.CBLDart_PredictiveModel_New(
        name,
        isolateId,
        predictionSync,
        predictionAsync,
        unregistered,
      );

  @override
  void CBLDart_PredictiveModel_Delete(
    CBLDart_PredictiveModel model,
  ) =>
      native.CBLDart_PredictiveModel_Delete(
        model,
      );

  @override
  FLSliceResult CBLDart_CBLBlobReader_Read(
    ffi.Pointer<CBLBlobReadStream> stream,
    int bufferSize,
    ffi.Pointer<CBLError> outError,
  ) =>
      native.CBLDart_CBLBlobReader_Read(
        stream,
        bufferSize,
        outError,
      );

  @override
  ffi.Pointer<CBLReplicator> CBLDart_CBLReplicator_Create(
    ffi.Pointer<CBLDart_ReplicatorConfiguration> config,
    ffi.Pointer<CBLError> errorOut,
  ) =>
      native.CBLDart_CBLReplicator_Create(
        config,
        errorOut,
      );

  @override
  void CBLDart_CBLReplicator_Release(
    ffi.Pointer<CBLReplicator> replicator,
  ) =>
      native.CBLDart_CBLReplicator_Release(
        replicator,
      );

  @override
  void CBLDart_CBLReplicator_AddChangeListener(
    ffi.Pointer<CBLDatabase> db,
    ffi.Pointer<CBLReplicator> replicator,
    CBLDart_AsyncCallback listenerId,
  ) =>
      native.CBLDart_CBLReplicator_AddChangeListener(
        db,
        replicator,
        listenerId,
      );

  @override
  void CBLDart_CBLReplicator_AddDocumentReplicationListener(
    ffi.Pointer<CBLDatabase> db,
    ffi.Pointer<CBLReplicator> replicator,
    CBLDart_AsyncCallback listenerId,
  ) =>
      native.CBLDart_CBLReplicator_AddDocumentReplicationListener(
        db,
        replicator,
        listenerId,
      );
}

class SymbolAddressesNative implements SymbolAddresses {
  const SymbolAddressesNative();

  @override
  ffi.Pointer<ffi.NativeFunction<NativeCBLDart_FLSliceResult_ReleaseByBuf>>
      get CBLDart_FLSliceResult_ReleaseByBuf =>
          native.addresses.CBLDart_FLSliceResult_ReleaseByBuf;

  @override
  ffi.Pointer<ffi.NativeFunction<NativeCBLDart_KnownSharedKeys_Delete>>
      get CBLDart_KnownSharedKeys_Delete =>
          native.addresses.CBLDart_KnownSharedKeys_Delete;

  @override
  ffi.Pointer<ffi.NativeFunction<NativeCBLDart_FLDictIterator_Delete>>
      get CBLDart_FLDictIterator_Delete =>
          native.addresses.CBLDart_FLDictIterator_Delete;

  @override
  ffi.Pointer<ffi.NativeFunction<NativeCBLDart_FLArrayIterator_Delete>>
      get CBLDart_FLArrayIterator_Delete =>
          native.addresses.CBLDart_FLArrayIterator_Delete;

  @override
  ffi.Pointer<ffi.NativeFunction<NativeCBLDart_AsyncCallback_Delete>>
      get CBLDart_AsyncCallback_Delete =>
          native.addresses.CBLDart_AsyncCallback_Delete;

  @override
  ffi.Pointer<ffi.NativeFunction<NativeCBLDart_CBLDatabase_Release>>
      get CBLDart_CBLDatabase_Release =>
          native.addresses.CBLDart_CBLDatabase_Release;

  @override
  ffi.Pointer<ffi.NativeFunction<NativeCBLDart_PredictiveModel_Delete>>
      get CBLDart_PredictiveModel_Delete =>
          native.addresses.CBLDart_PredictiveModel_Delete;

  @override
  ffi.Pointer<ffi.NativeFunction<NativeCBLDart_CBLReplicator_Release>>
      get CBLDart_CBLReplicator_Release =>
          native.addresses.CBLDart_CBLReplicator_Release;
}
