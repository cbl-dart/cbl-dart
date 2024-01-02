// ignore: lines_longer_than_80_chars
// ignore_for_file: avoid_redundant_argument_values, avoid_positional_boolean_parameters, avoid_private_typedef_functions, camel_case_types

import 'dart:ffi';
import 'dart:typed_data';

import 'base.dart';
import 'bindings.dart';
import 'blob.dart';
import 'data.dart';
import 'fleece.dart';
import 'global.dart';
import 'tracing.dart';
import 'utils.dart';

enum CBLEncryptionAlgorithm {
  aes256,
}

const _encryptionKeySizes = {
  CBLEncryptionAlgorithm.aes256: 32,
};

extension EncryptionKeySizesExt on CBLEncryptionAlgorithm {
  int get keySize => _encryptionKeySizes[this]!;
}

extension on int {
  CBLEncryptionAlgorithm toCBLEncryptionAlgorithm() =>
      CBLEncryptionAlgorithm.values[this - 1];
}

extension on CBLEncryptionAlgorithm {
  int toInt() => CBLEncryptionAlgorithm.values.indexOf(this) + 1;
}

class CBLEncryptionKey {
  CBLEncryptionKey({required this.algorithm, required this.bytes});

  final CBLEncryptionAlgorithm algorithm;
  final Data bytes;
}

final class _CBLEncryptionKey extends Struct {
  @Uint32()
  external int algorithm;

  @Array(32)
  external Array<Uint8> bytes;
}

typedef _CBLEncryptionKey_FromPassword_C = Bool Function(
  Pointer<_CBLEncryptionKey> key,
  FLString password,
);
typedef _CBLEncryptionKey_FromPassword = bool Function(
  Pointer<_CBLEncryptionKey> key,
  FLString password,
);

enum CBLConcurrencyControl {
  lastWriteWins,
  failOnConflict,
}

extension CBLConcurrencyControlExt on CBLConcurrencyControl {
  int toInt() => CBLConcurrencyControl.values.indexOf(this);
}

final class CBLDatabase extends Opaque {}

class CBLDatabaseConfiguration {
  CBLDatabaseConfiguration({required this.directory, this.encryptionKey});

  final String directory;
  final CBLEncryptionKey? encryptionKey;
}

final class _CBLDatabaseConfiguration extends Struct {
  external FLString directory;
  external _CBLEncryptionKey encryptionKey;
}

typedef _CBLDatabaseConfiguration_Default = _CBLDatabaseConfiguration
    Function();

typedef _CBL_CopyDatabase_C = Bool Function(
  FLString fromPath,
  FLString toPath,
  Pointer<_CBLDatabaseConfiguration> config,
  Pointer<CBLError> errorOut,
);
typedef _CBL_CopyDatabase = bool Function(
  FLString fromPath,
  FLString toPath,
  Pointer<_CBLDatabaseConfiguration> config,
  Pointer<CBLError> errorOut,
);

typedef _CBL_DeleteDatabase_C = Bool Function(
  FLString name,
  FLString inDirectory,
  Pointer<CBLError> outError,
);
typedef _CBL_DeleteDatabase = bool Function(
  FLString name,
  FLString inDirectory,
  Pointer<CBLError> outError,
);

typedef _CBL_DatabaseExists_C = Bool Function(
  FLString name,
  FLString inDirectory,
);
typedef _CBL_DatabaseExists = bool Function(
  FLString name,
  FLString inDirectory,
);

typedef _CBLDart_CBLDatabase_Open = Pointer<CBLDatabase> Function(
  FLString name,
  Pointer<_CBLDatabaseConfiguration> config,
  Pointer<CBLError> errorOut,
);

typedef _CBLDart_CBLDatabase_Release_C = Void Function(
  Pointer<CBLDatabase> db,
);

