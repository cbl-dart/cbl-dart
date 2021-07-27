import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../cbl_ffi.dart';
import 'async_callback.dart';
import 'base.dart';
import 'bindings.dart';
import 'document.dart';
import 'fleece.dart';
import 'query.dart';
import 'utils.dart';

enum CBLConcurrencyControl {
  lastWriteWins,
  failOnConflict,
}

extension CBLConcurrencyControlExt on CBLConcurrencyControl {
  int toInt() => CBLConcurrencyControl.values.indexOf(this);
}

class CBLDatabase extends Opaque {}

class CBLDatabaseConfiguration {
  CBLDatabaseConfiguration(this.directory);

  final String directory;
}

class CBLDart_CBLDatabaseConfiguration extends Struct {
  external FLString directory;
}

typedef CBLDart_CBLDatabaseConfiguration_Default
    = CBLDart_CBLDatabaseConfiguration Function();

typedef CBLDart_CBL_CopyDatabase_C = Uint8 Function(
  FLString fromPath,
  FLString toPath,
  Pointer<CBLDart_CBLDatabaseConfiguration> config,
  Pointer<CBLError> errorOut,
);
typedef CBLDart_CBL_CopyDatabase = int Function(
  FLString fromPath,
  FLString toPath,
  Pointer<CBLDart_CBLDatabaseConfiguration> config,
  Pointer<CBLError> errorOut,
);

typedef CBLDart_CBL_DeleteDatabase_C = Uint8 Function(
  FLString name,
  FLString inDirectory,
  Pointer<CBLError> outError,
);
typedef CBLDart_CBL_DeleteDatabase = int Function(
  FLString name,
  FLString inDirectory,
  Pointer<CBLError> outError,
);

typedef CBLDart_CBLDatabase_Exists_C = Uint8 Function(
  FLString name,
  FLString inDirectory,
);
typedef CBLDart_CBLDatabase_Exists = int Function(
  FLString name,
  FLString inDirectory,
);

typedef CBLDart_CBLDatabase_Open = Pointer<CBLDatabase> Function(
  FLString name,
  Pointer<CBLDart_CBLDatabaseConfiguration> config,
  Pointer<CBLError> errorOut,
);

typedef CBLDatabase_Close_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLError> errorOut,
);
typedef CBLDatabase_Close = int Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLError> errorOut,
);

typedef CBLDatabase_Delete_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLError> errorOut,
);
typedef CBLDatabase_Delete = int Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLError> errorOut,
);

enum CBLMaintenanceType {
  compact,
  reindex,
  integrityCheck,
  optimize,
  fullOptimize
}

extension CBLMaintenanceTypeIntExt on CBLMaintenanceType {
  int toInt() => CBLMaintenanceType.values.indexOf(this);
}

typedef CBLDatabase_PerformMaintenance_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  Uint32 type,
  Pointer<CBLError> errorOut,
);
typedef CBLDatabase_PerformMaintenance = int Function(
  Pointer<CBLDatabase> db,
  int type,
  Pointer<CBLError> errorOut,
);

typedef CBLDatabase_BeginTransaction_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLError> errorOut,
);
typedef CBLDatabase_BeginTransaction = int Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLError> errorOut,
);

typedef CBLDatabase_EndTransaction_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  Uint8 commit,
  Pointer<CBLError> errorOut,
);
typedef CBLDatabase_EndTransaction = int Function(
  Pointer<CBLDatabase> db,
  int commit,
  Pointer<CBLError> errorOut,
);

typedef CBLDart_CBLDatabase_Name = FLString Function(Pointer<CBLDatabase> db);

typedef CBLDart_CBLDatabase_Path = FLStringResult Function(
  Pointer<CBLDatabase> db,
);

typedef CBLDatabase_Count_C = Uint64 Function(
  Pointer<CBLDatabase> db,
);
typedef CBLDatabase_Count = int Function(
  Pointer<CBLDatabase> db,
);

