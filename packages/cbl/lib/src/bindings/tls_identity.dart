import 'dart:ffi';
import 'dart:typed_data';

import '../fleece/containers.dart';
import 'base.dart';
import 'cblite.dart' as cblite;
import 'cblitedart.dart' as cblitedart;
import 'fleece.dart';
import 'global.dart';
import 'slice.dart';
import 'utils.dart';

enum CBLKeyUsages {
  clientAuth(cblite.kCBLKeyUsagesClientAuth),
  serverAuth(cblite.kCBLKeyUsagesServerAuth);

  const CBLKeyUsages(this.value);

  factory CBLKeyUsages.fromValue(int value) => switch (value) {
    cblite.kCBLKeyUsagesClientAuth => clientAuth,
    cblite.kCBLKeyUsagesServerAuth => serverAuth,
    _ => throw ArgumentError('Unknown key usage: $value'),
  };

  final int value;
}

enum CBLSignatureDigestAlgorithm {
  none(0),
  sha1(5),
  sha224(8),
  sha256(9),
  sha384(10),
  sha512(11),
  ripemd160(4),
  sha3_224(16),
  sha3_256(17),
  sha3_384(18),
  sha3_512(19);

  const CBLSignatureDigestAlgorithm(this.value);

  // ignore: flutter_style_todos
  // TODO(https://github.com/cbl-dart/cbl-dart/issues/861): Remove workaround
  // for mbedTLS 3.6.5 enum renumbering.
  //
  // CBL 4.0.3 includes mbedTLS 3.6.5, which renumbered mbedtls_md_type_t to
  // align with PSA crypto API values. The CBL C header still declares the old
  // mbedTLS 2.x values, but the compiled binary passes the new 3.6.5 values
  // through the external key callbacks. We map the actual runtime values here
  // instead of using the header constants.
  factory CBLSignatureDigestAlgorithm.fromValue(int value) => switch (value) {
    0 => none,
    4 => ripemd160,
    5 => sha1,
    8 => sha224,
    9 => sha256,
    10 => sha384,
    11 => sha512,
    16 => sha3_224,
    17 => sha3_256,
    18 => sha3_384,
    19 => sha3_512,
    _ => throw ArgumentError('Unknown signature digest algorithm: $value'),
  };

  final int value;
}

final class TlsIdentityBindings {
  static String get kCBLCertAttrKeyCommonName =>
      cblite.kCBLCertAttrKeyCommonName.toDartString()!;
  static String get kCBLCertAttrKeyPseudonym =>
      cblite.kCBLCertAttrKeyPseudonym.toDartString()!;
  static String get kCBLCertAttrKeyGivenName =>
      cblite.kCBLCertAttrKeyGivenName.toDartString()!;
  static String get kCBLCertAttrKeySurname =>
      cblite.kCBLCertAttrKeySurname.toDartString()!;
  static String get kCBLCertAttrKeyOrganization =>
      cblite.kCBLCertAttrKeyOrganization.toDartString()!;
  static String get kCBLCertAttrKeyOrganizationUnit =>
      cblite.kCBLCertAttrKeyOrganizationUnit.toDartString()!;
  static String get kCBLCertAttrKeyPostalAddress =>
      cblite.kCBLCertAttrKeyPostalAddress.toDartString()!;
  static String get kCBLCertAttrKeyLocality =>
      cblite.kCBLCertAttrKeyLocality.toDartString()!;
  static String get kCBLCertAttrKeyPostalCode =>
      cblite.kCBLCertAttrKeyPostalCode.toDartString()!;
  static String get kCBLCertAttrKeyStateOrProvince =>
      cblite.kCBLCertAttrKeyStateOrProvince.toDartString()!;
  static String get kCBLCertAttrKeyCountry =>
      cblite.kCBLCertAttrKeyCountry.toDartString()!;
  static String get kCBLCertAttrKeyEmailAddress =>
      cblite.kCBLCertAttrKeyEmailAddress.toDartString()!;
  static String get kCBLCertAttrKeyHostname =>
      cblite.kCBLCertAttrKeyHostname.toDartString()!;
  static String get kCBLCertAttrKeyURL =>
      cblite.kCBLCertAttrKeyURL.toDartString()!;
  static String get kCBLCertAttrKeyIPAddress =>
      cblite.kCBLCertAttrKeyIPAddress.toDartString()!;
  static String get kCBLCertAttrKeyRegisteredID =>
      cblite.kCBLCertAttrKeyRegisteredID.toDartString()!;

  static Pointer<cblite.CBLCert> certCreateWithData(Uint8List data) =>
      cblite.CBLCert_CreateWithData(
        SliceResult.fromTypedList(data).makeGlobal().ref,
        globalCBLError..ref.reset(),
      ).checkError();

  static Pointer<cblite.CBLCert>? certNextInChain(
    Pointer<cblite.CBLCert> pointer,
  ) => cblite.CBLCert_CertNextInChain(pointer).toNullable();

  static SliceResult certData(
    Pointer<cblite.CBLCert> pointer, {
    required bool pemEncoded,
  }) =>
      SliceResult.fromFLSliceResult(cblite.CBLCert_Data(pointer, pemEncoded))!;

  static String? certSubjectNameComponent(
    Pointer<cblite.CBLCert> pointer,
    String key,
  ) => runWithSingleFLString(
    key,
    (flKey) => cblite.CBLCert_SubjectNameComponent(
      pointer,
      flKey,
    ).toDartStringAndRelease(),
  );

