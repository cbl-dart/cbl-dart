#include "CBLDart.h"

#include <mutex>
#include <shared_mutex>

#include "Callbacks.h"
#include "cbl/CouchbaseLite.h"
#include "dart/dart_api_dl.h"
#include "FleeceDart.h"

// Dart ------------------------------------------------------------------------

std::mutex initDartApiDLMutex;
bool initDartApiDLDone = false;

void CBLDart_InitDartApiDL(void *data)
{
    const std::scoped_lock lock(initDartApiDLMutex);
    if (!initDartApiDLDone)
    {
        Dart_InitializeApiDL(data);
        initDartApiDLDone = true;
    }
}

// -- Callbacks

CallbackIsolate *CBLDart_NewCallbackIsolate(Dart_Handle handle,
                                            Dart_Port sendPort)
{
    return new CallbackIsolate(handle, sendPort);
}

CallbackId CBLDart_CallbackIsolate_RegisterCallback(CallbackIsolate *isolate)
{
    return isolate->registerCallback();
}

void CBLDart_CallbackIsolate_UnregisterCallback(CallbackId callbackId,
                                                bool runFinalizer)
{
    auto isolate = CallbackIsolate::getForCallbackId(callbackId);
    assert(isolate != nullptr);

    isolate->unregisterCallback(callbackId, runFinalizer);
}

void CBLDart_Callback_CallForTest(CallbackId callbackId, int64_t argument)
{
    Dart_CObject argument__;
    argument__.type = Dart_CObject_kInt64;
    argument__.value.as_int64 = argument;

    Dart_CObject *argsValues[] = {&argument__};

    Dart_CObject args;
    args.type = Dart_CObject_kArray;
    args.value.as_array.length = 1;
    args.value.as_array.values = argsValues;

    CallbackCall().execute(callbackId, &args);
}

// Couchbase Lite --------------------------------------------------------------

// -- Log

std::mutex logApiMutex;

auto originalLogCallback = CBLLog_Callback();

CallbackId dartLogCallbackId = NULL_CALLBACK;

void CBLDart_LogCallbackWrapper(CBLLogDomain domain,
                                CBLLogLevel level,
                                const char *message)
{
    Dart_CObject domain_;
    domain_.type = Dart_CObject_kInt32;
    domain_.value.as_int32 = int32_t(domain);

    Dart_CObject level_;
    level_.type = Dart_CObject_kInt32;
    level_.value.as_int32 = int32_t(level);

    Dart_CObject message_;
    message_.type = Dart_CObject_kString;
    message_.value.as_string = const_cast<char *>(message);

    Dart_CObject *argsValues[] = {&domain_, &level_, &message_};

    Dart_CObject args;
    args.type = Dart_CObject_kArray;
    args.value.as_array.length = 3;
    args.value.as_array.values = argsValues;

    CallbackCall().execute(dartLogCallbackId, &args);
}

void CBLDart_LogCallbackFinalizer(CallbackId callbackId,
                                  void *context)
{
    const std::scoped_lock lock(logApiMutex);
    if (dartLogCallbackId == callbackId)
    {
        dartLogCallbackId = NULL_CALLBACK;
        CBLLog_SetCallback(originalLogCallback);
    }
}

void CBLDart_CBLLog_RestoreOriginalCallback()
{
    const std::scoped_lock lock(logApiMutex);

    CBLLog_SetCallback(originalLogCallback);
}

void CBLDart_CBLLog_SetCallback(CallbackId callbackId)
{
    const std::scoped_lock lock(logApiMutex);
    if (dartLogCallbackId == callbackId)
        return;

    if (dartLogCallbackId != NULL_CALLBACK)
    {
        CallbackIsolate::getForCallbackId(dartLogCallbackId)
            ->removeCallbackFinalizer(dartLogCallbackId);
    }

    if (callbackId != NULL_CALLBACK)
    {
        CallbackIsolate::getForCallbackId(callbackId)
            ->setCallbackFinalizer(callbackId,
                                   nullptr,
                                   CBLDart_LogCallbackFinalizer);
    }

    dartLogCallbackId = callbackId;

    if (callbackId == NULL_CALLBACK)
    {
        CBLLog_SetCallback(NULL);
    }
    else
    {
        CBLLog_SetCallback(CBLDart_LogCallbackWrapper);
    }
}

