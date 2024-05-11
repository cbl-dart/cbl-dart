//
// CBLDocument.h
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

CBL_CAPI_BEGIN

/** \defgroup documents   Documents
    @{
    A \ref CBLDocument is essentially a JSON object with an ID string that's unique in its database.
 */

CBL_PUBLIC extern const FLSlice kCBLTypeProperty;             ///< `"@type"`

/** \name  Document lifecycle
    @{ */

/** Conflict-handling options when saving or deleting a document. */
typedef CBL_ENUM(uint8_t, CBLConcurrencyControl) {
    /** The current save/delete will overwrite a conflicting revision if there is a conflict. */
    kCBLConcurrencyControlLastWriteWins,
    /** The current save/delete will fail if there is a conflict. */
    kCBLConcurrencyControlFailOnConflict
};


/** Custom conflict handler for use when saving or deleting a document. This handler is called
    if the save would cause a conflict, i.e. if the document in the database has been updated
    (probably by a pull replicator, or by application code on another thread)
    since it was loaded into the CBLDocument being saved.
    @param context  The value of the \p context parameter you passed to
                    \ref CBLDatabase_SaveDocumentWithConflictHandler.
    @param documentBeingSaved  The document being saved (same as the parameter you passed to
                    \ref CBLDatabase_SaveDocumentWithConflictHandler.) The callback may modify
                    this document's properties as necessary to resolve the conflict.
    @param conflictingDocument  The revision of the document currently in the database,
                    which has been changed since \p documentBeingSaved was loaded.
                    May be NULL, meaning that the document has been deleted.
    @return  True to save the document, false to abort the save. */
typedef bool (*CBLConflictHandler)(void* _cbl_nullable context,
                                   CBLDocument* _cbl_nullable documentBeingSaved,
                                   const CBLDocument* _cbl_nullable conflictingDocument);


/** Reads a document from the default collection in an immutable form.
    Each call to this function creates a new object (which must later be released.)
    @note  If you are reading the document in order to make changes to it, call
            \ref CBLDatabase_GetMutableDocument instead.
    @warning  <b>Deprecated :</b> Use CBLCollection_GetDocument on the default collection instead.
    @param database  The database.
    @param docID  The ID of the document.
    @param outError  On failure, the error will be written here. (A nonexistent document is not
                    considered a failure; in that event the error code will be zero.)
    @return  A new \ref CBLDocument instance, or NULL if the doc doesn't exist or an error occurred. */
_cbl_warn_unused
const CBLDocument* _cbl_nullable CBLDatabase_GetDocument(const CBLDatabase* database,
                                                         FLString docID,
                                                         CBLError* _cbl_nullable outError) CBLAPI;

CBL_REFCOUNTED(CBLDocument*, Document);

/** Saves a (mutable) document to the default collection.
    @warning If a newer revision has been saved since \p doc was loaded, it will be overwritten by
            this one. This can lead to data loss! To avoid this, call
            \ref CBLDatabase_SaveDocumentWithConcurrencyControl or
            \ref CBLDatabase_SaveDocumentWithConflictHandler instead.
    @warning  <b>Deprecated :</b> Use CBLCollection_SaveDocument on the default collection instead.
    @param db  The database.
    @param doc  The mutable document to save.
    @param outError  On failure, the error will be written here.
    @return  True on success, false on failure. */
bool CBLDatabase_SaveDocument(CBLDatabase* db,
                              CBLDocument* doc,
                              CBLError* _cbl_nullable outError) CBLAPI;

/** Saves a (mutable) document to the default collection.
    If a conflicting revision has been saved since \p doc was loaded, the \p concurrency
    parameter specifies whether the save should fail, or the conflicting revision should
    be overwritten with the revision being saved.
    If you need finer-grained control, call \ref CBLDatabase_SaveDocumentWithConflictHandler instead.
    @warning  <b>Deprecated :</b> Use CBLCollection_SaveDocumentWithConcurrencyControl on the default collection instead.
    @param db  The database.
    @param doc  The mutable document to save.
    @param concurrency  Conflict-handling strategy (fail or overwrite).
    @param outError  On failure, the error will be written here.
    @return  True on success, false on failure. */
