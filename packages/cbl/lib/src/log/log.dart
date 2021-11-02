import 'console_logger.dart';
import 'file_logger.dart';
import 'logger.dart';

/// Configuration of the [ConsoleLogger], [FileLogger] and a custom [Logger].
///
/// {@category Logging}
abstract class Log {
  Log._();

  /// Console logger writing messages to the system console.
  ConsoleLogger get console;

  /// File logger writing log messages to files.
  FileLogger get file;

  /// The currently set custom [Logger].
  Logger? get custom;
  set custom(Logger? value);
}

class LogImpl extends Log {
  LogImpl() : super._();

  /// Console logger writing messages to the system console.
  @override
  final console = ConsoleLoggerImpl();

  /// File logger writing log messages to files.
  @override
  final file = FileLoggerImpl();

  /// The currently set custom [Logger].
  @override
  Logger? get custom => _custom;
  Logger? _custom;

  @override
  set custom(Logger? value) {
    if (_custom != value) {
      _custom = value;
      setupCustomLogger(value);
    }
  }
}