typedef CBLDart_CBLDatabase_Config = CBLDart_CBLDatabaseConfiguration Function(
  Pointer<CBLDatabase> dbm,
);

typedef CBLDart_CBLDatabase_GetDocument = Pointer<CBLDocument> Function(
  Pointer<CBLDatabase> db,
  FLString docId,
  Pointer<CBLError> errorOut,
);

typedef CBLDart_CBLDatabase_GetMutableDocument = Pointer<CBLMutableDocument>
    Function(
  Pointer<CBLDatabase> db,
  FLString docId,
  Pointer<CBLError> errorOut,
);

typedef CBLDart_CBLDatabase_SaveDocumentWithConcurrencyControl_C = Uint8
    Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLMutableDocument> doc,
  Uint8 concurrency,
  Pointer<CBLError> errorOut,
);
typedef CBLDart_CBLDatabase_SaveDocumentWithConcurrencyControl = int Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLMutableDocument> doc,
  int concurrency,
  Pointer<CBLError> errorOut,
);

typedef SaveConflictHandler_C = Uint8 Function(
  Pointer<Void> context,
  Pointer<CBLMutableDocument> documentBeingSave,
  Pointer<CBLDocument> conflictingDocument,
);
typedef SaveConflictHandlerWrapper = int Function(
  Pointer<CBLMutableDocument> documentBeingSave,
  Pointer<CBLDocument> conflictingDocument,
);
typedef CBLSaveConflictHandler = bool Function(
  Pointer<CBLMutableDocument> documentBeingSave,
  Pointer<CBLDocument>? conflictingDocument,
);

typedef CBLDatabase_SaveDocumentWithConflictHandler_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLMutableDocument> doc,
  Pointer<NativeFunction<SaveConflictHandler_C>> conflictHandler,
  Pointer<Void> context,
  Pointer<CBLError> errorOut,
);
typedef CBLDatabase_SaveDocumentWithConflictHandler = int Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLMutableDocument> doc,
  Pointer<NativeFunction<SaveConflictHandler_C>> conflictHandler,
  Pointer<Void> context,
  Pointer<CBLError> errorOut,
);

class SaveDocumentResolvingAsyncCallbackMessage {
  SaveDocumentResolvingAsyncCallbackMessage(
    this.documentBeingSaved,
    this.conflictingDocument,
  );

  SaveDocumentResolvingAsyncCallbackMessage.fromArguments(List<dynamic> message)
      : this(
          (message[0] as int).toPointer<CBLMutableDocument>(),
          (message[1] as int?)?.toPointer<CBLDocument>(),
        );

  final Pointer<CBLMutableDocument> documentBeingSaved;
  final Pointer<CBLDocument>? conflictingDocument;
}

typedef CBLDart_CBLDatabase_SaveDocumentWithConflictHandlerAsync_C = Uint8
    Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLMutableDocument> doc,
  Pointer<CBLDartAsyncCallback> conflictHandler,
  Pointer<CBLError> errorOut,
);
typedef CBLDart_CBLDatabase_SaveDocumentWithConflictHandlerAsync = int Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLMutableDocument> doc,
  Pointer<CBLDartAsyncCallback> conflictHandler,
  Pointer<CBLError> errorOut,
);

typedef CBLDatabase_DeleteDocumentWithConcurrencyControl_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLDocument> document,
  Uint8 concurrency,
  Pointer<CBLError> errorOut,
);
typedef CBLDatabase_DeleteDocumentWithConcurrencyControl = int Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLDocument> document,
  int concurrency,
  Pointer<CBLError> errorOut,
);

typedef CBLDart_CBLDatabase_PurgeDocumentByID_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  FLString docId,
  Pointer<CBLError> errorOut,
);
typedef CBLDart_CBLDatabase_PurgeDocumentByID = int Function(
  Pointer<CBLDatabase> db,
  FLString docId,
  Pointer<CBLError> errorOut,
);

