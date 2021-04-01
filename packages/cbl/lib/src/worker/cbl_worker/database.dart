import 'dart:ffi';
import 'dart:typed_data';

import 'package:cbl_ffi/cbl_ffi.dart';
import 'package:ffi/ffi.dart';

import '../../database.dart';
import '../../errors.dart';
import '../request_router.dart';
import '../worker.dart';
import 'shared.dart';

late final _bindings = CBLBindings.instance.database;

extension on EncryptionKey {
  Pointer<CBLEncryptionKey> toCBLEncryptionKey() {
    final _keyByteLength = bytes.elementSizeInBytes;
    final bytesPointer = scoped(malloc<Uint8>(_keyByteLength));

    bytesPointer
        .asTypedList(_keyByteLength)
        .replaceRange(0, _keyByteLength, bytes);

    return scoped(malloc<CBLEncryptionKey>())
      ..ref.algorithm = encryptionAlgorithmToC(algorithm)
      ..ref.bytes = bytesPointer;
  }
}

extension on Pointer<CBLEncryptionKey> {
  EncryptionKey toEncryptionKey() => EncryptionKey(
        algorithm: encryptionAlgorithmFromC(ref.algorithm),
        bytes: Uint8List.fromList(
          ref.bytes.asTypedList(EncryptionKey.keyByteLength),
        ),
      );
}

extension on DatabaseConfiguration {
  Pointer<CBLDatabaseConfiguration> toCBLDatabaseConfiguration() =>
      scoped(malloc<CBLDatabaseConfiguration>())
        ..ref.directory =
            directory == null ? nullptr : directory!.toNativeUtf8().withScoped()
        ..ref.flags = flags.toCFlags()
        ..ref.encryptionKey = encryptionKey?.toCBLEncryptionKey() ?? nullptr;
}

extension on Pointer<CBLDatabaseConfiguration> {
  DatabaseConfiguration toDatabaseConfiguration() => DatabaseConfiguration(
        directory:
            ref.directory == nullptr ? null : ref.directory.toDartString(),
        flags: DatabaseFlag.parseCFlags(ref.flags),
        encryptionKey: ref.encryptionKey == nullptr
            ? null
            : ref.encryptionKey.toEncryptionKey(),
      );
}

class DatabaseExists extends WorkerRequest<bool> {
  DatabaseExists(this.name, this.directory);

  final String name;
  final String? directory;
}

bool databaseExists(DatabaseExists request) => _bindings
    .databaseExists(
      request.name.toNativeUtf8().withScoped(),
      request.directory == null
          ? nullptr
          : request.directory!.toNativeUtf8().withScoped(),
    )
    .toBool();

class CopyDatabase extends WorkerRequest<void> {
  CopyDatabase(this.fromPath, this.toName, this.config);

  final String fromPath;
  final String toName;
  final DatabaseConfiguration? config;
}

void copyDatabase(CopyDatabase request) => _bindings
    .copyDatabase(
      request.fromPath.toNativeUtf8().withScoped(),
      request.toName.toNativeUtf8().withScoped(),
      request.config?.toCBLDatabaseConfiguration() ?? nullptr,
      globalError,
    )
    .toBool()
    .checkResultAndError();

class DeleteDatabaseFile extends WorkerRequest<bool> {
  DeleteDatabaseFile(this.name, this.directory);
  final String name;
  final String? directory;
}

bool deleteDatabaseFile(DeleteDatabaseFile request) => _bindings
    .deleteDatabase(
      request.name.toNativeUtf8().withScoped(),
      request.directory == null
          ? nullptr
          : request.directory!.toNativeUtf8().withScoped(),
      globalError,
    )
    .toBool()
    .checkResultAndError();

class OpenDatabase extends WorkerRequest<int> {
  OpenDatabase(this.name, this.config);
  final String name;
  final DatabaseConfiguration? config;
}

int openDatabase(OpenDatabase request) => _bindings
    .open(
      request.name.toNativeUtf8().withScoped(),
      request.config?.toCBLDatabaseConfiguration() ?? nullptr,
      globalError,
    )
    .checkResultAndError()
    .address;

