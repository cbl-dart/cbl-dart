//
// CBLDatabase.h
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
#include "CBLQueryIndexTypes.h"

CBL_CAPI_BEGIN

/** \defgroup database   Database
    @{
    A \ref CBLDatabase is both a filesystem object and a container for documents.
 */

#ifdef COUCHBASE_ENTERPRISE

#ifdef __APPLE__
#pragma mark - Database Extension
#endif

/** \name  Database Extension
    @{ */

/** ENTERPRISE EDITION ONLY
  
    Enables Vector Search extension by specifying the extension path to search for the Vector Search extension library.
    This function must be called before opening a database that intends to use the vector search extension.
    @param path The file system path of the directory that contains the Vector Search extension library.
    @param outError  On return, will be set to the error that occurred.
    @return  True on success, false if there was an error.
    @note Must be called before opening a database that intends to use the vector search extension. */
bool CBL_EnableVectorSearch(FLString path, CBLError* _cbl_nullable outError) CBLAPI;

/** @} */

#endif

#ifdef __APPLE__
#pragma mark - CONFIGURATION
#endif

/** \name  Database configuration
    @{ */

#ifdef COUCHBASE_ENTERPRISE
/** Database encryption algorithms (available only in the Enterprise Edition). */
typedef CBL_ENUM(uint32_t, CBLEncryptionAlgorithm) {
    kCBLEncryptionNone = 0,         ///< No encryption (default)
    kCBLEncryptionAES256            ///< AES with 256-bit key
};

/** Encryption key sizes (in bytes). */
typedef CBL_ENUM(uint64_t, CBLEncryptionKeySize) {
    kCBLEncryptionKeySizeAES256 = 32,     ///< Key size for \ref kCBLEncryptionAES256
};

/** Encryption key specified in a \ref CBLDatabaseConfiguration. */
typedef struct {
    CBLEncryptionAlgorithm algorithm;       ///< Encryption algorithm
    uint8_t bytes[32];                      ///< Raw key data
} CBLEncryptionKey;
#endif

/** Database configuration options. */
typedef struct {
    FLString directory;                 ///< The parent directory of the database
#ifdef COUCHBASE_ENTERPRISE
    CBLEncryptionKey encryptionKey;     ///< The database's encryption key (if any)
#endif
    /** As Couchbase Lite normally configures its databases, There is a very
        small (though non-zero) chance that a power failure at just the wrong
        time could cause the most recently committed transaction's changes to
        be lost. This would cause the database to appear as it did immediately
        before that transaction.
     
        Setting this mode true ensures that an operating system crash or
        power failure will not cause the loss of any data.  FULL synchronous
        is very safe but it is also dramatically slower. */
    bool fullSync;
    
    /**
     Disable memory-mapped I/O. By default, memory-mapped I/O is enabled.
     Disabling it may affect database performance. Typically, there is no need to modify this setting.
     @note Memory-mapped I/O is always disabled on macOS to prevent database corruption,
           so setting mmapDisabled value has no effect on the macOS platform. */
    bool mmapDisabled;
} CBLDatabaseConfiguration;

/** Returns the default database configuration. */
CBLDatabaseConfiguration CBLDatabaseConfiguration_Default(void) CBLAPI;

#ifdef COUCHBASE_ENTERPRISE
/** Derives an encryption key from a password. If your UI uses passwords, call this function to
    create the key used to encrypt the database. It is designed for security, and deliberately
    runs slowly to make brute-force attacks impractical.
    @param key  The derived AES key will be stored here.
    @param password  The input password, which can be any data.
    @return  True on success, false if there was a problem deriving the key. */
bool CBLEncryptionKey_FromPassword(CBLEncryptionKey *key, FLString password) CBLAPI;

/** VOLATILE API: Derives an encryption key from a password in a way that is
    compatible with certain variants of Couchbase Lite in which a slightly different
    hashing algorithm is used.  The same notes apply as in CBLEncryptionKey_FromPassword
    @param key  The derived AES key will be stored here.
    @param password  The input password, which can be any data.
    @return  True on success, false if there was a problem deriving the key. */
bool CBLEncryptionKey_FromPasswordOld(CBLEncryptionKey *key, FLString password) CBLAPI;
#endif

