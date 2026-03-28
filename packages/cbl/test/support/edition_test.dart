import 'package:cbl/src/support/edition.dart';
import 'package:test/test.dart';

void main() {
  group('requireEnterprise', () {
    test('returns normally when the enterprise edition is active', () {
      overrideEdition(Edition.enterprise);

      expect(() => requireEnterprise('Database encryption'), returnsNormally);
    });

    test('throws when the enterprise edition is not active', () {
      overrideEdition(Edition.community);

      const capabilities = [
        'Local database replication',
        'Database encryption',
        'TLS identities',
      ];

      for (final capability in capabilities) {
        expect(
          () => requireEnterprise(capability),
          throwsA(
            isA<StateError>().having(
              (it) => it.message,
              'message',
              contains(capability),
            ),
          ),
        );
      }
    });
  });
}

void overrideEdition(Edition edition) {
  activeEditionOverride = edition;
  addTearDown(() => activeEditionOverride = null);
}
