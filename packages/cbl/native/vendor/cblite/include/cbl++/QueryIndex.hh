//
// QueryIndex.hh
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

// VOLATILE API: Couchbase Lite C++ API is not finalized, and may change in
// future releases.

#pragma once
#include "cbl++/Base.hh"
#include "cbl++/Collection.hh"
#include "cbl/CBLQueryIndex.h"

CBL_ASSUME_NONNULL_BEGIN

namespace cbl {
#ifdef COUCHBASE_ENTERPRISE
    class IndexUpdater;
#endif

    /** QueryIndex object representing an existing index in the collection. */
    class QueryIndex : private RefCounted {
    public:
        // Accessors:
        
        /** The index's name. */
        std::string name() const                        {return asString(CBLQueryIndex_Name(ref()));}
        
        /** A index's collection. */
        Collection collection() const                   {return Collection(CBLQueryIndex_Collection(ref()));}
        
#ifdef COUCHBASE_ENTERPRISE
        // Index Updater:
        
        /** ENTERPRISE EDITION ONLY
         
            Finds new or updated documents for which vectors need to be (re)computed and returns an \ref IndexUpdater object
            for setting the computed vectors to update the index. If the index is not lazy, an error will be returned.
            @note For updating lazy vector indexes only.
            @param limit The maximum number of vectors to be computed.
            @return An \ref IndexUpdater object for setting the computed vectors to update the index,
                    or NULL if the index is up-to-date. */
        inline IndexUpdater beginUpdate(size_t limit);
#endif
        
    protected:
        friend class Collection;
        
        static QueryIndex adopt(const CBLQueryIndex* _cbl_nullable i, CBLError *error) {
            if (!i && error->code != 0)
                throw *error;
            QueryIndex index;
            index._ref = (CBLRefCounted*)i;
            return index;
        }
        
        CBL_REFCOUNTED_BOILERPLATE(QueryIndex, RefCounted, CBLQueryIndex)
    };

#ifdef COUCHBASE_ENTERPRISE

    /** ENTERPRISE EDITION ONLY
     
        IndexUpdater is used for updating the index in lazy mode. Currently, the vector index is the only index type
        that can be updated lazily. */
    class IndexUpdater : private RefCounted {
    public:
        /** The total number of vectors to compute and set for updating the index. */
        size_t count() const                            {return CBLIndexUpdater_Count(ref());}
        
        /** Get the value at the given index for computing the vector. 
            @param index The zero-based index.
            @return The value. */
        fleece::Value value(size_t index) const {
            return CBLIndexUpdater_Value(ref(), index);
        }
        
        /** Sets the vector for the value corresponding to the given index.
            Setting NULL vector means that there is no vector for the value, and any existing vector
            will be removed when the \ref IndexUpdater::finish is called.
            @param index The zero-based index.
            @param vector  A pointer to the vector which is an array of floats, or NULL if there is no vector.
            @param dimension  The dimension of `vector`. Must be equal to the dimension value set in the vector index config. */
        void setVector(unsigned index, const float* _cbl_nullable vector, size_t dimension) {
            CBLError error;
            check(CBLIndexUpdater_SetVector(ref(), index, vector, dimension, &error), error);
        }
        
        /** Skip setting the vector for the value corresponding to the index.
            The vector will be required to compute and set again when the \ref QueryIndex::beginUpdate is later called.
            @param index The zero-based index. */
        void skipVector(size_t index) {
            CBLIndexUpdater_SkipVector(ref(), index);
        }
        
        /** Updates the index with the computed vectors and removes any index rows for which null vector was given.
            If there are any indexes that do not have their vector value set or are skipped, a error will be returned.
            @note Before calling \ref IndexUpdater::finish, the set vectors are kept in the memory.
            @warning The index updater cannot be used after calling \ref IndexUpdater::finish. */
        void finish() {
            CBLError error;
            check(CBLIndexUpdater_Finish(ref(), &error), error);
        }
        
    protected:
        static IndexUpdater adopt(const CBLIndexUpdater* _cbl_nullable i, CBLError *error) {
            if (!i && error->code != 0)
                throw *error;
            IndexUpdater updater;
            updater._ref = (CBLRefCounted*)i;
            return updater;
        }
        
        friend class QueryIndex;
        CBL_REFCOUNTED_BOILERPLATE(IndexUpdater, RefCounted, CBLIndexUpdater)
    };

    IndexUpdater QueryIndex::beginUpdate(size_t limit) {
        CBLError error {};
        auto updater = CBLQueryIndex_BeginUpdate(ref(), limit, &error);
        return IndexUpdater::adopt(updater, &error);
    }
#endif

    QueryIndex Collection::getIndex(slice name) {
        CBLError error {};
        return QueryIndex::adopt(CBLCollection_GetIndex(ref(), name, &error), &error);
    }
}

CBL_ASSUME_NONNULL_END