bool CBLDatabase_SaveDocumentWithConcurrencyControl(CBLDatabase* db,
                                                    CBLDocument* doc,
                                                    CBLConcurrencyControl concurrency,
                                                    CBLError* _cbl_nullable outError) CBLAPI;

/** Saves a (mutable) document to the default collection, allowing for custom conflict handling in the event
    that the document has been updated since \p doc was loaded.
    @warning <b>Deprecated :</b> Use CBLCollection_SaveDocumentWithConflictHandler on the default collection instead.
    @param db  The database.
    @param doc  The mutable document to save.
    @param conflictHandler  The callback to be invoked if there is a conflict.
    @param context  An arbitrary value to be passed to the \p conflictHandler.
    @param outError  On failure, the error will be written here.
    @return  True on success, false on failure. */
bool CBLDatabase_SaveDocumentWithConflictHandler(CBLDatabase* db,
                                                 CBLDocument* doc,
                                                 CBLConflictHandler conflictHandler,
                                                 void* _cbl_nullable context,
                                                 CBLError* _cbl_nullable outError) CBLAPI;

/** Deletes a document from the default collection. Deletions are replicated.
    @warning  You are still responsible for releasing the CBLDocument.
    @warning  <b>Deprecated :</b> Use CBLCollection_DeleteDocument on the default collection instead.
    @param db  The database.
    @param document  The document to delete.
    @param outError  On failure, the error will be written here.
    @return  True if the document was deleted, false if an error occurred. */
bool CBLDatabase_DeleteDocument(CBLDatabase *db,
                                const CBLDocument* document,
                                CBLError* _cbl_nullable outError) CBLAPI;

/** Deletes a document from the default collection. Deletions are replicated.
    @warning  You are still responsible for releasing the CBLDocument.
    @warning  <b>Deprecated :</b> Use CBLCollection_DeleteDocumentWithConcurrencyControl on the default collection instead.
    @param db  The database.
    @param document  The document to delete.
    @param concurrency  Conflict-handling strategy.
    @param outError  On failure, the error will be written here.
    @return  True if the document was deleted, false if an error occurred. */
bool CBLDatabase_DeleteDocumentWithConcurrencyControl(CBLDatabase *db,
                                                      const CBLDocument* document,
                                                      CBLConcurrencyControl concurrency,
                                                      CBLError* _cbl_nullable outError) CBLAPI;

/** Purges a document from the default collection. This removes all traces of the document.
    Purges are _not_ replicated. If the document is changed on a server, it will be re-created
    when pulled.
    @warning  You are still responsible for releasing the \ref CBLDocument reference.
    @warning  <b>Deprecated :</b> Use CBLCollection_PurgeDocument on the default collection instead.
    @note If you don't have the document in memory already, \ref CBLDatabase_PurgeDocumentByID is a
          simpler shortcut.
    @param db  The database.
    @param document  The document to purge.
    @param outError  On failure, the error will be written here.
    @return  True if the document was purged, false if it doesn't exist or the purge failed. */
bool CBLDatabase_PurgeDocument(CBLDatabase* db,
                               const CBLDocument* document,
                               CBLError* _cbl_nullable outError) CBLAPI;

/** Purges a document by its ID from the default collection.
    @note  If no document with that ID exists, this function will return false but the error
            code will be zero.
    @warning  <b>Deprecated :</b> Use CBLCollection_PurgeDocumentByID on the default collection instead.
    @param database  The database.
    @param docID  The document ID to purge.
    @param outError  On failure, the error will be written here.
    @return  True if the document was purged, false if it doesn't exist or the purge failed. */
bool CBLDatabase_PurgeDocumentByID(CBLDatabase* database,
                                   FLString docID,
                                   CBLError* _cbl_nullable outError) CBLAPI;

/** @} */



/** \name  Mutable documents
    @{
    The type `CBLDocument*` without a `const` qualifier refers to a _mutable_ document instance.
    A mutable document exposes its properties as a mutable dictionary, so you can change them
    in place and then call \ref CBLDatabase_SaveDocument to persist the changes.
 */

