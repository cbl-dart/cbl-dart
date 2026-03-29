
#pragma once

#include <cstdint>

#include "Fleece+Dart.h"
#ifdef CBL_FRAMEWORK_HEADERS
#include <CouchbaseLite/CouchbaseLite.h>
#else
#include "cbl/CouchbaseLite.h"
#endif

#include "CBLDart_Export.h"
#include "dart/dart_api_dl.h"

CBLDART_EXPORT
bool CBLDart_CpuSupportsAVX2();

/// Returns whether this build of cblitedart was compiled with the
/// COUCHBASE_ENTERPRISE flag.
CBLDART_EXPORT
bool CBLDart_IsEnterprise();

/**
 * This is a compatibility layer to allow Dart code to use the Couchbase Lite C
 * API. Some method signatures are incompatible with Dart's FFI capabilities.
 *
 * This layer is also where memory management of objects from the Couchbase Lite
 * C API is integrated with the garbage collection of Dart objects.
 */

enum CBLDartInitializeResult {
  CBLDartInitializeResult_kSuccess,
  CBLDartInitializeResult_kIncompatibleDartVM,
  CBLDartInitializeResult_kCBLInitError,
};

/**
 * Initializes the native libraries.
 *
 * This function can be called multiple times and is thread safe. The
 * libraries are only initialized by the first call and subsequent calls are
 * NOOPs.
 */
CBLDART_EXPORT
CBLDartInitializeResult CBLDart_Initialize(void* dartInitializeDlData,
                                           void* cblInitContext,
                                           CBLError* errorOut);

// === Dart Native ============================================================

// === Async Callbacks

typedef struct _CBLDart_AsyncCallback* CBLDart_AsyncCallback;

CBLDART_EXPORT
CBLDart_AsyncCallback CBLDart_AsyncCallback_New(uint32_t id, Dart_Port sendPort,
                                                bool debug);

CBLDART_EXPORT
void CBLDart_AsyncCallback_Delete(CBLDart_AsyncCallback callback);

CBLDART_EXPORT
void CBLDart_AsyncCallback_Close(CBLDart_AsyncCallback callback);

CBLDART_EXPORT
void CBLDart_AsyncCallback_CallForTest(CBLDart_AsyncCallback callback,
                                       int64_t argument);

// === Completer

typedef struct _CBLDart_Completer* CBLDart_Completer;

CBLDART_EXPORT
void CBLDart_Completer_Complete(CBLDart_Completer completer, uint64_t result);

// === Isolate ID

#define kCBLDartInvalidIsolateId -1

typedef int CBLDart_IsolateId;

CBLDART_EXPORT
CBLDart_IsolateId CBLDart_AllocateIsolateId();

CBLDART_EXPORT
void CBLDart_SetCurrentIsolateId(CBLDart_IsolateId isolateId);

CBLDART_EXPORT
CBLDart_IsolateId CBLDart_GetCurrentIsolateId();

// === Couchbase Lite =========================================================

// === Log

CBLDART_EXPORT
void CBLDart_CBLLog_AddCallback(CBLDart_AsyncCallback callback,
                                CBLLogLevel level);

CBLDART_EXPORT
void CBLDart_CBLLog_SetCallbackLevel(CBLDart_AsyncCallback callback,
                                     CBLLogLevel level);

CBLDART_EXPORT
void CBLDart_CBLLog_SetFileSink(CBLFileLogSink* sink);

CBLDART_EXPORT
CBLFileLogSink* CBLDart_CBLLog_GetFileSink();

CBLDART_EXPORT
void CBLDart_CBL_LogMessage(CBLLogDomain domain, CBLLogLevel level,
                            const void* msgBuf, size_t msgSize);

#ifdef COUCHBASE_ENTERPRISE
CBLDART_EXPORT
bool CBLDart_CBL_EnableVectorSearch(const void* dirBuf, size_t dirSize,
                                    CBLError* errorOut);
#endif

// === Database

typedef struct CBLDart_CBLEncryptionKey {
  uint32_t algorithm;
  uint8_t bytes[32];
} CBLDart_CBLEncryptionKey;

typedef struct {
  const void* directoryBuf;
  size_t directorySize;
  CBLDart_CBLEncryptionKey encryptionKey;
  bool fullSync;
} CBLDart_CBLDatabaseConfiguration;

CBLDART_EXPORT
CBLDart_CBLDatabaseConfiguration CBLDart_CBLDatabaseConfiguration_Default();

CBLDART_EXPORT
bool CBLDart_CBL_CopyDatabase(const void* fromPathBuf, size_t fromPathSize,
                              const void* toNameBuf, size_t toNameSize,
                              const CBLDart_CBLDatabaseConfiguration* config,
                              CBLError* outError);

