import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../document/blob_test.dart';
import '../test_binding.dart';
import '../utils/matchers.dart';
import 'private_keys.dart';

final futureExpiration = DateTime.utc(2100);

void main() {
  setupTestBinding();

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
      expect(
        OID(const [1, 2, 3, 4, 5]),
        isNot(OID(const [1, 2, 3, 4])),
      );
      expect(
        OID(const [1, 2, 3, 4]),
        isNot(OID(const [1, 2, 3, 4, 5])),
      );
      expect(
        OID(const [1, 2, 3, 4]),
        OID(const [1, 2, 3, 4]),
      );
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

      const differentAttributes =
          CertificateAttributes(commonName: 'OtherTest');
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

      const differentAttributes =
          CertificateAttributes(commonName: 'OtherTest');

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
      final decodedCertificate = await Certificate.decode(certificate.toPem());
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
      final decodedCertificate = await Certificate.decode(certificate.toDer());
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

      final [certificateA, certificateB] =
          await Certificate.decodeMultiple(combinedPem);
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
      final publicKey = certificate.publicKey;
      expect(publicKey.publicKeyDigest, isNotEmpty);
      expect(publicKey.publicKey, isNotNull);
      expect(publicKey.privateKey, isNull);
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
          futureExpiration.subtract(const Duration(seconds: 1))
        ]),
      );
    });
  });

  group('KeyPair', () {
    test('withPrivateKey PEM', () async {
      final keyPair = await KeyPair.withPrivateKey(privateKeyPem);
      expect(keyPair.privateKey, isNotNull);
      expect(keyPair.publicKey, isNotNull);
      expect(keyPair.publicKeyDigest, isNotEmpty);
    });

    test('withPrivateKey PEM with password', () async {
      final keyPair = await KeyPair.withPrivateKey(
        privateKeyEncryptedPem,
        password: privateKeyPassword,
      );
      expect(keyPair.privateKey, isNotNull);
      expect(keyPair.publicKey, isNotNull);
      expect(keyPair.publicKeyDigest, isNotEmpty);
    });

    test('withPrivateKey DER', () async {
      final keyPair = await KeyPair.withPrivateKey(privateKeyDer);
      expect(keyPair.privateKey, isNotNull);
      expect(keyPair.publicKey, isNotNull);
      expect(keyPair.publicKeyDigest, isNotEmpty);
    });

    test('withPrivateKey DER with password', () async {
      final keyPair = await KeyPair.withPrivateKey(
        privateKeyEncryptedDer,
        password: privateKeyPassword,
      );
      expect(keyPair.privateKey, isNotNull);
      expect(keyPair.publicKey, isNotNull);
      expect(keyPair.publicKeyDigest, isNotEmpty);
    });
  });

  group('TlsIdentity', () {
    test('from', () async {
      final keyPair = await KeyPair.withPrivateKey(privateKeyPem);
      final identity = await TlsIdentity.createIdentity(
        keyUsages: {KeyUsage.serverAuth},
        attributes: const CertificateAttributes(commonName: 'Test'),
        expiration: futureExpiration,
        keyPair: keyPair,
      );
      final certificate = identity.certificates.single;
      final restoredIdentify =
          await TlsIdentity.from(keyPair: keyPair, certificates: [certificate]);
      final restoredCertificate = restoredIdentify.certificates.single;
      expect(restoredCertificate.attributes, certificate.attributes);
      expect(
        restoredCertificate.publicKey.publicKey.data,
        certificate.publicKey.publicKey.data,
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
          futureExpiration.subtract(const Duration(seconds: 1))
        ]),
      );
      expect(identity.certificates.single.attributes.commonName, 'Test');
    });

    test(
      'create, retrieve and delete persisted identity',
      skip: Platform.isMacOS || Platform.isIOS
          ? 'TODO(blaugold): fix @autoreleasepool issue'
          : null,
      () async {
        final label = base64Encode(randomBytes(16, random: Random()));
        final identityFuture = Future(() => TlsIdentity.createIdentity(
              keyUsages: {KeyUsage.serverAuth},
              attributes:
                  const CertificateAttributes(commonName: 'CBL Dart Test'),
              expiration: futureExpiration,
              label: label,
            ));

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

        retrievedIdentity =
            await TlsIdentity.identityWithCertificates([certificate]);
        expect(retrievedIdentity, isNotNull);
        expect(retrievedIdentity.expires, identity.expires);
        expect(
          retrievedIdentity.certificates.single.attributes,
          certificate.attributes,
        );

        await TlsIdentity.deleteIdentity(label);
        await expectLater(TlsIdentity.identity(label), completion(isNull));
      },
    );

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
      final identityFuture =
          Future(() => TlsIdentity.identityWithCertificates(certificate));

      if (await expectPersistedIdentityUnsupported(identityFuture)) {
        return;
      }

      expect(
        identityFuture,
        throwsA(isDatabaseException
            .havingCode(DatabaseErrorCode.crypto)
            .havingMessage('No matching private key in keystore')),
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
