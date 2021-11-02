import 'dart:async';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../support/async_callback.dart';
import '../support/ffi.dart';
import '../support/native_object.dart';
import '../support/utils.dart';
import 'console_logger.dart';

/// Subsystems that log information.
///
/// {@category Logging}
enum LogDomain {
  database,
  query,
  replicator,
  network,
}

/// Levels of log messages. Higher values are more important/severe. Each level
/// includes the lower ones.
///
/// {@category Logging}
enum LogLevel {
  /// Extremely detailed messages, only written by debug builds of CBL.
  debug,

  /// Detailed messages about normally-unimportant stuff.
  verbose,

  /// Messages about ordinary behavior.
  info,

  /// Messages warning about unlikely and possibly bad stuff.
  warning,

  /// Messages about errors
  error,

  /// Disables logging entirely.
  none
}

/// Abstract class that custom loggers have to extended.
///
/// {@category Logging}
abstract class Logger {
  Logger([LogLevel? level]) : _level = level ?? LogLevel.info;

  void Function()? _levelChanged;

  /// The minimum log level for which [log] will be called.
  LogLevel get level => _level;
  LogLevel _level;

  set level(LogLevel logLevel) {
    if (_level != logLevel) {
      _level = logLevel;
      _levelChanged?.call();
    }
  }

  /// The callback which is invoked for each log message.
  void log(LogLevel level, LogDomain domain, String message);
}

/// A log message.
///
/// {@category Logging}
class LogMessage {
  /// Creates a log message.
  LogMessage(this.level, this.domain, this.message);

  /// The importance of this log message.
  final LogLevel level;

  /// The sub system which emitted this message.
  final LogDomain domain;

  /// The log message.
  final String message;
}

/// A [Logger] which emits the received [LogMessage]s from a [stream].
///
/// {@category Logging}
class StreamLogger extends Logger {
  /// Creates a [Logger] which emits the received [LogMessage]s from a [stream].
  StreamLogger([LogLevel? level]) : super(level);

  final _controller = StreamController<LogMessage>.broadcast();

  /// The stream of [LogMessage] received by this logger.
  late final Stream<LogMessage> stream = _controller.stream;

  @override
  void log(LogLevel level, LogDomain domain, String message) =>
      _controller.add(LogMessage(level, domain, message));
}

/// A [Logger] which formats logs in the same way as [ConsoleLogger] but uses
/// Dart's [print] function.
///
/// {@category Logging}
class DartConsoleLogger extends Logger {
  /// Creates a [Logger] which formats logs in the same way as [ConsoleLogger]
  /// but uses Dart's [print] function.
  DartConsoleLogger([LogLevel? level]) : super(level);

  @override
  void log(LogLevel level, LogDomain domain, String message) {
    // ignore: avoid_print
    print(_formatLogMessage(level, domain, message));
  }

  static String _formatLogMessage(
    LogLevel level,
    LogDomain domain,
    String message,
  ) =>
      '${_logTimeStamp()}| '
      '[${_formatDomain(domain)}] '
      '${describeEnum(level)}: $message';

  static String _logTimeStamp() {
    final now = DateTime.now();

    final h = _twoDigits(now.hour);
    final m = _twoDigits(now.minute);
    final s = _twoDigits(now.second);
    final microseconds = now.millisecond * 1000 + now.microsecond;
    final us = _paddedDigits(microseconds, digits: 6);
    return '$h:$m:$s.$us';
  }

  static String _formatDomain(LogDomain domain) {
    switch (domain) {
      case LogDomain.database:
        return 'DB';
      case LogDomain.query:
        return 'Query';
      case LogDomain.replicator:
        return 'Sync';
      case LogDomain.network:
        return 'WS';
    }
  }

  static String _paddedDigits(int value, {required int digits}) =>
      value.toString().padLeft(digits, '0');

  static String _twoDigits(int value) => _paddedDigits(value, digits: 2);
}

// === Impl ====================================================================

extension CBLLogDomainExt on CBLLogDomain {
  LogDomain toLogDomain() => LogDomain.values[index];
}

extension LogDomainExt on LogDomain {
  CBLLogDomain toCBLLogDomain() => CBLLogDomain.values[index];
}

extension CBLLogLevelExt on CBLLogLevel {
  LogLevel toLogLevel() => LogLevel.values[index];
}

extension LogLevelExt on LogLevel {
  CBLLogLevel toCBLLogLevel() => CBLLogLevel.values[index];
}

late final _bindings = cblBindings.logging;

Logger? _logger;
void Function(List<Object?>)? _loggerCallback;
AsyncCallback? _callback;

void setupCustomLogger(Logger? logger) {
  if (_logger == logger) {
    return;
  }

  // Remove older logger
  _cleanUpLogger();

  // Update callback
  if (logger == null) {
    _cleanUpCallback();
  } else {
    _setupCallback();
    // Install new logger only after the callback has been successfully setup.
    _setupLogger(logger);
  }
}

void _setupLogger(Logger logger) {
  _logger = logger;
  // The AsyncCallback is not created every time a Logger is set.
  // The Logger should still be called in the Zone in which it was set.
  _loggerCallback = Zone.current.bindUnaryCallbackGuarded((arguments) {
    final message = LogCallbackMessage.fromArguments(arguments);
    logger.log(
      message.level.toLogLevel(),
      message.domain.toLogDomain(),
      message.message,
    );
  });
  _logger!._levelChanged = _updateLogLevel;
  _updateLogLevel();
}

void _cleanUpLogger() {
  _logger?._levelChanged = null;
  _loggerCallback = null;
  _logger = null;
}

void _updateLogLevel() =>
    _bindings.setCallbackLevel(_logger!._level.toCBLLogLevel());

void _setupCallback() {
  if (_callback != null) {
    return;
  }

  _callback = AsyncCallback(
    (arguments) => _loggerCallback!(arguments),
    debugName: 'Logger.log',
  );

  // Try to set callback as the current global callback.
  if (!_callback!.native.call(_bindings.setCallback)) {
    _cleanUpCallback();
    throw StateError('Another isolate has already set a custom Logger.');
  }
}

void _cleanUpCallback() {
  _callback?.close();
  _callback = null;
}

void cblLogMessage(LogDomain domain, LogLevel level, String message) {
  _bindings.logMessage(domain.toCBLLogDomain(), level.toCBLLogLevel(), message);
}
