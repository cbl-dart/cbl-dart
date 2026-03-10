//
// Database.hh
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
#include "cbl++/Base.hh"
#include "cbl/CBLCollection.h"
#include "cbl/CBLDatabase.h"
#include "cbl/CBLDocument.h"
#include "cbl/CBLQuery.h"
#include "cbl/CBLLog.h"
#include "cbl/CBLScope.h"
#include "fleece/Mutable.hh"
#include <exception>
#include <functional>
#include <mutex>
#include <string>
#include <vector>

// VOLATILE API: Couchbase Lite C++ API is not finalized, and may change in
// future releases.

CBL_ASSUME_NONNULL_BEGIN

namespace cbl {
    class Collection;
    class Document;
    class MutableDocument;
    class Query;

    /** Conflict handler used when saving a document. */
    using ConflictHandler = std::function<bool(MutableDocument documentBeingSaved,
                                               Document conflictingDocument)>;

    
#ifdef COUCHBASE_ENTERPRISE
    /** ENTERPRISE EDITION ONLY
     
        Couchbase Lite  Extension. */
    class Extension {
    public:
        /** Enables Vector Search extension by specifying the extension path to search for the Vector Search extension library.
            This function must be called before opening a database that intends to use the vector search extension.
            @param path The file system path of the directory that contains the Vector Search extension library.
            @note Must be called before opening a database that intends to use the vector search extension. */
        static void enableVectorSearch(slice path) {
            CBLError error {};
            RefCounted::check(CBL_EnableVectorSearch(path, &error), error);
        }
    };
#endif

    /** Couchbase Lite Database. */
    class Database : private RefCounted {
    public:
        // Static database-file operations:

        /** Returns true if a database with the given name exists in the given directory.
            @param name  The database name (without the ".cblite2" extension.)
            @param inDirectory  The directory containing the database. If NULL, `name` must be an
                               absolute or relative path to the database. */
        static bool exists(slice name,
                           slice inDirectory)
        {
            return CBL_DatabaseExists(name, inDirectory);
        }

        /** Copies a database file to a new location, and assigns it a new internal UUID to distinguish
            it from the original database when replicating.
            @param fromPath  The full filesystem path to the original database (including extension).
            @param toName  The new database name (without the ".cblite2" extension.) */
        static void copyDatabase(slice fromPath,
                                 slice toName)
        {
            CBLError error;
            check( CBL_CopyDatabase(fromPath, toName,
                                    nullptr, &error), error );
        }

        /** Copies a database file to a new location, and assigns it a new internal UUID to distinguish
            it from the original database when replicating.
            @param fromPath  The full filesystem path to the original database (including extension).
            @param toName  The new database name (without the ".cblite2" extension.)
            @param config  The database configuration (directory and encryption option.) */
        static void copyDatabase(slice fromPath,
                                 slice toName,
                                 const CBLDatabaseConfiguration& config)
        {
            CBLError error;
            check( CBL_CopyDatabase(fromPath, toName,
                                    &config, &error), error );
        }

        /** Deletes a database file. If the database file is open, an error will be thrown.
            @param name  The database name (without the ".cblite2" extension.)
            @param inDirectory  The directory containing the database. If NULL, `name` must be an
                                absolute or relative path to the database. */
        static void deleteDatabase(slice name,
                                   slice inDirectory)
        {
            CBLError error;
            if (!CBL_DeleteDatabase(name,
                                    inDirectory,
                                    &error) && error.code != 0)
                check(false, error);
        }

        // Lifecycle:

        /** Opens a database, or creates it if it doesn't exist yet, returning a new \ref Database instance.
            It's OK to open the same database file multiple times. Each \ref Database instance is
            independent of the others (and must be separately closed and released.)
            @param name  The database name (without the ".cblite2" extension.) */
        Database(slice name) {
            open(name, nullptr);
        }

        /** Opens a database, or creates it if it doesn't exist yet, returning a new \ref Database instance.
            It's OK to open the same database file multiple times. Each \ref Database instance is
            independent of the others (and must be separately closed and released.)
            @param name  The database name (without the ".cblite2" extension.)
            @param config  The database configuration (directory and encryption option.) */
        Database(slice name,
                 const CBLDatabaseConfiguration& config)
        {
            open(name, &config);
        }

        /** Closes an open database. */
        void close() {
            CBLError error;
            check(CBLDatabase_Close(ref(), &error), error);
        }

