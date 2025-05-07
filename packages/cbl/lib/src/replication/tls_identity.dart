import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../bindings.dart';
import '../bindings/cblite.dart' hide CBLKeyUsages;
import '../bindings/tls_identity.dart';
import '../errors.dart';
import '../support/edition.dart';
import '../support/isolate.dart';
import '../support/native_object.dart';
import '../support/utils.dart';

final _bindings = CBLBindings.instance.tlsIdentity;

/// An [object identifier](https://en.wikipedia.org/wiki/Object_identifier)
/// (OID) for use in X.509 [Certificate]s.
///
/// {@category Replication}
@immutable
class OID {
  /// Creates an OID from a list of arcs.
  OID(this.arcs) {
    if (arcs.length < 2) {
      throw ArgumentError.value(
        arcs,
        'arcs',
        'must have at least two arcs',
      );
    }
  }

  /// Parses a string representation of an OID, e.g. `1.2.840.113549`.
  factory OID.parse(String oid) {
    final arcs = <int>[];

    final arcsString = oid.split('.').toList();
    if (arcsString.length < 2) {
      throw FormatException('OID must have at least two arcs', oid);
    }

    for (final (i, string) in arcsString.indexed) {
      final arc = int.tryParse(string);
      if (arc == null || arc < 0) {
        throw FormatException('Invalid OID arc $i: $string', oid);
      }
      arcs.add(arc);
    }

    return OID(arcs);
  }

  /// Decodes an OID from a sequence of bytes, which is the DER encoding of the
  /// OID without the OID tag and length prefix.
  factory OID._fromEncodedArcs(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw ArgumentError.value(bytes, 'bytes', 'must not be empty');
    }

    return OID([
      // Decode the first two arcs from the first byte.
      bytes[0] ~/ 40, bytes[0] % 40,
      // Decode the remaining arcs from base-128.
      ..._decodeBase128List(bytes.sublist(1))
    ]);
  }

  /// The arcs of this OID, e.g. `1.2.840.113549`, represented as a list of
  /// integers.
  final List<int> arcs;

  /// Encodes the OID as a sequence of bytes in DER, but without the OID tag and
  /// length prefix.
  Uint8List get _encodedArcs => Uint8List.fromList([
        // Encode the first two arcs in the first byte.
        arcs[0] * 40 + arcs[1],
        // Encode the remaining arcs in base-128.
        for (var i = 2; i < arcs.length; i++) ..._encodeBase128(arcs[i])
      ]);

  @override
  bool operator ==(Object other) =>
      other is OID && const DeepCollectionEquality().equals(arcs, other.arcs);

  @override
  int get hashCode => const DeepCollectionEquality().hash(arcs);

  @override
  String toString() => arcs.join('.');

  static List<int> _encodeBase128(int value) {
    final result = <int>[];
    do {
      result.insert(0, value & 0x7F);
      // ignore: parameter_assignments
      value >>= 7;
    } while (value > 0);

    // Set MSB=1 on all but last byte
    for (var i = 0; i < result.length - 1; i++) {
      result[i] |= 0x80;
    }
    return result;
  }

  static List<int> _decodeBase128List(List<int> bytes) {
    final result = <int>[];
    var value = 0;
    for (final byte in bytes) {
      value = (value << 7) | (byte & 0x7F);
      if ((byte & 0x80) == 0) {
        result.add(value);
        value = 0;
      }
    }
    return result;
  }
}

/// The issuer and Subject Alternative Name (SAN) attributes of a [Certificate].
///
/// {@category Replication}
@immutable
abstract final class CertificateAttributes {
  /// Creates a new instance of [CertificateAttributes] with the given
  /// attributes.
  const factory CertificateAttributes({
    required String commonName,
    String? pseudonym,
    String? givenName,
    String? surname,
    String? organization,
    String? organizationUnit,
    String? postalAddress,
    String? locality,
    String? postalCode,
    String? stateOrProvince,
    String? country,
    String? emailAddress,
    String? hostname,
    Uri? url,
    InternetAddress? ipAddress,
    OID? registeredId,
  }) = _CertificateAttributes;

  const CertificateAttributes._();

  /// The issuer's common name, e.g. `Jane Doe` or `jane.example.com`.
  String get commonName;

  /// The issuer's pseudonym, e.g. `jdoe`.
  String? get pseudonym;

  /// The issuer's given name, e.g. `Jane`.
  String? get givenName;

