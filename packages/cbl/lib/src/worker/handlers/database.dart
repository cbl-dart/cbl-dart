import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../../bindings/bindings.dart';
import '../../database.dart';
import '../../errors.dart';
import '../../ffi_utils.dart';
import '../handlers.dart';
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
            directory == null ? nullptr : scoped(Utf8.toUtf8(directory!))
        ..ref.flags = flags.toCFlags()
        ..ref.encryptionKey = encryptionKey?.toCBLEncryptionKey() ?? nullptr;
}

extension on Pointer<CBLDatabaseConfiguration> {
  DatabaseConfiguration toDatabaseConfiguration() => DatabaseConfiguration(
        directory:
            ref.directory == nullptr ? null : Utf8.fromUtf8(ref.directory),
        flags: DatabaseFlag.parseCFlags(ref.flags),
        encryptionKey: ref.encryptionKey == nullptr
            ? null
            : ref.encryptionKey.toEncryptionKey(),
      );
}

class DatabaseExists {
  DatabaseExists(this.name, this.directory);

  final String name;
  final String? directory;
}

bool databaseExists(DatabaseExists request) => _bindings
    .databaseExists(
      scoped(Utf8.toUtf8(request.name)),
      request.directory == null
          ? nullptr
          : scoped(Utf8.toUtf8(request.directory!)),
    )
    .toBool;

class CopyDatabase {
  CopyDatabase(this.fromPath, this.toName, this.config);

  final String fromPath;
  final String toName;
  final DatabaseConfiguration? config;
}

void copyDatabase(CopyDatabase request) => _bindings
    .copyDatabase(
      scoped(Utf8.toUtf8(request.fromPath)),
      scoped(Utf8.toUtf8(request.toName)),
      request.config?.toCBLDatabaseConfiguration() ?? nullptr,
      globalError,
    )
    .toBool
    .checkResultAndError();

class DeleteDatabaseFile {
  DeleteDatabaseFile(this.name, this.directory);
  final String name;
  final String? directory;
}

bool deleteDatabaseFile(DeleteDatabaseFile request) => _bindings
    .deleteDatabase(
      scoped(Utf8.toUtf8(request.name)),
      request.directory == null
          ? nullptr
          : scoped(Utf8.toUtf8(request.directory!)),
      globalError,
    )
    .toBool
    .checkResultAndError();

class OpenDatabase {
  OpenDatabase(this.name, this.config);
  final String name;
  final DatabaseConfiguration? config;
}

int openDatabase(OpenDatabase request) => _bindings
    .open(
      scoped(Utf8.toUtf8(request.name)),
      request.config?.toCBLDatabaseConfiguration() ?? nullptr,
      globalError,
    )
    .checkResultAndError()
    .address;

class GetDatabaseName extends ObjectRequest {
  GetDatabaseName(int address) : super(address);
}

String getDatabaseName(GetDatabaseName request) =>
    _bindings.name(request.pointer).asString;

class GetDatabasePath extends ObjectRequest {
  GetDatabasePath(int address) : super(address);
}

String getDatabasePath(GetDatabasePath request) =>
    _bindings.path(request.pointer).asString;

class GetDatabaseCount extends ObjectRequest {
  GetDatabaseCount(int address) : super(address);
}

int getDatabaseCount(GetDatabaseCount request) =>
    _bindings.count(request.pointer);

class GetDatabaseConfiguration extends ObjectRequest {
  GetDatabaseConfiguration(int address) : super(address);
}

DatabaseConfiguration getDatabaseConfiguration(
  GetDatabaseConfiguration request,
) {
  final config = scoped(malloc<CBLDatabaseConfiguration>());
  _bindings.config(request.pointer, config);
  return config.toDatabaseConfiguration();
}

class CloseDatabase extends ObjectRequest {
  CloseDatabase(int address) : super(address);
}

