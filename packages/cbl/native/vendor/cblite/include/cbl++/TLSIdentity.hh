//
// TLSIdentity.hh
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
#include "cbl/CBLLog.h"
#include "cbl/CBLTLSIdentity.h"
#include "fleece/Fleece.hh"
#include <cstring>
#include <exception>
#include <functional>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
CBL_ASSUME_NONNULL_BEGIN

namespace cbl {

    /** An RSA key pair, used with \ref Cert and \ref TLSIdentity.
        \note ENTERPRISE EDITION ONLY */
    class KeyPair : protected RefCounted {
    public:
        /** Alias for the C \ref CBLSignatureDigestAlgorithm enum, used by \ref ExternalKeyHolder::SignCallback. */
        using SignatureDigestAlgorithm = CBLSignatureDigestAlgorithm;

        /** The callbacks (and optional opaque handle) needed to wrap an externally managed key
            pair, used by \ref createWithExternalKey. Move-only: constructing a KeyPair from a
            holder transfers ownership of it -- and, if \ref customFree is set, of \ref externalKey
            too -- to the resulting KeyPair, or releases them immediately if creation fails.
            @note If \ref publicKeyData, \ref decrypt, or \ref sign throws, the exception is
                  caught and logged, and the corresponding TLS operation simply fails (as if the
                  callback had returned `std::nullopt`) rather than propagating out of the library. */
        struct ExternalKeyHolder {
            /** Returns the public key as an ASN.1 DER-encoded SubjectPublicKeyInfo structure,
                or `std::nullopt` on failure. */
            using PublicKeyCallback = std::function<std::optional<alloc_slice>(void* ctx)>;

            /** Decrypts \p input (RSA/PKCS#1 v1.5) and returns the plaintext, or `std::nullopt`
                on failure. */
            using DecryptCallback = std::function<std::optional<alloc_slice>(
                    void* ctx, slice input)>;

            /** Signs the already-hashed \p input and returns the signature, whose length must
                equal the key size, or `std::nullopt` on failure. */
            using SignCallback = std::function<std::optional<alloc_slice>(
                    void* ctx, SignatureDigestAlgorithm digestAlgorithm, slice input)>;

            /** Releases \ref externalKey. Called at most once, when the holder is destroyed --
                normally when the owning KeyPair is released, but immediately instead if
                \ref createWithExternalKey fails to create one. Leave `nullptr` (the default)
                if you want to manage externalKey's lifetime yourself. */
            using FreeCallback = std::function<void(void* ctx)>;

            /** An opaque pointer passed back to every callback below, including \ref customFree. */
            void* _cbl_nullable externalKey{nullptr};
            PublicKeyCallback   publicKeyData;
            DecryptCallback     decrypt;
            SignCallback        sign;
            FreeCallback        customFree{nullptr};

            /** Constructs a holder from the given opaque key handle and callbacks.
                @param externalKey_  See \ref externalKey.
                @param publicKeyData_  See \ref publicKeyData.
                @param decrypt_  See \ref decrypt.
                @param sign_  See \ref sign.
                @param customFree_  See \ref customFree. */
            ExternalKeyHolder(void* externalKey_,
                               PublicKeyCallback publicKeyData_,
                               DecryptCallback decrypt_,
                               SignCallback sign_,
                               FreeCallback customFree_ =nullptr)
                :externalKey(externalKey_)
                ,publicKeyData(std::move(publicKeyData_))
                ,decrypt(std::move(decrypt_))
                ,sign(std::move(sign_))
                ,customFree(std::move(customFree_))
            { }

            ~ExternalKeyHolder() {
                // This destructor is implicitly noexcept, so customFree must never let an
                // exception escape it.
                if ( !customFree || !externalKey ) return;
                try {
                    customFree(externalKey);
                } catch (const cbl::Error& error) {
                    CBL_Log(kCBLLogDomainListener, kCBLLogError, "ExternalKeyHolder::customFree threw error %d/%d: %s",
                            error.domain, error.code, error.what());
                } catch (const std::exception& error) {
                    CBL_Log(kCBLLogDomainListener, kCBLLogError, "ExternalKeyHolder::customFree threw %s", error.what());
                } catch (...) {
                    CBL_Log(kCBLLogDomainListener, kCBLLogError, "ExternalKeyHolder::customFree threw an unknown exception");
                }
            }

