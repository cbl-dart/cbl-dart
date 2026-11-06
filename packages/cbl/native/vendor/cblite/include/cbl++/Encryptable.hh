//
// Encryptable.hh
//
// Copyright (c) 2026 Couchbase, Inc All rights reserved.
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

#ifdef COUCHBASE_ENTERPRISE

#include "cbl++/Base.hh"
#include "cbl/CBLEncryptable.h"
#include "fleece/Fleece.hh"
#include <string_view>


CBL_ASSUME_NONNULL_BEGIN

namespace cbl {

    /** A reference to an encryptable value associated with a document.
        An Encryptable wraps a value (null, bool, number, string, array, dict) that should
        be encrypted by the push replicator and decrypted by the pull replicator. Its
        persistent form is a special dictionary in the document properties; construct an
        Encryptable from such a dictionary via Encryptable::getEncryptableValue.
        \note ENTERPRISE EDITION ONLY */
    class Encryptable : protected RefCounted {
    public:
    /** Creates an Encryptable wrapping an arbitrary Fleece value.
        @param value  The value to be encrypted. */
    explicit Encryptable(fleece::Value value) : Encryptable(CBLEncryptable_CreateWithValue(value), adopt){}

    /** Creates an Encryptable wrapping a string value.
        @param value  The string to be encrypted. */
    explicit Encryptable(std::string_view value) : Encryptable(CBLEncryptable_CreateWithString((slice)value), adopt){}

    /** Creates an Encryptable wrapping a null value.
        @note Use factory method to avoid ambiguity. */
    static Encryptable createWithNull() {
        return {CBLEncryptable_CreateWithNull(), adopt};
    }

    /** Creates an Encryptable wrapping a boolean value.
        @param value  The value to be encrypted.
        @note Use factory method to avoid ambiguity. */
    static Encryptable createWithBool(bool value) {
        return {CBLEncryptable_CreateWithBool(value), adopt};
    }

    /** Creates an Encryptable wrapping a signed integer value.
        @param value  The value to be encrypted.
        @note Use factory method to avoid ambiguity. */
    static Encryptable createWithInt(int64_t value) {
        return {CBLEncryptable_CreateWithInt(value), adopt};
    }

    /** Creates an Encryptable wrapping an unsigned integer value.
        @param value  The value to be encrypted.
        @note Use factory method to avoid ambiguity. */
    static Encryptable createWithUInt(uint64_t value) {
        return {CBLEncryptable_CreateWithUInt(value), adopt};
    }

    /** Creates an Encryptable wrapping a float value.
        @param value  The value to be encrypted.
        @note Use factory method to avoid ambiguity. */
    static Encryptable createWithFloat(float value) {
        return {CBLEncryptable_CreateWithFloat(value), adopt};
    }

    /** Creates an Encryptable wrapping a double value.
        @param value  The value to be encrypted.
        @note Use factory method to avoid ambiguity. */
    static Encryptable createWithDouble(double value) {
        return {CBLEncryptable_CreateWithDouble(value), adopt};
    }

    /** Returns the value to be encrypted by the push replicator. */
    fleece::Value value() const     {return CBLEncryptable_Value(ref());}

    /** Returns the Encryptable's underlying dictionary representation (its persistent form). */
    fleece::Dict properties() const {return CBLEncryptable_Properties(ref());}

    /** Sets this encryptable value into @p dict under @p key.
        Equivalent to the C API `FLMutableDict_SetEncryptableValue`. */
    void setInto(fleece::MutableDict dict, fleece::slice key) const {
        fleece::Dict props = properties();
        fleece::MutableDict mProps = props.asMutable();
        if (!mProps)
            mProps = props.mutableCopy();
        dict[key] = mProps;
    }

    /** Returns true if the given dictionary is the persistent form of an Encryptable.
        @param dict  The dictionary to test. */
    static bool isEncryptableValue(fleece::Dict dict) {
        return FLDict_IsEncryptableValue(dict);
    }

    /** Returns the Encryptable that the given value represents, if any.
        @param value  A value from a document, expected to be an encryptable dictionary.
        @return  The corresponding Encryptable, or a falsy Encryptable if the value is not one. */
    static Encryptable getEncryptableValue(fleece::Value value) {
        return Encryptable{const_cast<CBLEncryptable*>(FLValue_GetEncryptableValue(value))};
    }

    protected:
        CBL_REFCOUNTED_BOILERPLATE(Encryptable, RefCounted, CBLEncryptable)

    private:
        struct adopt_t {};
        inline static constexpr adopt_t adopt{};

        Encryptable(CBLEncryptable* cObj, adopt_t) {_ref = (CBLRefCounted*)cObj;}
    };

}

CBL_ASSUME_NONNULL_END

#endif // COUCHBASE_ENTERPRISE
