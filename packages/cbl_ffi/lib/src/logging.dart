import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../cbl_ffi.dart';
import 'async_callback.dart';
import 'bindings.dart';
import 'utils.dart';

enum CBLLogDomain {
  all,
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

typedef CBLDart_CBL_LogMessage_C = Void Function(
  Uint8 domain,
  Uint8 level,
  FLString message,
);
typedef CBLDart_CBL_LogMessage = void Function(
  int domain,
  int level,
  FLString message,
);

typedef CBLLog_ConsoleLevel_C = Uint8 Function();
typedef CBLLog_ConsoleLevel = int Function();

typedef CBLLog_SetConsoleLevel_C = Void Function(Uint8 logLevel);
typedef CBLLog_SetConsoleLevel = void Function(int logLevel);

typedef CBLLog_SetCallbackLevel_C = Void Function(Uint8 logLevel);
typedef CBLLog_SetCallbackLevel = void Function(int logLevel);

class LogCallbackMessage {
  LogCallbackMessage(this.domain, this.level, this.message);

  LogCallbackMessage.fromArguments(List<dynamic> arguments)
      : this(
          (arguments[0] as int).toLogDomain(),
          (arguments[1] as int).toLogLevel(),
          utf8.decode(arguments[2] as Uint8List),
        );

  final CBLLogDomain domain;
  final CBLLogLevel level;
  final String message;
}

typedef CBLDart_CBLLog_SetCallback_C = Uint8 Function(
  Pointer<CBLDartAsyncCallback> callback,
);
typedef CBLDart_CBLLog_SetCallback = int Function(
  Pointer<CBLDartAsyncCallback> callback,
);

class _CBLDart_CBLLogFileConfiguration extends Struct {
  @Uint8()
  external int level;

  external FLString directory;

  @Uint32()
  external int maxRotateCount;

  @Uint64()
  external int maxSize;

  @Uint8()
  external int usePlainText;
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
}

typedef CBLDart_CBLLog_SetFileConfig_C = Uint8 Function(
  Pointer<_CBLDart_CBLLogFileConfiguration> configuration,
  Uint32 capability,
  Pointer<CBLError> errorOut,
);
typedef CBLDart_CBLLog_SetFileConfig = int Function(
  Pointer<_CBLDart_CBLLogFileConfiguration> configuration,
  int capability,
  Pointer<CBLError> errorOut,
);

class LoggingBindings extends Bindings {
  LoggingBindings(Bindings parent) : super(parent) {
    _logMessage = libs.cblDart
        .lookupFunction<CBLDart_CBL_LogMessage_C, CBLDart_CBL_LogMessage>(
      'CBLDart_CBL_LogMessage',
    );
    _consoleLevel =
        libs.cbl.lookupFunction<CBLLog_ConsoleLevel_C, CBLLog_ConsoleLevel>(
      'CBLLog_ConsoleLevel',
    );
    _setConsoleLevel = libs.cbl
        .lookupFunction<CBLLog_SetConsoleLevel_C, CBLLog_SetConsoleLevel>(
      'CBLLog_SetConsoleLevel',
    );
    _setCallbackLevel = libs.cbl
        .lookupFunction<CBLLog_SetCallbackLevel_C, CBLLog_SetCallbackLevel>(
      'CBLLog_SetCallbackLevel',
    );
    _setCallback = libs.cblDart.lookupFunction<CBLDart_CBLLog_SetCallback_C,
        CBLDart_CBLLog_SetCallback>(
      'CBLDart_CBLLog_SetCallback',
    );
    _setFileConfig = libs.cblDart.lookupFunction<CBLDart_CBLLog_SetFileConfig_C,
        CBLDart_CBLLog_SetFileConfig>(
      'CBLDart_CBLLog_SetFileConfig',
    );
  }

  final _logFileConfigCapability = Random.secure().nextInt(1 << 32) + 1;

  late final CBLDart_CBL_LogMessage _logMessage;
  late final CBLLog_ConsoleLevel _consoleLevel;
  late final CBLLog_SetConsoleLevel _setConsoleLevel;
  late final CBLLog_SetCallbackLevel _setCallbackLevel;
  late final CBLDart_CBLLog_SetCallback _setCallback;
  late final CBLDart_CBLLog_SetFileConfig _setFileConfig;

  void logMessage(
    CBLLogDomain domain,
    CBLLogLevel level,
    String message,
  ) {
    stringTable.autoFree(() => _logMessage(
          domain.toInt(),
          level.toInt(),
          stringTable.flString(message, cache: false).ref,
        ));
  }

  CBLLogLevel consoleLevel() {
    return _consoleLevel().toLogLevel();
  }

  void setConsoleLevel(CBLLogLevel logLevel) {
    _setConsoleLevel(logLevel.toInt());
  }

  void setCallbackLevel(CBLLogLevel logLevel) {
    _setCallbackLevel(logLevel.toInt());
  }

  bool setCallback(Pointer<CBLDartAsyncCallback> callback) {
    return _setCallback(callback).toBool();
  }

  bool setFileLogConfiguration(CBLLogFileConfiguration? configuration) {
    return withZoneArena(() {
      final result = _setFileConfig(
        configuration != null ? _logFileConfig(configuration) : nullptr,
        _logFileConfigCapability,
        globalCBLError,
      );

      // The config could not be set because another isolate has already set
      // a config.
      if (result == 3) {
        return false;
      }

      result.checkCBLError();

      return true;
    });
  }

  Pointer<_CBLDart_CBLLogFileConfiguration> _logFileConfig(
    CBLLogFileConfiguration config,
  ) {
    final result = zoneArena<_CBLDart_CBLLogFileConfiguration>();

    result.ref
      ..level = config.level.toInt()
      ..directory = stringTable.flString(config.directory, arena: true).ref
      ..maxRotateCount = config.maxRotateCount
      ..maxSize = config.maxSize
      ..usePlainText = config.usePlainText.toInt();

    return result;
  }
}