typedef CBLDart_CBLDatabase_GetDocumentExpiration_C = Int64 Function(
  Pointer<CBLDatabase> db,
  FLString docId,
  Pointer<CBLError> errorOut,
);
typedef CBLDart_CBLDatabase_GetDocumentExpiration = int Function(
  Pointer<CBLDatabase> db,
  FLString docId,
  Pointer<CBLError> errorOut,
);

typedef CBLDart_CBLDatabase_SetDocumentExpiration_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  FLString docId,
  Int64 expiration,
  Pointer<CBLError> errorOut,
);
typedef CBLDart_CBLDatabase_SetDocumentExpiration = int Function(
  Pointer<CBLDatabase> db,
  FLString docId,
  int expiration,
  Pointer<CBLError> errorOut,
);

typedef CBLDart_CBLDatabase_AddDocumentChangeListener_C = Void Function(
  Pointer<CBLDatabase> db,
  FLString docId,
  Pointer<CBLDartAsyncCallback> listener,
);
typedef CBLDart_CBLDatabase_AddDocumentChangeListener = void Function(
  Pointer<CBLDatabase> db,
  FLString docId,
  Pointer<CBLDartAsyncCallback> listener,
);

typedef CBLDart_CBLDatabase_AddChangeListener_C = Void Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLDartAsyncCallback> listener,
);
typedef CBLDart_CBLDatabase_AddChangeListener = void Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLDartAsyncCallback> listener,
);

class DatabaseChangeCallbackMessage {
  DatabaseChangeCallbackMessage(this.documentIds);

  DatabaseChangeCallbackMessage.fromArguments(List<dynamic> message)
      : this(message.cast<Uint8List>().map(utf8.decode).toList());

  final List<String> documentIds;
}

enum CBLdart_IndexType {
  value,
  fullText,
}

extension on CBLdart_IndexType {
  int toInt() => CBLdart_IndexType.values.indexOf(this);
}

extension on int {
  CBLdart_IndexType toIndexType() => CBLdart_IndexType.values[this];
}

class CBLDart_CBLIndexSpec extends Struct {
  @Uint8()
  external int _type;

  @Uint32()
  // ignore: unused_field
  external int _expressionLanguage;

  external FLString expressions;

  @Uint8()
  // ignore: unused_field
  external int _ignoreAccents;

  external FLString language;
}

// ignore: camel_case_extensions
extension CBLDart_CBLIndexSpecExt on CBLDart_CBLIndexSpec {
  CBLdart_IndexType get type => _type.toIndexType();
  set type(CBLdart_IndexType value) => _type = value.toInt();
  set expressionLanguage(CBLQueryLanguage value) =>
      _expressionLanguage = value.toInt();
  set ignoreAccents(bool value) => _ignoreAccents = value.toInt();
}

typedef CBLDart_CBLDatabase_CreateIndex_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  FLString name,
  CBLDart_CBLIndexSpec indexSpec,
  Pointer<CBLError> errorOut,
);
typedef CBLDart_CBLDatabase_CreateIndex = int Function(
  Pointer<CBLDatabase> db,
  FLString name,
  CBLDart_CBLIndexSpec indexSpec,
  Pointer<CBLError> errorOut,
);

typedef CBLDart_CBLDatabase_DeleteIndex_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  FLString name,
  Pointer<CBLError> errorOut,
);
typedef CBLDart_CBLDatabase_DeleteIndex = int Function(
  Pointer<CBLDatabase> db,
  FLString name,
  Pointer<CBLError> errorOut,
);

typedef CBLDatabase_GetIndexNames = Pointer<FLArray> Function(
  Pointer<CBLDatabase> db,
);