typedef _CBLDart_CBLDatabase_Close_C = Bool Function(
  Pointer<CBLDatabase> db,
  Bool andDelete,
  Pointer<CBLError> errorOut,
);
typedef _CBLDart_CBLDatabase_Close = bool Function(
  Pointer<CBLDatabase> db,
  bool andDelete,
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

typedef _CBLDatabase_PerformMaintenance_C = Bool Function(
  Pointer<CBLDatabase> db,
  Uint32 type,
  Pointer<CBLError> errorOut,
);
typedef _CBLDatabase_PerformMaintenance = bool Function(
  Pointer<CBLDatabase> db,
  int type,
  Pointer<CBLError> errorOut,
);

typedef _CBLDatabase_BeginTransaction_C = Bool Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLError> errorOut,
);
typedef _CBLDatabase_BeginTransaction = bool Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLError> errorOut,
);

typedef _CBLDatabase_EndTransaction_C = Bool Function(
  Pointer<CBLDatabase> db,
  Bool commit,
  Pointer<CBLError> errorOut,
);
typedef _CBLDatabase_EndTransaction = bool Function(
  Pointer<CBLDatabase> db,
  bool commit,
  Pointer<CBLError> errorOut,
);

typedef _CBLDatabase_ChangeEncryptionKey_C = Bool Function(
  Pointer<CBLDatabase> db,
  Pointer<_CBLEncryptionKey> newKey,
  Pointer<CBLError> errorOut,
);
typedef _CBLDatabase_ChangeEncryptionKey = bool Function(
  Pointer<CBLDatabase> db,
  Pointer<_CBLEncryptionKey> newKey,
  Pointer<CBLError> errorOut,
);

typedef _CBLDatabase_Name = FLString Function(Pointer<CBLDatabase> db);

typedef _CBLDatabase_Path = FLStringResult Function(
  Pointer<CBLDatabase> db,
);

typedef _CBLDatabase_GetBlob = Pointer<CBLBlob> Function(
  Pointer<CBLDatabase> db,
  Pointer<FLDict> properties,
  Pointer<CBLError> errorOut,
);

typedef _CBLDatabase_SaveBlob_C = Bool Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLBlob> blob,
  Pointer<CBLError> errorOut,
);
typedef _CBLDatabase_SaveBlob = bool Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLBlob> blob,
  Pointer<CBLError> errorOut,
);

class DatabaseBindings extends Bindings {
  DatabaseBindings(super.parent) {
    if (libs.enterpriseEdition) {
      _encryptionKeyFromPassword = libs.cbl.lookupFunction<
          _CBLEncryptionKey_FromPassword_C, _CBLEncryptionKey_FromPassword>(
        'CBLEncryptionKey_FromPassword',
        isLeaf: useIsLeaf,
      );
    }
    _copyDatabase =
        libs.cbl.lookupFunction<_CBL_CopyDatabase_C, _CBL_CopyDatabase>(
      'CBL_CopyDatabase',
      isLeaf: useIsLeaf,
    );
    _deleteDatabase =
        libs.cbl.lookupFunction<_CBL_DeleteDatabase_C, _CBL_DeleteDatabase>(
      'CBL_DeleteDatabase',
      isLeaf: useIsLeaf,
    );
    _databaseExists =
        libs.cbl.lookupFunction<_CBL_DatabaseExists_C, _CBL_DatabaseExists>(
      'CBL_DatabaseExists',
      isLeaf: useIsLeaf,
    );
    _defaultConfiguration = libs.cbl.lookupFunction<
        _CBLDatabaseConfiguration_Default, _CBLDatabaseConfiguration_Default>(
      'CBLDatabaseConfiguration_Default',
      isLeaf: useIsLeaf,
    );
    _open = libs.cblDart
        .lookupFunction<_CBLDart_CBLDatabase_Open, _CBLDart_CBLDatabase_Open>(
      'CBLDart_CBLDatabase_Open',
      isLeaf: useIsLeaf,
    );
    _releasePtr = libs.cblDart.lookup('CBLDart_CBLDatabase_Release');
    _close = libs.cblDart.lookupFunction<_CBLDart_CBLDatabase_Close_C,
        _CBLDart_CBLDatabase_Close>(
      'CBLDart_CBLDatabase_Close',
      isLeaf: useIsLeaf,
    );
    _performMaintenance = libs.cbl.lookupFunction<
        _CBLDatabase_PerformMaintenance_C, _CBLDatabase_PerformMaintenance>(
      'CBLDatabase_PerformMaintenance',
      isLeaf: useIsLeaf,
    );
    _beginTransaction = libs.cbl.lookupFunction<_CBLDatabase_BeginTransaction_C,
        _CBLDatabase_BeginTransaction>(
      'CBLDatabase_BeginTransaction',
      isLeaf: useIsLeaf,
    );
    _endTransaction = libs.cbl.lookupFunction<_CBLDatabase_EndTransaction_C,
        _CBLDatabase_EndTransaction>(
      'CBLDatabase_EndTransaction',
      isLeaf: useIsLeaf,
    );
    if (libs.enterpriseEdition) {
      _changeEncryptionKey = libs.cbl.lookupFunction<
          _CBLDatabase_ChangeEncryptionKey_C, _CBLDatabase_ChangeEncryptionKey>(
        'CBLDatabase_ChangeEncryptionKey',
        isLeaf: useIsLeaf,
      );
    }
    _name = libs.cbl.lookupFunction<_CBLDatabase_Name, _CBLDatabase_Name>(
      'CBLDatabase_Name',
      isLeaf: useIsLeaf,
    );
    _path = libs.cbl.lookupFunction<_CBLDatabase_Path, _CBLDatabase_Path>(
      'CBLDatabase_Path',
      isLeaf: useIsLeaf,
    );
    _getBlob =
        libs.cbl.lookupFunction<_CBLDatabase_GetBlob, _CBLDatabase_GetBlob>(
      'CBLDatabase_GetBlob',
      isLeaf: useIsLeaf,
    );
    _saveBlob =
        libs.cbl.lookupFunction<_CBLDatabase_SaveBlob_C, _CBLDatabase_SaveBlob>(
      'CBLDatabase_SaveBlob',
      isLeaf: useIsLeaf,
    );
  }

