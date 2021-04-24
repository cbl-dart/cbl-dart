#include <mutex>
#include <shared_mutex>

#include "CBL+Dart.h"
#include "Callbacks.h"
#include "Fleece+Dart.h"
#include "Utils.hh"
#include "cbl/CouchbaseLite.h"
#include "dart/dart_api_dl.h"

// Dart ------------------------------------------------------------------------

std::mutex initDartApiDLMutex;
bool initDartApiDLDone = false;

void CBLDart_InitDartApiDL(void *data) {
  const std::scoped_lock<std::mutex> lock(initDartApiDLMutex);
  if (!initDartApiDLDone) {
    Dart_InitializeApiDL(data);
    initDartApiDLDone = true;
  }
}

// -- Callbacks

Callback *CBLDart_NewCallback(Dart_Handle handle, Dart_Port sendPort) {
  return new Callback(handle, sendPort);
}

void CBLDart_Callback_Close(Callback *callback) { callback->close(); }

void CBLDart_Callback_CallForTest(Callback *callback, int64_t argument) {
  Dart_CObject argument__;
  argument__.type = Dart_CObject_kInt64;
  argument__.value.as_int64 = argument;

  Dart_CObject *argsValues[] = {&argument__};

  Dart_CObject args;
  args.type = Dart_CObject_kArray;
  args.value.as_array.length = 1;
  args.value.as_array.values = argsValues;

  CallbackCall(*callback).execute(args);
}

// Couchbase Lite --------------------------------------------------------------

// -- Log

std::shared_mutex loggingMutex;

auto originalLogCallback = CBLLog_Callback();

Callback *dartLogCallback = nullptr;

void CBLDart_LogCallbackWrapper(CBLLogDomain domain, CBLLogLevel level,
                                const char *message) {
  const std::shared_lock<std::shared_mutex> lock(loggingMutex);

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

  CallbackCall(*dartLogCallback).execute(args);
}

void CBLDart_LogCallbackFinalizer(void *context) {
  CBLDart_CBLLog_RestoreOriginalCallback();
}

void CBLDart_CBLLog_RestoreOriginalCallback() {
  const std::unique_lock<std::shared_mutex> lock(loggingMutex);
  dartLogCallback = nullptr;
  CBLLog_SetCallback(originalLogCallback);
}

void CBLDart_CBLLog_SetCallback(Callback *callback) {
  const std::unique_lock<std::shared_mutex> lock(loggingMutex);

  dartLogCallback = callback;

  if (callback == nullptr) {
    CBLLog_SetCallback(NULL);
  } else {
    callback->setFinalizer(nullptr, CBLDart_LogCallbackFinalizer);
    CBLLog_SetCallback(CBLDart_LogCallbackWrapper);
  }
}

// -- RefCounted

/**
 * Dart_HandleFinalizer for objects which are backed by a CBLRefCounted.
 */
void CBLDart_CBLRefCountedFinalizer(void *dart_callback_data, void *peer) {
  auto refCounted = reinterpret_cast<CBLRefCounted *>(peer);
  CBL_Release(refCounted);
}

/**
 * Binds a CBLRefCounted to a Dart objects lifetime.
 *
 * If \p retain is true the ref counted object will be retained. Otherwise
 * it will only be released once the Dart object is garbage collected.
 */
void CBLDart_BindCBLRefCountedToDartObject(Dart_Handle handle,
                                           CBLRefCounted *refCounted,
                                           bool retain) {
  if (retain) CBL_Retain(refCounted);

  Dart_NewFinalizableHandle_DL(handle, refCounted, 0,
                               CBLDart_CBLRefCountedFinalizer);
}

// -- Listener

void CBLDart_CBLListenerFinalizer(void *context) {
  auto listenerToken = reinterpret_cast<CBLListenerToken *>(context);
  CBLListener_Remove(listenerToken);
}

// -- Database

void CBLDart_CBLDatabase_Config(CBLDatabase *db,
                                CBLDatabaseConfiguration *config) {
  *config = CBLDatabase_Config(db);
}

