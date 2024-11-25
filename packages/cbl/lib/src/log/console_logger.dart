import '../bindings.dart';
import 'logger.dart';

/// Logger for writing log messages to the system console.
///
/// {@category Logging}
abstract final class ConsoleLogger {
  /// The minium [LogLevel] of the log messages to be logged.
  ///
  /// The default log level is [LogLevel.warning].
  LogLevel get level;

  set level(LogLevel value);
}

final _bindings = CBLBindings.instance.logging;

final class ConsoleLoggerImpl extends ConsoleLogger {
  @override
  LogLevel get level => _bindings.consoleLevel().toLogLevel();

  @override
  set level(LogLevel value) => _bindings.setConsoleLevel(value.toCBLLogLevel());
}
