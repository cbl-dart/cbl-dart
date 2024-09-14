import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'base.dart';
import 'cblite.dart' as cblite;
import 'cblitedart.dart' as cblitedart;
import 'fleece.dart';
import 'global.dart';
import 'utils.dart';

enum CBLLogDomain {
  database,
  query,
  replicator,
  network,
}

extension on CBLLogDomain {
  int toInt() => CBLLogDomain.values.indexOf(this);
}

extension on int {
  CBLLogDomain toLogDomain() => CBLLogDomain.values[this];
}

enum CBLLogLevel {
  debug,
  verbose,
  info,
  warning,
  error,
  none,
}

extension on CBLLogLevel {
  int toInt() => CBLLogLevel.values.indexOf(this);
}

extension on int {
  CBLLogLevel toLogLevel() => CBLLogLevel.values[this];
}

final class LogCallbackMessage {
  LogCallbackMessage(this.domain, this.level, this.message);

  LogCallbackMessage.fromArguments(List<Object?> arguments)
      : this(
          (arguments[0]! as int).toLogDomain(),
          (arguments[1]! as int).toLogLevel(),
          utf8.decode(arguments[2]! as Uint8List, allowMalformed: true),
        );

  final CBLLogDomain domain;
  final CBLLogLevel level;
  final String message;
}

extension on cblite.CBLLogFileConfiguration {
  CBLLogFileConfiguration toCBLLogFileConfiguration() =>
      CBLLogFileConfiguration(
        level: level.toLogLevel(),
        directory: directory.toDartString()!,
        maxRotateCount: maxRotateCount,
        maxSize: maxSize,
        usePlainText: usePlaintext,
      );
}

final class CBLLogFileConfiguration {
  CBLLogFileConfiguration({
    required this.level,
    required this.directory,
    required this.maxRotateCount,
    required this.maxSize,
    required this.usePlainText,
  });

  final CBLLogLevel level;
  final String directory;
  final int maxRotateCount;
  final int maxSize;
  final bool usePlainText;

  CBLLogFileConfiguration copyWith({
    CBLLogLevel? level,
    String? directory,
    int? maxRotateCount,
    int? maxSize,
    bool? usePlainText,
  }) =>
      CBLLogFileConfiguration(
        level: level ?? this.level,
        directory: directory ?? this.directory,
        maxRotateCount: maxRotateCount ?? this.maxRotateCount,
        maxSize: maxSize ?? this.maxSize,
        usePlainText: usePlainText ?? this.usePlainText,
      );

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CBLLogFileConfiguration &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          directory == other.directory &&
          maxRotateCount == other.maxRotateCount &&
          maxSize == other.maxSize &&
          usePlainText == other.usePlainText;
}

final class LoggingBindings {
  const LoggingBindings();

  void logMessage(
    CBLLogDomain domain,
    CBLLogLevel level,
    String message,
  ) {
    runWithSingleFLString(
      message,
      (flMessage) =>
          cblite.CBL_LogMessage(domain.toInt(), level.toInt(), flMessage),
    );
  }

  CBLLogLevel consoleLevel() => cblite.CBLLog_ConsoleLevel().toLogLevel();

  void setConsoleLevel(CBLLogLevel logLevel) {
    cblite.CBLLog_SetConsoleLevel(logLevel.toInt());
  }

  void setCallbackLevel(CBLLogLevel logLevel) {
    cblitedart.CBLDart_CBLLog_SetCallbackLevel(logLevel.toInt());
  }

  bool setCallback(cblitedart.CBLDart_AsyncCallback callback) =>
      cblitedart.CBLDart_CBLLog_SetCallback(callback);

  void setFileLogConfiguration(CBLLogFileConfiguration? config) {
    withGlobalArena(() {
      cblitedart.CBLDart_CBLLog_SetFileConfig(
        _logFileConfig(config),
        globalCBLError,
      ).checkCBLError();
    });
  }

  CBLLogFileConfiguration? getLogFileConfiguration() =>
      cblitedart.CBLDart_CBLLog_GetFileConfig()
          .toNullable()
          ?.ref
          .toCBLLogFileConfiguration();

  bool setSentryBreadcrumbs({required bool enabled}) =>
      cblitedart.CBLDart_CBLLog_SetSentryBreadcrumbs(enabled);

  Pointer<cblite.CBLLogFileConfiguration> _logFileConfig(
    CBLLogFileConfiguration? config,
  ) {
    // ignore: always_put_control_body_on_new_line
    if (config == null) return nullptr;

    final result = globalArena<cblite.CBLLogFileConfiguration>();

    result.ref
      ..level = config.level.toInt()
      ..directory = config.directory.toFLString()
      ..maxRotateCount = config.maxRotateCount
      ..maxSize = config.maxSize
      ..usePlaintext = config.usePlainText;

    return result;
  }
}
