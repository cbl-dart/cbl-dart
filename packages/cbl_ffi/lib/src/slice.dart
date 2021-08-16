// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'dart:collection';
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'bindings.dart';
import 'fleece.dart';
import 'utils.dart';

late final _sliceBinds = CBLBindings.instance.fleece.slice;

/// A contiguous area of native memory, whose livetime is tied to some other
/// object.
///
/// [Slice]s are expected to be immutable.
///
/// On the nativ side, results which are typed as a slice and may have no value,
/// represent this with the _null slice_. In Dart, these results are typed as
/// nullable and are represented with `null`.
class Slice implements ByteBuffer {
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
    if (identical(this, other)) {
      return true;
    }

    if (other is! Slice) {
      return false;
    }

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

  // === ByteBuffer ============================================================

  @override
  int get lengthInBytes => size;

  @override
  Uint8List asUint8List([int offsetInBytes = 0, int? length]) =>
      _SliceUint8List(offsetInBytes, length ?? lengthInBytes, this);

  @override
  Int8List asInt8List([int offsetInBytes = 0, int? length]) =>
      _throwUnsupportedError();

  @override
  Uint8ClampedList asUint8ClampedList([int offsetInBytes = 0, int? length]) =>
      _throwUnsupportedError();

  @override
  Uint16List asUint16List([int offsetInBytes = 0, int? length]) =>
      _throwUnsupportedError();

  @override
  Int16List asInt16List([int offsetInBytes = 0, int? length]) =>
      _throwUnsupportedError();

  @override
  Uint32List asUint32List([int offsetInBytes = 0, int? length]) =>
      _throwUnsupportedError();

  @override
  Int32List asInt32List([int offsetInBytes = 0, int? length]) =>
      _throwUnsupportedError();

  @override
  Uint64List asUint64List([int offsetInBytes = 0, int? length]) =>
      _throwUnsupportedError();

  @override
  Int64List asInt64List([int offsetInBytes = 0, int? length]) =>
      _throwUnsupportedError();

  @override
  Int32x4List asInt32x4List([int offsetInBytes = 0, int? length]) =>
      _throwUnsupportedError();

  @override
  Float32List asFloat32List([int offsetInBytes = 0, int? length]) =>
      _throwUnsupportedError();

  @override
  Float64List asFloat64List([int offsetInBytes = 0, int? length]) =>
      _throwUnsupportedError();

  @override
  Float32x4List asFloat32x4List([int offsetInBytes = 0, int? length]) =>
      _throwUnsupportedError();

  @override
  Float64x2List asFloat64x2List([int offsetInBytes = 0, int? length]) =>
      _throwUnsupportedError();

  @override
  ByteData asByteData([int offsetInBytes = 0, int? length]) =>
      _throwUnsupportedError();

  Never _throwUnsupportedError() =>
      throw UnsupportedError('Not supported by Slice.');
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
class SliceResult extends Slice implements ByteBuffer {
  /// Creates an uninitialized [SliceResult] of [size].
  SliceResult(int size) : this._(_sliceBinds.create(size).buf, size);

  /// Private constructor to initialize slice.
  SliceResult._(
    Pointer<Uint8> buf,
    int size, {
    bool retain = false,
  }) : super._(buf, size) {
    makeGlobal();
    _sliceBinds.bindToDartObject(this, globalFLSliceResult.ref, retain: retain);
  }

  SliceResult._subSlice(SliceResult slice, int start, int end)
      : assert(start >= 0, start < slice.size),
        assert(end >= start && end <= slice.size),
        super._(slice.buf.elementAt(start), end - start) {
    _sliceBinds.bindToDartObject(
      this,
      slice.makeGlobalResult().ref,
      retain: true,
    );
  }

  /// Creates a [SliceResult] and copies the data from [slice] into it.
  SliceResult.fromSlice(Slice slice)
      : this._(_sliceBinds.copy(slice.makeGlobal().ref).buf, slice.size);

