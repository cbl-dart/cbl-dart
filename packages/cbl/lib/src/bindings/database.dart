import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'base.dart';
import 'bindings.dart';

/// Encryption algorithms (available only in the Enterprise Edition).
enum EncryptionAlgorithm {
  /// No encryption (default).
  none,

  /// AES with 256-bit key.
  aes256,
}

int encryptionAlgorithmToC(EncryptionAlgorithm value) =>
    EncryptionAlgorithm.values.indexOf(value);

EncryptionAlgorithm encryptionAlgorithmFromC(int value) =>
    EncryptionAlgorithm.values[value];

class CBLEncryptionKey extends Struct {
  @Uint32()
  external int algorithm;

  external Pointer<Uint8> bytes;
}

/// Flags for how to open a database.
class DatabaseFlag extends Option {
  const DatabaseFlag._(String name, int bits) : super(name, bits);

  /// Create the file if it doesn't exist.
  static const create = DatabaseFlag._('create', 1);

  /// Open file read-only.
  static const readOnly = DatabaseFlag._('readOnly', 2);

  /// Disable upgrading an older-version database.
  static const noUpgrade = DatabaseFlag._('noUpgrade', 4);

  static const values = {create, readOnly, noUpgrade};

  static Set<DatabaseFlag> parseCFlags(int flags) => values.parseCFlags(flags);
}

class CBLDatabaseConfiguration extends Struct {
  external Pointer<Utf8> directory;

  @Uint32()
  external int flags;

  external Pointer<CBLEncryptionKey> encryptionKey;
}

/// Conflict-handling options when saving or deleting a document.
enum ConcurrencyControl {
  /// The current save/delete will overwrite a conflicting revision if there is
  /// a conflict.
  lastWriteWins,

  /// The current save/delete will fail if there is a conflict.
  failOnConflict,
}

int concurrencyControlToC(ConcurrencyControl value) =>
    ConcurrencyControl.values.indexOf(value);

// TODO: Replace Void with CBLDatabase where appropriate
class CBLDatabase extends Opaque {}

typedef CBLDatabase_Exists_C = Uint8 Function(
  Pointer<Utf8> name,
  Pointer<Utf8> inDirectory,
);
typedef CBLDatabase_Exists = int Function(
  Pointer<Utf8> name,
  Pointer<Utf8> inDirectory,
);

typedef CBL_CopyDatabase_C = Uint8 Function(
  Pointer<Utf8> fromPath,
  Pointer<Utf8> toPath,
  Pointer<CBLDatabaseConfiguration> config,
  Pointer<CBLError> error,
);
typedef CBL_CopyDatabase = int Function(
  Pointer<Utf8> fromPath,
  Pointer<Utf8> toPath,
  Pointer<CBLDatabaseConfiguration> config,
  Pointer<CBLError> error,
);

typedef CBL_DeleteDatabase_C = Uint8 Function(
  Pointer<Utf8> name,
  Pointer<Utf8> inDirectory,
  Pointer<CBLError> outError,
);
typedef CBL_DeleteDatabase = int Function(
  Pointer<Utf8> name,
  Pointer<Utf8> inDirectory,
  Pointer<CBLError> outError,
);

typedef CBLDart_Database_BindToDartObject_C = Void Function(
  Handle dartDb,
  Pointer<Void> db,
);
typedef CBLDart_Database_BindToDartObject = void Function(
  Object dartDb,
  Pointer<Void> db,
);

typedef CBLDatabase_Open = Pointer<Void> Function(
  Pointer<Utf8> name,
  Pointer<CBLDatabaseConfiguration> config,
  Pointer<CBLError> error,
);

typedef CBLDatabase_Close_C = Uint8 Function(
  Pointer<Void> db,
  Pointer<CBLError> error,
);
typedef CBLDatabase_Close = int Function(
  Pointer<Void> db,
  Pointer<CBLError> error,
);

typedef CBLDatabase_Delete_C = Uint8 Function(
  Pointer<Void> db,
  Pointer<CBLError> error,
);
typedef CBLDatabase_Delete = int Function(
  Pointer<Void> db,
  Pointer<CBLError> error,
);

typedef CBLDatabase_Compact_C = Uint8 Function(
  Pointer<Void> db,
  Pointer<CBLError> error,
);
typedef CBLDatabase_Compact = int Function(
  Pointer<Void> db,
  Pointer<CBLError> error,
);