        /** Closes and deletes a database. */
        void deleteDatabase() {
            CBLError error;
            check(CBLDatabase_Delete(ref(), &error), error);
        }
        
        /** Performs database maintenance.
            @param type  The database maintenance type. */
        void performMaintenance(CBLMaintenanceType type) {
            CBLError error;
            check(CBLDatabase_PerformMaintenance(ref(), type, &error), error);
        }

        // Accessors:
        
        /** Returns the database's name. */
        std::string name() const                        {return asString(CBLDatabase_Name(ref()));}
        
        /** Returns the database's full filesystem path, or an empty string if the database is closed or deleted. */
        std::string path() const                        {return asString(CBLDatabase_Path(ref()));}
        
        /** Returns the database's configuration, as given when it was opened. */
        CBLDatabaseConfiguration config() const         {return CBLDatabase_Config(ref());}

        // Collections:
        
        /** Returns the names of all existing scopes in the database.
            The scope exists when there is at least one collection created under the scope.
            @note The default scope will always exist, containing at least the default collection.
            @return The names of all existing scopes in the database, or throws if an error occurred. */
        fleece::MutableArray getScopeNames() const {
            CBLError error {};
            FLMutableArray flNames = CBLDatabase_ScopeNames(ref(), &error);
            check(flNames, error);
            fleece::MutableArray names(flNames);
            FLMutableArray_Release(flNames);
            return names;
        }
        
        /** Returns the names of all collections in the scope.
            @param scopeName  The name of the scope.
            @return The names of all collections in the scope, or throws if an error occurred. */
        fleece::MutableArray getCollectionNames(slice scopeName =kCBLDefaultScopeName) const {
            CBLError error {};
            FLMutableArray flNames = CBLDatabase_CollectionNames(ref(), scopeName, &error);
            check(flNames, error);
            fleece::MutableArray names(flNames);
            FLMutableArray_Release(flNames);
            return names;
        }
        
        /** Returns the existing collection with the given name and scope.
            @param collectionName  The name of the collection.
            @param scopeName  The name of the scope.
            @return A \ref Collection instance, or NULL if the collection doesn't exist, or throws if an error occurred. */
        inline Collection getCollection(slice collectionName, slice scopeName =kCBLDefaultScopeName) const;
        
        /** Create a new collection.
            The naming rules of the collections and scopes are as follows:
                - Must be between 1 and 251 characters in length.
                - Can only contain the characters A-Z, a-z, 0-9, and the symbols _, -, and %.
                - Cannot start with _ or %.
                - Both scope and collection names are case sensitive.
            @note If the collection already exists, the existing collection will be returned.
            @param collectionName  The name of the collection.
            @param scopeName  The name of the scope.
            @return A \ref Collection instance, or throws if an error occurred. */
        inline Collection createCollection(slice collectionName, slice scopeName =kCBLDefaultScopeName);
        
        /** Delete an existing collection.
            @note The default collection cannot be deleted.
            @param collectionName  The name of the collection.
            @param scopeName  The name of the scope. */
        inline void deleteCollection(slice collectionName, slice scopeName =kCBLDefaultScopeName) {
            CBLError error {};
            check(CBLDatabase_DeleteCollection(ref(), collectionName, scopeName, &error), error);
        }
        
        /** Returns the default collection. */
        inline Collection getDefaultCollection() const;
        
        // Query:
        
        /** Creates a new query by compiling the input string.
            This is fast, but not instantaneous. If you need to run the same query many times, keep the
            \ref Query object around instead of compiling it each time. If you need to run related queries
            with only some values different, create one query with placeholder parameter(s), and substitute
            the desired value(s) with \ref Query::setParameters(fleece::Dict parameters) each time you run the query.
            @param language  The query language,
                    [JSON](https://github.com/couchbase/couchbase-lite-core/wiki/JSON-Query-Schema) or
                    [N1QL](https://docs.couchbase.com/server/4.0/n1ql/n1ql-language-reference/index.html).
            @param queryString  The query string.
            @return  The new query object. */
        inline Query createQuery(CBLQueryLanguage language, slice queryString);

        // Notifications:
        
        using NotificationsReadyCallback = std::function<void(Database)>;

