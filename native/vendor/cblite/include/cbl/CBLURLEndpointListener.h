//
//  CBLURLEndpointListener.h
//
// Copyright (c) 2025 Couchbase, Inc All rights reserved.
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

#include "CBLTLSIdentity.h"

CBL_CAPI_BEGIN

/** An opaque object representing the listener authenticator. */
typedef struct CBLListenerAuthenticator CBLListenerAuthenticator;

/** Password authenticator callback for verifying client credentials when the HTTP Basic Authentication is used. */
typedef bool (*CBLListenerPasswordAuthCallback) (
    void* context,              ///< Context
    FLString username,          ///< Username
    FLString password           ///< Password
);

/** Creates a password authenticatorfor verifying client credentials when the HTTP Basic Authentication is used. */
_cbl_warn_unused CBLListenerAuthenticator* CBLListenerAuth_CreatePassword(CBLListenerPasswordAuthCallback auth,
                                                                          void* _cbl_nullable context) CBLAPI;

/** Certificate authenticator callback for verifying client certificate when the TLS client certificate authentication is used. */
typedef bool (*CBLListenerCertAuthCallback) (
    void* context,              ///< Context
    CBLCert* cert               ///< Certificate
);

/** Creates a certificate authenticator for verifying client certificate with the specified authentication callback
    when the TLS client certificate authentication is used. */
_cbl_warn_unused CBLListenerAuthenticator* CBLListenerAuth_CreateCertificate(CBLListenerCertAuthCallback auth,
                                                                             void* _cbl_nullable context) CBLAPI;

/** Creates a certificate authenticator for verifying client certificate with the specified root certificate chain to trust
    when the TLS client certificate authentication is used. */
_cbl_warn_unused CBLListenerAuthenticator* CBLListenerAuth_CreateCertificateWithRootCerts(CBLCert* rootCerts) CBLAPI;

/** Frees a CBLListenerAuthenticator object. */
void CBLListenerAuth_Free(CBLListenerAuthenticator* _cbl_nullable) CBLAPI;

/** The configuration for the URLEndpointListener. */
typedef struct {
    /** (Required) The collections available for replication . */
    CBLCollection* _cbl_nonnull * _cbl_nonnull collections;

    /** (Required) The number of collections  (Required). */
    size_t collectionCount;

    /** The port that the listener will listen to. Default value is zero which means that the listener will automatically
        select an available port to listen to when the listener is started. */
    uint16_t port;

    /** The network interface in the form of the IP Address or network interface name such as en0 that the listener will
        listen to. The default value is null slice which means that the listener will listen to all network interfaces. */
    FLString networkInterface;

    /** Disable TLS communication. The default value is false which means that TLS will be enabled by default.  */
    bool disableTLS;

    /** TLSIdentity required for TLS communication. */
    CBLTLSIdentity* _cbl_nullable tlsIdentity;

    /** The authenticator used by the listener to authenticate clients. */
    CBLListenerAuthenticator* _cbl_nullable authenticator;

    /** Allow delta sync when replicating with the listener. The default value is false. */
    bool enableDeltaSync;

    /** Allow only pull replication to pull changes from the listener. The default value is false. */
    bool readOnly;
} CBLURLEndpointListenerConfiguration;

/** An opaque object representing the listener. */
typedef struct CBLURLEndpointListener CBLURLEndpointListener;

CBL_REFCOUNTED(CBLURLEndpointListener*, URLEndpointListener);

/** Creates a URL endpoint listener with the given configuration.
 @note You are responsible for releasing the returned reference. */
_cbl_warn_unused CBLURLEndpointListener* _cbl_nullable CBLURLEndpointListener_Create(const CBLURLEndpointListenerConfiguration*, CBLError* _cbl_nullable outError) CBLAPI;

/** Gets the listener's configuration. */
const CBLURLEndpointListenerConfiguration* CBLURLEndpointListener_Config(const CBLURLEndpointListener*) CBLAPI;

/** The listening port of the listener. If the listener is not started, the port will be zero. */
uint16_t CBLURLEndpointListener_Port(const CBLURLEndpointListener*) CBLAPI;

/** The TLS identity used by the listener for TLS communication. The value will be nullptr if the listener is not started, or if the TLS is disabled.
    @note The returned identity remains valid until the listener is stopped or released.
          If you want to keep it longer, retain it with `CBLTLSIdentity_Retain`. */
CBLTLSIdentity* CBLURLEndpointListener_TLSIdentity(const CBLURLEndpointListener*) CBLAPI;

/** The possible URLs of the listener. If the listener is not started, NULL will be returned.
    @note You are responsible for releasing the returned reference. */
FLMutableArray CBLURLEndpointListener_Urls(const CBLURLEndpointListener*) CBLAPI;

/** The connection status of the listener */
typedef struct {
    uint64_t connectionCount;       ///< The total number of connections.
    uint64_t activeConnectionCount; ///< The number of the connections that are in active or busy state.
} CBLConnectionStatus;

/** Gets the current connection status of the listener. */
CBLConnectionStatus CBLURLEndpointListener_Status(const CBLURLEndpointListener*) CBLAPI;

/** Starts the listener. */
bool CBLURLEndpointListener_Start(CBLURLEndpointListener*, CBLError* _cbl_nullable outError) CBLAPI;

/** Stops the listener. */
void CBLURLEndpointListener_Stop(CBLURLEndpointListener*) CBLAPI;

CBL_CAPI_END

#endif
