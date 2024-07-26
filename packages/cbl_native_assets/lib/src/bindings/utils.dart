// ignore_for_file: camel_case_types, non_constant_identifier_names

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'fleece.dart';
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
  FLString toFLString() {
    final self = this;
    if (self == null) {
      return nullFLString.ref;
    }

    return nativeUtf8StringEncoder.encode(self, globalArena).toFLString().ref;
  }

  FLString makeGlobalFLString() {
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
  FLString makeGlobalFLString() => globalFLString.ref
    ..buf = buffer
    ..size = size;

  Pointer<FLString> toFLString() {
    final flString = globalArena<FLString>();

    flString.ref
      ..buf = buffer
      ..size = size;

    return flString;
  }
}

T runWithSingleFLString<T>(String? string, T Function(FLString flString) fn) {
  if (string == null) {
    return fn(nullFLString.ref);
  }

  final nativeString =
      nativeUtf8StringEncoder.encode(string, cachedSliceResultAllocator);

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

// === Dynamic Library Loading =================================================

String resolveLibraryPathFromAddress(Pointer<Void> address) {
  if (Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isLinux ||
      Platform.isMacOS) {
    return _resolveLibraryPathFromAddressUnix(address);
  } else {
    // TODO(blaugold): implement windows support
    throw UnimplementedError(
      'resolveLibraryPathFromAddress on ${Platform.operatingSystem}',
    );
  }
}

String _resolveLibraryPathFromAddressUnix(Pointer<Void> address) {
  final info = malloc<_DL_info>();
  try {
    if (_dladdr(address, info) == 0) {
      return throw ArgumentError.value(
        address,
        'address',
        'unable to associate with library',
      );
    }
    return info.ref.dli_fname.cast<Utf8>().toDartString();
  } finally {
    malloc.free(info);
  }
}

final _process = DynamicLibrary.process();

final _dladdr = _process.lookupFunction<
    Int Function(Pointer<Void>, Pointer<_DL_info>),
    int Function(Pointer<Void>, Pointer<_DL_info>)>('dladdr');

final class _DL_info extends Struct {
  external Pointer<Char> dli_fname;
  external Pointer<Void> dli_fbase;
  external Pointer<Char> dli_sname;
  external Pointer<Void> dli_saddr;
}
