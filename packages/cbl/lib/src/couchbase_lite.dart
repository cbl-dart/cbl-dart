import 'dart:ffi';

import 'bindings/bindings.dart';
import 'blob.dart';
import 'database.dart';
import 'fleece.dart';
import 'native_callbacks.dart';
import 'worker/handlers.dart';
import 'worker/worker.dart';

export 'bindings/bindings.dart'
    show LibraryConfiguration, Libraries, LogLevel, LogDomain;

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
  /// Id of the [Worker] which is not bound to one specific object.
  static final _standaloneWorkerId = 'Standalone';

  /// Counter to generate unique ids for opened [Database]s.
  static int _nextDatabaseId = 0;

  /// Initializes the Couchbase Lite API and returns [CouchbaseLite], which is
  /// the entry point to the API.
  static Future<CouchbaseLite> init({required Libraries libraries}) async {
    CBLBindings.initInstance(libraries);

    SlotSetter.register(blobSlotSetter);

    final workerManager = WorkerManager(libraries: libraries);

    return CouchbaseLite._(
      workerManager,
      await workerManager.getWorker(id: _standaloneWorkerId),
    );
  }

  /// Private constructor to allow control over instance creation.
  CouchbaseLite._(this._workerManager, this._worker);

  final WorkerManager _workerManager;
  final Worker _worker;

  /// Returns true if a database with the given [name] exists in the given
  /// [directory].
  Future<bool> databaseExists(String name, {String? directory}) async {
    return _worker.makeRequest(DatabaseExists(name, directory));
  }

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
  }) async {
    return _worker.makeRequest(CopyDatabase(fromPath, toName, config));
  }

  /// Deletes a database file.
  ///
  /// If the database file is open, an error is thrown.
  ///
  /// [name] is the database name (without the ".cblite2" extension.)
  ///
  /// [directory] is the directory containing the database. If `null`, name must
  /// be an absolute or relative path to the database.
  Future<bool> deleteDatabase(String name, {String? directory}) async {
    return _worker.makeRequest(DeleteDatabaseFile(name, directory));
  }

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
    final worker = await _workerManager.getWorker(id: 'Database#$databaseId');
    final pointer = await worker.makeRequest<int>(OpenDatabase(name, config));
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
  LogLevel get logLevel => _logBindings.consoleLevel().toLogLevel;

  set logLevel(LogLevel level) => _logBindings.setConsoleLevel(level.toInt);

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
        (callback, arguments, result) {
          final domain = arguments[0] as int;
          final level = arguments[1] as int;
          final message = arguments[2] as String;
          callback(domain.toLogDomain, level.toLogLevel, message);
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

  /// Release resources occupied by CouchbaseLite.
  ///
  /// The Isolate will not exit until this method has been called.
  Future<void> dispose() async {
    await _workerManager.dispose();
    await NativeCallbacks.instance.dispose();
  }
}
