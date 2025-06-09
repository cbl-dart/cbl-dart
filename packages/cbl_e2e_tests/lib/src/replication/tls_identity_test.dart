import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cbl/cbl.dart';
import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/src/platform_check/platform_check.dart'
    as platform_check;

import '../../test_binding_impl.dart';
import '../document/blob_test.dart';
import '../test_binding.dart';
import '../utils/database_utils.dart';
import '../utils/matchers.dart';
import '../utils/replicator_utils.dart';
import 'private_keys.dart';
import 'url_endpoint_listener_test.dart';

final futureExpiration = DateTime.utc(2100);

void main() {
  setupTestBinding();

  group('PemData', () {
    test('toString', () {
      expect(privateKeyPem.toString(), 'PemData(length: 1704)');
    });

    test('==', () {
      expect(privateKeyPem, isNot(privateKeyEncryptedPem));
      expect(privateKeyPem, isNot(privateKeyDer));
      expect(privateKeyPem, privateKeyPem);
    });

    test('hashCode', () {
      expect(privateKeyPem.hashCode, isNot(privateKeyEncryptedPem.hashCode));
      expect(privateKeyPem.hashCode, isNot(privateKeyDer.hashCode));
      expect(privateKeyPem.hashCode, privateKeyPem.hashCode);
    });
  });

  group('DerData', () {
    test('toString', () {
      expect(privateKeyDer.toString(), 'DerData(length: 1218)');
    });

    test('==', () {
      expect(privateKeyDer, isNot(privateKeyPem));
      expect(privateKeyDer, isNot(privateKeyEncryptedPem));
      expect(privateKeyDer, privateKeyDer);
    });

    test('hashCode', () {
      expect(privateKeyDer.hashCode, isNot(privateKeyPem.hashCode));
      expect(privateKeyDer.hashCode, isNot(privateKeyEncryptedPem.hashCode));
      expect(privateKeyDer.hashCode, privateKeyDer.hashCode);
    });
  });

  group('OID', () {
    test('fromString', () {
      expect(OID.parse('1.2.3.4.5'), OID(const [1, 2, 3, 4, 5]));
      expect(() => OID.parse(''), throwsA(isA<FormatException>()));
      expect(() => OID.parse('1'), throwsA(isA<FormatException>()));
      expect(() => OID.parse('1.x'), throwsA(isA<FormatException>()));
    });

    test('toString', () {
      expect(OID(const [1, 2, 3, 4, 5]).toString(), '1.2.3.4.5');
    });

    test('==', () {
      expect(OID(const [1, 2, 3, 4, 5]), isNot(OID(const [1, 2, 3, 4])));
      expect(OID(const [1, 2, 3, 4]), isNot(OID(const [1, 2, 3, 4, 5])));
      expect(OID(const [1, 2, 3, 4]), OID(const [1, 2, 3, 4]));
    });

    test('hashCode', () {
      expect(
        OID(const [1, 2, 3, 4, 5]).hashCode,
        isNot(OID(const [1, 2, 3, 4]).hashCode),
      );
      expect(
        OID(const [1, 2, 3, 4]).hashCode,
        isNot(OID(const [1, 2, 3, 4, 5]).hashCode),
      );
      expect(
        OID(const [1, 2, 3, 4]).hashCode,
        OID(const [1, 2, 3, 4]).hashCode,
      );
    });
  });

  group('CertificateAttributes', () {
    test('create certificate and read attributes back', () async {
      final attributes = CertificateAttributes(
        commonName: 'Test',
        pseudonym: 'Pseudonym',
        givenName: 'GivenName',
        surname: 'Surname',
        organization: 'Organization',
        organizationUnit: 'OrganizationUnit',
        postalAddress: 'PostalAddress',
        locality: 'Locality',
        postalCode: 'PostalCode',
        stateOrProvince: 'StateOrProvince',
        country: 'Country',
        emailAddress: 'EmailAddress',
        hostname: 'Hostname, A',
        url: Uri.parse('https://example.com'),
        ipAddress: InternetAddress('1.2.3.4'),
        registeredId: OID(const [1, 2, 3, 4, 5]),
      );
      final identity = await TlsIdentity.createIdentity(
        keyUsages: {KeyUsage.serverAuth},
        attributes: attributes,
        expiration: futureExpiration,
      );
      expect(identity.certificates.single.attributes, attributes);
    });

    test('==', () {
      final attributes = CertificateAttributes(
        commonName: 'Test',
        pseudonym: 'Pseudonym',
        givenName: 'GivenName',
        surname: 'Surname',
        organization: 'Organization',
        organizationUnit: 'OrganizationUnit',
        postalAddress: 'PostalAddress',
        locality: 'Locality',
        postalCode: 'PostalCode',
        stateOrProvince: 'StateOrProvince',
        country: 'Country',
        emailAddress: 'EmailAddress',
        hostname: 'Hostname',
        url: Uri.parse('https://example.com'),
        ipAddress: InternetAddress('1.2.3.4'),
        registeredId: OID(const [1, 2, 3, 4, 5]),
      );
      expect(attributes, same(attributes));

      final identicalAttributes = CertificateAttributes(
        commonName: 'Test',
        pseudonym: 'Pseudonym',
        givenName: 'GivenName',
        surname: 'Surname',
        organization: 'Organization',
        organizationUnit: 'OrganizationUnit',
        postalAddress: 'PostalAddress',
        locality: 'Locality',
        postalCode: 'PostalCode',
        stateOrProvince: 'StateOrProvince',
        country: 'Country',
        emailAddress: 'EmailAddress',
        hostname: 'Hostname',
        url: Uri.parse('https://example.com'),
        ipAddress: InternetAddress('1.2.3.4'),
        registeredId: OID(const [1, 2, 3, 4, 5]),
      );
      expect(identicalAttributes, isNot(same(attributes)));
      expect(attributes, identicalAttributes);
      expect(identicalAttributes, attributes);

      const differentAttributes = CertificateAttributes(
        commonName: 'OtherTest',
      );
      expect(attributes, isNot(differentAttributes));
      expect(differentAttributes, isNot(attributes));
    });

    test('hashCode', () {
      final attributes = CertificateAttributes(
        commonName: 'Test',
        pseudonym: 'Pseudonym',
        givenName: 'GivenName',
        surname: 'Surname',
        organization: 'Organization',
        organizationUnit: 'OrganizationUnit',
        postalAddress: 'PostalAddress',
        locality: 'Locality',
        postalCode: 'PostalCode',
        stateOrProvince: 'StateOrProvince',
        country: 'Country',
        emailAddress: 'EmailAddress',
        hostname: 'Hostname',
        url: Uri.parse('https://example.com'),
        ipAddress: InternetAddress('1.2.3.4'),
        registeredId: OID(const [1, 2, 3, 4, 5]),
      );

      final identicalAttributes = CertificateAttributes(
        commonName: 'Test',
        pseudonym: 'Pseudonym',
        givenName: 'GivenName',
        surname: 'Surname',
        organization: 'Organization',
        organizationUnit: 'OrganizationUnit',
        postalAddress: 'PostalAddress',
        locality: 'Locality',
        postalCode: 'PostalCode',
        stateOrProvince: 'StateOrProvince',
        country: 'Country',
        emailAddress: 'EmailAddress',
        hostname: 'Hostname',
        url: Uri.parse('https://example.com'),
        ipAddress: InternetAddress('1.2.3.4'),
        registeredId: OID(const [1, 2, 3, 4, 5]),
      );

      const differentAttributes = CertificateAttributes(
        commonName: 'OtherTest',
      );

      expect(attributes.hashCode, identicalAttributes.hashCode);
      expect(attributes.hashCode, isNot(differentAttributes.hashCode));
    });

    test('toString', () {
      final attributes = CertificateAttributes(
        commonName: 'Test',
        pseudonym: 'Pseudonym',
        givenName: 'GivenName',
        surname: 'Surname',
        organization: 'Organization',
        organizationUnit: 'OrganizationUnit',
        postalAddress: 'PostalAddress',
        locality: 'Locality',
        postalCode: 'PostalCode',
        stateOrProvince: 'StateOrProvince',
        country: 'Country',
        emailAddress: 'EmailAddress',
        hostname: 'Hostname',
        url: Uri.parse('https://example.com'),
        ipAddress: InternetAddress('1.2.3.4'),
        registeredId: OID(const [1, 2, 3, 4, 5]),
      );
      expect(
        attributes.toString(),
        'CertificateAttributes('
        'commonName: Test, '
        'pseudonym: Pseudonym, '
        'givenName: GivenName, '
        'surname: Surname, '
        'organization: Organization, '
        'organizationUnit: OrganizationUnit, '
        'postalAddress: PostalAddress, '
        'locality: Locality, '
        'postalCode: PostalCode, '
        'stateOrProvince: StateOrProvince, '
        'country: Country, '
        'emailAddress: EmailAddress, '
        'hostname: Hostname, '
        'url: https://example.com, '
        "ipAddress: InternetAddress('1.2.3.4', IPv4), "
        // ignore: missing_whitespace_between_adjacent_strings
        'registeredId: 1.2.3.4.5'
        ')',
      );
    });
  });

  group('Certificate', () {
    test('decode PEM', () async {
      final identity = await TlsIdentity.createIdentity(
        keyUsages: {KeyUsage.serverAuth},
        attributes: const CertificateAttributes(commonName: 'Test'),
        expiration: futureExpiration,
      );
      final certificate = identity.certificates.single;
      final decodedCertificate = Certificate.decode(certificate.toPem());
      expect(decodedCertificate.created, certificate.created);
      expect(decodedCertificate.expires, certificate.expires);
      expect(decodedCertificate.attributes, certificate.attributes);
    });

    test('decode DER', () async {
      final identity = await TlsIdentity.createIdentity(
        keyUsages: {KeyUsage.serverAuth},
        attributes: const CertificateAttributes(commonName: 'Test'),
        expiration: futureExpiration,
      );
      final certificate = identity.certificates.single;
      final decodedCertificate = Certificate.decode(certificate.toDer());
      expect(decodedCertificate.created, certificate.created);
      expect(decodedCertificate.expires, certificate.expires);
      expect(decodedCertificate.attributes, certificate.attributes);
    });

    test('decodeMultiple', () async {
      final identityA = await TlsIdentity.createIdentity(
        keyUsages: {KeyUsage.serverAuth},
        attributes: const CertificateAttributes(commonName: 'A'),
        expiration: futureExpiration,
      );
      final identityB = await TlsIdentity.createIdentity(
        keyUsages: {KeyUsage.serverAuth},
        attributes: const CertificateAttributes(commonName: 'B'),
        expiration: futureExpiration,
      );
      final combinedPem = PemData.combined([
        identityA.certificates.single.toPem(),
        identityB.certificates.single.toPem(),
      ]);

      final [certificateA, certificateB] = Certificate.decodeMultiple(
        combinedPem,
      );
      expect(certificateA.attributes, identityA.certificates.single.attributes);
      expect(certificateB.attributes, identityB.certificates.single.attributes);
    });

    test('publicKey', () async {
      final identity = await TlsIdentity.createIdentity(
        keyUsages: {KeyUsage.serverAuth},
        attributes: const CertificateAttributes(commonName: 'Test'),
        expiration: futureExpiration,
      );
      final certificate = identity.certificates.single;
      final publicKey = await certificate.publicKey;
      expect(publicKey.publicKeyDigest, completion(isNotEmpty));
      expect(publicKey.publicKeyData, completion(isNotNull));
      expect(publicKey.privateKeyData, completion(isNull));
    });

    test('created', () async {
      final identity = await TlsIdentity.createIdentity(
        keyUsages: {KeyUsage.serverAuth},
        attributes: const CertificateAttributes(commonName: 'Test'),
        expiration: futureExpiration,
      );
      expect(
        identity.certificates.single.created,
        // Certificates become valid at the start of the second one minute
        // before the current time.
        DateTime.now()
            .toUtc()
            .subtract(const Duration(minutes: 1))
            .copyWith(millisecond: 0, microsecond: 0),
      );
    });

    test('expires', () async {
      final identity = await TlsIdentity.createIdentity(
        keyUsages: {KeyUsage.serverAuth},
        attributes: const CertificateAttributes(commonName: 'Test'),
        expiration: futureExpiration,
      );
      expect(
        identity.certificates.single.expires,
        // Certificates may expire one second before the expiration time
        // specified when creating the identity.
        anyOf([
          futureExpiration,
          futureExpiration.subtract(const Duration(seconds: 1)),
        ]),
      );
    });

    test('toString', () {
      const certificatePem = PemData('''
-----BEGIN CERTIFICATE-----
MIIDEDCCAfigAwIBAgIGAZa6V3hoMA0GCSqGSIb3DQEBCwUAMA8xDTALBgNVBAMM
BFRlc3QwIBcNMjUwNTEwMTMxNTU2WhgPMjA5OTEyMzEyMzU5NTlaMA8xDTALBgNV
BAMMBFRlc3QwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCwWf2yIGaA
K90Wwfram5dm75+7VSH4Nn6fZPUa3yTHDZpzU5jb5x02gjH+N2PoYW+OCuNGveYD
5jJLpD+D0IXsFISVz3ti2/dMyCRt5QNnXAcmRJ+U32tgQY8hc1oeGGgqBDA0gMBu
wxbQSomlyGDslDSI/UU0WD0QLAFvDysta3YBObaFAG/qwfYxValdY9zkEljetAya
skVFPFQltJk2Pw9WtOPi74dYgPlDCZ1iZaiK58hBJ86HYlfScmOm/2z7aGBboVLO
IPCMm6BOV/BdD4QuAh+hJTBDb+TvQCtYp7vuVwb2toBnJOPriUs2cODMYMrP43oB
eVB1vuj+20a3AgMBAAGjcDBuMAkGA1UdEwQCMAAwHQYDVR0OBBYEFI8TYFMS9ZZ7
f0ayjJNGoeS5vmtpMB8GA1UdIwQYMBaAFI8TYFMS9ZZ7f0ayjJNGoeS5vmtpMBEG
CWCGSAGG+EIBAQQEAwIGQDAOBgNVHQ8BAf8EBAMCBaAwDQYJKoZIhvcNAQELBQAD
ggEBAJog+tqqlFkX+UzfMvNvDK5LM0pYvu0aJzeqKIdokHhz7azknW9wJu+NJoQv
M7KAQUCWEgogVRQUBnuP+BxFOrOWhoHo4z7J7fjWoM+nQ+bQVaOVqBoz1/bsC4DR
cCciQIRXSp4KCz+CdZyO2r4fiSGoC5SGjv7agJ2Yhvpykz0VTsjyBTlKrh5gEFmL
MP9LxugRswSk1F1QZjLhQKM3rwl1LIrnYsRpOCanSMUu/yyl6TP+jkf9d68wRT/U
b17aolOOq/6xfP6QIc9I6pOoPhEFY18mCqVCKrF3YCQjVC3P7Ac1m2x5iMXL+fXF
9S9NZbVqfTwblAIiGKg5gvZ5VjY=
-----END CERTIFICATE-----

''');
      final certificate = Certificate.decode(certificatePem);
      expect(
        certificate.toString(),
        'Certificate('
        'created: 2025-05-10 13:15:56.000Z, '
        'expires: 2099-12-31 23:59:59.000Z, '
        // ignore: missing_whitespace_between_adjacent_strings
        'attributes: CertificateAttributes(commonName: Test)'
        ')',
      );
    });
  });

  group('KeyPair', () {
    group('fromExternal', () {
      group('failures', () {
        test('public key unavailable', () async {
          var uncaughtError = false;
          await runZonedGuarded(
            () async {
              final keyPair = await KeyPair.fromExternal(
                ExceptionExternalKeyPairDelegate(),
              );
              expect(await keyPair.publicKeyDigest, isNull);
            },
            (error, stackTrace) {
              if (error case UnimplementedError(
                message: 'ExceptionExternalKeyPairDelegate.publicKeyData',
              )) {
                uncaughtError = true;
              } else {
                // ignore: only_throw_errors
                throw error;
              }
            },
          );
          expect(uncaughtError, isTrue);
        });
      });

      test('publicKeyDigest', () async {
        final delegate = PointycastleExternalKeyPairDelegate();
        final keyPair = await KeyPair.fromExternal(delegate);
        expect(await keyPair.publicKeyDigest, isNotEmpty);
      });

      test('publicKey', () async {
        final delegate = PointycastleExternalKeyPairDelegate();
        final keyPair = await KeyPair.fromExternal(delegate);
        expect(
          (await keyPair.publicKeyData)!.data,
          (await delegate.publicKeyData())!.data,
        );
      });

      test('create self-signed identity', () async {
        final keyPair = await KeyPair.fromExternal(
          PointycastleExternalKeyPairDelegate(),
        );
        final identity = await TlsIdentity.createIdentity(
          keyUsages: {KeyUsage.serverAuth},
          attributes: const CertificateAttributes(commonName: 'Test'),
          expiration: futureExpiration,
          keyPair: keyPair,
        );
        final certificate = identity.certificates.single;
        expect(
          (await (await certificate.publicKey).publicKeyData)!.data,
          (await keyPair.publicKeyData)!.data,
        );
      });

      test('establish encrypted connection', skip: skipPeerSyncTest, () async {
        final listenerDb = await openAsyncTestDatabase(name: 'listener');
        final clientDb = await openAsyncTestDatabase(name: 'client');

        final keyPair = await KeyPair.fromExternal(
          PointycastleExternalKeyPairDelegate(),
        );
        final identity = await TlsIdentity.createIdentity(
          keyUsages: {KeyUsage.serverAuth},
          attributes: const CertificateAttributes(commonName: 'Test'),
          expiration: futureExpiration,
          keyPair: keyPair,
        );
        final listenerConfig = UrlEndpointListenerConfiguration(
          collections: [await listenerDb.defaultCollection],
          tlsIdentity: identity,
        );
        final listener = await UrlEndpointListener.create(listenerConfig);
        await listener.start();
        addTearDown(listener.stop);

        final replicatorConfig = ReplicatorConfiguration(
          target: UrlEndpoint(listener.urls!.first),
          acceptOnlySelfSignedServerCertificate: true,
        )..addCollection(await clientDb.defaultCollection);
        final replicator = await Replicator.create(replicatorConfig);

        await replicator.replicateOneShot();
        expect((await replicator.status).error, isNull);
      });
    });

    group('fromPrivateKey', () {
      test('PEM', () async {
        final keyPair = await KeyPair.fromPrivateKey(privateKeyPem);
        expect(keyPair.privateKeyData, completion(isNotNull));
        expect(keyPair.publicKeyData, completion(isNotNull));
        expect(keyPair.publicKeyDigest, completion(isNotEmpty));
      });

      test('PEM with password', () async {
        final keyPair = await KeyPair.fromPrivateKey(
          privateKeyEncryptedPem,
          password: privateKeyPassword,
        );
        expect(keyPair.privateKeyData, completion(isNotNull));
        expect(keyPair.publicKeyData, completion(isNotNull));
        expect(keyPair.publicKeyDigest, completion(isNotEmpty));
      });

      test('DER', () async {
        final keyPair = await KeyPair.fromPrivateKey(privateKeyDer);
        expect(keyPair.privateKeyData, completion(isNotNull));
        expect(keyPair.publicKeyData, completion(isNotNull));
        expect(keyPair.publicKeyDigest, completion(isNotEmpty));
      });

      test('DER with password', () async {
        final keyPair = await KeyPair.fromPrivateKey(
          privateKeyEncryptedDer,
          password: privateKeyPassword,
        );
        expect(keyPair.privateKeyData, completion(isNotNull));
        expect(keyPair.publicKeyData, completion(isNotNull));
        expect(keyPair.publicKeyDigest, completion(isNotEmpty));
      });
    });

    test('toString', () async {
      final keyPair = await KeyPair.fromPrivateKey(privateKeyPem);
      expect(
        keyPair.toString(),
        'KeyPair(publicKeyDigest: ${await keyPair.publicKeyDigest})',
      );
    });
  });

  group('TlsIdentity', () {
    test('from', () async {
      final keyPair = await KeyPair.fromPrivateKey(privateKeyPem);
      final identity = await TlsIdentity.createIdentity(
        keyUsages: {KeyUsage.serverAuth},
        attributes: const CertificateAttributes(commonName: 'Test'),
        expiration: futureExpiration,
        keyPair: keyPair,
      );
      final certificate = identity.certificates.single;
      final restoredIdentify = TlsIdentity.from(
        keyPair: keyPair,
        certificates: [certificate],
      );
      final restoredCertificate = restoredIdentify.certificates.single;
      expect(restoredCertificate.attributes, certificate.attributes);
      expect(
        (await (await restoredCertificate.publicKey).publicKeyData)?.data,
        (await (await certificate.publicKey).publicKeyData)?.data,
      );
    });

    test('createIdentity', () async {
      final identity = await TlsIdentity.createIdentity(
        keyUsages: {KeyUsage.serverAuth},
        attributes: const CertificateAttributes(commonName: 'Test'),
        expiration: futureExpiration,
      );

      expect(
        identity.expires,
        // Certificates may expire one second before the expiration time
        // specified when creating the identity.
        anyOf([
          futureExpiration,
          futureExpiration.subtract(const Duration(seconds: 1)),
        ]),
      );
      expect(identity.certificates.single.attributes.commonName, 'Test');
    });

    test('create, retrieve and delete persisted identity', () async {
      final label = base64Encode(randomBytes(16, random: Random()));
      final identityFuture = Future(
        () => TlsIdentity.createIdentity(
          keyUsages: {KeyUsage.serverAuth},
          attributes: const CertificateAttributes(commonName: 'CBL Dart Test'),
          expiration: futureExpiration,
          label: label,
        ),
      );

      if (await expectPersistedIdentityUnsupported(identityFuture)) {
        return;
      }

      final identity = await identityFuture;

      final certificate = identity.certificates.single;
      expect(certificate.attributes.commonName, 'CBL Dart Test');

      var retrievedIdentity = await TlsIdentity.identity(label);
      expect(retrievedIdentity, isNotNull);
      expect(retrievedIdentity!.expires, identity.expires);
      expect(
        retrievedIdentity.certificates.single.attributes,
        certificate.attributes,
      );

      retrievedIdentity = await TlsIdentity.identityWithCertificates([
        certificate,
      ]);
      expect(retrievedIdentity, isNotNull);
      expect(retrievedIdentity.expires, identity.expires);
      expect(
        retrievedIdentity.certificates.single.attributes,
        certificate.attributes,
      );

      await TlsIdentity.deleteIdentity(label);
      await expectLater(TlsIdentity.identity(label), completion(isNull));
    });

    test('retrieve non-persisted identity by label', () async {
      final label = base64Encode(randomBytes(16, random: Random()));
      final identityFuture = Future(() => TlsIdentity.identity(label));

      if (await expectPersistedIdentityUnsupported(identityFuture)) {
        return;
      }

      expect(await identityFuture, isNull);
    });

    test('delete non-persisted identity by label', () async {
      final label = base64Encode(randomBytes(16, random: Random()));
      final deleteFuture = Future(() => TlsIdentity.deleteIdentity(label));

      if (await expectPersistedIdentityUnsupported(deleteFuture)) {
        return;
      }

      await expectLater(deleteFuture, completes);
    });

    test('retrieve non-persisted identity by certificates', () async {
      final identity = await TlsIdentity.createIdentity(
        keyUsages: {KeyUsage.serverAuth},
        attributes: const CertificateAttributes(commonName: 'Test'),
        expiration: futureExpiration,
      );
      final certificate = identity.certificates;
      final identityFuture = Future(
        () => TlsIdentity.identityWithCertificates(certificate),
      );

      if (await expectPersistedIdentityUnsupported(identityFuture)) {
        return;
      }

      expect(
        identityFuture,
        throwsA(
          isDatabaseException
              .havingCode(DatabaseErrorCode.crypto)
              .havingMessage('No matching private key in keystore'),
        ),
      );
    });
  });
}