/** @} */


#ifdef __APPLE__
#pragma mark - FILE OPERATIONS
#endif
/** \name  Database file operations
    @{
    These functions operate on database files without opening them.
 */

/** Returns true if a database with the given name exists in the given directory.
    @param name  The database name (without the ".cblite2" extension.)
    @param inDirectory  The directory containing the database. If NULL, `name` must be an
                        absolute or relative path to the database. */
bool CBL_DatabaseExists(FLString name, FLString inDirectory) CBLAPI;

/** Copies a database file to a new location, and assigns it a new internal UUID to distinguish
    it from the original database when replicating.
    @param fromPath  The full filesystem path to the original database (including extension).
    @param toName  The new database name (without the ".cblite2" extension.)
    @param config  The database configuration (directory and encryption option.)
    @param outError  On return, will be set to the error that occurred, if applicable.
    @note While a database is open, one or more of its files may be in use.  Attempting to copy a file, while it is in use, will fail.  We recommend that you close a database before attempting to copy it. */
bool CBL_CopyDatabase(FLString fromPath,
                      FLString toName,
                      const CBLDatabaseConfiguration* _cbl_nullable config,
                      CBLError* _cbl_nullable outError) CBLAPI;

/** Deletes a database file. If the database file is open, an error is returned.
    @param name  The database name (without the ".cblite2" extension.)
    @param inDirectory  The directory containing the database. If NULL, `name` must be an
                        absolute or relative path to the database.
    @param outError  On return, will be set to the error that occurred, or a 0 code if no error.
    @return  True if the database was deleted, false if it doesn't exist or deletion failed.
                (You can tell the last two cases apart by looking at \p outError.)*/
bool CBL_DeleteDatabase(FLString name,
                        FLString inDirectory,
                        CBLError* _cbl_nullable outError) CBLAPI;

/** @} */


#ifdef __APPLE__
#pragma mark - LIFECYCLE
#endif
/** \name  Database lifecycle
    @{
    Opening, closing, and managing open databases.
 */

/** Opens a database, or creates it if it doesn't exist yet, returning a new \ref CBLDatabase
    instance.
    It's OK to open the same database file multiple times. Each \ref CBLDatabase instance is
    independent of the others (and must be separately closed and released.)
    @param name  The database name (without the ".cblite2" extension.)
    @param config  The database configuration (directory and encryption option.)
    @param outError  On failure, the error will be written here.
    @return  The new database object, or NULL on failure. */
_cbl_warn_unused
CBLDatabase* _cbl_nullable CBLDatabase_Open(FLSlice name,
                                            const CBLDatabaseConfiguration* _cbl_nullable config,
                                            CBLError* _cbl_nullable outError) CBLAPI;

/** Closes an open database. */
bool CBLDatabase_Close(CBLDatabase*,
                       CBLError* _cbl_nullable outError) CBLAPI;

CBL_REFCOUNTED(CBLDatabase*, Database);

/** Closes and deletes a database. If there are any other connections to the database,
    an error is returned. */
bool CBLDatabase_Delete(CBLDatabase*,
                        CBLError* _cbl_nullable outError) CBLAPI;

/** Begins a transaction. You **must** later call \ref
    CBLDatabase_EndTransaction to commit or abort the transaction.
    @note  Multiple writes are much faster when grouped in a transaction.
    @note  Changes will not be visible to other CBLDatabase instances on the same database until
            the transaction ends.
    @note  Transactions can nest. Changes are not committed until the outer transaction ends. */
bool CBLDatabase_BeginTransaction(CBLDatabase*,
                                  CBLError* _cbl_nullable outError) CBLAPI;

/** Ends a transaction, either committing or aborting. */
bool CBLDatabase_EndTransaction(CBLDatabase*,
                                bool commit,
                                CBLError* _cbl_nullable outError) CBLAPI;

#ifdef COUCHBASE_ENTERPRISE
/** Encrypts or decrypts a database, or changes its encryption key.

    If \p newKey is NULL, or its \p algorithm is \ref kCBLEncryptionNone, the database will be decrypted.
    Otherwise the database will be encrypted with that key; if it was already encrypted, it will be
    re-encrypted with the new key.*/
