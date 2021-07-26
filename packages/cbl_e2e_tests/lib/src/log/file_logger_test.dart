import 'dart:io';
import 'dart:math';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/log/logger.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('FileLogger', () {
    setUp(resetFilLogger);
    tearDownAll(resetFilLogger);

    test('enable file logger', () async {
      var logDir = Directory('$tmpDir/log');
      if (await logDir.exists()) {
        await logDir.delete();
      }
      await logDir.create(recursive: true);

      Log.file.config = LogFileConfiguration(
        directory: logDir.path,
        usePlainText: true,
      );
      Log.file.level = LogLevel.error;

      final logMessage = Random().nextInt(1 << 32).toString();
      cblLogMessage(LogDomain.network, LogLevel.error, logMessage);

      final logFiles = await logDir.list().toList();
      final errorFile = logFiles
          .firstWhere((file) => file.path.contains('cbl_error')) as File;
      final errorFileContents = await errorFile.readAsString();

      expect(errorFileContents, contains('[WS] ERROR: $logMessage'));
    });
  });
}

void resetFilLogger() {
  Log.file.config = null;
  Log.file.level = LogLevel.none;
}
