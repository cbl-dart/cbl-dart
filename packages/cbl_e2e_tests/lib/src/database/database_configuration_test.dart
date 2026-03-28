import 'dart:typed_data';

import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/api_variant.dart';
import '../utils/database_utils.dart';
import '../utils/encryption.dart';
import '../utils/matchers.dart';

void main() {
  setupTestBinding();

  group('EncryptionKey', () {
    group('key', () {
      test('throws when raw key is not exactly 32 bytes long', () {
        expect(() => EncryptionKey.key(Uint8List(0)), throwsArgumentError);
      });

      test('creates key from raw key', () {
        final databaseDirectory = databaseDirectoryForTest();
        final rawKey = randomRawEncryptionKey();

        // Open the database for the first time, creating it.
        openSyncTestDatabase(
          config: DatabaseConfiguration(
            directory: databaseDirectory,
            encryptionKey: EncryptionKey.key(rawKey),
          ),
        );

        // Open it again with the correct key.
        openSyncTestDatabase(
          config: DatabaseConfiguration(
            directory: databaseDirectory,
            encryptionKey: EncryptionKey.key(rawKey),
          ),
        );

        // Open it again without key.
        expect(openSyncTestDatabase, throwsNotADatabaseFile);
      });
    });

    group('password', () {
      apiTest('creates key from a password', () async {
        final databaseDirectory = databaseDirectoryForTest();
        const password = 'A';

        // Open the database for the first time, creating it.
        openSyncTestDatabase(
          config: DatabaseConfiguration(
            directory: databaseDirectory,
            encryptionKey: await createTestEncryptionKeyWithPassword(password),
          ),
        );

        // Open it again with the correct key.
        openSyncTestDatabase(
          config: DatabaseConfiguration(
            directory: databaseDirectory,
            encryptionKey: await createTestEncryptionKeyWithPassword(password),
          ),
        );

        // Open it again without key.
        expect(openSyncTestDatabase, throwsNotADatabaseFile);
      });
    });

    test('==', () {
      final a = EncryptionKey.key(randomRawEncryptionKey());
      final b = EncryptionKey.key(randomRawEncryptionKey());

      expect(a, equality(a));
      expect(a, isNot(b));
    });
  });

  group('DatabaseConfiguration', () {
    test('default', () {
      final config = DatabaseConfiguration();
      // Directory is the default directory provided by the CBL C SDK.
      expect(config.directory, isNotEmpty);
    });

    test('from copies directory', () {
      final config = DatabaseConfiguration(directory: 'A');
      final copy = DatabaseConfiguration.from(config);

      expect(copy, config);
    });

    test('from copies fullSync', () {
      final config = DatabaseConfiguration(fullSync: true);
      final copy = DatabaseConfiguration.from(config);

      expect(copy.fullSync, isTrue);
    });

    test('from does not copy encryptionKey', () {
      final config = DatabaseConfiguration(
        encryptionKey: EncryptionKey.key(randomRawEncryptionKey()),
      );
      final copy = DatabaseConfiguration.from(config);

      expect(copy.encryptionKey, isNull);
    });

    test('==', () {
      DatabaseConfiguration a;
      DatabaseConfiguration b;

      a = DatabaseConfiguration(directory: 'A');
      expect(a, a);

      b = DatabaseConfiguration(directory: 'A');
      expect(a, b);

      b = DatabaseConfiguration(directory: 'B');
      expect(b, isNot(a));
    });

    test('toString', () {
      final config = DatabaseConfiguration(directory: 'A');
      expect(config.toString(), 'DatabaseConfiguration(directory: A)');
    });

    apiTest(
      'repeated opens with fullSync disabled produce valid document timestamps',
      () async {
        final directory = databaseDirectoryForTest();

        for (var i = 0; i < 20; i++) {
          final db = await openTestDatabase(
            name: 'db_${i.toString().padLeft(4, '0')}',
            config: DatabaseConfiguration(
              directory: directory,
              fullSync: false,
            ),
            tearDown: false,
          );
          final collection = await db.defaultCollection;

          final doc = MutableDocument({'iter': i});
          await collection.saveDocument(doc);

          expect(doc.revisionId, isNotNull, reason: 'iteration $i');
          expect(doc.timestamp, greaterThanOrEqualTo(_minValidTimestamp));
          expect(
            _parseRevisionPrefix(doc.revisionId!),
            greaterThanOrEqualTo(_minValidTimestamp),
          );

          await db.close();
        }
      },
    );
  });
}

int _parseRevisionPrefix(String revisionId) =>
    int.parse(revisionId.substring(0, revisionId.indexOf('@')), radix: 16);

const _minValidTimestamp = 0x10000000000;
