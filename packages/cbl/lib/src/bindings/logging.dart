
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'base.dart';
import 'bindings.dart';
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

@immutable
final class CBLLogFileConfiguration {
  const CBLLogFileConfiguration({
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CBLLogFileConfiguration &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          directory == other.directory &&
          maxRotateCount == other.maxRotateCount &&
          maxSize == other.maxSize &&
          usePlainText == other.usePlainText;

  @override
  int get hashCode =>
      level.hashCode ^
      directory.hashCode ^
      maxRotateCount.hashCode ^
      maxSize.hashCode ^
      usePlainText.hashCode;
}

final class LoggingBindings extends Bindings {
  LoggingBindings(super.parent);

  void logMessage(
    CBLLogDomain domain,
    CBLLogLevel level,
    String message,
  ) {
    runWithSingleFLString(
      message,
      (flMessage) => cbl.CBL_LogMessage(
        domain.toInt(),
        level.toInt(),
        flMessage,
      ),
    );
  }

  CBLLogLevel consoleLevel() => cbl.CBLLog_ConsoleLevel().toLogLevel();

  void setConsoleLevel(CBLLogLevel logLevel) {
    cbl.CBLLog_SetConsoleLevel(logLevel.toInt());
  }

  void setCallbackLevel(CBLLogLevel logLevel) {
    cblDart.CBLDart_CBLLog_SetCallbackLevel(logLevel.toInt());
  }

  bool setCallback(cblitedart.CBLDart_AsyncCallback callback) =>
      cblDart.CBLDart_CBLLog_SetCallback(callback);

  void setFileLogConfiguration(CBLLogFileConfiguration? config) {
    withGlobalArena(() {
      cblDart.CBLDart_CBLLog_SetFileConfig(
        _logFileConfig(config),
        globalCBLError,
      ).checkCBLError();
    });
  }

  CBLLogFileConfiguration? getLogFileConfiguration() =>
      cblDart.CBLDart_CBLLog_GetFileConfig()
          .toNullable()
          ?.ref
          .toCBLLogFileConfiguration();

  bool setSentryBreadcrumbs({required bool enabled}) =>
      cblDart.CBLDart_CBLLog_SetSentryBreadcrumbs(enabled);

  Pointer<cblite.CBLLogFileConfiguration> _logFileConfig(
    CBLLogFileConfiguration? config,
  ) {
    if (config == null) {
      return nullptr;
    }

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
