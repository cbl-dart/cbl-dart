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
#include "fleece/Fleece.hh"
#include "fleece/Mutable.hh"
#include <exception>
#include <functional>
#include <mutex>
#include <optional>
#include <string>
#include <string_view>
#include <vector>


CBL_ASSUME_NONNULL_BEGIN

namespace cbl {
    class Blob;
    class Collection;
    class Document;
    class MutableDocument;
    class Query;

    /** Conflict handler used when saving a document. */
    using ConflictHandler = std::function<bool(MutableDocument documentBeingSaved,
                                               Document conflictingDocument)>;

    
#ifdef COUCHBASE_ENTERPRISE
    /** Manages Couchbase Lite extensions, such as the Vector Search extension.
        \note ENTERPRISE EDITION ONLY */
    class Extension {
    public:
        /** Enables Vector Search extension by specifying the extension path to search for the Vector Search extension library.
            This function must be called before opening a database that intends to use the vector search extension.
            @param path The file system path of the directory that contains the Vector Search extension library.
            @note Must be called before opening a database that intends to use the vector search extension. */
        static void enableVectorSearch(std::string_view path) {
            CBLError error {};
            internal::check(CBL_EnableVectorSearch(slice(path), &error), error);
        }
    };

    /** Alias for the C \ref CBLEncryptionAlgorithm enum identifying an encryption algorithm. */
    using EncryptionAlgorithm = CBLEncryptionAlgorithm;
    /** Alias for the C \ref CBLEncryptionKeySize enum giving the required key size for an algorithm. */
    using EncryptionKeySize   = CBLEncryptionKeySize;

    /** A database encryption key, used in \ref DatabaseConfiguration to open or create an
        encrypted database.
        \note ENTERPRISE EDITION ONLY */
    class EncryptionKey : public CBLEncryptionKey {
    public:
        /** Creates an empty key (algorithm \ref kCBLEncryptionNone, i.e. no encryption). */
        EncryptionKey()
        : CBLEncryptionKey()
        {}

        /** Creates a key from an existing C \ref CBLEncryptionKey.
            @param k  The C encryption key to copy. */
        EncryptionKey(const CBLEncryptionKey& k)
        : CBLEncryptionKey(k)
        {}

        /** Derives an AES-256 key from a password.
            @param password  The password to derive the key from.
            @param old  If true, uses the legacy (SHA-1-based) derivation; otherwise uses the
                        current (SHA-256-based) derivation. Pass true only to open databases
                        created with the older algorithm. */
        EncryptionKey(std::string_view password, bool old = false) {
            if ( old ) CBLEncryptionKey_FromPasswordOld(this, slice(password));
            else CBLEncryptionKey_FromPassword(this, slice(password));
        }

        /** Assigns from an existing C \ref CBLEncryptionKey. */
        EncryptionKey& operator=(const CBLEncryptionKey& k) {
            CBLEncryptionKey::operator=(k);
            return *this;
        }
    };

#endif

    /** Database configuration options. */
    class DatabaseConfiguration {
    public:
        std::string      directory;      ///< The parent directory of the database
    #ifdef COUCHBASE_ENTERPRISE
        EncryptionKey encryptionKey;     ///< The database's encryption key (if any)
    #endif
        /** As Couchbase Lite normally configures its databases, There is a very
            small (though non-zero) chance that a power failure at just the wrong
            time could cause the most recently committed transaction's changes to
            be lost. This would cause the database to appear as it did immediately
            before that transaction.

            Setting this mode true ensures that an operating system crash or
            power failure will not cause the loss of any data.  FULL synchronous
            is very safe but it is also dramatically slower. */
        bool fullSync{false};

        /** Constructs a configuration from a C \ref CBLDatabaseConfiguration, copying the
            directory and (in EE) encryption key out of it.
            @param cblConfig  The C configuration to copy from. */
        DatabaseConfiguration(const CBLDatabaseConfiguration& cblConfig) {
            directory = ((slice)cblConfig.directory).asString();
#ifdef COUCHBASE_ENTERPRISE
            encryptionKey = cblConfig.encryptionKey;
#endif
            fullSync = cblConfig.fullSync;
        }

        /** Default constructor: empty directory, no encryption, full-sync off. */
        DatabaseConfiguration() = default;