Future<bool> expectPersistedIdentityUnsupported(Future<void> future) async {
  if (Platform.isAndroid || Platform.isLinux) {
    await expectLater(
      future,
      throwsA(
        isDatabaseException
            .havingMessage(
              'Persisted identities are not supported on this platform.',
            )
            .havingCode(DatabaseErrorCode.unsupported),
      ),
    );
    return true;
  }

  return false;
}

final class ExceptionExternalKeyPairDelegate extends ExternalKeyPairDelegate {
  @override
  int get keySizeInBits => 1024;

  @override
  Future<DerData?> publicKeyData() {
    throw UnimplementedError('ExceptionExternalKeyPairDelegate.publicKeyData');
  }

  @override
  Future<Uint8List?> decrypt(Uint8List data) {
    throw UnimplementedError('ExceptionExternalKeyPairDelegate.decrypt');
  }

  @override
  Future<Uint8List?> sign(SignatureDigestAlgorithm? algorithm, Uint8List data) {
    throw UnimplementedError('ExceptionExternalKeyPairDelegate.sign');
  }
}

final class PointycastleExternalKeyPairDelegate
    extends ExternalKeyPairDelegate {
  PointycastleExternalKeyPairDelegate() {
    final keyGenerator = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(
          RSAKeyGeneratorParameters(
            // Fermat prime that is often used for RSA keys.
            BigInt.from(65537),
            keySizeInBits,
            64,
          ),
          FortunaRandom()..seed(
            KeyParameter(
              platform_check.Platform.instance.platformEntropySource().getBytes(
                32,
              ),
            ),
          ),
        ),
      );
    _keyPair = keyGenerator.generateKeyPair();
  }

  @override
  int get keySizeInBits => 2048;

  late final AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> _keyPair;

  @override
  Future<DerData?> publicKeyData() async {
    final publicKey = _keyPair.publicKey;
    final info = ASN1SubjectPublicKeyInfo(
      ASN1AlgorithmIdentifier.fromName('rsaEncryption'),
      ASN1BitString(
        stringValues:
            (ASN1Sequence()
                  ..add(ASN1Integer(publicKey.modulus))
                  ..add(ASN1Integer(publicKey.exponent)))
                .encode(),
      ),
    );
    return DerData(info.encode());
  }

  @override
  Future<Uint8List?> decrypt(Uint8List data) async {
    final cypher = PKCS1Encoding(RSAEngine())
      ..init(false, PrivateKeyParameter(_keyPair.privateKey));
    return cypher.process(data);
  }

  @override
  Future<Uint8List?> sign(
    SignatureDigestAlgorithm? algorithm,
    Uint8List data,
  ) async {
    if (algorithm == null) {
      final AsymmetricBlockCipher cypher = PKCS1Encoding(RSAEngine())
        ..init(true, PrivateKeyParameter<RSAPrivateKey>(_keyPair.privateKey));
      return cypher.process(data);
    }

    final signer = RSASigner(_PassThroughDigest(data), switch (algorithm) {
      SignatureDigestAlgorithm.sha1 => '06052b0e03021a',
      SignatureDigestAlgorithm.sha224 => '0609608648016503040204',
      SignatureDigestAlgorithm.sha256 => '0609608648016503040201',
      SignatureDigestAlgorithm.sha384 => '0609608648016503040202',
      SignatureDigestAlgorithm.sha512 => '0609608648016503040203',
      SignatureDigestAlgorithm.ripemd160 => '06052b24030201',
    })..init(true, PrivateKeyParameter<RSAPrivateKey>(_keyPair.privateKey));
    return signer.generateSignature(data).bytes;
  }
}

class _PassThroughDigest implements Digest {
  _PassThroughDigest(this._data);

  final Uint8List _data;

  @override
  String get algorithmName => 'PassThroughDigest';

  @override
  int get byteLength => _data.length;

  @override
  int get digestSize => _data.length;

  @override
  int doFinal(Uint8List out, int outOff) {
    out.setRange(outOff, outOff + _data.length, _data);
    return _data.length;
  }

  @override
  Uint8List process(Uint8List data) => _data;

  @override
  void reset() {}

  @override
  void update(Uint8List inp, int inpOff, int len) {}

  @override
  void updateByte(int inp) {}
}