bool CBLDatabase_ChangeEncryptionKey(CBLDatabase*,
                                     const CBLEncryptionKey* _cbl_nullable newKey,
                                     CBLError* outError) CBLAPI;
#endif

/** Maintenance Type used when performing database maintenance. */
typedef CBL_ENUM(uint32_t, CBLMaintenanceType) {
    /// Compact the database file and delete unused attachments
    kCBLMaintenanceTypeCompact = 0,
    
    /// Rebuild the entire database's indexes.
    kCBLMaintenanceTypeReindex,
    
    /// Check for the database’s corruption. If found, an error will be returned
    kCBLMaintenanceTypeIntegrityCheck,
    
    /// Partially scan indexes to gather database statistics that help optimize queries.
    /// This operation is also performed automatically when closing the database.
    kCBLMaintenanceTypeOptimize,
    
    /// Fully scans all indexes to gather database statistics that help optimize queries.
    /// This may take some time, depending on the size of the indexes, but it doesn't have to
    /// be redone unless the database changes drastically, or new indexes are created.
    kCBLMaintenanceTypeFullOptimize
};

/**  Performs database maintenance. */
bool CBLDatabase_PerformMaintenance(CBLDatabase* db,
                                    CBLMaintenanceType type,
                                    CBLError* _cbl_nullable outError) CBLAPI;

/** @} */

#ifdef __APPLE__
#pragma mark - ACCESSORS
#endif
/** \name  Database accessors
    @{
    Getting information about a database.
 */

/** Returns the database's name. */
FLString CBLDatabase_Name(const CBLDatabase*) CBLAPI;

/** Returns the database's full filesystem path, or null slice if the database is closed or deleted. */
_cbl_warn_unused
FLStringResult CBLDatabase_Path(const CBLDatabase*) CBLAPI;

/** Returns the number of documents in the database, or zero if the database is closed or deleted.
    @warning  <b>Deprecated :</b> Use CBLCollection_Count on the default collection instead. */
uint64_t CBLDatabase_Count(const CBLDatabase*) CBLAPI;

/** Returns the database's configuration, as given when it was opened. */
const CBLDatabaseConfiguration CBLDatabase_Config(const CBLDatabase*) CBLAPI;

/** @} */

/** \name  Query Indexes
    @{
    Query Index Management
 */

/** Creates a value index.
    Indexes are persistent.
    If an identical index with that name already exists, nothing happens (and no error is returned.)
    If a non-identical index with that name already exists, it is deleted and re-created.
    @warning  <b>Deprecated :</b> Use CBLCollection_CreateValueIndex on the default collection instead. */
bool CBLDatabase_CreateValueIndex(CBLDatabase *db,
                                  FLString name,
                                  CBLValueIndexConfiguration config,
                                  CBLError* _cbl_nullable outError) CBLAPI;

/** Creates a full-text index.
    Indexes are persistent.
    If an identical index with that name already exists, nothing happens (and no error is returned.)
    If a non-identical index with that name already exists, it is deleted and re-created.
    @warning  <b>Deprecated :</b> Use CBLCollection_CreateFullTextIndex on the default collection instead. */
bool CBLDatabase_CreateFullTextIndex(CBLDatabase *db,
                                     FLString name,
                                     CBLFullTextIndexConfiguration config,
                                     CBLError* _cbl_nullable outError) CBLAPI;

/** Deletes an index given its name.
    @warning  <b>Deprecated :</b> Use CBLCollection_DeleteIndex on the default collection instead. */
bool CBLDatabase_DeleteIndex(CBLDatabase *db,
                             FLString name,
                             CBLError* _cbl_nullable outError) CBLAPI;

/** Returns the names of the indexes on this database, as a Fleece array of strings.
    @note  You are responsible for releasing the returned Fleece array.
    @warning  <b>Deprecated :</b> Use CBLCollection_GetIndexNames on the default collection instead. */
_cbl_warn_unused
FLArray CBLDatabase_GetIndexNames(CBLDatabase *db) CBLAPI;


/** @} */

