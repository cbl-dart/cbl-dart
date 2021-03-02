import 'package:cbl/cbl.dart';

import 'test_binding.dart';

void main() {
  test('get and set log level', () {
    final initialLogLevel = cbl.logLevel;
    addTearDown(() => cbl.logLevel = initialLogLevel);

    cbl.logLevel = LogLevel.verbose;
    expect(cbl.logLevel, equals(LogLevel.verbose));
  });

  test('a custom log callback should receive log messages', () async {
    final initialLogCallback = cbl.logCallback;
    addTearDown(() => cbl.logCallback = initialLogCallback);

    cbl.logCallback = expectAsync3(
      (domain, level, message) {
        expect(message, isNotEmpty);
      },
      // Must be called at least once.
      max: -1,
      count: 1,
    );

    final db = await cbl.openDatabase(
      testDbName('LogCallback'),
      config: DatabaseConfiguration(directory: tmpDir),
    );

    await db.close();
  });
}
