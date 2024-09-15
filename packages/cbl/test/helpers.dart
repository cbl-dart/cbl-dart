import 'package:logging/logging.dart';
import 'package:test/test.dart';

/// Logger that outputs the full trace when a test fails.
Logger get logger => _logger ??= () {
      // A new logger is lazily created for each test so that the messages
      // captured by printOnFailure are scoped to the correct test.
      addTearDown(() => _logger = null);
      return _createTestLogger();
    }();

Logger? _logger;

Logger _createTestLogger() => Logger.detached('')
  ..level = Level.ALL
  ..onRecord.listen((record) {
    printOnFailure('${record.level.name}: ${record.time}: ${record.message}');
  });
