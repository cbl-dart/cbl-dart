import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('Authenticator', () {
    group('BasicAuthenticator', () {
      test('toString', () {
        expect(
          BasicAuthenticator(username: 'username', password: 'password')
              .toString(),
          'BasicAuthenticator(username: username, password: *****ord)',
        );
      });
    });

    group('SessionAuthenticator', () {
      test('default cookieName', () {
        expect(
          SessionAuthenticator(sessionId: '').cookieName,
          'SyncGatewaySession',
        );
      });

      test('toString', () {
        expect(
          SessionAuthenticator(sessionId: 'sessionId', cookieName: 'cookieName')
              .toString(),
          'SessionAuthenticator(sessionId: ******nId, cookieName: cookieName)',
        );
      });
    });

    group('ClientCertificateAuthenticator', () {
      test('toString', () async {
        final identity = await TlsIdentity.createIdentity(
          keyUsages: {KeyUsage.clientAuth},
          attributes: const CertificateAttributes(commonName: 'test'),
          expiration: DateTime(2100),
        );
        final authenticator = ClientCertificateAuthenticator(identity);
        expect(
          authenticator.toString(),
          'ClientCertificateAuthenticator(identity: $identity)',
        );
      });
    });
  });
}
