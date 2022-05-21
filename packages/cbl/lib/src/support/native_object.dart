// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import 'debug.dart';
import 'ffi.dart';

/// Binds the lifetime of a native CBL ref counted object to a Dart object.
///
/// [adopt] should be `true` when an existing reference to the native object
/// is transferred to the Dart [object] or the native object
/// has just been created and the created Dart [object] is the initial
/// reference holder.
void bindCBLRefCountedToDartObject<T extends NativeType>(
  Object object, {
  required Pointer<T> pointer,
  bool adopt = true,
  required String debugName,
}) {
  cblBindings.base.bindCBLRefCountedToDartObject(
    object,
    refCounted: pointer.cast(),
    retain: !adopt,
    debugName: _filterDebugRefCountedName(debugName),
  );
}

void bindCBLDatabaseToDartObject(
  Object object, {
  required Pointer<CBLDatabase> pointer,
  required String debugName,
}) {
  cblBindings.database.bindToDartObject(
    object,
    pointer,
    _filterDebugRefCountedName(debugName),
  );
}

void bindCBLReplicatorToDartObject(
  Object object, {
  required Pointer<CBLReplicator> pointer,
  required String debugName,
}) {
  cblBindings.replicator.bindToDartObject(
    object,
    pointer,
    _filterDebugRefCountedName(debugName),
  );
}

String? _filterDebugRefCountedName(String debugName) =>
    debugRefCounted ? debugName : null;
