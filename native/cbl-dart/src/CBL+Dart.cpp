#include <future>
#include <map>
#include <mutex>
#include <shared_mutex>
#include <thread>

#include "CBL+Dart.h"
#include "Utils.hh"

std::mutex initializeMutex;
bool initialized = false;

bool CBLDart_Initialize(void *dartInitializeDlData, void *cblInitContext,
                        CBLError *errorOut) {
  std::scoped_lock lock(initializeMutex);

  if (initialized) {
    // Only initialize libraries once.
    return true;
  }

#ifdef __ANDROID__
  // Initialize the Couchbase Lite library.
  if (!CBL_Init(reinterpret_cast<CBLInitContext *>(cblInitContext), errorOut)) {
    return false;
  }
#endif

  // Initialize the Dart API for this dynamic library.
  Dart_InitializeApiDL(dartInitializeDlData);

  initialized = true;
  return true;
}

// -- AsyncCallback

CBLDart::AsyncCallback *CBLDart_AsyncCallback_New(uint32_t id,
                                                  Dart_Handle object,
                                                  Dart_Port sendPort,
                                                  uint8_t debug) {
  return new CBLDart::AsyncCallback(id, object, sendPort, debug);
}

void CBLDart_AsyncCallback_Close(CBLDart::AsyncCallback *callback) {
  callback->close();
}

void CBLDart_AsyncCallback_CallForTest(CBLDart::AsyncCallback *callback,
                                       int64_t argument) {
  std::thread([=]() {
    Dart_CObject argument__;
    argument__.type = Dart_CObject_kInt64;
    argument__.value.as_int64 = argument;

    Dart_CObject *argsValues[] = {&argument__};

    Dart_CObject args;
    args.type = Dart_CObject_kArray;
    args.value.as_array.length = 1;
    args.value.as_array.values = argsValues;

    CBLDart::AsyncCallbackCall(*callback).execute(args);
  }).detach();
}

static CBLDart::AsyncCallback *CBLDart_AsAsyncCallback(void *pointer) {
  return reinterpret_cast<CBLDart::AsyncCallback *>(pointer);
}

// -- Dart Finalizer

struct CBLDart_DartFinalizerContext {
  Dart_Port registry;
  int64_t token;
};

static void CBLDart_RunDartFinalizer(void *dart_callback_data, void *peer) {
  auto context = reinterpret_cast<CBLDart_DartFinalizerContext *>(peer);
  // Finalizer callbacks must not call back into the VM through most of the
  // `Dart_` methods. That's why the finalizer registry is notified
  // asynchronously from another thread. The result of `async` needs to be
  // assigned to a reference. Otherwise it blocks until the async task
  // completes.
  auto _ = std::async(std::launch::async, [=]() {
    Dart_PostInteger_DL(context->registry, context->token);
    delete context;
  });
}

void CBLDart_RegisterDartFinalizer(Dart_Handle object, Dart_Port registry,
                                   int64_t token) {
  auto context = new CBLDart_DartFinalizerContext{
      .registry = registry,
      .token = token,
  };
  Dart_NewFinalizableHandle_DL(object, context, 0, CBLDart_RunDartFinalizer);
}

// Couchbase Lite --------------------------------------------------------------

// -- Base

CBLDart_FLStringResult CBLDart_CBLError_Message(CBLError *error) {
  return CBLDart_FLStringResultToDart(CBLError_Message(error));
}

#ifdef DEBUG
bool cblRefCountedDebugEnabled = false;
std::map<CBLRefCounted *, char *> cblRefCountedDebugNames;
std::mutex cblRefCountedDebugMutex;
#endif

inline void CBLDart_CBLRefCountedFinalizer_Impl(CBLRefCounted *refCounted) {
#ifdef DEBUG
  char *debugName = nullptr;
  {
    std::scoped_lock lock(cblRefCountedDebugMutex);
    auto nh = cblRefCountedDebugNames.extract(refCounted);
    if (!nh.empty()) {
      debugName = nh.mapped();
    }
  }
  if (debugName) {
    if (cblRefCountedDebugEnabled) {
      printf("CBLRefCountedFinalizer: %p %s\n", refCounted, debugName);
    }
    free(debugName);
  }
#endif

  CBL_Release(refCounted);
}

