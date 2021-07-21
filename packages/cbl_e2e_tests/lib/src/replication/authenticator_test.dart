import 'package:cbl/cbl.dart';
import 'package:test/test.dart';

import '../../test_binding_impl.dart';

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
  });
}