typedef CBLDatabase_BeginBatch_C = Uint8 Function(
  Pointer<Void> db,
  Pointer<CBLError> error,
);
typedef CBLDatabase_BeginBatch = int Function(
  Pointer<Void> db,
  Pointer<CBLError> error,
);

typedef CBLDatabase_EndBatch_C = Uint8 Function(
  Pointer<Void> db,
  Pointer<CBLError> error,
);
typedef CBLDatabase_EndBatch = int Function(
  Pointer<Void> db,
  Pointer<CBLError> error,
);

typedef CBLDatabase_Rekey_C = Uint8 Function(
  Pointer<Void> db,
  Pointer<CBLEncryptionKey> encryptionKey,
  Pointer<CBLError> error,
);
typedef CBLDatabase_Rekey = int Function(
  Pointer<Void> db,
  Pointer<CBLEncryptionKey> encryptionKey,
  Pointer<CBLError> error,
);

typedef CBLDatabase_Name = Pointer<Utf8> Function(
  Pointer<Void> db,
);

typedef CBLDatabase_Path = Pointer<Utf8> Function(
  Pointer<Void> db,
);

typedef CBLDatabase_Count_C = Uint64 Function(
  Pointer<Void> db,
);
typedef CBLDatabase_Count = int Function(
  Pointer<Void> db,
);

typedef CBLDatabase_Config_C = Void Function(
  Pointer<Void> db,
  Pointer<CBLDatabaseConfiguration> config,
);
typedef CBLDatabase_Config = void Function(
  Pointer<Void> db,
  Pointer<CBLDatabaseConfiguration> config,
);

typedef CBLDatabase_GetDocument = Pointer<Void> Function(
  Pointer<Void> db,
  Pointer<Utf8> docId,
);

typedef CBLDatabase_GetMutableDocument = Pointer<Void> Function(
  Pointer<Void> db,
  Pointer<Utf8> docId,
);

typedef CBLDatabase_SaveDocument_C = Pointer<Void> Function(
  Pointer<Void> db,
  Pointer<Void> doc,
  Uint8 concurrency,
  Pointer<CBLError> error,
);
typedef CBLDatabase_SaveDocument = Pointer<Void> Function(
  Pointer<Void> db,
  Pointer<Void> doc,
  int concurrency,
  Pointer<CBLError> error,
);
typedef CBLDart_CBLDatabase_SaveDocumentResolving_C = Pointer<Void> Function(
  Pointer<Void> db,
  Pointer<Void> doc,
  Int64 conflictResolverId,
  Pointer<CBLError> error,
);
typedef CBLDart_CBLDatabase_SaveDocumentResolving = Pointer<Void> Function(
  Pointer<Void> db,
  Pointer<Void> doc,
  int conflictResolverId,
  Pointer<CBLError> error,
);

typedef CBLDatabase_PurgeDocumentByID_C = Uint8 Function(
  Pointer<Void> db,
  Pointer<Utf8> docId,
  Pointer<CBLError> error,
);
typedef CBLDatabase_PurgeDocumentByID = int Function(
  Pointer<Void> db,
  Pointer<Utf8> docId,
  Pointer<CBLError> error,
);

typedef CBLDatabase_GetDocumentExpiration_C = Int64 Function(
  Pointer<Void> db,
  Pointer<Utf8> docId,
  Pointer<CBLError> error,
);
typedef CBLDatabase_GetDocumentExpiration = int Function(
  Pointer<Void> db,
  Pointer<Utf8> docId,
  Pointer<CBLError> error,
);

typedef CBLDatabase_SetDocumentExpiration_C = Uint8 Function(
  Pointer<Void> db,
  Pointer<Utf8> docId,
  Int64 expiration,
  Pointer<CBLError> error,
);
typedef CBLDatabase_SetDocumentExpiration = int Function(
  Pointer<Void> db,
  Pointer<Utf8> docId,
  int expiration,
  Pointer<CBLError> error,
);

typedef CBLDart_CBLDatabase_AddDocumentChangeListener_C = Void Function(
  Pointer<Void> db,
  Pointer<Utf8> docId,
  Int64 listener,
);
typedef CBLDart_CBLDatabase_AddDocumentChangeListener = void Function(
  Pointer<Void> db,
  Pointer<Utf8> docId,
  int listener,
);

