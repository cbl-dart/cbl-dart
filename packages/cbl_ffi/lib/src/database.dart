import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../cbl_ffi.dart';
import 'async_callback.dart';
import 'base.dart';
import 'bindings.dart';
import 'document.dart';
import 'fleece.dart';
import 'global.dart';
import 'query.dart';
import 'utils.dart';

enum CBLConcurrencyControl {
  lastWriteWins,
  failOnConflict,
}

extension on CBLConcurrencyControl {
  int toInt() => CBLConcurrencyControl.values.indexOf(this);
}

class CBLDatabase extends Opaque {}

class CBLDatabaseConfiguration {
  CBLDatabaseConfiguration({required this.directory});

  final String directory;
}

class _CBLDart_CBLDatabaseConfiguration extends Struct {
  // Workaround for a likely bug in Dart's FFI implementation. Without this
  // padding at the start of the struct the `buf` pointer in `directory`
  // points to a random location.
  //
  // When the bug is fixed and the padding can be removed, also remove it on
  // the native side.
  @Uint32()
  external int padding;
  external FLString directory;
}

typedef _CBLDart_CBLDatabaseConfiguration_Default
    = _CBLDart_CBLDatabaseConfiguration Function();

typedef _CBLDart_CBL_CopyDatabase_C = Uint8 Function(
  FLString fromPath,
  FLString toPath,
  Pointer<_CBLDart_CBLDatabaseConfiguration> config,
  Pointer<CBLError> errorOut,
);
typedef _CBLDart_CBL_CopyDatabase = int Function(
  FLString fromPath,
  FLString toPath,
  Pointer<_CBLDart_CBLDatabaseConfiguration> config,
  Pointer<CBLError> errorOut,
);

typedef _CBLDart_CBL_DeleteDatabase_C = Uint8 Function(
  FLString name,
  FLString inDirectory,
  Pointer<CBLError> outError,
);
typedef _CBLDart_CBL_DeleteDatabase = int Function(
  FLString name,
  FLString inDirectory,
  Pointer<CBLError> outError,
);

typedef _CBLDart_CBLDatabase_Exists_C = Uint8 Function(
  FLString name,
  FLString inDirectory,
);
typedef _CBLDart_CBLDatabase_Exists = int Function(
  FLString name,
  FLString inDirectory,
);

typedef _CBLDart_CBLDatabase_Open = Pointer<CBLDatabase> Function(
  FLString name,
  Pointer<_CBLDart_CBLDatabaseConfiguration> config,
  Pointer<CBLError> errorOut,
);

typedef _CBLDart_BindDatabaseToDartObject_C = Void Function(
  Handle object,
  Pointer<CBLDatabase> db,
  Pointer<Utf8> debugName,
);
typedef _CBLDart_BindDatabaseToDartObject = void Function(
  Object object,
  Pointer<CBLDatabase> db,
  Pointer<Utf8> debugName,
);

typedef _CBLDart_CBLDatabase_Close_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  Uint8 andDelete,
  Pointer<CBLError> errorOut,
);
typedef _CBLDart_CBLDatabase_Close = int Function(
  Pointer<CBLDatabase> db,
  int andDelete,
  Pointer<CBLError> errorOut,
);

enum CBLMaintenanceType {
  compact,
  reindex,
  integrityCheck,
  optimize,
  fullOptimize
}

extension on CBLMaintenanceType {
  int toInt() => CBLMaintenanceType.values.indexOf(this);
}

typedef _CBLDatabase_PerformMaintenance_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  Uint32 type,
  Pointer<CBLError> errorOut,
);
typedef _CBLDatabase_PerformMaintenance = int Function(
  Pointer<CBLDatabase> db,
  int type,
  Pointer<CBLError> errorOut,
);

typedef _CBLDatabase_BeginTransaction_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLError> errorOut,
);
typedef _CBLDatabase_BeginTransaction = int Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLError> errorOut,
);

typedef _CBLDatabase_EndTransaction_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  Uint8 commit,
  Pointer<CBLError> errorOut,
);
typedef _CBLDatabase_EndTransaction = int Function(
  Pointer<CBLDatabase> db,
  int commit,
  Pointer<CBLError> errorOut,
);

typedef _CBLDart_CBLDatabase_Name = FLString Function(Pointer<CBLDatabase> db);

