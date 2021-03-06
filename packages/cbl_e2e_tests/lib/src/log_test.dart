import 'package:cbl/cbl.dart';

import 'test_binding.dart';

void main() {
  group('logging', () {
    setUpAll(() => CblE2eTestBinding.instance.stopTestLogger());
    tearDownAll(() => CblE2eTestBinding.instance.startTestLogger());

    test('logLevel can be set', () {
      final initialLogLevel = cbl.logLevel;
      addTearDown(() => cbl.logLevel = initialLogLevel);

      cbl.logLevel = LogLevel.verbose;
      expect(cbl.logLevel, equals(LogLevel.verbose));
    });

    test(
      'logMessages emits log messages from CouchbaseLite implementation',
      () async {
        expect(
          cbl.logMessages().map((it) => it.message),
          emitsThrough(
            matches('litecore::SQLiteDataFile.+LogCallback.+\.cblite2'),
          ),
        );

        final db = await cbl.openDatabase(
          testDbName('LogCallback'),
          config: DatabaseConfiguration(directory: tmpDir),
        );

        addTearDown(db.close);
      },
    );
  });
}