  static ({DateTime created, DateTime expires}) certValidTimespan(
    Pointer<cblite.CBLCert> pointer,
  ) => withGlobalArena(() {
    final outCreated = globalArena<cblite.CBLTimestamp>();
    final outExpires = globalArena<cblite.CBLTimestamp>();
    cblite.CBLCert_ValidTimespan(pointer, outCreated, outExpires);
    return (
      created: DateTime.fromMillisecondsSinceEpoch(
        outCreated.value,
        isUtc: true,
      ),
      expires: DateTime.fromMillisecondsSinceEpoch(
        outExpires.value,
        isUtc: true,
      ),
    );
  });

  static Pointer<cblite.CBLKeyPair> certPublicKey(
    Pointer<cblite.CBLCert> pointer,
  ) => cblite.CBLCert_PublicKey(pointer);

  static Pointer<cblite.CBLKeyPair> keyPairCreateWithExternalKey({
    required int keySizeInBits,
    required Object delegate,
    required cblitedart.CBLDartExternalKeyPublicKeyData publicKeyData,
    required cblitedart.CBLDartExternalKeyDecrypt decrypt,
    required cblitedart.CBLDartExternalKeySign sign,
  }) => cblitedart.CBLDartKeyPair_CreateWithExternalKey(
    keySizeInBits,
    delegate,
    publicKeyData,
    decrypt,
    sign,
    globalCBLError,
  ).checkError();

  static Pointer<cblite.CBLKeyPair> keyPairCreateWithPrivateKey(
    Uint8List privateKey, {
    String? password,
  }) => runWithSingleFLString(
    password,
    (flPassword) => cblite.CBLKeyPair_CreateWithPrivateKeyData(
      SliceResult.fromTypedList(privateKey).makeGlobal().ref,
      flPassword,
      globalCBLError..ref.reset(),
    ).checkError(),
  );

  static String? keyPairPublicKeyDigest(Pointer<cblite.CBLKeyPair> pointer) =>
      cblite.CBLKeyPair_PublicKeyDigest(pointer).toDartStringAndRelease();

  static Uint8List? keyPairPublicKeyData(Pointer<cblite.CBLKeyPair> pointer) =>
      SliceResult.fromFLSliceResult(
        cblite.CBLKeyPair_PublicKeyData(pointer),
      )?.asTypedList().let(Uint8List.fromList);

  static Uint8List? keyPairPrivateKeyData(Pointer<cblite.CBLKeyPair> pointer) =>
      SliceResult.fromFLSliceResult(
        cblite.CBLKeyPair_PrivateKeyData(pointer),
      )?.asTypedList().let(Uint8List.fromList);

  static Pointer<cblite.CBLTLSIdentity> withKeyPairAndCerts(
    Pointer<cblite.CBLKeyPair> keyPair,
    Pointer<cblite.CBLCert> certificate,
  ) => cblite.CBLTLSIdentity_IdentityWithKeyPairAndCerts(
    keyPair,
    certificate,
    globalCBLError..ref.reset(),
  ).checkError();

  static Pointer<cblite.CBLTLSIdentity> create(
    Set<CBLKeyUsages> keyUsages,
    Map<String, String> attributes,
    Duration validityDuration,
    String? label,
  ) {
    final attributesDict = MutableDict(attributes);
    return runWithSingleFLString(
      label,
      (flLabel) => cblite.CBLTLSIdentity_CreateIdentity(
        keyUsages.fold(0, (value, usage) => value | usage.value),
        attributesDict.pointer.cast(),
        validityDuration.inMilliseconds,
        flLabel,
        globalCBLError..ref.reset(),
      ).checkError(),
    );
  }

  static Pointer<cblite.CBLTLSIdentity> createWithKeyPair(
    Set<CBLKeyUsages> keyUsages,
    Map<String, String> attributes,
    Duration expiration,
    Pointer<cblite.CBLKeyPair> keyPair,
  ) {
    final attributesDict = MutableDict(attributes);
    return cblite.CBLTLSIdentity_CreateIdentityWithKeyPair(
      keyUsages.fold(0, (value, usage) => value | usage.value),
      keyPair,
      attributesDict.pointer.cast(),
      expiration.inMilliseconds,
      globalCBLError..ref.reset(),
    ).checkError();
  }

  static Pointer<cblite.CBLTLSIdentity>? withLabel(String label) =>
      runWithSingleFLString(
        label,
        (flLabel) => cblite.CBLTLSIdentity_IdentityWithLabel(
          flLabel,
          globalCBLError..ref.reset(),
        ).checkError().toNullable(),
      );

  static Pointer<cblite.CBLTLSIdentity> withCerts(
    Pointer<cblite.CBLCert> certificate,
  ) => cblite.CBLTLSIdentity_IdentityWithCerts(
    certificate,
    globalCBLError..ref.reset(),
  ).checkError();

  static void deleteWithLabel(String label) => runWithSingleFLString(
    label,
    (flLabel) => cblite.CBLTLSIdentity_DeleteIdentityWithLabel(
      flLabel,
      globalCBLError..ref.reset(),
    ).checkError(),
  );

  static Pointer<cblite.CBLCert> identityCertificates(
    Pointer<cblite.CBLTLSIdentity> pointer,
  ) => cblite.CBLTLSIdentity_Certificates(pointer);

  static DateTime identityExpiration(Pointer<cblite.CBLTLSIdentity> pointer) =>
      DateTime.fromMillisecondsSinceEpoch(
        cblite.CBLTLSIdentity_Expiration(pointer),
        isUtc: true,
      );
}