typedef _CBLDart_CBLDatabase_Path = FLStringResult Function(
  Pointer<CBLDatabase> db,
);

typedef _CBLDatabase_Count_C = Uint64 Function(
  Pointer<CBLDatabase> db,
);
typedef _CBLDatabase_Count = int Function(
  Pointer<CBLDatabase> db,
);

typedef _CBLDart_CBLDatabase_GetDocument = Pointer<CBLDocument> Function(
  Pointer<CBLDatabase> db,
  FLString docId,
  Pointer<CBLError> errorOut,
);

typedef _CBLDart_CBLDatabase_GetMutableDocument = Pointer<CBLMutableDocument>
    Function(
  Pointer<CBLDatabase> db,
  FLString docId,
  Pointer<CBLError> errorOut,
);

typedef _CBLDart_CBLDatabase_SaveDocumentWithConcurrencyControl_C = Uint8
    Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLMutableDocument> doc,
  Uint8 concurrency,
  Pointer<CBLError> errorOut,
);
typedef _CBLDart_CBLDatabase_SaveDocumentWithConcurrencyControl = int Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLMutableDocument> doc,
  int concurrency,
  Pointer<CBLError> errorOut,
);

typedef _CBLDatabase_DeleteDocumentWithConcurrencyControl_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLDocument> document,
  Uint8 concurrency,
  Pointer<CBLError> errorOut,
);
typedef _CBLDatabase_DeleteDocumentWithConcurrencyControl = int Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLDocument> document,
  int concurrency,
  Pointer<CBLError> errorOut,
);

typedef _CBLDart_CBLDatabase_PurgeDocumentByID_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  FLString docId,
  Pointer<CBLError> errorOut,
);
typedef _CBLDart_CBLDatabase_PurgeDocumentByID = int Function(
  Pointer<CBLDatabase> db,
  FLString docId,
  Pointer<CBLError> errorOut,
);

typedef _CBLDart_CBLDatabase_GetDocumentExpiration_C = Int64 Function(
  Pointer<CBLDatabase> db,
  FLString docId,
  Pointer<CBLError> errorOut,
);
typedef _CBLDart_CBLDatabase_GetDocumentExpiration = int Function(
  Pointer<CBLDatabase> db,
  FLString docId,
  Pointer<CBLError> errorOut,
);

typedef _CBLDart_CBLDatabase_SetDocumentExpiration_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  FLString docId,
  Int64 expiration,
  Pointer<CBLError> errorOut,
);
typedef _CBLDart_CBLDatabase_SetDocumentExpiration = int Function(
  Pointer<CBLDatabase> db,
  FLString docId,
  int expiration,
  Pointer<CBLError> errorOut,
);

typedef _CBLDart_CBLDatabase_AddDocumentChangeListener_C = Void Function(
  Pointer<CBLDatabase> db,
  FLString docId,
  Pointer<CBLDartAsyncCallback> listener,
);
typedef _CBLDart_CBLDatabase_AddDocumentChangeListener = void Function(
  Pointer<CBLDatabase> db,
  FLString docId,
  Pointer<CBLDartAsyncCallback> listener,
);

typedef _CBLDart_CBLDatabase_AddChangeListener_C = Void Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLDartAsyncCallback> listener,
);
typedef _CBLDart_CBLDatabase_AddChangeListener = void Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLDartAsyncCallback> listener,
);

class DatabaseChangeCallbackMessage {
  DatabaseChangeCallbackMessage(this.documentIds);

  DatabaseChangeCallbackMessage.fromArguments(List<Object?> message)
      : this(message.cast<Uint8List>().map(utf8.decode).toList());

  final List<String> documentIds;
}

class CBLIndexSpec {
  CBLIndexSpec({
    required this.type,
    required this.expressionLanguage,
    required this.expressions,
    this.ignoreAccents,
    this.language,
  });

  final CBLIndexType type;
  final CBLQueryLanguage expressionLanguage;
  final String expressions;
  final bool? ignoreAccents;
  final String? language;
}

enum CBLIndexType {
  value,
  fullText,
}

extension on CBLIndexType {
  int toInt() => CBLIndexType.values.indexOf(this);
}

