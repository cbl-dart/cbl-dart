import 'dart:ffi';
import 'dart:typed_data';

import '../bindings.dart';
import '../fleece/containers.dart';
import 'base.dart';
import 'cblite.dart';
import 'fleece.dart';
import 'global.dart';
import 'utils.dart';

enum CBLKeyUsages {
  clientAuth(kCBLKeyUsagesClientAuth),
  serverAuth(kCBLKeyUsagesServerAuth);

  const CBLKeyUsages(this.value);

  factory CBLKeyUsages.fromValue(int value) => switch (value) {
        kCBLKeyUsagesClientAuth => clientAuth,
        kCBLKeyUsagesServerAuth => serverAuth,
        _ => throw ArgumentError('Unknown key usage: $value'),
      };

  final int value;
}

final class TlsIdentityBindings extends Bindings {
  TlsIdentityBindings(super.libraries);

  String get kCBLCertAttrKeyCommonName =>
      cbl.kCBLCertAttrKeyCommonName.toDartString()!;
  String get kCBLCertAttrKeyPseudonym =>
      cbl.kCBLCertAttrKeyPseudonym.toDartString()!;
  String get kCBLCertAttrKeyGivenName =>
      cbl.kCBLCertAttrKeyGivenName.toDartString()!;
  String get kCBLCertAttrKeySurname =>
      cbl.kCBLCertAttrKeySurname.toDartString()!;
  String get kCBLCertAttrKeyOrganization =>
      cbl.kCBLCertAttrKeyOrganization.toDartString()!;
  String get kCBLCertAttrKeyOrganizationUnit =>
      cbl.kCBLCertAttrKeyOrganizationUnit.toDartString()!;
  String get kCBLCertAttrKeyPostalAddress =>
      cbl.kCBLCertAttrKeyPostalAddress.toDartString()!;
  String get kCBLCertAttrKeyLocality =>
      cbl.kCBLCertAttrKeyLocality.toDartString()!;
  String get kCBLCertAttrKeyPostalCode =>
      cbl.kCBLCertAttrKeyPostalCode.toDartString()!;
  String get kCBLCertAttrKeyStateOrProvince =>
      cbl.kCBLCertAttrKeyStateOrProvince.toDartString()!;
  String get kCBLCertAttrKeyCountry =>
      cbl.kCBLCertAttrKeyCountry.toDartString()!;
  String get kCBLCertAttrKeyEmailAddress =>
      cbl.kCBLCertAttrKeyEmailAddress.toDartString()!;
  String get kCBLCertAttrKeyHostname =>
      cbl.kCBLCertAttrKeyHostname.toDartString()!;
  String get kCBLCertAttrKeyURL => cbl.kCBLCertAttrKeyURL.toDartString()!;
  String get kCBLCertAttrKeyIPAddress =>
      cbl.kCBLCertAttrKeyIPAddress.toDartString()!;
  String get kCBLCertAttrKeyRegisteredID =>
      cbl.kCBLCertAttrKeyRegisteredID.toDartString()!;

  Pointer<CBLCert> certCreateWithData(Uint8List data) =>
      cbl.CBLCert_CreateWithData(
        SliceResult.fromTypedList(data).makeGlobal().ref,
        globalCBLError..ref.reset(),
      ).checkError();

  Pointer<CBLCert>? certNextInChain(Pointer<CBLCert> pointer) =>
      cbl.CBLCert_CertNextInChain(pointer).toNullable();

  SliceResult certData(Pointer<CBLCert> pointer, {required bool pemEncoded}) =>
      SliceResult.fromFLSliceResult(cbl.CBLCert_Data(pointer, pemEncoded))!;

  String? certSubjectNameComponent(Pointer<CBLCert> pointer, String key) =>
      runWithSingleFLString(
        key,
        (flKey) => cbl.CBLCert_SubjectNameComponent(pointer, flKey)
            .toDartStringAndRelease(),
      );

