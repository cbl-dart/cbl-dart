import 'dart:ffi';
import 'dart:typed_data';

import 'base.dart';
import 'bindings.dart';
import 'cblite.dart' as cblite_lib;
import 'cblitedart.dart' as cblitedart_lib;
import 'data.dart';
import 'fleece.dart';
import 'global.dart';
import 'tracing.dart';
import 'utils.dart';

export 'cblite.dart' show CBLDatabase;

enum CBLEncryptionAlgorithm {
  aes256(cblite_lib.kCBLEncryptionAES256);

  const CBLEncryptionAlgorithm(this.value);

  factory CBLEncryptionAlgorithm.fromValue(int value) => switch (value) {
    cblite_lib.kCBLEncryptionAES256 => aes256,
    _ => throw ArgumentError('Unknown encryption algorithm: $value'),
  };

  final int value;

  int get keySize => switch (this) {
    CBLEncryptionAlgorithm.aes256 => cblite_lib.kCBLEncryptionKeySizeAES256,
  };
}

final class CBLEncryptionKey {
  CBLEncryptionKey({required this.algorithm, required this.bytes});

  final CBLEncryptionAlgorithm algorithm;
  final Data bytes;
}

enum CBLConcurrencyControl {
  lastWriteWins(cblite_lib.kCBLConcurrencyControlLastWriteWins),
  failOnConflict(cblite_lib.kCBLConcurrencyControlFailOnConflict);

  const CBLConcurrencyControl(this.value);

  final int value;
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
  compact(cblite_lib.kCBLMaintenanceTypeCompact),
  reindex(cblite_lib.kCBLMaintenanceTypeReindex),
  integrityCheck(cblite_lib.kCBLMaintenanceTypeIntegrityCheck),
  optimize(cblite_lib.kCBLMaintenanceTypeOptimize),
  fullOptimize(cblite_lib.kCBLMaintenanceTypeFullOptimize);

  const CBLMaintenanceType(this.value);

  final int value;
}

final class DatabaseBindings extends Bindings {
  DatabaseBindings(super.libraries);

  late final _finalizer = NativeFinalizer(
    cblitedart.addresses.CBLDart_CBLDatabase_Release.cast(),
  );

  CBLEncryptionKey encryptionKeyFromPassword(String password) =>
      withGlobalArena(() {
        final key = globalArena<cblite_lib.CBLEncryptionKey>();
        if (!cblite.CBLEncryptionKey_FromPassword(
          key,
          password.makeGlobalFLString(),
        )) {
          throw createCouchbaseLiteException(
            domain: CBLErrorDomain.couchbaseLite,
            code: CBLErrorCode.unexpectedError,
            message: 'There was a problem deriving the encryption key.',
          );
        }

        return _readEncryptionKey(key.ref);
      });

  bool copyDatabase(
    String from,
    String name,
    CBLDatabaseConfiguration? config,
  ) => withGlobalArena(
    () => cblitedart.CBLDart_CBL_CopyDatabase(
      from.toFLString(),
      name.toFLString(),
      _createConfig(config),
      globalCBLError,
    ).checkError(),
  );

  bool deleteDatabase(String name, String? inDirectory) => withGlobalArena(
    () => cblite.CBL_DeleteDatabase(
      name.toFLString(),
      inDirectory.toFLString(),
      globalCBLError,
    ).checkError(),
  );

  bool databaseExists(String name, String? inDirectory) => withGlobalArena(
    () =>
        cblite.CBL_DatabaseExists(name.toFLString(), inDirectory.toFLString()),
  );

  CBLDatabaseConfiguration defaultConfiguration() {
    final config = cblitedart.CBLDart_CBLDatabaseConfiguration_Default();
    return CBLDatabaseConfiguration(
      directory: config.directory.toDartString()!,
      fullSync: config.fullSync,
    );
  }

  Pointer<cblite_lib.CBLDatabase> open(
    String name,
    CBLDatabaseConfiguration? config,
  ) => withGlobalArena(() {
    final nameFlStr = name.toFLString();
    final cblConfig = _createConfig(config);
    return nativeCallTracePoint(
      TracedNativeCall.databaseOpen,
      () => cblitedart.CBLDart_CBLDatabase_Open(
        nameFlStr,
        cblConfig,
        globalCBLError,
      ),
    ).checkError();
  });

  void bindToDartObject(
    Finalizable object,
    Pointer<cblite_lib.CBLDatabase> db,
  ) {
    _finalizer.attach(object, db.cast());
  }

