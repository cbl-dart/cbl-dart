import 'log/console_logger.dart';
import 'log/file_logger.dart';
import 'log/logger.dart';

export 'log/console_logger.dart' show ConsoleLogger;
export 'log/file_logger.dart' show FileLogger, LogFileConfiguration;
export 'log/logger.dart'
    show LogMessage, Logger, StreamLogger, LogDomain, LogLevel;

/// Configuration of the [ConsoleLogger], [FileLogger] and a custom [Logger].
class Log {
  Log._();

  /// Console logger writing messages to the system console.
  static final ConsoleLogger console = ConsoleLoggerImpl();

  /// File logger writing log messages to files.
  static final FileLogger file = FileLoggerImpl();

  /// The currently set custom [Logger].
  static Logger? get custom => _custom;
  static Logger? _custom;
  static set custom(Logger? value) {
    if (_custom != value) {
      _custom = value;
      setupCustomLogger(value);
    }
  }
}