inline void CBLDart_BindCBLRefCountedToDartObject_Impl(
    Dart_Handle object, CBLRefCounted *refCounted, uint8_t retain,
    char *debugName, Dart_HandleFinalizer handleFinalizer) {
#ifdef DEBUG
  if (debugName) {
    std::scoped_lock lock(cblRefCountedDebugMutex);
    if (cblRefCountedDebugEnabled) {
      cblRefCountedDebugNames[refCounted] = debugName;
    }
  }
#endif

  if (retain) CBL_Retain(refCounted);

  Dart_NewFinalizableHandle_DL(object, refCounted, 0, handleFinalizer);
}

/**
 * Dart_HandleFinalizer for objects which are backed by a CBLRefCounted.
 */
void CBLDart_CBLRefCountedFinalizer(void *dart_callback_data, void *peer) {
  CBLDart_CBLRefCountedFinalizer_Impl(reinterpret_cast<CBLRefCounted *>(peer));
}

void CBLDart_BindCBLRefCountedToDartObject(Dart_Handle object,
                                           CBLRefCounted *refCounted,
                                           uint8_t retain, char *debugName) {
  CBLDart_BindCBLRefCountedToDartObject_Impl(
      object, refCounted, retain, debugName, CBLDart_CBLRefCountedFinalizer);
}

void CBLDart_SetDebugRefCounted(uint8_t enabled) {
#ifdef DEBUG
  std::scoped_lock lock(cblRefCountedDebugMutex);
  cblRefCountedDebugEnabled = enabled;
  if (!enabled) {
    cblRefCountedDebugNames.clear();
  }
#endif
}

void CBLDart_CBLListenerFinalizer(void *context) {
  auto listenerToken = reinterpret_cast<CBLListenerToken *>(context);
  CBLListener_Remove(listenerToken);
}

// -- Log

std::shared_mutex loggingMutex;
CBLDart::AsyncCallback *logCallback = nullptr;
CBLDart_CBLLogFileConfiguration *logFileConfig = nullptr;

void CBLDart_CBL_LogMessage(CBLLogDomain domain, CBLLogLevel level,
                            CBLDart_FLString message) {
  CBL_Log(domain, level, "%.*s", static_cast<int>(message.size),
          static_cast<const char *>(message.buf));
}

void CBLDart_LogCallbackWrapper(CBLLogDomain domain, CBLLogLevel level,
                                FLString message) {
  std::shared_lock lock(loggingMutex);

  Dart_CObject domain_;
  domain_.type = Dart_CObject_kInt32;
  domain_.value.as_int32 = static_cast<int32_t>(domain);

  Dart_CObject level_;
  level_.type = Dart_CObject_kInt32;
  level_.value.as_int32 = static_cast<int32_t>(level);

  Dart_CObject message_;
  CBLDart_CObject_SetFLString(&message_, message);

  Dart_CObject *argsValues[] = {&domain_, &level_, &message_};

  Dart_CObject args;
  args.type = Dart_CObject_kArray;
  args.value.as_array.length = 3;
  args.value.as_array.values = argsValues;

  CBLDart::AsyncCallbackCall(*logCallback).execute(args);
}

void CBLDart_LogCallbackFinalizer(void *context) {
  std::unique_lock lock(loggingMutex);
  CBLLog_SetCallback(nullptr);
  logCallback = nullptr;
}

