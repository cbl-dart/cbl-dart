//
// Base.hh
//
// Copyright (c) 2019 Couchbase, Inc All rights reserved.
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
#include "cbl/CBLBase.h"
#include "fleece/slice.hh"
#include <algorithm>
#include <functional>
#include <cassert>
#include <memory>
#include <utility>

#if DEBUG
#   include "cbl/CBLLog.h"
#endif

// VOLATILE API: Couchbase Lite C++ API is not finalized, and may change in
// future releases.

CBL_ASSUME_NONNULL_BEGIN

static inline bool operator== (const CBLError &e1, const CBLError &e2) {
    if (e1.code != 0)
        return e1.domain == e2.domain && e1.code == e2.code;
    else
        return e2.code == 0;
}

namespace cbl {

    using slice = fleece::slice;
    using alloc_slice = fleece::alloc_slice;

    // Artificial base class of the C++ wrapper classes; just manages ref-counting.
    class RefCounted {
    protected:
        RefCounted() noexcept                            :_ref(nullptr) { }
        explicit RefCounted(CBLRefCounted* _cbl_nullable ref) noexcept :_ref(CBL_Retain(ref)) { }
        RefCounted(const RefCounted &other) noexcept     :_ref(CBL_Retain(other._ref)) { }
        RefCounted(RefCounted &&other) noexcept          :_ref(other._ref) {other._ref = nullptr;}
        ~RefCounted() noexcept                           {CBL_Release(_ref);}

        RefCounted& operator= (const RefCounted &other) noexcept {
            CBL_Retain(other._ref);
            CBL_Release(_ref);
            _ref = other._ref;
            return *this;
        }

        RefCounted& operator= (RefCounted &&other) noexcept {
            if (other._ref != _ref) {
                CBL_Release(_ref);
                _ref = other._ref;
                other._ref = nullptr;
            }
            return *this;
        }

        void clear()                                    {CBL_Release(_ref); _ref = nullptr;}
        bool valid() const                              {return _ref != nullptr;} \
        explicit operator bool() const                  {return valid();} \

        static std::string asString(FLSlice s)          {return slice(s).asString();}
        static std::string asString(FLSliceResult &&s)  {return alloc_slice(s).asString();}

        static void check(bool ok, CBLError &error) {
            if (!ok) {
#if DEBUG
                alloc_slice message = CBLError_Message(&error);
                CBL_Log(kCBLLogDomainDatabase, kCBLLogError, "API returning error %d/%d: %.*s",
                        error.domain, error.code, (int)message.size, (char*)message.buf);
#endif
                throw error;
            }
        }

        CBLRefCounted* _cbl_nullable _ref;

        friend class Extension;
        friend class Transaction;
    };

// Internal use only: Copy/move ctors and assignment ops that have to be declared in subclasses
#define CBL_REFCOUNTED_WITHOUT_COPY_MOVE_BOILERPLATE(CLASS, SUPER, C_TYPE) \
public: \
    CLASS() noexcept                              :SUPER() { } \
    CLASS& operator=(std::nullptr_t)              {clear(); return *this;} \
    bool valid() const                            {return RefCounted::valid();} \
    explicit operator bool() const                {return valid();} \
    bool operator==(const CLASS &other) const     {return _ref == other._ref;} \
    bool operator!=(const CLASS &other) const     {return _ref != other._ref;} \
    C_TYPE* _cbl_nullable ref() const             {return (C_TYPE*)_ref;}\
protected: \
    explicit CLASS(C_TYPE* _cbl_nullable ref)     :SUPER((CBLRefCounted*)ref) { }

#define CBL_REFCOUNTED_BOILERPLATE(CLASS, SUPER, C_TYPE) \
CBL_REFCOUNTED_WITHOUT_COPY_MOVE_BOILERPLATE(CLASS, SUPER, C_TYPE) \
public: \
    CLASS(const CLASS &other) noexcept            :SUPER(other) { } \
    CLASS(CLASS &&other) noexcept                 :SUPER((SUPER&&)other) { } \
    CLASS& operator=(const CLASS &other) noexcept {SUPER::operator=(other); return *this;} \
    CLASS& operator=(CLASS &&other) noexcept      {SUPER::operator=((SUPER&&)other); return *this;}

    /** A token representing a registered listener; instances are returned from the various
        methods that register listeners, such as \ref Database::addListener.
        When this object goes out of scope, the listener will be unregistered.
        @note ListenerToken is now allowed to copy. */
    template <class... Args>
    class ListenerToken {
    public:
        using Callback = std::function<void(Args...)>;

        ListenerToken()                                  =default;
        ~ListenerToken()                                 {CBLListener_Remove(_token);}

        ListenerToken(Callback cb)
        :_callback(new Callback(cb))
        { }

        ListenerToken(ListenerToken &&other)
        :_token(other._token),
        _callback(std::move(other._callback))
        {other._token = nullptr;}

        ListenerToken& operator=(ListenerToken &&other) {
            CBLListener_Remove(_token);
            _token = other._token;
            other._token = nullptr;
            _callback = std::move(other._callback);
            return *this;
        }

        /** Unregisters the listener early, before it leaves scope. */
        void remove() {
            CBLListener_Remove(_token);
            _token = nullptr;
            _callback = nullptr;
        }

        void* _cbl_nullable context() const             {return _callback.get();}
        CBLListenerToken* _cbl_nullable token() const   {return _token;}
        void setToken(CBLListenerToken* token)          {assert(!_token); _token = token;}

        static void call(void* _cbl_nullable context, Args... args) {
            auto listener = (Callback*)context;
            (*listener)(args...);
        }

    private:
        CBLListenerToken* _cbl_nullable _token {nullptr};
        std::shared_ptr<Callback> _callback; // Use shared_ptr instead of unique_ptr to allow to move

        ListenerToken(const ListenerToken&) =delete;
        ListenerToken& operator=(const ListenerToken &other) =delete;
    };
}

CBL_ASSUME_NONNULL_END
