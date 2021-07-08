import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'base.dart';
import 'bindings.dart';
import 'document.dart';
import 'fleece.dart';
import 'native_callback.dart';
import 'utils.dart';

const encryptionKeyByteLength = 32;

enum CBLEncryptionAlgorithm {
  none,
  aes256,
}

extension on CBLEncryptionAlgorithm {
  int toInt() => CBLEncryptionAlgorithm.values.indexOf(this);
}

extension on int {
  CBLEncryptionAlgorithm toEncryptionAlgorithm() =>
      CBLEncryptionAlgorithm.values[this];
}

class CBLEncryptionKey extends Struct {
  @Uint32()
  external int _algorithm;

  external Pointer<Uint8> bytes;
}

extension CBLEncryptionKeyExt on CBLEncryptionKey {
  CBLEncryptionAlgorithm get algorithm => _algorithm.toEncryptionAlgorithm();

  set algorithm(CBLEncryptionAlgorithm value) => _algorithm = value.toInt();
}

class CBLDatabaseFlag extends Option {
  const CBLDatabaseFlag._(String name, int bits) : super(name, bits);

  static const create = CBLDatabaseFlag._('create', 1);
  static const readOnly = CBLDatabaseFlag._('readOnly', 2);
  static const noUpgrade = CBLDatabaseFlag._('noUpgrade', 4);

  static const values = [create, readOnly, noUpgrade];

  static Set<CBLDatabaseFlag> _parseCFlags(int flags) =>
      values.parseCFlags(flags);
}

class CBLDatabaseConfiguration extends Struct {
  external Pointer<Utf8> directory;

  @Uint32()
  external int _flags;

  external Pointer<CBLEncryptionKey> encryptionKey;
}

extension CBLDatabaseConfigurationExt on CBLDatabaseConfiguration {
  Set<CBLDatabaseFlag> get flags => CBLDatabaseFlag._parseCFlags(_flags);
  set flags(Set<CBLDatabaseFlag> value) => _flags = value.toCFlags();
}

enum CBLConcurrencyControl {
  lastWriteWins,
  failOnConflict,
}

extension CBLConcurrencyControlExt on CBLConcurrencyControl {
  int toInt() => CBLConcurrencyControl.values.indexOf(this);
}

class CBLDatabase extends Opaque {}

typedef CBL_CopyDatabase_C = Uint8 Function(
  Pointer<Utf8> fromPath,
  Pointer<Utf8> toPath,
  Pointer<CBLDatabaseConfiguration> config,
  Pointer<CBLError> errorOut,
);
typedef CBL_CopyDatabase = int Function(
  Pointer<Utf8> fromPath,
  Pointer<Utf8> toPath,
  Pointer<CBLDatabaseConfiguration> config,
  Pointer<CBLError> errorOut,
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

typedef CBLDatabase_Exists_C = Uint8 Function(
  Pointer<Utf8> name,
  Pointer<Utf8> inDirectory,
);
typedef CBLDatabase_Exists = int Function(
  Pointer<Utf8> name,
  Pointer<Utf8> inDirectory,
);

typedef CBLDatabase_Open = Pointer<CBLDatabase> Function(
  Pointer<Utf8> name,
  Pointer<CBLDatabaseConfiguration> config,
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

typedef CBLDatabase_BeginBatch_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLError> errorOut,
);
typedef CBLDatabase_BeginBatch = int Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLError> errorOut,
);

typedef CBLDatabase_EndBatch_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLError> errorOut,
);
typedef CBLDatabase_EndBatch = int Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLError> errorOut,
);

typedef CBLDatabase_Rekey_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLEncryptionKey> encryptionKey,
  Pointer<CBLError> errorOut,
);
typedef CBLDatabase_Rekey = int Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLEncryptionKey> encryptionKey,
  Pointer<CBLError> errorOut,
);