            ExternalKeyHolder(ExternalKeyHolder&& other) noexcept
                :externalKey(other.externalKey)
                ,publicKeyData(std::move(other.publicKeyData))
                ,decrypt(std::move(other.decrypt))
                ,sign(std::move(other.sign))
                ,customFree(std::move(other.customFree))
            {
                // Null these out so the moved-from holder's destructor doesn't also free externalKey.
                other.externalKey = nullptr;
                other.customFree = nullptr;
            }

            ExternalKeyHolder(const ExternalKeyHolder&) = delete;
            ExternalKeyHolder& operator=(const ExternalKeyHolder&) = delete;
            ExternalKeyHolder& operator=(ExternalKeyHolder&&) = delete;
        };

        /** Returns a key pair that wraps an external key pair managed by application code.
            All private key operations (signing and decryption) are delegated to \p holder's
            callbacks.
            @param keySizeInBits  The size of the RSA key in bits (e.g., 2048 or 4096).
            @param holder  The external key's callbacks and opaque handle. Ownership of the holder,
                   and of its \ref ExternalKeyHolder::externalKey "externalKey" if it has a
                   \ref ExternalKeyHolder::customFree "customFree" callback, transfers to the
                   returned KeyPair -- or is released immediately if this call throws.
            @throws cbl::Error  If the key pair cannot be created. */
        static KeyPair createWithExternalKey(size_t keySizeInBits, ExternalKeyHolder&& holder) {
            // Owned by this local unique_ptr until the CBLKeyPair takes ownership (see below);
            // if creation fails, its destructor cleans this up instead of leaking it.
            std::unique_ptr<ExternalKeyContext> context(new ExternalKeyContext{std::move(holder), keySizeInBits});

            CBLExternalKeyCallbacks cCallbacks = {};
            cCallbacks.publicKeyData = [](void* rawContext, void* output, size_t outputMaxLen,
                                          size_t* outputLen) -> bool {
                return internal::invokeSafely(kCBLLogDomainListener, "ExternalKeyHolder", "publicKeyData", [&] {
                    auto& holder = ((ExternalKeyContext*)rawContext)->holder;
                    return copyResult(holder.publicKeyData(holder.externalKey), output, outputMaxLen, outputLen);
                });
            };
            cCallbacks.decrypt = [](void* rawContext, FLSlice input, void* output, size_t outputMaxLen,
                                    size_t* outputLen) -> bool {
                return internal::invokeSafely(kCBLLogDomainListener, "ExternalKeyHolder", "decrypt", [&] {
                    auto& holder = ((ExternalKeyContext*)rawContext)->holder;
                    return copyResult(holder.decrypt(holder.externalKey, input), output, outputMaxLen, outputLen);
                });
            };
            cCallbacks.sign = [](void* rawContext, CBLSignatureDigestAlgorithm digestAlgorithm,
                                 FLSlice inputData, void* outSignature) -> bool {
                return internal::invokeSafely(kCBLLogDomainListener, "ExternalKeyHolder", "sign", [&] {
                    auto* context = (ExternalKeyContext*)rawContext;
                    auto& holder  = context->holder;
                    auto  result  = holder.sign(holder.externalKey, digestAlgorithm, inputData);
                    // The signature buffer is always exactly the key size, with no length to check
                    // it against, so reject any mismatch rather than risk overrunning it.
                    if ( !result || result->size != (context->keySizeInBits + 7) / 8 ) return false;
                    memcpy(outSignature, result->buf, result->size);
                    return true;
                });
            };
            cCallbacks.free = [](void* rawContext) { delete (ExternalKeyContext*)rawContext; };

            CBLError error{};
            CBLKeyPair* kp = CBLKeyPair_CreateWithExternalKey(keySizeInBits, context.get(), cCallbacks, &error);
            internal::check(kp != nullptr, error);
            context.release();  // The CBLKeyPair now owns it, and will free it via cCallbacks.free.
            return KeyPair(kp, adopt);
        }

        /** Creates an RSA key pair from private key data in PEM or DER format.
            @param privateKeyData  The private key data, in either PEM or DER format.
            @param passwordOrNull  The password used to decrypt the key, if any.
            @note Only PKCS#1 format for private keys is supported.
            @throws cbl::Error  If the key pair cannot be created. */
        static KeyPair createWithPrivateKeyData(slice privateKeyData,
                                                 std::optional<std::string_view> passwordOrNull =std::nullopt) {
            slice password;
            if ( passwordOrNull ) password = slice(*passwordOrNull);
            CBLError error{};
            CBLKeyPair* kp = CBLKeyPair_CreateWithPrivateKeyData(privateKeyData, password, &error);
            internal::check(kp != nullptr, error);
            return KeyPair(kp, adopt);
        }

