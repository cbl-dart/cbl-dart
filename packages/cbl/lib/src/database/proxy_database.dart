import 'dart:async';
import 'dart:io';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../document.dart';
import '../document/document.dart';
import '../document/fragment.dart';
import '../document/proxy_document.dart';
import '../errors.dart';
import '../query/index/index.dart';
import '../service/cbl_service.dart';
import '../service/cbl_service_api.dart';
import '../service/cbl_worker.dart';
import '../service/channel.dart';
import '../service/proxy_object.dart';
import '../service/serialization/json_packet_codec.dart';
import '../support/encoding.dart';
import '../support/listener_token.dart';
import '../support/resource.dart';
import '../support/streams.dart';
import '../support/utils.dart';
import 'blob_store.dart';
import 'database.dart';
import 'database_change.dart';
import 'database_configuration.dart';
import 'database_helper.dart';
import 'document_change.dart';
import 'proxy_blob_store.dart';

class ProxyDatabase extends ProxyObject
    with DatabaseHelper<ProxyDocumentDelegate>, ClosableResourceMixin
    implements AsyncDatabase, BlobStoreHolder {
  ProxyDatabase(
    this.client,
    DatabaseConfiguration config,
    this.state,
  )   : name = state.name,
        path = state.path,
        // Make a copy of config, since it is mutable.
        _config = DatabaseConfiguration.from(config),
        super(client.channel, state.id);

  static Future<void> remove(
    String name, {
    String? directory,
    required CblServiceClient client,
  }) =>
      client.channel.call(RemoveDatabase(name, directory));

  static Future<bool> exists(
    String name, {
    String? directory,
    required CblServiceClient client,
  }) =>
      client.channel.call(DatabaseExists(name, directory));

  static Future<void> copy({
    required String from,
    required String name,
    DatabaseConfiguration? config,
    required CblServiceClient client,
  }) =>
      client.channel.call(CopyDatabase(from, name, config));

  static Future<ProxyDatabase> open({
    required String name,
    required DatabaseConfiguration config,
    required CblServiceClient client,
  }) async {
    final state = await client.channel.call(OpenDatabase(name, config));
    return ProxyDatabase(client, config, state);
  }

  var _deleteOnClose = false;

  final CblServiceClient client;

  @override
  late final BlobStore blobStore = ProxyBlobStore(this);

  late final _listenerTokens = ListenerTokenRegistry(this);

  final DatabaseConfiguration _config;

  DatabaseState state;

  @override
  final String name;

  @override
  String? path;

  @override
  Future<int> get count => use(() async {
        await _refreshState();
        return state.count;
      });

  @override
  DatabaseConfiguration get config => DatabaseConfiguration.from(_config);

  @override
  Future<Document?> document(String id) => use(() async {
        final state = await channel
            .call(GetDocument(objectId, id, EncodingFormat.fleece));

        if (state == null) {
          return null;
        }

        return DelegateDocument(
          ProxyDocumentDelegate.fromState(state),
          database: this,
        );
      });

  @override
  Future<DocumentFragment> operator [](String id) => use(
      () => document(id).then((document) => DocumentFragmentImpl(document)));

  @override
  Future<bool> saveDocument(
    covariant MutableDelegateDocument document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]) =>
      use(() async {
        final delegate = await prepareDocument(document);

        final state = await channel.call(SaveDocument(
          objectId,
          delegate.getState(),
          concurrencyControl,
        ));

        if (state == null) {
          return false;
        }

        delegate.setState(state);

        return true;
      });

  @override
  Future<bool> saveDocumentWithConflictHandler(
    covariant MutableDelegateDocument document,
    SaveConflictHandler conflictHandler,
  ) =>
      use(() => saveDocumentWithConflictHandlerHelper(
            document,
            conflictHandler,
          ));

  @override
  Future<bool> deleteDocument(
    covariant DelegateDocument document, [
    ConcurrencyControl concurrencyControl = ConcurrencyControl.lastWriteWins,
  ]) =>
      use(() async {
        final delegate = await prepareDocument(document, syncProperties: false);

        final state = await channel.call(DeleteDocument(
          objectId,
          delegate.getState(withProperties: false),
          concurrencyControl,
        ));

        if (state == null) {
          return false;
        }

        delegate.setState(state);

        return true;
      });

  @override
  Future<void> purgeDocument(covariant DelegateDocument document) async {
    await prepareDocument(document, syncProperties: false);
    return purgeDocumentById(document.id);
  }

  @override
  Future<void> purgeDocumentById(String id) =>
      use(() => channel.call(PurgeDocument(objectId, id)));

  @override
  Future<void> inBatch(FutureOr<void> Function() fn) => use(() async {
        await channel.call(BeginDatabaseTransaction(databaseId: objectId));
        try {
          await fn();
          await channel.call(EndDatabaseTransaction(
            databaseId: objectId,
            commit: true,
          ));
        }
        // ignore: avoid_catches_without_on_clauses
        catch (e) {
          await channel.call(EndDatabaseTransaction(
            databaseId: objectId,
            commit: false,
          ));
          rethrow;
        }
      });

  @override
  Future<void> setDocumentExpiration(String id, DateTime? expiration) =>
      use(() => channel.call(SetDocumentExpiration(
            databaseId: objectId,
            documentId: id,
            expiration: expiration,
          )));

  @override
  Future<DateTime?> getDocumentExpiration(String id) => use(() => channel
      .call(GetDocumentExpiration(databaseId: objectId, documentId: id)));

  @override
  Future<ListenerToken> addChangeListener(DatabaseChangeListener listener) =>
      use(() async {
        final token = await _addChangeListener(listener);
        return token.also(_listenerTokens.add);
      });

  Future<AbstractListenerToken> _addChangeListener(
    DatabaseChangeListener listener,
  ) async {
    late final ProxyListenerToken<DatabaseChange> token;
    final listenerId = client.registerDatabaseChangeListener((documentIds) {
      token.callListener(DatabaseChange(this, documentIds));
    });

    await channel.call(AddDatabaseChangeListener(
      databaseId: objectId,
      listenerId: listenerId,
    ));

    return token = ProxyListenerToken(client, this, listenerId, listener);
  }

  @override
  Future<ListenerToken> addDocumentChangeListener(
    String id,
    DocumentChangeListener listener,
  ) =>
      use(() async {
        final token = await _addDocumentChangeListener(id, listener);
        return token.also(_listenerTokens.add);
      });

  Future<AbstractListenerToken> _addDocumentChangeListener(
    String id,
    DocumentChangeListener listener,
  ) async {
    late final ProxyListenerToken<DocumentChange> token;
    final listenerId = client.registerDocumentChangeListener(() {
      token.callListener(DocumentChange(this, id));
    });

    await channel.call(AddDocumentChangeListener(
      databaseId: objectId,
      documentId: id,
      listenerId: listenerId,
    ));

    return token = ProxyListenerToken(client, this, listenerId, listener);
  }

  @override
  Future<void> removeChangeListener(ListenerToken token) async =>
      use(() => _listenerTokens.remove(token));

  @override
  AsyncListenStream<DatabaseChange> changes() => useSync(() => ListenerStream(
        parent: this,
        addListener: _addChangeListener,
      ));

  @override
  AsyncListenStream<DocumentChange> documentChanges(String id) =>
      useSync(() => ListenerStream(
            parent: this,
            addListener: (listener) => _addDocumentChangeListener(id, listener),
          ));

  @override
  Future<void> performClose() async {
    if (_deleteOnClose) {
      await channel.call(DeleteDatabase(objectId));
    } else {
      await finalizeEarly();
    }
    path = null;
  }

  @override
  Future<void> delete() {
    _deleteOnClose = true;
    return close();
  }

  @override
  Future<void> performMaintenance(MaintenanceType type) =>
      use(() => channel.call(PerformDatabaseMaintenance(
            databaseId: objectId,
            type: type,
          )));

  @override
  Future<void> changeEncryptionKey(EncryptionKey? newKey) =>
      use(() => channel.call(ChangeDatabaseEncryptionKey(
            databaseId: objectId,
            encryptionKey: newKey,
          )));

  @override
  Future<List<String>> get indexes async {
    await _refreshState();
    return state.indexes;
  }

  @override
  Future<void> createIndex(String name, covariant IndexImplInterface index) =>
      use(() => channel.call(CreateIndex(
            databaseId: objectId,
            name: name,
            spec: index.toCBLIndexSpec(),
          )));

  @override
  Future<void> deleteIndex(String name) =>
      use(() => channel.call(DeleteIndex(databaseId: objectId, name: name)));

  @override
  String toString() => 'ProxyDatabase($name)';

  Future<void> _refreshState() async {
    state = await channel.call(GetDatabase(objectId));
  }

  @override
  ProxyDocumentDelegate createNewDocumentDelegate(
    DocumentDelegate oldDelegate,
  ) =>
      ProxyDocumentDelegate.fromDelegate(oldDelegate);
}

