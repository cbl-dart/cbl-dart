import '../support/ffi.dart';
import 'logger.dart';

/// Logger for writing log messages to the system console.
///
/// {@category Logging}
abstract class ConsoleLogger {
  ConsoleLogger._();

  /// The minium [LogLevel] of the log messages to be logged.
  ///
  /// The default log level is [LogLevel.warning].
  LogLevel get level;

  set level(LogLevel value);
}

final _bindings = cblBindings.logging;

class ConsoleLoggerImpl extends ConsoleLogger {
  ConsoleLoggerImpl() : super._();

  @override
  LogLevel get level => _bindings.consoleLevel().toLogLevel();

  @override
  set level(LogLevel value) => _bindings.setConsoleLevel(value.toCBLLogLevel());
}