        /** Returns a hex-encoded digest of the public key, or an empty string if it's not accessible. */
        std::string publicKeyDigest() const     {return internal::asString(CBLKeyPair_PublicKeyDigest(ref()));}

        /** Returns the public key data, or an empty string if it's not accessible. */
        std::string publicKeyData() const       {return internal::asString(CBLKeyPair_PublicKeyData(ref()));}

        /** Returns the private key data in DER format, or an empty string if it's not accessible
            (e.g. for a persistent key in secure storage, or an external key). */
        std::string privateKeyData() const      {return internal::asString(CBLKeyPair_PrivateKeyData(ref()));}

    protected:
        CBL_REFCOUNTED_BOILERPLATE(KeyPair, RefCounted, CBLKeyPair)

    private:
        friend class Cert;

        struct adopt_t {};
        inline static constexpr adopt_t adopt{};

        KeyPair(CBLKeyPair* _cbl_nullable cObj, adopt_t) {_ref = (CBLRefCounted*)cObj;}

        // The heap-allocated context handed to the C API by createWithExternalKey: owns the
        // ExternalKeyHolder and remembers the key size so the sign trampoline can bounds-check
        // against it. Deleted by the CBLExternalKeyCallbacks::free trampoline.
        struct ExternalKeyContext {
            ExternalKeyHolder holder;
            size_t            keySizeInBits;
        };

        // Shared by the publicKeyData/decrypt trampolines in createWithExternalKey: copies
        // result into output (bounded by outputMaxLen) and sets outputLen.
        static bool copyResult(const std::optional<alloc_slice>& result, void* output, size_t outputMaxLen,
                               size_t* outputLen) {
            if ( !outputLen ) return false;
            if ( !result ) {
                *outputLen = 0;
                return false;
            }

            *outputLen = result->size;
            if ( result->size > outputMaxLen || (result->size > 0 && !output) ) return false;

            if ( result->size > 0 ) memcpy(output, result->buf, result->size);
            return true;
        }
    };

    /** An X.509 certificate, or the first link of a certificate chain.
        \note ENTERPRISE EDITION ONLY */
    class Cert : protected RefCounted {
    public:
        /** Creates a Cert from X.509 certificate data in DER or PEM format.
            @param certData  The certificate data, in DER or PEM format.
            @note PEM data might consist of a series of certificates; if so, the returned Cert
                  represents only the first, and \ref nextInChain accesses the rest.
            @throws cbl::Error  If the certificate cannot be parsed. */
        static Cert createWithData(slice certData) {
            CBLError error{};
            CBLCert* cert = CBLCert_CreateWithData(certData, &error);
            internal::check(cert != nullptr, error);
            return Cert(cert, adopt);
        }

        /** Returns the next certificate in the chain, or a falsy Cert if this is the last one. */
        Cert nextInChain() const {
            return Cert(CBLCert_CertNextInChain(ref()), adopt);
        }

        /** Returns the certificate data in DER or PEM format.
            @param pemEncoded  If true, returns the data in PEM format; otherwise, DER format.
            @note DER format can only encode a single certificate; if this Cert includes multiple
                  certificates, use PEM format to preserve them all. */
        alloc_slice data(bool pemEncoded =false) const {
            return CBLCert_Data(ref(), pemEncoded);
        }

        /** Returns the certificate's Subject Name, an X.509 structured string of "KEY=VALUE"
            pairs separated by commas identifying the cert's owner.
            @note Rather than parsing this yourself, use \ref subjectNameComponent. */
        std::string subjectName() const {
            return internal::asString(CBLCert_SubjectName(ref()));
        }

        /** Returns a component of the certificate's Subject Name matching the given attribute key,
            or an empty string if there is no matching component.
            @param attributeKey  The subject name attribute key to look for, e.g. \ref kCBLCertAttrKeyCommonName. */
        std::string subjectNameComponent(slice attributeKey) const {
            return internal::asString(CBLCert_SubjectNameComponent(ref(), attributeKey));
        }