typedef CBLDart_CBLDatabase_AddChangeListener_C = Void Function(
  Pointer<Void> db,
  Int64 listener,
);
typedef CBLDart_CBLDatabase_AddChangeListener = void Function(
  Pointer<Void> db,
  int listener,
);

enum IndexType {
  value,
  fullText,
}

extension IndexTypeIntExt on IndexType {
  int get toInt => IndexType.values.indexOf(this);
}

class CBLIndexSpec extends Struct {
  @Uint32()
  external int type;

  external Pointer<Utf8> keyExpression;

  @Uint8()
  external int ignoreAccents;

  external Pointer<Utf8> language;
}

typedef CBLDart_CBLDatabase_CreateIndex_C = Uint8 Function(
  Pointer<Void> db,
  Pointer<Utf8> name,
  Pointer<CBLIndexSpec> indexSpec,
  Pointer<CBLError> error,
);
typedef CBLDart_CBLDatabase_CreateIndex = int Function(
  Pointer<Void> db,
  Pointer<Utf8> name,
  Pointer<CBLIndexSpec> indexSpec,
  Pointer<CBLError> error,
);

typedef CBLDatabase_DeleteIndex_C = Uint8 Function(
  Pointer<Void> db,
  Pointer<Utf8> name,
  Pointer<CBLError> error,
);
typedef CBLDatabase_DeleteIndex = int Function(
  Pointer<Void> db,
  Pointer<Utf8> name,
  Pointer<CBLError> error,
);

typedef CBLDatabase_IndexNames = Pointer<Void> Function(Pointer<Void> db);

