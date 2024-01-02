// ignore: lines_longer_than_80_chars
// ignore_for_file: cast_nullable_to_non_nullable,avoid_redundant_argument_values, avoid_positional_boolean_parameters, avoid_private_typedef_functions, camel_case_types

import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'async_callback.dart';
import 'base.dart';
import 'bindings.dart';
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

typedef _CBL_LogMessage_C = Void Function(
  Uint8 domain,
  Uint8 level,
  FLString message,
);
typedef _CBL_LogMessage = void Function(
  int domain,
  int level,
  FLString message,
);

typedef _CBLLog_ConsoleLevel_C = Uint8 Function();
typedef _CBLLog_ConsoleLevel = int Function();

typedef _CBLLog_SetConsoleLevel_C = Void Function(Uint8 logLevel);
typedef _CBLLog_SetConsoleLevel = void Function(int logLevel);

typedef _CBLDart_CBLLog_SetCallbackLevel_C = Void Function(Uint8 logLevel);
typedef _CBLDart_CBLLog_SetCallbackLevel = void Function(int logLevel);

class LogCallbackMessage {
  LogCallbackMessage(this.domain, this.level, this.message);

  LogCallbackMessage.fromArguments(List<Object?> arguments)
      : this(
          (arguments[0] as int).toLogDomain(),
          (arguments[1] as int).toLogLevel(),
          utf8.decode(arguments[2] as Uint8List, allowMalformed: true),
        );

  final CBLLogDomain domain;
  final CBLLogLevel level;
  final String message;
}

typedef _CBLDart_CBLLog_SetCallback_C = Bool Function(
  Pointer<CBLDartAsyncCallback> callback,
);
typedef _CBLDart_CBLLog_SetCallback = bool Function(
  Pointer<CBLDartAsyncCallback> callback,
);

final class _CBLLogFileConfiguration extends Struct {
  @Uint8()
  external int level;

  external FLString directory;

  @Uint32()
  external int maxRotateCount;

  @Size()
  external int maxSize;

  @Bool()
  external bool usePlainText;
}

extension on _CBLLogFileConfiguration {
  CBLLogFileConfiguration toCBLLogFileConfiguration() =>
      CBLLogFileConfiguration(
        level: level.toLogLevel(),
        directory: directory.toDartString()!,
        maxRotateCount: maxRotateCount,
        maxSize: maxSize,
        usePlainText: usePlainText,
      );
}