        /** Returns the time range during which the certificate is valid.
            @param outCreated  On return, the date/time the cert became valid (was signed).
            @param outExpires  On return, the date/time at which the certificate expires. */
        void validTimespan(CBLTimestamp* _cbl_nullable outCreated,
                            CBLTimestamp* _cbl_nullable outExpires) const {
            CBLCert_ValidTimespan(ref(), outCreated, outExpires);
        }

        /** Returns the certificate's public key. */
        KeyPair publicKey() const {
            return KeyPair(CBLCert_PublicKey(ref()), KeyPair::adopt);
        }

    protected:
        CBL_REFCOUNTED_BOILERPLATE(Cert, RefCounted, CBLCert)

    private:
        friend class TLSIdentity;
        friend class ListenerAuthenticator;

        struct adopt_t {};
        inline static constexpr adopt_t adopt{};

        Cert(CBLCert* _cbl_nullable cObj, adopt_t) {_ref = (CBLRefCounted*)cObj;}
    };

    /** Identity information, including an RSA key pair and X.509 certificate chain, used for
        server or client authentication as well as data encryption/decryption in TLS communication.

        A generated self-signed identity can be persisted using a specified label in the
        platform's secure key storage:
        - **Apple (macOS/iOS):** The identity is stored in the Keychain.
        - **Windows:** The identity is stored in the CNG Key Storage Provider.
        - **Linux and Android:** Not supported -- Linux has no standard/common secure key
          storage, and Android doesn't support native C/C++ API access to its keystore. A
          label must not be given on these platforms.

        Alternatively, \ref KeyPair::createWithExternalKey lets you implement your own
        cryptographic operations via callbacks, enabling certificate signing and data
        encryption/decryption using a private key kept in your preferred secure key storage,
        without ever exposing the private key outside of it.

        See \ref CBLTLSIdentity.h for further platform-specific notes.
        \note ENTERPRISE EDITION ONLY */
    class TLSIdentity : protected RefCounted {
    public:
        /** Alias for the C \ref CBLKeyUsages bitmask, specifying client and/or server authentication use. */
        using KeyUsages = CBLKeyUsages;

        /** Returns the certificate chain associated with this identity: the first certificate in
            the chain. Use \ref Cert::nextInChain to access additional certificates. */
        Cert certificates() const {
            return Cert(CBLTLSIdentity_Certificates(ref()));
        }

        /** Returns the expiration date/time of the first certificate in the chain. */
        CBLTimestamp expiration() const {
            return CBLTLSIdentity_Expiration(ref());
        }

        /** Creates a self-signed TLS identity using the specified certificate attributes.
            If a label is given, the identity will be persisted in the platform's secure key store
            (Keychain on Apple platforms, or CNG Key Storage Provider on Windows).
            @param keyUsages  The key usages for the generated identity.
            @param attributes  A dictionary containing the certificate attributes. The Common Name
                   (\ref kCBLCertAttrKeyCommonName) attribute is required.
            @param validityInMilliseconds  Certificate validity duration in milliseconds.
            @param label  The label used for persisting the identity in the platform's secure storage,
                   or `std::nullopt` if it should not be persisted.
            @note A label is not supported on Linux or Android platforms.
            @throws cbl::Error  If the identity cannot be created. */
        static TLSIdentity createIdentity(KeyUsages keyUsages,
                                           fleece::Dict attributes,
                                           int64_t validityInMilliseconds,
                                           std::optional<std::string_view> label =std::nullopt) {
            slice labelSlice;
            if ( label ) labelSlice = slice(*label);
            CBLError error{};
            CBLTLSIdentity* id = CBLTLSIdentity_CreateIdentity(keyUsages, attributes,
                                                                validityInMilliseconds, labelSlice, &error);
            internal::check(id != nullptr, error);
            return TLSIdentity(id, adopt);
        }

        /** Creates a self-signed TLS identity using the provided RSA key pair and certificate attributes.
            @param keyUsages  The key usages for the generated identity.
            @param keypair  The RSA key pair to be used for generating the TLS identity.
            @param attributes  A dictionary containing the certificate attributes. The Common Name
                   (\ref kCBLCertAttrKeyCommonName) attribute is required.
            @param validityInMilliseconds  Certificate validity duration in milliseconds.
            @throws cbl::Error  If the identity cannot be created. */
        static TLSIdentity createIdentity(KeyUsages keyUsages,
                                           const KeyPair& keypair,
                                           fleece::Dict attributes,
                                           int64_t validityInMilliseconds) {
            CBLError error{};
            CBLTLSIdentity* id = CBLTLSIdentity_CreateIdentityWithKeyPair(keyUsages, keypair.ref(), attributes,
                                                                          validityInMilliseconds, &error);
            internal::check(id != nullptr, error);
            return TLSIdentity(id, adopt);
        }

