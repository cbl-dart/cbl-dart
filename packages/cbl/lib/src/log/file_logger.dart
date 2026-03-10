// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'dart:io';

import '../bindings.dart';
import 'logger.dart';

/// The configuration for log files.
///
/// {@category Logging}
final class LogFileConfiguration {
  /// Creates the configuration for log files.
  LogFileConfiguration({
    required this.directory,
    this.usePlainText = false,
    int? maxSize,
    int? maxKeptFiles,
  }) {
    this.maxSize = maxSize ?? this.maxSize;
    this.maxKeptFiles = maxKeptFiles ?? this.maxKeptFiles;
  }

  /// Creates a [LogFileConfiguration] from [config] by copying all properties.
  LogFileConfiguration.from(LogFileConfiguration config)
    : directory = config.directory,
      usePlainText = config.usePlainText,
      _maxSize = config.maxSize,
      _maxKeptFiles = config.maxKeptFiles;

  static const _defaultMaxSize = 500 * 1024;
  static const _defaultMaxKeptFiles = 1;

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
      throw RangeError.range(maxSize, 1, null, 'maxSize');
    }
    _maxSize = maxSize;
  }

  /// The maximum number of log files to keep per log level.
  ///
  /// The default is 1 which means one backup for a total of 2 log files.
  int get maxKeptFiles => _maxKeptFiles;
  int _maxKeptFiles = _defaultMaxKeptFiles;

  set maxKeptFiles(int maxKeptFiles) {
    if (maxKeptFiles < 0) {
      throw RangeError.range(maxKeptFiles, 0, null, 'maxKeptFiles');
    }
    _maxKeptFiles = maxKeptFiles;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogFileConfiguration &&
          runtimeType == other.runtimeType &&
          directory == other.directory &&
          usePlainText == other.usePlainText &&
          maxSize == other.maxSize &&
          maxKeptFiles == other.maxKeptFiles;

  @override
  int get hashCode =>
      directory.hashCode ^
      usePlainText.hashCode ^
      maxSize.hashCode ^
      maxKeptFiles.hashCode;

  @override
  String toString() => [
    'LogFileConfiguration(',
    [
      'directory: $directory',
      if (usePlainText) 'USE-PLAIN-TEXT',
      'maxSize: ${(maxSize / 1024).toStringAsFixed(1)} KB',
      'maxKeptFiles: $maxKeptFiles',
    ].join(', '),
    ')',
  ].join();
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
///
/// {@category Logging}
abstract final class FileLogger {
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

final class FileLoggerImpl extends FileLogger {
  @override
  LogFileConfiguration? get config =>
      LoggingBindings.getLogFileConfiguration()?.toLogFileConfiguration();

  @override
  set config(LogFileConfiguration? config) => _update(config);

  @override
  LogLevel get level =>
      LoggingBindings.getLogFileConfiguration()?.level.toLogLevel() ?? _level;
  LogLevel _level = LogLevel.none;

  @override
  set level(LogLevel level) {
    _level = level;
    _update(config);
  }

  void _update(LogFileConfiguration? config) {
    final oldConfig = LoggingBindings.getLogFileConfiguration();

    CBLLogFileConfiguration? newConfig;
    if (config != null) {
      // Ensure that the directory exists.
      final directory = Directory(config.directory);
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      newConfig = CBLLogFileConfiguration(
        level: _level.toCBLLogLevel(),
        directory: config.directory,
        maxKeptFiles: config.maxKeptFiles,
        maxSize: config.maxSize,
        usePlainText: config.usePlainText,
      );
    }

    if (oldConfig != newConfig) {
      LoggingBindings.setFileLogConfiguration(newConfig);
    }
  }
}

extension on CBLLogFileConfiguration {
  LogFileConfiguration? toLogFileConfiguration() => LogFileConfiguration(
    directory: directory,
    usePlainText: usePlainText,
    maxKeptFiles: maxKeptFiles,
    maxSize: maxSize,
  );
}
