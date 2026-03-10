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
                    \ref CBLCollection_SaveDocumentWithConflictHandler.
    @param documentBeingSaved  The document being saved (same as the parameter you passed to
                    \ref CBLCollection_SaveDocumentWithConflictHandler.) The callback may modify
                    this document's properties as necessary to resolve the conflict.
    @param conflictingDocument  The revision of the document currently in the database,
                    which has been changed since \p documentBeingSaved was loaded.
                    May be NULL, meaning that the document has been deleted.
    @return  True to save the document, false to abort the save. */
typedef bool (*CBLConflictHandler)(void* _cbl_nullable context,
                                   CBLDocument* _cbl_nullable documentBeingSaved,
                                   const CBLDocument* _cbl_nullable conflictingDocument);

CBL_REFCOUNTED(CBLDocument*, Document);

/** @} */

/** \name  Mutable documents
    @{
    The type `CBLDocument*` without a `const` qualifier refers to a _mutable_ document instance.
    A mutable document exposes its properties as a mutable dictionary, so you can change them
    in place and then call \ref CBLDatabase_SaveDocument to persist the changes.
 */

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

/** The hybrid logical timestamp in nanoseconds since epoch that the revision was created. */
uint64_t CBLDocument_Timestamp(const CBLDocument*) CBLAPI;

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

/** @} */

/** @} */

CBL_CAPI_END