// -- RefCounted

/**
 * Dart_HandleFinalizer for objects which are backed by a CBLRefCounted.
 */
void CBLDart_CBLRefCountedFinalizer(void *dart_callback_data,
                                    void *peer)
{
    auto refCounted = reinterpret_cast<CBLRefCounted *>(peer);
    CBL_Release(refCounted);
}

/**
 * Binds a CBLRefCounted to a Dart objects lifetime.
 * 
 * If \p retain is true the ref counted object will be retained. Otherwise
 * it will only be released once the Dart object is garbage collected.
 */
void CBLDart_BindCBLRefCountedToDartObject(
    Dart_Handle handle,
    CBLRefCounted *refCounted,
    bool retain)
{
    if (retain)
        CBL_Retain(refCounted);

    Dart_NewWeakPersistentHandle_DL(
        handle,
        refCounted,
        0,
        CBLDart_CBLRefCountedFinalizer);
}

// -- Listener

void CBLDart_CBLListenerFinalizer(CallbackId callbackId,
                                  void *context)
{
    auto listenerToken = reinterpret_cast<CBLListenerToken *>(context);
    CBLListener_Remove(listenerToken);
}

// -- Database

void CBLDart_CBLDatabase_Config(CBLDatabase *db,
                                CBLDatabaseConfiguration *config)
{
    *config = CBLDatabase_Config(db);
}

void CBLDart_Database_BindToDartObject(Dart_Handle handle,
                                       CBLDatabase *db)
{
    Dart_NewWeakPersistentHandle_DL(
        handle,
        db,
        0,
        CBLDart_CBLRefCountedFinalizer);
}

bool CBLDart_SaveConflictHandlerWrapper(void *context,
                                        CBLDocument *documentBeingSaved,
                                        const CBLDocument *conflictingDocument)
{
    auto conflictHandler = reinterpret_cast<CallbackId>(context);

    // documentBeingSaved cannot be accessed from the Dart Isolate main thread
    // because this thread has a lock on it. So we make a copy give that to the
    // callback  and transfer the properties from the copy back to the original.
    auto documentBeingSavedCopy = CBLDocument_MutableCopy(documentBeingSaved);

    Dart_CObject documentBeingSaved_;
    documentBeingSaved_.type = Dart_CObject_kInt64;
    documentBeingSaved_.value.as_int64 =
        reinterpret_cast<int64_t>(documentBeingSavedCopy);

    Dart_CObject conflictingDocument_;
    if (conflictingDocument == NULL)
    {
        conflictingDocument_.type = Dart_CObject_kNull;
    }
    else
    {
        conflictingDocument_.type = Dart_CObject_kInt64;
        conflictingDocument_.value.as_int64 =
            reinterpret_cast<int64_t>(conflictingDocument);
    }

    Dart_CObject *argsValues[] = {&documentBeingSaved_, &conflictingDocument_};

    Dart_CObject args;
    args.type = Dart_CObject_kArray;
    args.value.as_array.length = 2;
    args.value.as_array.values = argsValues;

    bool decision;

    auto resultHandler = [&decision](Dart_CObject *result) {
        decision = result->value.as_bool;
    };

    CallbackCall(resultHandler).execute(conflictHandler, &args);

    auto newProperties = CBLDocument_MutableProperties(documentBeingSavedCopy);
    CBLDocument_SetProperties(documentBeingSaved, newProperties);
    CBLDocument_Release(documentBeingSavedCopy);

    return decision;
}

const CBLDocument *CBLDart_CBLDatabase_SaveDocumentResolving(
    CBLDatabase *db,
    CBLDocument *doc,
    CallbackId conflictHandler,
    CBLError *error)
{
    return CBLDatabase_SaveDocumentResolving(
        db,
        doc,
        CBLDart_SaveConflictHandlerWrapper,
        (void *)conflictHandler,
        error);
}

