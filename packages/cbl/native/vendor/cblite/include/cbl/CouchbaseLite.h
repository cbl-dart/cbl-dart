//
//  CouchbaseLite.h
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


/** \mainpage Couchbase Lite C API

    The C API of Couchbase Lite, an embedded NoSQL document database for mobile,
    desktop, and edge devices.

    \section getting_started Getting Started

    Include `cbl/CouchbaseLite.h` (or the individual `cbl/CBL*.h` headers). The API
    is organized into the groups listed on the <a href="modules.html">Modules</a> page.

    \code{.c}
    #include "cbl/CouchbaseLite.h"

    CBLError error;
    CBLDatabase* db = CBLDatabase_Open(FLSTR("mydb"), NULL, &error);
    if (!db) {
        // handle error; see CBLError_Message()
    }

    CBLCollection* collection = CBLDatabase_DefaultCollection(db, &error);

    CBLDocument* doc = CBLDocument_CreateWithID(FLSTR("doc1"));
    FLMutableDict props = CBLDocument_MutableProperties(doc);
    FLMutableDict_SetString(props, FLSTR("greeting"), FLSTR("Hello, World!"));

    if (!CBLCollection_SaveDocument(collection, doc, &error)) {
        // handle error
    }

    CBLDocument_Release(doc);
    CBLCollection_Release(collection);
    CBLDatabase_Close(db, &error);
    CBLDatabase_Release(db);
    \endcode

    \section reference_counting Reference Counting

    Couchbase Lite objects are reference-counted. Functions that create an object
    (typically named `..._Create()` or `..._New()`) return it with a ref-count of 1;
    release it with the type-safe `CBLXxx_Release()` function when you are done with
    it, or it will be leaked. Functions that return an existing object do not change
    its ref-count: do not release it unless you retained it, and retain it if you
    need to keep it alive. Each function's documentation states whether you are
    responsible for releasing the returned object. See
    \ref refcounting "Reference Counting" for details.

    \section error_handling Error Handling

    Functions that can fail take a `CBLError*` out-parameter and signal failure
    through their return value, typically by returning `false` or `NULL`. On failure,
    the error's domain and code are written to the out-parameter, and
    \ref CBLError_Message returns a human-readable message for it. See
    \ref errors "Errors".

    \section document_data Document Data

    Document properties are stored as Fleece values: \ref CBLDocument_Properties
    returns an `FLDict`, and \ref CBLDocument_MutableProperties returns an
    `FLMutableDict`. Strings and binary data are passed as `FLString`/`FLSlice`,
    non-owning views of a byte range that must not outlive the data they point to;
    use `FLSTR()` to make one from a string literal. Functions returning
    `FLSliceResult`/`FLStringResult` transfer ownership of heap-allocated data:
    release the result when done. The Fleece API is documented in this reference
    under the Fleece topic groups.
*/

#pragma once
#include "CBLBase.h"
#include "CBLBlob.h"
#include "CBLCollection.h"
#include "CBLDatabase.h"
#include "CBLDefaults.h"
#include "CBLDocument.h"
#include "CBLEncryptable.h"
#include "CBLLog.h"
#include "CBLLogSinks.h"
#include "CBLPlatform.h"
#include "CBLPrediction.h"
#include "CBLQuery.h"
#include "CBLQueryIndex.h"
#include "CBLQueryIndexTypes.h"
#include "CBLQueryTypes.h"
#include "CBLTLSIdentity.h"
#include "CBLReplicator.h"
#include "CBLScope.h"
#include "CBLURLEndpointListener.h"