  /// The issuer's surname, e.g. `Doe`.
  String? get surname;

  /// The issuer's organization, e.g. `Example Corp.`.
  String? get organization;

  /// The issuer's organization unit, e.g. `Marketing`.
  String? get organizationUnit;

  /// The issuer's postal address, e.g. `123 Example Blvd #2A`.
  String? get postalAddress;

  /// The issuer's locality, e.g. `Boston`.
  String? get locality;

  /// The issuer's postal code, e.g. `02134`.
  String? get postalCode;

  /// The issuer's state or province, e.g. `Massachusetts`.
  String? get stateOrProvince;

  /// The issuer's country, e.g. `us` (2-letter ISO country code).
  String? get country;

  /// The Subject Alternative Name (SAN) email address, e.g. `jane@example.com`.
  String? get emailAddress;

  /// The Subject Alternative Name (SAN) hostname, e.g. `example.com`.
  String? get hostname;

  /// The Subject Alternative Name (SAN) URL, e.g. `https://example.com/jane`.
  Uri? get url;

  /// The Subject Alternative Name (SAN) IP address, e.g. `1.2.3.4`.
  InternetAddress? get ipAddress;

  /// The Subject Alternative Name (SAN) registered ID, e.g. `1.2.3.4.5`.
  OID? get registeredId;

  @override
  bool operator ==(Object other) =>
      other is CertificateAttributes &&
      commonName == other.commonName &&
      pseudonym == other.pseudonym &&
      givenName == other.givenName &&
      surname == other.surname &&
      organization == other.organization &&
      organizationUnit == other.organizationUnit &&
      postalAddress == other.postalAddress &&
      locality == other.locality &&
      postalCode == other.postalCode &&
      stateOrProvince == other.stateOrProvince &&
      country == other.country &&
      emailAddress == other.emailAddress &&
      hostname == other.hostname &&
      url == other.url &&
      ipAddress == other.ipAddress &&
      registeredId == other.registeredId;

  @override
  int get hashCode =>
      commonName.hashCode ^
      pseudonym.hashCode ^
      givenName.hashCode ^
      surname.hashCode ^
      organization.hashCode ^
      organizationUnit.hashCode ^
      postalAddress.hashCode ^
      locality.hashCode ^
      postalCode.hashCode ^
      stateOrProvince.hashCode ^
      country.hashCode ^
      emailAddress.hashCode ^
      hostname.hashCode ^
      url.hashCode ^
      ipAddress.hashCode ^
      registeredId.hashCode;

  @override
  String toString() => [
        'CertificateAttributes(',
        [
          'commonName: $commonName',
          if (pseudonym case final pseudonym?) 'pseudonym: $pseudonym',
          if (givenName case final givenName?) 'givenName: $givenName',
          if (surname case final surname?) 'surname: $surname',
          if (organization case final organization?)
            'organization: $organization',
          if (organizationUnit case final organizationUnit?)
            'organizationUnit: $organizationUnit',
          if (postalAddress case final postalAddress?)
            'postalAddress: $postalAddress',
          if (locality case final locality?) 'locality: $locality',
          if (postalCode case final postalCode?) 'postalCode: $postalCode',
          if (stateOrProvince case final stateOrProvince?)
            'stateOrProvince: $stateOrProvince',
          if (country case final country?) 'country: $country',
          if (emailAddress case final emailAddress?)
            'emailAddress: $emailAddress',
          if (hostname case final hostname?) 'hostname: $hostname',
          if (url case final url?) 'url: $url',
          if (ipAddress case final ipAddress?) 'ipAddress: $ipAddress',
          if (registeredId case final registeredId?)
            'registeredId: $registeredId',
        ].join(', '),
        ')'
      ].join('');
}

final class _CertificateAttributes extends CertificateAttributes {
  const _CertificateAttributes({
    required this.commonName,
    this.pseudonym,
    this.givenName,
    this.surname,
    this.organization,
    this.organizationUnit,
    this.postalAddress,
    this.locality,
    this.postalCode,
    this.stateOrProvince,
    this.country,
    this.emailAddress,
    this.hostname,
    this.url,
    this.ipAddress,
    this.registeredId,
  }) : super._();

