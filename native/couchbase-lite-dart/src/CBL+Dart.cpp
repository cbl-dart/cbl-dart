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

CBLDartInitializeResult CBLDart_Initialize(void *dartInitializeDlData,
                                           void *cblInitContext,
                                           CBLError *errorOut) {
  std::scoped_lock lock(initializeMutex);

  if (initialized) {
    // Only initialize libraries once.
    return CBLDartInitializeResult_kSuccess;
  }

#ifdef __ANDROID__
  // Initialize the Couchbase Lite library.
  if (!CBL_Init(*reinterpret_cast<CBLInitContext *>(cblInitContext),
                errorOut)) {
    return CBLDartInitializeResult_kCBLInitError;
  }
#endif

  // Initialize the Dart API for this dynamic library.
  if (Dart_InitializeApiDL(dartInitializeDlData) != 0) {
    return CBLDartInitializeResult_kIncompatibleDartVM;
  }

  initialized = true;
  return CBLDartInitializeResult_kSuccess;
}

// === Dart Native ============================================================

// === Async Callbacks

#define ASYNC_CALLBACK_FROM_C(callback) \
  reinterpret_cast<CBLDart::AsyncCallback *>(callback)

#define ASYNC_CALLBACK_TO_C(callback) \
  reinterpret_cast<CBLDart_AsyncCallback>(callback)

CBLDart_AsyncCallback CBLDart_AsyncCallback_New(uint32_t id, Dart_Port sendPort,
                                                bool debug) {
  return ASYNC_CALLBACK_TO_C(new CBLDart::AsyncCallback(id, sendPort, debug));
}

void CBLDart_AsyncCallback_Delete(CBLDart_AsyncCallback callback) {
  delete ASYNC_CALLBACK_FROM_C(callback);
}

void CBLDart_AsyncCallback_Close(CBLDart_AsyncCallback callback) {
  ASYNC_CALLBACK_FROM_C(callback)->close();
}

void CBLDart_AsyncCallback_CallForTest(CBLDart_AsyncCallback callback,
                                       int64_t argument) {
  std::thread([=]() {
    Dart_CObject argument__{};
    argument__.type = Dart_CObject_kInt64;
    argument__.value.as_int64 = argument;

    Dart_CObject *argsValues[] = {&argument__};

    Dart_CObject args{};
    args.type = Dart_CObject_kArray;
    args.value.as_array.length = 1;
    args.value.as_array.values = argsValues;

    CBLDart::AsyncCallbackCall(*ASYNC_CALLBACK_FROM_C(callback)).execute(args);
  }).detach();
}

// === Couchbase Lite =========================================================

// === Database level locking

/**
 * Database level locking is only required in certain scenarios.
 *
 * Any given database is only ever accessed by the same Dart isolate. Since
 * Dart isolates are single threaded, we can safely use the CBL C API, which is
 * generally not thread safe.
 *
 * An exception are native finalizers. These are called from the Dart VM during
 * GC. Even though the Dart isolate will never execute while native finalizers
 * are running, native code called through FFI from the Dart isolate can.
 *
 * According to the CBL C docs we need to serialize all access to a database
 * instance and objects that belong to it. In reality, many operations of the
 * CBL C API are thread safe. We only use locking for the operations where it
 * turned out that it is necessary.
 *
 * Specifically we need to ensure that:
 *
 * - listeners are not finalized while the database is closing.
 * - replicators are not stopped while the database is closing.
 */

/**
 * Mapping of objects to the mutex that is used for database level locking of
 * the database the objects belong to.
 *
 * Every object in this mapping owns a shared_ptr to the database level mutex.
 *
 * `CBLDart_CreateDatabaseLock`, `CBLDart_CloneDatabaseLock`,
 * `CBLDart_AcquireDatabaseLock` and `CBLDart_ReleaseDatabaseLock` are used
 * to create, clone and acquire and release (the shared_ptr, not the lock)
 * database level locks.
 *
 * When a database is opened it uses `CBLDart_CreateDatabaseLock` to create the
 * mutex that belongs to the database.
 *
 * Other objects that need to lock access to the database use
 * `CBLDart_CloneDatabaseLock` to create a shared_ptr to the mutex of the
 * database they belong to.
 *
 * Callers of `CBLDart_CloneDatabaseLock` must ensure that the database is
 * still open when they call `CBLDart_CloneDatabaseLock`.
 *
 * These objects can then use `CBLDart_AcquireDatabaseLock` to acquire the
 * database level lock by providing a pointer to themself.
 *
 * When an object that has cloned a lock is destroyed it must call
 * `CBLDart_ReleaseDatabaseLock`.
 */