uint8_t CBLDart_CBLLog_SetCallback(CBLDart::AsyncCallback *callback) {
  std::unique_lock lock(loggingMutex);

  // Don't set the new callback if one has already been set. Another isolate,
  // different from the one currenlty calling, has already set its callback.
  if (callback != nullptr && logCallback != nullptr) {
    return false;
  }

  if (callback == nullptr) {
    logCallback = nullptr;
    CBLLog_SetCallback(nullptr);
  } else {
    logCallback = callback;
    callback->setFinalizer(nullptr, CBLDart_LogCallbackFinalizer);
    CBLLog_SetCallback(CBLDart_LogCallbackWrapper);
  }

  return true;
}

uint8_t CBLDart_CBLLog_SetFileConfig(CBLDart_CBLLogFileConfiguration *config,
                                     CBLError *errorOut) {
  std::unique_lock lock(loggingMutex);

  if (!config) {
    auto success = CBLLog_SetFileConfig(
        {
            .level = kCBLLogNone,
            .directory = {nullptr, 0},
            .maxRotateCount = 0,
            .maxSize = 0,
            .usePlaintext = false,
        },
        errorOut);
    if (success) {
      if (logFileConfig) {
        delete logFileConfig;
        logFileConfig = nullptr;
      }
    }
    return success;
  } else {
    auto success = CBLLog_SetFileConfig(
        {
            .level = config->level,
            .directory = CBLDart_FLStringFromDart(config->directory),
            .maxRotateCount = config->maxRotateCount,
            .maxSize = static_cast<size_t>(config->maxSize),
            .usePlaintext = static_cast<bool>(config->usePlaintext),
        },
        errorOut);
    if (success) {
      auto config_ = CBLLog_FileConfig();
      if (!logFileConfig) {
        logFileConfig = new CBLDart_CBLLogFileConfiguration;
      }
      *logFileConfig = {
          .level = config_->level,
          .directory = CBLDart_FLStringToDart(config_->directory),
          .maxRotateCount = config_->maxRotateCount,
          .maxSize = config->maxSize,
          .usePlaintext = config_->usePlaintext,
      };
    }
    return success;
  }
}

CBLDart_CBLLogFileConfiguration *CBLDart_CBLLog_GetFileConfig() {
  std::shared_lock lock(loggingMutex);
  return logFileConfig;
}

static bool CBLDart_LogFileConfigIsSet() { return logFileConfig != nullptr; }

