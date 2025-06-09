//
//  CBLTLSIdentity.h
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

#ifdef __OBJC__
#import <Foundation/Foundation.h>
#import <Security/Security.h>
#endif

CBL_CAPI_BEGIN

/** \defgroup TLSIdentity   TLSIdentity
    @{
    TLSIdentity represents identity information, including an RSA key pair and certificates,
    used for server or client authentication as well as data encryption / decryption in
    TLS communication.
 
    Couchbase Lite C provides functions for generating a new self-signed identity or
    using an existing identity. Similar to other Couchbase Lite platforms, when using
    Couchbase Lite C, a generated self-signed identity can be persisted using a specified
    label in the secure key storage, depending on the operating system as follows:
 
    ##Apple (macOS and iOS) & Windows
    The generated identity will be stored in the platform’s secure key storage as follows:
    - **Apple:** The identity is stored in the Keychain.
    - **Windows:** The identity is stored in CNG Key Storage Provider
 
    ##Linux and Android
    Due to the limitation that Linux-based operating systems do not have a standard or
    common secure key storage, and Android doesn’t support native C/C++ API access
    to the default keystore, Couchbase Lite C does not support persisting generated
    identities with the specified label on these platforms.

    Alternatively, Couchbase Lite C allows developers to implement their own
    cryptographic operations through a set of callbacks, enabling certificate signing
    and data encryption / decryption using a private key stored in their preferred
    secure key storage. The key idea is that all cryptographic operations are performed
    within the secure key storage without exposing the private key.
 */

/** \name X.509 Certificates
    @{
 */

// Certificate Attribute Keys:
CBL_PUBLIC extern const FLString kCBLCertAttrKeyCommonName;        // "CN",              e.g. "Jane Doe", (or "jane.example.com")
CBL_PUBLIC extern const FLString kCBLCertAttrKeyPseudonym;         // "pseudonym",       e.g. "plainjane837"
CBL_PUBLIC extern const FLString kCBLCertAttrKeyGivenName;         // "GN",              e.g. "Jane"
CBL_PUBLIC extern const FLString kCBLCertAttrKeySurname;           // "SN",              e.g. "Doe"
CBL_PUBLIC extern const FLString kCBLCertAttrKeyOrganization;      // "O",               e.g. "Example Corp."
CBL_PUBLIC extern const FLString kCBLCertAttrKeyOrganizationUnit;  // "OU",              e.g. "Marketing"
CBL_PUBLIC extern const FLString kCBLCertAttrKeyPostalAddress;     // "postalAddress",   e.g. "123 Example Blvd #2A"
CBL_PUBLIC extern const FLString kCBLCertAttrKeyLocality;          // "L",               e.g. "Boston"
CBL_PUBLIC extern const FLString kCBLCertAttrKeyPostalCode;        // "postalCode",      e.g. "02134"
CBL_PUBLIC extern const FLString kCBLCertAttrKeyStateOrProvince;   // "ST",              e.g. "Massachusetts" (or "Quebec", ...)
CBL_PUBLIC extern const FLString kCBLCertAttrKeyCountry;           // "C",               e.g. "us" (2-letter ISO country code)

// Certificate Subject Alternative Name attribute Keys:
CBL_PUBLIC extern const FLString kCBLCertAttrKeyEmailAddress;      // "rfc822Name",      e.g. "jane@example.com"
CBL_PUBLIC extern const FLString kCBLCertAttrKeyHostname;          // "dNSName",         e.g. "www.example.com"
CBL_PUBLIC extern const FLString kCBLCertAttrKeyURL;               // "uniformResourceIdentifier", e.g. "https://example.com/jane"
CBL_PUBLIC extern const FLString kCBLCertAttrKeyIPAddress;         // "iPAddress",       e.g. An IP Address in binary format e.g. "\x0A\x00\x01\x01"
CBL_PUBLIC extern const FLString kCBLCertAttrKeyRegisteredID;      // "registeredID",    e.g. A domain-specific identifier encoded as an ASN.1 Object Identifier (OID) in DER format.

/** An opaque object representing the X.509 Certifcate. */
typedef struct CBLCert CBLCert;
CBL_REFCOUNTED(CBLCert*, Cert);

/** An opaque object representing the key pair. */
typedef struct CBLKeyPair CBLKeyPair;
CBL_REFCOUNTED(CBLKeyPair*, KeyPair);

