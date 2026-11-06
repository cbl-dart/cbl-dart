//
//  Replicator.hh
//
// Copyright (c) 2019 Couchbase, Inc All rights reserved.
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
#include "cbl++/Document.hh"
#include "cbl++/TLSIdentity.hh"
#include "cbl/CBLReplicator.h"
#include "cbl/CBLDefaults.h"
#include <functional>
#include <optional>
#include <string>
#include <string_view>
#include <vector>
#include <unordered_map>


CBL_ASSUME_NONNULL_BEGIN

namespace cbl {

    /** The replication endpoint representing the location of a database to replicate with. */
    class Endpoint {
    public:        
        /** Creates a URL endpoint with a given URL.
            The URL's scheme must be `ws` or `wss`, it must of course have a valid hostname,
            and its path must be the name of the database on that server.
         
            The port can be omitted; it defaults to 80 for `ws` and 443 for `wss`.
            For example: `wss://example.org/dbname`.
            @param url  The url. */
        static Endpoint urlEndpoint(std::string_view url) {
            CBLError error {};
            auto endpoint = CBLEndpoint_CreateWithURL(slice(url), &error);
            internal::check(endpoint, error);
            return Endpoint(endpoint);
        }
        
#ifdef COUCHBASE_ENTERPRISE
        /** Creates a database endpoint with another local database. (Enterprise Edition only.) */
        static Endpoint databaseEndpoint(Database db) {
            return Endpoint(CBLEndpoint_CreateWithLocalDB(db.ref()));
        }
#endif
        
    protected:
        friend class ReplicatorConfiguration;
        
        CBLEndpoint* _cbl_nullable ref() const {return _ref.get();}

    private:
        Endpoint() = default;
        
        Endpoint(CBLEndpoint* ref) {
            _ref = std::shared_ptr<CBLEndpoint>(ref, [](auto r) {
                CBLEndpoint_Free(r);
            });
        }
        
        std::shared_ptr<CBLEndpoint> _ref;
    };

    /** Authentication credentials for a remote server. */
    class Authenticator {
    public:
        /** Creates a basic authenticator authenticator using username/password credentials. */
        static Authenticator basicAuthenticator(std::string_view username, std::string_view password) {
            return Authenticator(CBLAuth_CreatePassword(slice(username), slice(password)));
        }

        /** Creates a sesssion authenticator using a Couchbase Sync Gateway login session identifier,
            and optionally a cookie name. */
        static Authenticator sessionAuthenticator(std::string_view sessionId, std::optional<std::string_view> cookieName =std::nullopt) {
            slice cname;
            if ( cookieName ) cname = *cookieName;
            return Authenticator(CBLAuth_CreateSession(slice(sessionId), cname));
        }

#ifdef COUCHBASE_ENTERPRISE
        /** Creates a certificate authenticator using a TLS client identity. (Enterprise Edition only.) */
        static Authenticator certificateAuthenticator(const TLSIdentity& identity) {
            if ( !identity ) {
                throw Error{kCBLDomain, kCBLErrorInvalidParameter, "identity must not be empty"};
            }
            return Authenticator(CBLAuth_CreateCertificate(identity.ref()));
        }
#endif

    protected:
        friend class ReplicatorConfiguration;
        
        CBLAuthenticator* _cbl_nullable ref() const {return _ref.get();}
        
    private:
        Authenticator() = default;
        
        Authenticator(CBLAuthenticator* ref) {
            _ref = std::shared_ptr<CBLAuthenticator>(ref, [](auto r) {
                CBLAuth_Free(r);
            });
        }

        std::shared_ptr<CBLAuthenticator> _ref;
    };

    /** Replication Filter Function Callback. */
    using ReplicationFilter = std::function<bool(Document, CBLDocumentFlags flags)>;

    /** Replication Conflict Resolver Function Callback. */
    using ConflictResolver = std::function<Document(std::string_view docID,
                                                    const Document localDoc,
                                                    const Document remoteDoc)>;

#ifdef COUCHBASE_ENTERPRISE
    /** Result returned by a \ref PropertyEncryptor callback. */
    struct EncryptionResult {
        fleece::alloc_slice ciphertext;          ///< Encrypted data. Empty = skip (results in a crypto error).
        std::optional<std::string> algorithm;   ///< Optional algorithm name. Default: "CB_MOBILE_CUSTOM".
        std::optional<std::string> keyID;       ///< Optional key identifier.
        CBLError error {};              ///< Optional error. Non-zero aborts replication for this doc.
    };