  late final _CBLEncryptionKey_FromPassword _encryptionKeyFromPassword;
  late final _CBL_CopyDatabase _copyDatabase;
  late final _CBL_DeleteDatabase _deleteDatabase;
  late final _CBL_DatabaseExists _databaseExists;
  late final _CBLDatabaseConfiguration_Default _defaultConfiguration;
  late final _CBLDart_CBLDatabase_Open _open;
  late final Pointer<NativeFunction<_CBLDart_CBLDatabase_Release_C>>
      _releasePtr;
  late final _CBLDart_CBLDatabase_Close _close;
  late final _CBLDatabase_PerformMaintenance _performMaintenance;
  late final _CBLDatabase_BeginTransaction _beginTransaction;
  late final _CBLDatabase_EndTransaction _endTransaction;
  late final _CBLDatabase_ChangeEncryptionKey _changeEncryptionKey;
  late final _CBLDatabase_Name _name;
  late final _CBLDatabase_Path _path;
  late final _CBLDatabase_GetBlob _getBlob;
  late final _CBLDatabase_SaveBlob _saveBlob;

  late final _finalizer = NativeFinalizer(_releasePtr.cast());

  CBLEncryptionKey encryptionKeyFromPassword(String password) =>
      withGlobalArena(() {
        final key = globalArena<_CBLEncryptionKey>();
        if (!_encryptionKeyFromPassword(
          key,
          password.makeGlobalFLString(),
        )) {
          throw CBLErrorException(
            CBLErrorDomain.couchbaseLite,
            CBLErrorCode.unexpectedError,
            'There was a problem deriving the encryption key.',
          );
        }

        return _readEncryptionKey(key.ref);
      });

  bool copyDatabase(
    String from,
    String name,
    CBLDatabaseConfiguration? config,
  ) =>
      withGlobalArena(() => _copyDatabase(
            from.toFLString(),
            name.toFLString(),
            _createConfig(config),
            globalCBLError,
          ).checkCBLError());

  bool deleteDatabase(String name, String? inDirectory) =>
      withGlobalArena(() => _deleteDatabase(
            name.toFLString(),
            inDirectory.toFLString(),
            globalCBLError,
          ).checkCBLError());

