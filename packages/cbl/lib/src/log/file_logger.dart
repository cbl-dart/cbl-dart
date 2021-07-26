import 'package:cbl_ffi/cbl_ffi.dart';

import 'logger.dart';

/// The configuration for log files.
class LogFileConfiguration {
  /// Creates the configuration for log files.
  LogFileConfiguration({
    required this.directory,
    this.usePlainText = false,
    int? maxSize,
    int? maxRotateCount,
  }) {
    this.maxSize = maxSize ?? this.maxSize;
    this.maxRotateCount = maxRotateCount ?? this.maxRotateCount;
  }

  /// Creates a [LogFileConfiguration] from [config] by copying all properties.
  LogFileConfiguration.from(LogFileConfiguration config)
      : directory = config.directory,
        usePlainText = config.usePlainText,
        _maxSize = config.maxSize,
        _maxRotateCount = config.maxRotateCount;

  static const _defaultMaxSize = 500 * 1024;
  static const _defaultMaxRotateCount = 1;

  /// The directory to store the log files in.
  final String directory;

  /// Whether to use the plain text file format instead of the default binary
  /// format.
  bool usePlainText;

  /// The maximum size of a log file before being rotated, in bytes.
  ///
  /// The default is 500 KB.
  int get maxSize => _maxSize;
  int _maxSize = _defaultMaxSize;

  set maxSize(int maxSize) {
    if (maxSize <= 0) {
      throw ArgumentError.value(maxSize, 'maxSize', 'must be greater than 0');
    }
    _maxSize = maxSize;
  }

  /// The maximum number of rotated log files to keep.
  ///
  /// The default is 1 which means one backup for a total of 2 log files.
  int get maxRotateCount => _maxRotateCount;
  int _maxRotateCount = _defaultMaxRotateCount;

  set maxRotateCount(int maxRotateCount) {
    if (maxRotateCount <= 0) {
      throw ArgumentError.value(
        maxRotateCount,
        'maxRotateCount',
        'must be greater or the same as 0',
      );
    }
    _maxRotateCount = maxRotateCount;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogFileConfiguration &&
          runtimeType == other.runtimeType &&
          directory == other.directory &&
          usePlainText == other.usePlainText &&
          maxSize == other.maxSize &&
          maxRotateCount == other.maxRotateCount;
}

/// Logger for writing log messages to files.
///
/// To enable the file logger, setup the log file configuration and specify the
/// log level as desired.
///
/// It is important to configure your [LogFileConfiguration] object
/// appropriately before setting it in the logger. The logger makes a copy of
/// the instance you provide and uses that copy. Once configured, the logger
/// object ignores any changes you make to the configuration.
abstract class FileLogger {
  FileLogger._();

  /// The log file configuration the logger currently uses.
  ///
  /// This property is `null` by default. Setting it to `null` disables file
  /// logging.
  LogFileConfiguration? get config;
  set config(LogFileConfiguration? value);

  /// The minimum log level of the messages to be logged.
  ///
  /// The default log level for the file logger is [LogLevel.none], which means
  /// no logging at all.
  LogLevel get level;
  set level(LogLevel value);
}

// === Impl ====================================================================

late final _bindings = CBLBindings.instance.logging;

class FileLoggerImpl extends FileLogger {
  FileLoggerImpl() : super._();

  @override
  LogFileConfiguration? get config =>
      _config != null ? LogFileConfiguration.from(_config!) : null;
  LogFileConfiguration? _config;

  @override
  set config(LogFileConfiguration? config) {
    if (_config == config) {
      return;
    }
    _updateConfig(_level, config);
  }

  @override
  LogLevel get level => _level;
  LogLevel _level = LogLevel.none;

  @override
  set level(LogLevel level) {
    if (_level == level) {
      return;
    }
    _updateConfig(level, _config);
  }

  void _updateConfig(LogLevel level, LogFileConfiguration? config) {
    if (config == null) {
      if (_config == null) {
        return;
      }

      _bindings.setFileLogConfiguration(null);
      _config = null;
      return;
    }

    final cblConfig = CBLLogFileConfiguration(
      level: level.toCBLLogLevel(),
      directory: config.directory,
      maxRotateCount: config.maxRotateCount,
      maxSize: config.maxSize,
      usePlainText: config.usePlainText,
    );

    if (!_bindings.setFileLogConfiguration(cblConfig)) {
      throw StateError(
        'Another isolate has already set a log file configuration.',
      );
    }

    _config = LogFileConfiguration.from(config);
    _level = level;
  }
}
