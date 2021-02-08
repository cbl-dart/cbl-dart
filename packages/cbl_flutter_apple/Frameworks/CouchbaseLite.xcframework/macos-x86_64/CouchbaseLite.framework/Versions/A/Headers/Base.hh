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
#include "CBLBase.h"
#include <algorithm>
#include <functional>
#include <memory>
#include <cassert>

// PLEASE NOTE: This C++ wrapper API is provided as a convenience only.
// It is not considered part of the official Couchbase Lite API.

static inline bool operator== (const CBLError &e1, const CBLError &e2) {
    if (e1.code != 0)
        return e1.domain == e2.domain && e1.code == e2.code;
    else
        return e2.code == 0;
}

namespace cbl {

    // Artificial base class of the C++ wrapper classes; just manages ref-counting.
    class RefCounted {
    protected:
        RefCounted() noexcept                            :_ref(nullptr) { }
        explicit RefCounted(CBLRefCounted *ref) noexcept :_ref(CBL_Retain(ref)) { }
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

        static void check(bool ok, CBLError &error) {
            if (!ok) {
#if DEBUG
                char *message = CBLError_Message(&error);
                CBL_Log(kCBLLogDomainAll, CBLLogError, "API returning error %d/%d: %s",
                        error.domain, error.code, message);
                free(message);
#endif
                throw error;
            }
        }

        CBLRefCounted* _ref;

        friend class Batch;
    };

// Internal use only: Copy/move ctors and assignment ops that have to be declared in subclasses
#define CBL_REFCOUNTED_BOILERPLATE(CLASS, SUPER, C_TYPE) \
public: \
    CLASS() noexcept                              :SUPER() { } \
    CLASS(const CLASS &other) noexcept            :SUPER(other) { } \
    CLASS(CLASS &&other) noexcept                 :SUPER((CLASS&&)other) { } \
    CLASS& operator=(const CLASS &other) noexcept {SUPER::operator=(other); return *this;} \
    CLASS& operator=(CLASS &&other) noexcept      {SUPER::operator=((SUPER&&)other); return *this;}\
    CLASS& operator=(std::nullptr_t)              {clear(); return *this;} \
    bool valid() const                            {return _ref != nullptr;} \
    explicit operator bool() const                {return valid();} \
    bool operator==(const CLASS &other) const     {return _ref == other._ref;} \
    bool operator!=(const CLASS &other) const     {return _ref != other._ref;} \
    C_TYPE* ref() const                           {return (C_TYPE*)_ref;}\
protected: \
    explicit CLASS(C_TYPE* ref)                   :SUPER((CBLRefCounted*)ref) { }



    /** A token representing a registered listener; instances are returned from the various
        methods that register listeners, such as \ref Database::addListener.
        When this object goes out of scope, the listener will be unregistered. */
    template <class... Args>
    class ListenerToken {
    public:
        using Callback = std::function<void(Args...)>;

        ListenerToken()                                  { }
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
            _callback = other._callback;
            other._token = nullptr;
            return *this;
        }

        /** Unregisters the listener early, before it leaves scope. */
        void remove() {
            CBLListener_Remove(_token);
            _token = nullptr;
            _callback = nullptr;
        }

        void* context() const                       {return _callback.get();}
        CBLListenerToken* token() const             {return _token;}
        void setToken(CBLListenerToken* token)      {assert(!_token); _token = token;}

        static void call(void* context, Args... args) {
            auto listener = (Callback*)context;
            (*listener)(args...);
        }

    private:
        CBLListenerToken* _token {nullptr};
        std::unique_ptr<Callback> _callback;

        ListenerToken(const ListenerToken&) =delete;
        ListenerToken& operator=(const ListenerToken &other) =delete;
    };


}
