import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'bindings.dart';
import 'cblite.dart' as cblite_lib;
import 'cblitedart.dart' as cblitedart_lib;
import 'fleece.dart';
import 'global.dart';
import 'utils.dart';

enum CBLLogDomain {
  database(cblite_lib.kCBLLogDomainDatabase),
  query(cblite_lib.kCBLLogDomainQuery),
  replicator(cblite_lib.kCBLLogDomainReplicator),
  network(cblite_lib.kCBLLogDomainNetwork),
  listener(cblite_lib.kCBLLogDomainListener);

  const CBLLogDomain(this.value);

  factory CBLLogDomain.fromValue(int value) => switch (value) {
    cblite_lib.kCBLLogDomainDatabase => database,
    cblite_lib.kCBLLogDomainQuery => query,
    cblite_lib.kCBLLogDomainReplicator => replicator,
    cblite_lib.kCBLLogDomainNetwork => network,
    cblite_lib.kCBLLogDomainListener => listener,
    _ => throw ArgumentError('Unknown log domain: $value'),
  };

  final int value;
}

enum CBLLogLevel {
  debug(cblite_lib.kCBLLogDebug),
  verbose(cblite_lib.kCBLLogVerbose),
  info(cblite_lib.kCBLLogInfo),
  warning(cblite_lib.kCBLLogWarning),
  error(cblite_lib.kCBLLogError),
  none(cblite_lib.kCBLLogNone);

  const CBLLogLevel(this.value);

  factory CBLLogLevel.fromValue(int value) => switch (value) {
    cblite_lib.kCBLLogDebug => debug,
    cblite_lib.kCBLLogVerbose => verbose,
    cblite_lib.kCBLLogInfo => info,
    cblite_lib.kCBLLogWarning => warning,
    cblite_lib.kCBLLogError => error,
    cblite_lib.kCBLLogNone => none,
    _ => throw ArgumentError('Unknown log level: $value'),
  };

  final int value;
}

final class LogCallbackMessage {
  LogCallbackMessage(this.domain, this.level, this.message);

  LogCallbackMessage.fromArguments(List<Object?> arguments)
    : this(
        CBLLogDomain.fromValue(arguments[0]! as int),
        CBLLogLevel.fromValue(arguments[1]! as int),
        utf8.decode(arguments[2]! as Uint8List, allowMalformed: true),
      );

  final CBLLogDomain domain;
  final CBLLogLevel level;
  final String message;
}

extension on cblite_lib.CBLFileLogSink {
  CBLLogFileConfiguration toCBLLogFileConfiguration() =>
      CBLLogFileConfiguration(
        level: CBLLogLevel.fromValue(level),
        directory: directory.toDartString()!,
        maxKeptFiles: maxKeptFiles,
        maxSize: maxSize,
        usePlainText: usePlaintext,
      );
}

@immutable
final class CBLLogFileConfiguration {
  const CBLLogFileConfiguration({
    required this.level,
    required this.directory,
    required this.maxKeptFiles,
    required this.maxSize,
    required this.usePlainText,
  });

  final CBLLogLevel level;
  final String directory;
  final int maxKeptFiles;
  final int maxSize;
  final bool usePlainText;

  CBLLogFileConfiguration copyWith({
    CBLLogLevel? level,
    String? directory,
    int? maxKeptFiles,
    int? maxSize,
    bool? usePlainText,
  }) => CBLLogFileConfiguration(
    level: level ?? this.level,
    directory: directory ?? this.directory,
    maxKeptFiles: maxKeptFiles ?? this.maxKeptFiles,
    maxSize: maxSize ?? this.maxSize,
    usePlainText: usePlainText ?? this.usePlainText,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CBLLogFileConfiguration &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          directory == other.directory &&
          maxKeptFiles == other.maxKeptFiles &&
          maxSize == other.maxSize &&
          usePlainText == other.usePlainText;

  @override
  int get hashCode =>
      level.hashCode ^
      directory.hashCode ^
      maxKeptFiles.hashCode ^
      maxSize.hashCode ^
      usePlainText.hashCode;
}

final class LoggingBindings extends Bindings {
  LoggingBindings(super.libraries);

  void logMessage(CBLLogDomain domain, CBLLogLevel level, String message) {
    runWithSingleFLString(
      message,
      (flMessage) =>
          cblite.CBL_LogMessage(domain.value, level.value, flMessage),
    );
  }

  CBLLogLevel consoleLevel() =>
      CBLLogLevel.fromValue(cblite.CBLLogSinks_Console().level);

  void setConsoleLevel(CBLLogLevel logLevel) {
    final sink = cblite.CBLLogSinks_Console()..level = logLevel.value;
    cblite.CBLLogSinks_SetConsole(sink);
  }

  void setCallbackLevel(CBLLogLevel logLevel) {
    cblitedart.CBLDart_CBLLog_SetCallbackLevel(logLevel.value);
  }

  bool setCallback(cblitedart_lib.CBLDart_AsyncCallback callback) =>
      cblitedart.CBLDart_CBLLog_SetCallback(callback);

  void setFileLogConfiguration(CBLLogFileConfiguration? config) {
    withGlobalArena(() {
      cblitedart.CBLDart_CBLLog_SetFileSink(_logFileSink(config));
    });
  }

  CBLLogFileConfiguration? getLogFileConfiguration() =>
      cblitedart.CBLDart_CBLLog_GetFileSink()
          .toNullable()
          ?.ref
          .toCBLLogFileConfiguration();

  bool setSentryBreadcrumbs({required bool enabled}) =>
      cblitedart.CBLDart_CBLLog_SetSentryBreadcrumbs(enabled);

  Pointer<cblite_lib.CBLFileLogSink> _logFileSink(
    CBLLogFileConfiguration? config,
  ) {
    if (config == null) {
      return nullptr;
    }

    final result = globalArena<cblite_lib.CBLFileLogSink>();

    result.ref
      ..level = config.level.value
      ..directory = config.directory.toFLString()
      ..maxKeptFiles = config.maxKeptFiles
      ..maxSize = config.maxSize
      ..usePlaintext = config.usePlainText;

    return result;
  }
}