  ({DateTime created, DateTime expires}) certValidTimespan(
    Pointer<CBLCert> pointer,
  ) =>
      withGlobalArena(() {
        final outCreated = globalArena<CBLTimestamp>();
        final outExpires = globalArena<CBLTimestamp>();
        cbl.CBLCert_ValidTimespan(
          pointer,
          outCreated,
          outExpires,
        );
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

  Pointer<CBLKeyPair> certPublicKey(Pointer<CBLCert> pointer) =>
      cbl.CBLCert_PublicKey(pointer);

  Pointer<CBLKeyPair> keyPairCreateWithPrivateKey(
    Uint8List privateKey, {
    String? password,
  }) =>
      runWithSingleFLString(
        password,
        (flPassword) => cbl.CBLKeyPair_CreateWithPrivateKeyData(
          SliceResult.fromTypedList(privateKey).makeGlobal().ref,
          flPassword,
          globalCBLError..ref.reset(),
        ).checkError(),
      );

  String keyPairPublicKeyDigest(Pointer<CBLKeyPair> pointer) =>
      cbl.CBLKeyPair_PublicKeyDigest(pointer).toDartStringAndRelease()!;

  Uint8List keyPairPublicKeyData(Pointer<CBLKeyPair> pointer) =>
      SliceResult.fromFLSliceResult(cbl.CBLKeyPair_PublicKeyData(pointer))!
          .asTypedList();

  Uint8List? keyPairPrivateKeyData(Pointer<CBLKeyPair> pointer) =>
      SliceResult.fromFLSliceResult(cbl.CBLKeyPair_PrivateKeyData(pointer))
          ?.asTypedList();

  Pointer<CBLTLSIdentity> withKeyPairAndCerts(
    Pointer<CBLKeyPair> keyPair,
    Pointer<CBLCert> certificate,
  ) =>
      cbl.CBLTLSIdentity_IdentityWithKeyPairAndCerts(
        keyPair,
        certificate,
        globalCBLError..ref.reset(),
      ).checkError();

  Pointer<CBLTLSIdentity> create(
    Set<CBLKeyUsages> keyUsages,
    Map<String, String> attributes,
    Duration expiration,
    String? label,
  ) {
    final attributesDict = MutableDict(attributes);
    return runWithSingleFLString(
      label,
      (flLabel) => cbl.CBLTLSIdentity_CreateIdentity(
        keyUsages.fold(0, (value, usage) => value | usage.value),
        attributesDict.pointer.cast(),
        expiration.inMilliseconds,
        flLabel,
        globalCBLError..ref.reset(),
      ).checkError(),
    );
  }

  Pointer<CBLTLSIdentity> createWithKeyPair(
    Set<CBLKeyUsages> keyUsages,
    Map<String, String> attributes,
    Duration expiration,
    Pointer<CBLKeyPair> keyPair,
  ) {
    final attributesDict = MutableDict(attributes);
    return cbl.CBLTLSIdentity_CreateIdentityWithKeyPair(
      keyUsages.fold(0, (value, usage) => value | usage.value),
      keyPair,
      attributesDict.pointer.cast(),
      expiration.inMilliseconds,
      globalCBLError..ref.reset(),
    ).checkError();
  }

  Pointer<CBLTLSIdentity>? withLabel(String label) => runWithSingleFLString(
        label,
        (flLabel) => cbl.CBLTLSIdentity_IdentityWithLabel(
          flLabel,
          globalCBLError..ref.reset(),
        ).checkError().toNullable(),
      );

  Pointer<CBLTLSIdentity> withCerts(Pointer<CBLCert> certificate) =>
      cbl.CBLTLSIdentity_IdentityWithCerts(
        certificate,
        globalCBLError..ref.reset(),
      ).checkError();

  void deleteWithLabel(String label) => runWithSingleFLString(
        label,
        (flLabel) => cbl.CBLTLSIdentity_DeleteIdentityWithLabel(
          flLabel,
          globalCBLError..ref.reset(),
        ).checkError(),
      );

  Pointer<CBLCert> identityCertificates(Pointer<CBLTLSIdentity> pointer) =>
      cbl.CBLTLSIdentity_Certificates(pointer);

  DateTime identityExpiration(Pointer<CBLTLSIdentity> pointer) =>
      DateTime.fromMillisecondsSinceEpoch(
        cbl.CBLTLSIdentity_Expiration(pointer),
        isUtc: true,
      );
}