class GetDatabaseName extends ObjectRequest<CBLDatabase, String> {
  GetDatabaseName(Pointer<CBLDatabase> db) : super(db);
}

String getDatabaseName(GetDatabaseName request) =>
    _bindings.name(request.object).toDartString();

class GetDatabasePath extends ObjectRequest<CBLDatabase, String> {
  GetDatabasePath(Pointer<CBLDatabase> db) : super(db);
}

String getDatabasePath(GetDatabasePath request) =>
    _bindings.path(request.object).toDartString();

class GetDatabaseCount extends ObjectRequest<CBLDatabase, int> {
  GetDatabaseCount(Pointer<CBLDatabase> db) : super(db);
}

int getDatabaseCount(GetDatabaseCount request) =>
    _bindings.count(request.object);

class GetDatabaseConfiguration
    extends ObjectRequest<CBLDatabase, DatabaseConfiguration> {
  GetDatabaseConfiguration(Pointer<CBLDatabase> db) : super(db);
}

DatabaseConfiguration getDatabaseConfiguration(
  GetDatabaseConfiguration request,
) {
  final config = scoped(malloc<CBLDatabaseConfiguration>());
  _bindings.config(request.object, config);
  return config.toDatabaseConfiguration();
}

class CloseDatabase extends ObjectRequest<CBLDatabase, void> {
  CloseDatabase(Pointer<CBLDatabase> db) : super(db);
}

void closeDatabase(CloseDatabase request) =>
    _bindings.close(request.object, globalError).toBool().checkResultAndError();

class DeleteDatabase extends ObjectRequest<CBLDatabase, void> {
  DeleteDatabase(Pointer<CBLDatabase> db) : super(db);
}

void deleteDatabase(DeleteDatabase request) => _bindings
    .delete(request.object, globalError)
    .toBool()
    .checkResultAndError();

class CompactDatabase extends ObjectRequest<CBLDatabase, void> {
  CompactDatabase(Pointer<CBLDatabase> db) : super(db);
}

void compactDatabase(CompactDatabase request) => _bindings
    .compact(request.object, globalError)
    .toBool()
    .checkResultAndError();

class BeginDatabaseBatch extends ObjectRequest<CBLDatabase, void> {
  BeginDatabaseBatch(Pointer<CBLDatabase> db) : super(db);
}

void beginDatabaseBatch(BeginDatabaseBatch request) => _bindings
    .beginBatch(request.object, globalError)
    .toBool()
    .checkResultAndError();

class EndDatabaseBatch extends ObjectRequest<CBLDatabase, void> {
  EndDatabaseBatch(Pointer<CBLDatabase> db) : super(db);
}

void endDatabaseBatch(EndDatabaseBatch request) => _bindings
    .endBatch(request.object, globalError)
    .toBool()
    .checkResultAndError();

class RekeyDatabase extends ObjectRequest<CBLDatabase, void> {
  RekeyDatabase(Pointer<CBLDatabase> db, this.encryptionKey) : super(db);
  final EncryptionKey? encryptionKey;
}

void rekeyDatabase(RekeyDatabase request) {
  final encryptionKey = request.encryptionKey;
  final cblEncryptionKey =
      encryptionKey == null ? nullptr : encryptionKey.toCBLEncryptionKey();

  _bindings.rekey!
      .call(request.object, cblEncryptionKey, globalError)
      .toBool()
      .checkResultAndError();
}

class GetDatabaseDocument extends ObjectRequest<CBLDatabase, int?> {
  GetDatabaseDocument(Pointer<CBLDatabase> db, this.id) : super(db);
  final String id;
}

int? getDatabaseDocument(GetDatabaseDocument request) => _bindings
    .getDocument(request.object, request.id.toNativeUtf8().withScoped())
    .toAddressOrNull();

class GetDatabaseMutableDocument extends ObjectRequest<CBLDatabase, int?> {
  GetDatabaseMutableDocument(Pointer<CBLDatabase> db, this.id) : super(db);
  final String id;
}

int? getDatabaseMutableDocument(GetDatabaseMutableDocument request) => _bindings
    .getMutableDocument(request.object, request.id.toNativeUtf8().withScoped())
    .toAddressOrNull();