class DatabaseBindings extends Bindings {
  DatabaseBindings(Bindings parent) : super(parent) {
    _copyDatabase = libs.cblDart
        .lookupFunction<CBLDart_CBL_CopyDatabase_C, CBLDart_CBL_CopyDatabase>(
      'CBLDart_CBL_CopyDatabase',
    );
    _deleteDatabase = libs.cblDart.lookupFunction<CBLDart_CBL_DeleteDatabase_C,
        CBLDart_CBL_DeleteDatabase>(
      'CBLDart_CBL_DeleteDatabase',
    );
    _databaseExists = libs.cblDart.lookupFunction<CBLDart_CBLDatabase_Exists_C,
        CBLDart_CBLDatabase_Exists>(
      'CBLDart_CBL_DatabaseExists',
    );
    _defaultConfiguration = libs.cblDart.lookupFunction<
        CBLDart_CBLDatabaseConfiguration_Default,
        CBLDart_CBLDatabaseConfiguration_Default>(
      'CBLDart_CBLDatabaseConfiguration_Default',
    );
    _open = libs.cblDart
        .lookupFunction<CBLDart_CBLDatabase_Open, CBLDart_CBLDatabase_Open>(
      'CBLDart_CBLDatabase_Open',
    );
    _close = libs.cbl.lookupFunction<CBLDatabase_Close_C, CBLDatabase_Close>(
      'CBLDatabase_Close',
    );
    _delete = libs.cbl.lookupFunction<CBLDatabase_Delete_C, CBLDatabase_Delete>(
      'CBLDatabase_Delete',
    );
    _performMaintenance = libs.cbl.lookupFunction<
        CBLDatabase_PerformMaintenance_C, CBLDatabase_PerformMaintenance>(
      'CBLDatabase_PerformMaintenance',
    );
    _beginTransaction = libs.cbl.lookupFunction<CBLDatabase_BeginTransaction_C,
        CBLDatabase_BeginTransaction>(
      'CBLDatabase_BeginTransaction',
    );
    _endTransaction = libs.cbl.lookupFunction<CBLDatabase_EndTransaction_C,
        CBLDatabase_EndTransaction>(
      'CBLDatabase_EndTransaction',
    );
    _name = libs.cblDart
        .lookupFunction<CBLDart_CBLDatabase_Name, CBLDart_CBLDatabase_Name>(
      'CBLDart_CBLDatabase_Name',
    );
    _path = libs.cblDart
        .lookupFunction<CBLDart_CBLDatabase_Path, CBLDart_CBLDatabase_Path>(
      'CBLDart_CBLDatabase_Path',
    );
    _count = libs.cbl.lookupFunction<CBLDatabase_Count_C, CBLDatabase_Count>(
      'CBLDatabase_Count',
    );
    _config = libs.cblDart
        .lookupFunction<CBLDart_CBLDatabase_Config, CBLDart_CBLDatabase_Config>(
      'CBLDart_CBLDatabase_Config',
    );
    _getDocument = libs.cblDart.lookupFunction<CBLDart_CBLDatabase_GetDocument,
        CBLDart_CBLDatabase_GetDocument>(
      'CBLDart_CBLDatabase_GetDocument',
    );
    _getMutableDocument = libs.cblDart.lookupFunction<
        CBLDart_CBLDatabase_GetMutableDocument,
        CBLDart_CBLDatabase_GetMutableDocument>(
      'CBLDart_CBLDatabase_GetMutableDocument',
    );
    _saveDocumentWithConcurrencyControl = libs.cblDart.lookupFunction<
        CBLDart_CBLDatabase_SaveDocumentWithConcurrencyControl_C,
        CBLDart_CBLDatabase_SaveDocumentWithConcurrencyControl>(
      'CBLDart_CBLDatabase_SaveDocumentWithConcurrencyControl',
    );
    _saveConflictHandler = Pointer.fromFunction<SaveConflictHandler_C>(
      _staticSaveConflictHandler,
      // The function should throw because it catches all exceptions of the dart
      // conflict handler.
      // Passing `0` here (representing `false`) is a fail save to abort the
      // save operation in case there is a bug in the bindings layer.
      0,
    );
    _saveDocumentWithConflictHandler = libs.cbl.lookupFunction<
        CBLDatabase_SaveDocumentWithConflictHandler_C,
        CBLDatabase_SaveDocumentWithConflictHandler>(
      'CBLDatabase_SaveDocumentWithConflictHandler',
    );
    _saveDocumentWithConflictHandlerAsync = libs.cblDart.lookupFunction<
        CBLDart_CBLDatabase_SaveDocumentWithConflictHandlerAsync_C,
        CBLDart_CBLDatabase_SaveDocumentWithConflictHandlerAsync>(
      'CBLDart_CBLDatabase_SaveDocumentWithConflictHandlerAsync',
    );
    _deleteDocumentWithConcurrencyControl = libs.cbl.lookupFunction<
        CBLDatabase_DeleteDocumentWithConcurrencyControl_C,
        CBLDatabase_DeleteDocumentWithConcurrencyControl>(
      'CBLDatabase_DeleteDocumentWithConcurrencyControl',
    );
    _purgeDocumentByID = libs.cblDart.lookupFunction<
        CBLDart_CBLDatabase_PurgeDocumentByID_C,
        CBLDart_CBLDatabase_PurgeDocumentByID>(
      'CBLDart_CBLDatabase_PurgeDocumentByID',
    );
    _getDocumentExpiration = libs.cblDart.lookupFunction<
        CBLDart_CBLDatabase_GetDocumentExpiration_C,
        CBLDart_CBLDatabase_GetDocumentExpiration>(
      'CBLDart_CBLDatabase_GetDocumentExpiration',
    );
    _setDocumentExpiration = libs.cblDart.lookupFunction<
        CBLDart_CBLDatabase_SetDocumentExpiration_C,
        CBLDart_CBLDatabase_SetDocumentExpiration>(
      'CBLDart_CBLDatabase_SetDocumentExpiration',
    );
    _addDocumentChangeListener = libs.cblDart.lookupFunction<
        CBLDart_CBLDatabase_AddDocumentChangeListener_C,
        CBLDart_CBLDatabase_AddDocumentChangeListener>(
      'CBLDart_CBLDatabase_AddDocumentChangeListener',
    );
    _addChangeListener = libs.cblDart.lookupFunction<
        CBLDart_CBLDatabase_AddChangeListener_C,
        CBLDart_CBLDatabase_AddChangeListener>(
      'CBLDart_CBLDatabase_AddChangeListener',
    );
    _createIndex = libs.cblDart.lookupFunction<
        CBLDart_CBLDatabase_CreateIndex_C, CBLDart_CBLDatabase_CreateIndex>(
      'CBLDart_CBLDatabase_CreateIndex',
    );
    _deleteIndex = libs.cblDart.lookupFunction<
        CBLDart_CBLDatabase_DeleteIndex_C, CBLDart_CBLDatabase_DeleteIndex>(
      'CBLDart_CBLDatabase_DeleteIndex',
    );
    _indexNames = libs.cbl
        .lookupFunction<CBLDatabase_GetIndexNames, CBLDatabase_GetIndexNames>(
      'CBLDatabase_GetIndexNames',
    );
  }

