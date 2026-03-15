import 'dart:async';

import 'package:meta/meta.dart';

import '../document/blob.dart';
import '../document/document.dart';
import '../log.dart';
import '../log/log.dart';
import '../query/prediction.dart';
import '../query/query.dart';
import '../replication/replicator.dart';
import '../support/resource.dart';
import '../support/tracing.dart';
import '../tracing.dart';
import '../typed_data/adapter.dart';
import 'collection.dart';
import 'database_configuration.dart';
import 'ffi_database.dart';
import 'proxy_database.dart';
import 'scope.dart';

/// Conflict-handling options when saving or deleting a document.
///
/// {@category Database}
enum ConcurrencyControl {
  /// The current save/delete will overwrite a conflicting revision if there is
  /// a conflict.
  lastWriteWins,

  /// The current save/delete will fail if there is a conflict.
  failOnConflict,
}

/// The type of maintenance a database can perform.
///
/// {@category Database}
enum MaintenanceType {
  /// Compact the database file and delete unused attachments.
  compact,

  /// Rebuild the database's indexes.
  reindex,

  /// Check for database corruption.
  integrityCheck,

  /// Partially scan indexes to gather database statistics that help optimize
  /// queries.
  optimize,

  /// Fully scan all indexes to gather database statistics that help optimize
  /// queries.
  fullOptimize,
}

/// A Couchbase Lite database.
///
/// {@category Database}
abstract interface class Database implements ClosableResource {
  /// {@template cbl.Database.openAsync}
  /// Opens a Couchbase Lite database with the given [name] and [config], which
  /// executes in a separate worker isolate.
  ///
  /// If the database does not yet exist, it will be created.
  /// {@endtemplate}
  static Future<AsyncDatabase> openAsync(
    String name, [
    DatabaseConfiguration? config,
  ]) => AsyncDatabase.open(name, config);

  /// {@template cbl.Database.openSync}
  /// Opens a Couchbase Lite database with the given [name] and [config], which
  /// executes in the current isolate.
  ///
  /// If the database does not yet exist, it will be created.
  /// {@endtemplate}
  // ignore: prefer_constructors_over_static_methods
  static SyncDatabase openSync(String name, [DatabaseConfiguration? config]) =>
      SyncDatabase(name, config);

  /// {@template cbl.Database.remove}
  /// Deletes a database of the given [name] in the given [directory].
  /// {@endtemplate}
  static Future<void> remove(String name, {String? directory}) =>
      AsyncDatabase.remove(name, directory: directory);

  /// {@template cbl.Database.removeSync}
  /// Deletes a database of the given [name] in the given [directory].
  /// {@endtemplate}
  static void removeSync(String name, {String? directory}) =>
      SyncDatabase.remove(name, directory: directory);

  /// {@template cbl.Database.exists}
  /// Checks whether a database of the given [name] exists in the given
  /// [directory] or not.
  /// {@endtemplate}
  static Future<bool> exists(String name, {String? directory}) =>
      AsyncDatabase.exists(name, directory: directory);

  /// {@template cbl.Database.existsSync}
  /// Checks whether a database of the given [name] exists in the given
  /// [directory] or not.
  /// {@endtemplate}
  static bool existsSync(String name, {String? directory}) =>
      SyncDatabase.exists(name, directory: directory);

  /// {@template cbl.Database.copy}
  /// Copies a canned database [from] the given path to a new database with the
  /// given [name] and [config].
  ///
  /// The new database will be created at the directory specified in the
  /// [config].
  /// {@endtemplate}
  static Future<void> copy({
    required String from,
    required String name,
    DatabaseConfiguration? config,
  }) => AsyncDatabase.copy(from: from, name: name, config: config);

  /// {@template cbl.Database.copySync}
  /// Copies a canned database [from] the given path to a new database with the
  /// given [name] and [config].
  ///
  /// The new database will be created at the directory specified in the
  /// [config].
  /// {@endtemplate}
  static void copySync({
    required String from,
    required String name,
    DatabaseConfiguration? config,
  }) => SyncDatabase.copy(from: from, name: name, config: config);

  /// Configuration of the [ConsoleLogger], [FileLogger] and a custom [Logger].
  static final Log log = LogImpl();

