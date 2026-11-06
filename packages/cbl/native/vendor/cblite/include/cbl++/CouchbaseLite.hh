//
//  CouchbaseLite.hh
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


/** \mainpage Couchbase Lite C++ API

    A header-only C++ wrapper API around the Couchbase Lite C API, providing ref-counted
    C++ classes for the Couchbase Lite objects with automatic memory management, and
    exceptions for error handling.

    \section getting_started Getting Started

    Include `cbl++/CouchbaseLite.hh` (or the individual `cbl++` headers). All classes
    live in the \ref cbl namespace and are listed in the
    <a href="annotated.html">class list</a>; the main ones are \ref cbl::Database,
    \ref cbl::Collection, \ref cbl::MutableDocument, \ref cbl::Query, and
    \ref cbl::Replicator.

    \code{.cpp}
    #include "cbl++/CouchbaseLite.hh"

    cbl::Database db("mydb");
    cbl::Collection collection = db.getDefaultCollection();

    cbl::MutableDocument doc("doc1");
    doc["greeting"] = "Hello, World!";
    collection.saveDocument(doc);
    \endcode

    \section object_model Object Model

    The wrapper classes are thin smart references to the underlying ref-counted
    Couchbase Lite objects, behaving much like `std::shared_ptr`: copying a
    wrapper creates another reference to the same object, not a copy of the
    object, and the object is freed when its last reference goes away.

    A default-constructed wrapper is a null reference that points to no object;
    test it with `operator bool()` or with `valid()`. This documentation calls such
    objects *falsy*: functions like \ref cbl::Collection::getDocument return a
    falsy object instead of throwing when the requested item doesn't exist.

    Use `ref()` to access the underlying C object when mixing in C API calls.

    \section document_data Document Data

    Document properties are stored as Fleece values: \ref cbl::Document::properties
    returns a `fleece::Dict`, \ref cbl::MutableDocument::properties returns a
    `fleece::MutableDict`, and individual property values are accessed as
    `fleece::Value`.

    Strings and binary data are passed as `fleece::slice` and `fleece::alloc_slice`,
    which are constructible from `std::string`, `std::string_view`, and C strings.
    The difference between them is ownership: a `slice` is a non-owning view of a
    byte range and must not outlive the data it points to, while an `alloc_slice`
    owns a reference-counted buffer that keeps its data alive. To keep string data
    around, store it as an `alloc_slice` or convert it with `asString()`. The `cbl`
    namespace declares \ref cbl::slice and \ref cbl::alloc_slice as convenience
    aliases for these two types.

    The `fleece` classes are declared in the `fleece/Fleece.hh`, `fleece/Mutable.hh`,
    and `fleece/slice.hh` headers shipped with Couchbase Lite. They are thin wrappers
    around the Fleece C API, which is documented in the Couchbase Lite C API Reference.

    \section error_handling Error Handling

    Functions in the Couchbase Lite C++ API report Couchbase Lite-specific failures by
    throwing \ref cbl::Error, a subclass of `std::runtime_error` that provides the error
    domain, error code, and a human-readable message from `what()`.

    Catch \ref cbl::Error when you need Couchbase Lite-specific error details. Catch
    `std::exception` for general error handling.

    `noexcept` marks functions that are guaranteed not to throw. All other functions
    should be treated as potentially throwing on failure, unless otherwise documented.
*/

#pragma once
#include "Blob.hh"
#include "Collection.hh"
#include "Database.hh"
#include "Document.hh"
#include "Encryptable.hh"
#include "LogSinks.hh"
#include "Prediction.hh"
#include "Query.hh"
#include "QueryIndex.hh"
#include "Replicator.hh"
#include "TLSIdentity.hh"
#include "URLEndpointListener.hh"
#include "VectorIndex.hh"
