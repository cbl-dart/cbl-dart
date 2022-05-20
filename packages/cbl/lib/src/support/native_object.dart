// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import 'debug.dart';
import 'ffi.dart';

/// Handle to an object on the native side.
class NativeObject<T extends NativeType> {
  NativeObject(this.pointer);

  /// The pointer to the native object.
  final Pointer<T> pointer;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NativeObject &&
          runtimeType == other.runtimeType &&
          pointer.address == other.pointer.address;

  @override
  int get hashCode => pointer.address.hashCode;
}

/// Handle to a CouchbaseLite C API object.
class CBLObject<T extends NativeType> extends NativeObject<T> {
  /// Creates a handle to a CouchbaseLite C API object.
  ///
  /// [adopt] should be `true` when an existing reference to the native object
  /// is transferred to the created [CBLObject] or the native object has just
  /// been created and the created [CBLObject] is the initial reference holder.
  CBLObject(
    Pointer<T> pointer, {
    bool adopt = true,
    required String debugName,
  }) : super(pointer) {
    cblBindings.base.bindCBLRefCountedToDartObject(
      this,
      refCounted: pointer.cast(),
      retain: !adopt,
      debugName: _filterDebugRefCountedName(debugName),
    );
  }
}

/// Handle to a CBLDatabase.
class CBLDatabaseObject extends NativeObject<CBLDatabase> {
  /// Creates a handle to a CBLDatabase.
  CBLDatabaseObject(
    Pointer<CBLDatabase> pointer, {
    required String debugName,
  }) : super(pointer) {
    cblBindings.database.bindToDartObject(
      this,
      pointer,
      _filterDebugRefCountedName(debugName),
    );
  }
}

/// Handle to a CBLReplicator.
class CBLReplicatorObject extends NativeObject<CBLReplicator> {
  /// Creates a handle to a CBLReplicator.
  CBLReplicatorObject(
    Pointer<CBLReplicator> pointer, {
    required String debugName,
  }) : super(pointer) {
    cblBindings.replicator.bindToDartObject(
      this,
      pointer,
      _filterDebugRefCountedName(debugName),
    );
  }
}

class CBLBlobReadStreamObject extends NativeObject<CBLBlobReadStream> {
  /// Creates a handle to a CBLBlobReadStream.
  CBLBlobReadStreamObject(Pointer<CBLBlobReadStream> pointer) : super(pointer) {
    cblBindings.blobs.readStream.bindToDartObject(this, pointer);
  }
}

/// Handle to a Fleece encoder.
class FleeceEncoderObject extends NativeObject<FLEncoder> {
  /// Creates a handle to a Fleece encoder.
  FleeceEncoderObject(Pointer<FLEncoder> pointer) : super(pointer) {
    cblBindings.fleece.encoder.bindToDartObject(this, pointer);
  }
}

String? _filterDebugRefCountedName(String debugName) =>
    debugRefCounted ? debugName : null;