  /// Manager for registering and unregistering [PredictiveModel]s.
  static final Prediction prediction = PredictionImpl();

  /// The name of this database.
  String get name;

  /// The path to this database.
  ///
  /// Is `null` if the database is closed or deleted.
  String? get path;

  /// The configuration which was used to open this database.
  DatabaseConfiguration get config;

  /// The default [Scope] of this database.
  FutureOr<Scope> get defaultScope;

  /// The [Scope]s of this database.
  ///
  /// Every returned scope contains at least one collection.
  FutureOr<List<Scope>> get scopes;

  /// Returns the [Scope] with the given [name].
  ///
  /// Returns `null` if there is not at least one collection in the scope.
  FutureOr<Scope?> scope(String name);

  /// The default [Collection] of this database.
  FutureOr<Collection> get defaultCollection;

  /// Returns the [Collection] with the given [name] in the given [scope].
  ///
  /// Returns `null` if the collection does not exist.
  FutureOr<Collection?> collection(
    String name, [
    String scope = Scope.defaultName,
  ]);

  /// Returns all the [Collection]s in the given [scope].
  FutureOr<List<Collection>> collections([String scope = Scope.defaultName]);

  /// Creates a [Collection] with the given [name] in the specified [scope].
  ///
  /// If the [Collection] already exists, the existing collection will be
  /// returned.
  FutureOr<Collection> createCollection(
    String name, [
    String scope = Scope.defaultName,
  ]);

  /// Deletes the [Collection] with the given [name] in the given [scope].
  FutureOr<void> deleteCollection(
    String name, [
    String scope = Scope.defaultName,
  ]);

  /// Saves a [Blob] directly into this database without associating it with any
  /// [Document]s.
  ///
  /// Note: Blobs that are not associated with any document will be removed from
  /// the database when compacting the database.
  FutureOr<void> saveBlob(Blob blob);

  /// Gets a [Blob] using its metadata.
  ///
  /// If the blob with the specified metadata doesn’t exist, returns `null`.
  ///
  /// If the provided [properties] don't contain valid metadata, an
  /// [ArgumentError] is thrown.
  ///
  /// {@macro cbl.Blob.metadataTable}
  ///
  /// See also:
  ///
  /// - [Blob.isBlob] to check if a [Map] contains valid Blob metadata.
  FutureOr<Blob?> getBlob(Map<String, Object?> properties);

  /// Runs a group of database operations in a batch.
  ///
  /// {@template cbl.Database.inBatch}
  /// Use this when performing bulk write operations like multiple
  /// inserts/updates; it saves the overhead of multiple database commits,
  /// greatly improving performance.
  ///
  /// Calls to [inBatch] must not be nested.
  ///
  /// Any asynchronous tasks launched from inside a [inBatch] block must finish
  /// writing to the database before the [inBatch] block completes.
  /// {@endtemplate}
  Future<void> inBatch(FutureOr<void> Function() fn);

  /// Closes this database.
  ///
  /// Before closing this database, [Replicator]s and change streams are closed.
  @override
  Future<void> close();

  /// Closes and deletes this database.
  ///
  /// Before closing this database, [Replicator]s and change streams are closed.
  Future<void> delete();

  /// Performs database maintenance.
  FutureOr<void> performMaintenance(MaintenanceType type);

  /// Encrypts or decrypts a [Database], or changes its [EncryptionKey].
  ///
  /// {@macro cbl.EncryptionKey.enterpriseFeature}
  ///
  /// If [newKey] is `null`, the database will be decrypted. Otherwise the
  /// database will be encrypted with that key; if it was already encrypted, it
  /// will be re-encrypted with the new key.
  FutureOr<void> changeEncryptionKey(EncryptionKey? newKey);

  /// Creates a [Query] from a query string.
  ///
  /// By default [query] is expected to be an SQL++ query. If [json] is `true`,
  /// [query] is expected to be the [Query.jsonRepresentation] of a query.
  FutureOr<Query> createQuery(String query, {bool json = false});
}

/// A [Database] with a primarily synchronous API.
///
/// {@category Database}
abstract interface class SyncDatabase implements Database {
  /// {@macro cbl.Database.openSync}
  factory SyncDatabase(String name, [DatabaseConfiguration? config]) =>
      SyncDatabase.internal(name, config);

