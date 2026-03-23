import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:path/path.dart' as p;

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('Database.defaultDirectory', () {
    late String originalDirectory;

    setUp(() {
      originalDirectory = Database.defaultDirectory;
    });

    tearDown(() {
      Database.defaultDirectory = originalDirectory;
    });

    test('returns a non-empty string', () {
      expect(Database.defaultDirectory, isNotEmpty);
    });

    test('setter overrides resolved value', () {
      final custom = p.join(tmpDir, 'custom-dir');
      Database.defaultDirectory = custom;
      expect(Database.defaultDirectory, custom);
    });

    test('resetDefaultDirectory restores automatic resolution', () {
      // Reset to clear the test binding's override, capturing the
      // automatically resolved directory.
      Database.resetDefaultDirectory();
      final autoResolved = Database.defaultDirectory;

      Database.defaultDirectory = '/some/override';
      Database.resetDefaultDirectory();
      expect(Database.defaultDirectory, autoResolved);
    });

    test(
      'DatabaseConfiguration uses defaultDirectory when no directory given',
      () {
        final custom = p.join(tmpDir, 'config-dir');
        Database.defaultDirectory = custom;
        final config = DatabaseConfiguration();
        expect(config.directory, custom);
      },
    );

    test(
      'open database without explicit directory uses defaultDirectory',
      () async {
        final custom = Directory(p.join(tmpDir, 'default-dir-test'))
          ..createSync();
        addTearDown(() => custom.deleteSync(recursive: true));

        Database.defaultDirectory = custom.path;

        final db = await Database.openAsync('default-dir-db');
        addTearDown(db.close);

        expect(db.path, startsWith(custom.path));
      },
    );
  });
}
