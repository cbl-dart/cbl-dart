// ignore_for_file: invalid_use_of_internal_member

import 'dart:async';
import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/database/proxy_database.dart';
import 'package:cbl/src/service/cbl_service.dart';
import 'package:cbl/src/service/cbl_service_api.dart';
import 'package:cbl/src/service/cbl_worker.dart';
import 'package:cbl/src/service/channel.dart';
import 'package:cbl/src/service/serialization/json_packet_codec.dart';
import 'package:cbl/src/support/encoding.dart';
import 'package:cbl/src/support/utils.dart';
import 'package:cbl/src/typed_data_internal.dart';
import 'package:stream_channel/stream_channel.dart';

import '../test_binding.dart';
import 'api_variant.dart';

Future<void> removeDatabaseWithSharedIsolate(
  String name, {
  String? directory,
  Isolate isolate = Isolate.worker,
}) =>
    ProxyDatabase.remove(
      name,
      directory: directory,
      client: _sharedIsolateClient(isolate),
    );

Future<bool> databaseExistsWithSharedIsolate(
  String name, {
  String? directory,
  Isolate isolate = Isolate.worker,
}) =>
    ProxyDatabase.exists(
      name,
      directory: directory,
      client: _sharedIsolateClient(isolate),
    );

Future<void> copyDatabaseWithSharedIsolate({
  required String from,
  required String name,
  DatabaseConfiguration? config,
  Isolate isolate = Isolate.worker,
}) =>
    ProxyDatabase.copy(
      from: from,
      name: name,
      config: config,
      client: _sharedIsolateClient(isolate),
    );

String databaseDirectoryForTest() => [
      tmpDir,
      'Databases',
      if (testId != null) testId,
    ].join(Platform.pathSeparator);

FutureOr<Database> openTestDatabase({
  String name = 'db',
  DatabaseConfiguration? config,
  bool tearDown = true,
  TypedDataAdapter? typedDataAdapter,
}) =>
    runWithApi(
      sync: () => openSyncTestDatabase(
        name: name,
        config: config,
        tearDown: tearDown,
        typedDataAdapter: typedDataAdapter,
      ),
      async: () => openAsyncTestDatabase(
        name: name,
        config: config,
        tearDown: tearDown,
        typedDataAdapter: typedDataAdapter,
        isolate: isolate.value,
      ),
    );

SyncDatabase openSyncTestDatabase({
  String name = 'db',
  DatabaseConfiguration? config,
  bool tearDown = true,
  TypedDataAdapter? typedDataAdapter,
}) {
  config ??= DatabaseConfiguration(directory: databaseDirectoryForTest());

  // Ensure directory exists.
  File(config.directory).parent.createSync(recursive: true);

  final db = typedDataAdapter != null
      ? SyncDatabase.internal(name, config, typedDataAdapter)
      : SyncDatabase(name, config);

  if (tearDown) {
    addTearDown(db.close);
  }

  return db;
}

Future<AsyncDatabase> openAsyncTestDatabase({
  String name = 'db',
  DatabaseConfiguration? config,
  bool tearDown = true,
  TypedDataAdapter? typedDataAdapter,
  Isolate isolate = Isolate.worker,
  bool? usePublicApi,
}) async {
  assert(usePublicApi == null || isolate == Isolate.worker);

  config ??= DatabaseConfiguration(directory: databaseDirectoryForTest());

  // Ensure directory exists
  await File(config.directory).parent.create(recursive: true);

  final AsyncDatabase db;
  if (usePublicApi ?? false) {
    db = await (typedDataAdapter != null
        ? AsyncDatabase.openInternal(name, config, typedDataAdapter)
        : AsyncDatabase.open(name, config));
  } else {
    db = await ProxyDatabase.open(
      name: name,
      config: config,
      typedDataAdapter: typedDataAdapter,
      client: _sharedIsolateClient(isolate),
      encodingFormat:
          // To cover both transferring encoded data and Fleece values we use
          // different encoding formats for the two worker isolate targets.
          isolate == Isolate.worker ? EncodingFormat.fleece : null,
    );
  }

  if (tearDown) {
    addTearDown(db.close);
  }

  return db;
}

CblServiceClient _sharedIsolateClient(Isolate isolate) {
  CblServiceClient client;
  switch (isolate) {
    case Isolate.main:
      client = sharedMainIsolateClient;
      break;
    case Isolate.worker:
      client = sharedWorkerIsolateClient;
      break;
  }
  return client;
}

FutureOr<Database> getSharedTestDatabase() => runWithApi(
      sync: getSharedSyncTestDatabase,
      async: () => getSharedAsyncTestDatabase(isolate: isolate.value),
    );