class SaveDatabaseDocument
    extends ObjectWithArgRequest<CBLDatabase, CBLMutableDocument, int> {
  SaveDatabaseDocument(
    Pointer<CBLDatabase> db,
    Pointer<CBLMutableDocument> doc,
    this.concurrency,
  ) : super(db, doc);

  final ConcurrencyControl concurrency;
}

int saveDatabaseDocument(SaveDatabaseDocument request) => _bindings
    .saveDocument(
      request.object,
      request.argument,
      concurrencyControlToC(request.concurrency),
      globalError,
    )
    .checkResultAndError()
    .address;

class SaveDatabaseDocumentResolving
    extends ObjectWithArgRequest<CBLDatabase, CBLMutableDocument, int> {
  SaveDatabaseDocumentResolving(
    Pointer<CBLDatabase> db,
    Pointer<CBLMutableDocument> doc,
    this.conflictResolverAddress,
  ) : super(db, doc);

  final int conflictResolverAddress;
}

int saveDatabaseDocumentResolving(SaveDatabaseDocumentResolving request) =>
    _bindings
        .saveDocumentResolving(
          request.object,
          request.argument,
          request.conflictResolverAddress.toPointer(),
          globalError,
        )
        .checkResultAndError()
        .address;

class PurgeDatabaseDocumentById extends ObjectRequest<CBLDatabase, bool> {
  PurgeDatabaseDocumentById(Pointer<CBLDatabase> db, this.id) : super(db);
  final String id;
}

bool purgeDatabaseDocumentById(PurgeDatabaseDocumentById request) => _bindings
    .purgeDocumentByID(
      request.object,
      request.id.toNativeUtf8().withScoped(),
      globalError,
    )
    .toBool()
    .checkResultAndError();

class GetDatabaseDocumentExpiration
    extends ObjectRequest<CBLDatabase, DateTime?> {
  GetDatabaseDocumentExpiration(Pointer<CBLDatabase> db, this.id) : super(db);
  final String id;
}

DateTime? getDatabaseDocumentExpiration(GetDatabaseDocumentExpiration request) {
  final timestamp = _bindings.getDocumentExpiration(
    request.object,
    request.id.toNativeUtf8().withScoped(),
    globalError,
  );

  if (timestamp == -1) {
    checkError();
  }

  return timestamp == 0 ? null : DateTime.fromMillisecondsSinceEpoch(timestamp);
}

class SetDatabaseDocumentExpiration extends ObjectRequest<CBLDatabase, void> {
  SetDatabaseDocumentExpiration(Pointer<CBLDatabase> db, this.id, this.time)
      : super(db);
  final String id;
  final DateTime? time;
}

void setDatabaseDocumentExpiration(SetDatabaseDocumentExpiration request) =>
    _bindings
        .setDocumentExpiration(
          request.object,
          request.id.toNativeUtf8().withScoped(),
          request.time == null ? 0 : request.time!.millisecondsSinceEpoch,
          globalError,
        )
        .toBool()
        .checkResultAndError();

class DeleteDocument extends ObjectRequest<CBLDocument, void> {
  DeleteDocument(Pointer<CBLDocument> doc, this.concurrency) : super(doc);
  final ConcurrencyControl concurrency;
}

void deleteDocument(DeleteDocument request) => _docBindings
    .delete(
      request.object,
      concurrencyControlToC(request.concurrency),
      globalError,
    )
    .toBool()
    .checkResultAndError();

class PurgeDocument extends ObjectRequest<CBLDocument, void> {
  PurgeDocument(Pointer<CBLDocument> doc) : super(doc);
}

void purgeDocument(PurgeDocument request) => _docBindings
    .purge(request.object, globalError)
    .toBool()
    .checkResultAndError();

class AddDocumentChangeListener extends ObjectRequest<CBLDatabase, void> {
  AddDocumentChangeListener(
      Pointer<CBLDatabase> db, this.docId, this.listenerAddress)
      : super(db);
  final String docId;
  final int listenerAddress;
}