    /** Result returned by a \ref PropertyDecryptor callback. */
    struct DecryptionResult {
        fleece::alloc_slice plaintext;  ///< Decrypted data. Empty = leave property in encrypted form.
        CBLError error {};              ///< Optional error. Non-zero aborts replication for this doc.
    };

    /** Property Encryptor Function Callback. (Enterprise Edition only.)
        Called by the push replicator for each encryptable property in a document. */
    using PropertyEncryptor = std::function<EncryptionResult(
        fleece::slice scope,
        fleece::slice collection,
        fleece::slice documentID,
        fleece::Dict properties,
        fleece::slice keyPath,
        fleece::slice input)>;

    /** Property Decryptor Function Callback. (Enterprise Edition only.)
        Called by the pull replicator for each encrypted property in a document. */
    using PropertyDecryptor = std::function<DecryptionResult(
        fleece::slice scope,
        fleece::slice collection,
        fleece::slice documentID,
        fleece::Dict properties,
        fleece::slice keyPath,
        fleece::slice input,
        std::optional<std::string_view> algorithm,
        std::optional<std::string_view> keyID)>;
#endif

    /** A collection to replicate, along with its collection-specific replication settings
        such as filters and a conflict resolver. */
    class CollectionConfiguration {
    public:
        /** Creates CollectionConfiguration with the collection. */
        CollectionConfiguration(Collection collection)
        :_collection(collection)
        { }
        
        //-- Accessors:
        /** The collection. */
        Collection collection() const       {return _collection;}
        
        //-- Filtering:
        /** Optional set of channels to pull from. */
        fleece::MutableArray channels       = fleece::MutableArray::newArray();
        
        /** Optional set of document IDs to replicate. */
        fleece::MutableArray documentIDs    = fleece::MutableArray::newArray();

        /** Optional callback to filter which docs are pushed. */
        ReplicationFilter pushFilter;
        
        /** Optional callback to filter which docs are pulled. */
        ReplicationFilter pullFilter;
        
        //-- Conflict Resolver:
        /** Optional conflict-resolver callback. */
        ConflictResolver conflictResolver;
        
    private:
        Collection _collection;
    };

    /** Deprecated alias for backward compatibility
        @warning <b>Deprecated :</b> Use CollectionConfiguration instead. */
    using ReplicationCollection = CollectionConfiguration;

    /** The configuration of a replicator. */
    class ReplicatorConfiguration {
    public:
        /** Creates a  config with a list of collections and per-collection configurations to replicate and an endpoint
            @param collections The collections and per-collection configurations.
            @param endpoint The endpoint to replicate with. */
        ReplicatorConfiguration(std::vector<CollectionConfiguration>collections, Endpoint endpoint)
        :_collections(collections)
        ,_endpoint(endpoint)
        { }
        
        //-- Accessors:
        
        /** Returns the configured collections. */
        std::vector<CollectionConfiguration> collections() const  {return _collections;}
        
        /** Returns the configured endpoint. */
        Endpoint endpoint() const           {return _endpoint;}
        
        //-- Types:
        /** Replicator type : Push, pull or both  */
        CBLReplicatorType replicatorType    = kCBLReplicatorTypePushAndPull;
        /** Continuous replication or single-shot replication. */
        bool continuous                     = false;
        
        //-- Auto Purge:
        /** Enabled auto-purge or not.
            If auto purge is enabled, then the replicator will automatically purge any documents
            that the replicating user loses access to via the Sync Function on Sync Gateway. */
        bool enableAutoPurge                = true;
        
        //-- Retry Logic:
        /** Max retry attempts where the initial connect to replicate counts toward the given value.
            Specify 0 to use the default value, 10 times for a non-continuous replicator and max-int time for a continuous replicator.
            Specify 1 means there will be no retry after the first attempt. */
        unsigned maxAttempts                = 0;
        /** Max wait time between retry attempts in seconds.
            Specify 0 to use the default value of 300 seconds. */
        unsigned maxAttemptWaitTime         = 0;
        
