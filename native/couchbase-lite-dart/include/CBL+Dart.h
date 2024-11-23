
#pragma once

#include "Fleece+Dart.h"
#ifdef CBL_FRAMEWORK_HEADERS
#include <CouchbaseLite/CouchbaseLite.h>
#else
#include "cbl/CouchbaseLite.h"
#endif
#include "CBLDart_Export.h"
#include "dart/dart_api_dl.h"

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
 * This function can be called multiple times and is thread save. The
 * libraries are only initialized by the first call and subsequent calls are
 * NOOPs.
 */
CBLDART_EXPORT
CBLDartInitializeResult CBLDart_Initialize(void *dartInitializeDlData,
                                           void *cblInitContext,
                                           CBLError *errorOut);

// === Dart Native ============================================================

// === Async Callbacks

typedef struct _CBLDart_AsyncCallback *CBLDart_AsyncCallback;

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

// === Couchbase Lite =========================================================

// === Log

CBLDART_EXPORT
bool CBLDart_CBLLog_SetCallback(CBLDart_AsyncCallback callback);

CBLDART_EXPORT
void CBLDart_CBLLog_SetCallbackLevel(CBLLogLevel level);

CBLDART_EXPORT
bool CBLDart_CBLLog_SetFileConfig(CBLLogFileConfiguration *config,
                                  CBLError *errorOut);

CBLDART_EXPORT
CBLLogFileConfiguration *CBLDart_CBLLog_GetFileConfig();

CBLDART_EXPORT
bool CBLDart_CBLLog_SetSentryBreadcrumbs(bool enabled);

// === Database

CBLDART_EXPORT
CBLDatabase *CBLDart_CBLDatabase_Open(FLString name,
                                      CBLDatabaseConfiguration *config,
                                      CBLError *errorOut);

CBLDART_EXPORT
void CBLDart_CBLDatabase_Release(CBLDatabase *database);

CBLDART_EXPORT
bool CBLDart_CBLDatabase_Close(CBLDatabase *database, bool andDelete,
                               CBLError *errorOut);

// === Collection

CBLDART_EXPORT
void CBLDart_CBLCollection_AddDocumentChangeListener(
    const CBLDatabase *db, const CBLCollection *collection,
    const FLString docID, CBLDart_AsyncCallback listener);

CBLDART_EXPORT
void CBLDart_CBLCollection_AddChangeListener(const CBLDatabase *db,
                                             const CBLCollection *collection,
                                             CBLDart_AsyncCallback listener);

typedef enum : uint8_t {
  kCBLDart_IndexTypeValue,
  kCBLDart_IndexTypeFullText,
} CBLDart_IndexType;

struct CBLDart_CBLIndexSpec {
  CBLDart_IndexType type;
  CBLQueryLanguage expressionLanguage;
  FLString expressions;
  bool ignoreAccents;
  FLString language;
};

CBLDART_EXPORT
bool CBLDart_CBLCollection_CreateIndex(CBLCollection *collection, FLString name,
                                       CBLDart_CBLIndexSpec indexSpec,
                                       CBLError *errorOut);

// === Query

CBLDART_EXPORT
CBLListenerToken *CBLDart_CBLQuery_AddChangeListener(
    const CBLDatabase *db, CBLQuery *query, CBLDart_AsyncCallback listener);

// === Blob

CBLDART_EXPORT
FLSliceResult CBLDart_CBLBlobReader_Read(CBLBlobReadStream *stream,
                                         uint64_t bufferSize,
                                         CBLError *outError);

// === Replicator

struct CBLDart_ReplicationCollection {
  CBLCollection *collection;
  FLArray channels;
  FLArray documentIDs;
  CBLDart_AsyncCallback pushFilter;
  CBLDart_AsyncCallback pullFilter;
  CBLDart_AsyncCallback conflictResolver;
};

struct CBLDart_ReplicatorConfiguration {
  CBLDatabase *database;
  CBLEndpoint *endpoint;
  CBLReplicatorType replicatorType;
  bool continuous;
  bool disableAutoPurge;
  unsigned maxAttempts;
  unsigned maxAttemptWaitTime;
  unsigned heartbeat;
  CBLAuthenticator *authenticator;
  CBLProxySettings *proxy;
  FLDict headers;
  FLSlice *pinnedServerCertificate;
  FLSlice *trustedRootCertificates;
  CBLDart_ReplicationCollection *collections;
  size_t collectionsCount;
};

CBLDART_EXPORT
CBLReplicator *CBLDart_CBLReplicator_Create(
    CBLDart_ReplicatorConfiguration *config, CBLError *errorOut);

CBLDART_EXPORT
void CBLDart_CBLReplicator_Release(CBLReplicator *replicator);

CBLDART_EXPORT
void CBLDart_CBLReplicator_AddChangeListener(const CBLDatabase *db,
                                             CBLReplicator *replicator,
                                             CBLDart_AsyncCallback listenerId);

CBLDART_EXPORT
void CBLDart_CBLReplicator_AddDocumentReplicationListener(
    const CBLDatabase *db, CBLReplicator *replicator,
    CBLDart_AsyncCallback listenerId);
