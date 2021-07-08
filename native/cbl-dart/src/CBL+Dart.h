
#pragma once

#include "Callbacks.h"
#include "Fleece+Dart.h"
#include "cbl/CouchbaseLite.h"
#include "cbldart_export.h"
#include "dart/dart_api_dl.h"

/**
 * This is a compatibility layer to allow Dart code to use the Couchbase Lite C
 * API. Some method signatures are incompatible with Dart's FFI capabilities.
 *
 * This layer is also where memory management of objects from the Couchbase Lite
 * C API is integrated with the garbage collection of Dart objects.
 */

extern "C" {
// Dart --------------------------------------------------------------------

CBLDART_EXPORT
void CBLDart_InitDartApiDL(void *data);

// -- Callbacks

CBLDART_EXPORT
Callback *CBLDart_Callback_New(Dart_Handle object, Dart_Port sendPort);

CBLDART_EXPORT
void CBLDart_Callback_Close(Callback *callback);

CBLDART_EXPORT
void CBLDart_Callback_CallForTest(Callback *callback, int64_t argument);

// Couchbase Lite ----------------------------------------------------------

// -- Log

CBLDART_EXPORT
void CBLDart_CBLLog_RestoreOriginalCallback();

CBLDART_EXPORT
void CBLDart_CBLLog_SetCallback(Callback *callback);

// -- RefCounted

/**
 * Binds a CBLRefCounted to a Dart objects lifetime.
 *
 * If \p retain is true the ref counted object will be retained. Otherwise
 * it will only be released once the Dart object is garbage collected.
 */
CBLDART_EXPORT
void CBLDart_BindCBLRefCountedToDartObject(Dart_Handle object,
                                           CBLRefCounted *refCounted,
                                           uint8_t retain);

// -- Database

CBLDART_EXPORT
void CBLDart_CBLDatabase_Config(CBLDatabase *db,
                                CBLDatabaseConfiguration *config);

CBLDART_EXPORT
const CBLDocument *CBLDart_CBLDatabase_SaveDocumentResolving(
    CBLDatabase *db, CBLDocument *doc, Callback *conflictHandler,
    CBLError *errorOut);

CBLDART_EXPORT
void CBLDart_CBLDatabase_AddDocumentChangeListener(const CBLDatabase *db,
                                                   const char *docID,
                                                   Callback *listener);

CBLDART_EXPORT
void CBLDart_CBLDatabase_AddChangeListener(const CBLDatabase *db,
                                           Callback *listener);

// -- Query

CBLDART_EXPORT
void CBLDart_CBLQuery_Explain(const CBLQuery *query, CBLDart_FLSlice *result);

CBLDART_EXPORT
void CBLDart_CBLQuery_ColumnName(const CBLQuery *query, unsigned columnIndex,
                                 CBLDart_FLSlice *result);

CBLDART_EXPORT
CBLListenerToken *CBLDart_CBLQuery_AddChangeListener(CBLQuery *query,
                                                     Callback *listener);

// -- Blob

CBLDART_EXPORT
uint64_t CBLDart_CBLBlobReader_Read(CBLBlobReadStream *stream, void *buf,
                                    uint64_t bufSize, CBLError *outError);

// -- Replicator

struct CBLDart_ReplicatorConfiguration {
  CBLDatabase *database;

  CBLEndpoint *endpoint;

  uint8_t replicatorType;

  uint8_t continuous;

  CBLAuthenticator *authenticator;

  CBLProxySettings *proxy;

  FLDict headers;

  FLSlice *pinnedServerCertificate;

  FLSlice *trustedRootCertificates;

  FLArray channels;

  FLArray documentIDs;

  Callback *pushFilter;

  Callback *pullFilter;

  Callback *conflictResolver;
};

CBLDART_EXPORT
CBLReplicator *CBLDart_CBLReplicator_New(
    CBLDart_ReplicatorConfiguration *config, CBLError *errorOut);

CBLDART_EXPORT
void CBLDart_BindReplicatorToDartObject(Dart_Handle object,
                                        CBLReplicator *replicator);

CBLDART_EXPORT
uint8_t CBLDart_CBLReplicator_IsDocumentPending(CBLReplicator *replicator,
                                                char *docId,
                                                CBLError *errorOut);
CBLDART_EXPORT
void CBLDart_CBLReplicator_AddChangeListener(CBLReplicator *replicator,
                                             Callback *listenerId);

struct CBLDart_ReplicatedDocument {
  const char *ID;

  uint32_t flags;

  CBLError error;
};

CBLDART_EXPORT
void CBLDart_CBLReplicator_AddDocumentListener(CBLReplicator *replicator,
                                               Callback *listenerId);
}