        /** Returns a TLS identity built from an existing RSA key pair and certificate chain.
            The certificate chain is used as-is; the leaf certificate is not re-signed.
            @param keypair  The RSA keypair to be associated with the identity.
            @param cert  The certificate chain.
            @throws cbl::Error  If the identity cannot be created. */
        static TLSIdentity identityWithKeyPairAndCerts(const KeyPair& keypair, const Cert& cert) {
            CBLError error{};
            CBLTLSIdentity* id = CBLTLSIdentity_IdentityWithKeyPairAndCerts(keypair.ref(), cert.ref(), &error);
            internal::check(id != nullptr, error);
            return TLSIdentity(id, adopt);
        }

#if !defined(__linux__) && !defined(__ANDROID__)
        /** Deletes the TLS identity associated with the given persistent label from the platform's
            keystore (Keychain on Apple platforms, or CNG Key Storage Provider on Windows).
            @param label  The persistent label associated with the identity to be deleted.
            @return  true if the identity was deleted, or false if no such identity exists.
            @note Not supported on Linux or Android platforms.
            @throws cbl::Error  If deletion fails for a reason other than the identity not existing. */
        static bool deleteIdentityWithLabel(std::string_view label) {
            CBLError error{};
            bool deleted = CBLTLSIdentity_DeleteIdentityWithLabel(slice(label), &error);
            internal::check(deleted || error.code == 0, error);
            return deleted;
        }

        /** Retrieves the TLS identity associated with the given persistent label from the platform's
            keystore (Keychain on Apple platforms, or CNG Key Storage Provider on Windows).
            @param label  The persistent label associated with the identity.
            @return  The identity, or a falsy TLSIdentity if no such identity exists.
            @note Not supported on Linux or Android platforms.
            @throws cbl::Error  If the lookup fails for a reason other than the identity not existing. */
        static TLSIdentity identityWithLabel(std::string_view label) {
            CBLError error{};
            CBLTLSIdentity* id = CBLTLSIdentity_IdentityWithLabel(slice(label), &error);
            internal::check(id != nullptr || error.code == 0, error);
            return TLSIdentity(id, adopt);
        }

        /** Returns an existing TLS identity associated with the provided certificate chain in the
            keystore (Keychain on Apple platforms, or CNG Key Storage Provider on Windows). The key
            pair is looked up by the first certificate in the chain.
            @param cert  The certificate chain.
            @note Not supported on Linux or Android platforms.
            @throws cbl::Error  If the identity cannot be found. */
        static TLSIdentity identityWithCerts(const Cert& cert) {
            CBLError error{};
            CBLTLSIdentity* id = CBLTLSIdentity_IdentityWithCerts(cert.ref(), &error);
            internal::check(id != nullptr, error);
            return TLSIdentity(id, adopt);
        }
#endif //#if !defined(__linux__) && !defined(__ANDROID__)

#ifdef __OBJC__
        /** Returns a TLS identity from an existing identity in the keychain, given its SecIdentity object.
            @param secIdentity  The identity, which must be stored in the keychain.
            @param certs  Additional certificates (SecCertificateRef) to include in the identity's
                   certificate chain, if any.
            @throws cbl::Error  If the identity cannot be created. */
        static TLSIdentity identityWithSecIdentity(SecIdentityRef secIdentity,
                                                    NSArray* _cbl_nullable certs =nil) {
            CBLError error{};
            CBLTLSIdentity* id = CBLTLSIdentity_IdentityWithSecIdentity(secIdentity, certs, &error);
            internal::check(id != nullptr, error);
            return TLSIdentity(id, adopt);
        }
#endif //#ifdef __OBJC__

    protected:
        CBL_REFCOUNTED_BOILERPLATE(TLSIdentity, RefCounted, CBLTLSIdentity)

    private:
        friend class URLEndpointListener;

        struct adopt_t {};
        inline static constexpr adopt_t adopt{};

        TLSIdentity(CBLTLSIdentity* _cbl_nullable cObj, adopt_t) {_ref = (CBLRefCounted*)cObj;}
    };

}

CBL_ASSUME_NONNULL_END

#endif //#ifdef COUCHBASE_ENTERPRISE
