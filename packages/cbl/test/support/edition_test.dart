import 'package:cbl/src/support/edition.dart';
import 'package:test/test.dart';

void main() {
  group('useEnterpriseFeature', () {
    test('returns normally when the enterprise edition is active', () {
      overrideEdition(Edition.enterprise);

      expect(
        () => useEnterpriseFeature(EnterpriseFeature.databaseEncryption),
        returnsNormally,
      );
    });

    test('throws when the enterprise edition is not active', () {
      overrideEdition(Edition.community);

      final featureDescription = {
        EnterpriseFeature.localDbReplication: 'Local database replication',
        EnterpriseFeature.databaseEncryption: 'Database encryption',
        EnterpriseFeature.propertyEncryption: 'Property encryption',
      };

      for (final entry in featureDescription.entries) {
        expect(
          () => useEnterpriseFeature(entry.key),
          throwsA(
            isA<StateError>()
                .having((it) => it.message, 'message', contains(entry.value)),
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