/** Reads a document from the default collection in mutable form that can be updated and saved.
    (This function is otherwise identical to \ref CBLDatabase_GetDocument.)
    @note  You must release the document when you're done with it.
    @warning  <b>Deprecated :</b> Use CBLCollection_GetMutableDocument on the default collection instead.
    @param database  The database.
    @param docID  The ID of the document.
    @param outError  On failure, the error will be written here. (A nonexistent document is not
                    considered a failure; in that event the error code will be zero.)
    @return  A new \ref CBLDocument instance, or NULL if the doc doesn't exist or an error occurred. */
_cbl_warn_unused
CBLDocument* _cbl_nullable CBLDatabase_GetMutableDocument(CBLDatabase* database,
                                                          FLString docID,
                                                          CBLError* _cbl_nullable outError) CBLAPI;

/** Creates a new, empty document in memory, with a randomly-generated unique ID.
    It will not be added to a database until saved.
    @return  The new mutable document instance. */
_cbl_warn_unused
CBLDocument* CBLDocument_Create(void) CBLAPI;

/** Creates a new, empty document in memory, with the given ID.
    It will not be added to a database until saved.
    @note  If the given ID conflicts with a document already in the database, that will not
           be apparent until this document is saved. At that time, the result depends on the
           conflict handling mode used when saving; see the save functions for details.
    @param docID  The ID of the new document, or NULL to assign a new unique ID.
    @return  The new mutable document instance. */
_cbl_warn_unused
CBLDocument* CBLDocument_CreateWithID(FLString docID) CBLAPI;

/** Creates a new mutable CBLDocument instance that refers to the same document as the original.
    If the original document has unsaved changes, the new one will also start out with the same
    changes; but mutating one document thereafter will not affect the other.
    @note  You must release the new reference when you're done with it. Similarly, the original
           document still exists and must also be released when you're done with it.*/
_cbl_warn_unused
CBLDocument* CBLDocument_MutableCopy(const CBLDocument* original) CBLAPI;

/** @} */



/** \name  Document properties and metadata
    @{
    A document's body is essentially a JSON object. The properties are accessed in memory
    using the Fleece API, with the body itself being a \ref FLDict "dictionary").
 */

/** Returns a document's ID. */
FLString CBLDocument_ID(const CBLDocument*) CBLAPI;

/** Returns a document's revision ID, which is a short opaque string that's guaranteed to be
    unique to every change made to the document.
    If the document doesn't exist yet, this function returns NULL. */
FLString CBLDocument_RevisionID(const CBLDocument*) CBLAPI;

/** Returns a document's current sequence in the local database.
    This number increases every time the document is saved, and a more recently saved document
    will have a greater sequence number than one saved earlier, so sequences may be used as an
    abstract 'clock' to tell relative modification times. */
uint64_t CBLDocument_Sequence(const CBLDocument*) CBLAPI;

/** Returns a document's collection or NULL for the new document that hasn't been saved. */
CBLCollection* _cbl_nullable CBLDocument_Collection(const CBLDocument*) CBLAPI;

/** Returns a document's properties as a dictionary.
    @note  The dictionary object is owned by the document; you do not need to release it.
    @warning  When the document is released, this reference to the properties becomes invalid.
            If you need to use any properties after releasing the document, you must retain them
            by calling \ref FLValue_Retain (and of course later release them.)
    @warning  This dictionary _reference_ is immutable, but if the document is mutable the
           underlying dictionary itself is mutable and could be modified through a mutable
           reference obtained via \ref CBLDocument_MutableProperties. If you need to preserve the
           properties, call \ref FLDict_MutableCopy to make a deep copy. */
FLDict CBLDocument_Properties(const CBLDocument*) CBLAPI;

/** Returns a mutable document's properties as a mutable dictionary.
    You may modify this dictionary and then call \ref CBLDatabase_SaveDocument to persist the changes.
    @note  The dictionary object is owned by the document; you do not need to release it.
    @note  Every call to this function returns the same mutable collection. This is the
           same collection returned by \ref CBLDocument_Properties.
    @note  When accessing nested collections inside the properties as a mutable collection
           for modification, use \ref FLMutableDict_GetMutableDict or \ref FLMutableDict_GetMutableArray.
    @warning  When the document is released, this reference to the properties becomes invalid.
            If you need to use any properties after releasing the document, you must retain them
            by calling \ref FLValue_Retain (and of course later release them.) */