        //-- WebSocket:
        /** The heartbeat interval in seconds.
            Specify 0 to use the default value of 300 seconds. */
        unsigned heartbeat                  = 0;
        
    #ifdef __CBL_REPLICATOR_NETWORK_INTERFACE__
        /** The specific network interface to be used by the replicator to connect to the remote server.
            If not specified, an active network interface based on the OS's routing table will be used.
            @NOTE The networkInterface configuration is not supported. */
        std::string networkInterface;
    #endif

        //-- HTTP settings:
        /** Authentication credentials, if needed. */
        Authenticator authenticator;
        /** HTTP client proxy settings. */
        CBLProxySettings* _cbl_nullable proxy = nullptr;
        /** Extra HTTP headers to add to the WebSocket request. */
        fleece::MutableDict headers         = fleece::MutableDict::newDict();

        //-- Advance HTTP settings:
        /** The option to remove the restriction that does not allow the replicator to save the parent-domain
            cookies, the cookies whose domains are the parent domain of the remote host, from the HTTP
            response. For example, when the option is set to true, the cookies whose domain are “.foo.com”
            returned by “bar.foo.com” host will be permitted to save. This is only recommended if the host
            issuing the cookie is well trusted.
         
            This option is disabled by default, which means that the parent-domain cookies are not permitted
            to save by default. */
        bool acceptParentDomainCookies      = kCBLDefaultReplicatorAcceptParentCookies;

        //-- TLS settings:
        /** An X.509 cert (PEM or DER) to "pin" for TLS connections. The pinned cert will be evaluated against any certs
            in a cert chain, and the cert chain will be valid only if the cert chain contains the pinned cert. */
        std::string pinnedServerCertificate;
        /** Set of anchor certs (PEM format). */
        std::string trustedRootCertificates;
#ifdef COUCHBASE_ENTERPRISE
        /** Accept only self-signed server certificates; any other certificates are rejected.
            (Enterprise Edition only.) */
        bool acceptOnlySelfSignedServerCertificate = false;
#endif

#ifdef COUCHBASE_ENTERPRISE
        //-- Property Encryption (Enterprise Edition only):
        /** Optional callback to encrypt encryptable properties during push replication. */
        PropertyEncryptor documentPropertyEncryptor;
        /** Optional callback to decrypt encrypted properties during pull replication. */
        PropertyDecryptor documentPropertyDecryptor;
#endif

    protected:
        friend class Replicator;
        
        /** Base config without collections set. */
        operator CBLReplicatorConfiguration() const {
            CBLReplicatorConfiguration conf = {};
            conf.endpoint = _endpoint.ref();
            assert(conf.endpoint);
            conf.replicatorType = replicatorType;
            conf.continuous = continuous;
            conf.disableAutoPurge = !enableAutoPurge;
            conf.maxAttempts = maxAttempts;
            conf.maxAttemptWaitTime = maxAttemptWaitTime;
            conf.heartbeat = heartbeat;
            conf.authenticator = authenticator.ref();
            conf.acceptParentDomainCookies = acceptParentDomainCookies;
            conf.proxy = proxy;
            if (!headers.empty())
                conf.headers = headers;
        #ifdef __CBL_REPLICATOR_NETWORK_INTERFACE__
            if (!networkInterface.empty())
                conf.networkInterface = slice(networkInterface);
        #endif
            if (!pinnedServerCertificate.empty())
                conf.pinnedServerCertificate = slice(pinnedServerCertificate);
            if (!trustedRootCertificates.empty())
                conf.trustedRootCertificates = slice(trustedRootCertificates);
#ifdef COUCHBASE_ENTERPRISE
            conf.acceptOnlySelfSignedServerCertificate = acceptOnlySelfSignedServerCertificate;
#endif
            return conf;
        }
        
    private:
        Endpoint _endpoint;
        std::vector<CollectionConfiguration> _collections;
    };

