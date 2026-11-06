//
// URLEndpointListener.hh
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
#include "cbl++/Collection.hh"
#include "cbl++/TLSIdentity.hh"
#include "cbl/CBLURLEndpointListener.h"
#include "fleece/Fleece.hh"
#include <functional>
#include <memory>
#include <string>
#include <string_view>
#include <variant>
#include <vector>

CBL_ASSUME_NONNULL_BEGIN

namespace cbl {

    /** An authenticator used by \ref URLEndpointListener to verify client credentials.
        \note ENTERPRISE EDITION ONLY */
    class ListenerAuthenticator {
    public:
        /** Callback for verifying client credentials via HTTP Basic Authentication. */
        using PasswordAuthCallback = std::function<bool(std::string_view username, std::string_view password)>;

        /** Callback for verifying a client's certificate when TLS client-certificate authentication is used. */
        using CertAuthCallback = std::function<bool(const Cert& cert)>;

        /** Creates an empty (null) authenticator. */
        ListenerAuthenticator() = default;

        /** Creates a password authenticator that verifies client credentials via HTTP Basic Authentication.
            @param callback  The callback used to verify a client's username/password.
            @throws cbl::Error  If callback is falsy (empty). */
        static ListenerAuthenticator passwordAuthenticator(PasswordAuthCallback callback) {
            if ( !callback ) {
                throw Error{kCBLDomain, kCBLErrorInvalidParameter, "callback must not be empty"};
            }
            return ListenerAuthenticator(std::move(callback));
        }

        /** Creates a certificate authenticator that verifies a client's certificate using the given callback.
            @param callback  The callback used to verify a client's certificate.
            @throws cbl::Error  If callback is falsy (empty). */
        static ListenerAuthenticator certAuthenticator(CertAuthCallback callback) {
            if ( !callback ) {
                throw Error{kCBLDomain, kCBLErrorInvalidParameter, "callback must not be empty"};
            }
            return ListenerAuthenticator(std::move(callback));
        }

        /** Creates a certificate authenticator that trusts any client certificate signed by the given
            root certificate chain.
            @param rootCerts  The root certificate chain to trust.
            @throws cbl::Error  If rootCerts is falsy (empty). */
        static ListenerAuthenticator certAuthenticator(const Cert& rootCerts) {
            if ( !rootCerts ) {
                throw Error{kCBLDomain, kCBLErrorInvalidParameter, "rootCerts must not be empty"};
            }
            return ListenerAuthenticator(CBLListenerAuth_CreateCertificateWithRootCerts(rootCerts.ref()));
        }

        /** Returns a pointer to the underlying C CBLListenerAuthenticator object, or NULL if this
            is an empty (null) authenticator. */
        CBLListenerAuthenticator* _cbl_nullable ref() const {return _ref.get();}

    protected:
        friend class URLEndpointListenerConfiguration;

    private:
        // The C API only accepts a plain function pointer, so PasswordAuthCallback/CertAuthCallback
        // (arbitrary capturing C++ callables) are boxed here, and a captureless static trampoline
        // (_callPasswordAuth/_callCertAuth) is handed to the C API instead, along with a pointer to
        // this box as its `context`. _callback keeps that box alive for as long as any copy of this
        // authenticator exists (see URLEndpointListener::_authenticator for why that matters).
        using Callback = std::variant<PasswordAuthCallback, CertAuthCallback>;

        explicit ListenerAuthenticator(PasswordAuthCallback callback)
        :_callback(std::make_shared<Callback>(std::move(callback)))
        {
            _ref = std::shared_ptr<CBLListenerAuthenticator>(
                CBLListenerAuth_CreatePassword(&_callPasswordAuth, _callback.get()), CBLListenerAuth_Free);
        }

        explicit ListenerAuthenticator(CertAuthCallback callback)
        :_callback(std::make_shared<Callback>(std::move(callback)))
        {
            _ref = std::shared_ptr<CBLListenerAuthenticator>(
                CBLListenerAuth_CreateCertificate(&_callCertAuth, _callback.get()), CBLListenerAuth_Free);
        }

        // For the root-certs case, which needs no callback/context at all.
        explicit ListenerAuthenticator(CBLListenerAuthenticator* _cbl_nullable auth)
        :_ref(auth, CBLListenerAuth_Free)
        { }

