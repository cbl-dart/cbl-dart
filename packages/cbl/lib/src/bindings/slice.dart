// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'bindings.dart';
import 'fleece.dart';
import 'global.dart';
import 'utils.dart';

final _sliceBindings = CBLBindings.instance.fleece.slice;

/// A contiguous area of native memory, whose lifetime is tied to some other
/// object.
///
/// [Slice]s are expected to be immutable.
///
/// On the nativ side, results which are typed as a slice and may have no value,
/// represent this with the _null slice_. In Dart, these results are typed as
/// nullable and are represented with `null`.
class Slice implements Finalizable {
  /// Private constructor to initialize slice.
  Slice._(this.buf, this.size) {
    if (buf == nullptr) {
      ArgumentError.value(buf, 'buf', 'must not be the null pointer');
    }
    if (size < 0) {
      ArgumentError.value(size, 'size', 'must be non-negative');
    }
  }

  /// Creates a [Slice] which points to the same data as [slice].
  Slice.fromSlice(Slice slice) : this._(slice.buf, slice.size);

  /// Creates a [Slice] which points to the same data as [slice].
  ///
  /// Returns `null` if the [FLSlice] is the _null slice_.
  static Slice? fromFLSlice(FLSlice slice) =>
      slice.buf == nullptr ? null : Slice._(slice.buf, slice.size);

  /// Creates a [Slice] which points to the same data as [string].
  ///
  /// Returns `null` if the [FLSlice] is the _null slice_.
  static Slice? fromFLString(FLString string) =>
      string.buf == nullptr ? null : Slice._(string.buf, string.size);

  /// The pointer to start of this slice in native memory.
  final Pointer<Uint8> buf;

  /// The size of this slice in bytes.
  final int size;

  /// Interprets the data of this slice as an UTF-8 encoded string.
  String toDartString() => buf.cast<Utf8>().toDartString(length: size);

  /// Sets the [globalFLSlice] to this slice and returns it.
  Pointer<FLSlice> makeGlobal() {
    globalFLSlice.ref
      ..buf = buf
      ..size = size;
    return globalFLSlice;
  }

  /// Allocates a [FLSlice] sets it to this slice.
  Pointer<FLSlice> flSlice([Allocator allocator = malloc]) {
    final result = allocator<FLSlice>();
    result.ref
      ..buf = buf
      ..size = size;
    return result;
  }

  /// Compares this slice lexicographically to [other].
  ///
  /// | Result | Meaning                        |
  /// | -----: | :----------------------------- |
  /// |    < 0 | this slice is before [other]   |
  /// |   == 0 | this slice is equal to [other] |
  /// |    > 0 | this slice is after [other]    |
  int compareTo(Slice other) {
    final aFLSlice = makeGlobal();
    final bFLSlice = cachedSliceResultAllocator<FLSlice>();
    bFLSlice.ref
      ..buf = other.buf
      ..size = other.size;

    try {
      return _sliceBindings.compare(aFLSlice.ref, bFLSlice.ref);
    } finally {
      cachedSliceResultAllocator.free(bFLSlice);
    }
  }

  /// Returns a [Uint8List] that is a mutable view of this [Slice].
  ///
  /// You must ensure that this [Slice] is valid while the returned [Uint8List]
  /// is in use.
  ///
  /// For a less efficient but safer alternative, use [toTypedList].
  Uint8List asTypedList() => buf.asTypedList(size);

  /// Copies the contents of this [Slice] into a new [Uint8List] and returns it.
  Uint8List toTypedList() => Uint8List.fromList(asTypedList());

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! Slice) {
      return false;
    }

    final aFLSlice = makeGlobal();
    final bFLSlice = cachedSliceResultAllocator<FLSlice>();
    bFLSlice.ref
      ..buf = other.buf
      ..size = other.size;

    try {
      return _sliceBindings.equal(aFLSlice.ref, bFLSlice.ref);
    } finally {
      cachedSliceResultAllocator.free(bFLSlice);
    }
  }

  @override
  int get hashCode => buf.address;

  @override
  String toString() => 'Slice(buf: $buf, size: $size)';
}

/// A contiguous area of native memory, which stays alive at least as long as
/// this object.
///
/// [SliceResult]s are expected to be immutable after they have been returned as
/// a result.
///
/// On the nativ side, results which are typed as a slice and may have no value,
/// represent this with the _null slice_. In Dart, these results are typed as
/// nullable and are represented with `null`.
class SliceResult extends Slice {
  /// Creates an uninitialized [SliceResult] of [size].
  SliceResult(int size) : this._fromFLSliceResult(_sliceBindings.create(size));

  /// Creates a [SliceResult] and copies the data from [slice] into it.
  SliceResult.fromSlice(Slice slice)
      : this._fromFLSliceResult(_sliceBindings.copy(slice.makeGlobal().ref));

  SliceResult._fromFLSliceResult(
    FLSliceResult slice, {
    bool retain = false,
  }) : this._(slice.buf, slice.size, retain: retain);

