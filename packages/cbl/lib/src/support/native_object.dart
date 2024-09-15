// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'dart:ffi';

import '../bindings.dart';

const _baseBindings = BaseBindings();

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
  if (!adopt) {
    _baseBindings.retainRefCounted(pointer.cast());
  }
  _baseBindings.bindCBLRefCountedToDartObject(object, pointer.cast());
}