static void CBLDart_CheckFileLogging() {
  static std::once_flag checkFileLogging;
  std::call_once(checkFileLogging, []() {
    if (!CBLDart_LogFileConfigIsSet()) {
      CBL_Log(kCBLLogDomainDatabase, kCBLLogWarning,
              "Database.log.file.config is null, meaning file logging is "
              "disabled. Log files required for product support are not being "
              "generated.");
    }
  });
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

/**
 * A list of all the currently open database.
 *
 * Used to ensure that databases are closed only once.
 */
std::vector<CBLDatabase *> openDatabases;
std::mutex openDatabasesMutex;

static void CBLDart_RegisterOpenDatabase(CBLDatabase *database) {
  std::scoped_lock lock(openDatabasesMutex);
  openDatabases.push_back(database);
}

uint8_t CBLDart_CBLDatabase_Close(CBLDatabase *database, bool andDelete,
                                  CBLError *errorOut) {
  {
    std::scoped_lock lock(openDatabasesMutex);
    // Check if the database is still open.
    auto it = std::find(openDatabases.begin(), openDatabases.end(), database);
    if (it == openDatabases.end()) {
      // Return early since the database has already been closed.
      return true;
    }

    // Remove the database from the list of open databasea and close it.
    openDatabases.erase(it);
  }

  if (andDelete) {
    return CBLDatabase_Delete(database, errorOut);
  } else {
    return CBLDatabase_Close(database, errorOut);
  }
}

CBLDart_CBLDatabaseConfiguration CBLDart_CBLDatabaseConfiguration_Default() {
  auto config = CBLDatabaseConfiguration_Default();
  return {
      .directory = CBLDart_FLStringToDart(config.directory),
  };
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
  CBLDatabaseConfiguration config_;
  config_.directory = CBLDart_FLStringFromDart(config->directory);
  return CBL_CopyDatabase(CBLDart_FLStringFromDart(fromPath),
                          CBLDart_FLStringFromDart(toName), &config_, errorOut);
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
  CBLDart_CheckFileLogging();

  CBLDatabaseConfiguration config_ = {.directory = {nullptr, 0}};
  if (config) {
    config_.directory = CBLDart_FLStringFromDart(config->directory);
  }

  auto database =
      CBLDatabase_Open(CBLDart_FLStringFromDart(name), &config_, errorOut);

  if (database) {
    CBLDart_RegisterOpenDatabase(database);
  }

  return database;
}

void CBLDart_DatabaseFinalizer(void *dart_callback_data, void *peer) {
  auto database = reinterpret_cast<CBLDatabase *>(peer);
  CBLError error;
  if (!CBLDart_CBLDatabase_Close(database, false, &error)) {
    auto errorMessage = CBLError_Message(&error);
    CBL_Log(kCBLLogDomainDatabase, kCBLLogError,
            "Error closing database %p in Dart finalizer: %*.s", database,
            static_cast<int>(errorMessage.size), (char *)errorMessage.buf);
    FLSliceResult_Release(errorMessage);
  }
  CBLDart_CBLRefCountedFinalizer_Impl(
      reinterpret_cast<CBLRefCounted *>(database));
}

void CBLDart_BindDatabaseToDartObject(Dart_Handle object, CBLDatabase *database,
                                      char *debugName) {
  CBLDart_BindCBLRefCountedToDartObject_Impl(
      object, reinterpret_cast<CBLRefCounted *>(database), false, debugName,
      CBLDart_DatabaseFinalizer);
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
  auto callback = CBLDart_AsAsyncCallback(context);

  Dart_CObject args;
  CBLDart_CObject_SetEmptyArray(&args);

  CBLDart::AsyncCallbackCall(*callback).execute(args);
}

void CBLDart_CBLDatabase_AddDocumentChangeListener(
    const CBLDatabase *db, const CBLDart_FLString docID,
    CBLDart::AsyncCallback *listener) {
  auto listenerToken = CBLDatabase_AddDocumentChangeListener(
      db, CBLDart_FLStringFromDart(docID),
      CBLDart_DocumentChangeListenerWrapper, listener);

  listener->setFinalizer(listenerToken, CBLDart_CBLListenerFinalizer);
}

void CBLDart_DatabaseChangeListenerWrapper(void *context, const CBLDatabase *db,
                                           unsigned numDocs, FLString *docIDs) {
  auto callback = CBLDart_AsAsyncCallback(context);

  Dart_CObject docIDs_[numDocs];
  Dart_CObject *argsValues[numDocs];

  for (size_t i = 0; i < numDocs; i++) {
    auto docID_ = &docIDs_[i];
    CBLDart_CObject_SetFLString(docID_, docIDs[i]);
    argsValues[i] = docID_;
  }

  Dart_CObject args;
  args.type = Dart_CObject_kArray;
  args.value.as_array.length = numDocs;
  args.value.as_array.values = argsValues;

  CBLDart::AsyncCallbackCall(*callback).execute(args);
}

void CBLDart_CBLDatabase_AddChangeListener(const CBLDatabase *db,
                                           CBLDart::AsyncCallback *listener) {
  auto listenerToken = CBLDatabase_AddChangeListener(
      db, CBLDart_DatabaseChangeListenerWrapper, listener);

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

  // Is never reached, but stops the compiler warnings.
  return 0;
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
  auto callback = CBLDart_AsAsyncCallback(context);

  Dart_CObject args;
  CBLDart_CObject_SetEmptyArray(&args);

  CBLDart::AsyncCallbackCall(*callback).execute(args);
}

CBLListenerToken *CBLDart_CBLQuery_AddChangeListener(
    CBLQuery *query, CBLDart::AsyncCallback *listener) {
  auto listenerToken = CBLQuery_AddChangeListener(
      query, CBLDart_QueryChangeListenerWrapper, listener);

  listener->setFinalizer(listenerToken, CBLDart_CBLListenerFinalizer);

  return listenerToken;
}

// -- Blob

CBLDart_FLString CBLDart_CBLBlob_Digest(CBLBlob *blob) {
  return CBLDart_FLStringToDart(CBLBlob_Digest(blob));
}

CBLDart_FLString CBLDart_CBLBlob_ContentType(CBLBlob *blob) {
  return CBLDart_FLStringToDart(CBLBlob_ContentType(blob));
}

CBLDart_FLSliceResult CBLDart_CBLBlob_Content(const CBLBlob *blob,
                                              CBLError *errorOut) {
  return CBLDart_FLSliceResultToDart(CBLBlob_Content(blob, errorOut));
}

static void CBLDart_FinalizeCBLBlobReadStream(void *isolate_callback_data,
                                              void *peer) {
  CBLBlobReader_Close(reinterpret_cast<CBLBlobReadStream *>(peer));
}

void CBLDart_BindBlobReadStreamToDartObject(Dart_Handle object,
                                            CBLBlobReadStream *stream) {
  Dart_NewFinalizableHandle_DL(object, stream, 0,
                               CBLDart_FinalizeCBLBlobReadStream);
}

CBLDart_FLSliceResult CBLDart_CBLBlobReader_Read(CBLBlobReadStream *stream,
                                                 uint64_t bufferSize,
                                                 CBLError *outError) {
  auto bufferSize_t = static_cast<size_t>(bufferSize);
  auto buffer = FLSliceResult_New(bufferSize_t);

  auto bytesRead = CBLBlobReader_Read(stream, const_cast<void *>(buffer.buf),
                                      bufferSize_t, outError);

  // Handle error
  if (bytesRead == -1) {
    FLSliceResult_Release(buffer);
    return {nullptr, 0};
  }

  buffer.size = bytesRead;

  return CBLDart_FLSliceResultToDart(buffer);
}

CBLBlob *CBLDart_CBLBlob_CreateWithData(CBLDart_FLString contentType,
                                        CBLDart_FLSlice contents) {
  return CBLBlob_CreateWithData(CBLDart_FLStringFromDart(contentType),
                                CBLDart_FLSliceFromDart(contents));
}

CBLBlob *CBLDart_CBLBlob_CreateWithStream(CBLDart_FLString contentType,
                                          CBLBlobWriteStream *writer) {
  return CBLBlob_CreateWithStream(CBLDart_FLStringFromDart(contentType),
                                  writer);
}

// -- Replicator

CBLEndpoint *CBLDart_CBLEndpoint_CreateWithURL(CBLDart_FLString url,
                                               CBLError *errorOut) {
  return CBLEndpoint_CreateWithURL(CBLDart_FLStringFromDart(url), errorOut);
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
  CBLDart::AsyncCallback *pullFilter;
  CBLDart::AsyncCallback *pushFilter;
  CBLDart::AsyncCallback *conflictResolver;
};

std::map<CBLReplicator *, ReplicatorCallbackWrapperContext *>
    replicatorCallbackWrapperContexts;
std::mutex replicatorCallbackWrapperContexts_mutex;

bool CBLDart_ReplicatorFilterWrapper(CBLDart::AsyncCallback *callback,
                                     CBLDocument *document,
                                     CBLDocumentFlags flags) {
  Dart_CObject document_;
  CBLDart_CObject_SetPointer(&document_, document);

  Dart_CObject isDeleted_;
  isDeleted_.type = Dart_CObject_kInt32;
  isDeleted_.value.as_int32 = flags;

  Dart_CObject *argsValues[] = {&document_, &isDeleted_};

  Dart_CObject args;
  args.type = Dart_CObject_kArray;
  args.value.as_array.length = 2;
  args.value.as_array.values = argsValues;

  bool descision;

  auto resultHandler = [&](Dart_CObject *result) {
    descision = result->value.as_bool;
  };

  CBLDart::AsyncCallbackCall(*callback, resultHandler).execute(args);

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
  CBLDart_CObject_SetFLString(&documentID_, documentID);

  Dart_CObject local;
  CBLDart_CObject_SetPointer(&local, localDocument);

  Dart_CObject remote;
  CBLDart_CObject_SetPointer(&remote, remoteDocument);

  Dart_CObject *argsValues[] = {&documentID_, &local, &remote};

  Dart_CObject args;
  args.type = Dart_CObject_kArray;
  args.value.as_array.length = 3;
  args.value.as_array.values = argsValues;

  const CBLDocument *descision;
  auto resolverThrewException = false;

  auto resultHandler = [&](Dart_CObject *result) {
    switch (result->type) {
      case Dart_CObject_kNull:
        descision = nullptr;
        break;
      case Dart_CObject_kInt64:
        descision = reinterpret_cast<const CBLDocument *>(
            CBLDart_CObject_getIntValueAsInt64(result));
        break;

      case Dart_CObject_kBool:
        // `false` means the resolver threw an exception.
        if (!result->value.as_bool) {
          resolverThrewException = true;
          break;
        }
      default:
        throw std::logic_error(
            "Unexpected result from replicator conflict resolver.");
        break;
    }
  };

  CBLDart::AsyncCallbackCall(*callback, resultHandler).execute(args);

  if (resolverThrewException) {
    throw std::runtime_error("Replicator conflict resolver threw an exception");
  }

  return descision;
}

CBLReplicator *CBLDart_CBLReplicator_Create(
    CBLDart_ReplicatorConfiguration *config, CBLError *errorOut) {
  CBLReplicatorConfiguration config_;
  config_.database = config->database;
  config_.endpoint = config->endpoint;
  config_.replicatorType =
      static_cast<CBLReplicatorType>(config->replicatorType);
  config_.continuous = config->continuous;
  config_.disableAutoPurge = config->disableAutoPurge;
  config_.maxAttempts = config->maxAttempts;
  config_.maxAttemptWaitTime = config->maxAttemptWaitTime;
  config_.heartbeat = config->heartbeat;
  config_.authenticator = config->authenticator;

  CBLProxySettings proxy;
  if (config->proxy) {
    proxy.type = config->proxy->type;
    proxy.hostname = CBLDart_FLStringFromDart(config->proxy->hostname);
    proxy.port = config->proxy->port;
    proxy.username = CBLDart_FLStringFromDart(config->proxy->username);
    proxy.password = CBLDart_FLStringFromDart(config->proxy->password);
    config_.proxy = &proxy;
  } else {
    config_.proxy = nullptr;
  }

  config_.headers = config->headers;
  config_.pinnedServerCertificate = config->pinnedServerCertificate == nullptr
                                        ? kFLSliceNull
                                        : *config->pinnedServerCertificate;
  config_.trustedRootCertificates = config->trustedRootCertificates == nullptr
                                        ? kFLSliceNull
                                        : *config->trustedRootCertificates;
  config_.channels = config->channels;
  config_.documentIDs = config->documentIDs;
  config_.pullFilter = config->pullFilter == nullptr
                           ? nullptr
                           : CBLDart_ReplicatorPullFilterWrapper;
  config_.pushFilter = config->pushFilter == nullptr
                           ? nullptr
                           : CBLDart_ReplicatorPushFilterWrapper;
  config_.conflictResolver = config->conflictResolver == nullptr
                                 ? nullptr
                                 : CBLDart_ReplicatorConflictResolverWrapper;

  auto context = new ReplicatorCallbackWrapperContext;
  context->pullFilter = config->pullFilter;
  context->pushFilter = config->pushFilter;
  context->conflictResolver = config->conflictResolver;
  config_.context = context;

  auto replicator = CBLReplicator_Create(&config_, errorOut);

  if (replicator) {
    // Associate callback context with this instance so we can it released
    // when the replicator is released.
    std::scoped_lock lock(replicatorCallbackWrapperContexts_mutex);
    replicatorCallbackWrapperContexts[replicator] = context;
  } else {
    delete context;
  }

  return replicator;
}

void CBLDart_ReplicatorFinalizer(void *dart_callback_data, void *peer) {
  auto replicator = reinterpret_cast<CBLReplicator *>(peer);

  // Clean up context for callback wrapper
  ReplicatorCallbackWrapperContext *callbackWrapperContext;
  {
    std::scoped_lock lock(replicatorCallbackWrapperContexts_mutex);
    auto nh = replicatorCallbackWrapperContexts.extract(replicator);
    callbackWrapperContext = nh.mapped();
  }
  delete callbackWrapperContext;

  CBLReplicator_Stop(replicator);

  CBLDart_CBLRefCountedFinalizer_Impl(
      reinterpret_cast<CBLRefCounted *>(replicator));
}

void CBLDart_BindReplicatorToDartObject(Dart_Handle object,
                                        CBLReplicator *replicator,
                                        char *debugName) {
  CBLDart_BindCBLRefCountedToDartObject_Impl(
      object, reinterpret_cast<CBLRefCounted *>(replicator), false, debugName,
      CBLDart_ReplicatorFinalizer);
}

uint8_t CBLDart_CBLReplicator_IsDocumentPending(CBLReplicator *replicator,
                                                CBLDart_FLString docId,
                                                CBLError *errorOut) {
  return CBLReplicator_IsDocumentPending(
      replicator, CBLDart_FLStringFromDart(docId), errorOut);
}

class CObject_ReplicatorStatus {
 public:
  void init(const CBLReplicatorStatus *status) {
    assert(!errorMessageStr.buf);

    auto hasError = status->error.code != 0;

    // Init strings.
    if (hasError) {
      errorMessageStr = CBLError_Message(&status->error);
    }

    // Build CObject.
    object.type = Dart_CObject_kArray;
    object.value.as_array.length = hasError ? 6 : 3;
    object.value.as_array.values = objectValues;

    objectValues[0] = &activity;
    activity.type = Dart_CObject_kInt32;
    activity.value.as_int32 = status->activity;

    objectValues[1] = &progressComplete;
    progressComplete.type = Dart_CObject_kDouble;
    progressComplete.value.as_double = status->progress.complete;

    objectValues[2] = &progressDocumentCount;
    progressDocumentCount.type = Dart_CObject_kInt64;
    progressDocumentCount.value.as_int64 = status->progress.documentCount;

    if (hasError) {
      objectValues[3] = &errorDomain;
      errorDomain.type = Dart_CObject_kInt32;
      errorDomain.value.as_int32 = status->error.domain;

      objectValues[4] = &errorCode;
      errorCode.type = Dart_CObject_kInt32;
      errorCode.value.as_int32 = status->error.code;

      objectValues[5] = &errorMessage;
      CBLDart_CObject_SetFLString(&errorMessage,
                                  static_cast<FLString>(errorMessageStr));
    }
  }

  ~CObject_ReplicatorStatus() { FLSliceResult_Release(errorMessageStr); }

  Dart_CObject *cObject() { return &object; }

 private:
  Dart_CObject object;
  Dart_CObject *objectValues[6];
  Dart_CObject activity;
  Dart_CObject progressComplete;
  Dart_CObject progressDocumentCount;
  Dart_CObject errorDomain;
  Dart_CObject errorCode;
  Dart_CObject errorMessage;

  FLSliceResult errorMessageStr = {nullptr, 0};
};

void CBLDart_Replicator_ChangeListenerWrapper(
    void *context, CBLReplicator *replicator,
    const CBLReplicatorStatus *status) {
  auto callback = CBLDart_AsAsyncCallback(context);

  CObject_ReplicatorStatus cObjectStatus;
  cObjectStatus.init(status);

  Dart_CObject *argsValues[] = {cObjectStatus.cObject()};

  Dart_CObject args;
  args.type = Dart_CObject_kArray;
  args.value.as_array.length = 1;
  args.value.as_array.values = argsValues;

  CBLDart::AsyncCallbackCall(*callback).execute(args);
}

void CBLDart_CBLReplicator_AddChangeListener(CBLReplicator *replicator,
                                             CBLDart::AsyncCallback *listener) {
  auto listenerToken = CBLReplicator_AddChangeListener(
      replicator, CBLDart_Replicator_ChangeListenerWrapper, listener);

  listener->setFinalizer(listenerToken, CBLDart_CBLListenerFinalizer);
}

class CObject_ReplicatedDocument {
 public:
  void init(const CBLReplicatedDocument *document) {
    assert(!errorMessageStr);

    auto hasError = document->error.code != 0;

    if (hasError) {
      errorMessageStr = CBLError_Message(&document->error);
    }

    // Build CObject.
    object.type = Dart_CObject_kArray;
    object.value.as_array.length = hasError ? 5 : 2;
    object.value.as_array.values = objectValues;

    objectValues[0] = &id;
    CBLDart_CObject_SetFLString(&id, document->ID);

    objectValues[1] = &flags;
    flags.type = Dart_CObject_kInt32;
    flags.value.as_int32 = document->flags;

    if (hasError) {
      objectValues[2] = &errorDomain;
      errorDomain.type = Dart_CObject_kInt32;
      errorDomain.value.as_int32 = document->error.domain;

      objectValues[3] = &errorCode;
      errorCode.type = Dart_CObject_kInt32;
      errorCode.value.as_int32 = document->error.code;

      objectValues[4] = &errorMessage;
      CBLDart_CObject_SetFLString(&errorMessage,
                                  static_cast<FLString>(errorMessageStr));
    }
  }

  ~CObject_ReplicatedDocument() { FLSliceResult_Release(errorMessageStr); }

  Dart_CObject *cObject() { return &object; }

 private:
  Dart_CObject object;
  Dart_CObject *objectValues[5];
  Dart_CObject id;
  Dart_CObject flags;
  Dart_CObject errorDomain;
  Dart_CObject errorCode;
  Dart_CObject errorMessage;

  FLSliceResult errorMessageStr = {nullptr, 0};
};

void CBLDart_Replicator_DocumentReplicationListenerWrapper(
    void *context, CBLReplicator *replicator, bool isPush,
    unsigned numDocuments, const CBLReplicatedDocument *documents) {
  auto callback = CBLDart_AsAsyncCallback(context);

  Dart_CObject isPush_;
  isPush_.type = Dart_CObject_kBool;
  isPush_.value.as_bool = isPush;

  CObject_ReplicatedDocument cObjectDocuments[numDocuments];
  Dart_CObject *cObjectDocumentArrayValues[numDocuments];

  for (size_t i = 0; i < numDocuments; i++) {
    auto cObjectDocument = &cObjectDocuments[i];
    cObjectDocument->init(&documents[i]);
    cObjectDocumentArrayValues[i] = cObjectDocument->cObject();
  }

  Dart_CObject cObjectDocumentsArray;
  cObjectDocumentsArray.type = Dart_CObject_kArray;
  cObjectDocumentsArray.value.as_array.length = numDocuments;
  cObjectDocumentsArray.value.as_array.values = cObjectDocumentArrayValues;

  Dart_CObject *argsValues[] = {&isPush_, &cObjectDocumentsArray};

  Dart_CObject args;
  args.type = Dart_CObject_kArray;
  args.value.as_array.length = 2;
  args.value.as_array.values = argsValues;

  CBLDart::AsyncCallbackCall(*callback).execute(args);
}

void CBLDart_CBLReplicator_AddDocumentReplicationListener(
    CBLReplicator *replicator, CBLDart::AsyncCallback *listener) {
  auto listenerToken = CBLReplicator_AddDocumentReplicationListener(
      replicator, CBLDart_Replicator_DocumentReplicationListenerWrapper,
      (void *)listener);

  listener->setFinalizer(listenerToken, CBLDart_CBLListenerFinalizer);
}