void CBLDart_DocumentChangeListenerWrapper(void *context,
                                           const CBLDatabase *db,
                                           const char *docID)
{
    auto callbackId = CallbackId(context);

    Dart_CObject id;
    id.type = Dart_CObject_kString;
    id.value.as_string = const_cast<char *>(docID);

    Dart_CObject *argsValues[] = {&id};

    Dart_CObject args;
    args.type = Dart_CObject_kArray;
    args.value.as_array.length = 1;
    args.value.as_array.values = argsValues;

    CallbackCall().execute(callbackId, &args);
}

void CBLDart_CBLDatabase_AddDocumentChangeListener(
    const CBLDatabase *db,
    const char *docID,
    CallbackId listener)
{
    auto listenerToken = CBLDatabase_AddDocumentChangeListener(
        db,
        docID,
        CBLDart_DocumentChangeListenerWrapper,
        (void *)listener);

    CallbackIsolate::getForCallbackId(listener)->setCallbackFinalizer(
        listener,
        listenerToken,
        CBLDart_CBLListenerFinalizer);
}

void CBLDart_DatabaseChangeListenerWrapper(void *context,
                                           const CBLDatabase *db,
                                           unsigned numDocs,
                                           const char **docID)
{
    auto callbackId = CallbackId(context);

    auto ids = (Dart_CObject *)malloc(sizeof(Dart_CObject) * numDocs);
    auto argsValues = (Dart_CObject **)malloc(sizeof(Dart_CObject *) * numDocs);

    for (size_t i = 0; i < numDocs; i++)
    {
        auto id = ids[i];
        id.type = Dart_CObject_kString;
        id.value.as_string = const_cast<char *>(docID[i]);
        argsValues[i] = &id;
    }

    Dart_CObject args;
    args.type = Dart_CObject_kArray;
    args.value.as_array.length = numDocs;
    args.value.as_array.values = argsValues;

    CallbackCall().execute(callbackId, &args);

    free(ids);
    free(argsValues);
}

void CBLDart_CBLDatabase_AddChangeListener(const CBLDatabase *db,
                                           CallbackId listener)
{
    auto listenerToken = CBLDatabase_AddChangeListener(
        db,
        CBLDart_DatabaseChangeListenerWrapper,
        (void *)listener);

    CallbackIsolate::getForCallbackId(listener)->setCallbackFinalizer(
        listener,
        listenerToken,
        CBLDart_CBLListenerFinalizer);
}

bool CBLDart_CBLDatabase_CreateIndex(CBLDatabase *db,
                                     const char *name,
                                     CBLIndexSpec *spec,
                                     CBLError *error)
{
    return CBLDatabase_CreateIndex(db, name, *spec, error);
}

// -- Query

void CBLDart_CBLQuery_Explain(const CBLQuery *query,
                              CBLDart_FLSlice *result)
{
    *result = CBLDart_FLSliceResultToDart(CBLQuery_Explain(query));
}

void CBLDart_CBLQuery_ColumnName(const CBLQuery *query,
                                 unsigned columnIndex,
                                 CBLDart_FLSlice *result)
{
    *result = CBLDart_FLSliceToDart(CBLQuery_ColumnName(query, columnIndex));
}

void CBLDart_QueryChangeListenerWrapper(void *context,
                                        CBLQuery *query _cbl_nonnull)
{
    auto callbackId = CallbackId(context);

    Dart_CObject args;
    args.type = Dart_CObject_kArray;
    args.value.as_array.length = 0;
    args.value.as_array.values = NULL;

    CallbackCall().execute(callbackId, &args);
}

CBLListenerToken *CBLDart_CBLQuery_AddChangeListener(CBLQuery *query,
                                                     CallbackId listener)
{
    auto listenerToken = CBLQuery_AddChangeListener(
        query,
        CBLDart_QueryChangeListenerWrapper,
        (void *)listener);

    CallbackIsolate::getForCallbackId(listener)->setCallbackFinalizer(
        listener,
        listenerToken,
        CBLDart_CBLListenerFinalizer);

    return listenerToken;
}
