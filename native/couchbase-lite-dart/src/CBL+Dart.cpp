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

// === Couchbase Lite =========================================================

// === Base

static void CBLDart_CBLListenerFinalizer(void *context) {
  auto listenerToken = reinterpret_cast<CBLListenerToken *>(context);
  CBLListener_Remove(listenerToken);
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
    config_.directory = config->directory;
    config_.maxRotateCount = config->maxRotateCount;
    config_.maxSize = config->maxSize;
    config_.usePlaintext = config->usePlaintext;

    auto success = CBLLog_SetFileConfig(config_, errorOut);
    if (success) {
      auto config_ = CBLLog_FileConfig();
      if (!logFileConfig) {
        logFileConfig = new CBLLogFileConfiguration;
      }
      logFileConfig->level = config_->level;
      logFileConfig->directory = config_->directory;
      logFileConfig->maxRotateCount = config_->maxRotateCount;
      logFileConfig->maxSize = config->maxSize;
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

bool CBLDart_CBLDatabase_Close(CBLDatabase *database, bool andDelete,
                               CBLError *errorOut) {
  {
    std::scoped_lock lock(openDatabasesMutex);
    // Check if the database is still open.
    auto it = std::find(openDatabases.begin(), openDatabases.end(), database);
    if (it == openDatabases.end()) {
      // Return early since the database has already been closed.
      return true;
    }

    // Remove the database from the list of open database and close it.
    openDatabases.erase(it);
  }

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
  CBLDatabase_Release(database);
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
    const CBLDatabase *db, const FLString docID,
    CBLDart_AsyncCallback listener) {
  auto listenerToken = CBLDatabase_AddDocumentChangeListener(
      db, docID, CBLDart_DocumentChangeListenerWrapper, listener);

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

bool CBLDart_CBLDatabase_CreateIndex(CBLDatabase *db, FLString name,
                                     CBLDart_CBLIndexSpec indexSpec,
                                     CBLError *errorOut) {
  switch (indexSpec.type) {
    case kCBLDart_IndexTypeValue: {
      CBLValueIndexConfiguration config;
      config.expressionLanguage = indexSpec.expressionLanguage;
      config.expressions = indexSpec.expressions;

      return CBLDatabase_CreateValueIndex(db, name, config, errorOut);
    }
    case kCBLDart_IndexTypeFullText: {
    }
      CBLFullTextIndexConfiguration config;
      config.expressionLanguage = indexSpec.expressionLanguage;
      config.expressions = indexSpec.expressions;
      config.ignoreAccents = static_cast<bool>(indexSpec.ignoreAccents);
      config.language = indexSpec.language;

      return CBLDatabase_CreateFullTextIndex(db, name, config, errorOut);
  }

  // Is never reached, but stops the compiler warnings.
  return 0;
}

// === Query

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

struct ReplicatorCallbackWrapperContext {
  CBLDart::AsyncCallback *pullFilter;
  CBLDart::AsyncCallback *pushFilter;
  CBLDart::AsyncCallback *conflictResolver;
};

static std::map<CBLReplicator *, ReplicatorCallbackWrapperContext *>
    replicatorCallbackWrapperContexts;
static std::mutex replicatorCallbackWrapperContextsMutex;

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

  bool decision;

  auto resultHandler = [&](Dart_CObject *result) {
    decision = result->value.as_bool;
  };

  CBLDart::AsyncCallbackCall(*callback, resultHandler).execute(args);

  return decision;
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
  config_.proxy = config->proxy;
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
    std::scoped_lock lock(replicatorCallbackWrapperContextsMutex);
    replicatorCallbackWrapperContexts[replicator] = context;
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
}

void CBLDart_CBLReplicator_Release(CBLReplicator *replicator) {
  if (CBLReplicator_Status(replicator).activity == kCBLReplicatorStopped) {
    CBLDart_CBLReplicator_Release_Internal(replicator);
  } else {
    // Stop the replicator, since it is still running.
    CBLReplicator_Stop(replicator);

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
