import 'dart:ffi';
import 'dart:typed_data';

import '../bindings.dart';
import '../fleece/containers.dart';
import 'base.dart';
import 'cblite.dart' as cblite_lib;
import 'cblitedart.dart' as cblitedart_lib;
import 'fleece.dart';
import 'global.dart';
import 'utils.dart';

enum CBLKeyUsages {
  clientAuth(cblite_lib.kCBLKeyUsagesClientAuth),
  serverAuth(cblite_lib.kCBLKeyUsagesServerAuth);

  const CBLKeyUsages(this.value);

  factory CBLKeyUsages.fromValue(int value) => switch (value) {
    cblite_lib.kCBLKeyUsagesClientAuth => clientAuth,
    cblite_lib.kCBLKeyUsagesServerAuth => serverAuth,
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

final class TlsIdentityBindings extends Bindings {
  TlsIdentityBindings(super.libraries);

  String get kCBLCertAttrKeyCommonName =>
      cblite.kCBLCertAttrKeyCommonName.toDartString()!;
  String get kCBLCertAttrKeyPseudonym =>
      cblite.kCBLCertAttrKeyPseudonym.toDartString()!;
  String get kCBLCertAttrKeyGivenName =>
      cblite.kCBLCertAttrKeyGivenName.toDartString()!;
  String get kCBLCertAttrKeySurname =>
      cblite.kCBLCertAttrKeySurname.toDartString()!;
  String get kCBLCertAttrKeyOrganization =>
      cblite.kCBLCertAttrKeyOrganization.toDartString()!;
  String get kCBLCertAttrKeyOrganizationUnit =>
      cblite.kCBLCertAttrKeyOrganizationUnit.toDartString()!;
  String get kCBLCertAttrKeyPostalAddress =>
      cblite.kCBLCertAttrKeyPostalAddress.toDartString()!;
  String get kCBLCertAttrKeyLocality =>
      cblite.kCBLCertAttrKeyLocality.toDartString()!;
  String get kCBLCertAttrKeyPostalCode =>
      cblite.kCBLCertAttrKeyPostalCode.toDartString()!;
  String get kCBLCertAttrKeyStateOrProvince =>
      cblite.kCBLCertAttrKeyStateOrProvince.toDartString()!;
  String get kCBLCertAttrKeyCountry =>
      cblite.kCBLCertAttrKeyCountry.toDartString()!;
  String get kCBLCertAttrKeyEmailAddress =>
      cblite.kCBLCertAttrKeyEmailAddress.toDartString()!;
  String get kCBLCertAttrKeyHostname =>
      cblite.kCBLCertAttrKeyHostname.toDartString()!;
  String get kCBLCertAttrKeyURL => cblite.kCBLCertAttrKeyURL.toDartString()!;
  String get kCBLCertAttrKeyIPAddress =>
      cblite.kCBLCertAttrKeyIPAddress.toDartString()!;
  String get kCBLCertAttrKeyRegisteredID =>
      cblite.kCBLCertAttrKeyRegisteredID.toDartString()!;

  Pointer<cblite_lib.CBLCert> certCreateWithData(Uint8List data) =>
      cblite.CBLCert_CreateWithData(
        SliceResult.fromTypedList(data).makeGlobal().ref,
        globalCBLError..ref.reset(),
      ).checkError();

  Pointer<cblite_lib.CBLCert>? certNextInChain(
    Pointer<cblite_lib.CBLCert> pointer,
  ) => cblite.CBLCert_CertNextInChain(pointer).toNullable();

  SliceResult certData(
    Pointer<cblite_lib.CBLCert> pointer, {
    required bool pemEncoded,
  }) =>
      SliceResult.fromFLSliceResult(cblite.CBLCert_Data(pointer, pemEncoded))!;

  String? certSubjectNameComponent(
    Pointer<cblite_lib.CBLCert> pointer,
    String key,
  ) => runWithSingleFLString(
    key,
    (flKey) => cblite.CBLCert_SubjectNameComponent(
      pointer,
      flKey,
    ).toDartStringAndRelease(),
  );

  ({DateTime created, DateTime expires}) certValidTimespan(
    Pointer<cblite_lib.CBLCert> pointer,
  ) => withGlobalArena(() {
    final outCreated = globalArena<cblite_lib.CBLTimestamp>();
    final outExpires = globalArena<cblite_lib.CBLTimestamp>();
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

  Pointer<cblite_lib.CBLKeyPair> certPublicKey(
    Pointer<cblite_lib.CBLCert> pointer,
  ) => cblite.CBLCert_PublicKey(pointer);

  Pointer<cblite_lib.CBLKeyPair> keyPairCreateWithExternalKey({
    required int keySizeInBits,
    required Object delegate,
    required cblitedart_lib.CBLDartExternalKeyPublicKeyData publicKeyData,
    required cblitedart_lib.CBLDartExternalKeyDecrypt decrypt,
    required cblitedart_lib.CBLDartExternalKeySign sign,
  }) => cblitedart.CBLDartKeyPair_CreateWithExternalKey(
    keySizeInBits,
    delegate,
    publicKeyData,
    decrypt,
    sign,
    globalCBLError,
  ).checkError();

  Pointer<cblite_lib.CBLKeyPair> keyPairCreateWithPrivateKey(
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

  String? keyPairPublicKeyDigest(Pointer<cblite_lib.CBLKeyPair> pointer) =>
      cblite.CBLKeyPair_PublicKeyDigest(pointer).toDartStringAndRelease();

  Uint8List? keyPairPublicKeyData(Pointer<cblite_lib.CBLKeyPair> pointer) =>
      SliceResult.fromFLSliceResult(
        cblite.CBLKeyPair_PublicKeyData(pointer),
      )?.asTypedList().let(Uint8List.fromList);

  Uint8List? keyPairPrivateKeyData(Pointer<cblite_lib.CBLKeyPair> pointer) =>
      SliceResult.fromFLSliceResult(
        cblite.CBLKeyPair_PrivateKeyData(pointer),
      )?.asTypedList().let(Uint8List.fromList);

  Pointer<cblite_lib.CBLTLSIdentity> withKeyPairAndCerts(
    Pointer<cblite_lib.CBLKeyPair> keyPair,
    Pointer<cblite_lib.CBLCert> certificate,
  ) => cblite.CBLTLSIdentity_IdentityWithKeyPairAndCerts(
    keyPair,
    certificate,
    globalCBLError..ref.reset(),
  ).checkError();

  Pointer<cblite_lib.CBLTLSIdentity> create(
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

  Pointer<cblite_lib.CBLTLSIdentity> createWithKeyPair(
    Set<CBLKeyUsages> keyUsages,
    Map<String, String> attributes,
    Duration expiration,
    Pointer<cblite_lib.CBLKeyPair> keyPair,
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

  Pointer<cblite_lib.CBLTLSIdentity>? withLabel(String label) =>
      runWithSingleFLString(
        label,
        (flLabel) => cblite.CBLTLSIdentity_IdentityWithLabel(
          flLabel,
          globalCBLError..ref.reset(),
        ).checkError().toNullable(),
      );

  Pointer<cblite_lib.CBLTLSIdentity> withCerts(
    Pointer<cblite_lib.CBLCert> certificate,
  ) => cblite.CBLTLSIdentity_IdentityWithCerts(
    certificate,
    globalCBLError..ref.reset(),
  ).checkError();

  void deleteWithLabel(String label) => runWithSingleFLString(
    label,
    (flLabel) => cblite.CBLTLSIdentity_DeleteIdentityWithLabel(
      flLabel,
      globalCBLError..ref.reset(),
    ).checkError(),
  );

  Pointer<cblite_lib.CBLCert> identityCertificates(
    Pointer<cblite_lib.CBLTLSIdentity> pointer,
  ) => cblite.CBLTLSIdentity_Certificates(pointer);

  DateTime identityExpiration(Pointer<cblite_lib.CBLTLSIdentity> pointer) =>
      DateTime.fromMillisecondsSinceEpoch(
        cblite.CBLTLSIdentity_Expiration(pointer),
        isUtc: true,
      );
}
