
#pragma once

#include "Callbacks.h"
#include "cbldart_export.h"
#include "cbl/CouchbaseLite.h"
#include "dart/dart_api_dl.h"
#include "FleeceDart.h"

/**
 * This is a compatibility layer to allow Dart code to use the Couchbase Lite C 
 * API. Some method signatures are incompatible with Dart's FFI capabilities.
 * 
 * This layer is also where memory management of objects from the Couchbase Lite
 * C API is integrated with the garbage collection of Dart objects.
 */

extern "C"
{
    // Dart --------------------------------------------------------------------

    CBLDART_EXPORT
    void CBLDart_InitDartApiDL(void *data);

    // -- Callbacks

    CBLDART_EXPORT
    CallbackIsolate *
    CBLDart_NewCallbackIsolate(Dart_Handle handle,
                               Dart_Port sendPort);

    CBLDART_EXPORT
    CallbackId CBLDart_CallbackIsolate_RegisterCallback(
        CallbackIsolate *isolate);

    CBLDART_EXPORT
    void CBLDart_CallbackIsolate_UnregisterCallback(CallbackId callbackId,
                                                    bool runFinalizer);

    CBLDART_EXPORT
    void CBLDart_Callback_CallForTest(CallbackId callbackId, int64_t argument);

    // Couchbase Lite ----------------------------------------------------------

    // -- Log

    CBLDART_EXPORT
    void CBLDart_CBLLog_RestoreOriginalCallback();

    CBLDART_EXPORT
    void CBLDart_CBLLog_SetCallback(CallbackId callbackId);

    // -- RefCounted

    /**
     * Binds a CBLRefCounted to a Dart objects lifetime.
     * 
     * If \p retain is true the ref counted object will be retained. Otherwise
     * it will only be released once the Dart object is garbage collected.
     */
    CBLDART_EXPORT
    void CBLDart_BindCBLRefCountedToDartObject(
        Dart_Handle handle,
        CBLRefCounted *refCounted,
        bool retain);

    // -- Database

    CBLDART_EXPORT
    void CBLDart_CBLDatabase_Config(CBLDatabase *db,
                                    CBLDatabaseConfiguration *config);

    CBLDART_EXPORT
    void CBLDart_Database_BindToDartObject(Dart_Handle handle,
                                           CBLDatabase *db);

    CBLDART_EXPORT
    const CBLDocument *CBLDart_CBLDatabase_SaveDocumentResolving(
        CBLDatabase *db,
        CBLDocument *doc,
        CallbackId conflictHandler,
        CBLError *error);

    CBLDART_EXPORT
    void CBLDart_CBLDatabase_AddDocumentChangeListener(
        const CBLDatabase *db,
        const char *docID,
        CallbackId listener);

    CBLDART_EXPORT
    void CBLDart_CBLDatabase_AddChangeListener(const CBLDatabase *db,
                                               CallbackId listener);

    CBLDART_EXPORT
    bool CBLDart_CBLDatabase_CreateIndex(CBLDatabase *db,
                                         const char *name,
                                         CBLIndexSpec *spec,
                                         CBLError *error);

    // -- Query

    CBLDART_EXPORT
    void CBLDart_CBLQuery_Explain(const CBLQuery *query,
                                  CBLDart_FLSlice *result);

    CBLDART_EXPORT
    void CBLDart_CBLQuery_ColumnName(const CBLQuery *query,
                                     unsigned columnIndex,
                                     CBLDart_FLSlice *result);

    CBLDART_EXPORT
    CBLListenerToken *CBLDart_CBLQuery_AddChangeListener(CBLQuery *query,
                                                         CallbackId listener);
}