  @override
  final String commonName;
  @override
  final String? pseudonym;
  @override
  final String? givenName;
  @override
  final String? surname;
  @override
  final String? organization;
  @override
  final String? organizationUnit;
  @override
  final String? postalAddress;
  @override
  final String? locality;
  @override
  final String? postalCode;
  @override
  final String? stateOrProvince;
  @override
  final String? country;
  @override
  final String? emailAddress;
  @override
  final String? hostname;
  @override
  final Uri? url;
  @override
  final InternetAddress? ipAddress;
  @override
  final OID? registeredId;
}

final class _FfiCertificateAttributes extends CertificateAttributes {
  const _FfiCertificateAttributes(this._certificate) : super._();

  final FfiCertificate _certificate;

  @override
  String get commonName =>
      _certificate.attribute(_bindings.kCBLCertAttrKeyCommonName)!;

  @override
  String? get pseudonym =>
      _certificate.attribute(_bindings.kCBLCertAttrKeyPseudonym);

  @override
  String? get givenName =>
      _certificate.attribute(_bindings.kCBLCertAttrKeyGivenName);

  @override
  String? get surname =>
      _certificate.attribute(_bindings.kCBLCertAttrKeySurname);

  @override
  String? get organization =>
      _certificate.attribute(_bindings.kCBLCertAttrKeyOrganization);

  @override
  String? get organizationUnit =>
      _certificate.attribute(_bindings.kCBLCertAttrKeyOrganizationUnit);

  @override
  String? get postalAddress =>
      _certificate.attribute(_bindings.kCBLCertAttrKeyPostalAddress);

  @override
  String? get locality =>
      // TODO(blaugold): Use kCBLCertAttrKeyLocality once it is fixed in the
      // C SDK.
      // kCBLCertAttrKeyLocality does not work for reading, only for
      // passing the attribute when creating a certificate.
      // _bindings.kCBLCertAttrKeyLocality,
      _certificate.attribute('L');

  @override
  String? get postalCode =>
      _certificate.attribute(_bindings.kCBLCertAttrKeyPostalCode);

  @override
  String? get stateOrProvince =>
      _certificate.attribute(_bindings.kCBLCertAttrKeyStateOrProvince);

  @override
  String? get country =>
      _certificate.attribute(_bindings.kCBLCertAttrKeyCountry);

  @override
  String? get emailAddress =>
      _certificate.attribute(_bindings.kCBLCertAttrKeyEmailAddress);

  @override
  String? get hostname =>
      _certificate.attribute(_bindings.kCBLCertAttrKeyHostname);

  @override
  Uri? get url =>
      _certificate.attribute(_bindings.kCBLCertAttrKeyURL)?.let(Uri.parse);

  @override
  InternetAddress? get ipAddress => _certificate
      .attribute(_bindings.kCBLCertAttrKeyIPAddress)
      ?.let(_InternetAddressString.new)
      ?.address;

  @override
  OID? get registeredId => _certificate
      .attribute(_bindings.kCBLCertAttrKeyRegisteredID)
      ?.let((oid) => OID._fromEncodedArcs(Uint8List.fromList(oid.codeUnits)));
}

extension _CertificateAttributesToMapExtension on CertificateAttributes {
  Map<String, String> _toAttributesMap() => {
        _bindings.kCBLCertAttrKeyCommonName: commonName,
        if (pseudonym case final pseudonym?)
          _bindings.kCBLCertAttrKeyPseudonym: pseudonym,
        if (givenName case final givenName?)
          _bindings.kCBLCertAttrKeyGivenName: givenName,
        if (surname case final surname?)
          _bindings.kCBLCertAttrKeySurname: surname,
        if (organization case final organization?)
          _bindings.kCBLCertAttrKeyOrganization: organization,
        if (organizationUnit case final organizationUnit?)
          _bindings.kCBLCertAttrKeyOrganizationUnit: organizationUnit,
        if (postalAddress case final postalAddress?)
          _bindings.kCBLCertAttrKeyPostalAddress: postalAddress,
        if (locality case final locality?)
          _bindings.kCBLCertAttrKeyLocality: locality,
        if (postalCode case final postalCode?)
          _bindings.kCBLCertAttrKeyPostalCode: postalCode,
        if (stateOrProvince case final stateOrProvince?)
          _bindings.kCBLCertAttrKeyStateOrProvince: stateOrProvince,
        if (country case final country?)
          _bindings.kCBLCertAttrKeyCountry: country,
        if (emailAddress case final emailAddress?)
          _bindings.kCBLCertAttrKeyEmailAddress: emailAddress,
        if (hostname case final hostname?)
          _bindings.kCBLCertAttrKeyHostname: hostname,
        if (url case final url?) _bindings.kCBLCertAttrKeyURL: url.toString(),
        if (ipAddress case final ipAddress?)
          _bindings.kCBLCertAttrKeyIPAddress:
              _InternetAddressString.fromAddress(ipAddress).string,
        if (registeredId case final registeredId?)
          _bindings.kCBLCertAttrKeyRegisteredID:
              String.fromCharCodes(registeredId._encodedArcs),
      };
}