  /// The conflict handler which will be set by
  /// [saveDocumentWithConflictHandler] before making the call to the CBL API
  /// and cleared when that call finishes.
  static SaveConflictHandlerWrapper? _currentSaveConflictHandler;

  /// Static invoker of [_currentSaveConflictHandler].
  ///
  /// This is necessary because only static functions can be passed as C
  /// function pointers to native APIs.
  static int _staticSaveConflictHandler(
    Pointer<Void> context,
    Pointer<CBLMutableDocument> documentBeingSaved,
    Pointer<CBLDocument> conflictingDocument,
  ) {
    assert(_currentSaveConflictHandler != null);
    return _currentSaveConflictHandler!(
      documentBeingSaved,
      conflictingDocument,
    );
  }

  late final CBLDart_CBL_CopyDatabase _copyDatabase;
  late final CBLDart_CBL_DeleteDatabase _deleteDatabase;
  late final CBLDart_CBLDatabase_Exists _databaseExists;
  late final CBLDart_CBLDatabaseConfiguration_Default _defaultConfiguration;
  late final CBLDart_CBLDatabase_Open _open;
  late final CBLDatabase_Close _close;
  late final CBLDatabase_Delete _delete;
  late final CBLDatabase_PerformMaintenance _performMaintenance;
  late final CBLDatabase_BeginTransaction _beginTransaction;
  late final CBLDatabase_EndTransaction _endTransaction;
  late final CBLDart_CBLDatabase_Name _name;
  late final CBLDart_CBLDatabase_Path _path;
  late final CBLDatabase_Count _count;
  late final CBLDart_CBLDatabase_Config _config;
  late final CBLDart_CBLDatabase_GetDocument _getDocument;
  late final CBLDart_CBLDatabase_GetMutableDocument _getMutableDocument;
  late final CBLDart_CBLDatabase_SaveDocumentWithConcurrencyControl
      _saveDocumentWithConcurrencyControl;
  late final Pointer<NativeFunction<SaveConflictHandler_C>>
      _saveConflictHandler;
  late final CBLDatabase_SaveDocumentWithConflictHandler
      _saveDocumentWithConflictHandler;
  late final CBLDart_CBLDatabase_SaveDocumentWithConflictHandlerAsync
      _saveDocumentWithConflictHandlerAsync;
  late final CBLDatabase_DeleteDocumentWithConcurrencyControl
      _deleteDocumentWithConcurrencyControl;
  late final CBLDart_CBLDatabase_PurgeDocumentByID _purgeDocumentByID;
  late final CBLDart_CBLDatabase_GetDocumentExpiration _getDocumentExpiration;
  late final CBLDart_CBLDatabase_SetDocumentExpiration _setDocumentExpiration;
  late final CBLDart_CBLDatabase_AddDocumentChangeListener
      _addDocumentChangeListener;
  late final CBLDart_CBLDatabase_AddChangeListener _addChangeListener;
  late final CBLDart_CBLDatabase_CreateIndex _createIndex;
  late final CBLDart_CBLDatabase_DeleteIndex _deleteIndex;
  late final CBLDatabase_GetIndexNames _indexNames;