FLMutableDict CBLDocument_MutableProperties(CBLDocument*) CBLAPI;

/** Sets a mutable document's properties.
    Call \ref CBLDatabase_SaveDocument to persist the changes.
    @note  The dictionary object will be retained by the document. You are responsible for
           releasing any retained reference(s) you have to it. */
void CBLDocument_SetProperties(CBLDocument*,
                               FLMutableDict properties) CBLAPI;

/** Returns a document's properties as JSON.
    @note  You are responsible for releasing the result by calling \ref FLSliceResult_Release. */
_cbl_warn_unused
FLSliceResult CBLDocument_CreateJSON(const CBLDocument*) CBLAPI;

/** Sets a mutable document's properties from a JSON string. */
bool CBLDocument_SetJSON(CBLDocument*,
                         FLSlice json,
                         CBLError* _cbl_nullable outError) CBLAPI;

/** Returns the time, if any, at which a given document will expire and be purged.
    Documents don't normally expire; you have to call \ref CBLDatabase_SetDocumentExpiration
    to set a document's expiration time.
    @warning  <b>Deprecated :</b> Use CBLCollection_GetDocumentExpiration instead.
    @param db  The database.
    @param docID  The ID of the document.
    @param outError  On failure, an error is written here.
    @return  The expiration time as a CBLTimestamp (milliseconds since Unix epoch),
             or 0 if the document does not have an expiration,
             or -1 if the call failed. */
CBLTimestamp CBLDatabase_GetDocumentExpiration(CBLDatabase* db,
                                               FLSlice docID,
                                               CBLError* _cbl_nullable outError) CBLAPI;

/** Sets or clears the expiration time of a document.
    @warning  <b>Deprecated :</b> Use CBLCollection_SetDocumentExpiration instead.
    @param db  The database.
    @param docID  The ID of the document.
    @param expiration  The expiration time as a CBLTimestamp (milliseconds since Unix epoch),
                        or 0 if the document should never expire.
    @param outError  On failure, an error is written here.
    @return  True on success, false on failure. */
bool CBLDatabase_SetDocumentExpiration(CBLDatabase* db,
                                       FLSlice docID,
                                       CBLTimestamp expiration,
                                       CBLError* _cbl_nullable outError) CBLAPI;

/** @} */



/** \name  Document listeners
    @{
    A document change listener lets you detect changes made to a specific document after they
    are persisted to the database.
    @note If there are multiple CBLDatabase instances on the same database file, each one's
    document listeners will be notified of changes made by other database instances.
 */

/** A document change listener callback, invoked after a specific document is changed on disk.
    @warning  By default, this listener may be called on arbitrary threads. If your code isn't
                    prepared for that, you may want to use \ref CBLDatabase_BufferNotifications
                    so that listeners will be called in a safe context.
    @warning  <b>Deprecated :</b> Use CBLCollectionChangeListener instead.
    @param context  An arbitrary value given when the callback was registered.
    @param db  The database containing the document.
    @param docID  The document's ID. */
typedef void (*CBLDocumentChangeListener)(void *context,
                                          const CBLDatabase* db,
                                          FLString docID);

/** Registers a document change listener callback. It will be called after a specific document
    is changed on disk.
    @warning  <b>Deprecated :</b> Use CBLCollection_AddDocumentChangeListener on the default collection instead.
    @param db  The database to observe.
    @param docID  The ID of the document to observe.
    @param listener  The callback to be invoked.
    @param context  An opaque value that will be passed to the callback.
    @return  A token to be passed to \ref CBLListener_Remove when it's time to remove the listener.*/
_cbl_warn_unused
CBLListenerToken* CBLDatabase_AddDocumentChangeListener(const CBLDatabase* db,
                                                        FLString docID,
                                                        CBLDocumentChangeListener listener,
                                                        void* _cbl_nullable context) CBLAPI;

/** @} */
/** @} */

CBL_CAPI_END
