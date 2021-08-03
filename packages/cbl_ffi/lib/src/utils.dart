import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'fleece.dart';

// === Lang ====================================================================

extension AnyExt<T> on T {
  R let<R>(R Function(T it) f) => f(this);
}

// === Conversion ==============================================================

extension IntBoolExt on int {
  bool toBool() => this == 1;
}

extension BoolIntExt on bool {
  int toInt() => this ? 1 : 0;
}

final _flStringSizeOf = sizeOf<FLString>();
final _flStringSizeOfAligned = _flStringSizeOf + (_flStringSizeOf % 8);

extension StringFLStringExt on String? {
  Pointer<FLString> toFLStringInArena() {
    final string = this;
    if (string == null) {
      return nullFLString;
    }

    final encoded = utf8.encode(string);
    final flStringAndBuffer =
        zoneArena<Uint8>(_flStringSizeOfAligned + encoded.length);
    final flString = flStringAndBuffer.cast<FLString>();
    final buffer = flStringAndBuffer.elementAt(_flStringSizeOfAligned);
    buffer.asTypedList(encoded.length).setAll(0, encoded);
    flString.ref
      ..buf = buffer
      ..size = encoded.length;
    return flString;
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