  bool copyDatabase(
    String from,
    String name,
    CBLDatabaseConfiguration? configuration,
  ) {
    return withZoneArena(() {
      return stringTable.autoFree(() {
        return _copyDatabase(
          stringTable.flString(from).ref,
          stringTable.flString(name).ref,
          _createConfig(configuration),
          globalCBLError,
        ).checkCBLError().toBool();
      });
    });
  }

  bool deleteDatabase(String name, String? inDirectory) {
    return stringTable.autoFree(() {
      return _deleteDatabase(
        stringTable.flString(name).ref,
        stringTable.flString(inDirectory).ref,
        globalCBLError,
      ).checkCBLError().toBool();
    });
  }

  bool databaseExists(String name, String? inDirectory) {
    return stringTable.autoFree(() {
      return _databaseExists(
        stringTable.flString(name).ref,
        stringTable.flString(inDirectory).ref,
      ).toBool();
    });
  }

  CBLDatabaseConfiguration defaultConfiguration() {
    final config = _defaultConfiguration();
    String directory;
    if (Platform.isAndroid) {
      // TODO: useful database directory default for Android
      // The default for the database directory on Android is broken.
      // Android does not support allocating memory for the string returned from
      // `getcwd`. Aside from that the current working directory is not
      // something that Android apps usually use.
      directory = Directory.current.path;
    } else {
      directory = config.directory.toDartString()!;
    }
    return CBLDatabaseConfiguration(directory);
  }

