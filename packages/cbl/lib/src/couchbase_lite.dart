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

/// Returns a [LogCallback] which logs messages to a [Logger].
///
/// If [logger] is not provided a new `Logger` with name 'CBL' will be created
/// and used.
LogCallback loggerCallback({Logger? logger}) {
  logger ??= Logger('CBL');

  return (domain, level, message) {
    logger!.log(
      level.toLoggingLevel(),
      '${describeEnum(domain)}: $message',
    );
  };
}

/// A callback which is called with log messages from the CouchbaseLite logging
/// system.
///
/// The callback also receives a [domain] describing what part of the
/// CouchbaseLite implementation the message comes from.
///
/// Each messages is associated with a [level], allowing you to filter them
/// based on urgency.
///
/// See:
/// - [CouchbaseLite.logLevel] for the current log level at which messages are
///   emitted.
/// - [CouchbaseLite.logCallback] to configure a custom log callback.
typedef LogCallback = void Function(
  LogDomain domain,
  LogLevel level,
  String message,
);

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
        await _workerFactory.createWorker(id: 'Database#$databaseId');
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
  /// Messages below this level will not be sent to the [logCallback] or the
  /// default log callback.
  ///
  /// It is not possible to configure logging individually for objects such as
  /// databases or replicators.
  ///
  /// See:
  /// - [logCallback] to configure a custom log callback to handle log messages.
  /// - [restoreDefaultLogCallback] for more info about the default log
  ///   behavior.
  LogLevel get logLevel => _logBindings.consoleLevel().toLogLevel();

  set logLevel(LogLevel level) => _logBindings.setConsoleLevel(level.toInt());

  static LogCallback? _logCallback;

  /// A callback which is invoked when CouchbaseLite has something to log.
  ///
  /// To disable all logging set this property to `null`.
  ///
  /// See:
  /// - [logLevel] to configure which messages this callback will receive.
  /// - [LogCallback]
  LogCallback? get logCallback => _logCallback;

  set logCallback(LogCallback? callback) {
    if (_logCallback == callback) return;

    // Make sure the old callback is not being called while we make changes.
    restoreDefaultLogCallback();

    int? newCallbackId;

    if (callback != null) {
      newCallbackId = NativeCallbacks.instance.registerCallback<LogCallback>(
        callback,
        (callback, arguments, _) {
          final domain = arguments[0] as int;
          final level = arguments[1] as int;
          final message = arguments[2] as String;
          callback(domain.toLogDomain(), level.toLogLevel(), message);
        },
      );
    }

    _logBindings.setCallback(newCallbackId ?? 0);
  }

  /// Restores the log callback to the default callback which logs to the
  /// console.
  void restoreDefaultLogCallback() {
    _logBindings.restoreOriginalCallback();

    final oldCallback = _logCallback;

    if (oldCallback != null) {
      NativeCallbacks.instance.unregisterCallback(oldCallback);
    }

    _logCallback = null;
  }
}