  void close(Pointer<cblite_lib.CBLDatabase> db) {
    nativeCallTracePoint(
      TracedNativeCall.databaseClose,
      () => cblitedart.CBLDart_CBLDatabase_Close(db, false, globalCBLError),
    ).checkError();
  }

  void delete(Pointer<cblite_lib.CBLDatabase> db) {
    cblitedart.CBLDart_CBLDatabase_Close(db, true, globalCBLError).checkError();
  }

  void performMaintenance(
    Pointer<cblite_lib.CBLDatabase> db,
    CBLMaintenanceType type,
  ) {
    cblite.CBLDatabase_PerformMaintenance(
      db,
      type.value,
      globalCBLError,
    ).checkError();
  }

  void beginTransaction(Pointer<cblite_lib.CBLDatabase> db) {
    nativeCallTracePoint(
      TracedNativeCall.databaseBeginTransaction,
      () =>
          cblite.CBLDatabase_BeginTransaction(db, globalCBLError).checkError(),
    );
  }

  void endTransaction(
    Pointer<cblite_lib.CBLDatabase> db, {
    required bool commit,
  }) {
    nativeCallTracePoint(
      TracedNativeCall.databaseEndTransaction,
      () => cblite.CBLDatabase_EndTransaction(
        db,
        commit,
        globalCBLError,
      ).checkError(),
    );
  }

  void changeEncryptionKey(
    Pointer<cblite_lib.CBLDatabase> db,
    CBLEncryptionKey? key,
  ) {
    withGlobalArena(() {
      final keyStruct = globalArena<cblite_lib.CBLEncryptionKey>();
      _writeEncryptionKey(keyStruct.ref, from: key);
      cblite.CBLDatabase_ChangeEncryptionKey(
        db,
        keyStruct,
        globalCBLError,
      ).checkError();
    });
  }

  String name(Pointer<cblite_lib.CBLDatabase> db) =>
      cblite.CBLDatabase_Name(db).toDartString()!;

  String path(Pointer<cblite_lib.CBLDatabase> db) =>
      cblite.CBLDatabase_Path(db).toDartStringAndRelease()!;

  Pointer<cblite_lib.CBLBlob>? getBlob(
    Pointer<cblite_lib.CBLDatabase> db,
    cblite_lib.FLDict properties,
  ) => nativeCallTracePoint(
    TracedNativeCall.databaseGetBlob,
    () => cblite.CBLDatabase_GetBlob(db, properties, globalCBLError),
  ).checkError().toNullable();

  void saveBlob(
    Pointer<cblite_lib.CBLDatabase> db,
    Pointer<cblite_lib.CBLBlob> blob,
  ) {
    nativeCallTracePoint(
      TracedNativeCall.databaseSaveBlob,
      () => cblite.CBLDatabase_SaveBlob(db, blob, globalCBLError),
    ).checkError();
  }

  void _writeEncryptionKey(
    cblite_lib.CBLEncryptionKey to, {
    CBLEncryptionKey? from,
  }) {
    if (from == null) {
      to.algorithm = cblite_lib.kCBLEncryptionNone;
      return;
    }

    to.algorithm = from.algorithm.value;
    final bytes = from.bytes.toTypedList();
    for (var i = 0; i < from.algorithm.keySize; i++) {
      to.bytes[i] = bytes[i];
    }
  }

  CBLEncryptionKey _readEncryptionKey(cblite_lib.CBLEncryptionKey key) {
    final algorithm = CBLEncryptionAlgorithm.fromValue(key.algorithm);
    final bytes = Uint8List(algorithm.keySize);
    for (var i = 0; i < algorithm.keySize; i++) {
      bytes[i] = key.bytes[i];
    }
    return CBLEncryptionKey(
      algorithm: algorithm,
      bytes: Data.fromTypedList(bytes),
    );
  }

  Pointer<cblitedart_lib.CBLDart_CBLDatabaseConfiguration> _createConfig(
    CBLDatabaseConfiguration? config,
  ) {
    if (config == null) {
      return nullptr;
    }

    final result =
        globalArena<cblitedart_lib.CBLDart_CBLDatabaseConfiguration>();

    result.ref.directory = config.directory.toFLString();

    if (libraries.enterpriseEdition) {
      final key = globalArena<cblitedart_lib.CBLDart_CBLEncryptionKey>();
      _writeEncryptionKey(
        key.cast<cblite_lib.CBLEncryptionKey>().ref,
        from: config.encryptionKey,
      );
      result.ref.encryptionKey = key.ref;
    }

    return result;
  }
}
