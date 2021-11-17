#include <future>
#include <map>
#include <mutex>
#include <shared_mutex>
#include <thread>

#include "AsyncCallback.h"
#include "CBL+Dart.h"
#include "Sentry.h"
#include "Utils.h"

static std::mutex initializeMutex;
static bool initialized = false;

bool CBLDart_Initialize(void *dartInitializeDlData, void *cblInitContext,
                        CBLError *errorOut) {
  std::scoped_lock lock(initializeMutex);

  if (initialized) {
    // Only initialize libraries once.
    return true;
  }

#ifdef __ANDROID__
  // Initialize the Couchbase Lite library.
  if (!CBL_Init(*reinterpret_cast<CBLInitContext *>(cblInitContext),
                errorOut)) {
    return false;
  }
#endif

  // Initialize the Dart API for this dynamic library.
  Dart_InitializeApiDL(dartInitializeDlData);

  initialized = true;
  return true;
}

// === Dart Native ============================================================

// === Async Callbacks

#define ASYNC_CALLBACK_FROM_C(callback) \
  reinterpret_cast<CBLDart::AsyncCallback *>(callback)

#define ASYNC_CALLBACK_TO_C(callback) \
  reinterpret_cast<CBLDart_AsyncCallback>(callback)

CBLDart_AsyncCallback CBLDart_AsyncCallback_New(uint32_t id, Dart_Handle object,
                                                Dart_Port sendPort,
                                                uint8_t debug) {
  return ASYNC_CALLBACK_TO_C(
      new CBLDart::AsyncCallback(id, object, sendPort, debug));
}

void CBLDart_AsyncCallback_Close(CBLDart_AsyncCallback callback) {
  auto callback_ = ASYNC_CALLBACK_FROM_C(callback);
  callback_->close();
  delete callback_;
}

void CBLDart_AsyncCallback_CallForTest(CBLDart_AsyncCallback callback,
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

    CBLDart::AsyncCallbackCall(*ASYNC_CALLBACK_FROM_C(callback)).execute(args);
  }).detach();
}

static CBLDart::AsyncCallback *CBLDart_AsAsyncCallback(void *pointer) {
  return reinterpret_cast<CBLDart::AsyncCallback *>(pointer);
}

// === Dart Finalizer

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
  auto context = new CBLDart_DartFinalizerContext;
  context->registry = registry;
  context->token = token;

  Dart_NewFinalizableHandle_DL(object, context, 0, CBLDart_RunDartFinalizer);
}

// === Couchbase Lite =========================================================

// === Base

CBLDart_FLStringResult CBLDart_CBLError_Message(CBLError *error) {
  return CBLDart_FLStringResultToDart(CBLError_Message(error));
}

#ifdef DEBUG
static bool cblRefCountedDebugEnabled = false;
static std::map<CBLRefCounted *, std::string> cblRefCountedDebugNames;
static std::mutex cblRefCountedDebugMutex;
#endif