CBLDART_EXPORT
CBLDatabase* CBLDart_CBLDatabase_Open(const void* nameBuf, size_t nameSize,
                                      CBLDart_CBLDatabaseConfiguration* config,
                                      CBLError* errorOut);

CBLDART_EXPORT
void CBLDart_CBLDatabase_Release(CBLDatabase* database);

CBLDART_EXPORT
bool CBLDart_CBLDatabase_Close(CBLDatabase* database, bool andDelete,
                               CBLError* errorOut);

CBLDART_EXPORT
bool CBLDart_CBL_DeleteDatabase(const void* nameBuf, size_t nameSize,
                                const void* inDirBuf, size_t inDirSize,
                                CBLError* errorOut);

CBLDART_EXPORT
bool CBLDart_CBL_DatabaseExists(const void* nameBuf, size_t nameSize,
                                const void* inDirBuf, size_t inDirSize);

#ifdef COUCHBASE_ENTERPRISE
CBLDART_EXPORT
bool CBLDart_CBLEncryptionKey_FromPassword(CBLEncryptionKey* key,
                                           const void* pwBuf, size_t pwSize);
#endif

CBLDART_EXPORT
CBLScope* CBLDart_CBLDatabase_Scope(CBLDatabase* db, const void* nameBuf,
                                    size_t nameSize, CBLError* errorOut);

CBLDART_EXPORT
CBLCollection* CBLDart_CBLScope_Collection(CBLScope* scope, const void* nameBuf,
                                           size_t nameSize, CBLError* errorOut);

CBLDART_EXPORT
CBLCollection* CBLDart_CBLDatabase_CreateCollection(
    CBLDatabase* db, const void* colNameBuf, size_t colNameSize,
    const void* scopeNameBuf, size_t scopeNameSize, CBLError* errorOut);

CBLDART_EXPORT
bool CBLDart_CBLDatabase_DeleteCollection(
    CBLDatabase* db, const void* colNameBuf, size_t colNameSize,
    const void* scopeNameBuf, size_t scopeNameSize, CBLError* errorOut);

// === Collection

CBLDART_EXPORT
CBLDocument* CBLDart_CBLCollection_GetDocument(CBLCollection* collection,
                                               const void* docIDBuf,
                                               size_t docIDSize,
                                               CBLError* errorOut);

CBLDART_EXPORT
bool CBLDart_CBLCollection_PurgeDocumentByID(CBLCollection* collection,
                                             const void* docIDBuf,
                                             size_t docIDSize,
                                             CBLError* errorOut);

CBLDART_EXPORT
CBLTimestamp CBLDart_CBLCollection_GetDocumentExpiration(
    CBLCollection* collection, const void* docIDBuf, size_t docIDSize,
    CBLError* errorOut);

CBLDART_EXPORT
bool CBLDart_CBLCollection_SetDocumentExpiration(CBLCollection* collection,
                                                 const void* docIDBuf,
                                                 size_t docIDSize,
                                                 CBLTimestamp expiration,
                                                 CBLError* errorOut);

CBLDART_EXPORT
void CBLDart_CBLCollection_AddDocumentChangeListener(
    const CBLDatabase* db, const CBLCollection* collection,
    const void* docIDBuf, size_t docIDSize, CBLDart_AsyncCallback listener);

CBLDART_EXPORT
void CBLDart_CBLCollection_AddChangeListener(const CBLDatabase* db,
                                             const CBLCollection* collection,
                                             CBLDart_AsyncCallback listener);

CBLDART_EXPORT
CBLQueryIndex* CBLDart_CBLCollection_GetIndex(CBLCollection* collection,
                                              const void* nameBuf,
                                              size_t nameSize,
                                              CBLError* errorOut);

typedef enum : uint8_t {
  kCBLDart_IndexTypeValue,
  kCBLDart_IndexTypeFullText,
  kCBLDart_IndexTypeVector,
} CBLDart_IndexType;

struct CBLDart_CBLIndexSpec {
  CBLDart_IndexType type;
  CBLQueryLanguage expressionLanguage;
  const void* expressionsBuf;
  size_t expressionsSize;

  // Full text index configuration
  bool ignoreAccents;
  const void* languageBuf;
  size_t languageSize;

  // Vector index configuration
  unsigned dimensions;
  unsigned centroids;
  bool isLazy;
  void* encoding;
  uint32_t metric;
  unsigned minTrainingSize;
  unsigned maxTrainingSize;
  unsigned numProbes;
};

CBLDART_EXPORT
bool CBLDart_CBLCollection_CreateIndex(CBLCollection* collection,
                                       const void* nameBuf, size_t nameSize,
                                       CBLDart_CBLIndexSpec indexSpec,
                                       CBLError* errorOut);

