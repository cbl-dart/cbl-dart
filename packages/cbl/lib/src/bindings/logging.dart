import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'cblite.dart' as cblite;
import 'cblitedart.dart' as cblitedart;
import 'fleece.dart';
import 'utils.dart';

enum CBLLogDomain {
  database(cblite.kCBLLogDomainDatabase),
  query(cblite.kCBLLogDomainQuery),
  replicator(cblite.kCBLLogDomainReplicator),
  network(cblite.kCBLLogDomainNetwork),
  listener(cblite.kCBLLogDomainListener);

  const CBLLogDomain(this.value);

  factory CBLLogDomain.fromValue(int value) => switch (value) {
    cblite.kCBLLogDomainDatabase => database,
    cblite.kCBLLogDomainQuery => query,
    cblite.kCBLLogDomainReplicator => replicator,
    cblite.kCBLLogDomainNetwork => network,
    cblite.kCBLLogDomainListener => listener,
    _ => throw ArgumentError('Unknown log domain: $value'),
  };

  final int value;
}

enum CBLLogLevel {
  debug(cblite.kCBLLogDebug),
  verbose(cblite.kCBLLogVerbose),
  info(cblite.kCBLLogInfo),
  warning(cblite.kCBLLogWarning),
  error(cblite.kCBLLogError),
  none(cblite.kCBLLogNone);

  const CBLLogLevel(this.value);

  factory CBLLogLevel.fromValue(int value) => switch (value) {
    cblite.kCBLLogDebug => debug,
    cblite.kCBLLogVerbose => verbose,
    cblite.kCBLLogInfo => info,
    cblite.kCBLLogWarning => warning,
    cblite.kCBLLogError => error,
    cblite.kCBLLogNone => none,
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

extension on cblite.CBLFileLogSink {
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

final class LoggingBindings {
  static void logMessage(
    CBLLogDomain domain,
    CBLLogLevel level,
    String message,
  ) {
    final encoded = utf8.encode(message);
    cblitedart.CBLDart_CBL_LogMessage(
      domain.value,
      level.value,
      encoded.address.cast(),
      encoded.length,
    );
  }

  static CBLLogLevel consoleLevel() =>
      CBLLogLevel.fromValue(cblite.CBLLogSinks_Console().level);

  static void setConsoleLevel(CBLLogLevel logLevel) {
    final sink = cblite.CBLLogSinks_Console()..level = logLevel.value;
    cblite.CBLLogSinks_SetConsole(sink);
  }

  static void setCallbackLevel(CBLLogLevel logLevel) {
    cblitedart.CBLDart_CBLLog_SetCallbackLevel(logLevel.value);
  }

  static bool setCallback(cblitedart.CBLDart_AsyncCallback callback) =>
      cblitedart.CBLDart_CBLLog_SetCallback(callback);

  static void setFileLogConfiguration(CBLLogFileConfiguration? config) {
    if (config == null) {
      cblitedart.CBLDart_CBLLog_SetFileSink(nullptr);
      return;
    }

    final encoded = utf8.encode(config.directory);
    cblitedart.CBLDart_CBLLog_SetFileSinkV2(
      config.level.value,
      encoded.address.cast(),
      encoded.length,
      config.maxKeptFiles,
      config.maxSize,
      config.usePlainText,
    );
  }

  static CBLLogFileConfiguration? getLogFileConfiguration() =>
      cblitedart.CBLDart_CBLLog_GetFileSink()
          .toNullable()
          ?.ref
          .toCBLLogFileConfiguration();

  static bool setSentryBreadcrumbs({required bool enabled}) =>
      cblitedart.CBLDart_CBLLog_SetSentryBreadcrumbs(enabled);
}
