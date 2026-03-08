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

/** Supported Query languages */
typedef CBL_ENUM(uint32_t, CBLQueryLanguage) {
    kCBLJSONLanguage,       ///< [JSON query schema](https://github.com/couchbase/couchbase-lite-core/wiki/JSON-Query-Schema)
    kCBLN1QLLanguage        ///< [N1QL syntax](https://docs.couchbase.com/server/6.0/n1ql/n1ql-language-reference/index.html)
};

/** @} */

CBL_CAPI_END