        /** Returns a configuration initialized with the default settings (default directory,
            no encryption, full-sync off). */
        static DatabaseConfiguration defaultConfiguration() {
            return CBLDatabaseConfiguration_Default();
        }
    };

    /** A Couchbase Lite database, which is a container for collections of documents. */
    class Database : private RefCounted {
    public:
        // Static database-file operations:

        /** Returns true if a database with the given name exists in the given directory.
            @param name  The database name (without the ".cblite2" extension.)
            @param inDirectory  The directory containing the database. If not provided, `name` must be an
                absolute or relative path to the database. */
        static bool exists(std::string_view name, std::optional<std::string_view> inDirectory=std::nullopt) {
            slice inDir;
            if ( inDirectory ) inDir = slice(*inDirectory);
            return CBL_DatabaseExists(slice(name), inDir);
        }

        /** Copies a database file to a new location, and assigns it a new internal UUID to distinguish
            it from the original database when replicating.
            @param fromPath  The full filesystem path to the original database (including extension).
            @param toName  The new database name (without the ".cblite2" extension.) */
        static void copyDatabase(std::string_view fromPath,
                                 std::string_view toName)
        {
            CBLError error;
            internal::check( CBL_CopyDatabase(slice(fromPath), slice(toName),
                                              nullptr, &error), error );
        }

        /** Copies a database file to a new location, and assigns it a new internal UUID to distinguish
            it from the original database when replicating.
            @param fromPath  The full filesystem path to the original database (including extension).
            @param toName  The new database name (without the ".cblite2" extension.)
            @param config  The database configuration (directory and encryption option.) */
        static void copyDatabase(std::string_view fromPath,
                                 std::string_view toName,
                                 const DatabaseConfiguration& config)
        {
            CBLError error;
            CBLDatabaseConfiguration cblConfig{
                (slice)config.directory,
#ifdef COUCHBASE_ENTERPRISE
                config.encryptionKey,
#endif
                config.fullSync
            };
            internal::check( CBL_CopyDatabase(slice(fromPath), slice(toName),
                                              &cblConfig, &error), error );
        }

        /** Deletes a database file. If the database file is open, an error will be thrown.
            @param name  The database name (without the ".cblite2" extension.)
            @param inDirectory  The directory containing the database(optional), If not provided, `name` must be an
                absolute or relative path to the database. */
        static void deleteDatabase(std::string_view name, std::optional<std::string_view> inDirectory =std::nullopt) {
            CBLError error;
            slice inDir;
            if ( inDirectory ) inDir = slice(*inDirectory);
            if (!CBL_DeleteDatabase(slice(name), inDir, &error) && error.code != 0)
                internal::check(false, error);
        }

        // Lifecycle:

        /** Opens a database, or creates it if it doesn't exist yet, returning a new \ref Database instance.
            It's OK to open the same database file multiple times. Each \ref Database instance is
            independent of the others (and must be separately closed and released.)
            @param name  The database name (without the ".cblite2" extension.) */
        Database(std::string_view name) {
            open(name, nullptr);
        }

        /** Opens a database, or creates it if it doesn't exist yet, returning a new \ref Database instance.
            It's OK to open the same database file multiple times. Each \ref Database instance is
            independent of the others (and must be separately closed and released.)
            @param name  The database name (without the ".cblite2" extension.)
            @param config  The database configuration (directory and encryption option.) */
        Database(std::string_view name,
                 const DatabaseConfiguration& config)
        {
            CBLDatabaseConfiguration cblConfig{
                (slice)config.directory,
#ifdef COUCHBASE_ENTERPRISE
                config.encryptionKey,
#endif
                config.fullSync
            };
            open(name, &cblConfig);
        }

        /** Closes an open database. */
        void close() {
            CBLError error;
            internal::check(CBLDatabase_Close(ref(), &error), error);
        }

        /** Closes and deletes a database. */
        void deleteDatabase() {
            CBLError error;
            internal::check(CBLDatabase_Delete(ref(), &error), error);
        }
        