static std::map<void *, std::shared_ptr<std::mutex>> databaseMutexes;
static std::mutex databaseMutexesMutex;

static void CBLDart_CreateDatabaseLock(CBLDatabase *database) {
  std::scoped_lock lock(databaseMutexesMutex);
  databaseMutexes[database] = std::make_shared<std::mutex>();
}

static void CBLDart_CloneDatabaseLock(const CBLDatabase *database,
                                      void *owner) {
  std::scoped_lock lock(databaseMutexesMutex);
  assert(databaseMutexes.find(const_cast<CBLDatabase *>(database)) !=
         databaseMutexes.end());
  databaseMutexes[owner] = databaseMutexes[const_cast<CBLDatabase *>(database)];
}

static std::scoped_lock<std::mutex> CBLDart_AcquireDatabaseLock(void *owner) {
  std::scoped_lock lock(databaseMutexesMutex);
  return std::scoped_lock(*databaseMutexes[owner]);
}

static void CBLDart_ReleaseDatabaseLock(void *owner) {
  std::scoped_lock lock(databaseMutexesMutex);
  databaseMutexes.erase(owner);
}

// === Base

// Listeners that use this finalizer must use `CBLDart_CloneDatabaseLock`
// to retain the database lock of the database they belong to.
static void CBLDart_CBLListenerFinalizer(void *context) {
  auto listenerToken = reinterpret_cast<CBLListenerToken *>(context);
  {
    // We acquire the database lock here to ensure that the database is not
    // closed while we are still executing.
    auto databaseLock = CBLDart_AcquireDatabaseLock(listenerToken);
    CBLListener_Remove(listenerToken);
  }
  CBLDart_ReleaseDatabaseLock(listenerToken);
}

// === Log

static std::shared_mutex loggingMutex;
static CBLDart::AsyncCallback *logCallback = nullptr;
static CBLLogLevel logCallbackLevel = CBLLog_CallbackLevel();
static CBLLogFileConfiguration *logFileConfig = nullptr;
static bool logSentryBreadcrumbsEnabled = false;

// Forward declarations for the logging functions.
static void CBLDart_LogSentryBreadcrumb(CBLLogDomain domain, CBLLogLevel level,
                                        FLString message);
static void CBLDart_CallDartLogCallback(CBLLogDomain domain, CBLLogLevel level,
                                        FLString message);

