import 'dart:ffi';
import 'dart:typed_data';

import '../bindings.dart';
import '../fleece/containers.dart';
import 'base.dart';
import 'cblite.dart' as cblite;
import 'cblitedart.dart' as cblitedart;
import 'fleece.dart';
import 'global.dart';
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
  none(cblite.kCBLSignatureDigestNone),
  sha1(cblite.kCBLSignatureDigestSHA1),
  sha224(cblite.kCBLSignatureDigestSHA224),
  sha256(cblite.kCBLSignatureDigestSHA256),
  sha384(cblite.kCBLSignatureDigestSHA384),
  sha512(cblite.kCBLSignatureDigestSHA512),
  ripemd160(cblite.kCBLSignatureDigestRIPEMD160);

  const CBLSignatureDigestAlgorithm(this.value);

  factory CBLSignatureDigestAlgorithm.fromValue(int value) => switch (value) {
    cblite.kCBLSignatureDigestNone => none,
    cblite.kCBLSignatureDigestSHA1 => sha1,
    cblite.kCBLSignatureDigestSHA224 => sha224,
    cblite.kCBLSignatureDigestSHA256 => sha256,
    cblite.kCBLSignatureDigestSHA384 => sha384,
    cblite.kCBLSignatureDigestSHA512 => sha512,
    cblite.kCBLSignatureDigestRIPEMD160 => ripemd160,
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

  Pointer<cblite.CBLCert> certCreateWithData(Uint8List data) =>
      cblite.CBLCert_CreateWithData(
        SliceResult.fromTypedList(data).makeGlobal().ref,
        globalCBLError..ref.reset(),
      ).checkError();

  Pointer<cblite.CBLCert>? certNextInChain(Pointer<cblite.CBLCert> pointer) =>
      cblite.CBLCert_CertNextInChain(pointer).toNullable();

  SliceResult certData(
    Pointer<cblite.CBLCert> pointer, {
    required bool pemEncoded,
  }) =>
      SliceResult.fromFLSliceResult(cblite.CBLCert_Data(pointer, pemEncoded))!;

  String? certSubjectNameComponent(
    Pointer<cblite.CBLCert> pointer,
    String key,
  ) => runWithSingleFLString(
    key,
    (flKey) => cblite.CBLCert_SubjectNameComponent(
      pointer,
      flKey,
    ).toDartStringAndRelease(),
  );

  ({DateTime created, DateTime expires}) certValidTimespan(
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

  Pointer<cblite.CBLKeyPair> certPublicKey(Pointer<cblite.CBLCert> pointer) =>
      cblite.CBLCert_PublicKey(pointer);

  Pointer<cblite.CBLKeyPair> keyPairCreateWithExternalKey({
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

  Pointer<cblite.CBLKeyPair> keyPairCreateWithPrivateKey(
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

  String? keyPairPublicKeyDigest(Pointer<cblite.CBLKeyPair> pointer) =>
      cblite.CBLKeyPair_PublicKeyDigest(pointer).toDartStringAndRelease();

  Uint8List? keyPairPublicKeyData(Pointer<cblite.CBLKeyPair> pointer) =>
      SliceResult.fromFLSliceResult(
        cblite.CBLKeyPair_PublicKeyData(pointer),
      )?.asTypedList().let(Uint8List.fromList);

  Uint8List? keyPairPrivateKeyData(Pointer<cblite.CBLKeyPair> pointer) =>
      SliceResult.fromFLSliceResult(
        cblite.CBLKeyPair_PrivateKeyData(pointer),
      )?.asTypedList().let(Uint8List.fromList);

  Pointer<cblite.CBLTLSIdentity> withKeyPairAndCerts(
    Pointer<cblite.CBLKeyPair> keyPair,
    Pointer<cblite.CBLCert> certificate,
  ) => cblite.CBLTLSIdentity_IdentityWithKeyPairAndCerts(
    keyPair,
    certificate,
    globalCBLError..ref.reset(),
  ).checkError();

  Pointer<cblite.CBLTLSIdentity> create(
    Set<CBLKeyUsages> keyUsages,
    Map<String, String> attributes,
    Duration expiration,
    String? label,
  ) {
    final attributesDict = MutableDict(attributes);
    return runWithSingleFLString(
      label,
      (flLabel) => cblite.CBLTLSIdentity_CreateIdentity(
        keyUsages.fold(0, (value, usage) => value | usage.value),
        attributesDict.pointer.cast(),
        expiration.inMilliseconds,
        flLabel,
        globalCBLError..ref.reset(),
      ).checkError(),
    );
  }

  Pointer<cblite.CBLTLSIdentity> createWithKeyPair(
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

  Pointer<cblite.CBLTLSIdentity>? withLabel(String label) =>
      runWithSingleFLString(
        label,
        (flLabel) => cblite.CBLTLSIdentity_IdentityWithLabel(
          flLabel,
          globalCBLError..ref.reset(),
        ).checkError().toNullable(),
      );

  Pointer<cblite.CBLTLSIdentity> withCerts(
    Pointer<cblite.CBLCert> certificate,
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

  Pointer<cblite.CBLCert> identityCertificates(
    Pointer<cblite.CBLTLSIdentity> pointer,
  ) => cblite.CBLTLSIdentity_Certificates(pointer);

  DateTime identityExpiration(Pointer<cblite.CBLTLSIdentity> pointer) =>
      DateTime.fromMillisecondsSinceEpoch(
        cblite.CBLTLSIdentity_Expiration(pointer),
        isUtc: true,
      );
}