  Pointer<CBLDatabase> open(
    String name,
    CBLDatabaseConfiguration? configuration,
  ) {
    return withZoneArena(() {
      return stringTable.autoFree(() {
        return _open(
          stringTable.flString(name).ref,
          _createConfig(configuration),
          globalCBLError,
        ).checkCBLError();
      });
    });
  }

  void close(Pointer<CBLDatabase> db) {
    _close(db, globalCBLError).checkCBLError();
  }

  void delete(Pointer<CBLDatabase> db) {
    _delete(db, globalCBLError).checkCBLError();
  }

  void performMaintenance(Pointer<CBLDatabase> db, CBLMaintenanceType type) {
    _performMaintenance(db, type.toInt(), globalCBLError).checkCBLError();
  }

  void beginTransaction(Pointer<CBLDatabase> db) {
    _beginTransaction(db, globalCBLError).checkCBLError();
  }

  void endTransaction(Pointer<CBLDatabase> db, bool commit) {
    _endTransaction(db, commit.toInt(), globalCBLError).checkCBLError();
  }

  String name(Pointer<CBLDatabase> db) {
    return _name(db).toDartString()!;
  }

  String path(Pointer<CBLDatabase> db) {
    return _path(db).toDartStringAndRelease()!;
  }

  int count(Pointer<CBLDatabase> db) {
    return _count(db);
  }

  CBLDart_CBLDatabaseConfiguration config(Pointer<CBLDatabase> db) {
    return _config(db);
  }

  Pointer<CBLDocument>? getDocument(
    Pointer<CBLDatabase> db,
    String docId,
  ) {
    return stringTable.autoFree(() {
      return _getDocument(db, stringTable.flString(docId).ref, globalCBLError)
          .checkCBLError()
          .toNullable();
    });
  }

  Pointer<CBLMutableDocument>? getMutableDocument(
    Pointer<CBLDatabase> db,
    String docId,
  ) {
    return stringTable.autoFree(() {
      return _getMutableDocument(
        db,
        stringTable.flString(docId).ref,
        globalCBLError,
      ).checkCBLError().toNullable();
    });
  }

  void saveDocumentWithConcurrencyControl(
    Pointer<CBLDatabase> db,
    Pointer<CBLMutableDocument> doc,
    CBLConcurrencyControl concurrencyControl,
  ) {
    _saveDocumentWithConcurrencyControl(
      db,
      doc,
      concurrencyControl.toInt(),
      globalCBLError,
    ).checkCBLError();
  }

  void saveDocumentWithConflictHandler(
    Pointer<CBLDatabase> db,
    Pointer<CBLMutableDocument> doc,
    CBLSaveConflictHandler conflictHandler,
  ) {
    final zone = Zone.current;
    conflictHandler = zone.registerBinaryCallback(conflictHandler);
    _currentSaveConflictHandler = (documentBeingSaved, conflictingDocument) {
      var resolvedConflict = false;
      zone.runGuarded(() {
        resolvedConflict = conflictHandler(
          documentBeingSaved,
          conflictingDocument.toNullable(),
        );
      });
      return resolvedConflict.toInt();
    };

    try {
      _saveDocumentWithConflictHandler(
        db,
        doc,
        _saveConflictHandler,
        nullptr,
        globalCBLError,
      ).checkCBLError();
    } finally {
      _currentSaveConflictHandler = null;
    }
  }

  void saveDocumentWithConflictHandlerAsync(
    Pointer<CBLDatabase> db,
    Pointer<CBLMutableDocument> doc,
    Pointer<CBLDartAsyncCallback> conflictHandler,
  ) {
    _saveDocumentWithConflictHandlerAsync(
      db,
      doc,
      conflictHandler,
      globalCBLError,
    ).checkCBLError();
  }