  /// Returns a [SliceResult] which has the content and size of [list].
  factory SliceResult.fromUint8List(Uint8List list) {
    final buffer = list.buffer;
    if (buffer is SliceResult) {
      return buffer.subSlice(
        list.offsetInBytes,
        list.offsetInBytes + list.lengthInBytes,
      );
    }

    return SliceResult(list.lengthInBytes)..asUint8List().setAll(0, list);
  }

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

  /// Creates a [SliceResult] from a [FLSlice] by copying its content.
  static SliceResult? copyFLSlice(FLSlice slice) =>
      Slice.fromFLSlice(slice)?.let((slice) => SliceResult.fromSlice(slice));

  /// Creates a [SliceResult] from a [FLSliceResult] by copying its content.
  static SliceResult? copyFLSliceResult(
          FLSliceResult slice) =>
      slice.buf == nullptr
          ? null
          : Slice._(slice.buf, slice.size)
              .let((slice) => SliceResult.fromSlice(slice));

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

  /// Returns a [SliceResult] which contains the bytes of this slice, defined by
  /// the range between [start] and [end].
  ///
  /// The default of [end] is [size].
  SliceResult subSlice(int start, [int? end]) {
    end ??= size;

    RangeError.checkValidRange(start, end, size);

    if (start == 0 && end == size) {
      // Range is the whole slice.
      return this;
    }

    return SliceResult._subSlice(this, start, end);
  }

  @override
  String toString() => 'SliceResult(buf: $buf, size: $size)';
}

extension SliceResultUint8ListExt on Uint8List {
  /// Turns this [Uint8List] into a [SliceResult] which has the content and
  /// size of this list.
  SliceResult toSliceResult() => SliceResult.fromUint8List(this);
}

abstract class _SliceTypedDataList with ListMixin<int> implements TypedData {
  _SliceTypedDataList(this.offsetInBytes, this.lengthInBytes, this.buffer);

  int _get(int index);

  void _set(int index, int value);

  T _createSubList<T>(
    int start,
    int? end,
    T Function(int offsetInByte, int lengthInBytes) create,
  ) {
    // ignore: parameter_assignments
    end ??= length;
    RangeError.checkValidRange(start, end, length);
    return create(_offsetInBytes(start), _lengthInBytes(end - start));
  }

  @override
  final Slice buffer;

  @override
  final int offsetInBytes;

  @override
  final int lengthInBytes;

  @override
  int get length => lengthInBytes ~/ elementSizeInBytes;

  @override
  set length(int value) =>
      throw UnsupportedError('TypedData cannot be resized.');

  int _lengthInBytes(int length) => length * elementSizeInBytes;

  int _offsetInBytes(int offset) => offsetInBytes + offset * elementSizeInBytes;

  @override
  int operator [](int index) {
    RangeError.checkValidIndex(index, this);
    final result = _get(index);
    _keepAliveUntil(buffer);
    return result;
  }

  @override
  void operator []=(int index, int value) {
    RangeError.checkValidIndex(index, this);
    _set(index, value);
    _keepAliveUntil(buffer);
  }
}

class _SliceUint8List extends _SliceTypedDataList implements Uint8List {
  _SliceUint8List(int offsetInBytes, int lengthInBytes, Slice buffer)
      : _buf = buffer.buf.elementAt(offsetInBytes),
        super(offsetInBytes, lengthInBytes, buffer);

  final Pointer<Uint8> _buf;

  @override
  final int elementSizeInBytes = 1;

  @override
  int _get(int index) => _buf[index];

  @override
  void _set(int index, int value) => _buf[index] = value;

  @override
  Uint8List sublist(int start, [int? end]) => _createSubList(
        start,
        end,
        (offsetInByte, lengthInBytes) =>
            _SliceUint8List(offsetInBytes, lengthInBytes, buffer),
      );
}

@pragma('vm:never-inline')
void _keepAliveUntil(Object? object) {}