typedef CBLDatabase_Name = Pointer<Utf8> Function(
  Pointer<CBLDatabase> db,
);

typedef CBLDatabase_Path = Pointer<Utf8> Function(
  Pointer<CBLDatabase> db,
);

typedef CBLDatabase_Count_C = Uint64 Function(
  Pointer<CBLDatabase> db,
);
typedef CBLDatabase_Count = int Function(
  Pointer<CBLDatabase> db,
);

typedef CBLDatabase_Config_C = Void Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLDatabaseConfiguration> config,
);
typedef CBLDatabase_Config = void Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLDatabaseConfiguration> config,
);

typedef CBLDatabase_GetDocument = Pointer<CBLDocument> Function(
  Pointer<CBLDatabase> db,
  Pointer<Utf8> docId,
);

typedef CBLDatabase_GetMutableDocument = Pointer<CBLMutableDocument> Function(
  Pointer<CBLDatabase> db,
  Pointer<Utf8> docId,
);

typedef CBLDatabase_SaveDocument_C = Pointer<CBLDocument> Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLMutableDocument> doc,
  Uint8 concurrency,
  Pointer<CBLError> errorOut,
);
typedef CBLDatabase_SaveDocument = Pointer<CBLDocument> Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLMutableDocument> doc,
  int concurrency,
  Pointer<CBLError> errorOut,
);

class SaveDocumentResolvingCallbackMessage {
  SaveDocumentResolvingCallbackMessage(
    this.documentBeingSaved,
    this.conflictingDocument,
  );

  SaveDocumentResolvingCallbackMessage.fromArguments(List<dynamic> message)
      : this(
          (message[0] as int).toPointer<CBLMutableDocument>(),
          (message[1] as int?)?.toPointer<CBLDocument>(),
        );

  final Pointer<CBLMutableDocument> documentBeingSaved;
  final Pointer<CBLDocument>? conflictingDocument;
}

typedef CBLDart_CBLDatabase_SaveDocumentResolving_C = Pointer<CBLDocument>
    Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLMutableDocument> doc,
  Pointer<Callback> conflictHandler,
  Pointer<CBLError> errorOut,
);
typedef CBLDart_CBLDatabase_SaveDocumentResolving = Pointer<CBLDocument>
    Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLMutableDocument> doc,
  Pointer<Callback> conflictHandler,
  Pointer<CBLError> errorOut,
);

typedef CBLDatabase_PurgeDocumentByID_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  Pointer<Utf8> docId,
  Pointer<CBLError> errorOut,
);
typedef CBLDatabase_PurgeDocumentByID = int Function(
  Pointer<CBLDatabase> db,
  Pointer<Utf8> docId,
  Pointer<CBLError> errorOut,
);

typedef CBLDatabase_GetDocumentExpiration_C = Int64 Function(
  Pointer<CBLDatabase> db,
  Pointer<Utf8> docId,
  Pointer<CBLError> errorOut,
);
typedef CBLDatabase_GetDocumentExpiration = int Function(
  Pointer<CBLDatabase> db,
  Pointer<Utf8> docId,
  Pointer<CBLError> errorOut,
);

typedef CBLDatabase_SetDocumentExpiration_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  Pointer<Utf8> docId,
  Int64 expiration,
  Pointer<CBLError> errorOut,
);
typedef CBLDatabase_SetDocumentExpiration = int Function(
  Pointer<CBLDatabase> db,
  Pointer<Utf8> docId,
  int expiration,
  Pointer<CBLError> errorOut,
);

typedef CBLDart_CBLDatabase_AddDocumentChangeListener_C = Void Function(
  Pointer<CBLDatabase> db,
  Pointer<Utf8> docId,
  Pointer<Callback> listener,
);
typedef CBLDart_CBLDatabase_AddDocumentChangeListener = void Function(
  Pointer<CBLDatabase> db,
  Pointer<Utf8> docId,
  Pointer<Callback> listener,
);

