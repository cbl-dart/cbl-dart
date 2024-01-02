// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';

import '../bindings.dart';
import '../service/cbl_service_api.dart';
import '../service/cbl_worker.dart';
import '../support/edition.dart';
import '../support/ffi.dart';
import '../support/isolate.dart';
import 'database.dart';

// ignore: avoid_classes_with_only_static_members
/// A key used to encrypt a [Database].
///
/// {@template cbl.EncryptionKey.enterpriseFeature}
/// This feature is only available in the **Enterprise Edition**.
/// {@endtemplate}
///
/// This is an AES-256 key, which is 32 bytes long.
///
/// A key can be created from the raw bytes through [key]. It is important to
/// use a cryptographically secure source of randomness to generate this key,
/// for example [Random.secure].
///
/// Alternatively a key can be derived from a password through [passwordAsync]
/// or [passwordAsync]. If your UI uses passwords, call one of these method to
/// create the key used to encrypt the database. They are designed for security,
/// and deliberately run slowly to make brute-force attacks impractical.
///
/// See also:
///
/// - [DatabaseConfiguration.encryptionKey] for the encryption key used when
///   opening or copying a [Database].
/// - [Database.changeEncryptionKey] for changing the encryption key of a
///   [Database].
///
/// {@category Database}
/// {@category Enterprise Edition}
abstract class EncryptionKey {
  /// Creates an [EncryptionKey] from raw [bytes].
  ///
  /// If [bytes] is not exactly 32 bytes long, an [ArgumentError] is thrown.
  ///
  /// It is important to use a cryptographically secure source of randomness to
  /// generate this key, for example [Random.secure].
  static EncryptionKey key(Uint8List bytes) => EncryptionKeyImpl.key(bytes);

  /// Derives an [EncryptionKey] from a [password].
  ///
  /// If your UI uses passwords, call this method to create the key used to
  /// encrypt the database. It is designed for security, and deliberately runs
  /// slowly to make brute-force attacks impractical.
  ///
  /// See also:
  ///
  /// - [passwordAsync] for the asynchronous version of this method.
  static EncryptionKey passwordSync(String password) =>
      EncryptionKeyImpl.passwordSync(password);

  /// Derives an [EncryptionKey] from a [password].
  ///
  /// If your UI uses passwords, call this method to create the key used to
  /// encrypt the database. It is designed for security, and deliberately runs
  /// slowly to make brute-force attacks impractical.
  ///
  /// See also:
  ///
  /// - [passwordSync] for the synchronous version of this method.
  static Future<EncryptionKey> passwordAsync(String password) =>
      EncryptionKeyImpl.passwordAsync(password);
}

class EncryptionKeyImpl implements EncryptionKey {
  EncryptionKeyImpl(this.cblKey);

  // ignore: prefer_constructors_over_static_methods
  static EncryptionKeyImpl key(Uint8List bytes) {
    useEnterpriseFeature(EnterpriseFeature.databaseEncryption);

    final keySize = CBLEncryptionAlgorithm.aes256.keySize;
    if (bytes.length != keySize) {
      throw ArgumentError.value(
        bytes,
        'bytes',
        'must be exactly $keySize bytes long, but is ${bytes.length}',
      );
    }

    return EncryptionKeyImpl(CBLEncryptionKey(
      algorithm: CBLEncryptionAlgorithm.aes256,
      bytes: Data.fromTypedList(bytes),
    ));
  }

  // ignore: prefer_constructors_over_static_methods
  static EncryptionKeyImpl passwordSync(String password) {
    useEnterpriseFeature(EnterpriseFeature.databaseEncryption);
    final key = cblBindings.database.encryptionKeyFromPassword(password);
    return EncryptionKeyImpl(key);
  }

  static Future<EncryptionKeyImpl> passwordAsync(String password) async {
    useEnterpriseFeature(EnterpriseFeature.databaseEncryption);
    return CblWorker.executeCall(
      EncryptionKeyFromPassword(password),
      debugName: 'EncryptionKeyImpl.passwordAsync()',
    );
  }

  final CBLEncryptionKey cblKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EncryptionKeyImpl &&
          runtimeType == other.runtimeType &&
          cblKey.algorithm == other.cblKey.algorithm &&
          const DeepCollectionEquality().equals(
            cblKey.bytes.toTypedList(),
            other.cblKey.bytes.toTypedList(),
          );

  @override
  int get hashCode =>
      cblKey.algorithm.hashCode ^
      const DeepCollectionEquality().hash(cblKey.bytes.toTypedList());
}

/// Configuration for opening or copying a [Database].
///
/// {@category Database}
class DatabaseConfiguration {
  /// Creates a configuration for opening or copying a [Database].
  DatabaseConfiguration({String? directory, this.encryptionKey})
      : directory = directory ?? _defaultDirectory();

  /// Creates a configuration from another [config], by copying its properties.
  ///
  /// Does not copy [encryptionKey], to reduce locations and length of storage
  /// of security sensitive key material.
  DatabaseConfiguration.from(DatabaseConfiguration config)
      : this(directory: config.directory);

  /// Path to the directory to store the [Database] in.
  String directory;

  /// The key to encrypt the database with.
  ///
  /// {@macro cbl.EncryptionKey.enterpriseFeature}
  EncryptionKey? encryptionKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DatabaseConfiguration &&
          runtimeType == other.runtimeType &&
          directory == other.directory &&
          encryptionKey == other.encryptionKey;

  @override
  int get hashCode => directory.hashCode ^ encryptionKey.hashCode;

  @override
  String toString() => [
        'DatabaseConfiguration(',
        [
          'directory: $directory',
          if (encryptionKey != null) 'ENCRYPTION-KEY',
        ].join(', '),
        ')',
      ].join();
}

String _defaultDirectory() {
  final filesDir = IsolateContext.instance.initContext?.filesDir;
  if (filesDir != null) {
    return '$filesDir${Platform.pathSeparator}CouchbaseLite';
  }

  return Directory.current.path;
}