void addDocumentChangeListener(AddDocumentChangeListener request) =>
    _bindings.addDocumentChangeListener(
      request.object,
      request.docId.toNativeUtf8().withScoped(),
      request.listenerAddress.toPointer(),
    );

late final _docBindings = CBLBindings.instance.document;

class AddDatabaseChangeListener extends ObjectRequest<CBLDatabase, void> {
  AddDatabaseChangeListener(Pointer<CBLDatabase> db, this.listenerAddress)
      : super(db);
  final int listenerAddress;
}

void addDatabaseChangeListener(AddDatabaseChangeListener request) =>
    _bindings.addChangeListener(
      request.object,
      request.listenerAddress.toPointer(),
    );

class CreateDatabaseIndex extends ObjectRequest<CBLDatabase, void> {
  CreateDatabaseIndex(Pointer<CBLDatabase> db, this.name, this.index)
      : super(db);
  final String name;
  final Index index;
}

extension on Pointer<CBLIndexSpec> {
  void initScoped(Index index) {
    late IndexType indexType;
    if (index is ValueIndex) {
      indexType = IndexType.value;
    } else if (index is FullTextIndex) {
      indexType = IndexType.fullText;
    } else {
      throw UnimplementedError('Index is not implemented: $index');
    }

    ref.type = indexType.toInt();
    ref.keyExpression = index.keyExpressions.toNativeUtf8().withScoped();

    if (index is FullTextIndex) {
      ref.ignoreAccents = index.ignoreAccents.toInt();
      ref.language = index.language?.toNativeUtf8().withScoped() ?? nullptr;
    } else {
      ref.ignoreAccents = false.toInt();
      ref.language == nullptr;
    }
  }
}

void createDatabaseIndex(CreateDatabaseIndex request) => _bindings
    .createIndex(
      request.object,
      request.name.toNativeUtf8().withScoped(),
      (scoped(malloc<CBLIndexSpec>())..initScoped(request.index)).ref,
      globalError,
    )
    .toBool()
    .checkResultAndError();

class DeleteDatabaseIndex extends ObjectRequest<CBLDatabase, void> {
  DeleteDatabaseIndex(Pointer<CBLDatabase> db, this.name) : super(db);
  final String name;
}

void deleteDatabaseIndex(DeleteDatabaseIndex request) => _bindings
    .deleteIndex(
      request.object,
      request.name.toNativeUtf8().withScoped(),
      globalError,
    )
    .toBool()
    .checkResultAndError();

class GetDatabaseIndexNames extends ObjectRequest<CBLDatabase, int> {
  GetDatabaseIndexNames(Pointer<CBLDatabase> db) : super(db);
}

int getDatabaseIndexNames(GetDatabaseIndexNames request) =>
    _bindings.indexNames(request.object).address;

void addDatabaseHandlersToRouter(RequestRouter router) {
  router.addHandler(databaseExists);
  router.addHandler(copyDatabase);
  router.addHandler(deleteDatabaseFile);
  router.addHandler(openDatabase);
  router.addHandler(getDatabaseName);
  router.addHandler(getDatabasePath);
  router.addHandler(getDatabaseCount);
  router.addHandler(getDatabaseConfiguration);
  router.addHandler(closeDatabase);
  router.addHandler(deleteDatabase);
  router.addHandler(compactDatabase);
  router.addHandler(beginDatabaseBatch);
  router.addHandler(endDatabaseBatch);
  router.addHandler(rekeyDatabase);
  router.addHandler(getDatabaseDocument);
  router.addHandler(getDatabaseMutableDocument);
  router.addHandler(saveDatabaseDocument);
  router.addHandler(saveDatabaseDocumentResolving);
  router.addHandler(purgeDatabaseDocumentById);
  router.addHandler(getDatabaseDocumentExpiration);
  router.addHandler(setDatabaseDocumentExpiration);
  router.addHandler(deleteDocument);
  router.addHandler(purgeDocument);
  router.addHandler(addDocumentChangeListener);
  router.addHandler(addDatabaseChangeListener);
  router.addHandler(createDatabaseIndex);
  router.addHandler(deleteDatabaseIndex);
  router.addHandler(getDatabaseIndexNames);
}