        /** Performs database maintenance.
            @param type  The database maintenance type. */
        void performMaintenance(CBLMaintenanceType type) {
            CBLError error;
            internal::check(CBLDatabase_PerformMaintenance(ref(), type, &error), error);
        }

#ifdef COUCHBASE_ENTERPRISE
        /** Encrypts or decrypts a database, or changes its encryption key.

            If \p newKey is NULL, or its \p algorithm is \ref kCBLEncryptionNone, the database will be decrypted.
            Otherwise the database will be encrypted with that key; if it was already encrypted, it will be
            re-encrypted with the new key. */
        void changeEncryptionKey(const EncryptionKey* _cbl_nullable newKey) {
            CBLError error{};
            internal::check(CBLDatabase_ChangeEncryptionKey(ref(), newKey, &error), error);
        }
#endif

        // Accessors:
        
        /** Returns the database's name. */
        std::string name() const                        {return internal::asString(CBLDatabase_Name(ref()));}
        
        /** Returns the database's full filesystem path, or an empty string if the database is closed or deleted. */
        std::string path() const                        {return internal::asString(CBLDatabase_Path(ref()));}
        
        /** Returns the database's configuration, as given when it was opened. */
        DatabaseConfiguration config() const            {return CBLDatabase_Config(ref());}

        /** Get a \ref Blob from the database using the \ref Blob properties.

            The \ref Blob properties is a blob's metadata containing two required fields
            which are a special marker property `"@type":"blob"`, and property `digest` whose value
            is a hex SHA-1 digest of the blob's data. The other optional properties are `length` and
            `content_type`. To obtain the \ref Blob properties from a \ref Blob,
            call \ref Blob::properties function.

            @param properties   The properties for getting the \ref Blob object.
            @return  The \ref Blob, or a falsy Blob if no blob with the given digest exists.
            @throws cbl::Error  On a database error (such as malformed blob properties). Note a
                    non-existent blob is not an error — that returns a falsy Blob rather than throwing. */
        inline Blob getBlob(fleece::Dict properties) const;

        /** Save a new \ref Blob object into the database without associating it with
            any documents. The properties of the saved \ref Blob object will include
            information necessary for referencing the \ref Blob object in the properties
            of the document to be saved into the database.

            Normally you do not need to use this function unless you are in the situation
            (e.g. developing javascript binding) that you cannot retain the \ref CBLBlob
            object until the document containing the \ref CBLBlob object is successfully
            saved into the database.
            \note The saved \ref Blob objects that are not associated with any documents
                  will be removed from the database when compacting the database.
            @param blob The Blob to save. */
        inline void saveBlob(const Blob& blob);

        // Collections:
        
        /** Returns the names of all existing scopes in the database.
            The scope exists when there is at least one collection created under the scope.
            @note The default scope will always exist, containing at least the default collection.
            @return The names of all existing scopes in the database, or throws if an error occurred. */
        fleece::MutableArray getScopeNames() const {
            CBLError error {};
            FLMutableArray flNames = CBLDatabase_ScopeNames(ref(), &error);
            internal::check(error.code == 0, error);
            fleece::MutableArray names(flNames);
            FLMutableArray_Release(flNames);
            return names;
        }
        
        /** Returns the names of all collections in the scope.
            @param scopeName  The name of the scope.
            @return The names of all collections in the scope, or throws if an error occurred. */
        fleece::MutableArray getCollectionNames(std::string_view scopeName = (std::string_view)slice(kCBLDefaultScopeName)) const {
            CBLError error {};
            FLMutableArray flNames = CBLDatabase_CollectionNames(ref(), slice(scopeName), &error);
            internal::check(error.code == 0, error);
            fleece::MutableArray names(flNames);
            FLMutableArray_Release(flNames);
            return names;
        }
        
        /** Returns the existing collection with the given name and scope.
            @param collectionName  The name of the collection.
            @param scopeName  The name of the scope (optional). If not supplied, the default scope name will be used.
            @return The \ref Collection, or a falsy Collection if it doesn't exist.
            @throws cbl::Error  On a database error. Note a non-existent collection is not an
                    error — that returns a falsy Collection rather than throwing. */
        inline Collection getCollection(std::string_view collectionName, std::optional<std::string_view> scopeName = std::nullopt) const;