void closeDatabase(CloseDatabase request) =>
    _bindings.close(request.pointer, globalError).toBool.checkResultAndError();

class DeleteDatabase extends ObjectRequest {
  DeleteDatabase(int address) : super(address);
}

void deleteDatabase(DeleteDatabase request) =>
    _bindings.delete(request.pointer, globalError).toBool.checkResultAndError();

class CompactDatabase extends ObjectRequest {
  CompactDatabase(int address) : super(address);
}

void compactDatabase(CompactDatabase request) => _bindings
    .compact(request.pointer, globalError)
    .toBool
    .checkResultAndError();

class BeginDatabaseBatch extends ObjectRequest {
  BeginDatabaseBatch(int address) : super(address);
}

void beginDatabaseBatch(BeginDatabaseBatch request) => _bindings
    .beginBatch(request.pointer, globalError)
    .toBool
    .checkResultAndError();

class EndDatabaseBatch extends ObjectRequest {
  EndDatabaseBatch(int address) : super(address);
}

void endDatabaseBatch(EndDatabaseBatch request) => _bindings
    .endBatch(request.pointer, globalError)
    .toBool
    .checkResultAndError();

class RekeyDatabase extends ObjectRequest {
  RekeyDatabase(int address, this.encryptionKey) : super(address);
  final EncryptionKey? encryptionKey;
}

void rekeyDatabase(RekeyDatabase request) {
  final encryptionKey = request.encryptionKey;
  final cblEncryptionKey =
      encryptionKey == null ? nullptr : encryptionKey.toCBLEncryptionKey();

  _bindings.rekey!
      .call(request.pointer, cblEncryptionKey, globalError)
      .toBool
      .checkResultAndError();
}

class GetDatabaseDocument extends ObjectRequest {
  GetDatabaseDocument(int address, this.id) : super(address);
  final String id;
}

int? getDatabaseDocument(GetDatabaseDocument request) => _bindings
    .getDocument(request.pointer, scoped(Utf8.toUtf8(request.id)))
    .addressOrNull;

class GetDatabaseMutableDocument extends ObjectRequest {
  GetDatabaseMutableDocument(int address, this.id) : super(address);
  final String id;
}

int? getDatabaseMutableDocument(GetDatabaseMutableDocument request) => _bindings
    .getMutableDocument(request.pointer, scoped(Utf8.toUtf8(request.id)))
    .addressOrNull;

class SaveDatabaseDocument extends ObjectRequest {
  SaveDatabaseDocument(int address, this.docAdress, this.concurrency)
      : super(address);
  final int docAdress;
  final ConcurrencyControl concurrency;
}

int saveDatabaseDocument(SaveDatabaseDocument request) => _bindings
    .saveDocument(
      request.pointer,
      request.docAdress.toPointer,
      concurrencyControlToC(request.concurrency),
      globalError,
    )
    .checkResultAndError()
    .address;

class SaveDatabaseDocumentResolving extends ObjectRequest {
  SaveDatabaseDocumentResolving(
      int address, this.docAddress, this.conflictResolverId)
      : super(address);
  final int docAddress;
  final int conflictResolverId;
}

int saveDatabaseDocumentResolving(SaveDatabaseDocumentResolving request) =>
    _bindings
        .saveDocumentResolving(
          request.pointer,
          request.docAddress.toPointer,
          request.conflictResolverId,
          globalError,
        )
        .checkResultAndError()
        .address;

class PurgeDatabaseDocumentById extends ObjectRequest {
  PurgeDatabaseDocumentById(int address, this.id) : super(address);
  final String id;
}

bool purgeDatabaseDocumentById(PurgeDatabaseDocumentById request) => _bindings
    .purgeDocumentByID(
      request.pointer,
      scoped(Utf8.toUtf8(request.id)),
      globalError,
    )
    .toBool
    .checkResultAndError();

class GetDatabaseDocumentExpiration extends ObjectRequest {
  GetDatabaseDocumentExpiration(int address, this.id) : super(address);
  final String id;
}