extension type _InternetAddressString(String string) {
  _InternetAddressString.fromAddress(InternetAddress address)
      : this(String.fromCharCodes(address.rawAddress));

  InternetAddress get address =>
      InternetAddress.fromRawAddress(Uint8List.fromList(string.codeUnits));
}

/// Encoded cryptographic data, such as certificates and keys.
///
/// Cryptographic data can be encoded either as [PemData] or [DerData].
///
/// {@category Replication}
abstract final class CryptoData {
  Uint8List get _data;
}

/// [PEM-encoded](https://en.wikipedia.org/wiki/Privacy-Enhanced_Mail)
/// cryptographic data.
///
/// PEM data can contain multiple objects in multiple [blocks].
///
/// {@category Replication}
final class PemData implements CryptoData {
  /// Creates a new instance of [PemData] with the given PEM [data].
  const PemData(this.data);

  /// Creates a new instance of [PemData] by concatenating the given [blocks] of
  /// PEM data.
  factory PemData.combined(Iterable<PemData> blocks) =>
      PemData(blocks.map((block) => block.data).join('\n'));

  /// The PEM data as a string.
  final String data;

  /// The individual PEM blocks contained in this data.
  ///
  /// Each returned [PemData] object contains a single PEM block.
  List<PemData> get blocks {
    final lines = data.split('\n');
    final blocks = <PemData>[];
    final currentBlock = <String>[];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        continue;
      }
      if (line.startsWith('-----BEGIN')) {
        if (currentBlock.isNotEmpty) {
          throw FormatException(
            'New PEM block found before previous block was closed:\n'
            '${currentBlock.join('\n')}',
            null,
            null,
          );
        }
        currentBlock.add(line);
      } else if (line.startsWith('-----END')) {
        currentBlock.add(line);
        blocks.add(PemData(currentBlock.join('\n')));
        currentBlock.clear();
      } else {
        currentBlock.add(line);
      }
    }

    if (currentBlock.isNotEmpty) {
      throw FormatException(
        'PEM data ended without closing PEM block:\n'
        '${currentBlock.join('\n')}',
        null,
        null,
      );
    }

    return blocks;
  }

  @override
  Uint8List get _data => utf8.encode(data);
}

/// [DER-encoded](https://en.wikipedia.org/wiki/X.690#DER_encoding)
/// cryptographic data.
///
/// {@category Replication}
final class DerData implements CryptoData {
  /// Creates a new instance of [DerData] with the given DER [data].
  const DerData(this.data);

  /// The DER data as a byte array.
  final Uint8List data;

  @override
  Uint8List get _data => data;
}

/// A X.509 certificate.
///
/// {@category Replication}
abstract final class Certificate {
  /// Decodes a [Certificate] from the given [data].
  ///
  /// [PemData] must contain a single certificate. To decode [PemData]
  /// containing multiple certificates, use [decodeMultiple].
  ///
  /// [DerData] can only contain a single certificate.
  static Future<Certificate> decode(CryptoData data) =>
      FfiCertificate.decode(data);

  /// Decodes one or more [Certificate]s from the given [data].
  ///
  /// Since [DerData] cannot contain multiple certificates, the provided data
  /// must be [PemData].
  static Future<List<Certificate>> decodeMultiple(PemData data) =>
      FfiCertificate.decodeMultiple(data);

  /// A [KeyPair] only containing the public key of this certificate.
  KeyPair get publicKey;

  /// The date when this certificate was created.
  DateTime get created;

  /// The date when this certificate expires.
  DateTime get expires;

  /// The issuer and Subject Alternative Name (SAN) attributes of this
  /// certificate.
  CertificateAttributes get attributes;

  /// Encodes this certificate as PEM data.
  PemData toPem();

  /// Encodes this certificate as DER data.
  DerData toDer();
}

