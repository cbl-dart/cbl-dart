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
#include "cbl/CBLLog.h"
#include "cbl/CBLQueryTypes.h"
#include "fleece/slice.hh"
#include <algorithm>
#include <exception>
#include <functional>
#include <cassert>
#include <memory>
#include <stdexcept>
#include <utility>


CBL_ASSUME_NONNULL_BEGIN

/** Equality for two \ref CBLError values. Two errors are equal when both indicate success
    (`code == 0`), or when they share the same `domain` and `code`. */
inline bool operator== (const CBLError &e1, const CBLError &e2) {
    if (e1.code != 0)
        return e1.domain == e2.domain && e1.code == e2.code;
    else
        return e2.code == 0;
}

namespace cbl {

    /** Convenience alias for `fleece::slice`, a non-owning view of a byte range. */
    using slice = fleece::slice;
    /** Convenience alias for `fleece::alloc_slice`, an owning byte buffer. */
    using alloc_slice = fleece::alloc_slice;

    using QueryLanguage = CBLQueryLanguage;

    // Internal base class of the C++ wrapper classes; it holds the reference to the
    // underlying ref-counted C object and manages retain/release for it.
    // Not part of the public API, and excluded from the API docs.
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
        bool valid() const                              {return _ref != nullptr;}
        explicit operator bool() const                  {return valid();}

        CBLRefCounted* _cbl_nullable _ref;

        friend class Extension;
        friend class Transaction;
    };

    /** The exception thrown by the Couchbase Lite C++ API to report a Couchbase Lite failure.
        It derives from `std::runtime_error` (and thus `std::exception`) and carries the
        failure's \ref domain and \ref code (the same values as the C API's `CBLError`), plus a
        human-readable message available via `what()`. Catch this type when you need the
        structured error information; catch `std::exception` for general handling. */
    struct Error: std::runtime_error {
        /** Constructs an Error.
            @param domain  The error domain.
            @param code    The error code, specific to the domain.
            @param what    The human-readable error message (returned by `what()`). */
        Error(CBLErrorDomain domain, int code, const std::string& what)
        : std::runtime_error(what)
        , domain(domain)
        , code(code)
        {}
        Error()
        : std::runtime_error("")
        , domain(kCBLDomain)
        , code(0)
        {}
        Error& operator=(const Error& other) {
            std::runtime_error::operator=(other);
            domain = other.domain;
            code   = other.code;
            return *this;
        }
        CBLErrorDomain domain;         ///< Domain of errors.
        int            code;           ///< Error code, specific to the domain. 0 always means no error.
    };

    namespace internal {
        inline std::string asString(FLSlice s)          {return slice(s).asString();}
        inline std::string asString(FLSliceResult &&s)  {return alloc_slice(s).asString();}

        inline void check(bool ok, CBLError &error) {
            if (!ok) {
                alloc_slice message = CBLError_Message(&error);
#if DEBUG
                CBL_Log(kCBLLogDomainDatabase, kCBLLogError, "API returning error %d/%d: %.*s",
                        error.domain, error.code, (int)message.size, (char*)message.buf);
#endif
                throw cbl::Error{error.domain, error.code, message.asString()};
            }
        }

        /** Invokes fn (typically a user-supplied C++ callback), catching and logging any exception
            it throws instead of letting it escape, and returning `false` instead. For use by
            trampolines that bridge a C++ callable into a plain C-API callback invoked from a
            context that isn't C++-exception-safe (e.g. a network/TLS layer mid-handshake, possibly
            backed by plain C underneath) -- an escaping exception there wouldn't propagate to any
            caller, it would just call std::terminate() and kill the whole process.
            @param className  The class the trampoline belongs to, used only for the log message.
            @param what  A short description of the operation, used only for the log message. */
        template <class Fn>
        inline bool invokeSafely(CBLLogDomain logDomain, const char* className, const char* what, Fn&& fn) noexcept {
            try {
                return fn();
            } catch (const cbl::Error& error) {
                CBL_Log(logDomain, kCBLLogError, "%s::%s threw error %d/%d: %s",
                        className, what, error.domain, error.code, error.what());
            } catch (const std::exception& error) {
                CBL_Log(logDomain, kCBLLogError, "%s::%s threw %s", className, what, error.what());
            } catch (...) {
                CBL_Log(logDomain, kCBLLogError, "%s::%s threw an unknown exception", className, what);
            }
            return false;
        }
    }