static void CBLDart_LogCallback(CBLLogDomain domain, CBLLogLevel level,
                                FLString message) {
  std::shared_lock lock(loggingMutex);

  if (logSentryBreadcrumbsEnabled) {
    CBLDart_LogSentryBreadcrumb(domain, level, message);
  }

  if (logCallback && level >= logCallbackLevel) {
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

static void CBLDart_CallDartLogCallback(CBLLogDomain domain, CBLLogLevel level,
                                        FLString message) {
  Dart_CObject domain_{};
  domain_.type = Dart_CObject_kInt32;
  domain_.value.as_int32 = static_cast<int32_t>(domain);

  Dart_CObject level_{};
  level_.type = Dart_CObject_kInt32;
  level_.value.as_int32 = static_cast<int32_t>(level);

  Dart_CObject message_{};
  CBLDart_CObject_SetFLString(&message_, message);

  Dart_CObject *argsValues[] = {&domain_, &level_, &message_};

  Dart_CObject args{};
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

bool CBLDart_CBLLog_SetCallback(CBLDart_AsyncCallback callback) {
  std::unique_lock lock(loggingMutex);
  auto callback_ = ASYNC_CALLBACK_FROM_C(callback);

  // Don't set the new callback if one has already been set. Another isolate,
  // different from the one currently calling, has already set its callback.
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

bool CBLDart_CBLLog_SetFileConfig(CBLLogFileConfiguration *config,
                                  CBLError *errorOut) {
  std::unique_lock lock(loggingMutex);

  if (!config) {
    CBLLogFileConfiguration config_{};
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
    CBLLogFileConfiguration config_{};
    config_.level = config->level;
    config_.directory = config->directory;
    config_.maxRotateCount = config->maxRotateCount;
    config_.maxSize = config->maxSize;
    config_.usePlaintext = config->usePlaintext;

    auto success = CBLLog_SetFileConfig(config_, errorOut);
    if (success) {
      auto config_ = CBLLog_FileConfig();
      if (!logFileConfig) {
        logFileConfig = new CBLLogFileConfiguration{};
      }
      logFileConfig->level = config_->level;
      logFileConfig->directory = config_->directory;
      logFileConfig->maxRotateCount = config_->maxRotateCount;
      logFileConfig->maxSize = config_->maxSize;
      logFileConfig->usePlaintext = config_->usePlaintext;
    }
    return success;
  }
}

CBLLogFileConfiguration *CBLDart_CBLLog_GetFileConfig() {
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
    // Sentry is not available, so we can't enable breadcrumbs logging.
    return false;
  }

  std::unique_lock lock(loggingMutex);
  logSentryBreadcrumbsEnabled = enabled;
  CBLDart_UpdateEffectiveLogCallback();
  CBLDart_UpdateEffectiveLogCallbackLevel();
  return true;
}

// === Database

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

static bool CBLDart_UnregisterOpenDatabase(CBLDatabase *database) {
  std::scoped_lock lock(openDatabasesMutex);
  // Check if the database is still open.
  auto it = std::find(openDatabases.begin(), openDatabases.end(), database);
  if (it == openDatabases.end()) {
    // The database has already been closed.
    return false;
  }

  // Remove the database from the list of open database and close it.
  openDatabases.erase(it);
  return true;
}

bool CBLDart_CBLDatabase_Close(CBLDatabase *database, bool andDelete,
                               CBLError *errorOut) {
  if (!CBLDart_UnregisterOpenDatabase(database)) {
    // Return early since the database has already been closed.
    return true;
  }

  // We close the database under a lock to ensure that certain finalizers are
  // not running while the database is being closed.
  auto databaseLock = CBLDart_AcquireDatabaseLock(database);
  if (andDelete) {
    return CBLDatabase_Delete(database, errorOut);
  } else {
    return CBLDatabase_Close(database, errorOut);
  }
}

CBLDatabase *CBLDart_CBLDatabase_Open(FLString name,
                                      CBLDatabaseConfiguration *config,
                                      CBLError *errorOut) {
  CBLDart_CheckFileLogging();

  auto config_ = config ? *config : CBLDatabaseConfiguration_Default();

  auto database = CBLDatabase_Open(name, &config_, errorOut);

  if (database) {
    CBLDart_RegisterOpenDatabase(database);
    CBLDart_CreateDatabaseLock(database);
  }

  return database;
}

void CBLDart_CBLDatabase_Release(CBLDatabase *database) {
  CBLError error;
  if (!CBLDart_CBLDatabase_Close(database, false, &error)) {
    auto errorMessage = CBLError_Message(&error);
    CBL_Log(kCBLLogDomainDatabase, kCBLLogError,
            "Error closing database %p in Dart finalizer: %*.s", database,
            static_cast<int>(errorMessage.size), (char *)errorMessage.buf);
    FLSliceResult_Release(errorMessage);
  }
  CBLDart_ReleaseDatabaseLock(database);
  CBLDatabase_Release(database);
}

// === Collection

static void CBLDart_CollectionDocumentChangeListenerWrapper(
    void *context, const CBLDocumentChange *change) {
  auto callback = ASYNC_CALLBACK_FROM_C(context);

  Dart_CObject args{};
  CBLDart_CObject_SetEmptyArray(&args);

  CBLDart::AsyncCallbackCall(*callback).execute(args);
}

void CBLDart_CBLCollection_AddDocumentChangeListener(
    const CBLDatabase *db, const CBLCollection *collection,
    const FLString docID, CBLDart_AsyncCallback listener) {
  auto listenerToken = CBLCollection_AddDocumentChangeListener(
      collection, docID, CBLDart_CollectionDocumentChangeListenerWrapper,
      listener);

  CBLDart_CloneDatabaseLock(db, listenerToken);

  ASYNC_CALLBACK_FROM_C(listener)->setFinalizer(listenerToken,
                                                CBLDart_CBLListenerFinalizer);
}

static void CBLDart_CollectionChangeListenerWrapper(
    void *context, const CBLCollectionChange *change) {
  auto callback = ASYNC_CALLBACK_FROM_C(context);
  auto numDocs = change->numDocs;
  auto docIDs = change->docIDs;

  std::vector<Dart_CObject> docIdObjects(numDocs);

  for (size_t i = 0; i < numDocs; i++) {
    CBLDart_CObject_SetFLString(&docIdObjects[i], docIDs[i]);
  }

  auto docIdObjectsArray = docIdObjects.data();

  Dart_CObject args{};
  args.type = Dart_CObject_kArray;
  args.value.as_array.length = numDocs;
  args.value.as_array.values = &docIdObjectsArray;

  CBLDart::AsyncCallbackCall(*callback).execute(args);
}

void CBLDart_CBLCollection_AddChangeListener(const CBLDatabase *db,
                                             const CBLCollection *collection,
                                             CBLDart_AsyncCallback listener) {
  auto listenerToken = CBLCollection_AddChangeListener(
      collection, CBLDart_CollectionChangeListenerWrapper, listener);

  CBLDart_CloneDatabaseLock(db, listenerToken);

  ASYNC_CALLBACK_FROM_C(listener)->setFinalizer(listenerToken,
                                                CBLDart_CBLListenerFinalizer);
}

bool CBLDart_CBLCollection_CreateIndex(CBLCollection *collection, FLString name,
                                       CBLDart_CBLIndexSpec indexSpec,
                                       CBLError *errorOut) {
  switch (indexSpec.type) {
    case kCBLDart_IndexTypeValue: {
      CBLValueIndexConfiguration config{};
      config.expressionLanguage = indexSpec.expressionLanguage;
      config.expressions = indexSpec.expressions;

      return CBLCollection_CreateValueIndex(collection, name, config, errorOut);
    }
    case kCBLDart_IndexTypeFullText: {
    }
      CBLFullTextIndexConfiguration config{};
      config.expressionLanguage = indexSpec.expressionLanguage;
      config.expressions = indexSpec.expressions;
      config.ignoreAccents = static_cast<bool>(indexSpec.ignoreAccents);
      config.language = indexSpec.language;

      return CBLCollection_CreateFullTextIndex(collection, name, config,
                                               errorOut);
  }

  // Is never reached, but stops the compiler warnings.
  return 0;
}

// === Query

static void CBLDart_QueryChangeListenerWrapper(void *context, CBLQuery *query,
                                               CBLListenerToken *token) {
  auto callback = ASYNC_CALLBACK_FROM_C(context);

  Dart_CObject args{};
  CBLDart_CObject_SetEmptyArray(&args);

  CBLDart::AsyncCallbackCall(*callback).execute(args);
}

CBLListenerToken *CBLDart_CBLQuery_AddChangeListener(
    const CBLDatabase *db, CBLQuery *query, CBLDart_AsyncCallback listener) {
  auto listenerToken = CBLQuery_AddChangeListener(
      query, CBLDart_QueryChangeListenerWrapper, listener);

  CBLDart_CloneDatabaseLock(db, listenerToken);

  ASYNC_CALLBACK_FROM_C(listener)->setFinalizer(listenerToken,
                                                CBLDart_CBLListenerFinalizer);

  return listenerToken;
}

// === Blob

FLSliceResult CBLDart_CBLBlobReader_Read(CBLBlobReadStream *stream,
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

  return buffer;
}

// === Replicator

typedef std::map<const CBLCollection *, CBLDart::AsyncCallback *>
    ReplicatorCollectionCallbackMap;

struct ReplicatorCallbackWrapperContext {
  ReplicatorCollectionCallbackMap pushFilters;
  ReplicatorCollectionCallbackMap pullFilters;
  ReplicatorCollectionCallbackMap conflictResolvers;

  void retainCollections() {
    for (auto &pair : pushFilters) {
      CBLCollection_Retain(pair.first);
    }
    for (auto &pair : pullFilters) {
      CBLCollection_Retain(pair.first);
    }
    for (auto &pair : conflictResolvers) {
      CBLCollection_Retain(pair.first);
    }
  }

  void releaseCollections() {
    for (auto &pair : pushFilters) {
      CBLCollection_Release(pair.first);
    }
    for (auto &pair : pullFilters) {
      CBLCollection_Release(pair.first);
    }
    for (auto &pair : conflictResolvers) {
      CBLCollection_Release(pair.first);
    }
  }

  ~ReplicatorCallbackWrapperContext() { releaseCollections(); }
};

static std::map<CBLReplicator *, ReplicatorCallbackWrapperContext *>
    replicatorCallbackWrapperContexts;
static std::mutex replicatorCallbackWrapperContextsMutex;

static bool CBLDart_ReplicatorFilterWrapper(CBLDart::AsyncCallback *callback,
                                            CBLDocument *document,
                                            CBLDocumentFlags flags) {
  Dart_CObject document_{};
  CBLDart_CObject_SetPointer(&document_, document);

  Dart_CObject flags_{};
  flags_.type = Dart_CObject_kInt32;
  flags_.value.as_int32 = flags;

  Dart_CObject *argsValues[] = {&document_, &flags_};

  Dart_CObject args{};
  args.type = Dart_CObject_kArray;
  args.value.as_array.length = 2;
  args.value.as_array.values = argsValues;

  bool decision;

  auto resultHandler = [&](Dart_CObject *result) {
    decision = result->value.as_bool;
  };

  CBLDart::AsyncCallbackCall(*callback, resultHandler).execute(args);

  return decision;
}

static bool CBLDart_ReplicatorPushFilterWrapper(void *context,
                                                CBLDocument *document,
                                                CBLDocumentFlags flags) {
  auto wrapperContext =
      reinterpret_cast<ReplicatorCallbackWrapperContext *>(context);
  auto collection = CBLDocument_Collection(document);
  return CBLDart_ReplicatorFilterWrapper(
      wrapperContext->pushFilters[collection], document, flags);
}

static bool CBLDart_ReplicatorPullFilterWrapper(void *context,
                                                CBLDocument *document,
                                                CBLDocumentFlags flags) {
  auto wrapperContext =
      reinterpret_cast<ReplicatorCallbackWrapperContext *>(context);
  auto collection = CBLDocument_Collection(document);
  return CBLDart_ReplicatorFilterWrapper(
      wrapperContext->pullFilters[collection], document, flags);
}

static const CBLDocument *CBLDart_ReplicatorConflictResolverWrapper(
    void *context, FLString documentID, const CBLDocument *localDocument,
    const CBLDocument *remoteDocument) {
  auto wrapperContext =
      reinterpret_cast<ReplicatorCallbackWrapperContext *>(context);
  auto collection =
      CBLDocument_Collection(localDocument ? localDocument : remoteDocument);
  auto callback = wrapperContext->conflictResolvers[collection];

  Dart_CObject documentID_{};
  CBLDart_CObject_SetFLString(&documentID_, documentID);

  Dart_CObject local{};
  CBLDart_CObject_SetPointer(&local, localDocument);

  Dart_CObject remote{};
  CBLDart_CObject_SetPointer(&remote, remoteDocument);

  Dart_CObject *argsValues[] = {&documentID_, &local, &remote};

  Dart_CObject args{};
  args.type = Dart_CObject_kArray;
  args.value.as_array.length = 3;
  args.value.as_array.values = argsValues;

  const CBLDocument *decision;
  auto resolverThrewException = false;

  auto resultHandler = [&](Dart_CObject *result) {
    switch (result->type) {
      case Dart_CObject_kNull:
        decision = nullptr;
        break;
      case Dart_CObject_kInt32:
      case Dart_CObject_kInt64:
        decision = reinterpret_cast<const CBLDocument *>(
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

  return decision;
}

CBLReplicator *CBLDart_CBLReplicator_Create(
    CBLDart_ReplicatorConfiguration *config, CBLError *errorOut) {
  CBLReplicatorConfiguration config_{};
  config_.endpoint = config->endpoint;
  config_.replicatorType =
      static_cast<CBLReplicatorType>(config->replicatorType);
  config_.continuous = config->continuous;
  config_.disableAutoPurge = config->disableAutoPurge;
  config_.maxAttempts = config->maxAttempts;
  config_.maxAttemptWaitTime = config->maxAttemptWaitTime;
  config_.heartbeat = config->heartbeat;
  config_.authenticator = config->authenticator;
  config_.proxy = config->proxy;
  config_.headers = config->headers;
  config_.pinnedServerCertificate = config->pinnedServerCertificate == nullptr
                                        ? kFLSliceNull
                                        : *config->pinnedServerCertificate;
  config_.trustedRootCertificates = config->trustedRootCertificates == nullptr
                                        ? kFLSliceNull
                                        : *config->trustedRootCertificates;

  std::vector<CBLReplicationCollection> replicationCollections(
      config->collectionsCount);
  config_.collections = replicationCollections.data();
  config_.collectionCount = config->collectionsCount;

  auto context = new ReplicatorCallbackWrapperContext;
  config_.context = context;

  for (size_t i = 0; i < config->collectionsCount; i++) {
    auto replicationCollection = config->collections[i];
    auto collection = replicationCollection.collection;

    replicationCollections[i] = {};
    auto replicationCollection_ = &replicationCollections[i];

    replicationCollection_->collection = collection;
    replicationCollection_->channels = replicationCollection.channels;
    replicationCollection_->documentIDs = replicationCollection.documentIDs;

    if (replicationCollection.pushFilter) {
      replicationCollection_->pushFilter = CBLDart_ReplicatorPushFilterWrapper;
      context->pushFilters[collection] =
          ASYNC_CALLBACK_FROM_C(replicationCollection.pushFilter);
    }

    if (replicationCollection.pullFilter) {
      replicationCollection_->pullFilter = CBLDart_ReplicatorPullFilterWrapper;
      context->pullFilters[collection] =
          ASYNC_CALLBACK_FROM_C(replicationCollection.pullFilter);
    }

    if (replicationCollection.conflictResolver) {
      replicationCollection_->conflictResolver =
          CBLDart_ReplicatorConflictResolverWrapper;
      context->conflictResolvers[collection] =
          ASYNC_CALLBACK_FROM_C(replicationCollection.conflictResolver);
    }
  }

  context->retainCollections();

  auto replicator = CBLReplicator_Create(&config_, errorOut);

  if (replicator) {
    // Associate callback context with this instance so we can it released
    // when the replicator is released.
    std::scoped_lock lock(replicatorCallbackWrapperContextsMutex);
    replicatorCallbackWrapperContexts[replicator] = context;

    CBLDart_CloneDatabaseLock(config->database, replicator);
  } else {
    delete context;
  }

  return replicator;
}

static void CBLDart_CBLReplicator_Release_Internal(CBLReplicator *replicator) {
  // Release the replicator.
  CBLReplicator_Release(replicator);

  // Clean up context for callback wrappers as the last step.
  std::scoped_lock lock(replicatorCallbackWrapperContextsMutex);
  auto nh = replicatorCallbackWrapperContexts.extract(replicator);
  delete nh.mapped();

  CBLDart_ReleaseDatabaseLock(replicator);
}

void CBLDart_CBLReplicator_Release(CBLReplicator *replicator) {
  if (CBLReplicator_Status(replicator).activity == kCBLReplicatorStopped) {
    CBLDart_CBLReplicator_Release_Internal(replicator);
  } else {
    {
      // Stop the replicator, since it is still running.
      auto databaseLock = CBLDart_AcquireDatabaseLock(replicator);
      CBLReplicator_Stop(replicator);
    }

    // Get of the Dart finalizer thread.
    auto _ = std::async(std::launch::async, [=]() {
      // Wait for the replicator to stop.
      while (CBLReplicator_Status(replicator).activity !=
             kCBLReplicatorStopped) {
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
      }

      // Now release the replicator.
      CBLDart_CBLReplicator_Release_Internal(replicator);
    });
  }
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
  Dart_CObject object{};
  Dart_CObject *objectValues[6];
  Dart_CObject activity{};
  Dart_CObject progressComplete{};
  Dart_CObject progressDocumentCount{};
  Dart_CObject errorDomain{};
  Dart_CObject errorCode{};
  Dart_CObject errorMessage{};

  FLSliceResult errorMessageStr = {nullptr, 0};
};

static void CBLDart_Replicator_ChangeListenerWrapper(
    void *context, CBLReplicator *replicator,
    const CBLReplicatorStatus *status) {
  auto callback = ASYNC_CALLBACK_FROM_C(context);

  ReplicatorStatus_CObject_Helper cObjectStatus;
  cObjectStatus.init(status);

  Dart_CObject *argsValues[] = {cObjectStatus.cObject()};

  Dart_CObject args{};
  args.type = Dart_CObject_kArray;
  args.value.as_array.length = 1;
  args.value.as_array.values = argsValues;

  CBLDart::AsyncCallbackCall(*callback).execute(args);
}

void CBLDart_CBLReplicator_AddChangeListener(const CBLDatabase *db,
                                             CBLReplicator *replicator,
                                             CBLDart_AsyncCallback listener) {
  auto listenerToken = CBLReplicator_AddChangeListener(
      replicator, CBLDart_Replicator_ChangeListenerWrapper, listener);

  CBLDart_CloneDatabaseLock(db, listenerToken);

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
    object.value.as_array.length = hasError ? 7 : 4;
    object.value.as_array.values = objectValues;

    objectValues[0] = &id;
    CBLDart_CObject_SetFLString(&id, document->ID);

    objectValues[1] = &flags;
    flags.type = Dart_CObject_kInt32;
    flags.value.as_int32 = document->flags;

    objectValues[2] = &scope;
    CBLDart_CObject_SetFLString(&scope, document->scope);

    objectValues[3] = &collection;
    CBLDart_CObject_SetFLString(&collection, document->collection);

    if (hasError) {
      objectValues[4] = &errorDomain;
      errorDomain.type = Dart_CObject_kInt32;
      errorDomain.value.as_int32 = document->error.domain;

      objectValues[5] = &errorCode;
      errorCode.type = Dart_CObject_kInt32;
      errorCode.value.as_int32 = document->error.code;

      objectValues[6] = &errorMessage;
      CBLDart_CObject_SetFLString(&errorMessage,
                                  static_cast<FLString>(errorMessageStr));
    }
  }

  ~ReplicatedDocument_CObject_Helper() {
    FLSliceResult_Release(errorMessageStr);
  }

  Dart_CObject *cObject() { return &object; }

 private:
  Dart_CObject object{};
  Dart_CObject *objectValues[7];
  Dart_CObject id{};
  Dart_CObject flags{};
  Dart_CObject scope{};
  Dart_CObject collection{};
  Dart_CObject errorDomain{};
  Dart_CObject errorCode{};
  Dart_CObject errorMessage{};

  FLSliceResult errorMessageStr = {nullptr, 0};
};

static void CBLDart_Replicator_DocumentReplicationListenerWrapper(
    void *context, CBLReplicator *replicator, bool isPush,
    unsigned numDocuments, const CBLReplicatedDocument *documents) {
  auto callback = ASYNC_CALLBACK_FROM_C(context);

  Dart_CObject isPush_{};
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

  Dart_CObject cObjectDocumentsArray{};
  cObjectDocumentsArray.type = Dart_CObject_kArray;
  cObjectDocumentsArray.value.as_array.length = numDocuments;
  cObjectDocumentsArray.value.as_array.values = documentObjects.data();

  Dart_CObject *argsValues[] = {&isPush_, &cObjectDocumentsArray};

  Dart_CObject args{};
  args.type = Dart_CObject_kArray;
  args.value.as_array.length = 2;
  args.value.as_array.values = argsValues;

  CBLDart::AsyncCallbackCall(*callback).execute(args);
}

void CBLDart_CBLReplicator_AddDocumentReplicationListener(
    const CBLDatabase *db, CBLReplicator *replicator,
    CBLDart_AsyncCallback listener) {
  auto listenerToken = CBLReplicator_AddDocumentReplicationListener(
      replicator, CBLDart_Replicator_DocumentReplicationListenerWrapper,
      (void *)listener);

  CBLDart_CloneDatabaseLock(db, listenerToken);

  ASYNC_CALLBACK_FROM_C(listener)->setFinalizer(listenerToken,
                                                CBLDart_CBLListenerFinalizer);
}
