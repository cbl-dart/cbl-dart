import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../../database.dart';
import '../../errors.dart';
import '../request_router.dart';
import '../worker.dart';
import 'shared.dart';

late final _bindings = CBLBindings.instance.database;

extension on EncryptionAlgorithm {
  CBLEncryptionAlgorithm toCBLEncryptionAlgorithm() =>
      CBLEncryptionAlgorithm.values[index];
}

extension on DatabaseFlag {
  CBLDatabaseFlag toCBLDatabaseFlag() => CBLDatabaseFlag.values[index];
}

extension on ConcurrencyControl {
  CBLConcurrencyControl toCBLConcurrencyControl() =>
      CBLConcurrencyControl.values[index];
}

extension on MaintenanceType {
  CBLMaintenanceType toCBLMaintenanceType() => CBLMaintenanceType.values[index];
}

class DatabaseExists extends WorkerRequest<bool> {
  DatabaseExists(this.name, this.directory);

  final String name;
  final String? directory;
}

bool databaseExists(DatabaseExists request) =>
    _bindings.databaseExists(request.name, request.directory);

class CopyDatabase extends WorkerRequest<void> {
  CopyDatabase(
    this.fromPath,
    this.toName,
    this.directory,
    this.flags,
    this.encryptionAlgorithm,
    Uint8List? encryptionKey,
  ) : encryptionKey = encryptionKey == null
            ? null
            : TransferableTypedData.fromList([encryptionKey]);

  final String fromPath;
  final String toName;
  final String? directory;
  final Set<DatabaseFlag>? flags;
  final EncryptionAlgorithm? encryptionAlgorithm;
  final TransferableTypedData? encryptionKey;
}

void copyDatabase(CopyDatabase request) => _bindings.copyDatabase(
      request.fromPath,
      request.toName,
      request.directory,
      request.flags?.map((flag) => flag.toCBLDatabaseFlag()).toSet(),
      request.encryptionAlgorithm?.toCBLEncryptionAlgorithm(),
      request.encryptionKey?.materialize().asUint8List(),
    );

class DeleteDatabaseFile extends WorkerRequest<bool> {
  DeleteDatabaseFile(this.name, this.directory);
  final String name;
  final String? directory;
}

bool deleteDatabaseFile(DeleteDatabaseFile request) =>
    _bindings.deleteDatabase(request.name, request.directory);

class OpenDatabase extends WorkerRequest<TransferablePointer<CBLDatabase>> {
  OpenDatabase(
    this.name,
    this.directory,
    this.flags,
    this.encryptionAlgorithm,
    Uint8List? encryptionKey,
  ) : encryptionKey = encryptionKey == null
            ? null
            : TransferableTypedData.fromList([encryptionKey]);

  final String name;
  final String? directory;
  final Set<DatabaseFlag>? flags;
  final EncryptionAlgorithm? encryptionAlgorithm;
  final TransferableTypedData? encryptionKey;
}

TransferablePointer<CBLDatabase> openDatabase(OpenDatabase request) => _bindings
    .open(
      request.name,
      request.directory,
      request.flags?.map((flag) => flag.toCBLDatabaseFlag()).toSet(),
      request.encryptionAlgorithm?.toCBLEncryptionAlgorithm(),
      request.encryptionKey?.materialize().asUint8List(),
    )
    .toTransferablePointer();

class GetDatabaseName extends WorkerRequest<String> {
  GetDatabaseName(Pointer<CBLDatabase> db) : db = db.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
}

String getDatabaseName(GetDatabaseName request) =>
    _bindings.name(request.db.pointer);

class GetDatabasePath extends WorkerRequest<String> {
  GetDatabasePath(Pointer<CBLDatabase> db) : db = db.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
}

String getDatabasePath(GetDatabasePath request) =>
    _bindings.path(request.db.pointer);

class GetDatabaseCount extends WorkerRequest<int> {
  GetDatabaseCount(Pointer<CBLDatabase> db) : db = db.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
}

int getDatabaseCount(GetDatabaseCount request) =>
    _bindings.count(request.db.pointer);

class CloseDatabase extends WorkerRequest<void> {
  CloseDatabase(Pointer<CBLDatabase> db) : db = db.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
}

void closeDatabase(CloseDatabase request) =>
    _bindings.close(request.db.pointer);

class DeleteDatabase extends WorkerRequest<void> {
  DeleteDatabase(Pointer<CBLDatabase> db) : db = db.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
}

void deleteDatabase(DeleteDatabase request) =>
    _bindings.delete(request.db.pointer);

