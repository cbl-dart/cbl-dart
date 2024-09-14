import 'dart:ffi';
import 'dart:typed_data';

import 'base.dart';
import 'blob.dart';
import 'cblite.dart' as cblite;
import 'cblitedart.dart' as cblitedart;
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

final class CBLEncryptionKey {
  CBLEncryptionKey({required this.algorithm, required this.bytes});

  final CBLEncryptionAlgorithm algorithm;
  final Data bytes;
}

enum CBLConcurrencyControl {
  lastWriteWins,
  failOnConflict,
}

extension CBLConcurrencyControlExt on CBLConcurrencyControl {
  int toInt() => CBLConcurrencyControl.values.indexOf(this);
}

typedef CBLDatabase = cblite.CBLDatabase;

final class CBLDatabaseConfiguration {
  CBLDatabaseConfiguration({required this.directory, this.encryptionKey});

  final String directory;
  final CBLEncryptionKey? encryptionKey;
}

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

final class DatabaseBindings {
  const DatabaseBindings();

  static final _finalizer = NativeFinalizer(Native.addressOf<
              NativeFunction<cblitedart.NativeCBLDart_CBLDatabase_Release>>(
          cblitedart.CBLDart_CBLDatabase_Release)
      .cast());

  CBLEncryptionKey encryptionKeyFromPassword(String password) =>
      withGlobalArena(() {
        final key = globalArena<cblitedart.CBLDartEncryptionKey>();
        if (!cblitedart.CBLDart_CBLEncryptionKey_FromPassword(
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
      withGlobalArena(() => cblitedart.CBLDart_CBL_CopyDatabase(
            from.toFLString(),
            name.toFLString(),
            _createConfig(config),
            globalCBLError,
          ).checkCBLError());

  bool deleteDatabase(String name, String? inDirectory) =>
      withGlobalArena(() => cblite.CBL_DeleteDatabase(
            name.toFLString(),
            inDirectory.toFLString(),
            globalCBLError,
          ).checkCBLError());

  bool databaseExists(String name, String? inDirectory) =>
      withGlobalArena(() => cblite.CBL_DatabaseExists(
            name.toFLString(),
            inDirectory.toFLString(),
          ));

  CBLDatabaseConfiguration defaultConfiguration() {
    final config = cblitedart.CBLDart_CBLDatabaseConfiguration_Default();
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
          () => cblitedart.CBLDart_CBLDatabase_Open(
            nameFlStr,
            cblConfig,
            globalCBLError,
          ),
        ).checkCBLError();
      });

  void bindToDartObject(Finalizable object, Pointer<CBLDatabase> db) {
    _finalizer.attach(object, db.cast());
  }

  void close(Pointer<CBLDatabase> db) {
    nativeCallTracePoint(
      TracedNativeCall.databaseClose,
      () => cblitedart.CBLDart_CBLDatabase_Close(db, false, globalCBLError),
    ).checkCBLError();
  }

  void delete(Pointer<CBLDatabase> db) {
    cblitedart.CBLDart_CBLDatabase_Close(db, true, globalCBLError)
        .checkCBLError();
  }

  void performMaintenance(Pointer<CBLDatabase> db, CBLMaintenanceType type) {
    cblite.CBLDatabase_PerformMaintenance(db, type.toInt(), globalCBLError)
        .checkCBLError();
  }

  void beginTransaction(Pointer<CBLDatabase> db) {
    nativeCallTracePoint(
      TracedNativeCall.databaseBeginTransaction,
      () => cblite.CBLDatabase_BeginTransaction(db, globalCBLError)
          .checkCBLError(),
    );
  }

  void endTransaction(Pointer<CBLDatabase> db, {required bool commit}) {
    nativeCallTracePoint(
      TracedNativeCall.databaseEndTransaction,
      () => cblite.CBLDatabase_EndTransaction(db, commit, globalCBLError)
          .checkCBLError(),
    );
  }

  void changeEncryptionKey(Pointer<CBLDatabase> db, CBLEncryptionKey? key) {
    withGlobalArena(() {
      final keyStruct = globalArena<cblitedart.CBLDartEncryptionKey>();
      _writeEncryptionKey(keyStruct.ref, from: key);
      cblitedart.CBLDart_CBLDatabase_ChangeEncryptionKey(
        db,
        keyStruct,
        globalCBLError,
      ).checkCBLError();
    });
  }

  String name(Pointer<CBLDatabase> db) =>
      cblite.CBLDatabase_Name(db).toDartString()!;

  String path(Pointer<CBLDatabase> db) =>
      cblite.CBLDatabase_Path(db).toDartStringAndRelease()!;

  Pointer<CBLBlob>? getBlob(
    Pointer<CBLDatabase> db,
    FLDict properties,
  ) =>
      nativeCallTracePoint(
        TracedNativeCall.databaseGetBlob,
        () => cblite.CBLDatabase_GetBlob(db, properties, globalCBLError),
      ).checkCBLError().toNullable();

  void saveBlob(Pointer<CBLDatabase> db, Pointer<CBLBlob> blob) {
    nativeCallTracePoint(
      TracedNativeCall.databaseSaveBlob,
      () => cblite.CBLDatabase_SaveBlob(db, blob, globalCBLError),
    ).checkCBLError();
  }

  void _writeEncryptionKey(
    cblitedart.CBLDartEncryptionKey to, {
    CBLEncryptionKey? from,
  }) {
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

  CBLEncryptionKey _readEncryptionKey(cblitedart.CBLDartEncryptionKey key) {
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

  Pointer<cblitedart.CBLDartDatabaseConfiguration> _createConfig(
    CBLDatabaseConfiguration? config,
  ) {
    if (config == null) {
      return nullptr;
    }

    final result = globalArena<cblitedart.CBLDartDatabaseConfiguration>();

    result.ref.directory = config.directory.toFLString();

    _writeEncryptionKey(result.ref.encryptionKey, from: config.encryptionKey);

    return result;
  }
}