    /** A replicator that syncs documents between a local database's collections and a target database. */
    class Replicator : private RefCounted {
    public:
        /** Creates a new replicator using the specified config. */
        Replicator(const ReplicatorConfiguration& config)
        {
            // Get the current configured collections and populate one for the
            // default collection if the config is configured with the database:
            auto collections = config.collections();

            // Create a shared context. Its pointer is passed as the C-level context so
            // that all captureless C callbacks (filters, conflict resolver, encryptor,
            // decryptor) can reach both the collection map and the crypto functions.
            _context = std::make_shared<ReplicatorContext>();

            // Get base C config:
            CBLReplicatorConfiguration c_config = config;

            // Construct C replication collections to set to the c_config:
            std::vector<CBLCollectionConfiguration> colConfigs;
            for (int i = 0; i < collections.size(); i++) {
                CollectionConfiguration& col = collections[i];

                CBLCollectionConfiguration colConfig {};
                colConfig.collection = col.collection().ref();

                if (!col.channels.empty()) {
                    colConfig.channels = col.channels;
                }

                if (!col.documentIDs.empty()) {
                    colConfig.documentIDs = col.documentIDs;
                }

                if (col.pushFilter) {
                    colConfig.pushFilter = [](void* context,
                                              CBLDocument* cDoc,
                                              CBLDocumentFlags flags) -> bool {
                        auto doc = Document(cDoc);
                        auto ctx = (ReplicatorContext*)context;
                        return ctx->collectionMap.find(doc.collection())->second.pushFilter(doc, flags);
                    };
                }

                if (col.pullFilter) {
                    colConfig.pullFilter = [](void* context,
                                              CBLDocument* cDoc,
                                              CBLDocumentFlags flags) -> bool {
                        auto doc = Document(cDoc);
                        auto ctx = (ReplicatorContext*)context;
                        return ctx->collectionMap.find(doc.collection())->second.pullFilter(doc, flags);
                    };
                }

                if (col.conflictResolver) {
                    colConfig.conflictResolver = [](void* context,
                                                    FLString docID,
                                                    const CBLDocument* cLocalDoc,
                                                    const CBLDocument* cRemoteDoc) -> const CBLDocument*
                    {
                        auto localDoc = Document(cLocalDoc);
                        auto remoteDoc = Document(cRemoteDoc);
                        auto collection = localDoc ? localDoc.collection() : remoteDoc.collection();

                        auto ctx = (ReplicatorContext*)context;
                        auto resolved = ctx->collectionMap.find(collection)->second.
                            conflictResolver((std::string_view)slice(docID), localDoc, remoteDoc);

                        auto ref = resolved.ref();
                        if (ref && ref != cLocalDoc && ref != cRemoteDoc) {
                            CBLDocument_Retain(ref);
                        }
                        return ref;
                    };
                }
                colConfigs.push_back(colConfig);
                _context->collectionMap.insert({col.collection(), col});
            }

            c_config.collections = colConfigs.data();
            c_config.collectionCount = colConfigs.size();
            c_config.context = _context.get();

#ifdef COUCHBASE_ENTERPRISE
            if (config.documentPropertyEncryptor) {
                _context->encryptor = config.documentPropertyEncryptor;
                c_config.documentPropertyEncryptor = [](void* context,
                                                        FLString scope,
                                                        FLString collection,
                                                        FLString documentID,
                                                        FLDict properties,
                                                        FLString keyPath,
                                                        FLSlice input,
                                                        FLStringResult* algorithm,
                                                        FLStringResult* keyID,
                                                        CBLError* error) -> FLSliceResult {
                    auto ctx = (ReplicatorContext*)context;
                    auto r = ctx->encryptor(scope, collection, documentID, properties, keyPath, input);
                    if (error)     *error     = r.error;
                    if (algorithm) *algorithm = r.algorithm ? FLStringResult(slice(*r.algorithm)) : FLStringResult{};
                    if (keyID)     *keyID     = r.keyID ? FLStringResult(slice(*r.keyID)) : FLStringResult{};
                    return FLSliceResult(r.ciphertext);
                };
            }

            if (config.documentPropertyDecryptor) {
                _context->decryptor = config.documentPropertyDecryptor;
                c_config.documentPropertyDecryptor = [](void* context,
                                                        FLString scope,
                                                        FLString collection,
                                                        FLString documentID,
                                                        FLDict properties,
                                                        FLString keyPath,
                                                        FLSlice input,
                                                        FLString algorithm,
                                                        FLString keyID,
                                                        CBLError* error) -> FLSliceResult {
                    auto ctx = (ReplicatorContext*)context;
                    auto toOpt = [](FLString s) -> std::optional<std::string_view> {
                        return s.buf ? std::optional<std::string_view>{{(const char*)s.buf, s.size}} : std::nullopt;
                    };
                    auto r = ctx->decryptor(scope, collection, documentID, properties, keyPath, input,
                                            toOpt(algorithm), toOpt(keyID));
                    if (error) *error = r.error;
                    return FLSliceResult(r.plaintext);
                };
            }
#endif

            CBLError error {};
            _ref = (CBLRefCounted*) CBLReplicator_Create(&c_config, &error);
            internal::check(_ref, error);
        }