        // These trampolines are invoked from the network/TLS layer during a handshake -- a
        // context that isn't C++-exception-safe, since an escaping exception could call
        // std::terminate() instead of just failing this one connection attempt (the same reason
        // KeyPair's sign/decrypt/publicKeyData trampolines in TLSIdentity.hh use the same
        // internal::invokeSafely helper) -- so any exception the user's callback throws is caught,
        // logged, and turned into a plain authentication failure (false) instead.
        static bool _callPasswordAuth(void* context, FLString username, FLString password) noexcept {
            return internal::invokeSafely(kCBLLogDomainListener, "ListenerAuthenticator", "passwordAuthCallback", [&] {
                return std::get<PasswordAuthCallback>(*(Callback*)context)(slice(username), slice(password));
            });
        }

        static bool _callCertAuth(void* context, CBLCert* cert) noexcept {
            return internal::invokeSafely(kCBLLogDomainListener, "ListenerAuthenticator", "certAuthCallback", [&] {
                return std::get<CertAuthCallback>(*(Callback*)context)(Cert(cert));
            });
        }

        std::shared_ptr<CBLListenerAuthenticator> _ref;
        std::shared_ptr<Callback> _callback;
    };

    /** The configuration of a \ref URLEndpointListener.
        \note ENTERPRISE EDITION ONLY */
    class URLEndpointListenerConfiguration {
    public:
        /** Creates a configuration for the given collections.
            @param collections  The collections to make available for replication. */
        URLEndpointListenerConfiguration(std::vector<Collection> collections)
        :_collections(std::move(collections))
        { }

        //-- Accessors:

        /** Returns the configured collections. */
        std::vector<Collection> collections() const  {return _collections;}

        //-- Network:

        /** The port that the listener will listen on. The default value, zero, means the listener will
            automatically select an available port when started. */
        uint16_t port = 0;

        /** The network interface, as an IP address or a network interface name such as "en0", that the
            listener will listen on. The default value, an empty string, means the listener will listen
            on all network interfaces. */
        std::string networkInterface;

        //-- TLS:

        /** Disables TLS communication. The default value, false, means TLS is enabled by default. */
        bool disableTLS = false;

        /** The TLS identity to use for TLS communication, if \ref disableTLS is false. If left unset,
            the listener generates and uses its own anonymous self-signed identity. */
        TLSIdentity tlsIdentity;

        //-- Authentication:

        /** The authenticator used by the listener to authenticate clients, if any. */
        ListenerAuthenticator authenticator;

        //-- Replication behavior:

        /** Allows delta sync when replicating with the listener. The default value is false. */
        bool enableDeltaSync = false;

        /** Allows only pull replication, so clients may only pull changes from the listener.
            The default value is false. */
        bool readOnly = false;

    private:
        friend class URLEndpointListener;

        // Builds the C config with everything except .collections/.collectionCount, which the
        // caller (URLEndpointListener's constructor) must fill in itself: those point at a
        // CBLCollection* array whose backing storage this method has no place to keep alive
        // beyond its own return.
        CBLURLEndpointListenerConfiguration toCConfigWithoutCollections() const {
            CBLURLEndpointListenerConfiguration c{};
            c.port = port;
            if ( !networkInterface.empty() ) c.networkInterface = slice(networkInterface);
            c.disableTLS = disableTLS;
            c.tlsIdentity = tlsIdentity.ref();
            c.authenticator = authenticator.ref();
            c.enableDeltaSync = enableDeltaSync;
            c.readOnly = readOnly;
            return c;
        }

        std::vector<Collection> _collections;
    };

    /** A listener that serves the collections of local databases over the network, to enable
        peer-to-peer sync with incoming replicator connections.
        \note ENTERPRISE EDITION ONLY */
    class URLEndpointListener : protected RefCounted {
    public:
        /** The connection status of a listener: its total and active connection counts. */
        using ConnectionStatus = CBLConnectionStatus;