/** Creates a CBLCert from X.509 certificate data in DER or PEM format.
    @param certData The certificate data in DER or PEM format.
    @param outError On failure, the error will be written here.
    @return A CBLCert instance on success, or NULL on failure.
    @note PEM data might consist of a series of certificates. If so, the returned CBLCert
          will represent only the first, and you can iterate over the next by calling \ref CBLCert_NextInChain.
    @note You are responsible for releasing the returned reference. */
_cbl_warn_unused
CBLCert* _cbl_nullable CBLCert_CreateWithData(FLSlice certData, CBLError* _cbl_nullable outError) CBLAPI;

/** Gets the next certificate in the chain if presents.
    @param cert The current certificate.
    @return A CBLCert instance of the next certificte in the chain, or NULL if none is presents.
    @note You are responsible for releasing the returned reference. */
_cbl_warn_unused
CBLCert* _cbl_nullable CBLCert_CertNextInChain(CBLCert* cert) CBLAPI;

/** Returns the X.509 certificate data in either DER or PEM format.
    @param cert The certificate.
    @param pemEncoded   If true, returns the data in PEM format; otherwise, returns DER format.
    @return Certificate data in either DER or PEM format.
    @note DER format can only encode a single certificate, so if this CBLCert includes multiple certificates, use PEM format to preserve them.
    @note You are responsible for releasing the returned data. */
_cbl_warn_unused
FLSliceResult CBLCert_Data(CBLCert* cert, bool pemEncoded) CBLAPI;

/** Returns the certificate's Subject Name, which identifies the cert's owner.
    This is an X.509 structured string consisting of "KEY=VALUE" pairs separated by commas,
    where the keys are attribute names. (Commas in values are backslash-escaped.)
    @param cert The certificate.
    @return The certificate's Subject Name.
    @note Rather than parsing this yourself, use \ref CBLCert_SubjectNameComponent.
    @note You are responsible for releasing the returned data. */
_cbl_warn_unused
FLSliceResult CBLCert_SubjectName(CBLCert* cert) CBLAPI;

/** Returns a component of the certificate's subject name that matches the specified attribute key.
    @param cert The certificate.
    @param attributeKey The subject name attribute key to look for
    @return A string containing the first matching component of the subject name, or NULL if not found.
    @note You are responsible for releasing the returned string. */
_cbl_warn_unused
FLSliceResult CBLCert_SubjectNameComponent(CBLCert* cert, FLString attributeKey) CBLAPI;

/** Returns the time range during which a certificate is valid.
    @param cert  The certificate.
    @param outCreated  On return, the date/time the cert became valid (was signed).
    @param outExpires  On return, the date/time at which the certificate expires. */
void CBLCert_ValidTimespan(CBLCert* cert,
                           CBLTimestamp* _cbl_nullable outCreated,
                           CBLTimestamp* _cbl_nullable outExpires) CBLAPI;

/** Returns a certificate's public key.
    @note You are responsible for releasing the returned key reference. */
_cbl_warn_unused
CBLKeyPair* CBLCert_PublicKey(CBLCert*) CBLAPI;

/** @} */

/** \name RSA Key-pair
    @{
 */

/** Digest algorithms to be used when generating signatures with a private key. */
typedef CBL_ENUM(int, CBLSignatureDigestAlgorithm) {
    kCBLSignatureDigestNone = 0,   ///< No digest, just direct signature of input data.
    kCBLSignatureDigestSHA1 = 4,   ///< SHA-1 message digest.
    kCBLSignatureDigestSHA224,     ///< SHA-224 message digest.
    kCBLSignatureDigestSHA256,     ///< SHA-256 message digest.
    kCBLSignatureDigestSHA384,     ///< SHA-384 message digest.
    kCBLSignatureDigestSHA512,     ///< SHA-512 message digest.
    kCBLSignatureDigestRIPEMD160,  ///< RIPEMD-160 message digest.
};

/** Callbacks for performing cryptographic operations with an externally managed key pair.
    These callbacks are used during certificate signing and the TLS handshake process.
    The core idea is that all private key operations are delegated to the application's secure key storage,
    ensuring that the private key is never exposed outside the key storage. */