        /** Create a new collection.
            The naming rules of the collections and scopes are as follows:
                - Must be between 1 and 251 characters in length.
                - Can only contain the characters A-Z, a-z, 0-9, and the symbols _, -, and %.
                - Cannot start with _ or %.
                - Both scope and collection names are case sensitive.
            @note If the collection already exists, the existing collection will be returned.
            @param collectionName  The name of the collection.
            @param scopeName  The name of the scope (optional).  If not supplied, the default scope name will be used.
            @return A \ref Collection instance. */
        inline Collection createCollection(std::string_view collectionName, std::optional<std::string_view> scopeName =std::nullopt);
        
        /** Delete an existing collection.
            @note The default collection cannot be deleted.
            @param collectionName  The name of the collection.
            @param scopeName  The name of the scope (optional). If not supplied, the default scope name will be used. */
        void deleteCollection(std::string_view collectionName, std::optional<std::string_view> scopeName =std::nullopt) {
            CBLError error {};
            slice sname = scopeName.value_or(slice(kCBLDefaultScopeName));
            if ( scopeName ) sname = *scopeName;
            internal::check(CBLDatabase_DeleteCollection(ref(), slice(collectionName), sname, &error), error);
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
        inline Query createQuery(QueryLanguage language, std::string_view queryString);

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

        /** Releases the underlying database handle. The database remains open if other
            \ref Database references to it exist. */
        ~Database() {
            clear();
        }
        
    protected:
        friend class Collection;
        friend class Scope;
        
        CBL_REFCOUNTED_WITHOUT_COPY_MOVE_BOILERPLATE(Database, RefCounted, CBLDatabase)

    private:
        void open(std::string_view name, const CBLDatabaseConfiguration* _cbl_nullable config) {
            CBLError error {};
            _ref = (CBLRefCounted*)CBLDatabase_Open(slice(name), config, &error);
            internal::check(_ref != nullptr, error);
            
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
        /** Copy constructor. Both `*this` and `other` refer to the same underlying
            \ref CBLDatabase handle (its refcount is incremented) and share the
            buffered-notification callback state. */
        Database(const Database &other) noexcept
        :RefCounted(other)
        ,_notificationReadyCallbackAccess(other._notificationReadyCallbackAccess)
        { }

        /** Move constructor. Takes over `other`'s \ref CBLDatabase handle and
            buffered-notification callback state, leaving `other` empty. */
        Database(Database &&other) noexcept
        :RefCounted((RefCounted&&)other)
        ,_notificationReadyCallbackAccess(std::move(other._notificationReadyCallbackAccess))
        { }

        /** Copy assignment. Releases the currently-referenced handle (if any), then
            makes `*this` refer to the same \ref CBLDatabase as `other` (refcount
            incremented) and share its buffered-notification callback state. */
        Database& operator=(const Database &other) noexcept {
            RefCounted::operator=(other);
            _notificationReadyCallbackAccess = other._notificationReadyCallbackAccess;
            return *this;
        }

        /** Move assignment. Releases the currently-referenced handle (if any), then
            takes over `other`'s \ref CBLDatabase handle and buffered-notification
            callback state; `other` is left empty. */
        Database& operator=(Database &&other) noexcept {
            RefCounted::operator=((RefCounted&&)other);
            _notificationReadyCallbackAccess = std::move(other._notificationReadyCallbackAccess);
            return *this;
        }
        
        /** Releases the underlying C \ref CBLDatabase handle and drops the buffered-notification
            callback. After this call the object is empty (its `operator bool` returns false).
            @note Other \ref Database references to the same database file remain valid. */
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

        /** Begins a batch operation on the given C database handle. Provided for callers
            that hold a raw \ref CBLDatabase pointer rather than a C++ \ref Database wrapper.
            @param db  The database to begin a transaction on. */
        explicit Transaction (CBLDatabase *db) {
            CBLError error{};
            internal::check(CBLDatabase_BeginTransaction(db, &error), error);
            _db = db;
        }

        /** Commits changes and ends the transaction. */
        void commit()   {end(true);}

        /** Ends the transaction, rolling back changes. */
        void abort()    {end(false);}

        /** Ends the transaction, rolling back any changes that have not been committed. */
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
                        internal::check(false, error);
                }
            }
        }

        CBLDatabase* _cbl_nullable _db = nullptr;
    };
}

CBL_ASSUME_NONNULL_END
