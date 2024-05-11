//
// CBLEncryptable.h
//
// Copyright (c) 2021 Couchbase, Inc All rights reserved.
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

#ifdef COUCHBASE_ENTERPRISE

CBL_CAPI_BEGIN

/** \defgroup encryptables Encryptables
    @{

    A \ref CBLEncryptable is a value to be encrypted by the replicator when a document is
    pushed to the remote server. When a document is pulled from the remote server, the
    encrypted value will be decrypted by the replicator.
 
    Similar to \ref CBLBlob, a \ref CBLEncryptable acts as a proxy for a dictionary structure
    with the special marker property `"@type":"encryptable"`, and another property `value`
    whose value is the actual value to be encrypted by the push replicator.
 
    The push replicator will automatically detect \ref CBLEncryptable dictionaries inside
    the document and calls the specified \ref CBLPropertyEncryptor callback to encrypt the
    actual value. When the value is successfully encrypted, the replicator will transform
    the property key and the encrypted \ref CBLPropertyEncryptor dictionary value into
    Couchbase Server SDK's encrypted field format :
 
    * The original key will be prefixed with 'encrypted$'.
 
    * The transformed \ref CBLEncryptable dictionary will contain `alg` property indicating
      the encryption algorithm, `ciphertext` property whose value is a base-64 string of the
      encrypted value, and optionally `kid` property indicating the encryption key identifier
      if specified when returning the result of \ref CBLPropertyEncryptor callback call.
    
    For security reason, a document that contains CBLEncryptable dictionaries will fail
    to push with the \ref kCBLErrorCrypto error if their value cannot be encrypted including
    when a \ref CBLPropertyEncryptor callback is not specified or when there is an error
    or a null result returned from the callback call.
 
    The pull replicator will automatically detect the encrypted properties that are in the
    Couchbase Server SDK's encrypted field format and call the specified \ref CBLPropertyDecryptor
    callback to decrypt the encrypted value. When the value is successfully decrypted,
    the replicator will transform the property format back to the CBLEncryptable format
    including removing the 'encrypted$' prefix.
 
    The \ref CBLPropertyDecryptor callback can intentionally skip the decryption by returnning a
    null result. When a decryption is skipped, the encrypted property in the form of
    Couchbase Server SDK's encrypted field format will be kept as it was received from the remote
    server. If an error is returned from the callback call, the document will be failed to pull with
    the \ref kCBLErrorCrypto error.
 
    If a \ref CBLPropertyDecryptor callback is not specified, the replicator will not attempt to
    detect any encrypted properties. As a result, all encrypted properties in the form of
    Couchbase Server SDK's encrypted field format will be kept as they was received from the remote
    server.
    
    To create a new \ref CBLEncryptable, call CBLEncryptable_CreateWith<Value Type>
    function such as \ref CBLEncryptable_CreateWithString. Then call \ref FLSlot_SetEncryptableValue
    to add the \ref CBLEncryptable to a dictionary in the document. Noted that adding
    \ref CBLEncryptable to an array is not supported. For example:
 
    FLSlot_SetEncryptableValue(FLMutableDict_Set(properties, key), encryptableValue);
 
    Note: When creating a \ref CBLEncryptable, you are responsible for releasing the
    \ref CBLEncryptable object but not until its document is saved into the database.
 
    When a document is loaded from the database, call \ref FLDict_GetEncryptableValue on an
    Encryptable dictionary value to obtain a \ref CBLEncryptable object.
 */

CBL_PUBLIC extern const FLSlice kCBLEncryptableType;                ///< `"encryptable"`
CBL_PUBLIC extern const FLSlice kCBLEncryptableValueProperty;       ///< `"value"`

CBL_REFCOUNTED(CBLEncryptable*, Encryptable);

#ifdef __APPLE__
#pragma mark - CREATING:
#endif

/** Creates CBLEncryptable object with null value. */
CBLEncryptable* CBLEncryptable_CreateWithNull(void) CBLAPI;

/** Creates CBLEncryptable object with a boolean value. */
CBLEncryptable* CBLEncryptable_CreateWithBool(bool value) CBLAPI;

/** Creates CBLEncryptable object with an int value. */
CBLEncryptable* CBLEncryptable_CreateWithInt(int64_t value) CBLAPI;

/** Creates CBLEncryptable object with an unsigned int value. */
CBLEncryptable* CBLEncryptable_CreateWithUInt(uint64_t value) CBLAPI;

/** Creates CBLEncryptable object with a float value. */
CBLEncryptable* CBLEncryptable_CreateWithFloat(float value) CBLAPI;

/** Creates CBLEncryptable object with a double value. */
CBLEncryptable* CBLEncryptable_CreateWithDouble(double value) CBLAPI;

/** Creates CBLEncryptable object with a string value. */
CBLEncryptable* CBLEncryptable_CreateWithString(FLString value) CBLAPI;

/** Creates CBLEncryptable object with an FLValue value. */
CBLEncryptable* CBLEncryptable_CreateWithValue(FLValue value) CBLAPI;

/** Creates CBLEncryptable object with an FLArray value. */
CBLEncryptable* CBLEncryptable_CreateWithArray(FLArray value) CBLAPI;

/** Creates CBLEncryptable object with an FLDict value. */
CBLEncryptable* CBLEncryptable_CreateWithDict(FLDict value) CBLAPI;

#ifdef __APPLE__
#pragma mark - READING:
#endif

/** Returns the value to be encrypted by the push replicator. */
FLValue CBLEncryptable_Value(const CBLEncryptable* encryptable) CBLAPI;

/** Returns the dictionary format of the \ref CBLEncryptable object. */
FLDict CBLEncryptable_Properties(const CBLEncryptable* encryptable) CBLAPI;

#ifdef __APPLE__
#pragma mark - FLEECE:
#endif

/** Checks whether the given dictionary is a \ref CBLEncryptable or not. */
bool FLDict_IsEncryptableValue(FLDict _cbl_nullable) CBLAPI;

/** Checks whether the given FLValue is a \ref CBLEncryptable or not. */
static inline bool FLValue_IsEncryptableValue(FLValue _cbl_nullable value) {
    return FLDict_IsEncryptableValue(FLValue_AsDict(value));
}

/** Returns a \ref CBLEncryptable object corresponding to the given encryptable dictionary
    in a document or NULL if the dictionary is not a \ref CBLEncryptable.
    \note  The returned CBLEncryptable object will be released when its document is released. */
const CBLEncryptable* _cbl_nullable FLDict_GetEncryptableValue(FLDict _cbl_nullable encryptableDict) CBLAPI;

/** Returns a \ref CBLEncryptable object corresponding to the given \ref FLValue in a document
    or NULL if the value is not a \ref CBLEncryptable.
    \note  The returned CBLEncryptable object will be released when its document is released. */
static inline const CBLEncryptable* _cbl_nullable FLValue_GetEncryptableValue(FLValue _cbl_nullable value) {
    return FLDict_GetEncryptableValue(FLValue_AsDict(value));
}

/** Set a \ref CBLEncryptable's dictionary into a mutable dictionary's slot. */
void FLSlot_SetEncryptableValue(FLSlot slot, const CBLEncryptable* encryptable) CBLAPI;

/** Set a \ref CBLEncryptable's dictionary into a mutable dictionary. */
static inline void FLMutableDict_SetEncryptableValue(FLMutableDict dict, FLString key, CBLEncryptable* encryptable) {
    FLSlot_SetEncryptableValue(FLMutableDict_Set(dict, key), encryptable);
}

/** @} */

CBL_CAPI_END

#endif