typedef struct CBLExternalKeyCallbacks {
    /** Provides the public key data as an ASN.1 DER-encoded SubjectPublicKeyInfo structure.
        For more information, see RFC 5280: https://datatracker.ietf.org/doc/html/rfc5280
        @param externalKey  The external key pointer given to CBLKeyPair_CreateWithExternalKey.
        @param output  Where to copy the key data.
        @param outputMaxLen  Maximum length of output that can be written.
        @param outputLen  Store the length of the output here before returning.
        @return True on success, false on failure. */
    bool (*publicKeyData)(void* externalKey, void* output, size_t outputMaxLen, size_t* outputLen);
    
    /** Decrypts the input data using the private key, applying the RSA algorithm with PKCS#1 v1.5 padding.
        In some cryptographic libraries, this is referred to as “RSA/ECB/PKCS1Padding.
        @param externalKey  The external key pointer given to CBLKeyPair_CreateWithExternalKey.
        @param input  The encrypted data (size is always equal to the key size.)
        @param output  Where to write the decrypted data.
        @param outputMaxLen  Maximum length of output that can be written.
        @param outputLen  Store the length of the output here before returning.
        @return True on success, false on failure.
        @note Depending on the selected key exchange method, the decrypt() function may not be invoked
              during the TLS handshake. */
    bool (*decrypt)(void* externalKey, FLSlice input, void* output, size_t outputMaxLen, size_t* outputLen);
    
    /** Generates a signature for the input data using the private key and the PKCS#1 v1.5 padding algorithm.
        Ensure that the input data, which is already hashed based on the specified digest algorithm, is encoded as
        an ASN.1 DigestInfo structure in DER format before performing the signing operation. Some cryptographic
        libraries may handle the DigestInfo formatting internally.
        @param externalKey  The external key pointer given to CBLKeyPair_CreateWithExternalKey.
        @param digestAlgorithm  Indicates what type of digest to create the signature from.
        @param inputData The data to be signed.
        @param outSignature  Write the signature here; length must be equal to the key size.
        @return True on success, false on failure.
        @note The inputData has already been hashed; the implementation MUST NOT hash it again.
              The algorithm is provided as a reference for what was used to perform the hashing. */
    bool (*sign)(void* externalKey, CBLSignatureDigestAlgorithm digestAlgorithm, FLSlice inputData, void* outSignature);
    
    /** Called when the CBLKeyPair is released and the callback is no longer needed, so that
        your code can free any associated resources. (This callback is optionaly and may be NULL.)
        @param externalKey  The external key pointer given to CBLKeyPair_CreateWithExternalKey. */
    void (*_cbl_nullable free)(void* externalKey);
} CBLExternalKeyCallbacks;

/** Returns an RSA key pair object that wraps an external key pair managed by application code.
    All private key operations (signing and decryption) are delegated to the specified callbacks.
    @param keySizeInBits The size of the RSA key in bits (e.g., 2048 or 4096).
    @param externalKey An opaque pointer that will be passed to the callbacks. Typically a pointer to your own external key object.
    @param callbacks A set of callback functions used to perform cryptographic operations using the external key.
    @param outError On failure, the error will be written here.
    @return A CBLKeyPair instance on success, or NULL on failure.
    @note You are responsible for releasing the returned KeyPair */
_cbl_warn_unused
CBLKeyPair* _cbl_nullable CBLKeyPair_CreateWithExternalKey(size_t keySizeInBits,
                                                           void* externalKey,
                                                           CBLExternalKeyCallbacks callbacks,
                                                           CBLError* _cbl_nullable outError) CBLAPI;

/** Creates an RSA KeyPair from private key data in PEM or DER format.
    @param privateKeyData The private key data in either PEM or DER format.
    @param passwordOrNull The password used to decrypt the key, or NULL if the key is not encrypted.
    @param outError On failure, the error will be written here.
    @return A CBLKeyPair instance on success, or NULL on failure.
    @note Only PKCS#1 format for private keys is supported.
    @note You are responsible for releasig the returned KeyPair. */
_cbl_warn_unused
CBLKeyPair* _cbl_nullable CBLKeyPair_CreateWithPrivateKeyData(FLSlice privateKeyData,
                                                              FLSlice passwordOrNull,
                                                              CBLError* _cbl_nullable outError) CBLAPI;


/** Returns a hex-encoded digest of the public key.
    @param keyPair The key pair from which to extract the public key digest.
    @return A hex-encoded digest of the public key.
    @note Returns empty result if the public key digest cannot be retrieved.
    @note You are responsible for releasing the returned data. */
