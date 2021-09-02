import 'dart:async';
import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/database/proxy_database.dart';
import 'package:cbl/src/service/cbl_service.dart';
import 'package:cbl/src/service/cbl_worker.dart';
import 'package:cbl/src/support/utils.dart';

import '../test_binding.dart';
import 'api_variant.dart';

String databaseDirectoryForTest() => [
      tmpDir,
      'Databases',
      if (testDescriptions != null) ...testDescriptions!
    ].join(Platform.pathSeparator);

FutureOr<Database> openTestDatabase({
  String name = 'db',
  DatabaseConfiguration? config,
  bool tearDown = true,
}) =>
    runApi(
      sync: () => openSyncTestDatabase(
        name: name,
        config: config,
        tearDown: tearDown,
      ),
      async: () => openAsyncTestDatabase(
        name: name,
        config: config,
        tearDown: tearDown,
      ),
    );

SyncDatabase openSyncTestDatabase({
  String name = 'db',
  DatabaseConfiguration? config,
  bool tearDown = true,
}) {
  config ??= DatabaseConfiguration(directory: databaseDirectoryForTest());

  // Ensure directory exists.
  File(config.directory).parent.createSync(recursive: true);

  final db = SyncDatabase(name, config);

  if (tearDown) {
    addTearDown(db.close);
  }

  return db;
}

CblWorker? _sharedWorker;
late CblServiceClient _sharedClient;

void setupSharedTestCblWorker() {
  setUpAll(() async {
    _sharedWorker = CblWorker(debugName: 'Shared');
    await _sharedWorker!.start();
    _sharedClient = CblServiceClient(channel: _sharedWorker!.channel);
  });

  tearDownAll(() => _sharedWorker?.stop());
}

Future<AsyncDatabase> openAsyncTestDatabase({
  String name = 'db',
  DatabaseConfiguration? config,
  bool tearDown = true,
}) async {
  config ??= DatabaseConfiguration(directory: databaseDirectoryForTest());

  // Ensure directory exists
  await File(config.directory).parent.create(recursive: true);

  final db = await ProxyDatabase.open(
    name: name,
    config: config,
    client: _sharedClient,
  );

  if (tearDown) {
    addTearDown(db.close);
  }

  return db;
}

SyncDatabase? _sharedSyncDatabase;
Future<AsyncDatabase>? _sharedAsyncDatabase;

void setupSharedTestDatabases() {
  tearDownAll(() => Future.wait([
        _sharedSyncDatabase?.close(),
        _sharedAsyncDatabase?.then((db) => db.close())
      ].whereType<Future<void>>()));
}

Future<AsyncDatabase> openSharedAsyncTestDatabase() =>
    _sharedAsyncDatabase ??= openAsyncTestDatabase(
      name: 'shared-async',
      tearDown: false,
    );

SyncDatabase openSharedSyncTestDatabase() =>
    _sharedSyncDatabase ??= openSyncTestDatabase(
      name: 'shared-sync',
      tearDown: false,
    );

FutureOr<Database> openSharedTestDatabase() => runApi(
      sync: openSharedSyncTestDatabase,
      async: openSharedAsyncTestDatabase,
    );

extension AsyncDatabaseUtilsExtension on Database {
  /// Returns a stream wich emits the ids of all the documents in this database.
  FutureOr<List<String>> getAllIds() => _allIdsQuery()
      .then((query) => query.execute())
      .then((resultSet) => resultSet.allResults())
      .then((results) => results.map(_getIdFromResult).toList());

  /// Returns a stream which emits the ids of all the documents in the
  /// database when they change.
  Stream<List<String>> watchAllIds() => _allIdsQuery()
      .toFuture()
      .asStream()
      .asyncExpand((query) => query.changes())
      .asyncMap(
          (resultSet) => resultSet.asStream().map(_getIdFromResult).toList());

  FutureOr<Query> _allIdsQuery() =>
      Query.fromN1ql(this, 'SELECT META().id FROM _');

  String _getIdFromResult(Result result) => result[0].string!;

  /// Deletes all documents in this database and returns whether any documents
  /// where deleted.
  Future<bool> deleteAllDocuments() async {
    var deletedAnyDocument = false;

    await inBatch(() async {
      for (final id in await getAllIds()) {
        final doc = await document(id);
        if (doc != null) {
          await deleteDocument(doc);
        }
        deletedAnyDocument = doc != null;
      }
    });

    return deletedAnyDocument;
  }

  FutureOr<void> saveAllDocuments(Iterable<MutableDocument> documents) =>
      // ignore: void_checks
      inBatch(() {
        if (this is SyncDatabase) {
          documents.forEach(saveDocument);
        }
        if (this is AsyncDatabase) {
          return Future.wait(
            documents.map((document) async => saveDocument(document)),
          );
        }
      });
}

extension ResultSetExt on ResultSet {
  Stream<StringMap> plainMapStream() =>
      asStream().map((result) => result.toPlainMap());

  Stream<List<Object?>> plainListStream() =>
      asStream().map((result) => result.toPlainList());

  FutureOr<List<StringMap>> allPlainMapResults() => allResults()
      .then((results) => results.map((result) => result.toPlainMap()).toList());

  FutureOr<List<Object?>> allPlainListResults() => allResults().then(
      (results) => results.map((result) => result.toPlainList()).toList());
}
