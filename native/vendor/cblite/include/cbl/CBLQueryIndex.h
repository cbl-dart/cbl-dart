//
//  CBLQueryIndex.h
//
// Copyright (c) 2024 Couchbase, Inc All rights reserved.
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
#include "CBLQueryTypes.h"

CBL_CAPI_BEGIN

/** \defgroup index  Index
    @{
 Indexes are used to speed up queries by allowing fast -- O(log n) -- lookup of documents
 that have specific values or ranges of values. The values may be properties, or expressions
 based on properties.

 An index will speed up queries that use the expression it indexes, but it takes up space in
 the database file, and it slows down document saves slightly because it needs to be kept up
 to date when documents change.

 Tuning a database with indexes can be a tricky task. Fortunately, a lot has been written about
 it in the relational-database (SQL) realm, and much of that advice holds for Couchbase Lite.
 You may find SQLite's documentation particularly helpful since Couchbase Lite's querying is
 based on SQLite.

 Supported index types:
     * Value indexes speed up queries by making it possible to look up property (or expression)
       values without scanning every document. They're just like regular indexes in SQL or N1QL.
       Multiple expressions are supported; the first is the primary key, second is secondary.
       Expressions must evaluate to scalar types (boolean, number, string).
 
     * Full-Text Search (FTS) indexes enable fast search of natural-language words or phrases
       by using the `MATCH()` function in a query. A FTS index is **required** for full-text
       search: a query with a `MATCH()` function will fail to compile unless there is already a
       FTS index for the property/expression being matched.
 
     * (Enterprise Edition Only) Vector indexes allows efficient search of ML vectors by using
       the `VECTOR_MATCH()` function in a query. The `CouchbaseLiteVectorSearch`
       extension library is **required** to use the functionality. Use \ref CBL_EnableVectorSearch
       function to set the directoary path containing the extension library.  */

/** \name  CBLQueryIndex
    @{
    CBLQueryIndex represents an existing index in a collection.
 
    Available in the enterprise edition, the \ref CBLQueryIndex can be used to obtain
    a \ref CBLIndexUpdater object for updating the vector index in lazy mode. */
CBL_REFCOUNTED(CBLQueryIndex*, QueryIndex);

/** Returns the index's name.
    @param index  The index.
    @return The name of the index. */
FLString CBLQueryIndex_Name(const CBLQueryIndex* index) CBLAPI;

/** Returns the collection that the index belongs to.
    @param index  The index.
    @return A \ref CBLCollection instance that the index belongs to. */
CBLCollection* CBLQueryIndex_Collection(const CBLQueryIndex* index) CBLAPI;

#ifdef COUCHBASE_ENTERPRISE

CBL_REFCOUNTED(CBLIndexUpdater*, IndexUpdater);

/** ENTERPRISE EDITION ONLY
 
    Finds new or updated documents for which vectors need to be (re)computed and returns an \ref CBLIndexUpdater object
    for setting the computed vectors to update the index. If the index is not lazy, an error will be returned.
    @note For updating lazy vector indexes only.
    @note You are responsible for releasing the returned A \ref CBLIndexUpdater object.
    @param index  The index.
    @param limit The maximum number of vectors to be computed.
    @param outError  On failure, an error is written here.
    @return A \ref CBLIndexUpdater object for setting the computed vectors to update the index, 
            or NULL if the index is up-to-date or an error occurred. */
_cbl_warn_unused
CBLIndexUpdater* _cbl_nullable CBLQueryIndex_BeginUpdate(CBLQueryIndex* index,
                                                    size_t limit,
                                                    CBLError* _cbl_nullable outError) CBLAPI;

/** @} */

/** \name IndexUpdater
    @{
    CBLIndexUpdater used for updating the index in lazy mode. Currently, the vector index is the only index type that
    can be updated lazily.
 */
 
/** ENTERPRISE EDITION ONLY
 
    Returns the total number of vectors to compute and set for updating the index.
    @param updater  The index updater.
    @return The total number of vectors to compute and set for updating the index. */
size_t CBLIndexUpdater_Count(const CBLIndexUpdater* updater) CBLAPI;

/** ENTERPRISE EDITION ONLY
 
    Returns the valut at the given index to compute a vector from.
    @note The returned Fleece value is valid unilt its \ref CBLIndexUpdater is released. 
          If you want to keep it longer, retain it with `FLRetain`.
    @param updater  The index updater.
    @param index  The zero-based index.
    @return A Fleece value of the index's evaluated expression at the given index. */
FLValue CBLIndexUpdater_Value(CBLIndexUpdater* updater, size_t index) CBLAPI;

/** ENTERPRISE EDITION ONLY
 
    Sets the vector for the value corresponding to the given index.
    Setting null vector means that there is no vector for the value, and any existing vector
    will be removed when the `CBLIndexUpdater_Finish` is called.
    @param updater  The index updater.
    @param index The zero-based index.
    @param vector  A pointer to the vector which is an array of floats, or NULL if there is no vector.
    @param dimension  The dimension of `vector`. Must be equal to the dimension value set in the vector index config.
    @param outError  On failure, an error is written here.
    @return True if success, or False if an error occurred. */
bool CBLIndexUpdater_SetVector(CBLIndexUpdater* updater,
                               size_t index,
                               const float vector[_cbl_nullable],
                               size_t dimension,
                               CBLError* _cbl_nullable outError) CBLAPI;

/** ENTERPRISE EDITION ONLY
 
    Skip setting the vector for the value corresponding to the index.
    The vector will be required to compute and set again when the `CBLQueryIndex_BeginUpdate` is later called.
    @param updater  The index updater.
    @param index The zero-based index. */
void CBLIndexUpdater_SkipVector(CBLIndexUpdater* updater, size_t index) CBLAPI;

/** ENTERPRISE EDITION ONLY
 
    Updates the index with the computed vectors and removes any index rows for which null vector was given.
    If there are any indexes that do not have their vector value set or are skipped, a error will be returned.
    @note Before calling `CBLIndexUpdater_Finish`, the set vectors are kept in the memory.
    @warning The index updater cannot be used after calling `CBLIndexUpdater_Finish`.
    @param updater  The index updater.
    @param outError  On failure, an error is written here.
    @return True if success, or False if an error occurred. */
bool CBLIndexUpdater_Finish(CBLIndexUpdater* updater, CBLError* _cbl_nullable outError) CBLAPI;

#endif

/** @} */

/** @} */

CBL_CAPI_END