        /** Starts a replicator, asynchronously. Does nothing if it's already started.
            @note Replicators cannot be started from within a database's transaction.
            @param resetCheckpoint  If true, the persistent saved state ("checkpoint") for this replication
                                   will be discarded, causing it to re-scan all documents. This significantly
                                   increases time and bandwidth (redundant docs are not transferred, but their
                                   IDs are) but can resolve unexpected problems with missing documents if one
                                   side or the other has gotten out of sync. */
        void start(bool resetCheckpoint =false) {CBLReplicator_Start(ref(), resetCheckpoint);}
        
        /** Stops a running replicator, asynchronously. Does nothing if it's not already started.
            The replicator will call your replicator change listener if registered with an activity level of
            \ref kCBLReplicatorStopped after it stops. Until then, consider it still active. */
        void stop()                         {CBLReplicator_Stop(ref());}

        /** Informs the replicator whether it's considered possible to reach the remote host with
            the current network configuration. The default value is true. This only affects the
            replicator's behavior while it's in the Offline state:
            * Setting it to false will cancel any pending retry and prevent future automatic retries.
            * Setting it back to true will initiate an immediate retry. */
        void setHostReachable(bool r)       {CBLReplicator_SetHostReachable(ref(), r);}
        
        /** Puts the replicator in or out of "suspended" state. The default is false.
            * Setting suspended=true causes the replicator to disconnect and enter Offline state;
              it will not attempt to reconnect while it's suspended.
            * Setting suspended=false causes the replicator to attempt to reconnect, _if_ it was
              connected when suspended, and is still in Offline state. */
        void setSuspended(bool s)           {CBLReplicator_SetSuspended(ref(), s);}

        /** Returns the replicator's current status. */
        CBLReplicatorStatus status() const  {return CBLReplicator_Status(ref());}

        /** Returns the ID used to correlate the replication session with the remote endpoint.
            This value is intended for logging and diagnostics, and is an empty string until the
            replicator receives a correlation ID from the remote endpoint. */
        std::string correlationID() const  {return internal::asString(CBLReplicator_CorrelationID(ref()));}

        /** Indicates which documents in the given collection have local changes that have not yet been
            pushed to the server by this replicator. This is of course a snapshot, that will go out of date
            as the replicator makes progress and/or documents are saved locally.
            
            The result is, effectively, a set of document IDs: a dictionary whose keys are the IDs and
            values are `true`.
            If there are no pending documents, the dictionary is empty.
            @warning If the given collection is not part of the replication, an error will be thrown. */
        fleece::Dict pendingDocumentIDs(Collection& collection) const {
            CBLError error;
            fleece::Dict result = CBLReplicator_PendingDocumentIDs(ref(), collection.ref(), &error);
            internal::check(result != nullptr, error);
            return result;
        }
        
        /** Indicates whether the document with the given ID in the given collection has local changes
            that have not yet been pushed to the server by this replicator.
         
            This is equivalent to, but faster than, calling \ref Replicator::pendingDocumentIDs and
            checking whether the result contains \p docID. See that function's documentation for details.
            @note A `false` result means the document is not pending, _or_ there was an error.
                  To tell the difference, compare the error code to zero.
            @warning If the given collection is not part of the replication, an error will be thrown. */
        bool isDocumentPending(std::string_view docID, Collection& collection) const {
            CBLError error;
            bool pending = CBLReplicator_IsDocumentPending(ref(), slice(docID), collection.ref(), &error);
            internal::check(pending || error.code == 0, error);
            return pending;
        }
        
