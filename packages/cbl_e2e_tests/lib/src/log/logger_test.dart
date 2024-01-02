import 'dart:async';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/log/logger.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('Logger', () {
    late final Logger? originalLogger;
    setUpAll(() => originalLogger = Database.log.custom);
    tearDownAll(() => Database.log.custom = originalLogger);
    setUp(() => Database.log.custom = null);

    test('is called with log message', () {
      Database.log.custom = TestLogger(expectAsync3((level, domain, message) {
        expect(level, LogLevel.warning);
        expect(domain, LogDomain.network);
        expect(message, 'A');
      }), level: LogLevel.warning);

      cblLogMessage(LogDomain.network, LogLevel.warning, 'A');
    });

    test('update level of logger', () {
      final logger = Database.log.custom = TestLogger(
        expectAsync3((level, domain, message) {}),
        level: LogLevel.error,
      );

      // Wont be logged because its under the current level.
      cblLogMessage(LogDomain.network, LogLevel.warning, 'A');

      logger.level = LogLevel.warning;

      // Will no be be logged after setting a new level.
      cblLogMessage(LogDomain.network, LogLevel.warning, 'A');
    });

    test('remove logger', () async {
      final receivedMessage = Completer<void>();

      Database.log.custom = TestLogger(expectAsync3((level, domain, message) {
        receivedMessage.complete();
      }), level: LogLevel.error);

      // Will be logged.
      cblLogMessage(LogDomain.network, LogLevel.error, 'A');

      // Logs are delivered asynchronously. If the logger is removed to early
      // it never sees the message.
      await receivedMessage.future;

      Database.log.custom = null;

      // Wont be logged because logger has been removed.
      cblLogMessage(LogDomain.network, LogLevel.warning, 'A');
    });

    group('StreamLogger', () {
      test('emits log messages', () {
        final logger = Database.log.custom = StreamLogger(LogLevel.warning);
        addTearDown(() => Database.log.custom = null);

        expect(
          logger.stream,
          emits(
            isA<LogMessage>()
                .having((it) => it.domain, 'domain', LogDomain.network)
                .having((it) => it.level, 'lever', LogLevel.warning)
                .having((it) => it.message, 'message', 'A'),
          ),
        );

        cblLogMessage(LogDomain.network, LogLevel.warning, 'A');
      });
    });
  });
}

class TestLogger extends Logger {
  TestLogger(this.callback, {LogLevel level = LogLevel.info}) : super(level);

  void Function(LogLevel level, LogDomain domain, String message) callback;

  @override
  void log(LogLevel level, LogDomain domain, String message) {
    callback(level, domain, message);
  }
}
