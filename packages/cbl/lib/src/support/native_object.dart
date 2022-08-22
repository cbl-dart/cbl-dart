// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import 'ffi.dart';

/// Binds the lifetime of a native CBL ref counted object to a Dart object.
///
/// [adopt] should be `true` when an existing reference to the native object is
/// transferred to the Dart [object] or the native object has just been created
/// and the created Dart [object] is the initial reference holder.
void bindCBLRefCountedToDartObject<T extends NativeType>(
  Finalizable object, {
  required Pointer<T> pointer,
  bool adopt = true,
}) {
  cblBindings.base.bindCBLRefCountedToDartObject(
    object,
    refCounted: pointer.cast(),
    retain: !adopt,
  );
}

void bindCBLDatabaseToDartObject(
  Finalizable object, {
  required Pointer<CBLDatabase> pointer,
}) {
  cblBindings.database.bindToDartObject(object, pointer);
}

void bindCBLReplicatorToDartObject(
  Finalizable object, {
  required Pointer<CBLReplicator> pointer,
}) {
  cblBindings.replicator.bindToDartObject(object, pointer);
}
