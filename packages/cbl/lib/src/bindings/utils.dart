import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'cblite.dart' as cblite_lib;
import 'global.dart';
import 'native_utf8_string.dart';
import 'slice.dart';

// === Lang ====================================================================

extension AnyExt<T> on T {
  R let<R>(R Function(T it) f) => f(this);
}

@pragma('vm:never-inline')
Object? cblReachabilityFence(Object? object) => object;

// === Conversion ==============================================================

extension StringFLStringExt on String? {
  cblite_lib.FLString toFLString() {
    final self = this;
    if (self == null) {
      return nullFLString.ref;
    }

    return nativeUtf8StringEncoder.encode(self, globalArena).toFLString().ref;
  }

  cblite_lib.FLString makeGlobalFLString() {
    final self = this;
    if (self == null) {
      globalFLString.ref
        ..size = 0
        ..buf = nullptr;

      return globalFLString.ref;
    }

    return nativeUtf8StringEncoder
        .encode(self, globalArena)
        .makeGlobalFLString();
  }
}

extension NativeUtf8StringFLStringExt on NativeUtf8String {
  cblite_lib.FLString makeGlobalFLString() => globalFLString.ref
    ..buf = buffer.cast()
    ..size = size;

  Pointer<cblite_lib.FLString> toFLString() {
    final flString = globalArena<cblite_lib.FLString>();

    flString.ref
      ..buf = buffer.cast()
      ..size = size;

    return flString;
  }
}

T runWithSingleFLString<T>(
  String? string,
  T Function(cblite_lib.FLString flString) fn,
) {
  if (string == null) {
    return fn(nullFLString.ref);
  }

  final nativeString = nativeUtf8StringEncoder.encode(
    string,
    cachedSliceResultAllocator,
  );

  try {
    return fn(nativeString.makeGlobalFLString());
  } finally {
    nativeString.free();
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
      // ignore: unnecessary_parenthesis
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