typedef CBLDart_CBLDatabase_AddChangeListener_C = Void Function(
  Pointer<CBLDatabase> db,
  Pointer<Callback> listener,
);
typedef CBLDart_CBLDatabase_AddChangeListener = void Function(
  Pointer<CBLDatabase> db,
  Pointer<Callback> listener,
);

enum CBLIndexType {
  value,
  fullText,
}

extension on CBLIndexType {
  int toInt() => CBLIndexType.values.indexOf(this);
}

extension on int {
  CBLIndexType toIndexType() => CBLIndexType.values[this];
}

class CBLIndexSpec extends Struct {
  @Uint32()
  external int _type;

  external Pointer<Utf8> keyExpression;

  @Uint8()
  external int _ignoreAccents;

  external Pointer<Utf8> language;
}

extension CBLIndexSpecExt on CBLIndexSpec {
  CBLIndexType get type => _type.toIndexType();
  set type(CBLIndexType value) => _type = value.toInt();
  bool get ignoreAccents => _ignoreAccents.toBool();
  set ignoreAccents(bool value) => _ignoreAccents = value.toInt();
}

typedef CBLDatabase_CreateIndex_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  Pointer<Utf8> name,
  CBLIndexSpec indexSpec,
  Pointer<CBLError> errorOut,
);
typedef CBLDatabase_CreateIndex = int Function(
  Pointer<CBLDatabase> db,
  Pointer<Utf8> name,
  CBLIndexSpec indexSpec,
  Pointer<CBLError> errorOut,
);

typedef CBLDatabase_DeleteIndex_C = Uint8 Function(
  Pointer<CBLDatabase> db,
  Pointer<Utf8> name,
  Pointer<CBLError> errorOut,
);
typedef CBLDatabase_DeleteIndex = int Function(
  Pointer<CBLDatabase> db,
  Pointer<Utf8> name,
  Pointer<CBLError> errorOut,
);

typedef CBLDatabase_IndexNames = Pointer<FLArray> Function(
  Pointer<CBLDatabase> db,
);

