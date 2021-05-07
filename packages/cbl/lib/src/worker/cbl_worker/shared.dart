import 'dart:ffi';
import 'dart:isolate';

/// A wrapper for a [Pointer] to send it through a [SendPort].
///
/// A [TransferablePointer] cannot represent a [nullptr].
/// Instead use `null` to represent the absence of a value..
class TransferablePointer<T extends NativeType> {
  /// Creates a wrapper for [pointer] to send it through a [SendPort].
  TransferablePointer(Pointer<T> pointer)
      : assert(pointer != nullptr),
        address = pointer.address;

  /// The pointer's raw address.
  final int address;

  /// The pointer which is wrapped by this [TransferablePointer].
  Pointer<T> get pointer => Pointer.fromAddress(address);
}

extension TransferablePointerExt<T extends NativeType> on Pointer<T> {
  /// Creates a [TransferablePointer] from this pointer.
  ///
  /// This pointer must not be the [nullptr].
  TransferablePointer<T> toTransferablePointer() =>
      toTransferablePointerOrNull()!;

  /// Creates a [TransferablePointer] from this pointer, or returns `null`
  /// when this is the [nullptr].
  TransferablePointer<T>? toTransferablePointerOrNull() =>
      this == nullptr ? null : TransferablePointer(this);
}