final class FfiCertificate implements Certificate, Finalizable {
  FfiCertificate.fromPointer(this.pointer, {bool adopt = false}) {
    bindCBLRefCountedToDartObject(this, pointer: pointer, adopt: adopt);
  }

  static Future<FfiCertificate> _decode(CryptoData data) async {
    final pointer = await runInSecondaryIsolate(
      () => _bindings.certCreateWithData(data._data),
    );
    return FfiCertificate.fromPointer(pointer, adopt: true);
  }

  static Future<FfiCertificate> combined(
    Iterable<FfiCertificate> certificates,
  ) async {
    if (certificates.isEmpty) {
      throw ArgumentError.value(
        certificates,
        'certificates',
        'must not be empty',
      );
    }

    if (certificates.length == 1) {
      return certificates.first;
    }

    return _decode(PemData.combined(certificates.map((cert) => cert.toPem())));
  }

  static Future<FfiCertificate> decode(CryptoData data) async {
    useEnterpriseFeature(EnterpriseFeature.peerToPeerSync);

    if (data is PemData && data.blocks.length > 1) {
      throw ArgumentError.value(
        data,
        'data',
        'PEM data must contain a single block when decoding a certificate',
      );
    }

    final certificate = await _decode(data);

    assert(certificate._nextInChain == null);

    return certificate;
  }

  static Future<List<FfiCertificate>> decodeMultiple(PemData data) {
    useEnterpriseFeature(EnterpriseFeature.peerToPeerSync);
    return Future.wait(data.blocks.map(decode));
  }

  final Pointer<CBLCert> pointer;

  FfiCertificate? get _nextInChain => _bindings
      .certNextInChain(pointer)
      ?.let((pointer) => FfiCertificate.fromPointer(pointer, adopt: true));

  @override
  KeyPair get publicKey =>
      FfiKeyPair.fromPointer(_bindings.certPublicKey(pointer), adopt: true);

  @override
  DateTime get created => _bindings.certValidTimespan(pointer).created;

  @override
  DateTime get expires => _bindings.certValidTimespan(pointer).expires;

  @override
  late final CertificateAttributes attributes = _FfiCertificateAttributes(this);

  @override
  PemData toPem() =>
      PemData(_bindings.certData(pointer, pemEncoded: true).toDartString());

  @override
  DerData toDer() =>
      DerData(_bindings.certData(pointer, pemEncoded: false).asTypedList());

  String? attribute(String key) =>
      _bindings.certSubjectNameComponent(pointer, key);

  Future<List<FfiCertificate>> toList() async {
    if (_nextInChain == null) {
      return [this];
    }

    return decodeMultiple(toPem());
  }
}

/// Digest algorithms to be used when generating signatures with a private key.
///
/// {@category Replication}
enum SignatureDigestAlgorithm {
  /// No digest, just direct signature of input data.
  none,

  /// SHA-1 message digest.
  sha1,

  /// SHA-224 message digest.
  sha224,

  /// SHA-256 message digest.
  sha256,

  /// SHA-384 message digest.
  sha384,

  /// SHA-512 message digest.
  sha512,

  /// RIPEMD-160 message digest.
  ripemd160,
}

/// A [RSA](https://en.wikipedia.org/wiki/RSA_cryptosystem) public-key
/// cryptography key pair.
///
/// {@category Replication}
abstract final class KeyPair {
  /// Creates a [KeyPair] from an existing encoded [privateKey].
  ///
  /// If the [privateKey] is encrypted, a [password] must be provided to decrypt
  /// it.
  ///
  /// An encrypted [privateKey] must be in PKCS#1 format. This can be achieved
  /// by using the `-traditional` option with the
  /// [`openssl rsa`](https://docs.openssl.org/3.5/man1/openssl-rsa/) command.
  static Future<KeyPair> withPrivateKey(
    CryptoData privateKey, {
    String? password,
  }) =>
      FfiKeyPair.withPrivateKey(
        privateKey,
        password: password,
      );

  /// A hex-encoded digest of the public key.
  String get publicKeyDigest;

  /// The DER-encoded public key.
  DerData get publicKey;

  /// The DER-encoded private key, if it is known and accessible.
  DerData? get privateKey;
}

final class FfiKeyPair implements KeyPair, Finalizable {
  FfiKeyPair.fromPointer(this.pointer, {bool adopt = false}) {
    bindCBLRefCountedToDartObject(this, pointer: pointer, adopt: adopt);
  }