  SliceResult._(super.buf, super.size, {bool retain = false}) : super._() {
    _sliceBindings.bindToDartObject(this, buf: buf, retain: retain);
  }

  /// Returns a [SliceResult] which has the content and size of [list].
  factory SliceResult.fromTypedList(Uint8List list) =>
      SliceResult(list.lengthInBytes)..asTypedList().setAll(0, list);

  /// Creates a [SliceResult] which contains [string] encoded as UTF-8.
  factory SliceResult.fromString(String string) {
    final encoded = utf8.encode(string);
    return SliceResult(encoded.length)..asTypedList().setAll(0, encoded);
  }

  /// Creates a [SliceResult] from a [FLSlice] by copying its content.
  static SliceResult? fromFLSlice(FLSlice slice) =>
      Slice.fromFLSlice(slice)?.let(SliceResult.fromSlice);

  /// Creates a [SliceResult] from [FLSliceResult].
  ///
  /// If the the slice should be retained, set [retain] to `true`. The slice
  /// will be release when this object is garbage collected.
  static SliceResult? fromFLSliceResult(
    FLSliceResult slice, {
    bool retain = false,
  }) =>
      slice.buf == nullptr
          ? null
          : SliceResult._fromFLSliceResult(slice, retain: retain);

  static final _keepAliveForTypedList = Expando<SliceResult>();

  /// Sets the [globalFLSliceResult] to this slice and returns it.
  Pointer<FLSliceResult> makeGlobalResult() {
    globalFLSliceResult.ref
      ..buf = buf
      ..size = size;
    return globalFLSliceResult;
  }

  /// Allocates a [FLSliceResult] sets it to this slice.
  Pointer<FLSliceResult> flSliceResult([Allocator allocator = malloc]) {
    final result = allocator<FLSliceResult>();
    result.ref
      ..buf = buf
      ..size = size;
    return result;
  }

  @override
  Uint8List asTypedList() {
    final list = super.asTypedList();
    _keepAliveForTypedList[list] = this;
    return list;
  }

  @override
  String toString() => 'SliceResult(buf: $buf, size: $size)';
}

/// A form of a [SliceResult] which can be sent through an isolate port.
///
/// A [TransferableSliceResult] must only be materialized once and only in one
/// isolate.
///
/// If a [TransferableSliceResult] is never materialized the memory of the slice
/// result is leaked.
class TransferableSliceResult {
  TransferableSliceResult(SliceResult sliceResult)
      : _bufAddress = sliceResult.buf.address,
        _size = sliceResult.size {
    // Retain the slice now, in case `sliceResult` is garbage collected
    // before this transferable slice result is materialized.
    _sliceBindings.retainSliceResultByBuf(sliceResult.buf);
  }

  final int _bufAddress;
  final int _size;

  SliceResult materialize() =>
      SliceResult._(Pointer.fromAddress(_bufAddress), _size);
}

final sliceResultAllocator = SliceResultAllocator();

/// Allocator which allocates memory through [SliceResult]s.
///
/// This allocator has the advantage that allocated memory is freed when the
/// corresponding Dart [SliceResult] object is finalized, including when an
/// isolate is destroyed.
class SliceResultAllocator implements Allocator {
  final _slices = <SliceResult>[];

  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    if (alignment != null) {
      throw ArgumentError.value(alignment, 'alignment', 'is not supported');
    }

    final slice = SliceResult(byteCount);

    // Keep the slice alive for as long as the allocated memory is in use.
    _slices.add(slice);

    return slice.buf.cast();
  }

  @override
  void free(Pointer<NativeType> pointer) {
    _slices.removeWhere((slice) => slice.buf.address == pointer.address);
  }
}

/// Allocator which owns a single [SliceResult] to quickly allocate memory.
///
/// If the [SliceResult] is already allocated, this allocator will use another
/// delegate allocator to allocate the requested memory.
class SingleSliceResultAllocator implements Allocator {
  SingleSliceResultAllocator({
    required SliceResult sliceResult,
    Allocator delegate = calloc,
  })  : _delegate = delegate,
        _sliceResult = sliceResult;

  final Allocator _delegate;
  final SliceResult _sliceResult;
  var _sliceResultIsUsed = false;

  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    if (alignment == null &&
        !_sliceResultIsUsed &&
        byteCount <= _sliceResult.size) {
      _sliceResultIsUsed = true;
      return _sliceResult.buf.cast();
    }

    return _delegate.allocate<T>(byteCount, alignment: alignment);
  }

  @override
  void free(Pointer<NativeType> pointer) {
    if (pointer.address == _sliceResult.buf.address) {
      if (!_sliceResultIsUsed) {
        throw StateError('pointer is not allocated: $pointer');
      }
      _sliceResultIsUsed = false;
    } else {
      _delegate.free(pointer);
    }
  }
}

final cachedSliceResultAllocator = SingleSliceResultAllocator(
  sliceResult: SliceResult(1024),
  delegate: malloc,
);