  /// @nodoc
  @internal
  factory SyncDatabase.internal(
    String name, [
    DatabaseConfiguration? config,
    TypedDataAdapter? typedDataAdapter,
  ]) => syncOperationTracePoint(
    () => OpenDatabaseOp(name, config),
    () => FfiDatabase(
      name: name,
      config: config,
      typedDataAdapter: typedDataAdapter,
    ),
  );

  /// {@macro cbl.Database.removeSync}
  static void remove(String name, {String? directory}) =>
      FfiDatabase.remove(name, directory: directory);

  /// {@macro cbl.Database.existsSync}
  static bool exists(String name, {String? directory}) =>
      FfiDatabase.exists(name, directory: directory);

  /// {@macro cbl.Database.copySync}
  static void copy({
    required String from,
    required String name,
    DatabaseConfiguration? config,
  }) => FfiDatabase.copy(from: from, name: name, config: config);

  @override
  SyncScope get defaultScope;

  @override
  List<SyncScope> get scopes;

  @override
  SyncScope? scope(String name);

  @override
  SyncCollection get defaultCollection;

  @override
  SyncCollection? collection(String name, [String scope = Scope.defaultName]);

  @override
  List<SyncCollection> collections([String scope = Scope.defaultName]);

  @override
  SyncCollection createCollection(
    String name, [
    String scope = Scope.defaultName,
  ]);

  @override
  void deleteCollection(String name, [String scope = Scope.defaultName]);

  @override
  Future<void> saveBlob(Blob blob);

  @override
  Blob? getBlob(Map<String, Object?> properties);

  /// Runs a group of database operations in a batch, synchronously.
  ///
  /// {@macro cbl.Database.inBatch}
  void inBatchSync(void Function() fn);

  @override
  void performMaintenance(MaintenanceType type);

  @override
  void changeEncryptionKey(EncryptionKey? newKey);

  @override
  SyncQuery createQuery(String query, {bool json = false});
}

/// A [Database] with a primarily asynchronous API.
///
/// {@category Database}
abstract interface class AsyncDatabase implements Database {
  /// {@macro cbl.Database.openAsync}
  static Future<AsyncDatabase> open(
    String name, [
    DatabaseConfiguration? config,
  ]) => openInternal(name, config);

  /// @nodoc
  @internal
  static Future<AsyncDatabase> openInternal(
    String name, [
    DatabaseConfiguration? config,
    TypedDataAdapter? typedDataAdapter,
  ]) => asyncOperationTracePoint(
    () => OpenDatabaseOp(name, config),
    () => WorkerDatabase.open(name, config, typedDataAdapter),
  );

  /// {@macro cbl.Database.remove}
  static Future<void> remove(String name, {String? directory}) =>
      WorkerDatabase.remove(name, directory: directory);

  /// {@macro cbl.Database.exists}
  static Future<bool> exists(String name, {String? directory}) =>
      WorkerDatabase.exists(name, directory: directory);

  /// {@macro cbl.Database.copy}
  static Future<void> copy({
    required String from,
    required String name,
    DatabaseConfiguration? config,
  }) => WorkerDatabase.copy(from: from, name: name, config: config);

  @override
  Future<AsyncScope> get defaultScope;

  @override
  Future<List<AsyncScope>> get scopes;

  @override
  Future<AsyncScope?> scope(String name);

  @override
  Future<AsyncCollection> get defaultCollection;

  @override
  Future<AsyncCollection?> collection(
    String name, [
    String scope = Scope.defaultName,
  ]);

  @override
  Future<List<AsyncCollection>> collections([String scope = Scope.defaultName]);

  @override
  Future<AsyncCollection> createCollection(
    String name, [
    String scope = Scope.defaultName,
  ]);

  @override
  Future<void> deleteCollection(
    String name, [
    String scope = Scope.defaultName,
  ]);

  @override
  Future<void> saveBlob(Blob blob);

  @override
  Future<Blob?> getBlob(Map<String, Object?> properties);

  @override
  Future<void> inBatch(FutureOr<void> Function() fn);

  @override
  Future<void> performMaintenance(MaintenanceType type);

  @override
  Future<void> changeEncryptionKey(EncryptionKey? newKey);

  @override
  Future<AsyncQuery> createQuery(String query, {bool json = false});
}
