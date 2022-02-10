import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'fleece.dart';
import 'global.dart';
import 'slice.dart';

// === Lang ====================================================================

extension AnyExt<T> on T {
  R let<R>(R Function(T it) f) => f(this);
}

// === Conversion ==============================================================

final _flStringSizeOf = sizeOf<FLString>();
final _flStringSizeOfAligned = _flStringSizeOf + (_flStringSizeOf % 8);

extension StringFLStringExt on String? {
  Pointer<FLString> toFLString([Allocator? allocator]) {
    final self = this;
    if (self == null) {
      return nullFLString;
    }

    final effectiveAllocator = allocator ?? globalArena;

    final encoded = utf8.encode(self);
    final flStringAndBuffer =
        effectiveAllocator<Uint8>(_flStringSizeOfAligned + encoded.length);
    final flString = flStringAndBuffer.cast<FLString>();
    final buffer = flStringAndBuffer.elementAt(_flStringSizeOfAligned);
    buffer.asTypedList(encoded.length).setAll(0, encoded);

    flString.ref
      ..buf = buffer
      ..size = encoded.length;

    return flString;
  }

  Pointer<FLString> makeGlobalFLString([Allocator? allocator]) {
    final self = this;
    if (self == null) {
      globalFLString.ref
        ..size = 0
        ..buf = nullptr;

      return globalFLString;
    }

    final effectiveAllocator = allocator ?? globalArena;

    final encoded = utf8.encode(self);
    final buffer = effectiveAllocator<Uint8>(encoded.length);
    buffer.asTypedList(encoded.length).setAll(0, encoded);

    globalFLString.ref
      ..size = encoded.length
      ..buf = buffer;

    return globalFLString;
  }
}

T runWithSingleFLString<T>(String? string, T Function(FLString flString) fn) {
  final flString = string.makeGlobalFLString(singleSliceResultAllocator).ref;
  try {
    return fn(flString);
  } finally {
    singleSliceResultAllocator.free(flString.buf);
  }
}

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

@pragma('vm:never-inline')
void keepAlive(Object object) {}