// For use by the cbl++ headers only: generates the public boilerplate members (ctors,
// assignment ops, comparisons, ref()) that each wrapper class must declare itself.
#define CBL_REFCOUNTED_WITHOUT_COPY_MOVE_BOILERPLATE(CLASS, SUPER, C_TYPE) \
public: \
    /** Constructs a null reference (one that points to no object). */ \
    CLASS() noexcept                              :SUPER() { } \
    /** Releases the underlying object and resets this to a null reference. */ \
    CLASS& operator=(std::nullptr_t)              {clear(); return *this;} \
    /** Returns true if this references an object, or false if it is a null reference. */ \
    bool valid() const                            {return RefCounted::valid();} \
    /** Returns true if this references an object (same as \ref valid). */ \
    explicit operator bool() const                {return valid();} \
    /** Returns true if both sides reference the same object, or are both null references. */ \
    bool operator==(const CLASS &other) const     {return _ref == other._ref;} \
    /** Returns true if the two sides reference different objects. */ \
    bool operator!=(const CLASS &other) const     {return _ref != other._ref;} \
    /** Returns a pointer to the underlying C object (C_TYPE), or NULL if this is a null reference. */ \
    C_TYPE* _cbl_nullable ref() const             {return (C_TYPE*)_ref;}\
protected: \
    /** (Internal) Constructs a reference wrapping, and retaining, a C object pointer. */ \
    explicit CLASS(C_TYPE* _cbl_nullable ref)     :SUPER((CBLRefCounted*)ref) { }

#define CBL_REFCOUNTED_BOILERPLATE(CLASS, SUPER, C_TYPE) \
CBL_REFCOUNTED_WITHOUT_COPY_MOVE_BOILERPLATE(CLASS, SUPER, C_TYPE) \
public: \
    /** Copy constructor: creates another reference to the same object as \p other. */ \
    CLASS(const CLASS &other) noexcept            :SUPER(other) { } \
    /** Move constructor: takes over the reference from \p other, leaving it a null reference. */ \
    CLASS(CLASS &&other) noexcept                 :SUPER((SUPER&&)other) { } \
    /** Copy assignment: replaces this reference with a reference to \p other's object. */ \
    CLASS& operator=(const CLASS &other) noexcept {SUPER::operator=(other); return *this;} \
    /** Move assignment: replaces this reference with \p other's, leaving \p other a null reference. */ \
    CLASS& operator=(CLASS &&other) noexcept      {SUPER::operator=((SUPER&&)other); return *this;}

    /** A token representing a registered listener; instances are returned from the various
        methods that register listeners, such as \ref Collection::addChangeListener.
        When this object goes out of scope, the listener will be unregistered.
        @note ListenerToken is not allowed to copy. */
    template <class... Args>
    class ListenerToken {
    public:
        /** The type of the user callback that this token holds. */
        using Callback = std::function<void(Args...)>;

        /** Creates an empty, unregistered token. */
        ListenerToken()                                  =default;
        /** Unregisters the listener (if any) and releases the token. */
        ~ListenerToken()                                 {CBLListener_Remove(_token);}

        /** Creates a token wrapping the given callback. The token is not yet registered with
            any listener API; call the appropriate `addListener` method to do that.
            @param cb  The callback to be invoked when notifications arrive. */
        ListenerToken(Callback cb)
        :_callback(new Callback(cb))
        { }

        /** Move-constructs a token, transferring ownership of the underlying listener registration. */
        ListenerToken(ListenerToken &&other)
        :_token(other._token),
        _callback(std::move(other._callback))
        {other._token = nullptr;}

        /** Move-assigns a token: removes this token's existing listener (if any) and adopts the
            other token's registration. */
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

        /** Returns an opaque pointer used internally as the `context` argument for C-API callbacks. */
        void* _cbl_nullable context() const             {return _callback.get();}
        /** Returns the underlying \ref CBLListenerToken (the C registration handle), or NULL
            if not registered. */
        CBLListenerToken* _cbl_nullable token() const   {return _token;}
        /** Assigns the underlying \ref CBLListenerToken returned from a C-API `AddXxxListener`
            call. May only be called once on a freshly constructed token. */
        void setToken(CBLListenerToken* token)          {assert(!_token); _token = token;}

        /** Static thunk used as the C-API callback. Forwards the call to the C++ \ref Callback
            stored in `context` (which must be a pointer returned from \ref context). */
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