class _CBLDart_CBLIndexSpec extends Struct {
  @Uint8()
  // ignore: unused_field
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
extension on _CBLDart_CBLIndexSpec {
  set type(CBLIndexType value) => _type = value.toInt();
  set expressionLanguage(CBLQueryLanguage value) =>
      _expressionLanguage = value.toInt();
  set ignoreAccents(bool value) => _ignoreAccents = value.toInt();
}

typedef _CBLDart_CBLDatabase_CreateIndex_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  FLString name,
  _CBLDart_CBLIndexSpec indexSpec,
  Pointer<CBLError> errorOut,
);
typedef _CBLDart_CBLDatabase_CreateIndex = int Function(
  Pointer<CBLDatabase> db,
  FLString name,
  _CBLDart_CBLIndexSpec indexSpec,
  Pointer<CBLError> errorOut,
);

typedef _CBLDart_CBLDatabase_DeleteIndex_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  FLString name,
  Pointer<CBLError> errorOut,
);
typedef _CBLDart_CBLDatabase_DeleteIndex = int Function(
  Pointer<CBLDatabase> db,
  FLString name,
  Pointer<CBLError> errorOut,
);

typedef _CBLDatabase_GetIndexNames = Pointer<FLArray> Function(
  Pointer<CBLDatabase> db,
);

typedef _CBLDatabase_GetBlob = Pointer<CBLBlob> Function(
  Pointer<CBLDatabase> db,
  Pointer<FLDict> properties,
  Pointer<CBLError> errorOut,
);

typedef _CBLDatabase_SaveBlob_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLBlob> blob,
  Pointer<CBLError> errorOut,
);
typedef _CBLDatabase_SaveBlob = int Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLBlob> blob,
  Pointer<CBLError> errorOut,
);

