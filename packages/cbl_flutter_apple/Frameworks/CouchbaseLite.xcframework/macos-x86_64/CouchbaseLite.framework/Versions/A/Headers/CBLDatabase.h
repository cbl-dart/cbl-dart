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
#include "fleece/FLSlice.h"

#ifdef __cplusplus
extern "C" {
#endif

/** \defgroup database   Database
    @{
    A \ref CBLDatabase is both a filesystem object and a container for documents.
 */

#pragma mark - CONFIGURATION
/** \name  Database configuration
    @{ */

/** Flags for how to open a database. */
typedef CBL_OPTIONS(uint32_t, CBLDatabaseFlags) {
    kCBLDatabase_Create        = 1,  ///< Create the file if it doesn't exist
    kCBLDatabase_ReadOnly      = 2,  ///< Open file read-only
    kCBLDatabase_NoUpgrade     = 4,  ///< Disable upgrading an older-version database
};

/** Database encryption algorithms (available only in the Enterprise Edition). */
typedef CBL_ENUM(uint32_t, CBLEncryptionAlgorithm) {
    kCBLEncryptionNone = 0,      ///< No encryption (default)
#ifdef COUCHBASE_ENTERPRISE
    kCBLEncryptionAES256,        ///< AES with 256-bit key
#endif
};

/** Encryption key sizes (in bytes). */
typedef CBL_ENUM(uint64_t, CBLEncryptionKeySize) {
    kCBLEncryptionKeySizeAES256 = 32,     ///< Key size for \ref kCBLEncryptionAES256
};

/** Encryption key specified in a \ref CBLDatabaseConfiguration. */
typedef struct CBLEncryptionKey {
    CBLEncryptionAlgorithm algorithm;       ///< Encryption algorithm
    uint8_t bytes[32];                      ///< Raw key data
} CBLEncryptionKey;

/** Database configuration options. */
typedef struct {
    const char *directory;                  ///< The parent directory of the database
    CBLDatabaseFlags flags;                 ///< Options for opening the database
    CBLEncryptionKey* encryptionKey;        ///< The database's encryption key (if any)
} CBLDatabaseConfiguration;

typedef struct {
    FLString directory;                     ///< The parent directory of the database
    CBLDatabaseFlags flags;                 ///< Options for opening the database
    CBLEncryptionKey* encryptionKey;        ///< The database's encryption key (if any)
} CBLDatabaseConfiguration_s;


/** Returns the default database configuration. */
CBLDatabaseConfiguration CBLDatabaseConfiguration_Default(void);

CBLDatabaseConfiguration_s CBLDatabaseConfiguration_Default_s(void);

/** @} */



#pragma mark - FILE OPERATIONS
/** \name  Database file operations
    @{
    These functions operate on database files without opening them.
 */

/** Returns true if a database with the given name exists in the given directory.
    @param name  The database name (without the ".cblite2" extension.)
    @param inDirectory  The directory containing the database. If NULL, `name` must be an
                        absolute or relative path to the database. */
bool CBL_DatabaseExists(const char* _cbl_nonnull name, const char *inDirectory) CBLAPI;

bool CBL_DatabaseExists_s(FLString name, FLString inDirectory) CBLAPI;

/** Copies a database file to a new location, and assigns it a new internal UUID to distinguish
    it from the original database when replicating.
    @param fromPath  The full filesystem path to the original database (including extension).
    @param toName  The new database name (without the ".cblite2" extension.)
    @param config  The database configuration (directory and encryption option.) */
bool CBL_CopyDatabase(const char* _cbl_nonnull fromPath,
                      const char* _cbl_nonnull toName,
                      const CBLDatabaseConfiguration* config,
                      CBLError*) CBLAPI;

bool CBL_CopyDatabase_s(FLString fromPath,
                        FLString toName,
                        const CBLDatabaseConfiguration_s* config,
                        CBLError*) CBLAPI;

/** Deletes a database file. If the database file is open, an error is returned.
    @param name  The database name (without the ".cblite2" extension.)
    @param inDirectory  The directory containing the database. If NULL, `name` must be an
                        absolute or relative path to the database.
    @param outError  On return, will be set to the error that occurred, or a 0 code if no error.
     @return  True if the database was deleted, false if it doesn't exist or deletion failed.
                (You can tell the last two cases apart by looking at \p outError.)*/
bool CBL_DeleteDatabase(const char *name _cbl_nonnull,
                        const char *inDirectory,
                        CBLError *outError) CBLAPI;

bool CBL_DeleteDatabase_s(FLString name,
                          FLString inDirectory,
                          CBLError *outError) CBLAPI;

/** @} */



#pragma mark - LIFECYCLE
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
    @param error  On failure, the error will be written here.
    @return  The new database object, or NULL on failure. */
_cbl_warn_unused
CBLDatabase* CBLDatabase_Open(const char *name _cbl_nonnull,
                              const CBLDatabaseConfiguration* config,
                              CBLError* error) CBLAPI;

_cbl_warn_unused
CBLDatabase* CBLDatabase_Open_s(FLSlice name,
                                const CBLDatabaseConfiguration_s* config,
                                CBLError* error) CBLAPI;

/** Closes an open database. */
bool CBLDatabase_Close(CBLDatabase*, CBLError*) CBLAPI;

CBL_REFCOUNTED(CBLDatabase*, Database);

/** Closes and deletes a database. If there are any other connections to the database,
    an error is returned. */
bool CBLDatabase_Delete(CBLDatabase* _cbl_nonnull, CBLError*) CBLAPI;

/** Compacts a database file. */
bool CBLDatabase_Compact(CBLDatabase* _cbl_nonnull, CBLError*) CBLAPI;

/** Begins a batch operation, similar to a transaction. You **must** later call \ref
    CBLDatabase_EndBatch to end (commit) the batch.
    @note  Multiple writes are much faster when grouped inside a single batch.
    @note  Changes will not be visible to other CBLDatabase instances on the same database until
            the batch operation ends.
    @note  Batch operations can nest. Changes are not committed until the outer batch ends. */
bool CBLDatabase_BeginBatch(CBLDatabase* _cbl_nonnull, CBLError*) CBLAPI;

/** Ends a batch operation. This **must** be called after \ref CBLDatabase_BeginBatch. */
bool CBLDatabase_EndBatch(CBLDatabase* _cbl_nonnull, CBLError*) CBLAPI;

#ifdef COUCHBASE_ENTERPRISE
/** Encrypts or decrypts a database, or changes its encryption key.

    If \p newKey is NULL, or its \p algorithm is \ref kCBLEncryptionNone, the database will be decrypted.
    Otherwise the database will be encrypted with that key; if it was already encrypted, it will be
    re-encrypted with the new key.*/
bool CBLDatabase_Rekey(CBLDatabase* _cbl_nonnull,
                       const CBLEncryptionKey *newKey,
                       CBLError* outError) CBLAPI;
#endif

/** @} */



#pragma mark - ACCESSORS
/** \name  Database accessors
    @{
    Getting information about a database.
 */

/** Returns the database's name. */
const char* CBLDatabase_Name(const CBLDatabase* _cbl_nonnull) CBLAPI _cbl_returns_nonnull;

/** Returns the database's full filesystem path. */
const char* CBLDatabase_Path(const CBLDatabase* _cbl_nonnull) CBLAPI _cbl_returns_nonnull;

/** Returns the number of documents in the database. */
uint64_t CBLDatabase_Count(const CBLDatabase* _cbl_nonnull) CBLAPI;

/** Returns the database's configuration, as given when it was opened.
    @note  The encryption key is not filled in, for security reasons. */
const CBLDatabaseConfiguration CBLDatabase_Config(const CBLDatabase* _cbl_nonnull) CBLAPI;

/** @} */



#pragma mark - LISTENERS
/** \name  Database listeners
    @{
    A database change listener lets you detect changes made to all documents in a database.
    (If you only want to observe specific documents, use a \ref CBLDocumentChangeListener instead.)
    @note If there are multiple \ref CBLDatabase instances on the same database file, each one's
    listeners will be notified of changes made by other database instances.
    @warning  Changes made to the database file by other processes will _not_ be notified. */

/** A database change listener callback, invoked after one or more documents are changed on disk.
    @warning  By default, this listener may be called on arbitrary threads. If your code isn't
                    prepared for that, you may want to use \ref CBLDatabase_BufferNotifications
                    so that listeners will be called in a safe context.
    @param context  An arbitrary value given when the callback was registered.
    @param db  The database that changed.
    @param numDocs  The number of documents that changed (size of the `docIDs` array)
    @param docIDs  The IDs of the documents that changed, as a C array of `numDocs` C strings. */
    typedef void (*CBLDatabaseChangeListener)(void *context,
                                              const CBLDatabase* db _cbl_nonnull,
                                              unsigned numDocs,
                                              const char **docIDs _cbl_nonnull);

/** Registers a database change listener callback. It will be called after one or more
    documents are changed on disk.
    @param db  The database to observe.
    @param listener  The callback to be invoked.
    @param context  An opaque value that will be passed to the callback.
    @return  A token to be passed to \ref CBLListener_Remove when it's time to remove the
            listener.*/
_cbl_warn_unused
CBLListenerToken* CBLDatabase_AddChangeListener(const CBLDatabase* db _cbl_nonnull,
                                                CBLDatabaseChangeListener listener _cbl_nonnull,
                                                void *context) CBLAPI;

/** @} */
/** @} */    // end of outer \defgroup



#pragma mark - NOTIFICATION SCHEDULING
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
typedef void (*CBLNotificationsReadyCallback)(void *context,
                                              CBLDatabase* db _cbl_nonnull);

/** Switches the database to buffered-notification mode. Notifications for objects belonging
    to this database (documents, queries, replicators, and of course the database) will not be
    called immediately; your \ref CBLNotificationsReadyCallback will be called instead.
    @param db  The database whose notifications are to be buffered.
    @param callback  The function to be called when a notification is available.
    @param context  An arbitrary value that will be passed to the callback. */
void CBLDatabase_BufferNotifications(CBLDatabase *db _cbl_nonnull,
                                     CBLNotificationsReadyCallback callback _cbl_nonnull,
                                     void *context) CBLAPI;

/** Immediately issues all pending notifications for this database, by calling their listener
    callbacks. */
void CBLDatabase_SendNotifications(CBLDatabase *db _cbl_nonnull) CBLAPI;
                                     
/** @} */
/** @} */    // end of outer \defgroup

#ifdef __cplusplus
}
#endif