inline void CBLDart_CBLRefCountedFinalizer_Impl(CBLRefCounted *refCounted) {
#ifdef DEBUG
  std::string debugName;
  {
    std::scoped_lock lock(cblRefCountedDebugMutex);
    auto nh = cblRefCountedDebugNames.extract(refCounted);
    if (!nh.empty()) {
      debugName = nh.mapped();
    }
  }
  if (!debugName.empty()) {
    if (cblRefCountedDebugEnabled) {
      printf("CBLRefCountedFinalizer: %p %s\n", refCounted, debugName.c_str());
    }
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
static void CBLDart_CBLRefCountedFinalizer(void *dart_callback_data,
                                           void *peer) {
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

static std::mutex listenerTokenToDatabaseMutex;
static std::map<CBLListenerToken *, const CBLDatabase *>
    listenerTokenToDatabase;

static void CBLDart_RetainDatabaseForListenerToken(const CBLDatabase *database,
                                                   CBLListenerToken *token) {
  CBLDatabase_Retain(database);

  std::scoped_lock lock(listenerTokenToDatabaseMutex);
  listenerTokenToDatabase[token] = database;
}

static void CBLDart_CBLListenerFinalizer(void *context) {
  auto listenerToken = reinterpret_cast<CBLListenerToken *>(context);
  CBLListener_Remove(listenerToken);

  std::scoped_lock lock(listenerTokenToDatabaseMutex);
  auto nh = listenerTokenToDatabase.extract(listenerToken);
  if (!nh.empty()) {
    CBLDatabase_Release(nh.mapped());
  }
}

// === Log

static std::shared_mutex loggingMutex;
static CBLDart::AsyncCallback *logCallback = nullptr;
static CBLLogLevel logCallbackLevel = CBLLog_CallbackLevel();
static CBLDart_CBLLogFileConfiguration *logFileConfig = nullptr;
static bool logSentryBreadcrumbsEnabled = false;

// Forward declarations for the logging functions.
static void CBLDart_LogSentryBreadcrumb(CBLLogDomain domain, CBLLogLevel level,
                                        FLString message);
static void CBLDart_CallDartLogCallback(CBLLogDomain domain, CBLLogLevel level,
                                        FLString message);

static void CBLDart_LogCallback(CBLLogDomain domain, CBLLogLevel level,
                                FLString message) {
  if (logSentryBreadcrumbsEnabled) {
    CBLDart_LogSentryBreadcrumb(domain, level, message);
  }

  if (level >= logCallbackLevel) {
    CBLDart_CallDartLogCallback(domain, level, message);
  }
}

static void CBLDart_UpdateEffectiveLogCallback() {
  if (logSentryBreadcrumbsEnabled || logCallback) {
    CBLLog_SetCallback(CBLDart_LogCallback);
  } else {
    CBLLog_SetCallback(nullptr);
  }
}

static void CBLDart_UpdateEffectiveLogCallbackLevel() {
  if (logSentryBreadcrumbsEnabled) {
    CBLLog_SetCallbackLevel(kCBLLogDebug);
  } else {
    CBLLog_SetCallbackLevel(logCallbackLevel);
  }
}

void CBLDart_CBL_LogMessage(CBLLogDomain domain, CBLLogLevel level,
                            CBLDart_FLString message) {
  CBL_Log(domain, level, "%.*s", static_cast<int>(message.size),
          static_cast<const char *>(message.buf));
}

static void CBLDart_CallDartLogCallback(CBLLogDomain domain, CBLLogLevel level,
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

static void CBLDart_LogCallbackFinalizer(void *context) {
  std::unique_lock lock(loggingMutex);
  logCallback = nullptr;
  CBLDart_UpdateEffectiveLogCallback();
  CBLDart_UpdateEffectiveLogCallbackLevel();
}

uint8_t CBLDart_CBLLog_SetCallback(CBLDart_AsyncCallback callback) {
  std::unique_lock lock(loggingMutex);
  auto callback_ = ASYNC_CALLBACK_FROM_C(callback);

  // Don't set the new callback if one has already been set. Another isolate,
  // different from the one currenlty calling, has already set its callback.
  if (callback_ != nullptr && logCallback != nullptr) {
    return false;
  }

  if (callback_ == nullptr) {
    logCallback = nullptr;
  } else {
    logCallback = callback_;
    callback_->setFinalizer(nullptr, CBLDart_LogCallbackFinalizer);
  }
  CBLDart_UpdateEffectiveLogCallback();

  return true;
}

void CBLDart_CBLLog_SetCallbackLevel(CBLLogLevel level) {
  std::unique_lock lock(loggingMutex);
  logCallbackLevel = level;
  CBLDart_UpdateEffectiveLogCallbackLevel();
}

uint8_t CBLDart_CBLLog_SetFileConfig(CBLDart_CBLLogFileConfiguration *config,
                                     CBLError *errorOut) {
  std::unique_lock lock(loggingMutex);

  if (!config) {
    CBLLogFileConfiguration config_;
    config_.level = kCBLLogNone;
    config_.directory = {nullptr, 0};
    config_.maxRotateCount = 0;
    config_.maxSize = 0;
    config_.usePlaintext = false;

    auto success = CBLLog_SetFileConfig(config_, errorOut);
    if (success) {
      if (logFileConfig) {
        delete logFileConfig;
        logFileConfig = nullptr;
      }
    }
    return success;
  } else {
    CBLLogFileConfiguration config_;
    config_.level = config->level;
    config_.directory = CBLDart_FLStringFromDart(config->directory);
    config_.maxRotateCount = config->maxRotateCount;
    config_.maxSize = static_cast<size_t>(config->maxSize);
    config_.usePlaintext = static_cast<bool>(config->usePlaintext);

    auto success = CBLLog_SetFileConfig(config_, errorOut);
    if (success) {
      auto config_ = CBLLog_FileConfig();
      if (!logFileConfig) {
        logFileConfig = new CBLDart_CBLLogFileConfiguration;
      }
      logFileConfig->level = config_->level;
      logFileConfig->directory = CBLDart_FLStringToDart(config_->directory);
      logFileConfig->maxRotateCount = config_->maxRotateCount;
      logFileConfig->maxSize = config->maxSize;
      logFileConfig->usePlaintext = config_->usePlaintext;
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

static const char *CBLDart_LogDomainToSentryCategory(CBLLogDomain domain) {
  switch (domain) {
    case kCBLLogDomainDatabase:
      return "cbl.db";
    case kCBLLogDomainQuery:
      return "cbl.query";
    case kCBLLogDomainReplicator:
      return "cbl.sync";
    case kCBLLogDomainNetwork:
      return "cbl.ws";
    default:
      return nullptr;
  }
}

static const char *CBLDart_LogLevelToSentryLevel(CBLLogLevel level) {
  switch (level) {
    case kCBLLogDebug:
    case kCBLLogVerbose:
      return "debug";
    case kCBLLogInfo:
      return "info";
    case kCBLLogWarning:
      return "warning";
    case kCBLLogError:
      return "error";
    case kCBLLogNone:
    default:
      return nullptr;
  }
}

static void CBLDart_LogSentryBreadcrumb(CBLLogDomain domain, CBLLogLevel level,
                                        FLString message) {
  // Prepare breadcrumb data.
  auto sentryCategory = CBLDart_LogDomainToSentryCategory(domain);
  auto sentryLevel = CBLDart_LogLevelToSentryLevel(level);
  auto message_ = CBLDart_FLStringToString(message);

  // Build breadcrumb.
  auto breadcrumb = sentry_value_new_breadcrumb("debug", message_.c_str());
  sentry_value_set_by_key(breadcrumb, "category",
                          sentry_value_new_string(sentryCategory));
  if (sentryLevel) {
    sentry_value_set_by_key(breadcrumb, "level",
                            sentry_value_new_string(sentryLevel));
  }

  // Add breadcrumb to sentry.
  sentry_add_breadcrumb(breadcrumb);
}

bool CBLDart_CBLLog_SetSentryBreadcrumbs(bool enabled) {
  if (!CBLDart_InitSentryAPI()) {
    // Setntry is not available, so we can't enable breadcrumbs logging.
    return false;
  }

  std::unique_lock lock(loggingMutex);
  logSentryBreadcrumbsEnabled = enabled;
  CBLDart_UpdateEffectiveLogCallback();
  CBLDart_UpdateEffectiveLogCallbackLevel();
  return true;
}

// === Document

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

// === Database

static CBLDart_CBLDatabaseConfiguration CBLDart_CBLDatabaseConfigurationToDart(
    CBLDatabaseConfiguration config) {
  CBLDart_CBLDatabaseConfiguration config_;
  config_.directory = CBLDart_FLStringToDart(config.directory);
#ifdef COUCHBASE_ENTERPRISE
  config_.encryptionKey = config.encryptionKey;
#endif
  return config_;
}

static CBLDatabaseConfiguration CBLDart_CBLDatabaseConfigurationFromDart(
    CBLDart_CBLDatabaseConfiguration config) {
  CBLDatabaseConfiguration config_;
  config_.directory = CBLDart_FLStringFromDart(config.directory);
#ifdef COUCHBASE_ENTERPRISE
  config_.encryptionKey = config.encryptionKey;
#endif
  return config_;
}

#ifdef COUCHBASE_ENTERPRISE
bool CBLDart_CBLEncryptionKey_FromPassword(CBLEncryptionKey *key,
                                           CBLDart_FLString password) {
  return CBLEncryptionKey_FromPassword(key, CBLDart_FLStringFromDart(password));
}
#endif

/**
 * A list of all the currently open database.
 *
 * Used to ensure that databases are closed only once.
 */
static std::vector<CBLDatabase *> openDatabases;
static std::mutex openDatabasesMutex;

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
  return CBLDart_CBLDatabaseConfigurationToDart(
      CBLDatabaseConfiguration_Default());
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
  auto config_ = CBLDart_CBLDatabaseConfigurationFromDart(*config);
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

  auto config_ = config ? CBLDart_CBLDatabaseConfigurationFromDart(*config)
                        : CBLDatabaseConfiguration_Default();

  auto database =
      CBLDatabase_Open(CBLDart_FLStringFromDart(name), &config_, errorOut);

  if (database) {
    CBLDart_RegisterOpenDatabase(database);
  }

  return database;
}

static void CBLDart_DatabaseFinalizer(void *dart_callback_data, void *peer) {
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
  return CBLDart_CBLDatabaseConfigurationToDart(CBLDatabase_Config(db));
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

static void CBLDart_DocumentChangeListenerWrapper(void *context,
                                                  const CBLDatabase *db,
                                                  FLString docID) {
  auto callback = CBLDart_AsAsyncCallback(context);

  Dart_CObject args;
  CBLDart_CObject_SetEmptyArray(&args);

  CBLDart::AsyncCallbackCall(*callback).execute(args);
}

void CBLDart_CBLDatabase_AddDocumentChangeListener(
    const CBLDatabase *db, const CBLDart_FLString docID,
    CBLDart_AsyncCallback listener) {
  auto listenerToken = CBLDatabase_AddDocumentChangeListener(
      db, CBLDart_FLStringFromDart(docID),
      CBLDart_DocumentChangeListenerWrapper, listener);

  // TODO(blaugold): remove this when bug fix in CBL has landed
  // https://issues.couchbase.com/browse/CBL-2548
  CBLDart_RetainDatabaseForListenerToken(db, listenerToken);

  ASYNC_CALLBACK_FROM_C(listener)->setFinalizer(listenerToken,
                                                CBLDart_CBLListenerFinalizer);
}

static void CBLDart_DatabaseChangeListenerWrapper(void *context,
                                                  const CBLDatabase *db,
                                                  unsigned numDocs,
                                                  FLString *docIDs) {
  auto callback = CBLDart_AsAsyncCallback(context);

  std::vector<Dart_CObject> docIdObjects(numDocs);

  for (size_t i = 0; i < numDocs; i++) {
    CBLDart_CObject_SetFLString(&docIdObjects[i], docIDs[i]);
  }

  auto docIdObjectsArray = docIdObjects.data();

  Dart_CObject args;
  args.type = Dart_CObject_kArray;
  args.value.as_array.length = numDocs;
  args.value.as_array.values = &docIdObjectsArray;

  CBLDart::AsyncCallbackCall(*callback).execute(args);
}

void CBLDart_CBLDatabase_AddChangeListener(const CBLDatabase *db,
                                           CBLDart_AsyncCallback listener) {
  auto listenerToken = CBLDatabase_AddChangeListener(
      db, CBLDart_DatabaseChangeListenerWrapper, listener);

  ASYNC_CALLBACK_FROM_C(listener)->setFinalizer(listenerToken,
                                                CBLDart_CBLListenerFinalizer);
}

uint8_t CBLDart_CBLDatabase_CreateIndex(CBLDatabase *db, CBLDart_FLString name,
                                        CBLDart_CBLIndexSpec indexSpec,
                                        CBLError *errorOut) {
  switch (indexSpec.type) {
    case kCBLDart_IndexTypeValue: {
      CBLValueIndexConfiguration config;
      config.expressionLanguage = indexSpec.expressionLanguage;
      config.expressions = CBLDart_FLStringFromDart(indexSpec.expressions);

      return CBLDatabase_CreateValueIndex(db, CBLDart_FLStringFromDart(name),
                                          config, errorOut);
    }
    case kCBLDart_IndexTypeFullText: {
    }
      CBLFullTextIndexConfiguration config;
      config.expressionLanguage = indexSpec.expressionLanguage;
      config.expressions = CBLDart_FLStringFromDart(indexSpec.expressions);
      config.ignoreAccents = static_cast<bool>(indexSpec.ignoreAccents);
      config.language = CBLDart_FLSliceFromDart(indexSpec.language);

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

// === Query

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

static void CBLDart_QueryChangeListenerWrapper(void *context, CBLQuery *query,
                                               CBLListenerToken *token) {
  auto callback = CBLDart_AsAsyncCallback(context);

  Dart_CObject args;
  CBLDart_CObject_SetEmptyArray(&args);

  CBLDart::AsyncCallbackCall(*callback).execute(args);
}

CBLListenerToken *CBLDart_CBLQuery_AddChangeListener(
    CBLQuery *query, CBLDart_AsyncCallback listener) {
  auto listenerToken = CBLQuery_AddChangeListener(
      query, CBLDart_QueryChangeListenerWrapper, listener);

  ASYNC_CALLBACK_FROM_C(listener)->setFinalizer(listenerToken,
                                                CBLDart_CBLListenerFinalizer);

  return listenerToken;
}

// === Blob

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

// === Replicator

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

static std::map<CBLReplicator *, ReplicatorCallbackWrapperContext *>
    replicatorCallbackWrapperContexts;
static std::mutex replicatorCallbackWrapperContexts_mutex;

static bool CBLDart_ReplicatorFilterWrapper(CBLDart::AsyncCallback *callback,
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

static bool CBLDart_ReplicatorPullFilterWrapper(void *context,
                                                CBLDocument *document,
                                                CBLDocumentFlags flags) {
  auto wrapperContext =
      reinterpret_cast<ReplicatorCallbackWrapperContext *>(context);
  return CBLDart_ReplicatorFilterWrapper(wrapperContext->pullFilter, document,
                                         flags);
}

static bool CBLDart_ReplicatorPushFilterWrapper(void *context,
                                                CBLDocument *document,
                                                CBLDocumentFlags flags) {
  auto wrapperContext =
      reinterpret_cast<ReplicatorCallbackWrapperContext *>(context);
  return CBLDart_ReplicatorFilterWrapper(wrapperContext->pushFilter, document,
                                         flags);
}

static const CBLDocument *CBLDart_ReplicatorConflictResolverWrapper(
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
      case Dart_CObject_kInt32:
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
        auto message = std::string(
            "Unexpected result from replicator conflict resolver, with "
            "Dart_CObject_Type: ");
        message += std::to_string(result->type);

        throw std::logic_error(message);
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
  config_.pinnedServerCertificate =
      config->pinnedServerCertificate == nullptr
          ? kFLSliceNull
          : CBLDart_FLSliceFromDart(*config->pinnedServerCertificate);
  config_.trustedRootCertificates =
      config->trustedRootCertificates == nullptr
          ? kFLSliceNull
          : CBLDart_FLSliceFromDart(*config->trustedRootCertificates);
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
  context->pullFilter = ASYNC_CALLBACK_FROM_C(config->pullFilter);
  context->pushFilter = ASYNC_CALLBACK_FROM_C(config->pushFilter);
  context->conflictResolver = ASYNC_CALLBACK_FROM_C(config->conflictResolver);
  config_.context = context;

#ifdef COUCHBASE_ENTERPRISE
  config_.propertyEncryptor = nullptr;
  config_.propertyDecryptor = nullptr;
#endif

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

static void CBLDart_ReplicatorFinalizer(void *dart_callback_data, void *peer) {
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

class ReplicatorStatus_CObject_Helper {
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

  ~ReplicatorStatus_CObject_Helper() { FLSliceResult_Release(errorMessageStr); }

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

static void CBLDart_Replicator_ChangeListenerWrapper(
    void *context, CBLReplicator *replicator,
    const CBLReplicatorStatus *status) {
  auto callback = CBLDart_AsAsyncCallback(context);

  ReplicatorStatus_CObject_Helper cObjectStatus;
  cObjectStatus.init(status);

  Dart_CObject *argsValues[] = {cObjectStatus.cObject()};

  Dart_CObject args;
  args.type = Dart_CObject_kArray;
  args.value.as_array.length = 1;
  args.value.as_array.values = argsValues;

  CBLDart::AsyncCallbackCall(*callback).execute(args);
}

void CBLDart_CBLReplicator_AddChangeListener(CBLReplicator *replicator,
                                             CBLDart_AsyncCallback listener) {
  auto listenerToken = CBLReplicator_AddChangeListener(
      replicator, CBLDart_Replicator_ChangeListenerWrapper, listener);

  ASYNC_CALLBACK_FROM_C(listener)->setFinalizer(listenerToken,
                                                CBLDart_CBLListenerFinalizer);
}

class ReplicatedDocument_CObject_Helper {
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

  ~ReplicatedDocument_CObject_Helper() {
    FLSliceResult_Release(errorMessageStr);
  }

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

static void CBLDart_Replicator_DocumentReplicationListenerWrapper(
    void *context, CBLReplicator *replicator, bool isPush,
    unsigned numDocuments, const CBLReplicatedDocument *documents) {
  auto callback = CBLDart_AsAsyncCallback(context);

  Dart_CObject isPush_;
  isPush_.type = Dart_CObject_kBool;
  isPush_.value.as_bool = isPush;

  std::vector<ReplicatedDocument_CObject_Helper> documentObjectHelpers(
      numDocuments);
  std::vector<Dart_CObject *> documentObjects(numDocuments);

  for (size_t i = 0; i < numDocuments; i++) {
    auto helper = &documentObjectHelpers[i];
    helper->init(&documents[i]);
    documentObjects[i] = helper->cObject();
  }

  Dart_CObject cObjectDocumentsArray;
  cObjectDocumentsArray.type = Dart_CObject_kArray;
  cObjectDocumentsArray.value.as_array.length = numDocuments;
  cObjectDocumentsArray.value.as_array.values = documentObjects.data();

  Dart_CObject *argsValues[] = {&isPush_, &cObjectDocumentsArray};

  Dart_CObject args;
  args.type = Dart_CObject_kArray;
  args.value.as_array.length = 2;
  args.value.as_array.values = argsValues;

  CBLDart::AsyncCallbackCall(*callback).execute(args);
}

void CBLDart_CBLReplicator_AddDocumentReplicationListener(
    CBLReplicator *replicator, CBLDart_AsyncCallback listener) {
  auto listenerToken = CBLReplicator_AddDocumentReplicationListener(
      replicator, CBLDart_Replicator_DocumentReplicationListenerWrapper,
      (void *)listener);

  ASYNC_CALLBACK_FROM_C(listener)->setFinalizer(listenerToken,
                                                CBLDart_CBLListenerFinalizer);
}
