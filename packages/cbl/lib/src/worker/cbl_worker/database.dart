import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../../database.dart';
import '../../errors.dart';
import '../request_router.dart';
import '../worker.dart';
import 'shared.dart';

late final _bindings = CBLBindings.instance.database;

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
  );

  final String fromPath;
  final String toName;
  final String? directory;
}

void copyDatabase(CopyDatabase request) => _bindings.copyDatabase(
      request.fromPath,
      request.toName,
      request.directory,
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
  );

  final String name;
  final String? directory;
}

TransferablePointer<CBLDatabase> openDatabase(OpenDatabase request) => _bindings
    .open(
      request.name,
      request.directory,
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

class BeginDatabaseTransaction extends WorkerRequest<void> {
  BeginDatabaseTransaction(Pointer<CBLDatabase> db)
      : db = db.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
}

void beginDatabaseTransaction(BeginDatabaseTransaction request) =>
    _bindings.beginTransaction(request.db.pointer);

class EndDatabaseTransaction extends WorkerRequest<void> {
  EndDatabaseTransaction(Pointer<CBLDatabase> db, this.commit)
      : db = db.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
  final bool commit;
}

void endDatabaseTransaction(EndDatabaseTransaction request) =>
    _bindings.endTransaction(request.db.pointer, request.commit);

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

class SaveDatabaseDocumentWithConcurrencyControl extends WorkerRequest<void> {
  SaveDatabaseDocumentWithConcurrencyControl(
    Pointer<CBLDatabase> db,
    Pointer<CBLMutableDocument> doc,
    this.concurrency,
  )   : db = db.toTransferablePointer(),
        doc = doc.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
  final TransferablePointer<CBLMutableDocument> doc;
  final ConcurrencyControl concurrency;
}

void saveDatabaseDocumentWithConcurrencyControl(
  SaveDatabaseDocumentWithConcurrencyControl request,
) =>
    _bindings.saveDocumentWithConcurrencyControl(
      request.db.pointer,
      request.doc.pointer,
      request.concurrency.toCBLConcurrencyControl(),
    );

class SaveDatabaseDocumentWithConflictHandler extends WorkerRequest<void> {
  SaveDatabaseDocumentWithConflictHandler(
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

void saveDatabaseDocumentResolvingWithConflictHandler(
  SaveDatabaseDocumentWithConflictHandler request,
) =>
    _bindings.saveDocumentWithConflictHandler(
      request.db.pointer,
      request.doc.pointer,
      request.conflictResolver.pointer,
    );

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

class DeleteDocumentWithConcurrencyControl extends WorkerRequest<bool> {
  DeleteDocumentWithConcurrencyControl(
      Pointer<CBLDatabase> db, Pointer<CBLDocument> doc, this.concurrency)
      : db = db.toTransferablePointer(),
        doc = doc.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
  final TransferablePointer<CBLDocument> doc;
  final ConcurrencyControl concurrency;
}

bool deleteDocumentWithConcurrencyControl(
  DeleteDocumentWithConcurrencyControl request,
) =>
    _bindings.deleteDocumentWithConcurrencyControl(
      request.db.pointer,
      request.doc.pointer,
      request.concurrency.toCBLConcurrencyControl(),
    );

class PurgeDocumentByID extends WorkerRequest<bool> {
  PurgeDocumentByID(Pointer<CBLDatabase> db, this.docID)
      : db = db.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
  final String docID;
}

void purgeDocumentByID(PurgeDocumentByID request) =>
    _bindings.purgeDocumentByID(request.db.pointer, request.docID);

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
  CBLdart_IndexType type;
  bool? ignoreAccents;
  String? language;

  if (index is ValueIndex) {
    type = CBLdart_IndexType.value;
  } else if (index is FullTextIndex) {
    type = CBLdart_IndexType.fullText;
    ignoreAccents = index.ignoreAccents;
    language = index.language;
  } else {
    throw UnimplementedError('index of unknown type: $index');
  }

  _bindings.createIndex(
    request.db.pointer,
    request.name,
    type,
    CBLQueryLanguage.json,
    index.expressions,
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
  GetDatabaseIndexNames request,
) =>
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
  router.addHandler(beginDatabaseTransaction);
  router.addHandler(endDatabaseTransaction);
  router.addHandler(getDatabaseDocument);
  router.addHandler(getDatabaseMutableDocument);
  router.addHandler(saveDatabaseDocumentWithConcurrencyControl);
  router.addHandler(saveDatabaseDocumentResolvingWithConflictHandler);
  router.addHandler(purgeDatabaseDocumentById);
  router.addHandler(getDatabaseDocumentExpiration);
  router.addHandler(setDatabaseDocumentExpiration);
  router.addHandler(deleteDocumentWithConcurrencyControl);
  router.addHandler(purgeDocumentByID);
  router.addHandler(addDocumentChangeListener);
  router.addHandler(addDatabaseChangeListener);
  router.addHandler(createDatabaseIndex);
  router.addHandler(deleteDatabaseIndex);
  router.addHandler(getDatabaseIndexNames);
}
