import 'dart:async';
import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';
import 'package:logging/logging.dart';
import 'package:synchronized/synchronized.dart';

import 'blob.dart';
import 'database.dart';
import 'fleece.dart';
import 'native_callbacks.dart';
import 'replicator.dart';
import 'utils.dart';
import 'worker/cbl_worker.dart';

export 'package:cbl_ffi/cbl_ffi.dart'
    show LibraryConfiguration, Libraries, LogLevel, LogDomain;

/// A entry, which is emitted when CouchbaseLite logs a message.
///
/// See:
/// - [CouchbaseLite.logMessages] for how to listen to log messages.
class LogMessage {
  LogMessage({
    required this.level,
    required this.domain,
    required this.message,
  });

  /// The level at which this message is emitted, allowing you to filter them
  /// based on urgency.
  final LogLevel level;

  /// The [domain] of the CouchbaseLite implementation this message comes from.
  final LogDomain domain;

  /// The logged message.
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogMessage &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          domain == other.domain &&
          message == other.message;

  @override
  int get hashCode =>
      super.hashCode ^ level.hashCode ^ domain.hashCode ^ message.hashCode;

  @override
  String toString() => 'LogMessage('
      'level: $level, '
      'domain: $domain, '
      'message: $message '
      ')';
}

/// Extension to map between CouchbaseLite's [LogLevel] and `logging`s [Level].
extension LogLevelExt on LogLevel {
  /// Returns a [Level] from the `logging` package which corresponds to this
  /// CouchbaseLite log level.
  Level toLoggingLevel() {
    switch (this) {
      case LogLevel.verbose:
        return Level.FINER;
      case LogLevel.debug:
        return Level.FINE;
      case LogLevel.info:
        return Level.INFO;
      case LogLevel.warning:
        return Level.WARNING;
      case LogLevel.error:
        return Level.SEVERE;
      case LogLevel.none:
        throw UnsupportedError('LogLevel.none has not mapping to Level');
    }
  }
}

/// Extension for logging [LogMessage]s to [Logger]s.
extension LogMessageLoggerExtension on Logger {
  /// Logs [logMessage] to this logger.
  void logLogMessage(LogMessage logMessage) => log(
        logMessage.level.toLoggingLevel(),
        '${describeEnum(logMessage.domain)}: ${logMessage.message}',
      );
}

extension LogMessageStreamExtension on Stream<LogMessage> {
  /// Adds a subscription to to this stream which logs the emitted [LogMessage]s
  /// to [logger].
  ///
  /// If [logger] is not provided a new `Logger` with name 'CBL' will be created
  /// and used.
  StreamSubscription<LogMessage> logToLogger([Logger? logger]) {
    logger ??= Logger('CBL');
    return listen((logMessage) => logger!.logLogMessage(logMessage));
  }
}

/// The initializer and entry point to the Couchbase Lite API.
class CouchbaseLite {
  static final _lock = Lock();

  /// Id of the [Worker] which is not bound to one specific object.
  static final _standaloneWorkerId = 'Standalone';

  /// Counter to generate unique ids for opened [Database]s.
  static int _nextDatabaseId = 0;

  /// The singleton instance of [CouchbaseLite].
  ///
  /// You have to [initialize] it before accessing this field.
  static CouchbaseLite get instance => _instance!;
  static CouchbaseLite? _instance;

  /// Initializes [instance] and returns it.
  static Future<CouchbaseLite> initialize({required Libraries libraries}) =>
      _lock.synchronized(() async {
        if (_instance != null) return _instance!;

        CBLBindings.initInstance(libraries);

        SlotSetter.register(blobSlotSetter);

        final workerFactory = CblWorkerFactory(libraries: libraries);

        return _instance = CouchbaseLite._(
          workerFactory,
          await workerFactory.createWorker(id: _standaloneWorkerId),
        );
      });

  /// Release resources occupied by [instance].
  ///
  /// You have to close all other resources such as [Database]s or [Replicator]s
  /// before calling this method.
  ///
  /// The Isolate will not exit until this method has been called.
  static Future<void> dispose() => _lock.synchronized(() async {
        if (_instance == null) return;

        await _instance!._worker.stop();

        await NativeCallbacks.instance.dispose();

        _instance = null;
      });

  /// Private constructor to allow control over instance creation.
  CouchbaseLite._(this._workerFactory, this._worker);

  final CblWorkerFactory _workerFactory;
  final Worker _worker;

  /// Returns true if a database with the given [name] exists in the given
  /// [directory].
  ///
  /// [name] is the database name (without the ".cblite2" extension.).
  ///
  /// [directory] is the directory containing the database.
  Future<bool> databaseExists(String name, {required String directory}) =>
      _worker.execute(DatabaseExists(name, directory));