  static Future<KeyPair> withPrivateKey(
    CryptoData privateKey, {
    String? password,
  }) async {
    useEnterpriseFeature(EnterpriseFeature.peerToPeerSync);

    final pointer = await runInSecondaryIsolate(
      () => _bindings.keyPairCreateWithPrivateKey(
        privateKey._data,
        password: password,
      ),
    );
    return FfiKeyPair.fromPointer(pointer, adopt: true);
  }

  final Pointer<CBLKeyPair> pointer;

  @override
  String get publicKeyDigest => _bindings.keyPairPublicKeyDigest(pointer);

  @override
  DerData get publicKey => DerData(_bindings.keyPairPublicKeyData(pointer));

  @override
  DerData? get privateKey =>
      _bindings.keyPairPrivateKeyData(pointer)?.let(DerData.new);
}

/// Purpose for which a certified public key may be used.
///
/// {@category Replication}
enum KeyUsage {
  /// The public key is intended for TLS client authentication.
  clientAuth,

  /// The public key is intended for TLS server authentication.
  serverAuth;

  CBLKeyUsages _toCbl() => switch (this) {
        clientAuth => CBLKeyUsages.clientAuth,
        serverAuth => CBLKeyUsages.serverAuth,
      };
}

/// TLS identity including a [KeyPair] and X.509 [Certificate] chain used for
/// configuring TLS communication for replication.
///
/// {@category Replication}
abstract class TlsIdentity {
  /// Creates a [TlsIdentity] from an existing identity using the provided RSA
  /// [keyPair] and chain of [certificates].
  ///
  /// Certificates will not be resigned with the [keyPair]. They will be used as
  /// is.
  static Future<TlsIdentity> from({
    required KeyPair keyPair,
    required List<Certificate> certificates,
  }) =>
      FfiTlsIdentity.from(keyPair: keyPair, certificates: certificates.cast());

  /// Creates a self-signed [TlsIdentity].
  ///
  /// The [keyUsages] specify the intended use of the public key of the
  /// generated certificate.
  ///
  /// The [attributes] specify the issuer and Subject Alternative Name (SAN)
  /// attributes of the generated certificate.
  ///
  /// The [expiration] specifies the time when the certificate will expire.
  ///
  /// If [keyPair] is provided, it will be used to sign the certificate, instead
  /// of generating a new key pair.
  ///
  /// ## Persisted Identity
  ///
  /// Persisted identities are _not supported_ on Android or Linux, or when
  /// providing a [keyPair].
  ///
  /// If [label] is provided, the identity will be persisted in the platforms
  /// secure storage (Keychain on Apple platforms or CNG Key Storage Provider on
  /// Windows).
  ///
  /// To retrieve a persisted identity, use [identity].
  ///
  /// To delete a persisted identity, use [deleteIdentity].
  static Future<TlsIdentity> createIdentity({
    required Set<KeyUsage> keyUsages,
    required CertificateAttributes attributes,
    required DateTime expiration,
    String? label,
    KeyPair? keyPair,
  }) =>
      FfiTlsIdentity.createIdentity(
        keyUsages: keyUsages,
        attributes: attributes,
        expiration: expiration,
        label: label,
        keyPair: keyPair,
      );

  /// Retrieves a persisted identity with the given [label].
  ///
  /// If no identity with the given label exists, `null` is returned.
  ///
  /// Persisted identities are _not supported_ on Android or Linux.
  static Future<TlsIdentity?> identity(String label) =>
      FfiTlsIdentity.identity(label);

  /// Deletes a persisted identity with the given [label].
  ///
  /// If the identity does not exist, this method does nothing.
  ///
  /// Persisted identities are _not supported_ on Android or Linux.
  static Future<void> deleteIdentity(String label) =>
      FfiTlsIdentity.deleteIdentity(label);

  /// Retrieves an identity associated with the provided chain of [certificates]
  /// from the platform's secure storage.
  ///
  /// The [KeyPair] will be looked up by the first [Certificate] in the chain.
  ///
  /// Persisted identities are _not supported_ on Android or Linux.
  static Future<TlsIdentity> identityWithCertificates(
    List<Certificate> certificates,
  ) =>
      FfiTlsIdentity.identityWithCertificates(certificates.cast());

  /// The chain of X.509 [Certificate]s associated with this identity.
  List<Certificate> get certificates;

