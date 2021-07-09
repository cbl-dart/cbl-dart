#include <map>
#include <mutex>
#include <shared_mutex>

#include "Callbacks.h"
#include "CBL+Dart.h"
#include "dart/dart_api_dl.h"
#include "Fleece+Dart.h"
#include "Utils.hh"

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

Callback *CBLDart_Callback_New(Dart_Handle object, Dart_Port sendPort) {
  return new Callback(object, sendPort);
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

// -- Base

CBLDart_FLStringResult CBLDart_CBLError_Message(CBLError *error) {
  return CBLDart_FLStringResultToDart(CBLError_Message(error));
}

/**
 * Dart_HandleFinalizer for objects which are backed by a CBLRefCounted.
 */
void CBLDart_CBLRefCountedFinalizer(void *dart_callback_data, void *peer) {
  auto refCounted = reinterpret_cast<CBLRefCounted *>(peer);
  CBL_Release(refCounted);
}

void CBLDart_BindCBLRefCountedToDartObject(Dart_Handle object,
                                           CBLRefCounted *refCounted,
                                           uint8_t retain) {
  if (retain) CBL_Retain(refCounted);

  Dart_NewFinalizableHandle_DL(object, refCounted, 0,
                               CBLDart_CBLRefCountedFinalizer);
}

void CBLDart_CBLListenerFinalizer(void *context) {
  auto listenerToken = reinterpret_cast<CBLListenerToken *>(context);
  CBLListener_Remove(listenerToken);
}

// -- Log

std::shared_mutex loggingMutex;

auto originalLogCallback = CBLLog_Callback();

Callback *dartLogCallback = nullptr;

void CBLDart_LogCallbackWrapper(CBLLogDomain domain, CBLLogLevel level,
                                FLString message) {
  const std::shared_lock<std::shared_mutex> lock(loggingMutex);

  Dart_CObject domain_;
  domain_.type = Dart_CObject_kInt32;
  domain_.value.as_int32 = int32_t(domain);

  Dart_CObject level_;
  level_.type = Dart_CObject_kInt32;
  level_.value.as_int32 = int32_t(level);

  Dart_CObject message_;
  message_.type = Dart_CObject_kInt64;
  message_.value.as_int64 = reinterpret_cast<int64_t>(&message);

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

// -- Document

CBLDart_FLString CBLDart_CBLDocument_ID(CBLDocument *doc) {
  return CBLDart_FLStringToDart(CBLDocument_ID(doc));
}

CBLDart_FLString CBLDart_CBLDocument_RevisionID(CBLDocument *doc) {
  return CBLDart_FLStringToDart(CBLDocument_RevisionID(doc));
}

CBLDart_FLStringResult CBLDart_CBLDocument_CreateJSON(CBLDocument *doc) {
  return CBLDart_FLStringResultToDart(CBLDocument_CreateJSON(doc));
}

CBLDocument *CBLDart_CBLDocument_CreateWithID(CBLDart_FLString docID) {
  return CBLDocument_CreateWithID(CBLDart_FLStringFromDart(docID));
}

int8_t CBLDart_CBLDocument_SetJSON(CBLDocument *doc, CBLDart_FLString json,
                                   CBLError *errorOut) {
  return CBLDocument_SetJSON(doc, CBLDart_FLStringFromDart(json), errorOut);
}

// -- Database

CBLDart_CBLDatabaseConfiguration CBLDart_CBLDatabaseConfiguration_Default() {
  auto config = CBLDatabaseConfiguration_Default();
  CBLDart_CBLDatabaseConfiguration result;
  result.directory = CBLDart_FLStringToDart(config.directory);
  return result;
}

uint8_t CBLDart_CBL_DatabaseExists(CBLDart_FLString name,
                                   CBLDart_FLString inDirectory) {
  return CBL_DatabaseExists(CBLDart_FLStringFromDart(name),
                            CBLDart_FLStringFromDart(inDirectory));
}

uint8_t CBLDart_CBL_CopyDatabase(CBLDart_FLString fromPath,
                                 CBLDart_FLString toName,
                                 CBLDart_CBLDatabaseConfiguration *config,
                                 CBLError *errorOut) {
  CBLDatabaseConfiguration _config;
  _config.directory = CBLDart_FLStringFromDart(config->directory);
  return CBL_CopyDatabase(CBLDart_FLStringFromDart(fromPath),
                          CBLDart_FLStringFromDart(toName), &_config, errorOut);
}

uint8_t CBLDart_CBL_DeleteDatabase(CBLDart_FLString name,
                                   CBLDart_FLString inDirectory,
                                   CBLError *errorOut) {
  return CBL_DeleteDatabase(CBLDart_FLStringFromDart(name),
                            CBLDart_FLStringFromDart(inDirectory), errorOut);
}

CBLDatabase *CBLDart_CBLDatabase_Open(CBLDart_FLString name,
                                      CBLDart_CBLDatabaseConfiguration *config,
                                      CBLError *errorOut) {
  CBLDatabaseConfiguration _config;
  _config.directory = CBLDart_FLStringFromDart(config->directory);
  return CBLDatabase_Open(CBLDart_FLStringFromDart(name), &_config, errorOut);
}

CBLDart_FLString CBLDart_CBLDatabase_Name(CBLDatabase *db) {
  return CBLDart_FLStringToDart(CBLDatabase_Name(db));
}

CBLDart_FLStringResult CBLDart_CBLDatabase_Path(CBLDatabase *db) {
  return CBLDart_FLStringResultToDart(CBLDatabase_Path(db));
}

CBLDart_CBLDatabaseConfiguration CBLDart_CBLDatabase_Config(CBLDatabase *db) {
  auto config = CBLDatabase_Config(db);
  return {
      .directory = CBLDart_FLStringToDart(config.directory),
  };
}

const CBLDocument *CBLDart_CBLDatabase_GetDocument(CBLDatabase *database,
                                                   CBLDart_FLString docID,
                                                   CBLError *errorOut) {
  return CBLDatabase_GetDocument(database, CBLDart_FLStringFromDart(docID),
                                 errorOut);
}

CBLDocument *CBLDart_CBLDatabase_GetMutableDocument(CBLDatabase *database,
                                                    CBLDart_FLString docID,
                                                    CBLError *errorOut) {
  return CBLDatabase_GetMutableDocument(
      database, CBLDart_FLStringFromDart(docID), errorOut);
}

uint8_t CBLDart_CBLDatabase_SaveDocumentWithConcurrencyControl(
    CBLDatabase *db, CBLDocument *doc, CBLConcurrencyControl concurrency,
    CBLError *errorOut) {
  return CBLDatabase_SaveDocumentWithConcurrencyControl(db, doc, concurrency,
                                                        errorOut);
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

uint8_t CBLDart_CBLDatabase_SaveDocumentWithConflictHandler(
    CBLDatabase *db, CBLDocument *doc, Callback *conflictHandler,
    CBLError *errorOut) {
  return CBLDatabase_SaveDocumentWithConflictHandler(
      db, doc, CBLDart_SaveConflictHandlerWrapper, (void *)conflictHandler,
      errorOut);
}

CBLDART_EXPORT
uint8_t CBLDart_CBLDatabase_PurgeDocumentByID(CBLDatabase *database,
                                              CBLDart_FLString docID,
                                              CBLError *errorOut) {
  return CBLDatabase_PurgeDocumentByID(
      database, CBLDart_FLStringFromDart(docID), errorOut);
}

CBLTimestamp CBLDart_CBLDatabase_GetDocumentExpiration(CBLDatabase *db,
                                                       CBLDart_FLSlice docID,
                                                       CBLError *errorOut) {
  return CBLDatabase_GetDocumentExpiration(db, CBLDart_FLStringFromDart(docID),
                                           errorOut);
}

uint8_t CBLDart_CBLDatabase_SetDocumentExpiration(CBLDatabase *db,
                                                  CBLDart_FLSlice docID,
                                                  CBLTimestamp expiration,
                                                  CBLError *errorOut) {
  return CBLDatabase_SetDocumentExpiration(db, CBLDart_FLStringFromDart(docID),
                                           expiration, errorOut);
}

void CBLDart_DocumentChangeListenerWrapper(void *context, const CBLDatabase *db,
                                           FLString docID) {
  const Callback &callback = *reinterpret_cast<Callback *>(context);

  Dart_CObject args;
  args.type = Dart_CObject_kArray;
  args.value.as_array.length = 0;

  CallbackCall(callback).execute(args);
}

void CBLDart_CBLDatabase_AddDocumentChangeListener(const CBLDatabase *db,
                                                   const CBLDart_FLString docID,
                                                   Callback *listener) {
  auto listenerToken = CBLDatabase_AddDocumentChangeListener(
      db, CBLDart_FLStringFromDart(docID),
      CBLDart_DocumentChangeListenerWrapper, (void *)listener);

  listener->setFinalizer(listenerToken, CBLDart_CBLListenerFinalizer);
}

void CBLDart_DatabaseChangeListenerWrapper(void *context, const CBLDatabase *db,
                                           unsigned numDocs, FLString *docID) {
  const Callback &callback = *reinterpret_cast<Callback *>(context);

  auto ids = new Dart_CObject[numDocs];
  auto argsValues = new Dart_CObject *[numDocs];

  for (size_t i = 0; i < numDocs; i++) {
    auto id = &ids[i];
    id->type = Dart_CObject_kInt64;
    id->value.as_int64 = reinterpret_cast<int64_t>(&docID[i]);
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

uint8_t CBLDart_CBLDatabase_CreateIndex(CBLDatabase *db, CBLDart_FLString name,
                                        CBLDart_CBLIndexSpec indexSpec,
                                        CBLError *errorOut) {
  switch (indexSpec.type) {
    case kCBLDart_IndexTypeValue: {
      CBLValueIndexConfiguration config = {
          .expressionLanguage = indexSpec.expressionLanguage,
          .expressions = CBLDart_FLStringFromDart(indexSpec.expressions),
      };
      return CBLDatabase_CreateValueIndex(db, CBLDart_FLStringFromDart(name),
                                          config, errorOut);
    }
    case kCBLDart_IndexTypeFullText: {
    }
      CBLFullTextIndexConfiguration config = {
          .expressionLanguage = indexSpec.expressionLanguage,
          .expressions = CBLDart_FLStringFromDart(indexSpec.expressions),
          .ignoreAccents = static_cast<bool>(indexSpec.ignoreAccents),
          .language = CBLDart_FLSliceFromDart(indexSpec.language),
      };
      return CBLDatabase_CreateFullTextIndex(db, CBLDart_FLStringFromDart(name),
                                             config, errorOut);
  }
}

uint8_t CBLDart_CBLDatabase_DeleteIndex(CBLDatabase *db, CBLDart_FLString name,
                                        CBLError *errorOut) {
  return CBLDatabase_DeleteIndex(db, CBLDart_FLStringFromDart(name), errorOut);
}

// -- Query

CBLQuery *CBLDart_CBLDatabase_CreateQuery(CBLDatabase *db,
                                          CBLQueryLanguage language,
                                          CBLDart_FLString queryString,
                                          int *errorPosOut,
                                          CBLError *errorOut) {
  return CBLDatabase_CreateQuery(db, language,
                                 CBLDart_FLStringFromDart(queryString),
                                 errorPosOut, errorOut);
}

CBLDart_FLStringResult CBLDart_CBLQuery_Explain(const CBLQuery *query) {
  return CBLDart_FLStringResultToDart(CBLQuery_Explain(query));
}

CBLDart_FLString CBLDart_CBLQuery_ColumnName(const CBLQuery *query,
                                             unsigned columnIndex) {
  return CBLDart_FLStringToDart(CBLQuery_ColumnName(query, columnIndex));
}

FLValue CBLDart_CBLResultSet_ValueForKey(CBLResultSet *rs,
                                         CBLDart_FLString key) {
  return CBLResultSet_ValueForKey(rs, CBLDart_FLStringFromDart(key));
}

void CBLDart_QueryChangeListenerWrapper(void *context, CBLQuery *query,
                                        CBLListenerToken *token) {
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

CBLBlob *CBLDart_CBLBlob_CreateWithStream(CBLDart_FLString contentType,
                                          CBLBlobWriteStream *writer) {
  return CBLBlob_CreateWithStream(CBLDart_FLStringFromDart(contentType),
                                  writer);
}

// -- Replicator

CBLEndpoint *CBLDart_CBLEndpoint_CreateWithURL(CBLDart_FLString url) {
  return CBLEndpoint_CreateWithURL(CBLDart_FLStringFromDart(url));
}

CBLAuthenticator *CBLDart_CBLAuth_CreatePassword(CBLDart_FLString username,
                                                 CBLDart_FLString password) {
  return CBLAuth_CreatePassword(CBLDart_FLStringFromDart(username),
                                CBLDart_FLStringFromDart(password));
}

CBLAuthenticator *CBLDart_CBLAuth_CreateSession(CBLDart_FLString sessionID,
                                                CBLDart_FLString cookieName) {
  return CBLAuth_CreateSession(CBLDart_FLStringFromDart(sessionID),
                               CBLDart_FLStringFromDart(cookieName));
}

struct ReplicatorCallbackWrapperContext {
  Callback *pullFilter;
  Callback *pushFilter;
  Callback *conflictResolver;
};

std::map<CBLReplicator *, ReplicatorCallbackWrapperContext *>
    replicatorCallbackWrapperContexts;
std::mutex replicatorCallbackWrapperContexts_mutex;

bool CBLDart_ReplicatorFilterWrapper(Callback *callback, CBLDocument *document,
                                     CBLDocumentFlags flags) {
  Dart_CObject documentAddress;
  documentAddress.type = Dart_CObject_kInt64;
  documentAddress.value.as_int64 = reinterpret_cast<int64_t>(document);

  Dart_CObject isDeleted_;
  isDeleted_.type = Dart_CObject_kInt32;
  isDeleted_.value.as_int32 = flags;

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
                                         CBLDocumentFlags flags) {
  auto wrapperContext =
      reinterpret_cast<ReplicatorCallbackWrapperContext *>(context);
  return CBLDart_ReplicatorFilterWrapper(wrapperContext->pullFilter, document,
                                         flags);
}

bool CBLDart_ReplicatorPushFilterWrapper(void *context, CBLDocument *document,
                                         CBLDocumentFlags flags) {
  auto wrapperContext =
      reinterpret_cast<ReplicatorCallbackWrapperContext *>(context);
  return CBLDart_ReplicatorFilterWrapper(wrapperContext->pushFilter, document,
                                         flags);
}

const CBLDocument *CBLDart_ReplicatorConflictResolverWrapper(
    void *context, FLString documentID, const CBLDocument *localDocument,
    const CBLDocument *remoteDocument) {
  auto wrapperContext =
      reinterpret_cast<ReplicatorCallbackWrapperContext *>(context);
  auto callback = wrapperContext->conflictResolver;

  Dart_CObject documentID_;
  documentID_.type = Dart_CObject_kInt64;
  documentID_.value.as_int64 = reinterpret_cast<int64_t>(&documentID);

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

CBLReplicator *CBLDart_CBLReplicator_Create(
    CBLDart_ReplicatorConfiguration *config, CBLError *errorOut) {
  CBLReplicatorConfiguration _config;
  _config.database = config->database;
  _config.endpoint = config->endpoint;
  _config.replicatorType =
      static_cast<CBLReplicatorType>(config->replicatorType);
  _config.continuous = config->continuous;
  _config.disableAutoPurge = config->disableAutoPurge;
  _config.maxAttempts = config->maxAttempts;
  _config.maxAttemptWaitTime = config->maxAttemptWaitTime;
  _config.heartbeat = config->heartbeat;
  _config.authenticator = config->authenticator;

  if (config->proxy) {
    CBLProxySettings proxy;
    proxy.type = config->proxy->type;
    proxy.hostname = CBLDart_FLStringFromDart(config->proxy->hostname);
    proxy.port = config->proxy->port;
    proxy.username = CBLDart_FLStringFromDart(config->proxy->username);
    proxy.password = CBLDart_FLStringFromDart(config->proxy->password);
    _config.proxy = &proxy;
  } else {
    _config.proxy = nullptr;
  }

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

  auto replicator = CBLReplicator_Create(&_config, errorOut);

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

void CBLDart_BindReplicatorToDartObject(Dart_Handle object,
                                        CBLReplicator *replicator) {
  Dart_NewFinalizableHandle_DL(object, reinterpret_cast<void *>(replicator), 0,
                               CBLDart_ReplicatorFinalizer);
}

uint8_t CBLDart_CBLReplicator_IsDocumentPending(CBLReplicator *replicator,
                                                CBLDart_FLString docId,
                                                CBLError *errorOut) {
  return CBLReplicator_IsDocumentPending(
      replicator, CBLDart_FLStringFromDart(docId), errorOut);
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

void CBLDart_Replicator_DocumentReplicationListenerWrapper(
    void *context, CBLReplicator *replicator, bool isPush,
    unsigned numDocuments, const CBLReplicatedDocument *documents) {
  auto callback = reinterpret_cast<Callback *>(context);

  Dart_CObject isPush_;
  isPush_.type = Dart_CObject_kBool;
  isPush_.value.as_bool = isPush;

  auto dartDocuments = new CBLDart_ReplicatedDocument[numDocuments];

  for (size_t i = 0; i < numDocuments; i++) {
    auto document = &documents[i];
    auto dartDocument = &dartDocuments[i];

    dartDocument->ID = CBLDart_FLStringToDart(document->ID);
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

void CBLDart_CBLReplicator_AddDocumentReplicationListener(
    CBLReplicator *replicator, Callback *listener) {
  auto listenerToken = CBLReplicator_AddDocumentReplicationListener(
      replicator, CBLDart_Replicator_DocumentReplicationListenerWrapper,
      (void *)listener);

  listener->setFinalizer(listenerToken, CBLDart_CBLListenerFinalizer);
}