        /** Switches the database to buffered-notification mode. Notifications for objects belonging
            to this database (documents, queries, replicators, and of course the database) will not be
            called immediately; your \ref NotificationsReadyCallback will be called instead.
            @param callback  The function to be called when a notification is available. */
        void bufferNotifications(NotificationsReadyCallback callback) {
            _notificationReadyCallbackAccess->setCallback(callback);
            CBLDatabase_BufferNotifications(ref(), [](void *context, CBLDatabase *db) {
                ((NotificationsReadyCallbackAccess*)context)->call(Database(db));
            }, _notificationReadyCallbackAccess.get());
        }

        /** Immediately issues all pending notifications for this database, by calling their listener callbacks. */
        void sendNotifications() {
            CBLDatabase_SendNotifications(ref());
        }
        
        // Destructors:
        
        ~Database() {
            clear();
        }
        
    protected:
        friend class Collection;
        friend class Scope;
        
        CBL_REFCOUNTED_WITHOUT_COPY_MOVE_BOILERPLATE(Database, RefCounted, CBLDatabase)

    private:
        void open(slice& name, const CBLDatabaseConfiguration* _cbl_nullable config) {
            CBLError error {};
            _ref = (CBLRefCounted*)CBLDatabase_Open(name, config, &error);
            check(_ref != nullptr, error);
            
            _notificationReadyCallbackAccess = std::make_shared<NotificationsReadyCallbackAccess>();
        }
        
        class NotificationsReadyCallbackAccess {
        public:
            void setCallback(NotificationsReadyCallback callback) {
                std::lock_guard<std::mutex> lock(_mutex);
                _callback = callback;
            }
            
            void call(Database db) {
                NotificationsReadyCallback callback;
                {
                    std::lock_guard<std::mutex> lock(_mutex);
                    callback = _callback;
                }
                if (callback)
                    callback(db);
            }
        private:
            std::mutex _mutex;
            NotificationsReadyCallback _callback {nullptr};
        };
        
        std::shared_ptr<NotificationsReadyCallbackAccess> _notificationReadyCallbackAccess;
        
    public:
        Database(const Database &other) noexcept
        :RefCounted(other)
        ,_notificationReadyCallbackAccess(other._notificationReadyCallbackAccess)
        { }
        
        Database(Database &&other) noexcept
        :RefCounted((RefCounted&&)other)
        ,_notificationReadyCallbackAccess(std::move(other._notificationReadyCallbackAccess))
        { }
        
        Database& operator=(const Database &other) noexcept {
            RefCounted::operator=(other);
            _notificationReadyCallbackAccess = other._notificationReadyCallbackAccess;
            return *this;
        }
        
        Database& operator=(Database &&other) noexcept {
            RefCounted::operator=((RefCounted&&)other);
            _notificationReadyCallbackAccess = std::move(other._notificationReadyCallbackAccess);
            return *this;
        }
        
        void clear() {
            // Reset _notificationReadyCallbackAccess the releasing the _ref to
            // ensure that CBLDatabase is deleted before _notificationReadyCallbackAccess.
            RefCounted::clear();
            _notificationReadyCallbackAccess.reset();
        }
    };


    /** A helper object for database transactions.
        A Transaction object should be declared as a local (auto) variable.
        You must explicitly call \ref commit to commit changes; if you don't, the transaction
        will abort when it goes out of scope. */
    class Transaction {
    public:
        /** Begins a batch operation on the database that will end when the Batch instance
            goes out of scope. */
        explicit Transaction(Database db)
        :Transaction(db.ref())
        { }

        explicit Transaction (CBLDatabase *db) {
            CBLError error;
            RefCounted::check(CBLDatabase_BeginTransaction(db, &error), error);
            _db = db;
        }

        /** Commits changes and ends the transaction. */
        void commit()   {end(true);}

        /** Ends the transaction, rolling back changes. */
        void abort()    {end(false);}

        ~Transaction()  {end(false);}

    private:
        void end(bool commit) {
            CBLDatabase *db = _db;
            if (db) {
                _db = nullptr;
                CBLError error;
                if (!CBLDatabase_EndTransaction(db, commit, &error)) {
                    // If an exception is thrown while a Batch is in scope, its destructor will
                    // call end(). If I'm in this situation I cannot throw another exception or
                    // the C++ runtime will abort the process. Detect this and just warn instead.
                    if (std::current_exception())
                        CBL_Log(kCBLLogDomainDatabase, kCBLLogWarning,
                                "Transaction::end failed, while handling an exception");
                    else
                        RefCounted::check(false, error);
                }
            }
        }

        CBLDatabase* _cbl_nullable _db = nullptr;
    };
}

CBL_ASSUME_NONNULL_END
