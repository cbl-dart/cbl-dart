import 'dart:ffi';

import 'bindings.dart';

/// Subsystems that log information.
enum LogDomain {
  all,
  database,
  query,
  replicator,
  network,
}

extension IntLogDomainExt on LogDomain {
  int get toInt => LogDomain.values.indexOf(this);
}

extension LogDomainIntExt on int {
  LogDomain get toLogDomain => LogDomain.values[this];
}

/// Levels of log messages. Higher values are more important/severe. Each level
/// includes the lower ones.
enum LogLevel {
  /// Extremely detailed messages, only written by debug builds of CBL.
  debug,

  /// Detailed messages about normally-unimportant stuff.
  verbose,

  /// Messages about ordinary behavior.
  info,

  /// Messages warning about unlikely and possibly bad stuff.
  warning,

  /// Messages about errors
  error,

  /// Disables logging entirely.
  none
}

extension IntLogLevelExt on LogLevel {
  int get toInt => LogLevel.values.indexOf(this);
}

extension LogLevelIntExt on int {
  LogLevel get toLogLevel => LogLevel.values[this];
}

typedef CBLLog_ConsoleLevel_C = Uint8 Function();
typedef CBLLog_ConsoleLevel = int Function();

typedef CBLLog_SetConsoleLevel_C = Void Function(Uint8 logLevel);
typedef CBLLog_SetConsoleLevel = void Function(int logLevel);

typedef CBLDart_CBLLog_RestoreOriginalCallback_C = Void Function();
typedef CBLDart_CBLLog_RestoreOriginalCallback = void Function();

typedef CBLDart_CBLLog_SetCallback_C = Void Function(Int64 callbackId);
typedef CBLDart_CBLLog_SetCallback = void Function(int callbackId);

class LogBindings {
  LogBindings(Libraries libs)
      : consoleLevel =
            libs.cbl.lookupFunction<CBLLog_ConsoleLevel_C, CBLLog_ConsoleLevel>(
          'CBLLog_ConsoleLevel',
        ),
        setConsoleLevel = libs.cbl
            .lookupFunction<CBLLog_SetConsoleLevel_C, CBLLog_SetConsoleLevel>(
          'CBLLog_SetConsoleLevel',
        ),
        restoreOriginalCallback = libs.cblDart.lookupFunction<
            CBLDart_CBLLog_RestoreOriginalCallback_C,
            CBLDart_CBLLog_RestoreOriginalCallback>(
          'CBLDart_CBLLog_RestoreOriginalCallback',
        ),
        setCallback = libs.cblDart.lookupFunction<CBLDart_CBLLog_SetCallback_C,
            CBLDart_CBLLog_SetCallback>(
          'CBLDart_CBLLog_SetCallback',
        );

  final CBLLog_ConsoleLevel consoleLevel;
  final CBLLog_SetConsoleLevel setConsoleLevel;
  final CBLDart_CBLLog_RestoreOriginalCallback restoreOriginalCallback;
  final CBLDart_CBLLog_SetCallback setCallback;
}