  /// Copies a database file to a new location, and assigns it a new internal
  /// UUID to distinguish it from the original database when replicating.
  ///
  /// [fromPath] is the full filesystem path to the original database
  /// (including extension).
  ///
  /// [toName] is the new database name (without the ".cblite2" extension.).
  ///
  /// [config] is the database configuration of the new database
  /// (directory and encryption option.)
  Future<void> copyDatabase({
    required String fromPath,
    required String toName,
    DatabaseConfiguration? config,
  }) =>
      _worker.execute(CopyDatabase(fromPath, toName, config));

  /// Deletes a database file.
  ///
  /// If the database file is open, an error is thrown.
  ///
  /// [name] is the database name (without the ".cblite2" extension.)
  ///
  /// [directory] is the directory containing the database.
  Future<bool> deleteDatabase(String name, {required String directory}) =>
      _worker.execute(DeleteDatabaseFile(name, directory));

  /// Opens a database, or creates it if it doesn't exist yet, returning a new
  /// [Database] instance.
  ///
  /// It's OK to open the same database file multiple times. Each [Database]
  /// instance is independent of the others (and must be separately closed and
  /// released.)
  ///
  /// [name] is the database name (without the ".cblite2" extension.).
  ///
  /// [config] contains the database configuration (directory and encryption
  /// option.)
  Future<Database> openDatabase(
    String name, {
    DatabaseConfiguration? config,
  }) async {
    final databaseId = _nextDatabaseId++;
    final worker =
        await _workerFactory.createWorker(id: 'Database(#$databaseId|$name)');
    final pointer = await worker.execute(OpenDatabase(name, config));
    return createDatabase(
      debugName: name,
      pointer: Pointer.fromAddress(pointer),
      worker: worker,
    );
  }

  static late final _logBindings = CBLBindings.instance.log;

  /// The current LogLevel of all of CouchbaseLite.
  ///
  /// Messages below this level will not be sent to the [logMessages] or the
  /// default log callback.
  ///
  /// It is not possible to configure logging individually for objects such as
  /// databases or replicators.
  ///
  /// See:
  /// - [logMessages] to handle log messages in Dart.
  /// - [loggingIsDisabled] for completely disabling logging completely.
  LogLevel get logLevel => _logBindings.consoleLevel().toLogLevel();

  set logLevel(LogLevel level) => _logBindings.setConsoleLevel(level.toInt());

  bool _loggingIsDisabled = false;

  /// Whether logging is completely disabled.
  ///
  /// [logMessages] cannot be listened to while logging is disabled and while
  /// [logMessages] has listeners, logging cannot be disabled.
  bool get loggingIsDisabled => _loggingIsDisabled;

  set loggingIsDisabled(bool disabled) {
    if (_loggingIsDisabled == disabled) return;

    _loggingIsDisabled = disabled;

    if (disabled) {
      assert(
        !_logMessages.hasListener,
        'logging cannot be be disabled while `logMessage` stream has listeners',
      );

      _logBindings.setCallback(NativeCallbacks.nullCallback);
    } else {
      _logBindings.restoreOriginalCallback();
    }
  }

  late final _logMessages =
      callbackBroadcastStreamController<LogMessage>(
    startStream: (callbackId) {
      assert(
        !_loggingIsDisabled,
        '`logMessages` stream cannot be listened to while `loggingIsDisable` is `true`',
      );

      _logBindings.setCallback(callbackId);
    },
    stopStream: () {
      _logBindings.restoreOriginalCallback();

      // We wait here a few milliseconds to ensure that all messages which
      // have been dispatched to the callback are received by it.
      return Future<void>.delayed(Duration(milliseconds: 50));
    },
    createEvent: (arguments) {
      final level = arguments[1] as int;
      final domain = arguments[0] as int;
      final message = arguments[2] as String;
      return LogMessage(
        level: level.toLogLevel(),
        domain: domain.toLogDomain(),
        message: message,
      );
    },
  );

  /// Broadcast stream which emits [LogMessage]s from the CouchbaseLite
  /// implementation.
  ///
  /// If [loggingIsDisabled] is `false` and this stream has no listeners the
  /// default consoler logger of the CouchbaseLite implementation will be used.
  ///
  /// Listening to this stream allows you to replace the default console logger
  /// with your own logging implementation.
  ///
  /// See:
  /// - [loggingIsDisabled] for how that property interacts with this stream.
  Stream<LogMessage> logMessages() => _logMessages.stream;
}
