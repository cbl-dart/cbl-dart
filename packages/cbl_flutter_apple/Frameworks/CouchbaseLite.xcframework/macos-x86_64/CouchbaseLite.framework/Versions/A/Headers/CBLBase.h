//
// CBLBase.h
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
#ifdef CMAKE
#include "cbl_config.h"
#endif

#include "CBL_Compat.h"
#include "fleece/FLSlice.h"
#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif


/** \defgroup errors   Errors
     @{
    Types and constants for communicating errors from API calls. */

/** Error domains, serving as namespaces for numeric error codes. */
typedef CBL_ENUM(uint32_t, CBLErrorDomain) {
    CBLDomain = 1,         ///< code is a Couchbase Lite error code; see \ref CBLErrorCode
    CBLPOSIXDomain,        ///< code is a POSIX `errno`; see "errno.h"
    CBLSQLiteDomain,       ///< code is a SQLite error; see "sqlite3.h"
    CBLFleeceDomain,       ///< code is a Fleece error; see "FleeceException.h"
    CBLNetworkDomain,      ///< code is a network error; see \ref CBLNetworkErrorCode
    CBLWebSocketDomain,    ///< code is a WebSocket close code (1000...1015) or HTTP error (300..599)

    CBLMaxErrorDomainPlus1
};

/** Couchbase Lite error codes, in the CBLDomain. */
typedef CBL_ENUM(int32_t, CBLErrorCode) {
    CBLErrorAssertionFailed = 1,    ///< Internal assertion failure
    CBLErrorUnimplemented,          ///< Oops, an unimplemented API call
    CBLErrorUnsupportedEncryption,  ///< Unsupported encryption algorithm
    CBLErrorBadRevisionID,          ///< Invalid revision ID syntax
    CBLErrorCorruptRevisionData,    ///< Revision contains corrupted/unreadable data
    CBLErrorNotOpen,                ///< Database/KeyStore/index is not open
    CBLErrorNotFound,               ///< Document not found
    CBLErrorConflict,               ///< Document update conflict
    CBLErrorInvalidParameter,       ///< Invalid function parameter or struct value
    CBLErrorUnexpectedError, /*10*/ ///< Internal unexpected C++ exception
    CBLErrorCantOpenFile,           ///< Database file can't be opened; may not exist
    CBLErrorIOError,                ///< File I/O error
    CBLErrorMemoryError,            ///< Memory allocation failed (out of memory?)
    CBLErrorNotWriteable,           ///< File is not writeable
    CBLErrorCorruptData,            ///< Data is corrupted
    CBLErrorBusy,                   ///< Database is busy/locked
    CBLErrorNotInTransaction,       ///< Function must be called while in a transaction
    CBLErrorTransactionNotClosed,   ///< Database can't be closed while a transaction is open
    CBLErrorUnsupported,            ///< Operation not supported in this database
    CBLErrorNotADatabaseFile,/*20*/ ///< File is not a database, or encryption key is wrong
    CBLErrorWrongFormat,            ///< Database exists but not in the format/storage requested
    CBLErrorCrypto,                 ///< Encryption/decryption error
    CBLErrorInvalidQuery,           ///< Invalid query
    CBLErrorMissingIndex,           ///< No such index, or query requires a nonexistent index
    CBLErrorInvalidQueryParam,      ///< Unknown query param name, or param number out of range
    CBLErrorRemoteError,            ///< Unknown error from remote server
    CBLErrorDatabaseTooOld,         ///< Database file format is older than what I can open
    CBLErrorDatabaseTooNew,         ///< Database file format is newer than what I can open
    CBLErrorBadDocID,               ///< Invalid document ID
    CBLErrorCantUpgradeDatabase,/*30*/ ///< DB can't be upgraded (might be unsupported dev version)

    CBLNumErrorCodesPlus1
};

/** Network error codes, in the CBLNetworkDomain. */
typedef CBL_ENUM(int32_t,  CBLNetworkErrorCode) {
    CBLNetErrDNSFailure = 1,            ///< DNS lookup failed
    CBLNetErrUnknownHost,               ///< DNS server doesn't know the hostname
    CBLNetErrTimeout,                   ///< No response received before timeout
    CBLNetErrInvalidURL,                ///< Invalid URL
    CBLNetErrTooManyRedirects,          ///< HTTP redirect loop
    CBLNetErrTLSHandshakeFailed,        ///< Low-level error establishing TLS
    CBLNetErrTLSCertExpired,            ///< Server's TLS certificate has expired
    CBLNetErrTLSCertUntrusted,          ///< Cert isn't trusted for other reason
    CBLNetErrTLSClientCertRequired,     ///< Server requires client to have a TLS certificate
    CBLNetErrTLSClientCertRejected,     ///< Server rejected my TLS client certificate
    CBLNetErrTLSCertUnknownRoot,        ///< Self-signed cert, or unknown anchor cert
    CBLNetErrInvalidRedirect,           ///< Attempted redirect to invalid URL
    CBLNetErrUnknown,                   ///< Unknown networking error
    CBLNetErrTLSCertRevoked,            ///< Server's cert has been revoked
    CBLNetErrTLSCertNameMismatch,       ///< Server cert's name does not match DNS name
};


/** A struct holding information about an error. It's declared on the stack by a caller, and
    its address is passed to an API function. If the function's return value indicates that
    there was an error (usually by returning NULL or false), then the CBLError will have been
    filled in with the details. */
typedef struct {
    CBLErrorDomain domain;      ///< Domain of errors; a namespace for the `code`.
    int32_t code;               ///< Error code, specific to the domain. 0 always means no error.
    int32_t internal_info;
} CBLError;

/** Returns a message describing an error.
    @note  It is the caller's responsibility to free the returned C string by calling `free`. */
