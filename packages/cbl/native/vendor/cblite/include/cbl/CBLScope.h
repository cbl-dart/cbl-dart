//
//  CBLScope.h
//
// Copyright (c) 2022 Couchbase, Inc All rights reserved.
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

/** \defgroup scope   Scope
    @{
    A \ref CBLScope represents a scope or namespace of the collections.
 
    The scope implicitly exists when there is at least one collection created under the scope.
    The default scope is exceptional in that it will always exists even there are no collections
    under it.
 
    ## `CBLScope` Lifespan
    `CBLScope` is ref-counted. Same as the CBLCollection, the CBLScope objects
    retrieved from the database must be released after you are done using them.
    When the database is closed or released, the scope objects will become invalid,
    most operations on the invalid \ref CBLCollection object will fail with
    \ref kCBLErrorNotOpen error result. */

CBL_REFCOUNTED(CBLScope*, Scope);

/** \name  Default Scope Name
    @{
    The default scope name constant.
 */

/** The default scope's name. */
CBL_PUBLIC extern const FLString kCBLDefaultScopeName;

/** @} */

/** \name  Scope Accessors
    @{
    Getting information about a scope.
 */

/** Returns the name of the scope.
    @param scope  The scope.
    @return  The name of the scope. */
FLString CBLScope_Name(const CBLScope* scope) CBLAPI;

/** Returns the scope's database.
    @note The database object is owned by the scope object; you do not need to release it.
    @param scope  The scope.
    @return The database of the scope. */
CBLDatabase* CBLScope_Database(const CBLScope* scope) CBLAPI;

/** @} */

/** \name  Collections
    @{
    Accessing the collections under the scope.
 */

/** Returns the names of all collections in the scope.
    @note  You are responsible for releasing the returned array.
    @param scope  The scope.
    @param outError  On failure, the error will be written here.
    @return  The names of all collections in the scope, or NULL if an error occurred. */
FLMutableArray _cbl_nullable CBLScope_CollectionNames(const CBLScope* scope,
                                                      CBLError* _cbl_nullable outError) CBLAPI;

/** Returns an existing collection in the scope with the given name.
    @note  You are responsible for releasing the returned collection.
    @param scope  The scope.
    @param collectionName  The name of the collection.
    @param outError  On failure, the error will be written here.
    @return A \ref CBLCollection instance, or NULL if the collection doesn't exist or an error occurred. */
CBLCollection* _cbl_nullable CBLScope_Collection(const CBLScope* scope,
                                                 FLString collectionName,
                                                 CBLError* _cbl_nullable outError) CBLAPI;

/** @} */
/** @} */    // end of outer \defgroup

CBL_CAPI_END
