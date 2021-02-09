import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

export 'package:ffi/ffi.dart';

// Allocation ------------------------------------------------------------------

/// [Arena] manages allocated C memory.
///
/// Arenas are zoned.
class Arena {
  Arena();

  final List<Pointer<Void>> _allocations = [];

  /// Bound the lifetime of [ptr] to this [Arena].
  T scoped<T extends Pointer>(T ptr) {
    _allocations.add(ptr.cast());
    return ptr;
  }

  /// Frees all memory pointed to by [Pointer]s in this arena.
  void finalize() {
    for (final ptr in _allocations) {
      malloc.free(ptr);
    }
  }

  /// The last [Arena] in the zone.
  factory Arena.current() {
    return Zone.current[#_currentArena] as Arena;
  }
}

/// Bound the lifetime of [ptr] to the current [Arena].
T scoped<T extends Pointer>(T ptr) => Arena.current().scoped(ptr);

/// Runs the [body] in an [Arena] freeing all memory which is [scoped] during
/// execution of [body] at the end of the execution.
R runArena<R>(R Function() body) {
  final arena = Arena();
  Object? _result;

  try {
    final result = runZoned(
      () => body(),
      zoneValues: {#_currentArena: arena},
    );
    _result = result;
    return result;
  } finally {
    final result = _result;
    if (result is Future) {
      result.whenComplete(arena.finalize);
    } else {
      arena.finalize();
    }
  }
}

// Conversion ------------------------------------------------------------------

extension IntBoolExt on int {
  bool get toBool => this == 1;
}

extension BoolIntExt on bool {
  int get toInt => this ? 1 : 0;
}

extension AddressPointerExt on int {
  Pointer<Void> get toPointer => Pointer.fromAddress(this);
}

extension NullableAddressPointerExt on int? {
  Pointer<Void> get toPointer => (this?.toPointer).orNullptr;
}

extension PointerExt<T extends NativeType> on Pointer<T> {
  /// If this is the [nullptr] return `null` else this pointer address.
  int? get addressOrNull => this == nullptr ? null : address;

  /// `null` if this pointer is the [nullptr]. Otherwise this Pointer.
  Pointer<T>? get asNullable => this == nullptr ? null : this;
}

extension NullablePointerExt<T extends NativeType> on Pointer<T>? {
  Pointer<T> get orNullptr => this == null ? nullptr : this!;
}

extension Utf8PointerStringExt on Pointer<Utf8> {
  String get asString => Utf8.fromUtf8(this);
}

extension StringUtf8PointerExt on String {
  Pointer<Utf8> get asUtf8 => Utf8.toUtf8(this);
  Pointer<Utf8> get asUtf8Scoped => scoped(Utf8.toUtf8(this));
}