_cbl_warn_unused
FLSliceResult CBLKeyPair_PublicKeyDigest(CBLKeyPair* keyPair) CBLAPI;

/** Returns the public key data.
    @param keyPair The key pair from which to retrieve the public key.
    @return The public key data.
    @note Returns empty result if the public key data cannot be retrieved.
    @note You are responsible for releasing the returned data. */
_cbl_warn_unused
FLSliceResult CBLKeyPair_PublicKeyData(CBLKeyPair* keyPair) CBLAPI;

/** Returns the private key data in DER format, if the private key is known and its data is accessible.
    @param keyPair The key pair containing the private key.
    @return The private key data, or an empty slice if the key is not accessible.
    @note Persistent private keys in the secure key store generally don't have accessible data.
    @note You are responsible for releasing the returned data. */
_cbl_warn_unused
FLSliceResult CBLKeyPair_PrivateKeyData(CBLKeyPair* keyPair) CBLAPI;

/** @} */

/** \name TLS Identity
    @{
 */

/** An opaque object representing the TLSIdentity. */
typedef struct CBLTLSIdentity CBLTLSIdentity;
CBL_REFCOUNTED(CBLTLSIdentity*, TLSIdentity);


/** Returns the certificate chain associated with the given TLS identity.
    @param identity The TLS identity.
    @return The first certificate in the chain. Use CBLCert_CertNextInChain to access additional certificates. */
_cbl_warn_unused
CBLCert* CBLTLSIdentity_Certificates(CBLTLSIdentity* identity) CBLAPI;

/** Returns the date/time at which the first certificate in the chain expires. */

/** Returns the expiration date/time of the first certificate in the chain.
    @param identity The identity.
    @return The expiration timestamp of the first certificate. */
CBLTimestamp CBLTLSIdentity_Expiration(CBLTLSIdentity* identity) CBLAPI;

/** Defines key usage options for creating self-signed TLS identities.
    This enumeration specifies whether a key can be used for client or server authentication.
    The values can be combined using bitwise OR (`|`) to allow multiple usages. */
typedef CBL_OPTIONS(uint16_t, CBLKeyUsages) {
    kCBLKeyUsagesClientAuth = 0x80, ///< For client authentication.
    kCBLKeyUsagesServerAuth = 0x40  ///< For server authentication.
};

/** Creates a self-signed TLS identity using the specified certificate attributes.
    If a non-NULL label (`kFLSliceNull` indicates NULL) is provided, the identity will be persisted in
    the platform's secure key store (Keychain on Apple platforms or CNG Key Storage Provider on Windows).
    @param keyUsages The key usages for the generated identity.
    @param attributes A dictionary containing the certificate attributes.
    @param validityInMilliseconds Certificate validity duration in milliseconds.
    @param label The label used for persisting the identity in the platform's secure storage. If `kFLSliceNull` is passed, the identity will not be persisted.
    @param outError On failure, the error will be written here.
    @return A CBLTLSIdentity instance on success, or NULL on failure.
    @note A non-NULL label is not supported on Linux or Android platforms. On these platforms, passing `kFLSliceNull` for the label is required.
    @Note The Common Name (kCBLCertAttrKeyCommonName) attribute is required.
    @Note You are responsible for releasing the returned reference. */
_cbl_warn_unused
CBLTLSIdentity* _cbl_nullable CBLTLSIdentity_CreateIdentity(CBLKeyUsages keyUsages,
                                                            FLDict attributes,
                                                            int64_t validityInMilliseconds,
                                                            FLString label,
                                                            CBLError* _cbl_nullable outError) CBLAPI;

/** Creates a self-signed TLS identity using the provided RSA key pair and certificate attributes.
    @param keyUsages The key usages for the generated identity.
    @param keypair The RSA key pair to be used for generating the TLS identity.
    @param attributes A dictionary containing the certificate attributes.
    @param validityInMilliseconds Certificate validity duration in milliseconds.
    @param outError On failure, the error will be written here.
    @return A CBLTLSIdentity instance on success, or NULL on failure.
    @Note The Common Name (kCBLCertAttrKeyCommonName) attribute is required.
    @Note You are responsible for releasig the returned reference. */