        /** A change listener that notifies you when the replicator's status changes.
            @note The listener's callback will be called on a background thread managed by the replicator.
                  It must pay attention to thread-safety. It should not take a long time to return,
                  or it will slow down the replicator. */
        using ChangeListener = cbl::ListenerToken<Replicator, const CBLReplicatorStatus&>;
        
        /** Registers a listener that will be called when the replicator's status changes.
            @param callback  The callback to be invoked.
            @return A Change Listener Token. Call \ref ListenerToken::remove() method to remove the listener. */
        [[nodiscard]] ChangeListener addChangeListener(ChangeListener::Callback callback) {
            auto l = ChangeListener(callback);
            l.setToken( CBLReplicator_AddChangeListener(ref(), &_callChangeListener, l.context()) );
            return l;
        }
        
        /** A document replication listener that notifies you when documents are replicated.
            @note The listener's callback will be called on a background thread managed by the replicator.
                  It must pay attention to thread-safety. It should not take a long time to return,
                  or it will slow down the replicator. */
        using DocumentReplicationListener = cbl::ListenerToken<Replicator, bool,
            const std::vector<CBLReplicatedDocument>>;

        /** Registers a listener that will be called when documents are replicated.
            @param callback  The callback to be invoked.
            @return A Change Listener Token. Call \ref ListenerToken::remove() method to remove the listener. */
        [[nodiscard]] DocumentReplicationListener addDocumentReplicationListener(DocumentReplicationListener::Callback callback) {
            auto l = DocumentReplicationListener(callback);
            l.setToken( CBLReplicator_AddDocumentReplicationListener(ref(), &_callDocListener, l.context()) );
            return l;
        }
        
    private:
        static void _callChangeListener(void* _cbl_nullable context,
                                        CBLReplicator *repl,
                                        const CBLReplicatorStatus *status)
        {
            ChangeListener::call(context, Replicator(repl), *status);
        }

        static void _callDocListener(void* _cbl_nullable context,
                                     CBLReplicator *repl,
                                     bool isPush,
                                     unsigned numDocuments,
                                     const CBLReplicatedDocument* documents)
        {
            std::vector<CBLReplicatedDocument> docs(&documents[0], &documents[numDocuments]);
            DocumentReplicationListener::call(context, Replicator(repl), isPush, docs);
        }
        
        using CollectionToReplCollectionMap = std::unordered_map<Collection, CollectionConfiguration>;

        struct ReplicatorContext {
            CollectionToReplCollectionMap collectionMap;
#ifdef COUCHBASE_ENTERPRISE
            PropertyEncryptor encryptor;
            PropertyDecryptor decryptor;
#endif
        };
        std::shared_ptr<ReplicatorContext> _context;
        
        CBL_REFCOUNTED_WITHOUT_COPY_MOVE_BOILERPLATE(Replicator, RefCounted, CBLReplicator)
        
    public:
        /** Copy constructor. Both `*this` and `other` refer to the same underlying
            \ref CBLReplicator handle (its refcount is incremented) and share the
            collection-configuration map. */
        Replicator(const Replicator &other) noexcept
        :RefCounted(other)
        ,_context(other._context)
        { }

        /** Move constructor. Takes over `other`'s \ref CBLReplicator handle and
            collection-configuration map, leaving `other` empty. */
        Replicator(Replicator &&other) noexcept
        :RefCounted((RefCounted&&)other)
        ,_context(std::move(other._context))
        { }

        /** Copy assignment. Releases the currently-referenced handle (if any), then
            makes `*this` refer to the same \ref CBLReplicator as `other` (refcount
            incremented) and share its collection-configuration map. */
        Replicator& operator=(const Replicator &other) noexcept {
            RefCounted::operator=(other);
            _context = other._context;
            return *this;
        }

        /** Move assignment. Releases the currently-referenced handle (if any), then
            takes over `other`'s \ref CBLReplicator handle and collection-configuration
            map; `other` is left empty. */
        Replicator& operator=(Replicator &&other) noexcept {
            RefCounted::operator=((RefCounted&&)other);
            _context = std::move(other._context);
            return *this;
        }
        
        /** Releases the underlying C \ref CBLReplicator and drops the C++ collection-configuration
            map. After this call the object is empty (its \ref Replicator::operator bool() const
            returns false). */
        void clear() {
            RefCounted::clear();
            _context.reset();
        }
    };
}

CBL_ASSUME_NONNULL_END