#ifdef __APPLE__
#pragma mark - LISTENERS
#endif
/** \name  Database listeners
    @{
    A database change listener lets you detect changes made to all documents in the default collection.
    (If you only want to observe specific documents, use a \ref CBLDocumentChangeListener instead.)
    @note If there are multiple \ref CBLDatabase instances on the same database file, each one's
    listeners will be notified of changes made by other database instances.
    @warning  Changes made to the database file by other processes will _not_ be notified. */

/** A default collection change listener callback, invoked after one or more documents in the default collection are changed on disk.
    @warning  By default, this listener may be called on arbitrary threads. If your code isn't
              prepared for that, you may want to use \ref CBLDatabase_BufferNotifications
              so that listeners will be called in a safe context.
    @warning  <b>Deprecated :</b> CBLCollectionChangeListener instead.
    @param context  An arbitrary value given when the callback was registered.
    @param db  The database that changed.
    @param numDocs  The number of documents that changed (size of the `docIDs` array)
    @param docIDs  The IDs of the documents that changed, as a C array of `numDocs` C strings. */
typedef void (*CBLDatabaseChangeListener)(void* _cbl_nullable context,
                                          const CBLDatabase* db,
                                          unsigned numDocs,
                                          FLString docIDs[_cbl_nonnull]);

/** Registers a default collection change listener callback. It will be called after one or more
    documents are changed on disk.
    @warning  <b>Deprecated :</b> Use CBLCollection_AddChangeListener on the default collection instead.
    @param db  The database to observe.
    @param listener  The callback to be invoked.
    @param context  An opaque value that will be passed to the callback.
    @return  A token to be passed to \ref CBLListener_Remove when it's time to remove the listener.*/
_cbl_warn_unused
CBLListenerToken* CBLDatabase_AddChangeListener(const CBLDatabase* db,
                                                CBLDatabaseChangeListener listener,
                                                void* _cbl_nullable context) CBLAPI;

/** @} */
/** @} */    // end of outer \defgroup


#ifdef __APPLE__
#pragma mark - NOTIFICATION SCHEDULING
#endif
/** \defgroup listeners   Listeners
    @{ */
/** \name  Scheduling notifications
    @{
    Applications may want control over when Couchbase Lite notifications (listener callbacks)
    happen. They may want them called on a specific thread, or at certain times during an event
    loop. This behavior may vary by database, if for instance each database is associated with a
    separate thread.

    The API calls here enable this. When notifications are "buffered" for a database, calls to
    listeners will be deferred until the application explicitly allows them. Instead, a single
    callback will be issued when the first notification becomes available; this gives the app a
    chance to schedule a time when the notifications should be sent and callbacks called.
 */

/** Callback indicating that the database (or an object belonging to it) is ready to call one
    or more listeners. You should call \ref CBLDatabase_SendNotifications at your earliest
    convenience, in the context (thread, dispatch queue, etc.) you want them to run.
    @note  This callback is called _only once_ until the next time \ref CBLDatabase_SendNotifications
            is called. If you don't respond by (sooner or later) calling that function,
            you will not be informed that any listeners are ready.
    @warning  This can be called from arbitrary threads. It should do as little work as
              possible, just scheduling a future call to \ref CBLDatabase_SendNotifications. */
typedef void (*CBLNotificationsReadyCallback)(void* _cbl_nullable context,
                                              CBLDatabase* db);

/** Switches the database to buffered-notification mode. Notifications for objects belonging
    to this database (documents, queries, replicators, and of course the database) will not be
    called immediately; your \ref CBLNotificationsReadyCallback will be called instead.
    @param db  The database whose notifications are to be buffered.
    @param callback  The function to be called when a notification is available.
    @param context  An arbitrary value that will be passed to the callback. */
void CBLDatabase_BufferNotifications(CBLDatabase *db,
                                     CBLNotificationsReadyCallback _cbl_nullable callback,
                                     void* _cbl_nullable context) CBLAPI;

/** Immediately issues all pending notifications for this database, by calling their listener
    callbacks. */
void CBLDatabase_SendNotifications(CBLDatabase *db) CBLAPI;
                                     
/** @} */
/** @} */    // end of outer \defgroup

CBL_CAPI_END
