
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

extern "C" {

/**
 * Initializes the native libraries.
 *
 * This function can be called multiple times and is thread save. The
 * libraries are only initialized by the first call and subsequent calls are
 * NOOPs.
 */
CBLDART_EXPORT
bool CBLDart_Initialize(void *dartInitializeDlData, void *cblInitContext,
                        CBLError *errorOut);

// === Dart Native ============================================================

// === Async Callbacks

typedef struct _CBLDart_AsyncCallback *CBLDart_AsyncCallback;

CBLDART_EXPORT
CBLDart_AsyncCallback CBLDart_AsyncCallback_New(uint32_t id, Dart_Handle object,
                                                Dart_Port sendPort, bool debug);

CBLDART_EXPORT
void CBLDart_AsyncCallback_Close(CBLDart_AsyncCallback callback);

CBLDART_EXPORT
void CBLDart_AsyncCallback_CallForTest(CBLDart_AsyncCallback callback,
                                       int64_t argument);

// === Dart Finalizer

CBLDART_EXPORT
void CBLDart_RegisterDartFinalizer(Dart_Handle object, Dart_Port registry,
                                   int64_t token);

// === Couchbase Lite =========================================================

// === Base

/**
 * Binds a CBLRefCounted to a Dart objects lifetime.
 *
 * If \p retain is true the ref counted object will be retained. Otherwise
 * it will only be released once the Dart object is garbage collected.
 */
CBLDART_EXPORT
void CBLDart_BindCBLRefCountedToDartObject(Dart_Handle object,
                                           CBLRefCounted *refCounted,
                                           bool retain, char *debugName);

/**
 * Sets whether information to debug CBLRefCounted is printed.
 *
 * This features is only functional in debug builds.
 */
CBLDART_EXPORT
void CBLDart_SetDebugRefCounted(bool enabled);

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
void CBLDart_BindDatabaseToDartObject(Dart_Handle object, CBLDatabase *database,
                                      char *debugName);

CBLDART_EXPORT
bool CBLDart_CBLDatabase_Close(CBLDatabase *database, bool andDelete,
                               CBLError *errorOut);

CBLDART_EXPORT
void CBLDart_CBLDatabase_AddDocumentChangeListener(
    const CBLDatabase *db, const FLString docID,
    CBLDart_AsyncCallback listener);

CBLDART_EXPORT
void CBLDart_CBLDatabase_AddChangeListener(const CBLDatabase *db,
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
bool CBLDart_CBLDatabase_CreateIndex(CBLDatabase *db, FLString name,
                                     CBLDart_CBLIndexSpec indexSpec,
                                     CBLError *errorOut);

// === Query

CBLDART_EXPORT
CBLListenerToken *CBLDart_CBLQuery_AddChangeListener(
    CBLQuery *query, CBLDart_AsyncCallback listener);

// === Blob

CBLDART_EXPORT
void CBLDart_BindBlobReadStreamToDartObject(Dart_Handle object,
                                            CBLBlobReadStream *stream);

CBLDART_EXPORT
FLSliceResult CBLDart_CBLBlobReader_Read(CBLBlobReadStream *stream,
                                         uint64_t bufferSize,
                                         CBLError *outError);

// === Replicator

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
  FLArray channels;
  FLArray documentIDs;
  CBLDart_AsyncCallback pushFilter;
  CBLDart_AsyncCallback pullFilter;
  CBLDart_AsyncCallback conflictResolver;
};

CBLDART_EXPORT
CBLReplicator *CBLDart_CBLReplicator_Create(
    CBLDart_ReplicatorConfiguration *config, CBLError *errorOut);

CBLDART_EXPORT
void CBLDart_BindReplicatorToDartObject(Dart_Handle object,
                                        CBLReplicator *replicator,
                                        char *debugName);

CBLDART_EXPORT
void CBLDart_CBLReplicator_AddChangeListener(CBLReplicator *replicator,
                                             CBLDart_AsyncCallback listenerId);

CBLDART_EXPORT
void CBLDart_CBLReplicator_AddDocumentReplicationListener(
    CBLReplicator *replicator, CBLDart_AsyncCallback listenerId);
}