class WorkerDatabase extends ProxyDatabase {
  WorkerDatabase._(
    this.worker,
    DatabaseConfiguration config,
    DatabaseState state,
  ) : super(CblServiceClient(channel: worker.channel), config, state);

  static Future<WorkerDatabase> open(
    String name, [
    DatabaseConfiguration? config,
  ]) async {
    config ??= DatabaseConfiguration();

    final worker = CblWorker(debugName: _databaseName(name));
    await worker.start();

    try {
      final state = await worker.channel.call(OpenDatabase(name, config));
      return WorkerDatabase._(worker, config, state);
    } on CouchbaseLiteException {
      await worker.stop();
      rethrow;
    }
  }

  static Future<void> remove(String name, {String? directory}) =>
      CblWorker.executeCall(
        RemoveDatabase(name, directory),
        debugName: 'WorkerDatabase.remove',
      );

  static Future<bool> exists(String name, {String? directory}) =>
      CblWorker.executeCall(
        DatabaseExists(name, directory),
        debugName: 'WorkerDatabase.exists',
      );

  static Future<void> copy({
    required String from,
    required String name,
    DatabaseConfiguration? config,
  }) =>
      CblWorker.executeCall(
        CopyDatabase(from, name, config),
        debugName: 'WorkerDatabase.copy',
      );

  final CblWorker worker;

  @override
  Future<void> performClose() async {
    await super.performClose();
    await worker.stop();
  }
}

class RemoteDatabase extends ProxyDatabase {
  RemoteDatabase._(
    CblServiceClient client,
    DatabaseConfiguration config,
    DatabaseState state,
  ) : super(client, config, state);

  static Future<RemoteDatabase> open(
    Uri uri,
    String name,
    DatabaseConfiguration config,
  ) async {
    final channel = Channel(
      transport: WebSocketChannel.connect(uri),
      packetCodec: JsonPacketCodec(),
      serializationRegistry: cblServiceSerializationRegistry(),
    );
    final client = CblServiceClient(channel: channel);
    final state = await channel.call(OpenDatabase(name, config));
    return RemoteDatabase._(client, config, state);
  }

  @override
  Future<void> performClose() async {
    await super.performClose();
    await channel.close();
  }
}

String _databaseName(String path) => path.split(Platform.pathSeparator).last;