char* CBLError_Message(const CBLError* _cbl_nonnull) CBLAPI;

FLSliceResult CBLError_Message_s(const CBLError* _cbl_nonnull) CBLAPI;

/** @} */



/** \defgroup other_types   Other Types
     @{ */

/** A date/time representation used for document expiration (and in date/time queries.)
    Measured in milliseconds since the Unix epoch (1/1/1970, midnight UTC.) */
typedef int64_t CBLTimestamp;


/** Returns the current time, in milliseconds since 1/1/1970. */
CBLTimestamp CBL_Now(void) CBLAPI;

/** @} */



/** \defgroup refcounting   Reference Counting
     @{
    Couchbase Lite "objects" are reference-counted; the functions below are the shared
    _retain_ and _release_ operations. (But there are type-safe equivalents defined for each
    class, so you can call \ref CBLDatabase_Release() on a database, for instance, without having to
    type-cast.)

    API functions that **create** a ref-counted object (typically named `..._New()` or `..._Create()`)
    return the object with a ref-count of 1; you are responsible for releasing the reference
    when you're done with it, or the object will be leaked.

    Other functions that return an **existing** ref-counted object do not modify its ref-count.
    You do _not_ need to release such a reference. But if you're keeping a reference to the object
    for a while, you should retain the reference to ensure it stays alive, and then release it when
    finished (to balance the retain.)
 */

typedef struct CBLRefCounted CBLRefCounted;

/** Increments an object's reference-count.
    Usually you'll call one of the type-safe synonyms specific to the object type,
    like \ref CBLDatabase_Retain` */
CBLRefCounted* CBL_Retain(CBLRefCounted*) CBLAPI;

/** Decrements an object's reference-count, freeing the object if the count hits zero.
    Usually you'll call one of the type-safe synonyms specific to the object type,
    like \ref CBLDatabase_Release. */
void CBL_Release(CBLRefCounted*) CBLAPI;

/** Returns the total number of Couchbase Lite objects. Useful for leak checking. */
unsigned CBL_InstanceCount(void) CBLAPI;

/** Logs the class and address of each Couchbase Lite object. Useful for leak checking.
    @note  May only be functional in debug builds of Couchbase Lite. */
void CBL_DumpInstances(void) CBLAPI;

// Declares retain/release functions for TYPE. For internal use only.
#define CBL_REFCOUNTED(TYPE, NAME) \
    static inline const TYPE CBL##NAME##_Retain(const TYPE _cbl_nonnull t) \
                                            {return (const TYPE)CBL_Retain((CBLRefCounted*)t);} \
    static inline void CBL##NAME##_Release(const TYPE t) {CBL_Release((CBLRefCounted*)t);}

/** @} */



/** \defgroup database  Database
     @{ */
/** A connection to an open database. */
typedef struct CBLDatabase   CBLDatabase;
/** @} */

/** \defgroup documents  Documents
     @{ */
/** An in-memory copy of a document.
    CBLDocument objects can be mutable or immutable. Immutable objects are referenced by _const_
    pointers; mutable ones by _non-const_ pointers. This prevents you from accidentally calling
    a mutable-document function on an immutable document. */
typedef struct CBLDocument   CBLDocument;
/** @} */

/** \defgroup blobs Blobs
     @{ */
/** A binary data value associated with a \ref CBLDocument. */
typedef struct CBLBlob      CBLBlob;
/** @} */

/** \defgroup queries  Queries
     @{ */
/** A compiled database query. */
typedef struct CBLQuery      CBLQuery;

/** An iterator over the rows resulting from running a query. */
typedef struct CBLResultSet  CBLResultSet;
/** @} */

/** \defgroup replication  Replication
     @{ */
/** A background task that syncs a \ref CBLDatabase with a remote server or peer. */
typedef struct CBLReplicator CBLReplicator;
/** @} */



/** \defgroup listeners   Listeners
     @{
    Every API function that registers a listener callback returns an opaque token representing
    the registered callback. To unregister any type of listener, call \ref CBLListener_Remove.

    The steps to creating a listener are:
    1. Define the type of contextual information the callback needs. This is usually one of
        your objects, or a custom struct.
    2. Implement the listener function:
      - The parameters and return value must match the callback defined in the API.
      - The first parameter is always a `void*` that points to your contextual
          information, so cast that to the actual pointer type.
      - **The function may be called on a background thread!** And since the CBL API is not itself
          thread-safe, you'll need to take special precautions if you want to call the API
          from your listener, such as protecting all of your calls (inside and outside the
          listener) with a mutex. It's safer to use \ref CBLDatabase_BufferNotifications to
          schedule listener callbacks to a time of your own choosing, such as your thread's
          event loop; see that function's docs for details.
    3. To register the listener, call the relevant `AddListener` function.
      - The parameters will include the CBL object to observe, the address of your listener
        function, and a pointer to the contextual information. (That pointer needs to remain
        valid for as long as the listener is registered, so it can't be a pointer to a local
        variable.)
      - The return value is a \ref CBLListenerToken pointer; save that.
    4. To unregister the listener, pass the \ref CBLListenerToken to \ref CBLListener_Remove.
      - You **must** unregister the listener before the contextual information pointer is
        invalidated, e.g. before freeing the object it points to.
 */

/** An opaque 'cookie' representing a registered listener callback.
    It's returned from functions that register listeners, and used to remove a listener by
    calling \ref CBLListener_Remove. */
typedef struct CBLListenerToken CBLListenerToken;

/** Removes a listener callback, given the token that was returned when it was added. */
void CBLListener_Remove(CBLListenerToken*) CBLAPI;


/** @} */

#ifdef __cplusplus
}
#endif