DateTime? getDatabaseDocumentExpiration(GetDatabaseDocumentExpiration request) {
  final timestamp = _bindings.getDocumentExpiration(
    request.pointer,
    scoped(Utf8.toUtf8(request.id)),
    globalError,
  );

  if (timestamp == -1) {
    checkError();
  }

  return timestamp == 0 ? null : DateTime.fromMillisecondsSinceEpoch(timestamp);
}

class SetDatabaseDocumentExpiration extends ObjectRequest {
  SetDatabaseDocumentExpiration(int address, this.id, this.time)
      : super(address);
  final String id;
  final DateTime? time;
}

void setDatabaseDocumentExpiration(SetDatabaseDocumentExpiration request) =>
    _bindings
        .setDocumentExpiration(
          request.pointer,
          scoped(Utf8.toUtf8(request.id)),
          request.time == null ? 0 : request.time!.millisecondsSinceEpoch,
          globalError,
        )
        .toBool
        .checkResultAndError();

class DeleteDocument extends ObjectRequest {
  DeleteDocument(int address, this.concurrency) : super(address);
  final ConcurrencyControl concurrency;
}

void deleteDocument(DeleteDocument request) => _docBindings
    .delete(
      request.pointer,
      concurrencyControlToC(request.concurrency),
      globalError,
    )
    .toBool
    .checkResultAndError();

class PurgeDocument extends ObjectRequest {
  PurgeDocument(int address) : super(address);
}

void purgeDocument(PurgeDocument request) => _docBindings
    .purge(request.pointer, globalError)
    .toBool
    .checkResultAndError();

class AddDocumentChangeListener extends ObjectRequest {
  AddDocumentChangeListener(int address, this.docId, this.listenerId)
      : super(address);
  final String docId;
  final int listenerId;
}

void addDocumentChangeListener(AddDocumentChangeListener request) =>
    _bindings.addDocumentChangeListener(
      request.pointer,
      scoped(Utf8.toUtf8(request.docId)),
      request.listenerId,
    );

late final _docBindings = CBLBindings.instance.document;

class AddDatabaseChangeListener extends ObjectRequest {
  AddDatabaseChangeListener(int address, this.listenerId) : super(address);
  final int listenerId;
}

void addDatabaseChangeListener(AddDatabaseChangeListener request) =>
    _bindings.addChangeListener(request.pointer, request.listenerId);

class CreateDatabaseIndex extends ObjectRequest {
  CreateDatabaseIndex(int address, this.name, this.index) : super(address);
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

    ref.type = indexType.toInt;
    ref.keyExpression = index.keyExpressions.asUtf8Scoped;

    if (index is FullTextIndex) {
      ref.ignoreAccents = index.ignoreAccents.toInt;
      ref.language = index.language?.asUtf8Scoped ?? nullptr;
    } else {
      ref.ignoreAccents = false.toInt;
      ref.language == nullptr;
    }
  }
}

void createDatabaseIndex(CreateDatabaseIndex request) => _bindings
    .createIndex(
      request.pointer,
      request.name.asUtf8Scoped,
      scoped(malloc<CBLIndexSpec>())..initScoped(request.index),
      globalError,
    )
    .toBool
    .checkResultAndError();

class DeleteDatabaseIndex extends ObjectRequest {
  DeleteDatabaseIndex(int address, this.name) : super(address);
  final String name;
}

void deleteDatabaseIndex(DeleteDatabaseIndex request) => _bindings
    .deleteIndex(
      request.pointer,
      request.name.asUtf8Scoped,
      globalError,
    )
    .toBool
    .checkResultAndError();

class GetDatabaseIndexNames extends ObjectRequest {
  GetDatabaseIndexNames(int address) : super(address);
}

int getDatabaseIndexNames(GetDatabaseIndexNames request) =>
    _bindings.indexNames(request.pointer).address;

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