class DatabaseBindings {
  DatabaseBindings(Libraries libs)
      : databaseExists =
            libs.cbl.lookupFunction<CBLDatabase_Exists_C, CBLDatabase_Exists>(
          'CBL_DatabaseExists',
        ),
        copyDatabase =
            libs.cbl.lookupFunction<CBL_CopyDatabase_C, CBL_CopyDatabase>(
          'CBL_CopyDatabase',
        ),
        deleteDatabase =
            libs.cbl.lookupFunction<CBL_DeleteDatabase_C, CBL_DeleteDatabase>(
          'CBL_DeleteDatabase',
        ),
        bindToDartObject = libs.cblDart.lookupFunction<
            CBLDart_Database_BindToDartObject_C,
            CBLDart_Database_BindToDartObject>(
          'CBLDart_Database_BindToDartObject',
        ),
        open = libs.cbl.lookupFunction<CBLDatabase_Open, CBLDatabase_Open>(
          'CBLDatabase_Open',
        ),
        close = libs.cbl.lookupFunction<CBLDatabase_Close_C, CBLDatabase_Close>(
          'CBLDatabase_Close',
        ),
        delete =
            libs.cbl.lookupFunction<CBLDatabase_Delete_C, CBLDatabase_Delete>(
          'CBLDatabase_Delete',
        ),
        compact =
            libs.cbl.lookupFunction<CBLDatabase_Compact_C, CBLDatabase_Compact>(
          'CBLDatabase_Compact',
        ),
        beginBatch = libs.cbl
            .lookupFunction<CBLDatabase_BeginBatch_C, CBLDatabase_BeginBatch>(
          'CBLDatabase_BeginBatch',
        ),
        endBatch = libs.cbl
            .lookupFunction<CBLDatabase_EndBatch_C, CBLDatabase_EndBatch>(
          'CBLDatabase_EndBatch',
        ),
        rekey =
            libs.cblEE?.lookupFunction<CBLDatabase_Rekey_C, CBLDatabase_Rekey>(
          'CBLDatabase_Rekey',
        ),
        name = libs.cbl.lookupFunction<CBLDatabase_Name, CBLDatabase_Name>(
          'CBLDatabase_Name',
        ),
        path = libs.cbl.lookupFunction<CBLDatabase_Path, CBLDatabase_Path>(
          'CBLDatabase_Path',
        ),
        count = libs.cbl.lookupFunction<CBLDatabase_Count_C, CBLDatabase_Count>(
          'CBLDatabase_Count',
        ),
        config = libs.cblDart
            .lookupFunction<CBLDatabase_Config_C, CBLDatabase_Config>(
          'CBLDart_CBLDatabase_Config',
        ),
        getDocument = libs.cbl
            .lookupFunction<CBLDatabase_GetDocument, CBLDatabase_GetDocument>(
          'CBLDatabase_GetDocument',
        ),
        getMutableDocument = libs.cbl.lookupFunction<
            CBLDatabase_GetMutableDocument, CBLDatabase_GetMutableDocument>(
          'CBLDatabase_GetMutableDocument',
        ),
        saveDocument = libs.cbl.lookupFunction<CBLDatabase_SaveDocument_C,
            CBLDatabase_SaveDocument>(
          'CBLDatabase_SaveDocument',
        ),
        saveDocumentResolving = libs.cblDart.lookupFunction<
            CBLDart_CBLDatabase_SaveDocumentResolving_C,
            CBLDart_CBLDatabase_SaveDocumentResolving>(
          'CBLDart_CBLDatabase_SaveDocumentResolving',
        ),
        purgeDocumentByID = libs.cbl.lookupFunction<
            CBLDatabase_PurgeDocumentByID_C, CBLDatabase_PurgeDocumentByID>(
          'CBLDatabase_PurgeDocumentByID',
        ),
        getDocumentExpiration = libs.cbl.lookupFunction<
            CBLDatabase_GetDocumentExpiration_C,
            CBLDatabase_GetDocumentExpiration>(
          'CBLDatabase_GetDocumentExpiration',
        ),
        setDocumentExpiration = libs.cbl.lookupFunction<
            CBLDatabase_SetDocumentExpiration_C,
            CBLDatabase_SetDocumentExpiration>(
          'CBLDatabase_SetDocumentExpiration',
        ),
        addDocumentChangeListener = libs.cblDart.lookupFunction<
            CBLDart_CBLDatabase_AddDocumentChangeListener_C,
            CBLDart_CBLDatabase_AddDocumentChangeListener>(
          'CBLDart_CBLDatabase_AddDocumentChangeListener',
        ),
        addChangeListener = libs.cblDart.lookupFunction<
            CBLDart_CBLDatabase_AddChangeListener_C,
            CBLDart_CBLDatabase_AddChangeListener>(
          'CBLDart_CBLDatabase_AddChangeListener',
        ),
        createIndex = libs.cblDart.lookupFunction<
            CBLDart_CBLDatabase_CreateIndex_C, CBLDart_CBLDatabase_CreateIndex>(
          'CBLDart_CBLDatabase_CreateIndex',
        ),
        deleteIndex = libs.cbl
            .lookupFunction<CBLDatabase_DeleteIndex_C, CBLDatabase_DeleteIndex>(
          'CBLDatabase_DeleteIndex',
        ),
        indexNames = libs.cbl
            .lookupFunction<CBLDatabase_IndexNames, CBLDatabase_IndexNames>(
          'CBLDatabase_IndexNames',
        );

  final CBLDatabase_Exists databaseExists;
  final CBL_CopyDatabase copyDatabase;
  final CBL_DeleteDatabase deleteDatabase;
  final CBLDart_Database_BindToDartObject bindToDartObject;
  final CBLDatabase_Open open;
  final CBLDatabase_Close close;
  final CBLDatabase_Delete delete;
  final CBLDatabase_Compact compact;
  final CBLDatabase_BeginBatch beginBatch;
  final CBLDatabase_EndBatch endBatch;
  final CBLDatabase_Rekey? rekey;
  final CBLDatabase_Name name;
  final CBLDatabase_Name path;
  final CBLDatabase_Count count;
  final CBLDatabase_Config config;
  final CBLDatabase_GetDocument getDocument;
  final CBLDatabase_GetMutableDocument getMutableDocument;
  final CBLDatabase_SaveDocument saveDocument;
  final CBLDart_CBLDatabase_SaveDocumentResolving saveDocumentResolving;
  final CBLDatabase_PurgeDocumentByID purgeDocumentByID;
  final CBLDatabase_GetDocumentExpiration getDocumentExpiration;
  final CBLDatabase_SetDocumentExpiration setDocumentExpiration;
  final CBLDart_CBLDatabase_AddDocumentChangeListener addDocumentChangeListener;
  final CBLDart_CBLDatabase_AddChangeListener addChangeListener;
  final CBLDart_CBLDatabase_CreateIndex createIndex;
  final CBLDatabase_DeleteIndex deleteIndex;
  final CBLDatabase_IndexNames indexNames;
}