class DatabaseBindings extends Bindings {
  DatabaseBindings(Bindings parent) : super(parent) {
    _copyDatabase =
        libs.cbl.lookupFunction<CBL_CopyDatabase_C, CBL_CopyDatabase>(
      'CBL_CopyDatabase',
    );
    _deleteDatabase =
        libs.cbl.lookupFunction<CBL_DeleteDatabase_C, CBL_DeleteDatabase>(
      'CBL_DeleteDatabase',
    );
    _databaseExists =
        libs.cbl.lookupFunction<CBLDatabase_Exists_C, CBLDatabase_Exists>(
      'CBL_DatabaseExists',
    );
    _open = libs.cbl.lookupFunction<CBLDatabase_Open, CBLDatabase_Open>(
      'CBLDatabase_Open',
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
    _beginBatch = libs.cbl
        .lookupFunction<CBLDatabase_BeginBatch_C, CBLDatabase_BeginBatch>(
      'CBLDatabase_BeginBatch',
    );
    _endBatch =
        libs.cbl.lookupFunction<CBLDatabase_EndBatch_C, CBLDatabase_EndBatch>(
      'CBLDatabase_EndBatch',
    );
    _rekey = libs.cblEE?.lookupFunction<CBLDatabase_Rekey_C, CBLDatabase_Rekey>(
      'CBLDatabase_Rekey',
    );
    _name = libs.cbl.lookupFunction<CBLDatabase_Name, CBLDatabase_Name>(
      'CBLDatabase_Name',
    );
    _path = libs.cbl.lookupFunction<CBLDatabase_Path, CBLDatabase_Path>(
      'CBLDatabase_Path',
    );
    _count = libs.cbl.lookupFunction<CBLDatabase_Count_C, CBLDatabase_Count>(
      'CBLDatabase_Count',
    );
    _config =
        libs.cblDart.lookupFunction<CBLDatabase_Config_C, CBLDatabase_Config>(
      'CBLDart_CBLDatabase_Config',
    );
    _getDocument = libs.cbl
        .lookupFunction<CBLDatabase_GetDocument, CBLDatabase_GetDocument>(
      'CBLDatabase_GetDocument',
    );
    _getMutableDocument = libs.cbl.lookupFunction<
        CBLDatabase_GetMutableDocument, CBLDatabase_GetMutableDocument>(
      'CBLDatabase_GetMutableDocument',
    );
    _saveDocument = libs.cbl
        .lookupFunction<CBLDatabase_SaveDocument_C, CBLDatabase_SaveDocument>(
      'CBLDatabase_SaveDocument',
    );
    _saveDocumentResolving = libs.cblDart.lookupFunction<
        CBLDart_CBLDatabase_SaveDocumentResolving_C,
        CBLDart_CBLDatabase_SaveDocumentResolving>(
      'CBLDart_CBLDatabase_SaveDocumentResolving',
    );
    _purgeDocumentByID = libs.cbl.lookupFunction<
        CBLDatabase_PurgeDocumentByID_C, CBLDatabase_PurgeDocumentByID>(
      'CBLDatabase_PurgeDocumentByID',
    );
    _getDocumentExpiration = libs.cbl.lookupFunction<
        CBLDatabase_GetDocumentExpiration_C, CBLDatabase_GetDocumentExpiration>(
      'CBLDatabase_GetDocumentExpiration',
    );
    _setDocumentExpiration = libs.cbl.lookupFunction<
        CBLDatabase_SetDocumentExpiration_C, CBLDatabase_SetDocumentExpiration>(
      'CBLDatabase_SetDocumentExpiration',
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
    _createIndex = libs.cbl
        .lookupFunction<CBLDatabase_CreateIndex_C, CBLDatabase_CreateIndex>(
      'CBLDatabase_CreateIndex',
    );
    _deleteIndex = libs.cbl
        .lookupFunction<CBLDatabase_DeleteIndex_C, CBLDatabase_DeleteIndex>(
      'CBLDatabase_DeleteIndex',
    );
    _indexNames =
        libs.cbl.lookupFunction<CBLDatabase_IndexNames, CBLDatabase_IndexNames>(
      'CBLDatabase_IndexNames',
    );
  }

  late final CBL_CopyDatabase _copyDatabase;
  late final CBL_DeleteDatabase _deleteDatabase;
  late final CBLDatabase_Exists _databaseExists;
  late final CBLDatabase_Open _open;
  late final CBLDatabase_Close _close;
  late final CBLDatabase_Delete _delete;
  late final CBLDatabase_PerformMaintenance _performMaintenance;
  late final CBLDatabase_BeginBatch _beginBatch;
  late final CBLDatabase_EndBatch _endBatch;
  late final CBLDatabase_Rekey? _rekey;
  late final CBLDatabase_Name _name;
  late final CBLDatabase_Name _path;
  late final CBLDatabase_Count _count;
  late final CBLDatabase_Config _config;
  late final CBLDatabase_GetDocument _getDocument;
  late final CBLDatabase_GetMutableDocument _getMutableDocument;
  late final CBLDatabase_SaveDocument _saveDocument;
  late final CBLDart_CBLDatabase_SaveDocumentResolving _saveDocumentResolving;
  late final CBLDatabase_PurgeDocumentByID _purgeDocumentByID;
  late final CBLDatabase_GetDocumentExpiration _getDocumentExpiration;
  late final CBLDatabase_SetDocumentExpiration _setDocumentExpiration;
  late final CBLDart_CBLDatabase_AddDocumentChangeListener
      _addDocumentChangeListener;
  late final CBLDart_CBLDatabase_AddChangeListener _addChangeListener;
  late final CBLDatabase_CreateIndex _createIndex;
  late final CBLDatabase_DeleteIndex _deleteIndex;
  late final CBLDatabase_IndexNames _indexNames;

  bool copyDatabase(
    String fromPath,
    String toPath,
    String? directory,
    Set<CBLDatabaseFlag>? flags,
    CBLEncryptionAlgorithm? encryptionAlgorithm,
    Uint8List? encryptionKeyBytes,
  ) {
    return withZoneArena(() {
      return stringTable.autoFree(() {
        return _copyDatabase(
          stringTable.cString(fromPath),
          stringTable.cString(toPath),
          _createConfig(
            directory,
            flags,
            encryptionAlgorithm,
            encryptionKeyBytes,
          ),
          globalCBLError,
        ).checkCBLError().toBool();
      });
    });
  }

  bool deleteDatabase(String name, String? inDirectory) {
    return stringTable.autoFree(() {
      return _deleteDatabase(
        stringTable.cString(name),
        inDirectory == null ? nullptr : stringTable.cString(inDirectory),
        globalCBLError,
      ).checkCBLError().toBool();
    });
  }

  bool databaseExists(String name, String? inDirectory) {
    return stringTable.autoFree(() {
      return _databaseExists(
        stringTable.cString(name),
        inDirectory == null ? nullptr : stringTable.cString(inDirectory),
      ).toBool();
    });
  }

  Pointer<CBLDatabase> open(
    String name,
    String? directory,
    Set<CBLDatabaseFlag>? flags,
    CBLEncryptionAlgorithm? encryptionAlgorithm,
    Uint8List? encryptionKeyBytes,
  ) {
    return withZoneArena(() {
      return stringTable.autoFree(() {
        return _open(
          stringTable.cString(name),
          _createConfig(
            directory,
            flags,
            encryptionAlgorithm,
            encryptionKeyBytes,
          ),
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

  void beginBatch(Pointer<CBLDatabase> db) {
    _beginBatch(db, globalCBLError).checkCBLError();
  }

  void endBatch(Pointer<CBLDatabase> db) {
    _endBatch(db, globalCBLError).checkCBLError();
  }

  void rekey(
    Pointer<CBLDatabase> db,
    final CBLEncryptionAlgorithm? encryptionAlgorithm,
    final Uint8List? encryptionKeyBytes,
  ) {
    withZoneArena(() {
      _rekey!
          .call(
            db,
            _createEncryptionKey(encryptionAlgorithm, encryptionKeyBytes),
            globalCBLError,
          )
          .checkCBLError();
    });
  }

  String name(Pointer<CBLDatabase> db) {
    return _name(db).toDartString();
  }

  String path(Pointer<CBLDatabase> db) {
    return _path(db).toDartString();
  }

  int count(Pointer<CBLDatabase> db) {
    return _count(db);
  }

  void config(
    Pointer<CBLDatabase> db,
    Pointer<CBLDatabaseConfiguration> config,
  ) {
    _config(db, config);
  }

  Pointer<CBLDocument> getDocument(
    Pointer<CBLDatabase> db,
    String docId,
  ) {
    return stringTable.autoFree(() {
      return _getDocument(db, stringTable.cString(docId));
    });
  }

  Pointer<CBLMutableDocument> getMutableDocument(
    Pointer<CBLDatabase> db,
    String docId,
  ) {
    return stringTable.autoFree(() {
      return _getMutableDocument(db, stringTable.cString(docId));
    });
  }

  Pointer<CBLDocument> saveDocument(
    Pointer<CBLDatabase> db,
    Pointer<CBLMutableDocument> doc,
    CBLConcurrencyControl concurrencyControl,
  ) {
    return _saveDocument(db, doc, concurrencyControl.toInt(), globalCBLError)
        .checkCBLError();
  }

  Pointer<CBLDocument> saveDocumentResolving(
    Pointer<CBLDatabase> db,
    Pointer<CBLMutableDocument> doc,
    Pointer<Callback> conflictHandler,
  ) {
    return _saveDocumentResolving(db, doc, conflictHandler, globalCBLError)
        .checkCBLError();
  }

  bool purgeDocumentByID(Pointer<CBLDatabase> db, String docId) {
    return stringTable.autoFree(() {
      return _purgeDocumentByID(db, stringTable.cString(docId), globalCBLError)
          .checkCBLError()
          .toBool();
    });
  }

  DateTime? getDocumentExpiration(Pointer<CBLDatabase> db, String docId) {
    return stringTable.autoFree(() {
      final expiration = _getDocumentExpiration(
        db,
        stringTable.cString(docId),
        globalCBLError,
      ).checkCBLError();

      return expiration == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(expiration);
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
        stringTable.cString(docId),
        expiration?.millisecondsSinceEpoch ?? 0,
        globalCBLError,
      ).checkCBLError();
    });
  }

  void addDocumentChangeListener(
    Pointer<CBLDatabase> db,
    String docId,
    Pointer<Callback> listener,
  ) {
    stringTable.autoFree(() {
      _addDocumentChangeListener(db, stringTable.cString(docId), listener);
    });
  }

  void addChangeListener(
    Pointer<CBLDatabase> db,
    Pointer<Callback> listener,
  ) {
    _addChangeListener(db, listener);
  }

  void createIndex(
    Pointer<CBLDatabase> db,
    String name,
    CBLIndexType type,
    String keyExpressions,
    bool? ignoreAccents,
    String? language,
  ) {
    withZoneArena(() {
      stringTable.autoFree(() {
        _createIndex(
          db,
          stringTable.cString(name),
          _createIndexSpec(type, keyExpressions, ignoreAccents, language).ref,
          globalCBLError,
        ).checkCBLError();
      });
    });
  }

  void deleteIndex(Pointer<CBLDatabase> db, String name) {
    stringTable.autoFree(() {
      _deleteIndex(db, stringTable.cString(name), globalCBLError)
          .checkCBLError();
    });
  }

  Pointer<FLArray> indexNames(Pointer<CBLDatabase> db) {
    return _indexNames(db);
  }

  Pointer<CBLDatabaseConfiguration> _createConfig(
    String? directory,
    Set<CBLDatabaseFlag>? flags,
    CBLEncryptionAlgorithm? encryptionAlgorithm,
    Uint8List? encryptionKey,
  ) {
    final result = zoneArena<CBLDatabaseConfiguration>();

    result.ref
      ..directory = stringTable.cString(directory, arena: true)
      .._flags = (flags ?? {}).toCFlags()
      ..encryptionKey =
          _createEncryptionKey(encryptionAlgorithm, encryptionKey);

    return result;
  }

  Pointer<CBLEncryptionKey> _createEncryptionKey(
    CBLEncryptionAlgorithm? encryptionAlgorithm,
    Uint8List? bytes,
  ) {
    assert(encryptionAlgorithm == null || bytes != null);

    if (encryptionAlgorithm == null) return nullptr;

    final result = zoneArena<CBLEncryptionKey>();

    final keyBytes = zoneArena<Uint8>(encryptionKeyByteLength)
      ..asTypedList(encryptionKeyByteLength).setAll(0, bytes!);

    result.ref
      ..algorithm = encryptionAlgorithm
      ..bytes = keyBytes;

    return result;
  }

  Pointer<CBLIndexSpec> _createIndexSpec(
    CBLIndexType type,
    String keyExpressions,
    bool? ignoreAccents,
    String? language,
  ) {
    final result = zoneArena<CBLIndexSpec>();

    result.ref
      ..type = type
      ..keyExpression = stringTable.cString(keyExpressions, arena: true)
      ..ignoreAccents = ignoreAccents ?? false
      ..language = stringTable.cString(language, arena: true);

    return result;
  }
}