class CBLLogFileConfiguration {
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

typedef _CBLDart_CBLLog_SetFileConfig_C = Bool Function(
  Pointer<_CBLLogFileConfiguration> config,
  Pointer<CBLError> errorOut,
);
typedef _CBLDart_CBLLog_SetFileConfig = bool Function(
  Pointer<_CBLLogFileConfiguration> config,
  Pointer<CBLError> errorOut,
);

typedef _CBLDart_CBLLog_GetFileConfig = Pointer<_CBLLogFileConfiguration>
    Function();

typedef _CBLDart_CBLLog_SetSentryBreadcrumbs_C = Bool Function(Bool enabled);
typedef _CBLDart_CBLLog_SetSentryBreadcrumbs = bool Function(bool enabled);

class LoggingBindings extends Bindings {
  LoggingBindings(super.parent) {
    _logMessage = libs.cbl.lookupFunction<_CBL_LogMessage_C, _CBL_LogMessage>(
      'CBL_LogMessage',
      isLeaf: useIsLeaf,
    );
    _consoleLevel =
        libs.cbl.lookupFunction<_CBLLog_ConsoleLevel_C, _CBLLog_ConsoleLevel>(
      'CBLLog_ConsoleLevel',
      isLeaf: useIsLeaf,
    );
    _setConsoleLevel = libs.cbl
        .lookupFunction<_CBLLog_SetConsoleLevel_C, _CBLLog_SetConsoleLevel>(
      'CBLLog_SetConsoleLevel',
      isLeaf: useIsLeaf,
    );
    _setCallbackLevel = libs.cblDart.lookupFunction<
        _CBLDart_CBLLog_SetCallbackLevel_C, _CBLDart_CBLLog_SetCallbackLevel>(
      'CBLDart_CBLLog_SetCallbackLevel',
      isLeaf: useIsLeaf,
    );
    _setCallback = libs.cblDart.lookupFunction<_CBLDart_CBLLog_SetCallback_C,
        _CBLDart_CBLLog_SetCallback>(
      'CBLDart_CBLLog_SetCallback',
      isLeaf: useIsLeaf,
    );
    _setFileConfig = libs.cblDart.lookupFunction<
        _CBLDart_CBLLog_SetFileConfig_C, _CBLDart_CBLLog_SetFileConfig>(
      'CBLDart_CBLLog_SetFileConfig',
      isLeaf: useIsLeaf,
    );
    _getFileConfig = libs.cblDart.lookupFunction<_CBLDart_CBLLog_GetFileConfig,
        _CBLDart_CBLLog_GetFileConfig>(
      'CBLDart_CBLLog_GetFileConfig',
      isLeaf: useIsLeaf,
    );
    _setSentryBreadcrumbs = libs.cblDart.lookupFunction<
        _CBLDart_CBLLog_SetSentryBreadcrumbs_C,
        _CBLDart_CBLLog_SetSentryBreadcrumbs>(
      'CBLDart_CBLLog_SetSentryBreadcrumbs',
      isLeaf: useIsLeaf,
    );
  }

  late final _CBL_LogMessage _logMessage;
  late final _CBLLog_ConsoleLevel _consoleLevel;
  late final _CBLLog_SetConsoleLevel _setConsoleLevel;
  late final _CBLDart_CBLLog_SetCallbackLevel _setCallbackLevel;
  late final _CBLDart_CBLLog_SetCallback _setCallback;
  late final _CBLDart_CBLLog_SetFileConfig _setFileConfig;
  late final _CBLDart_CBLLog_GetFileConfig _getFileConfig;
  late final _CBLDart_CBLLog_SetSentryBreadcrumbs _setSentryBreadcrumbs;

  void logMessage(
    CBLLogDomain domain,
    CBLLogLevel level,
    String message,
  ) {
    runWithSingleFLString(
      message,
      (flMessage) => _logMessage(domain.toInt(), level.toInt(), flMessage),
    );
  }

  CBLLogLevel consoleLevel() => _consoleLevel().toLogLevel();

  void setConsoleLevel(CBLLogLevel logLevel) {
    _setConsoleLevel(logLevel.toInt());
  }

  void setCallbackLevel(CBLLogLevel logLevel) {
    _setCallbackLevel(logLevel.toInt());
  }

  bool setCallback(Pointer<CBLDartAsyncCallback> callback) =>
      _setCallback(callback);

  void setFileLogConfiguration(CBLLogFileConfiguration? config) {
    withGlobalArena(() {
      _setFileConfig(
        _logFileConfig(config),
        globalCBLError,
      ).checkCBLError();
    });
  }

  CBLLogFileConfiguration? getLogFileConfiguration() =>
      _getFileConfig().toNullable()?.ref.toCBLLogFileConfiguration();

  bool setSentryBreadcrumbs({required bool enabled}) =>
      _setSentryBreadcrumbs(enabled);

  Pointer<_CBLLogFileConfiguration> _logFileConfig(
    CBLLogFileConfiguration? config,
  ) {
    // ignore: always_put_control_body_on_new_line
    if (config == null) return nullptr;

    final result = globalArena<_CBLLogFileConfiguration>();

    result.ref
      ..level = config.level.toInt()
      ..directory = config.directory.toFLString()
      ..maxRotateCount = config.maxRotateCount
      ..maxSize = config.maxSize
      ..usePlainText = config.usePlainText;

    return result;
  }
}
