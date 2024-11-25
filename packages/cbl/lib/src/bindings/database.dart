import 'dart:ffi';
import 'dart:typed_data';

import 'base.dart';
import 'bindings.dart';
import 'cblite.dart' as cblite;
import 'cblitedart.dart' as cblitedart;
import 'data.dart';
import 'fleece.dart';
import 'global.dart';
import 'tracing.dart';
import 'utils.dart';

export 'cblite.dart' show CBLDatabase;

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

final class CBLDatabaseConfiguration {
  CBLDatabaseConfiguration({
    required this.directory,
    this.encryptionKey,
    required this.fullSync,
  });

  final String directory;
  final CBLEncryptionKey? encryptionKey;
  final bool fullSync;
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

final class DatabaseBindings extends Bindings {
  DatabaseBindings(super.parent);

  late final _finalizer =
      NativeFinalizer(cblDart.addresses.CBLDart_CBLDatabase_Release.cast());

  CBLEncryptionKey encryptionKeyFromPassword(String password) =>
      withGlobalArena(() {
        final key = globalArena<cblite.CBLEncryptionKey>();
        if (!cbl.CBLEncryptionKey_FromPassword(
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
      withGlobalArena(() => cblDart.CBLDart_CBL_CopyDatabase(
            from.toFLString(),
            name.toFLString(),
            _createConfig(config),
            globalCBLError,
          ).checkCBLError());

  bool deleteDatabase(String name, String? inDirectory) =>
      withGlobalArena(() => cbl.CBL_DeleteDatabase(
            name.toFLString(),
            inDirectory.toFLString(),
            globalCBLError,
          ).checkCBLError());

  bool databaseExists(String name, String? inDirectory) =>
      withGlobalArena(() => cbl.CBL_DatabaseExists(
            name.toFLString(),
            inDirectory.toFLString(),
          ));

  CBLDatabaseConfiguration defaultConfiguration() {
    final config = cblDart.CBLDart_CBLDatabaseConfiguration_Default();
    return CBLDatabaseConfiguration(
      directory: config.directory.toDartString()!,
      fullSync: config.fullSync,
    );
  }

  Pointer<cblite.CBLDatabase> open(
    String name,
    CBLDatabaseConfiguration? config,
  ) =>
      withGlobalArena(() {
        final nameFlStr = name.toFLString();
        final cblConfig = _createConfig(config);
        return nativeCallTracePoint(
          TracedNativeCall.databaseOpen,
          () => cblDart.CBLDart_CBLDatabase_Open(
            nameFlStr,
            cblConfig,
            globalCBLError,
          ),
        ).checkCBLError();
      });

  void bindToDartObject(Finalizable object, Pointer<cblite.CBLDatabase> db) {
    _finalizer.attach(object, db.cast());
  }

  void close(Pointer<cblite.CBLDatabase> db) {
    nativeCallTracePoint(
      TracedNativeCall.databaseClose,
      () => cblDart.CBLDart_CBLDatabase_Close(db, false, globalCBLError),
    ).checkCBLError();
  }

  void delete(Pointer<cblite.CBLDatabase> db) {
    cblDart.CBLDart_CBLDatabase_Close(db, true, globalCBLError).checkCBLError();
  }

  void performMaintenance(
      Pointer<cblite.CBLDatabase> db, CBLMaintenanceType type) {
    cbl.CBLDatabase_PerformMaintenance(db, type.toInt(), globalCBLError)
        .checkCBLError();
  }

  void beginTransaction(Pointer<cblite.CBLDatabase> db) {
    nativeCallTracePoint(
      TracedNativeCall.databaseBeginTransaction,
      () =>
          cbl.CBLDatabase_BeginTransaction(db, globalCBLError).checkCBLError(),
    );
  }

  void endTransaction(Pointer<cblite.CBLDatabase> db, {required bool commit}) {
    nativeCallTracePoint(
      TracedNativeCall.databaseEndTransaction,
      () => cbl.CBLDatabase_EndTransaction(db, commit, globalCBLError)
          .checkCBLError(),
    );
  }

  void changeEncryptionKey(
      Pointer<cblite.CBLDatabase> db, CBLEncryptionKey? key) {
    withGlobalArena(() {
      final keyStruct = globalArena<cblite.CBLEncryptionKey>();
      _writeEncryptionKey(keyStruct.ref, from: key);
      cbl.CBLDatabase_ChangeEncryptionKey(db, keyStruct, globalCBLError)
          .checkCBLError();
    });
  }

  String name(Pointer<cblite.CBLDatabase> db) =>
      cbl.CBLDatabase_Name(db).toDartString()!;

  String path(Pointer<cblite.CBLDatabase> db) =>
      cbl.CBLDatabase_Path(db).toDartStringAndRelease()!;

  Pointer<cblite.CBLBlob>? getBlob(
    Pointer<cblite.CBLDatabase> db,
    cblite.FLDict properties,
  ) =>
      nativeCallTracePoint(
        TracedNativeCall.databaseGetBlob,
        () => cbl.CBLDatabase_GetBlob(db, properties, globalCBLError),
      ).checkCBLError().toNullable();

  void saveBlob(Pointer<cblite.CBLDatabase> db, Pointer<cblite.CBLBlob> blob) {
    nativeCallTracePoint(
      TracedNativeCall.databaseSaveBlob,
      () => cbl.CBLDatabase_SaveBlob(db, blob, globalCBLError),
    ).checkCBLError();
  }

  void _writeEncryptionKey(
    cblite.CBLEncryptionKey to, {
    CBLEncryptionKey? from,
  }) {
    if (from == null) {
      to.algorithm = cblite.kCBLEncryptionNone;
      return;
    }

    to.algorithm = from.algorithm.toInt();
    final bytes = from.bytes.toTypedList();
    for (var i = 0; i < from.algorithm.keySize; i++) {
      to.bytes[i] = bytes[i];
    }
  }

  CBLEncryptionKey _readEncryptionKey(cblite.CBLEncryptionKey key) {
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

  Pointer<cblitedart.CBLDart_CBLDatabaseConfiguration> _createConfig(
    CBLDatabaseConfiguration? config,
  ) {
    if (config == null) {
      return nullptr;
    }

    final result = globalArena<cblitedart.CBLDart_CBLDatabaseConfiguration>();

    result.ref.directory = config.directory.toFLString();

    if (libraries.enterpriseEdition) {
      final key = globalArena<cblitedart.CBLDart_CBLEncryptionKey>();
      _writeEncryptionKey(
        key.cast<cblite.CBLEncryptionKey>().ref,
        from: config.encryptionKey,
      );
      result.ref.encryptionKey = key.ref;
    }

    return result;
  }
}
