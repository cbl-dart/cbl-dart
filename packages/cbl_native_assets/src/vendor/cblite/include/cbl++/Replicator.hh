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
#include "cbl/CBLReplicator.h"
#include "cbl/CBLDefaults.h"
#include <functional>
#include <string>
#include <vector>
#include <unordered_map>

// VOLATILE API: Couchbase Lite C++ API is not finalized, and may change in
// future releases.

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
        static Endpoint urlEndpoint(slice url) {
            CBLError error {};
            auto endpoint = CBLEndpoint_CreateWithURL(url, &error);
            if (!endpoint)
                throw error;
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
        static Authenticator basicAuthenticator(slice username, slice password) {
            return Authenticator(CBLAuth_CreatePassword(username, password));
        }

        /** Creates a sesssion authenticator using a Couchbase Sync Gateway login session identifier,
            and optionally a cookie name (pass NULL for the default.) */
        static Authenticator sessionAuthenticator(slice sessionId, slice cookieName) {
            return Authenticator(CBLAuth_CreateSession(sessionId, cookieName));
        }
        
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
    using ConflictResolver = std::function<Document(slice docID,
                                                    const Document localDoc,
                                                    const Document remoteDoc)>;

    /** The collection and the configuration that can be configured specifically for the replication. */
    class ReplicationCollection {
    public:
        /** Creates  ReplicationCollection with the collection. */
        ReplicationCollection(Collection collection)
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
        
        /** Optional callback to validate incoming docs. */
        ReplicationFilter pullFilter;
        
        //-- Conflict Resolver:
        /** Optional conflict-resolver callback. */
        ConflictResolver conflictResolver;
        
    private:
        Collection _collection;
    };

    /** The configuration of a replicator. */
    class ReplicatorConfiguration {
    public:
        /** Creates a config using a database to represent the default collection and an endpoint.
            @note Only the default collection will be used in the replication.
            @warning <b>Deprecated :</b>
                     Use ReplicatorConfiguration::ReplicatorConfiguration(std::vector<ReplicationCollection>collections, Endpoint endpoint)
                     instead.
            @param db The database to represent the default collection.
            @param endpoint The endpoint to replicate with. */
        ReplicatorConfiguration(Database db, Endpoint endpoint)
        :_database(db)
        ,_endpoint(endpoint)
        { }
        
        /** Creates a  config with a list of collections and per-collection configurations to replicate and an endpoint
            @param collections The collections and per-collection configurations.
            @param endpoint The endpoint to replicate with. */
        ReplicatorConfiguration(std::vector<ReplicationCollection>collections, Endpoint endpoint)
        :_collections(collections)
        ,_endpoint(endpoint)
        { }
        
        //-- Accessors:
        /** Returns the configured database. */
        Database database() const           {return _database;}
        /** Returns the configured endpoint. */
        Endpoint endpoint() const           {return _endpoint;}
        /** Returns the configured collections. */
        std::vector<ReplicationCollection> collections() const  {return _collections;}
        
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

        //-- Filtering:
        /** Optional set of channels to pull from when replicating with the default collection.
            @note This property can only be used when creating the config object with the database instead of collections.
            @warning <b>Deprecated :</b> Use ReplicationCollection::channels instead. */
        fleece::MutableArray channels       = fleece::MutableArray::newArray();
        
        /** Optional set of document IDs to replicate when replicating with the default collection.
            @note This property can only be used when creating the config object with the database instead of collections.
            @warning <b>Deprecated :</b> Use ReplicationCollection::documentIDs instead. */
        fleece::MutableArray documentIDs    = fleece::MutableArray::newArray();

        /** Optional callback to filter which docs are pushed when replicating with the default collection.
            @note This property can only be used when creating the config object with the database instead of collections.
            @warning <b>Deprecated :</b> Use ReplicationCollection::pushFilter instead. */
        ReplicationFilter pushFilter;
        
        /** Optional callback to validate incoming docs when replicating with the default collection.
            @note This property can only be used when creating the config object with the database instead of collections.
            @warning <b>Deprecated :</b> Use ReplicationCollection::pullFilter instead. */
        ReplicationFilter pullFilter;
        
        //-- Conflict Resolver:
        /** Optional conflict-resolver callback.
            @note This property can only be used when creating the config object with the database instead of collections.
            @warning <b>Deprecated :</b> Use ReplicationCollection::conflictResolver instead. */
        ConflictResolver conflictResolver;
        
    protected:
        friend class Replicator;
        
        /** Base config without database, collections, filters, and conflict resolver set. */
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
            return conf;
        }
        
    private:
        Database _database;
        Endpoint _endpoint;
        std::vector<ReplicationCollection> _collections;
    };

    /** Replicator for replicating documents in collections in local database and targeted database. */
    class Replicator : private RefCounted {
    public:
        /** Creates a new replicator using the specified config. */
        Replicator(const ReplicatorConfiguration& config)
        {
            // Get the current configured collections and populate one for the
            // default collection if the config is configured with the database:
            auto collections = config.collections();
            
            auto database = config.database();
            if (database) {
                assert(collections.empty());
                auto defaultCollection = database.getDefaultCollection();
                if (!defaultCollection) {
                    throw std::invalid_argument("default collection not exist");
                }
                ReplicationCollection col = ReplicationCollection(defaultCollection);
                col.channels = config.channels;
                col.documentIDs = config.documentIDs;
                col.pushFilter = config.pushFilter;
                col.pullFilter = config.pullFilter;
                col.conflictResolver = config.conflictResolver;
                collections.push_back(col);
            }
            
            // Created a shared collection map. The pointer of the collection map will be
            // used as a context.
            _collectionMap = std::shared_ptr<CollectionToReplCollectionMap>(new CollectionToReplCollectionMap());
            
            // Get base C config:
            CBLReplicatorConfiguration c_config = config;
            
            // Construct C replication collections to set to the c_config:
            std::vector<CBLReplicationCollection> replCols;
            for (int i = 0; i < collections.size(); i++) {
                ReplicationCollection& col = collections[i];
                
                CBLReplicationCollection replCol {};
                replCol.collection = col.collection().ref();
                
                if (!col.channels.empty()) {
                    replCol.channels = col.channels;
                }

                if (!col.documentIDs.empty()) {
                    replCol.documentIDs = col.documentIDs;
                }

                if (col.pushFilter) {
                    replCol.pushFilter = [](void* context,
                                            CBLDocument* cDoc,
                                            CBLDocumentFlags flags) -> bool {
                        auto doc = Document(cDoc);
                        auto map = (CollectionToReplCollectionMap*)context;
                        return map->find(doc.collection())->second.pushFilter(doc, flags);
                    };
                }
                
                if (col.pullFilter) {
                    replCol.pullFilter = [](void* context,
                                            CBLDocument* cDoc,
                                            CBLDocumentFlags flags) -> bool {
                        auto doc = Document(cDoc);
                        auto map = (CollectionToReplCollectionMap*)context;
                        return map->find(doc.collection())->second.pullFilter(doc, flags);
                    };
                }
                
                if (col.conflictResolver) {
                    replCol.conflictResolver = [](void* context,
                                                 FLString docID,
                                                 const CBLDocument* cLocalDoc,
                                                 const CBLDocument* cRemoteDoc) -> const CBLDocument*
                    {
                        auto localDoc = Document(cLocalDoc);
                        auto remoteDoc = Document(cRemoteDoc);
                        auto collection = localDoc ? localDoc.collection() : remoteDoc.collection();
                        
                        auto map = (CollectionToReplCollectionMap*)context;
                        auto resolved = map->find(collection)->second.
                            conflictResolver(slice(docID), localDoc, remoteDoc);
                        
                        auto ref = resolved.ref();
                        if (ref && ref != cLocalDoc && ref != cRemoteDoc) {
                            CBLDocument_Retain(ref);
                        }
                        return ref;
                    };
                }
                replCols.push_back(replCol);
                _collectionMap->insert({col.collection(), col});
            }
            
            c_config.collections = replCols.data();
            c_config.collectionCount = replCols.size();
            c_config.context = _collectionMap.get();
            
            CBLError error {};
            _ref = (CBLRefCounted*) CBLReplicator_Create(&c_config, &error);
            check(_ref, error);
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

        /** Indicates which documents in the default collection have local changes that have not yet
            been pushed to the server by this replicator. This is of course a snapshot, that will
            go out of date as the replicator makes progress and/or documents are saved locally.

            The result is, effectively, a set of document IDs: a dictionary whose keys are the IDs and
            values are `true`.
            If there are no pending documents, the dictionary is empty.
            @note This function can be called on a stopped or un-started replicator.
            @note Documents that would never be pushed by this replicator, due to its configuration's
                  `pushFilter` or `docIDs`, are ignored.
            @warning If the default collection is not part of the replication, an error will be thrown.
            @warning <b>Deprecated :</b> Use Replicator::pendingDocumentIDs(Collection& collection) instead. */
        fleece::Dict pendingDocumentIDs() const {
            CBLError error;
            fleece::Dict result = CBLReplicator_PendingDocumentIDs(ref(), &error);
            check(result != nullptr, error);
            return result;
        }

        /** Indicates whether the document in the default collection with the given ID has local changes that
            have not yet been pushed to the server by this replicator.

            This is equivalent to, but faster than, calling \ref Replicator::pendingDocumentIDs() and
            checking whether the result contains \p docID. See that function's documentation for details.
            @note A `false` result means the document is not pending, _or_ there was an error.
                  To tell the difference, compare the error code to zero.
            @warning If the default collection is not part of the replication, an error will be thrown.
            @warning <b>Deprecated :</b> Use Replicator::isDocumentPending(fleece::slice docID, Collection& collection) instead. */
        bool isDocumentPending(fleece::slice docID) const {
            CBLError error;
            bool pending = CBLReplicator_IsDocumentPending(ref(), docID, &error);
            check(pending || error.code == 0, error);
            return pending;
        }
        
        /** Indicates which documents in the given collection have local changes that have not yet been
            pushed to the server by this replicator. This is of course a snapshot, that will go out of date
            as the replicator makes progress and/or documents are saved locally.
            
            The result is, effectively, a set of document IDs: a dictionary whose keys are the IDs and
            values are `true`.
            If there are no pending documents, the dictionary is empty.
            @warning If the given collection is not part of the replication, an error will be thrown. */
        fleece::Dict pendingDocumentIDs(Collection& collection) const {
            CBLError error;
            fleece::Dict result = CBLReplicator_PendingDocumentIDs2(ref(), collection.ref(), &error);
            check(result != nullptr, error);
            return result;
        }
        
        /** Indicates whether the document with the given ID in the given collection has local changes
            that have not yet been pushed to the server by this replicator.
         
            This is equivalent to, but faster than, calling \ref Replicator::pendingDocumentIDs(Collection& collection) and
            checking whether the result contains \p docID. See that function's documentation for details.
            @note A `false` result means the document is not pending, _or_ there was an error.
                  To tell the difference, compare the error code to zero.
            @warning If the given collection is not part of the replication, an error will be thrown. */
        bool isDocumentPending(fleece::slice docID, Collection& collection) const {
            CBLError error;
            bool pending = CBLReplicator_IsDocumentPending2(ref(), docID, collection.ref(), &error);
            check(pending || error.code == 0, error);
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
        
        using CollectionToReplCollectionMap = std::unordered_map<Collection, ReplicationCollection>;
        std::shared_ptr<CollectionToReplCollectionMap> _collectionMap;
        
        CBL_REFCOUNTED_WITHOUT_COPY_MOVE_BOILERPLATE(Replicator, RefCounted, CBLReplicator)
        
    public:
        Replicator(const Replicator &other) noexcept
        :RefCounted(other)
        ,_collectionMap(other._collectionMap)
        { }
        
        Replicator(Replicator &&other) noexcept
        :RefCounted((RefCounted&&)other)
        ,_collectionMap(std::move(other._collectionMap))
        { }
        
        Replicator& operator=(const Replicator &other) noexcept {
            RefCounted::operator=(other);
            _collectionMap = other._collectionMap;
            return *this;
        }
        
        Replicator& operator=(Replicator &&other) noexcept {
            RefCounted::operator=((RefCounted&&)other);
            _collectionMap = std::move(other._collectionMap);
            return *this;
        }
        
        void clear() {
            RefCounted::clear();
            _collectionMap.reset();
        }
    };
}

CBL_ASSUME_NONNULL_END