class DatabaseBindings extends Bindings {
  DatabaseBindings(Bindings parent) : super(parent) {
    _copyDatabase = libs.cblDart
        .lookupFunction<_CBLDart_CBL_CopyDatabase_C, _CBLDart_CBL_CopyDatabase>(
      'CBLDart_CBL_CopyDatabase',
    );
    _deleteDatabase = libs.cblDart.lookupFunction<_CBLDart_CBL_DeleteDatabase_C,
        _CBLDart_CBL_DeleteDatabase>(
      'CBLDart_CBL_DeleteDatabase',
    );
    _databaseExists = libs.cblDart.lookupFunction<_CBLDart_CBLDatabase_Exists_C,
        _CBLDart_CBLDatabase_Exists>(
      'CBLDart_CBL_DatabaseExists',
    );
    _defaultConfiguration = libs.cblDart.lookupFunction<
        _CBLDart_CBLDatabaseConfiguration_Default,
        _CBLDart_CBLDatabaseConfiguration_Default>(
      'CBLDart_CBLDatabaseConfiguration_Default',
    );
    _open = libs.cblDart
        .lookupFunction<_CBLDart_CBLDatabase_Open, _CBLDart_CBLDatabase_Open>(
      'CBLDart_CBLDatabase_Open',
    );
    _bindtoDartObject = libs.cblDart.lookupFunction<
        _CBLDart_BindDatabaseToDartObject_C, _CBLDart_BindDatabaseToDartObject>(
      'CBLDart_BindDatabaseToDartObject',
    );
    _close = libs.cblDart.lookupFunction<_CBLDart_CBLDatabase_Close_C,
        _CBLDart_CBLDatabase_Close>(
      'CBLDart_CBLDatabase_Close',
    );
    _performMaintenance = libs.cbl.lookupFunction<
        _CBLDatabase_PerformMaintenance_C, _CBLDatabase_PerformMaintenance>(
      'CBLDatabase_PerformMaintenance',
    );
    _beginTransaction = libs.cbl.lookupFunction<_CBLDatabase_BeginTransaction_C,
        _CBLDatabase_BeginTransaction>(
      'CBLDatabase_BeginTransaction',
    );
    _endTransaction = libs.cbl.lookupFunction<_CBLDatabase_EndTransaction_C,
        _CBLDatabase_EndTransaction>(
      'CBLDatabase_EndTransaction',
    );
    _name = libs.cblDart
        .lookupFunction<_CBLDart_CBLDatabase_Name, _CBLDart_CBLDatabase_Name>(
      'CBLDart_CBLDatabase_Name',
    );
    _path = libs.cblDart
        .lookupFunction<_CBLDart_CBLDatabase_Path, _CBLDart_CBLDatabase_Path>(
      'CBLDart_CBLDatabase_Path',
    );
    _count = libs.cbl.lookupFunction<_CBLDatabase_Count_C, _CBLDatabase_Count>(
      'CBLDatabase_Count',
    );
    _getDocument = libs.cblDart.lookupFunction<_CBLDart_CBLDatabase_GetDocument,
        _CBLDart_CBLDatabase_GetDocument>(
      'CBLDart_CBLDatabase_GetDocument',
    );
    _getMutableDocument = libs.cblDart.lookupFunction<
        _CBLDart_CBLDatabase_GetMutableDocument,
        _CBLDart_CBLDatabase_GetMutableDocument>(
      'CBLDart_CBLDatabase_GetMutableDocument',
    );
    _saveDocumentWithConcurrencyControl = libs.cblDart.lookupFunction<
        _CBLDart_CBLDatabase_SaveDocumentWithConcurrencyControl_C,
        _CBLDart_CBLDatabase_SaveDocumentWithConcurrencyControl>(
      'CBLDart_CBLDatabase_SaveDocumentWithConcurrencyControl',
    );
    _deleteDocumentWithConcurrencyControl = libs.cbl.lookupFunction<
        _CBLDatabase_DeleteDocumentWithConcurrencyControl_C,
        _CBLDatabase_DeleteDocumentWithConcurrencyControl>(
      'CBLDatabase_DeleteDocumentWithConcurrencyControl',
    );
    _purgeDocumentByID = libs.cblDart.lookupFunction<
        _CBLDart_CBLDatabase_PurgeDocumentByID_C,
        _CBLDart_CBLDatabase_PurgeDocumentByID>(
      'CBLDart_CBLDatabase_PurgeDocumentByID',
    );
    _getDocumentExpiration = libs.cblDart.lookupFunction<
        _CBLDart_CBLDatabase_GetDocumentExpiration_C,
        _CBLDart_CBLDatabase_GetDocumentExpiration>(
      'CBLDart_CBLDatabase_GetDocumentExpiration',
    );
    _setDocumentExpiration = libs.cblDart.lookupFunction<
        _CBLDart_CBLDatabase_SetDocumentExpiration_C,
        _CBLDart_CBLDatabase_SetDocumentExpiration>(
      'CBLDart_CBLDatabase_SetDocumentExpiration',
    );
    _addDocumentChangeListener = libs.cblDart.lookupFunction<
        _CBLDart_CBLDatabase_AddDocumentChangeListener_C,
        _CBLDart_CBLDatabase_AddDocumentChangeListener>(
      'CBLDart_CBLDatabase_AddDocumentChangeListener',
    );
    _addChangeListener = libs.cblDart.lookupFunction<
        _CBLDart_CBLDatabase_AddChangeListener_C,
        _CBLDart_CBLDatabase_AddChangeListener>(
      'CBLDart_CBLDatabase_AddChangeListener',
    );
    _createIndex = libs.cblDart.lookupFunction<
        _CBLDart_CBLDatabase_CreateIndex_C, _CBLDart_CBLDatabase_CreateIndex>(
      'CBLDart_CBLDatabase_CreateIndex',
    );
    _deleteIndex = libs.cblDart.lookupFunction<
        _CBLDart_CBLDatabase_DeleteIndex_C, _CBLDart_CBLDatabase_DeleteIndex>(
      'CBLDart_CBLDatabase_DeleteIndex',
    );
    _indexNames = libs.cbl
        .lookupFunction<_CBLDatabase_GetIndexNames, _CBLDatabase_GetIndexNames>(
      'CBLDatabase_GetIndexNames',
    );
    _getBlob =
        libs.cbl.lookupFunction<_CBLDatabase_GetBlob, _CBLDatabase_GetBlob>(
      'CBLDatabase_GetBlob',
    );
    _saveBlob =
        libs.cbl.lookupFunction<_CBLDatabase_SaveBlob_C, _CBLDatabase_SaveBlob>(
      'CBLDatabase_SaveBlob',
    );
  }

