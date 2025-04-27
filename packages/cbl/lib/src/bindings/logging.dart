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
  database(cblite.kCBLLogDomainDatabase),
  query(cblite.kCBLLogDomainQuery),
  replicator(cblite.kCBLLogDomainReplicator),
  network(cblite.kCBLLogDomainNetwork);

  const CBLLogDomain(this.value);

  factory CBLLogDomain.fromValue(int value) => switch (value) {
        cblite.kCBLLogDomainDatabase => database,
        cblite.kCBLLogDomainQuery => query,
        cblite.kCBLLogDomainReplicator => replicator,
        cblite.kCBLLogDomainNetwork => network,
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

extension on cblite.CBLLogFileConfiguration {
  CBLLogFileConfiguration toCBLLogFileConfiguration() =>
      CBLLogFileConfiguration(
        level: CBLLogLevel.fromValue(level),
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
  LoggingBindings(super.libraries);

  void logMessage(
    CBLLogDomain domain,
    CBLLogLevel level,
    String message,
  ) {
    runWithSingleFLString(
      message,
      (flMessage) => cbl.CBL_LogMessage(
        domain.value,
        level.value,
        flMessage,
      ),
    );
  }

  CBLLogLevel consoleLevel() =>
      CBLLogLevel.fromValue(cbl.CBLLog_ConsoleLevel());

  void setConsoleLevel(CBLLogLevel logLevel) {
    cbl.CBLLog_SetConsoleLevel(logLevel.value);
  }

  void setCallbackLevel(CBLLogLevel logLevel) {
    cblDart.CBLDart_CBLLog_SetCallbackLevel(logLevel.value);
  }

  bool setCallback(cblitedart.CBLDart_AsyncCallback callback) =>
      cblDart.CBLDart_CBLLog_SetCallback(callback);

  void setFileLogConfiguration(CBLLogFileConfiguration? config) {
    withGlobalArena(() {
      cblDart.CBLDart_CBLLog_SetFileConfig(
        _logFileConfig(config),
        globalCBLError,
      ).checkError();
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
      ..level = config.level.value
      ..directory = config.directory.toFLString()
      ..maxRotateCount = config.maxRotateCount
      ..maxSize = config.maxSize
      ..usePlaintext = config.usePlainText;

    return result;
  }
}