_cbl_warn_unused
CBLTLSIdentity* _cbl_nullable CBLTLSIdentity_CreateIdentityWithKeyPair(CBLKeyUsages keyUsages,
                                                                       CBLKeyPair* keypair,
                                                                       FLDict attributes,
                                                                       int64_t validityInMilliseconds,
                                                                       CBLError* _cbl_nullable outError) CBLAPI;

#if !defined(__linux__) && !defined(__ANDROID__)

/** Deletes the TLS identity associated with the given persistent label from the platform's keystore
 *  (Keychain on Apple platforms or CNG Key Storage Provider on Windows).
 *  @param label The persistent label associated with the identity to be deleted.
 *  @param outError On failure, the error will be written here.
 *  @return `true` if the identity was successfully deleted, or `false` on failure.
 *  @note This function is not supported on Linux or Android platforms. */
bool CBLTLSIdentity_DeleteIdentityWithLabel(FLString label,
                                            CBLError* _cbl_nullable outError) CBLAPI;

_cbl_warn_unused
/** Retrieves a TLS identity associated with the given persistent label from the platform's keystore
 *  (Keychain on Apple platforms or CNG Key Storage Provider on Windows).
 *  @param label The persistent label associated with the identity to be deleted.
 *  @param outError On failure, the error will be written here.
 *  @return A CBLTLSIdentity instance if the identity is found and successfully retrieved,
 *          or `NULL` if the identity does not exist or an error occurs.
    @Note The Linux and Android platforms do not support this function.
    @note You are responsible for releasing the returned reference. */
CBLTLSIdentity* _cbl_nullable CBLTLSIdentity_IdentityWithLabel(FLString label,
                                                               CBLError* _cbl_nullable outError) CBLAPI;

#endif //#if !defined(__linux__) && !defined(__ANDROID__)

/** Returns a TLS identity from an existing identity using the provided RSA keypair and certificate chain.
 *  The certificate chain is used as-is; the leaf certificate is not re-signed.
 *  @param keypair A CBLKeyPair instance representing the RSA keypair to be associated with the identity.
 *  @param cert A CBLCert instance representing the certificate chain.
 *  @param outError On failure, the error will be written here.
 *  @return A CBLTLSIdentity instance on success, or `NULL` if an error occurs.
    @note You are responsible for releasing the returned reference. */
_cbl_warn_unused
CBLTLSIdentity* _cbl_nullable CBLTLSIdentity_IdentityWithKeyPairAndCerts(CBLKeyPair* keypair,
                                                                         CBLCert* cert,
                                                                         CBLError* _cbl_nullable outError) CBLAPI;

#if !defined(__linux__) && !defined(__ANDROID__)

/** Returns an existing TLS identity associated with the provided certificate chain in the keystore
 *  (Keychain for Apple or CNG Key Storage Provider for Windows). The keypair will be looked up
 *  by the first certificate in the chain.
 *  @param cert A CBLCert instance representing the certificate chain.
 *  @param outError On failure, the error will be written here.
 *  @return A CBLTLSIdentity instance on success, or `NULL` if an error occurs.
 *  @Note The Linux and Android platforms do not support this function.
 *  @note You are responsible for releasing the returned reference. */
_cbl_warn_unused
CBLTLSIdentity* _cbl_nullable CBLTLSIdentity_IdentityWithCerts(CBLCert* cert,
                                                               CBLError* _cbl_nullable outError) CBLAPI;

#endif //#if !defined(__linux__) && !defined(__ANDROID__)

#ifdef __OBJC__

/** Returns a TLS identity from existing identity in the keychain using the given SecIdentity object.
    @param secIdentity A SecIdentityRef representing the identity. The identity must be stored in the keychain.
    @param certs An optional NSArray of additional certificates (SecCertificateRef) to include in the identity's certificate chain.
    @param outError  On failure, the error will be written here.
    @return A CBLTLSIdentity instance on success, or NULL on failure.
    @note You are responsible for releasing the returned reference. */
CBLTLSIdentity* _cbl_nullable CBLTLSIdentity_IdentityWithSecIdentity(SecIdentityRef secIdentity,
                                                                     NSArray* _cbl_nullable certs,
                                                                     CBLError* _cbl_nullable outError) CBLAPI;

#endif //#ifdef __OBJC__

/** @} */

/** @} */   // end of outer \defgroup

CBL_CAPI_END

#endif // #ifdef COUCHBASE_ENTERPRISE