SyncDatabase getSharedSyncTestDatabase() =>
    _sharedSyncDatabase ??= openSyncTestDatabase(
      name: 'shared-sync',
      tearDown: false,
    );

Future<AsyncDatabase> getSharedAsyncTestDatabase({
  Isolate isolate = Isolate.worker,
}) =>
    _sharedServiceDatabase ??= openAsyncTestDatabase(
      name: 'shared-async-${isolate.name}',
      tearDown: false,
      isolate: isolate,
    );

SyncDatabase? _sharedSyncDatabase;
Future<AsyncDatabase>? _sharedServiceDatabase;
Future<AsyncDatabase>? _sharedWorkerDatabase;

void setupSharedTestDatabases() {
  tearDownAll(() => Future.wait([
        _sharedSyncDatabase?.close(),
        _sharedServiceDatabase?.then((db) => db.close()),
        _sharedWorkerDatabase?.then((db) => db.close()),
      ].whereType<Future<void>>()));
}

late CblServiceClient sharedMainIsolateClient;

void setupSharedTestMainIsolateClient() {
  late final List<StreamChannel<Object?>> transportChannels;
  late CblService service;

  setUpAll(() {
    transportChannels = _streamControllerChannelPair();

    // We are using the `JsonPacketCodec` here to maximize code coverage.
    // The shared test worker already covers the `IsolatePacketCodec`.
    final packetCodec = JsonPacketCodec();

    final serviceChannel = Channel(
      transport: transportChannels[0],
      serializationRegistry: cblServiceSerializationRegistry(),
      packetCodec: packetCodec,
    );
    final clientChannel = Channel(
      transport: transportChannels[1],
      serializationRegistry: cblServiceSerializationRegistry(),
      packetCodec: packetCodec,
    );

    service = CblService(channel: serviceChannel);
    sharedMainIsolateClient = CblServiceClient(channel: clientChannel);
  });

  tearDownAll(() async {
    await sharedMainIsolateClient.channel.close();
    await service.dispose();
    await service.channel.close();
  });
}

List<StreamChannel<T>> _streamControllerChannelPair<T>() {
  // ignore: close_sinks
  final controllerA = StreamController<T>();
  // ignore: close_sinks
  final controllerB = StreamController<T>();
  return [
    StreamChannel(controllerA.stream, controllerB.sink),
    StreamChannel(controllerB.stream, controllerA.sink),
  ];
}

late CblServiceClient sharedWorkerIsolateClient;

void setupSharedTestWorkerIsolateClient() {
  late final CblWorker worker;

  setUpAll(() async {
    worker = CblWorker(debugName: 'Shared');
    await worker.start();

    sharedWorkerIsolateClient = CblServiceClient(channel: worker.channel);
  });

  tearDownAll(() async {
    await worker.stop();
  });
}

extension AsyncDatabaseUtilsExtension on Database {
  /// Returns a stream wich emits the ids of all the documents in this database.
  FutureOr<List<String>> getAllIds() => _allIdsQuery()
      .then((query) => query.execute())
      .then((resultSet) => resultSet.allResults())
      .then((results) => results.map(_getIdFromResult).toList());

  /// Returns a stream which emits the ids of all the documents in the database
  /// when they change.
  Stream<List<String>> watchAllIds() => _allIdsQuery()
      .toFuture()
      .asStream()
      .asyncExpand((query) => query.changes())
      .asyncMap(
          (change) => change.results.asStream().map(_getIdFromResult).toList());

  FutureOr<Query> _allIdsQuery() =>
      Query.fromN1ql(this, 'SELECT META().id FROM _');

  String _getIdFromResult(Result result) => result[0].string!;

  /// Deletes all documents in this database and returns whether any documents
  /// where deleted.
  Future<bool> deleteAllDocuments() async {
    var deletedAnyDocument = false;

    await inBatch(() async {
      for (final id in await getAllIds()) {
        final collection = await defaultCollection;
        final doc = await collection.document(id);
        if (doc != null) {
          await collection.deleteDocument(doc);
        }
        deletedAnyDocument = doc != null;
      }
    });

    return deletedAnyDocument;
  }

  FutureOr<void> saveAllDocuments(Iterable<MutableDocument> documents) =>
      // ignore: void_checks
      inBatch(() {
        if (this case SyncDatabase(:final defaultCollection)) {
          documents.forEach(defaultCollection.saveDocument);
        }
        if (this case AsyncDatabase(:final defaultCollection)) {
          return Future.wait(
            documents.map((document) async =>
                (await defaultCollection).saveDocument(document)),
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
