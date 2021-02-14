import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

export 'package:ffi/ffi.dart';

// Allocation ------------------------------------------------------------------

typedef MemoryFinalizer = void Function();

/// [Arena] manages allocated C memory.
///
/// Arenas are zoned.
class Arena {
  Arena();

  final List<Pointer<Void>> _allocations = [];

  final List<MemoryFinalizer> _finalizers = [];

  /// Bound the lifetime of [ptr] to this [Arena].
  T scoped<T extends Pointer>(T ptr) {
    _allocations.add(ptr.cast());
    return ptr;
  }

  void registerFinalzier(MemoryFinalizer finalizer) {
    _finalizers.add(finalizer);
  }

  /// Frees all memory pointed to by [Pointer]s in this arena.
  void finalize() {
    for (final ptr in _allocations) {
      malloc.free(ptr);
    }

    for (final finalizer in _finalizers) {
      finalizer();
    }
  }

  /// The last [Arena] in the zone.
  factory Arena.current() {
    return Zone.current[#_currentArena] as Arena;
  }
}

/// Bound the lifetime of [ptr] to the current [Arena].
T scoped<T extends Pointer>(T ptr) => Arena.current().scoped(ptr);

/// Registers [finalizer] to be called when the current [Arena] is finalized.
void registerFinalzier(MemoryFinalizer finalizer) =>
    Arena.current().registerFinalzier(finalizer);

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

final _scoped = scoped;

extension PointerExt<T extends NativeType> on Pointer<T> {
  /// If this is the [nullptr] return `null` else this pointer address.
  int? get addressOrNull => this == nullptr ? null : address;

  /// `null` if this pointer is the [nullptr]. Otherwise this Pointer.
  Pointer<T>? get asNullable => this == nullptr ? null : this;

  Pointer<T> get asScoped => _scoped(this);
}

extension NullablePointerExt<T extends NativeType> on Pointer<T>? {
  Pointer<T> get orNullptr => this == null ? nullptr : this!;
}