class PerformDatabaseMaintenance
    extends WorkerRequest<CouchbaseLiteException?> {
  PerformDatabaseMaintenance(Pointer<CBLDatabase> db, this.type)
      : db = db.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
  final MaintenanceType type;
}

void performDatabaseMaintenance(PerformDatabaseMaintenance request) =>
    _bindings.performMaintenance(
        request.db.pointer, request.type.toCBLMaintenanceType());

class BeginDatabaseBatch extends WorkerRequest<void> {
  BeginDatabaseBatch(Pointer<CBLDatabase> db) : db = db.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
}

void beginDatabaseBatch(BeginDatabaseBatch request) =>
    _bindings.beginBatch(request.db.pointer);

class EndDatabaseBatch extends WorkerRequest<void> {
  EndDatabaseBatch(Pointer<CBLDatabase> db) : db = db.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
}

void endDatabaseBatch(EndDatabaseBatch request) =>
    _bindings.endBatch(request.db.pointer);

class RekeyDatabase extends WorkerRequest<void> {
  RekeyDatabase(Pointer<CBLDatabase> db, this.encryptionAlgorithm,
      Uint8List? encryptionKey)
      : db = db.toTransferablePointer(),
        encryptionKey = encryptionKey == null
            ? null
            : TransferableTypedData.fromList([encryptionKey]);

  final TransferablePointer<CBLDatabase> db;
  final EncryptionAlgorithm? encryptionAlgorithm;
  final TransferableTypedData? encryptionKey;
}

void rekeyDatabase(RekeyDatabase request) {
  _bindings.rekey(
    request.db.pointer,
    request.encryptionAlgorithm?.toCBLEncryptionAlgorithm(),
    request.encryptionKey?.materialize().asUint8List(),
  );
}

class GetDatabaseDocument
    extends WorkerRequest<TransferablePointer<CBLDocument>?> {
  GetDatabaseDocument(Pointer<CBLDatabase> db, this.id)
      : db = db.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
  final String id;
}

TransferablePointer<CBLDocument>? getDatabaseDocument(
        GetDatabaseDocument request) =>
    _bindings
        .getDocument(request.db.pointer, request.id)
        .toTransferablePointerOrNull();

class GetDatabaseMutableDocument
    extends WorkerRequest<TransferablePointer<CBLMutableDocument>?> {
  GetDatabaseMutableDocument(Pointer<CBLDatabase> db, this.id)
      : db = db.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
  final String id;
}

TransferablePointer<CBLMutableDocument>? getDatabaseMutableDocument(
        GetDatabaseMutableDocument request) =>
    _bindings
        .getMutableDocument(request.db.pointer, request.id)
        .toTransferablePointerOrNull();

class SaveDatabaseDocument
    extends WorkerRequest<TransferablePointer<CBLDocument>> {
  SaveDatabaseDocument(
    Pointer<CBLDatabase> db,
    Pointer<CBLMutableDocument> doc,
    this.concurrency,
  )   : db = db.toTransferablePointer(),
        doc = doc.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
  final TransferablePointer<CBLMutableDocument> doc;
  final ConcurrencyControl concurrency;
}

TransferablePointer<CBLDocument> saveDatabaseDocument(
        SaveDatabaseDocument request) =>
    _bindings
        .saveDocument(
          request.db.pointer,
          request.doc.pointer,
          request.concurrency.toCBLConcurrencyControl(),
        )
        .toTransferablePointer();

class SaveDatabaseDocumentResolving
    extends WorkerRequest<TransferablePointer<CBLDocument>> {
  SaveDatabaseDocumentResolving(
    Pointer<CBLDatabase> db,
    Pointer<CBLMutableDocument> doc,
    Pointer<Callback> conflictResolver,
  )   : db = db.toTransferablePointer(),
        doc = doc.toTransferablePointer(),
        conflictResolver = conflictResolver.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
  final TransferablePointer<CBLMutableDocument> doc;
  final TransferablePointer<Callback> conflictResolver;
}

TransferablePointer<CBLDocument> saveDatabaseDocumentResolving(
        SaveDatabaseDocumentResolving request) =>
    _bindings
        .saveDocumentResolving(
          request.db.pointer,
          request.doc.pointer,
          request.conflictResolver.pointer,
        )
        .toTransferablePointer();

class PurgeDatabaseDocumentById extends WorkerRequest<bool> {
  PurgeDatabaseDocumentById(Pointer<CBLDatabase> db, this.id)
      : db = db.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
  final String id;
}

bool purgeDatabaseDocumentById(PurgeDatabaseDocumentById request) =>
    _bindings.purgeDocumentByID(request.db.pointer, request.id);

