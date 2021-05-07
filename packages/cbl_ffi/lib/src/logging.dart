import 'dart:ffi';

import 'bindings.dart';
import 'native_callback.dart';

enum CBLLogDomain {
  all,
  database,
  query,
  replicator,
  network,
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

typedef CBLLog_ConsoleLevel_C = Uint8 Function();
typedef CBLLog_ConsoleLevel = int Function();

typedef CBLLog_SetConsoleLevel_C = Void Function(Uint8 logLevel);
typedef CBLLog_SetConsoleLevel = void Function(int logLevel);

typedef CBLDart_CBLLog_RestoreOriginalCallback_C = Void Function();
typedef CBLDart_CBLLog_RestoreOriginalCallback = void Function();

class LogCallbackMessage {
  LogCallbackMessage(this.domain, this.level, this.message);

  LogCallbackMessage.fromArguments(List<dynamic> arguments)
      : this(
          (arguments[0] as int).toLogDomain(),
          (arguments[1] as int).toLogLevel(),
          arguments[2] as String,
        );

  final CBLLogDomain domain;
  final CBLLogLevel level;
  final String message;
}

typedef CBLDart_CBLLog_SetCallback_C = Void Function(
  Pointer<Callback> callback,
);
typedef CBLDart_CBLLog_SetCallback = void Function(
  Pointer<Callback> callback,
);

class LoggingBindings extends Bindings {
  LoggingBindings(Bindings parent) : super(parent) {
    _consoleLevel =
        libs.cbl.lookupFunction<CBLLog_ConsoleLevel_C, CBLLog_ConsoleLevel>(
      'CBLLog_ConsoleLevel',
    );
    _setConsoleLevel = libs.cbl
        .lookupFunction<CBLLog_SetConsoleLevel_C, CBLLog_SetConsoleLevel>(
      'CBLLog_SetConsoleLevel',
    );
    _restoreOriginalCallback = libs.cblDart.lookupFunction<
        CBLDart_CBLLog_RestoreOriginalCallback_C,
        CBLDart_CBLLog_RestoreOriginalCallback>(
      'CBLDart_CBLLog_RestoreOriginalCallback',
    );
    _setCallback = libs.cblDart.lookupFunction<CBLDart_CBLLog_SetCallback_C,
        CBLDart_CBLLog_SetCallback>(
      'CBLDart_CBLLog_SetCallback',
    );
  }

  late final CBLLog_ConsoleLevel _consoleLevel;
  late final CBLLog_SetConsoleLevel _setConsoleLevel;
  late final CBLDart_CBLLog_RestoreOriginalCallback _restoreOriginalCallback;
  late final CBLDart_CBLLog_SetCallback _setCallback;

  CBLLogLevel consoleLevel() {
    return _consoleLevel().toLogLevel();
  }

  void setConsoleLevel(CBLLogLevel logLevel) {
    _setConsoleLevel(logLevel.toInt());
  }

  // TODO: does not actually work because the original callback returend by
  // the cbl API is `null`
  void restoreOriginalCallback() {
    _restoreOriginalCallback();
  }

  void setCallback(Pointer<Callback> callback) {
    _setCallback(callback);
  }
}
