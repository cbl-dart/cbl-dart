import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

// === Lang ====================================================================

extension AnyExt<T> on T {
  R let<R>(R Function(T it) f) => f(this);
}

@pragma('vm:never-inline')
Object? cblReachabilityFence(Object? object) => object;

// === String encoding =========================================================

/// Encodes [string] as UTF-8 into a native memory buffer allocated by
/// [allocator], returning the buffer pointer and size.
///
/// This is needed when the encoded data must be stored in struct fields or
/// otherwise outlive a single leaf-function call. For direct leaf-function
/// calls, prefer using `utf8.encode` with `Uint8List.address`.
({Pointer<Void> buf, int size}) encodeStringToArena(
  String string,
  Allocator allocator,
) {
  final encoded = utf8.encode(string);
  final buf = allocator<Uint8>(encoded.length);
  buf.asTypedList(encoded.length).setAll(0, encoded);
  return (buf: buf.cast(), size: encoded.length);
}

// === Conversion ==============================================================

extension Utf8PointerExt on Pointer<Utf8> {
  String toDartStringAndFree() {
    final result = toDartString();
    malloc.free(this);
    return result;
  }
}

extension AddressPointerExt on int {
  Pointer<T> toPointer<T extends NativeType>() => Pointer.fromAddress(this);
}

extension NullableAddressPointerExt on int? {
  Pointer<T> toPointer<T extends NativeType>() =>
      (this?.toPointer<T>()).elseNullptr();
}

extension PointerExt<T extends NativeType> on Pointer<T> {
  /// If this is the [nullptr] return `null` else this pointer address.
  int? toAddressOrNull() => this == nullptr ? null : address;

  /// `null` if this pointer is the [nullptr]. Otherwise this Pointer.
  Pointer<T>? toNullable() => this == nullptr ? null : this;
}

extension NullablePointerExt<T extends NativeType> on Pointer<T>? {
  Pointer<T> elseNullptr() => this == null ? nullptr : this!;
}