CBLDART_EXPORT
bool CBLDart_CBLCollection_DeleteIndex(CBLCollection* collection,
                                       const void* nameBuf, size_t nameSize,
                                       CBLError* errorOut);

// === Document

CBLDART_EXPORT
CBLDocument* CBLDart_CBLDocument_CreateWithID(const void* docIDBuf,
                                              size_t docIDSize);

CBLDART_EXPORT
bool CBLDart_CBLDocument_SetJSON(CBLDocument* doc, const void* jsonBuf,
                                 size_t jsonSize, CBLError* errorOut);

// === Query

CBLDART_EXPORT
CBLQuery* CBLDart_CBLDatabase_CreateQuery(CBLDatabase* db,
                                          CBLQueryLanguage language,
                                          const void* queryBuf,
                                          size_t querySize, int* errorPos,
                                          CBLError* errorOut);

CBLDART_EXPORT
CBLListenerToken* CBLDart_CBLQuery_AddChangeListener(
    const CBLDatabase* db, CBLQuery* query, CBLDart_AsyncCallback listener);

CBLDART_EXPORT
FLValue CBLDart_CBLResultSet_ValueForKey(CBLResultSet* resultSet,
                                         const void* keyBuf, size_t keySize);

// === Prediction

typedef FLMutableDict (*CBLDart_PredictiveModel_PredictionSync)(FLDict input);
typedef void (*CBLDart_PredictiveModel_PredictionAsync)(
    FLDict input, CBLDart_Completer completer);
typedef void (*CBLDart_PredictiveModel_Unregistered)(void);

typedef struct _CBLDart_PredictiveModel* CBLDart_PredictiveModel;

CBLDART_EXPORT
CBLDart_PredictiveModel CBLDart_PredictiveModel_New(
    const void* nameBuf, size_t nameSize, CBLDart_IsolateId isolateId,
    CBLDart_PredictiveModel_PredictionSync predictionSync,
    CBLDart_PredictiveModel_PredictionAsync predictionAsync,
    CBLDart_PredictiveModel_Unregistered unregistered);

CBLDART_EXPORT
void CBLDart_PredictiveModel_Delete(CBLDart_PredictiveModel model);

#ifdef COUCHBASE_ENTERPRISE
CBLDART_EXPORT
void CBLDart_CBL_UnregisterPredictiveModel(const void* nameBuf,
                                           size_t nameSize);
#endif

// === Blob

CBLDART_EXPORT
FLSliceResult CBLDart_CBLBlobReader_Read(CBLBlobReadStream* stream,
                                         uint64_t bufferSize,
                                         CBLError* outError);

CBLDART_EXPORT
CBLBlob* CBLDart_CBLBlob_CreateWithData(const void* contentTypeBuf,
                                        size_t contentTypeSize,
                                        const void* contentBuf,
                                        size_t contentSize);

CBLDART_EXPORT
CBLBlob* CBLDart_CBLBlob_CreateWithStream(const void* contentTypeBuf,
                                          size_t contentTypeSize,
                                          CBLBlobWriteStream* stream);

// === Replicator

CBLDART_EXPORT
CBLEndpoint* CBLDart_CBLEndpoint_CreateWithURL(const void* urlBuf,
                                               size_t urlSize,
                                               CBLError* errorOut);

CBLDART_EXPORT
CBLAuthenticator* CBLDart_CBLAuth_CreatePassword(const void* userBuf,
                                                 size_t userSize,
                                                 const void* pwBuf,
                                                 size_t pwSize);

CBLDART_EXPORT
CBLAuthenticator* CBLDart_CBLAuth_CreateSession(const void* sidBuf,
                                                size_t sidSize,
                                                const void* cnBuf,
                                                size_t cnSize);

CBLDART_EXPORT
bool CBLDart_CBLReplicator_IsDocumentPending(CBLReplicator* replicator,
                                             const void* docIDBuf,
                                             size_t docIDSize,
                                             CBLCollection* collection,
                                             CBLError* errorOut);

struct CBLDart_ProxySettings {
  CBLProxyType type;
  const void* hostnameBuf;
  size_t hostnameSize;
  uint16_t port;
  const void* usernameBuf;
  size_t usernameSize;
  const void* passwordBuf;
  size_t passwordSize;
};

struct CBLDart_ReplicationCollection {
  CBLCollection* collection;
  FLArray channels;
  FLArray documentIDs;
  CBLDart_AsyncCallback pushFilter;
  CBLDart_AsyncCallback pullFilter;
  CBLDart_AsyncCallback conflictResolver;
};