  bool databaseExists(String name, String? inDirectory) =>
      withGlobalArena(() => _databaseExists(
            name.toFLString(),
            inDirectory.toFLString(),
          ));

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
      withGlobalArena(() {
        final nameFlStr = name.toFLString();
        final cblConfig = _createConfig(config);
        return nativeCallTracePoint(
          TracedNativeCall.databaseOpen,
          () => _open(nameFlStr, cblConfig, globalCBLError),
        ).checkCBLError();
      });

  void bindToDartObject(Finalizable object, Pointer<CBLDatabase> db) {
    _finalizer.attach(object, db.cast());
  }

  void close(Pointer<CBLDatabase> db) {
    nativeCallTracePoint(
      TracedNativeCall.databaseClose,
      () => _close(db, false, globalCBLError),
    ).checkCBLError();
  }

  void delete(Pointer<CBLDatabase> db) {
    _close(db, true, globalCBLError).checkCBLError();
  }

  void performMaintenance(Pointer<CBLDatabase> db, CBLMaintenanceType type) {
    _performMaintenance(db, type.toInt(), globalCBLError).checkCBLError();
  }

  void beginTransaction(Pointer<CBLDatabase> db) {
    nativeCallTracePoint(
      TracedNativeCall.databaseBeginTransaction,
      () => _beginTransaction(db, globalCBLError).checkCBLError(),
    );
  }

  void endTransaction(Pointer<CBLDatabase> db, {required bool commit}) {
    nativeCallTracePoint(
      TracedNativeCall.databaseEndTransaction,
      () => _endTransaction(db, commit, globalCBLError).checkCBLError(),
    );
  }

  void changeEncryptionKey(Pointer<CBLDatabase> db, CBLEncryptionKey? key) {
    withGlobalArena(() {
      final keyStruct = globalArena<_CBLEncryptionKey>();
      _writeEncryptionKey(keyStruct.ref, from: key);
      _changeEncryptionKey(db, keyStruct, globalCBLError).checkCBLError();
    });
  }

  String name(Pointer<CBLDatabase> db) => _name(db).toDartString()!;

  String path(Pointer<CBLDatabase> db) => _path(db).toDartStringAndRelease()!;

  Pointer<CBLBlob>? getBlob(
    Pointer<CBLDatabase> db,
    Pointer<FLDict> properties,
  ) =>
      nativeCallTracePoint(
        TracedNativeCall.databaseGetBlob,
        () => _getBlob(db, properties, globalCBLError),
      ).checkCBLError().toNullable();

  void saveBlob(Pointer<CBLDatabase> db, Pointer<CBLBlob> blob) {
    nativeCallTracePoint(
      TracedNativeCall.databaseSaveBlob,
      () => _saveBlob(db, blob, globalCBLError),
    ).checkCBLError();
  }

  void _writeEncryptionKey(_CBLEncryptionKey to, {CBLEncryptionKey? from}) {
    if (from == null) {
      // kCBLEncryptionNone = 0
      to.algorithm = 0;
      return;
    }

    to.algorithm = from.algorithm.toInt();
    final bytes = from.bytes.toTypedList();
    for (var i = 0; i < from.algorithm.keySize; i++) {
      to.bytes[i] = bytes[i];
    }
  }

  CBLEncryptionKey _readEncryptionKey(_CBLEncryptionKey key) {
    final algorithm = key.algorithm.toCBLEncryptionAlgorithm();
    final bytes = Uint8List(algorithm.keySize);
    for (var i = 0; i < algorithm.keySize; i++) {
      bytes[i] = key.bytes[i];
    }
    return CBLEncryptionKey(
      algorithm: algorithm,
      bytes: Data.fromTypedList(bytes),
    );
  }

  Pointer<_CBLDatabaseConfiguration> _createConfig(
    CBLDatabaseConfiguration? config,
  ) {
    if (config == null) {
      return nullptr;
    }

    final result = globalArena<_CBLDatabaseConfiguration>();

    result.ref.directory = config.directory.toFLString();

    if (libs.enterpriseEdition) {
      _writeEncryptionKey(result.ref.encryptionKey, from: config.encryptionKey);
    }

    return result;
  }
}
