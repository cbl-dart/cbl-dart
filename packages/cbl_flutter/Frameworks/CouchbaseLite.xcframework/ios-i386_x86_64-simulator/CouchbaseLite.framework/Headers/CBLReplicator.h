//
// CBLReplicator.h
//
// Copyright (c) 2018 Couchbase, Inc All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#pragma once
#include "CBLBase.h"
#include "fleece/Fleece.h"

#ifdef __cplusplus
extern "C" {
#endif

/** \defgroup replication   Replication
    A replicator is a background task that synchronizes changes between a local database and
    another database on a remote server (or on a peer device, or even another local database.)
    @{ */

/** \name  Configuration
    @{ */

/** The name of the HTTP cookie used by Sync Gateway to store session keys. */
CBL_CORE_API extern const char* const kCBLAuthDefaultCookieName;

/** An opaque object representing the location of a database to replicate with. */
typedef struct CBLEndpoint CBLEndpoint;

/** Creates a new endpoint representing a server-based database at the given URL.
    The URL's scheme must be `ws` or `wss`, it must of course have a valid hostname,
    and its path must be the name of the database on that server.
    The port can be omitted; it defaults to 80 for `ws` and 443 for `wss`.
    For example: `wss://example.org/dbname` */
CBLEndpoint* CBLEndpoint_NewWithURL(const char *url _cbl_nonnull) CBLAPI;

CBLEndpoint* CBLEndpoint_NewWithURL_s(FLString url) CBLAPI;

#ifdef COUCHBASE_ENTERPRISE
/** Creates a new endpoint representing another local database. (Enterprise Edition only.) */
CBLEndpoint* CBLEndpoint_NewWithLocalDB(CBLDatabase* _cbl_nonnull) CBLAPI;
#endif

/** Frees a CBLEndpoint object. */
void CBLEndpoint_Free(CBLEndpoint*) CBLAPI;


/** An opaque object representing authentication credentials for a remote server. */
typedef struct CBLAuthenticator CBLAuthenticator;

/** Creates an authenticator for HTTP Basic (username/password) auth. */
CBLAuthenticator* CBLAuth_NewBasic(const char *username _cbl_nonnull,
                                   const char *password _cbl_nonnull) CBLAPI;

CBLAuthenticator* CBLAuth_NewBasic_s(FLString username,
                                     FLString password) CBLAPI;

/** Creates an authenticator using a Couchbase Sync Gateway login session identifier,
    and optionally a cookie name (pass NULL for the default.) */
CBLAuthenticator* CBLAuth_NewSession(const char *sessionID _cbl_nonnull,
                                     const char *cookieName) CBLAPI;

CBLAuthenticator* CBLAuth_NewSession_s(FLString sessionID,
                                       FLString cookieName) CBLAPI;

/** Frees a CBLAuthenticator object. */
void CBLAuth_Free(CBLAuthenticator*) CBLAPI;


/** Direction of replication: push, pull, or both. */
typedef CBL_ENUM(uint8_t, CBLReplicatorType) {
    kCBLReplicatorTypePushAndPull = 0,    ///< Bidirectional; both push and pull
    kCBLReplicatorTypePush,               ///< Pushing changes to the target
    kCBLReplicatorTypePull                ///< Pulling changes from the target
};

/** A callback that can decide whether a particular document should be pushed or pulled.
    @warning  This callback will be called on a background thread managed by the replicator.
                It must pay attention to thread-safety. It should not take a long time to return,
                or it will slow down the replicator.
    @param context  The `context` field of the \ref CBLReplicatorConfiguration.
    @param document  The document in question.
    @param isDeleted True if the document has been deleted.
    @return  True if the document should be replicated, false to skip it. */
typedef bool (*CBLReplicationFilter)(void *context, CBLDocument* document, bool isDeleted);

/** Conflict-resolution callback for use in replications. This callback will be invoked
    when the replicator finds a newer server-side revision of a document that also has local
    changes. The local and remote changes must be resolved before the document can be pushed
    to the server.
    @warning  This callback will be called on a background thread managed by the replicator.
                It must pay attention to thread-safety. However, unlike a filter callback,
                it does not need to return quickly. If it needs to prompt for user input,
                that's OK.
    @param context  The `context` field of the \ref CBLReplicatorConfiguration.
    @param documentID  The ID of the conflicted document.
    @param localDocument  The current revision of the document in the local database,
                or NULL if the local document has been deleted.
    @param remoteDocument  The revision of the document found on the server,
                or NULL if the document has been deleted on the server.
    @return  The resolved document to save locally (and push, if the replicator is pushing.)
        This can be the same as \p localDocument or \p remoteDocument, or you can create
        a mutable copy of either one and modify it appropriately.
        Or return NULL if the resolution is to delete the document. */
typedef const CBLDocument* (*CBLConflictResolver)(void *context,
                                                  const char *documentID,
                                                  const CBLDocument *localDocument,
                                                  const CBLDocument *remoteDocument);

/** Default conflict resolver. This always returns `localDocument`. */
extern const CBLConflictResolver CBLDefaultConflictResolver;


/** Types of proxy servers, for CBLProxySettings. */
typedef CBL_ENUM(uint8_t, CBLProxyType) {
    kCBLProxyHTTP,                      ///< HTTP proxy; must support 'CONNECT' method
    kCBLProxyHTTPS,                     ///< HTTPS proxy; must support 'CONNECT' method
};


/** Proxy settings for the replicator. */
typedef struct {
    CBLProxyType type;                  ///< Type of proxy
    const char *hostname;               ///< Proxy server hostname or IP address
    uint16_t port;                      ///< Proxy server port
    const char *username;               ///< Username for proxy auth (optional)
    const char *password;               ///< Password for proxy auth
} CBLProxySettings;


/** The configuration of a replicator. */
typedef struct {
    CBLDatabase* database;              ///< The database to replicate
    CBLEndpoint* endpoint;              ///< The address of the other database to replicate with
    CBLReplicatorType replicatorType;   ///< Push, pull or both
    bool continuous;                    ///< Continuous replication?
    //-- HTTP settings:
    CBLAuthenticator* authenticator;    ///< Authentication credentials, if needed
    const CBLProxySettings* proxy;      ///< HTTP client proxy settings
    FLDict headers;                     ///< Extra HTTP headers to add to the WebSocket request
    //-- TLS settings:
    FLSlice pinnedServerCertificate;    ///< An X.509 cert to "pin" TLS connections to (PEM or DER)
    FLSlice trustedRootCertificates;    ///< Set of anchor certs (PEM format)
    //-- Filtering:
    FLArray channels;                   ///< Optional set of channels to pull from
    FLArray documentIDs;                ///< Optional set of document IDs to replicate
    CBLReplicationFilter pushFilter;    ///< Optional callback to filter which docs are pushed
    CBLReplicationFilter pullFilter;    ///< Optional callback to validate incoming docs
    CBLConflictResolver conflictResolver;///< Optional conflict-resolver callback
    void* context;                      ///< Arbitrary value that will be passed to callbacks
} CBLReplicatorConfiguration;

/** @} */



/** \name  Lifecycle
    @{ */

CBL_REFCOUNTED(CBLReplicator*, Replicator);

/** Creates a replicator with the given configuration. */
CBLReplicator* CBLReplicator_New(const CBLReplicatorConfiguration* _cbl_nonnull,
                                 CBLError*) CBLAPI;

/** Returns the configuration of an existing replicator. */
const CBLReplicatorConfiguration* CBLReplicator_Config(CBLReplicator* _cbl_nonnull) CBLAPI;

/** Instructs the replicator to ignore existing checkpoints the next time it runs.
    This will cause it to scan through all the documents on the remote database, which takes
    a lot longer, but it can resolve problems with missing documents if the client and
    server have gotten out of sync somehow. */
void CBLReplicator_ResetCheckpoint(CBLReplicator* _cbl_nonnull) CBLAPI;

/** Starts a replicator, asynchronously. Does nothing if it's already started. */
void CBLReplicator_Start(CBLReplicator* _cbl_nonnull) CBLAPI;

/** Stops a running replicator, asynchronously. Does nothing if it's not already started.
    The replicator will call your \ref CBLReplicatorChangeListener with an activity level of
    \ref kCBLReplicatorStopped after it stops. Until then, consider it still active. */
void CBLReplicator_Stop(CBLReplicator* _cbl_nonnull) CBLAPI;

/** Informs the replicator whether it's considered possible to reach the remote host with
    the current network configuration. The default value is true. This only affects the
    replicator's behavior while it's in the Offline state:
    * Setting it to false will cancel any pending retry and prevent future automatic retries.
    * Setting it back to true will initiate an immediate retry.*/
void CBLReplicator_SetHostReachable(CBLReplicator* _cbl_nonnull, bool reachable) CBLAPI;

/** Puts the replicator in or out of "suspended" state. The default is false.
    * Setting suspended=true causes the replicator to disconnect and enter Offline state;
      it will not attempt to reconnect while it's suspended.
    * Setting suspended=false causes the replicator to attempt to reconnect, _if_ it was
      connected when suspended, and is still in Offline state. */
void CBLReplicator_SetSuspended(CBLReplicator* repl, bool suspended) CBLAPI;

/** @} */



/** \name  Status and Progress
    @{
 */

/** The possible states a replicator can be in during its lifecycle. */
typedef CBL_ENUM(uint8_t, CBLReplicatorActivityLevel) {
    kCBLReplicatorStopped,    ///< The replicator is unstarted, finished, or hit a fatal error.
    kCBLReplicatorOffline,    ///< The replicator is offline, as the remote host is unreachable.
    kCBLReplicatorConnecting, ///< The replicator is connecting to the remote host.
    kCBLReplicatorIdle,       ///< The replicator is inactive, waiting for changes to sync.
    kCBLReplicatorBusy        ///< The replicator is actively transferring data.
};

/** A fractional progress value, ranging from 0.0 to 1.0 as replication progresses.
    The value is very approximate and may bounce around during replication; making it more
    accurate would require slowing down the replicator and incurring more load on the server.
    It's fine to use in a progress bar, though. */
typedef struct {
    float fractionComplete;     /// Very-approximate completion, from 0.0 to 1.0
    uint64_t documentCount;     ///< Number of documents transferred so far
} CBLReplicatorProgress;

/** A replicator's current status. */
typedef struct {
    CBLReplicatorActivityLevel activity;    ///< Current state
    CBLReplicatorProgress progress;         ///< Approximate fraction complete
    CBLError error;                         ///< Error, if any
} CBLReplicatorStatus;

/** Returns the replicator's current status. */
CBLReplicatorStatus CBLReplicator_Status(CBLReplicator* _cbl_nonnull) CBLAPI;

/** Indicates which documents have local changes that have not yet been pushed to the server
    by this replicator. This is of course a snapshot, that will go out of date as the replicator
    makes progress and/or documents are saved locally.

    The result is, effectively, a set of document IDs: a dictionary whose keys are the IDs and
    values are `true`.
    If there are no pending documents, the dictionary is empty.
    On error, NULL is returned.

    \note  This function can be called on a stopped or un-started replicator.
    \note  Documents that would never be pushed by this replicator, due to its configuration's
           `pushFilter` or `docIDs`, are ignored.
    \warning  You are responsible for releasing the returned array via \ref FLValue_Release. */
FLDict CBLReplicator_PendingDocumentIDs(CBLReplicator* _cbl_nonnull,
                                        CBLError*) CBLAPI;

/** Indicates whether the document with the given ID has local changes that have not yet been
    pushed to the server by this replicator.

    This is equivalent to, but faster than, calling \ref CBLReplicator_PendingDocumentIDs and
    checking whether the result contains \p docID. See that function's documentation for details.

    \note  A `false` result means the document is not pending, _or_ there was an error.
           To tell the difference, compare the error code to zero. */
bool CBLReplicator_IsDocumentPending(CBLReplicator *repl _cbl_nonnull,
                                     FLString docID,
                                     CBLError *outError) CBLAPI;


/** A callback that notifies you when the replicator's status changes.
    @warning  This callback will be called on a background thread managed by the replicator.
                It must pay attention to thread-safety. It should not take a long time to return,
                or it will slow down the replicator.
    @param context  The value given when the listener was added.
    @param replicator  The replicator.
    @param status  The replicator's status. */
typedef void (*CBLReplicatorChangeListener)(void *context, 
                                            CBLReplicator *replicator _cbl_nonnull,
                                            const CBLReplicatorStatus *status _cbl_nonnull);

/** Adds a listener that will be called when the replicator's status changes. */
CBLListenerToken* CBLReplicator_AddChangeListener(CBLReplicator* _cbl_nonnull,
                                                  CBLReplicatorChangeListener _cbl_nonnull, 
                                                  void *context) CBLAPI;


/** Flags describing a replicated document. */
typedef CBL_OPTIONS(unsigned, CBLDocumentFlags) {
    kCBLDocumentFlagsDeleted        = 1 << 0,   ///< The document has been deleted.
    kCBLDocumentFlagsAccessRemoved  = 1 << 1    ///< Lost access to the document on the server.
};


/** Information about a document that's been pushed or pulled. */
typedef struct {
    const char *ID;             ///< The document ID
    CBLDocumentFlags flags;     ///< Indicates whether the document was deleted or removed
    CBLError error;             ///< If the code is nonzero, the document failed to replicate.
} CBLReplicatedDocument;

/** A callback that notifies you when documents are replicated.
    @warning  This callback will be called on a background thread managed by the replicator.
                It must pay attention to thread-safety. It should not take a long time to return,
                or it will slow down the replicator.
    @param context  The value given when the listener was added.
    @param replicator  The replicator.
    @param isPush  True if the document(s) were pushed, false if pulled.
    @param numDocuments  The number of documents reported by this callback.
    @param documents  An array with information about each document. */
typedef void (*CBLReplicatedDocumentListener)(void *context,
                                              CBLReplicator *replicator _cbl_nonnull,
                                              bool isPush,
                                              unsigned numDocuments,
                                              const CBLReplicatedDocument* documents);

/** Adds a listener that will be called when documents are replicated. */
CBLListenerToken* CBLReplicator_AddDocumentListener(CBLReplicator* _cbl_nonnull,
                                                    CBLReplicatedDocumentListener _cbl_nonnull,
                                                    void *context) CBLAPI;

/** @} */
/** @} */

#ifdef __cplusplus
}
#endif