  late final _CBLDart_CBL_CopyDatabase _copyDatabase;
  late final _CBLDart_CBL_DeleteDatabase _deleteDatabase;
  late final _CBLDart_CBLDatabase_Exists _databaseExists;
  late final _CBLDart_CBLDatabaseConfiguration_Default _defaultConfiguration;
  late final _CBLDart_CBLDatabase_Open _open;
  late final _CBLDart_BindDatabaseToDartObject _bindtoDartObject;
  late final _CBLDart_CBLDatabase_Close _close;
  late final _CBLDatabase_PerformMaintenance _performMaintenance;
  late final _CBLDatabase_BeginTransaction _beginTransaction;
  late final _CBLDatabase_EndTransaction _endTransaction;
  late final _CBLDart_CBLDatabase_Name _name;
  late final _CBLDart_CBLDatabase_Path _path;
  late final _CBLDatabase_Count _count;
  late final _CBLDart_CBLDatabase_GetDocument _getDocument;
  late final _CBLDart_CBLDatabase_GetMutableDocument _getMutableDocument;
  late final _CBLDart_CBLDatabase_SaveDocumentWithConcurrencyControl
      _saveDocumentWithConcurrencyControl;
  late final _CBLDatabase_DeleteDocumentWithConcurrencyControl
      _deleteDocumentWithConcurrencyControl;
  late final _CBLDart_CBLDatabase_PurgeDocumentByID _purgeDocumentByID;
  late final _CBLDart_CBLDatabase_GetDocumentExpiration _getDocumentExpiration;
  late final _CBLDart_CBLDatabase_SetDocumentExpiration _setDocumentExpiration;
  late final _CBLDart_CBLDatabase_AddDocumentChangeListener
      _addDocumentChangeListener;
  late final _CBLDart_CBLDatabase_AddChangeListener _addChangeListener;
  late final _CBLDart_CBLDatabase_CreateIndex _createIndex;
  late final _CBLDart_CBLDatabase_DeleteIndex _deleteIndex;
  late final _CBLDatabase_GetIndexNames _indexNames;
  late final _CBLDatabase_GetBlob _getBlob;
  late final _CBLDatabase_SaveBlob _saveBlob;

  bool copyDatabase(
    String from,
    String name,
    CBLDatabaseConfiguration? config,
  ) =>
      withZoneArena(() => _copyDatabase(
            from.toFLStringInArena().ref,
            name.toFLStringInArena().ref,
            _createConfig(config),
            globalCBLError,
          ).checkCBLError().toBool());

  bool deleteDatabase(String name, String? inDirectory) =>
      withZoneArena(() => _deleteDatabase(
            name.toFLStringInArena().ref,
            inDirectory.toFLStringInArena().ref,
            globalCBLError,
          ).checkCBLError().toBool());

  bool databaseExists(String name, String? inDirectory) =>
      withZoneArena(() => _databaseExists(
            name.toFLStringInArena().ref,
            inDirectory.toFLStringInArena().ref,
          ).toBool());

  CBLDatabaseConfiguration defaultConfiguration() {
    final config = _defaultConfiguration();
    return CBLDatabaseConfiguration(
      directory: config.directory.toDartString()!,
    );
  }

  Pointer<CBLDatabase> open(
    String name,
    CBLDatabaseConfiguration? config,
  ) =>
      withZoneArena(() => _open(
            name.toFLStringInArena().ref,
            _createConfig(config),
            globalCBLError,
          ).checkCBLError());

  void bindToDartObject(
    Object object,
    Pointer<CBLDatabase> db,
    String? debugName,
  ) {
    _bindtoDartObject(
      object,
      db,
      debugName?.toNativeUtf8() ?? nullptr,
    );
  }

  void close(Pointer<CBLDatabase> db) {
    _close(db, false.toInt(), globalCBLError).checkCBLError();
  }

  void delete(Pointer<CBLDatabase> db) {
    _close(db, true.toInt(), globalCBLError).checkCBLError();
  }

  void performMaintenance(Pointer<CBLDatabase> db, CBLMaintenanceType type) {
    _performMaintenance(db, type.toInt(), globalCBLError).checkCBLError();
  }

  void beginTransaction(Pointer<CBLDatabase> db) {
    _beginTransaction(db, globalCBLError).checkCBLError();
  }

  void endTransaction(Pointer<CBLDatabase> db, {required bool commit}) {
    _endTransaction(db, commit.toInt(), globalCBLError).checkCBLError();
  }

  String name(Pointer<CBLDatabase> db) => _name(db).toDartString()!;

