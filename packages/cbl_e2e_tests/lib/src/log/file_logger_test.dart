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
        throwsArgumentError,
      );
      expect(
        () => LogFileConfiguration(directory: 'A', maxSize: -1),
        throwsArgumentError,
      );

      final config = LogFileConfiguration(directory: 'A');

      expect(() => config.maxRotateCount = -1, throwsArgumentError);
      expect(() => config.maxSize = -1, throwsArgumentError);
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
        'maxRotateCount: 1'
        ')',
      );
    });
  });

  group('FileLogger', () {
    setUp(resetFileLogger);
    tearDownAll(resetFileLogger);

    test('enable file logger', () async {
      var logDir = Directory('$tmpDir/EnableFileLogger');
      await logDir.reset();

      Database.log.file
        ..config = LogFileConfiguration(
          directory: logDir.path,
          usePlainText: true,
        )
        ..level = LogLevel.error;

      final logMessage = 'TEST_LOG_MESSAGE';
      cblLogMessage(LogDomain.network, LogLevel.error, logMessage);

      final errorFileContents = await logDir
          .findAndReadFile((file) => file.path.contains('cbl_error'));

      expect(errorFileContents, contains('[WS] ERROR: $logMessage'));
    });
  });
}

void resetFileLogger() {
  Database.log.file
    ..config = null
    ..level = LogLevel.none;
}