class GetDatabaseDocumentExpiration extends WorkerRequest<DateTime?> {
  GetDatabaseDocumentExpiration(Pointer<CBLDatabase> db, this.id)
      : db = db.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
  final String id;
}

DateTime? getDatabaseDocumentExpiration(
  GetDatabaseDocumentExpiration request,
) =>
    _bindings.getDocumentExpiration(request.db.pointer, request.id);

class SetDatabaseDocumentExpiration extends WorkerRequest<void> {
  SetDatabaseDocumentExpiration(Pointer<CBLDatabase> db, this.id, this.time)
      : db = db.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
  final String id;
  final DateTime? time;
}

void setDatabaseDocumentExpiration(SetDatabaseDocumentExpiration request) =>
    _bindings.setDocumentExpiration(
        request.db.pointer, request.id, request.time);

class DeleteDocument extends WorkerRequest<void> {
  DeleteDocument(Pointer<CBLDocument> doc, this.concurrency)
      : doc = doc.toTransferablePointer();

  final TransferablePointer<CBLDocument> doc;
  final ConcurrencyControl concurrency;
}

void deleteDocument(DeleteDocument request) => _docBindings.delete(
      request.doc.pointer,
      request.concurrency.toCBLConcurrencyControl(),
    );

class PurgeDocument extends WorkerRequest<void> {
  PurgeDocument(Pointer<CBLDocument> doc) : doc = doc.toTransferablePointer();

  final TransferablePointer<CBLDocument> doc;
}

void purgeDocument(PurgeDocument request) =>
    _docBindings.purge(request.doc.pointer);

class AddDocumentChangeListener extends WorkerRequest<void> {
  AddDocumentChangeListener(
      Pointer<CBLDatabase> db, this.docId, Pointer<Callback> listener)
      : db = db.toTransferablePointer(),
        listener = listener.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
  final String docId;
  final TransferablePointer<Callback> listener;
}

void addDocumentChangeListener(AddDocumentChangeListener request) =>
    _bindings.addDocumentChangeListener(
      request.db.pointer,
      request.docId,
      request.listener.pointer,
    );

late final _docBindings = CBLBindings.instance.document;

class AddDatabaseChangeListener extends WorkerRequest<void> {
  AddDatabaseChangeListener(Pointer<CBLDatabase> db, Pointer<Callback> listener)
      : db = db.toTransferablePointer(),
        listener = listener.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
  final TransferablePointer<Callback> listener;
}

void addDatabaseChangeListener(AddDatabaseChangeListener request) =>
    _bindings.addChangeListener(request.db.pointer, request.listener.pointer);

class CreateDatabaseIndex extends WorkerRequest<void> {
  CreateDatabaseIndex(Pointer<CBLDatabase> db, this.name, this.index)
      : db = db.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
  final String name;
  final Index index;
}

void createDatabaseIndex(CreateDatabaseIndex request) {
  final index = request.index;
  CBLIndexType type;
  bool? ignoreAccents;
  String? language;

  if (index is ValueIndex) {
    type = CBLIndexType.value;
  } else if (index is FullTextIndex) {
    type = CBLIndexType.fullText;
    ignoreAccents = index.ignoreAccents;
    language = index.language;
  } else {
    throw UnimplementedError('index of unknown type: $index');
  }

  _bindings.createIndex(
    request.db.pointer,
    request.name,
    type,
    index.keyExpressions,
    ignoreAccents,
    language,
  );
}

class DeleteDatabaseIndex extends WorkerRequest<void> {
  DeleteDatabaseIndex(Pointer<CBLDatabase> db, this.name)
      : db = db.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
  final String name;
}

void deleteDatabaseIndex(DeleteDatabaseIndex request) =>
    _bindings.deleteIndex(request.db.pointer, request.name);

class GetDatabaseIndexNames
    extends WorkerRequest<TransferablePointer<FLArray>> {
  GetDatabaseIndexNames(Pointer<CBLDatabase> db)
      : db = db.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
}

TransferablePointer<FLArray> getDatabaseIndexNames(
        GetDatabaseIndexNames request) =>
    _bindings.indexNames(request.db.pointer).toTransferablePointer();

void addDatabaseHandlersToRouter(RequestRouter router) {
  router.addHandler(databaseExists);
  router.addHandler(copyDatabase);
  router.addHandler(deleteDatabaseFile);
  router.addHandler(openDatabase);
  router.addHandler(getDatabaseName);
  router.addHandler(getDatabasePath);
  router.addHandler(getDatabaseCount);
  router.addHandler(closeDatabase);
  router.addHandler(deleteDatabase);
  router.addHandler(performDatabaseMaintenance);
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