bool CBLDart_SaveConflictHandlerWrapper(
    void *context, CBLDocument *documentBeingSaved,
    const CBLDocument *conflictingDocument) {
  const Callback &callback = *reinterpret_cast<Callback *>(context);

  // documentBeingSaved cannot be accessed from the Dart Isolate main thread
  // because this thread has a lock on it. So we make a copy give that to the
  // callback  and transfer the properties from the copy back to the original.
  auto documentBeingSavedCopy = CBLDocument_MutableCopy(documentBeingSaved);

  Dart_CObject documentBeingSaved_;
  documentBeingSaved_.type = Dart_CObject_kInt64;
  documentBeingSaved_.value.as_int64 =
      reinterpret_cast<int64_t>(documentBeingSavedCopy);

  Dart_CObject conflictingDocument_;
  if (conflictingDocument == NULL) {
    conflictingDocument_.type = Dart_CObject_kNull;
  } else {
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

  CallbackCall(callback, resultHandler).execute(args);

  auto newProperties = CBLDocument_MutableProperties(documentBeingSavedCopy);
  CBLDocument_SetProperties(documentBeingSaved, newProperties);
  CBLDocument_Release(documentBeingSavedCopy);

  return decision;
}

const CBLDocument *CBLDart_CBLDatabase_SaveDocumentResolving(
    CBLDatabase *db, CBLDocument *doc, Callback *conflictHandler,
    CBLError *error) {
  return CBLDatabase_SaveDocumentResolving(db, doc,
                                           CBLDart_SaveConflictHandlerWrapper,
                                           (void *)conflictHandler, error);
}

void CBLDart_DocumentChangeListenerWrapper(void *context, const CBLDatabase *db,
                                           const char *docID) {
  const Callback &callback = *reinterpret_cast<Callback *>(context);

  Dart_CObject args;
  args.type = Dart_CObject_kArray;
  args.value.as_array.length = 0;

  CallbackCall(callback).execute(args);
}

void CBLDart_CBLDatabase_AddDocumentChangeListener(const CBLDatabase *db,
                                                   const char *docID,
                                                   Callback *listener) {
  auto listenerToken = CBLDatabase_AddDocumentChangeListener(
      db, docID, CBLDart_DocumentChangeListenerWrapper, (void *)listener);

  listener->setFinalizer(listenerToken, CBLDart_CBLListenerFinalizer);
}

void CBLDart_DatabaseChangeListenerWrapper(void *context, const CBLDatabase *db,
                                           unsigned numDocs,
                                           const char **docID) {
  const Callback &callback = *reinterpret_cast<Callback *>(context);

  auto ids = new Dart_CObject[numDocs];
  auto argsValues = new Dart_CObject *[numDocs];

  for (size_t i = 0; i < numDocs; i++) {
    auto id = &ids[i];
    id->type = Dart_CObject_kString;
    id->value.as_string = const_cast<char *>(docID[i]);
    argsValues[i] = id;
  }

  Dart_CObject args;
  args.type = Dart_CObject_kArray;
  args.value.as_array.length = numDocs;
  args.value.as_array.values = argsValues;

  CallbackCall(callback).execute(args);

  delete[] ids;
  delete[] argsValues;
}

void CBLDart_CBLDatabase_AddChangeListener(const CBLDatabase *db,
                                           Callback *listener) {
  auto listenerToken = CBLDatabase_AddChangeListener(
      db, CBLDart_DatabaseChangeListenerWrapper, (void *)listener);

  listener->setFinalizer(listenerToken, CBLDart_CBLListenerFinalizer);
}

// -- Query

void CBLDart_CBLQuery_Explain(const CBLQuery *query, CBLDartSlice *result) {
  *result = CBLDart_FLSliceResultToDart(CBLQuery_Explain(query));
}

void CBLDart_CBLQuery_ColumnName(const CBLQuery *query, unsigned columnIndex,
                                 CBLDartSlice *result) {
  *result = CBLDart_FLSliceToDart(CBLQuery_ColumnName(query, columnIndex));
}

void CBLDart_QueryChangeListenerWrapper(void *context, CBLQuery *query) {
  const Callback &callback = *reinterpret_cast<Callback *>(context);

  Dart_CObject args;
  args.type = Dart_CObject_kArray;
  args.value.as_array.length = 0;
  args.value.as_array.values = NULL;

  CallbackCall(callback).execute(args);
}

CBLListenerToken *CBLDart_CBLQuery_AddChangeListener(CBLQuery *query,
                                                     Callback *listener) {
  auto listenerToken = CBLQuery_AddChangeListener(
      query, CBLDart_QueryChangeListenerWrapper, (void *)listener);

  listener->setFinalizer(listenerToken, CBLDart_CBLListenerFinalizer);

  return listenerToken;
}

// -- Blob

uint64_t CBLDart_CBLBlobReader_Read(CBLBlobReadStream *stream, void *buf,
                                    uint64_t bufSize, CBLError *outError) {
  return CBLBlobReader_Read(stream, buf, static_cast<size_t>(bufSize),
                            outError);
}

// -- Replicator

struct ReplicatorCallbackWrapperContext {
  Callback *pullFilter;
  Callback *pushFilter;
  Callback *conflictResolver;
};

std::map<CBLReplicator *, ReplicatorCallbackWrapperContext *>
    replicatorCallbackWrapperContexts;
std::mutex replicatorCallbackWrapperContexts_mutex;

bool CBLDart_ReplicatorFilterWrapper(Callback *callback, CBLDocument *document,
                                     bool isDeleted) {
  Dart_CObject documentAddress;
  documentAddress.type = Dart_CObject_kInt64;
  documentAddress.value.as_int64 = reinterpret_cast<int64_t>(document);

  Dart_CObject isDeleted_;
  isDeleted_.type = Dart_CObject_kBool;
  isDeleted_.value.as_bool = isDeleted;

  Dart_CObject *argsValues[] = {&documentAddress, &isDeleted_};

  Dart_CObject args;
  args.type = Dart_CObject_kArray;
  args.value.as_array.length = 2;
  args.value.as_array.values = argsValues;

  bool descision;

  auto resultHandler = [&descision](Dart_CObject *result) {
    descision = result->value.as_bool;
  };

  CallbackCall(*callback, resultHandler).execute(args);

  return descision;
}

bool CBLDart_ReplicatorPullFilterWrapper(void *context, CBLDocument *document,
                                         bool isDeleted) {
  auto wrapperContext =
      reinterpret_cast<ReplicatorCallbackWrapperContext *>(context);
  return CBLDart_ReplicatorFilterWrapper(wrapperContext->pullFilter, document,
                                         isDeleted);
}

bool CBLDart_ReplicatorPushFilterWrapper(void *context, CBLDocument *document,
                                         bool isDeleted) {
  auto wrapperContext =
      reinterpret_cast<ReplicatorCallbackWrapperContext *>(context);
  return CBLDart_ReplicatorFilterWrapper(wrapperContext->pushFilter, document,
                                         isDeleted);
}

const CBLDocument *CBLDart_ReplicatorConflictResolverWrapper(
    void *context, const char *documentID, const CBLDocument *localDocument,
    const CBLDocument *remoteDocument) {
  auto wrapperContext =
      reinterpret_cast<ReplicatorCallbackWrapperContext *>(context);
  auto callback = wrapperContext->conflictResolver;

  Dart_CObject documentID_;
  documentID_.type = Dart_CObject_kString;
  documentID_.value.as_string = const_cast<char *>(documentID);

  Dart_CObject local;
  if (localDocument == NULL) {
    local.type = Dart_CObject_kNull;
  } else {
    local.type = Dart_CObject_kInt64;
    local.value.as_int64 = reinterpret_cast<int64_t>(localDocument);
  }

  Dart_CObject remote;
  if (remoteDocument == NULL) {
    remote.type = Dart_CObject_kNull;
  } else {
    remote.type = Dart_CObject_kInt64;
    remote.value.as_int64 = reinterpret_cast<int64_t>(remoteDocument);
  }

  Dart_CObject *argsValues[] = {&documentID_, &local, &remote};

  Dart_CObject args;
  args.type = Dart_CObject_kArray;
  args.value.as_array.length = 3;
  args.value.as_array.values = argsValues;

  const CBLDocument *descision;

  auto resultHandler = [&descision](Dart_CObject *result) {
    descision = result->type == Dart_CObject_kNull
                    ? NULL
                    : reinterpret_cast<const CBLDocument *>(
                          CBLDart_CObject_getIntValueAsInt64(result));
  };

  CallbackCall(*callback, resultHandler).execute(args);

  return descision;
}

CBLReplicator *CBLDart_CBLReplicator_New(CBLDartReplicatorConfiguration *config,
                                         CBLError *error) {
  CBLReplicatorConfiguration _config;
  _config.database = config->database;
  _config.endpoint = config->endpoint;
  _config.replicatorType =
      static_cast<CBLReplicatorType>(config->replicatorType);
  _config.continuous = config->continuous;
  _config.authenticator = config->authenticator;
  _config.proxy = config->proxy;
  _config.headers = config->headers;
  _config.pinnedServerCertificate = config->pinnedServerCertificate == NULL
                                        ? kFLSliceNull
                                        : *config->pinnedServerCertificate;
  _config.trustedRootCertificates = config->trustedRootCertificates == NULL
                                        ? kFLSliceNull
                                        : *config->trustedRootCertificates;
  _config.channels = config->channels;
  _config.documentIDs = config->documentIDs;
  _config.pullFilter = config->pullFilter == nullptr
                           ? NULL
                           : CBLDart_ReplicatorPullFilterWrapper;
  _config.pushFilter = config->pushFilter == nullptr
                           ? NULL
                           : CBLDart_ReplicatorPushFilterWrapper;
  _config.conflictResolver = config->conflictResolver == nullptr
                                 ? NULL
                                 : CBLDart_ReplicatorConflictResolverWrapper;

  auto context = new ReplicatorCallbackWrapperContext;
  context->pullFilter = config->pullFilter;
  context->pushFilter = config->pushFilter;
  context->conflictResolver = config->conflictResolver;
  _config.context = context;

  auto replicator = CBLReplicator_New(&_config, error);

  // Associate callback context with this instance so we can it released
  // when the replicator is released.
  std::scoped_lock<std::mutex> lock(replicatorCallbackWrapperContexts_mutex);
  replicatorCallbackWrapperContexts[replicator] = context;

  return replicator;
}

void CBLDart_ReplicatorFinalizer(void *dart_callback_data, void *peer) {
  auto replicator = reinterpret_cast<CBLReplicator *>(peer);

  CBLReplicator_Release(replicator);

  // Clean up context for callback wrapper
  std::scoped_lock<std::mutex> lock(replicatorCallbackWrapperContexts_mutex);
  auto callbackWrapperContext = replicatorCallbackWrapperContexts[replicator];
  replicatorCallbackWrapperContexts.erase(replicator);
  delete callbackWrapperContext;
}

void CBLDart_BindReplicatorToDartObject(Dart_Handle handle,
                                        CBLReplicator *replicator) {
  Dart_NewFinalizableHandle_DL(handle, reinterpret_cast<void *>(replicator), 0,
                               CBLDart_ReplicatorFinalizer);
}

bool CBLDart_CBLReplicator_IsDocumentPending(CBLReplicator *replicator,
                                             char *docId, CBLError *error) {
  return CBLReplicator_IsDocumentPending(replicator, FLStr(docId), error);
}

void CBLDart_Replicator_ChangeListenerWrapper(
    void *context, CBLReplicator *replicator,
    const CBLReplicatorStatus *status) {
  auto callback = reinterpret_cast<Callback *>(context);

  Dart_CObject statusAddress;
  statusAddress.type = Dart_CObject_kInt64;
  statusAddress.value.as_int64 = reinterpret_cast<int64_t>(status);

  Dart_CObject *argsValues[] = {&statusAddress};

  Dart_CObject args;
  args.type = Dart_CObject_kArray;
  args.value.as_array.length = 1;
  args.value.as_array.values = argsValues;

  // Only required to make the call blocking.
  auto resultHandler = [](Dart_CObject *result) {};

  CallbackCall(*callback, resultHandler).execute(args);
}

void CBLDart_CBLReplicator_AddChangeListener(CBLReplicator *replicator,
                                             Callback *listener) {
  auto listenerToken = CBLReplicator_AddChangeListener(
      replicator, CBLDart_Replicator_ChangeListenerWrapper, (void *)listener);

  listener->setFinalizer(listenerToken, CBLDart_CBLListenerFinalizer);
}

void CBLDart_Replicator_DocumentListenerWrapper(
    void *context, CBLReplicator *replicator, bool isPush,
    unsigned numDocuments, const CBLReplicatedDocument *documents) {
  auto callback = reinterpret_cast<Callback *>(context);

  Dart_CObject isPush_;
  isPush_.type = Dart_CObject_kBool;
  isPush_.value.as_bool = isPush;

  auto dartDocuments = new CBLDartReplicatedDocument[numDocuments];

  for (size_t i = 0; i < numDocuments; i++) {
    auto document = &documents[i];
    auto dartDocument = &dartDocuments[i];

    dartDocument->ID = document->ID;
    dartDocument->flags = document->flags;
    dartDocument->error = document->error;
  }

  Dart_CObject numDocuments_;
  numDocuments_.type = Dart_CObject_kInt64;
  numDocuments_.value.as_int64 = numDocuments;

  Dart_CObject documents_;
  documents_.type = Dart_CObject_kInt64;
  documents_.value.as_int64 = reinterpret_cast<int64_t>(dartDocuments);

  Dart_CObject *argsValues[] = {&isPush_, &numDocuments_, &documents_};

  Dart_CObject args;
  args.type = Dart_CObject_kArray;
  args.value.as_array.length = 3;
  args.value.as_array.values = argsValues;

  // Only required to make the call blocking.
  auto resultHandler = [](Dart_CObject *result) {};

  CallbackCall(*callback, resultHandler).execute(args);

  delete[] dartDocuments;
}

void CBLDart_CBLReplicator_AddDocumentListener(CBLReplicator *replicator,
                                               Callback *listener) {
  auto listenerToken = CBLReplicator_AddDocumentListener(
      replicator, CBLDart_Replicator_DocumentListenerWrapper, (void *)listener);

  listener->setFinalizer(listenerToken, CBLDart_CBLListenerFinalizer);
}