struct CBLDart_ReplicatorConfiguration {
  CBLDatabase* database;
  CBLEndpoint* endpoint;
  CBLReplicatorType replicatorType;
  bool continuous;
  bool disableAutoPurge;
  unsigned maxAttempts;
  unsigned maxAttemptWaitTime;
  unsigned heartbeat;
  CBLAuthenticator* authenticator;
  CBLDart_ProxySettings* proxy;
  FLDict headers;
  bool acceptOnlySelfSignedServerCertificate;
  FLSlice* pinnedServerCertificate;
  FLSlice* trustedRootCertificates;
  CBLDart_ReplicationCollection* collections;
  size_t collectionsCount;
  bool acceptParentDomainCookies;
};

CBLDART_EXPORT
CBLReplicator* CBLDart_CBLReplicator_Create(
    CBLDart_ReplicatorConfiguration* config, CBLError* errorOut);

CBLDART_EXPORT
void CBLDart_CBLReplicator_Release(CBLReplicator* replicator);

CBLDART_EXPORT
void CBLDart_CBLReplicator_AddChangeListener(const CBLDatabase* db,
                                             CBLReplicator* replicator,
                                             CBLDart_AsyncCallback listenerId);

CBLDART_EXPORT
void CBLDart_CBLReplicator_AddDocumentReplicationListener(
    const CBLDatabase* db, CBLReplicator* replicator,
    CBLDart_AsyncCallback listenerId);

// === UrlEndpointListener

#ifdef COUCHBASE_ENTERPRISE
CBLDART_EXPORT
CBLURLEndpointListener* CBLDart_CBLURLEndpointListener_Create(
    CBLCollection** collections, size_t collectionCount, uint16_t port,
    const void* networkInterfaceBuf, size_t networkInterfaceSize,
    bool disableTLS, CBLTLSIdentity* tlsIdentity,
    CBLListenerAuthenticator* authenticator, bool enableDeltaSync,
    bool readOnly, CBLError* errorOut);
#endif

// === FileLogSink

CBLDART_EXPORT
void CBLDart_CBLLog_SetFileSinkV2(CBLLogLevel level, const void* dirBuf,
                                  size_t dirSize, unsigned maxKeptFiles,
                                  size_t maxSize, bool usePlaintext);

// === TLS Identity

#ifdef COUCHBASE_ENTERPRISE

CBLDART_EXPORT
FLSliceResult CBLDart_CBLCert_SubjectNameComponent(CBLCert* cert,
                                                   const void* keyBuf,
                                                   size_t keySize);

CBLDART_EXPORT
CBLKeyPair* CBLDart_CBLKeyPair_CreateWithPrivateKeyData(const void* pkBuf,
                                                        size_t pkSize,
                                                        const void* pwBuf,
                                                        size_t pwSize,
                                                        CBLError* errorOut);

CBLDART_EXPORT
CBLTLSIdentity* CBLDart_CBLTLSIdentity_CreateIdentity(
    int keyUsages, FLDict attrs, int64_t validityMs, const void* labelBuf,
    size_t labelSize, CBLError* errorOut);

CBLDART_EXPORT
CBLTLSIdentity* CBLDart_CBLTLSIdentity_IdentityWithLabel(const void* labelBuf,
                                                         size_t labelSize,
                                                         CBLError* errorOut);

CBLDART_EXPORT
bool CBLDart_CBLTLSIdentity_DeleteIdentityWithLabel(const void* labelBuf,
                                                    size_t labelSize,
                                                    CBLError* errorOut);

typedef void (*CBLDartExternalKeyPublicKeyData)(CBLDart_Completer completer,
                                                void* output,
                                                size_t outputMaxLen,
                                                size_t* outputLen);

typedef void (*CBLDartExternalKeyDecrypt)(CBLDart_Completer completer,
                                          FLSlice input, void* output,
                                          size_t outputMaxLen,
                                          size_t* outputLen);

typedef void (*CBLDartExternalKeySign)(
    CBLDart_Completer completer, CBLSignatureDigestAlgorithm digestAlgorithm,
    FLSlice inputData, void* outSignature);

CBLDART_EXPORT CBLKeyPair* CBLDartKeyPair_CreateWithExternalKey(
    size_t keySizeInBits, Dart_Handle delegate,
    CBLDartExternalKeyPublicKeyData publicKeyData,
    CBLDartExternalKeyDecrypt decrypt, CBLDartExternalKeySign sign,
    CBLError* outError);

typedef void (*CBLDartListenerPasswordAuthCallback)(CBLDart_Completer completer,
                                                    FLString username,
                                                    FLString password);

CBLDART_EXPORT bool CBLDart_ListenerPasswordAuthCallbackTrampoline(
    void* context, FLString username, FLString password);

typedef void (*CBLDartListenerCertAuthCallback)(CBLDart_Completer completer,
                                                CBLCert* cert);

CBLDART_EXPORT bool CBLDart_ListenerCertAuthCallbackTrampoline(void* context,
                                                               CBLCert* cert);

#endif