  bool deleteDocumentWithConcurrencyControl(
    Pointer<CBLDatabase> db,
    Pointer<CBLDocument> document,
    CBLConcurrencyControl concurrency,
  ) {
    return _deleteDocumentWithConcurrencyControl(
      db,
      document,
      concurrency.toInt(),
      globalCBLError,
    ).checkCBLError().toBool();
  }

  bool purgeDocumentByID(Pointer<CBLDatabase> db, String docId) {
    return stringTable.autoFree(() {
      return _purgeDocumentByID(
        db,
        stringTable.flString(docId).ref,
        globalCBLError,
      ).checkCBLError().toBool();
    });
  }

  DateTime? getDocumentExpiration(Pointer<CBLDatabase> db, String docId) {
    return stringTable.autoFree(() {
      final result = _getDocumentExpiration(
        db,
        stringTable.flString(docId).ref,
        globalCBLError,
      );

      if (result == -1) {
        checkCBLError();
      }

      return result == 0 ? null : DateTime.fromMillisecondsSinceEpoch(result);
    });
  }

  void setDocumentExpiration(
    Pointer<CBLDatabase> db,
    String docId,
    DateTime? expiration,
  ) {
    return stringTable.autoFree(() {
      _setDocumentExpiration(
        db,
        stringTable.flString(docId).ref,
        expiration?.millisecondsSinceEpoch ?? 0,
        globalCBLError,
      ).checkCBLError();
    });
  }

  void addDocumentChangeListener(
    Pointer<CBLDatabase> db,
    String docId,
    Pointer<CBLDartAsyncCallback> listener,
  ) {
    stringTable.autoFree(() {
      _addDocumentChangeListener(db, stringTable.flString(docId).ref, listener);
    });
  }

  void addChangeListener(
    Pointer<CBLDatabase> db,
    Pointer<CBLDartAsyncCallback> listener,
  ) {
    _addChangeListener(db, listener);
  }

  void createIndex(
    Pointer<CBLDatabase> db,
    String name,
    CBLdart_IndexType type,
    CBLQueryLanguage expressionLanguage,
    String expressions,
    bool? ignoreAccents,
    String? language,
  ) {
    withZoneArena(() {
      stringTable.autoFree(() {
        _createIndex(
          db,
          stringTable.flString(name).ref,
          _createIndexSpec(
            type,
            expressionLanguage,
            expressions,
            ignoreAccents,
            language,
          ).ref,
          globalCBLError,
        ).checkCBLError();
      });
    });
  }

  void deleteIndex(Pointer<CBLDatabase> db, String name) {
    stringTable.autoFree(() {
      _deleteIndex(
        db,
        stringTable.flString(name).ref,
        globalCBLError,
      ).checkCBLError();
    });
  }

  Pointer<FLArray> indexNames(Pointer<CBLDatabase> db) {
    return _indexNames(db);
  }

  Pointer<CBLDart_CBLDatabaseConfiguration> _createConfig(
    CBLDatabaseConfiguration? config,
  ) {
    if (config == null) {
      return nullptr;
    }

    final result = zoneArena<CBLDart_CBLDatabaseConfiguration>();

    result.ref.directory =
        stringTable.flString(config.directory, arena: true).ref;

    return result;
  }

  Pointer<CBLDart_CBLIndexSpec> _createIndexSpec(
    CBLdart_IndexType type,
    CBLQueryLanguage expressionLanguage,
    String expressions,
    bool? ignoreAccents,
    String? language,
  ) {
    final result = zoneArena<CBLDart_CBLIndexSpec>();

    result.ref
      ..type = type
      ..expressionLanguage = expressionLanguage
      ..expressions = stringTable.flString(expressions, arena: true).ref
      ..ignoreAccents = ignoreAccents ?? false
      ..language = stringTable.flString(language, arena: true).ref;

    return result;
  }
}