  String path(Pointer<CBLDatabase> db) => _path(db).toDartStringAndRelease()!;

  int count(Pointer<CBLDatabase> db) => _count(db);

  Pointer<CBLDocument>? getDocument(
    Pointer<CBLDatabase> db,
    String docId,
  ) =>
      withZoneArena(() =>
          _getDocument(db, docId.toFLStringInArena().ref, globalCBLError)
              .checkCBLError()
              .toNullable());

  Pointer<CBLMutableDocument>? getMutableDocument(
    Pointer<CBLDatabase> db,
    String docId,
  ) =>
      withZoneArena(() => _getMutableDocument(
            db,
            docId.toFLStringInArena().ref,
            globalCBLError,
          ).checkCBLError().toNullable());

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

  bool deleteDocumentWithConcurrencyControl(
    Pointer<CBLDatabase> db,
    Pointer<CBLDocument> document,
    CBLConcurrencyControl concurrency,
  ) =>
      _deleteDocumentWithConcurrencyControl(
        db,
        document,
        concurrency.toInt(),
        globalCBLError,
      ).checkCBLError().toBool();

  bool purgeDocumentByID(Pointer<CBLDatabase> db, String docId) =>
      withZoneArena(() => _purgeDocumentByID(
            db,
            docId.toFLStringInArena().ref,
            globalCBLError,
          ).checkCBLError().toBool());

  DateTime? getDocumentExpiration(Pointer<CBLDatabase> db, String docId) =>
      withZoneArena(() {
        final result = _getDocumentExpiration(
          db,
          docId.toFLStringInArena().ref,
          globalCBLError,
        );

        if (result == -1) {
          checkCBLError();
        }

        return result == 0 ? null : DateTime.fromMillisecondsSinceEpoch(result);
      });

  void setDocumentExpiration(
    Pointer<CBLDatabase> db,
    String docId,
    DateTime? expiration,
  ) =>
      withZoneArena(() {
        _setDocumentExpiration(
          db,
          docId.toFLStringInArena().ref,
          expiration?.millisecondsSinceEpoch ?? 0,
          globalCBLError,
        ).checkCBLError();
      });

  void addDocumentChangeListener(
    Pointer<CBLDatabase> db,
    String docId,
    Pointer<CBLDartAsyncCallback> listener,
  ) {
    withZoneArena(() {
      _addDocumentChangeListener(db, docId.toFLStringInArena().ref, listener);
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
    CBLIndexSpec spec,
  ) {
    withZoneArena(() {
      _createIndex(
        db,
        name.toFLStringInArena().ref,
        _createIndexSpec(spec).ref,
        globalCBLError,
      ).checkCBLError();
    });
  }

  void deleteIndex(Pointer<CBLDatabase> db, String name) {
    withZoneArena(() {
      _deleteIndex(
        db,
        name.toFLStringInArena().ref,
        globalCBLError,
      ).checkCBLError();
    });
  }

  Pointer<FLArray> indexNames(Pointer<CBLDatabase> db) => _indexNames(db);

  Pointer<CBLBlob>? getBlob(
    Pointer<CBLDatabase> db,
    Pointer<FLDict> properties,
  ) =>
      _getBlob(db, properties, globalCBLError).checkCBLError().toNullable();

  void saveBlob(Pointer<CBLDatabase> db, Pointer<CBLBlob> blob) {
    _saveBlob(db, blob, globalCBLError).checkCBLError();
  }

  Pointer<_CBLDart_CBLDatabaseConfiguration> _createConfig(
    CBLDatabaseConfiguration? config,
  ) {
    if (config == null) {
      return nullptr;
    }

    final result = zoneArena<_CBLDart_CBLDatabaseConfiguration>();

    result.ref.directory = config.directory.toFLStringInArena().ref;

    return result;
  }

  Pointer<_CBLDart_CBLIndexSpec> _createIndexSpec(CBLIndexSpec spec) {
    final result = zoneArena<_CBLDart_CBLIndexSpec>();

    result.ref
      ..type = spec.type
      ..expressionLanguage = spec.expressionLanguage
      ..expressions = spec.expressions.toFLStringInArena().ref
      ..ignoreAccents = spec.ignoreAccents ?? false
      ..language = spec.language.toFLStringInArena().ref;

    return result;
  }
}