  /// The expiration date of the first [Certificate] in the chain associated
  /// with this identity.
  DateTime get expires;
}

final class FfiTlsIdentity implements TlsIdentity, Finalizable {
  FfiTlsIdentity._fromPointer(
    this.pointer, {
    required this.certificates,
    bool adopt = false,
  }) {
    bindCBLRefCountedToDartObject(this, pointer: pointer, adopt: adopt);
  }

  static Future<TlsIdentity> fromPointer(
    Pointer<CBLTLSIdentity> pointer, {
    bool adopt = false,
  }) async {
    final certificateChain = FfiCertificate.fromPointer(
      _bindings.identityCertificates(pointer),
      adopt: false,
    );
    final certificates = await certificateChain.toList();
    return FfiTlsIdentity._fromPointer(
      pointer,
      certificates: certificates,
      adopt: adopt,
    );
  }

  static Future<TlsIdentity> from({
    required KeyPair keyPair,
    required List<FfiCertificate> certificates,
  }) async {
    useEnterpriseFeature(EnterpriseFeature.peerToPeerSync);

    final keyPairPointer = (keyPair as FfiKeyPair).pointer;
    final certificateChainPointer =
        (await FfiCertificate.combined(certificates)).pointer;

    return FfiTlsIdentity.fromPointer(
      await runInSecondaryIsolate(
        () => _bindings.withKeyPairAndCerts(
          keyPairPointer,
          certificateChainPointer,
        ),
      ),
      adopt: true,
    );
  }

  static Future<TlsIdentity> createIdentity({
    required Set<KeyUsage> keyUsages,
    required CertificateAttributes attributes,
    required DateTime expiration,
    String? label,
    KeyPair? keyPair,
  }) async {
    useEnterpriseFeature(EnterpriseFeature.peerToPeerSync);

    if (label != null) {
      _checkPersistedIdentitySupport();

      if (keyPair != null) {
        throw DatabaseException(
          'Only one of label or keyPair can be specified.',
          DatabaseErrorCode.invalidParameter,
        );
      }
    }

    final cblKeyUsages = keyUsages.map((usage) => usage._toCbl()).toSet();
    final attributesMap = attributes._toAttributesMap();
    final expirationDuration =
        expiration.toUtc().difference(DateTime.now().toUtc());
    final keyPairPointer = (keyPair as FfiKeyPair?)?.pointer;

    return FfiTlsIdentity.fromPointer(
      await runInSecondaryIsolate(
        () => keyPairPointer != null
            ? _bindings.createWithKeyPair(
                cblKeyUsages,
                attributesMap,
                expirationDuration,
                keyPairPointer,
              )
            : _bindings.create(
                cblKeyUsages,
                attributesMap,
                expirationDuration,
                label,
              ),
      ),
      adopt: true,
    );
  }

  static Future<TlsIdentity?> identity(String label) async {
    useEnterpriseFeature(EnterpriseFeature.peerToPeerSync);
    _checkPersistedIdentitySupport();

    final pointer =
        await runInSecondaryIsolate(() => _bindings.withLabel(label));
    if (pointer == null) {
      return null;
    }

    return FfiTlsIdentity.fromPointer(pointer, adopt: true);
  }

  static Future<TlsIdentity> identityWithCertificates(
    List<FfiCertificate> certificates,
  ) async {
    useEnterpriseFeature(EnterpriseFeature.peerToPeerSync);
    _checkPersistedIdentitySupport();

    final certificatePointer =
        (await FfiCertificate.combined(certificates)).pointer;
    return FfiTlsIdentity.fromPointer(
      await runInSecondaryIsolate(
        () => _bindings.withCerts(certificatePointer),
      ),
      adopt: true,
    );
  }

  static Future<void> deleteIdentity(String label) async {
    useEnterpriseFeature(EnterpriseFeature.peerToPeerSync);
    _checkPersistedIdentitySupport();
    await runInSecondaryIsolate(() => _bindings.deleteWithLabel(label));
  }

  static void _checkPersistedIdentitySupport() {
    if (Platform.isAndroid || Platform.isLinux) {
      throw DatabaseException(
        'Persisted identities are not supported on this platform.',
        DatabaseErrorCode.unsupported,
      );
    }
  }

  final Pointer<CBLTLSIdentity> pointer;

  @override
  final List<Certificate> certificates;

  @override
  DateTime get expires => _bindings.identityExpiration(pointer);
}
