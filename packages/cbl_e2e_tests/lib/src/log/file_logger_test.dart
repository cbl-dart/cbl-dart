import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/log/logger.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/file_system.dart';

void main() {
  setupTestBinding();

  group('FileLogConfiguration', () {
    test('validate properties', () {
      expect(
        () => LogFileConfiguration(directory: 'A', maxRotateCount: -1),
        throwsRangeError,
      );
      expect(
        () => LogFileConfiguration(directory: 'A', maxSize: 0),
        throwsRangeError,
      );

      final config = LogFileConfiguration(directory: 'A')..maxRotateCount = 0;

      expect(() => config.maxRotateCount = -1, throwsRangeError);

      config.maxSize = 1;
      expect(() => config.maxSize = 0, throwsRangeError);
    });

    test('from', () {
      final source = LogFileConfiguration(
        directory: 'A',
        usePlainText: true,
        maxSize: 99,
        maxRotateCount: 999,
      );
      final copy = LogFileConfiguration.from(source);
      expect(copy.directory, source.directory);
      expect(copy.usePlainText, source.usePlainText);
      expect(copy.maxSize, source.maxSize);
      expect(copy.maxRotateCount, source.maxRotateCount);
    });

    test('==', () {
      LogFileConfiguration a;
      LogFileConfiguration b;

      a = LogFileConfiguration(directory: 'A');
      expect(a, a);

      b = LogFileConfiguration.from(a);
      expect(a, b);

      b.usePlainText = true;
      expect(a, isNot(b));
    });

    test('toString', () {
      expect(
        LogFileConfiguration(directory: 'A', usePlainText: true).toString(),
        'LogFileConfiguration('
        'directory: A, '
        'USE-PLAIN-TEXT, '
        'maxSize: 500.0 KB, '
        // ignore: missing_whitespace_between_adjacent_strings
        'maxRotateCount: 1'
        ')',
      );
    });
  });

  group('FileLogger', () {
    LogFileConfiguration? originalLogConfig;
    LogLevel? originalLogLevel;

    setUp(() {
      originalLogConfig ??= Database.log.file.config;
      originalLogLevel ??= Database.log.file.level;

      Database.log.file
        ..config = null
        ..level = LogLevel.none;
    });

    tearDownAll(() {
      Database.log.file
        ..config = originalLogConfig
        ..level = originalLogLevel!;
    });

    test('get and set config', () {
      final config = LogFileConfiguration(
        directory: '$tmpDir/GetAndSetLogFileConfig',
        maxSize: 2,
        maxRotateCount: 3,
        usePlainText: true,
      );

      expect(Database.log.file.config, isNull);

      Database.log.file.config = config;
      expect(Database.log.file.config, config);
    });

    test('get and set level', () {
      expect(Database.log.file.level, LogLevel.none);

      Database.log.file.level = LogLevel.verbose;
      expect(Database.log.file.level, LogLevel.verbose);
    });

    test('enable file logger', () async {
      final logDir = Directory('$tmpDir/EnableFileLogger');
      await logDir.reset();

      Database.log.file
        ..config = LogFileConfiguration(
          directory: logDir.path,
          usePlainText: true,
        )
        ..level = LogLevel.error;

      const logMessage = 'TEST_LOG_MESSAGE';
      cblLogMessage(LogDomain.network, LogLevel.error, logMessage);

      final errorFileContents = await logDir
          .findAndReadFile((file) => file.path.contains('cbl_error'));

      expect(errorFileContents, contains('[WS] ERROR: $logMessage'));
    });
  });
}
