import 'dart:async';
import 'dart:isolate';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/log/logger.dart';
import 'package:cbl/src/support/isolate.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('Multi-isolate Logger', () {
    late final Logger? originalLogger;
    setUpAll(() => originalLogger = Database.log.custom);
    tearDownAll(() => Database.log.custom = originalLogger);
    setUp(() => Database.log.custom = null);

    test('loggers in multiple isolates each receive log messages', () async {
      // Set up logger in main isolate.
      final mainMessages = <LogMessage>[];
      final mainReceivedMessage = Completer<void>();
      Database.log.custom = TestLogger((level, domain, message) {
        mainMessages.add(LogMessage(level, domain, message));
        if (!mainReceivedMessage.isCompleted) {
          mainReceivedMessage.complete();
        }
      });

      // Spawn a secondary isolate that registers its own logger and waits for
      // a log message.
      final context = IsolateContext.instance.forSecondaryIsolate();
      final secondaryResult = ReceivePort();
      final secondaryReady = Completer<void>();
      final readyPort = ReceivePort()
        ..listen((_) {
          if (!secondaryReady.isCompleted) {
            secondaryReady.complete();
          }
        });

      await Isolate.spawn(
        _secondaryIsolateMain,
        _SecondaryIsolateConfig(
          context: context,
          resultPort: secondaryResult.sendPort,
          readyPort: readyPort.sendPort,
        ),
      );

      // Wait for secondary isolate to register its logger.
      await secondaryReady.future;
      readyPort.close();

      // Emit a log message from the main isolate. Both loggers should receive
      // it since the native log callback fans out to all registered callbacks.
      cblLogMessage(LogDomain.network, LogLevel.warning, 'A');

      // Wait for both isolates to receive the message.
      await mainReceivedMessage.future;
      final secondaryMessages =
          await secondaryResult.first as List<List<dynamic>>;

      // Verify main isolate received the message.
      expect(mainMessages, hasLength(1));
      expect(mainMessages.first.domain, LogDomain.network);
      expect(mainMessages.first.level, LogLevel.warning);
      expect(mainMessages.first.message, 'A');

      // Verify secondary isolate received the message.
      expect(secondaryMessages, hasLength(1));
      expect(secondaryMessages.first, [
        LogLevel.warning.index,
        LogDomain.network.index,
        'A',
      ]);
    });

    test(
      'removing logger in one isolate does not affect other isolate',
      () async {
        final mainMessages = <LogMessage>[];
        final mainReceivedMessage = Completer<void>();
        Database.log.custom = TestLogger((level, domain, message) {
          mainMessages.add(LogMessage(level, domain, message));
          if (!mainReceivedMessage.isCompleted) {
            mainReceivedMessage.complete();
          }
        });

        // Register and immediately remove a logger in a secondary isolate.
        final context = IsolateContext.instance.forSecondaryIsolate();
        await Isolate.run(() async {
          await initSecondaryIsolate(context);
          Database.log.custom = TestLogger((_, _, _) {});
          Database.log.custom = null;
        });

        // Main isolate logger should still work.
        cblLogMessage(LogDomain.network, LogLevel.warning, 'B');
        await mainReceivedMessage.future;

        expect(mainMessages, hasLength(1));
        expect(mainMessages.first.message, 'B');
      },
    );
  });
}

final class _SecondaryIsolateConfig {
  _SecondaryIsolateConfig({
    required this.context,
    required this.resultPort,
    required this.readyPort,
  });

  final IsolateContext context;
  final SendPort resultPort;
  final SendPort readyPort;
}

Future<void> _secondaryIsolateMain(_SecondaryIsolateConfig config) async {
  await initSecondaryIsolate(config.context);

  final messages = <List<dynamic>>[];
  final receivedMessage = Completer<void>();

  Database.log.custom = TestLogger((level, domain, message) {
    messages.add([level.index, domain.index, message]);
    if (!receivedMessage.isCompleted) {
      receivedMessage.complete();
    }
  });

  // Signal that the logger is registered.
  config.readyPort.send(null);

  // Wait for a message to be received.
  await receivedMessage.future;

  // Clean up logger before exiting.
  Database.log.custom = null;

  config.resultPort.send(messages);
}

final class TestLogger extends Logger {
  TestLogger(this.callback, {LogLevel level = LogLevel.warning}) : super(level);

  void Function(LogLevel level, LogDomain domain, String message) callback;

  @override
  void log(LogLevel level, LogDomain domain, String message) {
    callback(level, domain, message);
  }
}