        /** Creates a URL endpoint listener with the given configuration.
            @param config  The listener's configuration.
            @throws cbl::Error  If the listener cannot be created. */
        explicit URLEndpointListener(const URLEndpointListenerConfiguration& config)
        :_authenticator(config.authenticator)
        {
            auto collections = config.collections();
            std::vector<CBLCollection*> cCollections;
            cCollections.reserve(collections.size());
            for ( auto& collection : collections ) cCollections.push_back(collection.ref());

            CBLURLEndpointListenerConfiguration c_config = config.toCConfigWithoutCollections();
            c_config.collections = cCollections.data();
            c_config.collectionCount = cCollections.size();

            CBLError error{};
            _ref = (CBLRefCounted*)CBLURLEndpointListener_Create(&c_config, &error);
            internal::check(_ref != nullptr, error);
        }

        /** The listening port of the listener. If the listener is not started, the port will be zero. */
        uint16_t port() const  {return CBLURLEndpointListener_Port(ref());}

        /** The TLS identity used by the listener for TLS communication, or a falsy TLSIdentity if the
            listener is not started, or if TLS is disabled.
            @note The returned identity remains valid only until the listener is stopped or released.
                  Assign it to a variable of your own if you need it to outlive that. */
        TLSIdentity tlsIdentity() const  {return TLSIdentity(CBLURLEndpointListener_TLSIdentity(ref()));}

        /** The possible URLs of the listener, or a falsy MutableArray if the listener is not started. */
        fleece::MutableArray urls() const {
            FLMutableArray flUrls = CBLURLEndpointListener_Urls(ref());
            fleece::MutableArray result(flUrls);
            FLMutableArray_Release(flUrls);
            return result;
        }

        /** Returns the current connection status of the listener. */
        ConnectionStatus status() const  {return CBLURLEndpointListener_Status(ref());}

        /** Starts the listener.
            @throws cbl::Error  If the listener cannot be started. */
        void start() {
            CBLError error{};
            internal::check(CBLURLEndpointListener_Start(ref(), &error), error);
        }

        /** Stops the listener. */
        void stop()  {CBLURLEndpointListener_Stop(ref());}

    private:
        // Keeps the authenticator's callback context alive for as long as this URLEndpointListener
        // itself lives, decoupled from the ListenerConfiguration used to construct it (which the
        // caller may reasonably discard right after construction, as with ReplicatorConfiguration).
        // This matters because the underlying C listener does NOT extend that lifetime itself: it
        // heap-allocates its own shallow copy of the CBLListenerAuthenticator struct (sharing the
        // same context pointer, see CBLURLEndpointListener_Internal.hh), so if nothing else kept the
        // original context alive, it would dangle the moment the config's ListenerAuthenticator was
        // destroyed -- unlike tlsIdentity/collections, which the listener retains via CBL_Retain.
        ListenerAuthenticator _authenticator;

        CBL_REFCOUNTED_WITHOUT_COPY_MOVE_BOILERPLATE(URLEndpointListener, RefCounted, CBLURLEndpointListener)

    public:
        /** Copy constructor. Both `*this` and `other` refer to the same underlying
            \ref CBLURLEndpointListener handle (its refcount is incremented) and share the
            authenticator's callback context. */
        URLEndpointListener(const URLEndpointListener& other) noexcept
        :RefCounted(other)
        ,_authenticator(other._authenticator)
        { }

        /** Move constructor. Takes over `other`'s \ref CBLURLEndpointListener handle and
            authenticator context, leaving `other` empty. */
        URLEndpointListener(URLEndpointListener&& other) noexcept
        :RefCounted(static_cast<RefCounted&&>(other))
        ,_authenticator(std::move(other._authenticator))
        { }

        /** Copy assignment. Releases the currently-referenced handle (if any), then makes
            `*this` refer to the same \ref CBLURLEndpointListener as `other` (refcount
            incremented) and share its authenticator context. */
        URLEndpointListener& operator=(const URLEndpointListener& other) noexcept {
            RefCounted::operator=(other);
            _authenticator = other._authenticator;
            return *this;
        }

        /** Move assignment. Releases the currently-referenced handle (if any), then takes
            over `other`'s \ref CBLURLEndpointListener handle and authenticator context;
            `other` is left empty. */
        URLEndpointListener& operator=(URLEndpointListener&& other) noexcept {
            RefCounted::operator=(static_cast<RefCounted&&>(other));
            _authenticator = std::move(other._authenticator);
            return *this;
        }
    };

}

CBL_ASSUME_NONNULL_END

#endif //#ifdef COUCHBASE_ENTERPRISE
