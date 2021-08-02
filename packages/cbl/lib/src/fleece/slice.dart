import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:cbl_ffi/cbl_ffi.dart';
import 'package:ffi/ffi.dart';

import '../support/ffi.dart';

late final _sliceBinds = cblBindings.fleece.slice;

/// A contiguous area of native memory, whose livetime is tied to some other
/// object.
///
/// [Slice]s are expected to be immutable.
///
/// On the nativ side, results which are typed as a slice and may have no value,
/// represent this with the _null slice_. In Dart, these results are typed as
/// nullable and are represented with `null`.
class Slice {
  /// Private constructor to initialize slice.
  Slice._(this.buf, this.size) : assert(buf != nullptr && size >= 0);

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

  /// Returns an unmodifiable view of the data of this slice.
  Uint8List asBytes() => UnmodifiableUint8ListView(buf.asTypedList(size));

  /// Interprets the data of this slice as an UTF-8 encoded string.
  String toDartString() => buf.cast<Utf8>().toDartString(length: size);

  /// Sets the [globalFLSlice] to this slice and returns it.
  Pointer<FLSlice> makeGlobal() {
    globalFLSlice.ref
      ..buf = buf
      ..size = size;
    return globalFLSlice;
  }

  /// Compares this slice lexicographically to [other].
  ///
  /// |  Result | Meaning                        |
  /// |--------:|:-------------------------------|
  /// |     < 0 | this slice is before [other]   |
  /// |    == 0 | this slice is equal to [other] |
  /// |     > 0 | this slice is after [other]    |
  int compareTo(Slice other) {
    final aFLSlice = makeGlobal();
    final bFLSlice = malloc<FLSlice>();
    bFLSlice.ref
      ..buf = other.buf
      ..size = other.size;

    try {
      return _sliceBinds.compare(aFLSlice.ref, bFLSlice.ref);
    } finally {
      malloc.free(bFLSlice);
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    if (other is! Slice) return false;

    final aFLSlice = makeGlobal();
    final bFLSlice = malloc<FLSlice>();
    bFLSlice.ref
      ..buf = other.buf
      ..size = other.size;

    try {
      return _sliceBinds.equal(aFLSlice.ref, bFLSlice.ref);
    } finally {
      malloc.free(bFLSlice);
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
/// [SliceResult]s are expected to be immutable after they have been returned
/// as a result.
///
/// On the nativ side, results which are typed as a slice and may have no value,
/// represent this with the _null slice_. In Dart, these results are typed as
/// nullable and are represented with `null`.
class SliceResult extends Slice {
  /// Private constructor to initialize slice.
  SliceResult._(
    Pointer<Uint8> buf,
    int size, {
    bool retain = false,
  }) : super._(buf, size) {
    makeGlobal();
    _sliceBinds.bindToDartObject(this, globalFLSliceResult.ref, retain);
  }

  /// Creates an uninitialized [SliceResult] of [size].
  SliceResult(int size) : super._(_sliceBinds.create(size).buf, size);

  /// Creates a [SliceResult] and copies the data from [slice] into it.
  SliceResult.fromSlice(Slice slice)
      : super._(_sliceBinds.copy(slice.makeGlobal().ref).buf, slice.size);

  /// Creates a [SliceResult] which contains [string] encoded as UTF-8.
  factory SliceResult.fromString(String string) {
    final encoded = utf8.encode(string);
    final result = SliceResult(encoded.length);
    result.buf.asTypedList(encoded.length).setAll(0, encoded);
    return result;
  }

  /// Creates a [SliceResult] from [FLSliceResult].
  ///
  /// If the the slice should be retained, set [retain] to `true`.
  /// The slice will be release when this object is garbage collected.
  static SliceResult? fromFLSliceResult(
    FLSliceResult slice, {
    bool retain = false,
  }) =>
      slice.buf == nullptr
          ? null
          : SliceResult._(slice.buf, slice.size, retain: retain);

  /// Expando which is used to keep a [SliceResult] alive, while [Uint8List]s
  /// are alive which are backed by it.
  static final _backingSliceOfBytes =
      Expando<SliceResult>('SliceResult.backingSliceOfBytes');

  /// Returns an modifiable view of the data of this slice.
  @override
  Uint8List asBytes() {
    final bytes = buf.asTypedList(size);
    _backingSliceOfBytes[bytes] = this;
    return bytes;
  }

  @override
  String toString() => 'SliceResult(buf: $buf, size: $size)';
}
