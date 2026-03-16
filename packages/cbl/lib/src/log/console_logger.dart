import '../bindings.dart';
import 'logger.dart';

/// Logger for writing log messages to the system console.
///
/// {@category Logging}
abstract final class ConsoleLogger {
  /// The minimum [LogLevel] of the log messages to be logged.
  ///
  /// The default log level is [LogLevel.warning].
  LogLevel get level;

  set level(LogLevel value);
}

final class ConsoleLoggerImpl extends ConsoleLogger {
  @override
  LogLevel get level => LoggingBindings.consoleLevel().toLogLevel();

  @override
  set level(LogLevel value) =>
      LoggingBindings.setConsoleLevel(value.toCBLLogLevel());
}
