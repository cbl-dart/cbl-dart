//
//  CBLQueryTypes.h
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

CBL_CAPI_BEGIN

/** \defgroup queries   Queries
    @{ */

/** Query languages */
typedef CBL_ENUM(uint32_t, CBLQueryLanguage) {
    /**
     * VOLATILE API : The JSON query language is a volatile API.  Volatile APIs are experimental and may likely be changed.
     * They may also be used to indicate inherently private APIs that may be exposed, but "YMMV" (your mileage may vary)
     * principles apply.
     *
     * See the [JSON query schema](https://github.com/couchbase/couchbase-lite-core/wiki/JSON-Query-Schema).
     */
    kCBLJSONLanguage,
    /**
     * SQL++ (formerly N1QL) query language.
     *
     * See the [N1QL language reference](https://docs.couchbase.com/couchbase-lite/current/c/query-n1ql-mobile.html).
     */
    kCBLN1QLLanguage
};

/** @} */

CBL_CAPI_END
