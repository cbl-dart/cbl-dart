// ignore_for_file: always_put_control_body_on_new_line
// ignore_for_file: cascade_invocations
// ignore_for_file: prefer_foreach
// ignore_for_file: avoid_positional_boolean_parameters

import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' show malloc;

// ============================================================================
// Fleece Binary Format Constants
// ============================================================================

/// Tags occupy the upper 4 bits of the first byte of a value.
abstract final class FleeceTag {
  static const int smallInt = 0x0; // 0000: 12-bit signed integer
  static const int longInt = 0x1; // 0001: variable-length integer
  static const int float = 0x2; // 0010: 32-bit or 64-bit float
  static const int special = 0x3; // 0011: null, false, true, undefined
  static const int string = 0x4; // 0100: UTF-8 string
  static const int data = 0x5; // 0101: binary data
  static const int array = 0x6; // 0110: array
  static const int dict = 0x7; // 0111: dictionary
  static const int pointer = 0x8; // 1xxx: backward pointer
}

/// Special value subtypes (tag 0x3).
abstract final class FleeceSpecial {
  static const int null_ = 0;
  static const int false_ = 1;
  static const int true_ = 2;
  static const int undefined = 3;
}

/// Range of small (inline) integers: -2048 to 2047.
const int _smallIntMin = -2048;
const int _smallIntMax = 2047;

/// Maximum backward offset for a narrow (2-byte) pointer.
const int _narrowPointerMax = 0x7FFF; // 15-bit offset field

// ============================================================================
// Fleece Decoder
// ============================================================================

/// Type of a decoded Fleece value.
enum FleeceValueType {
  null_,
  undefined,
  bool_,
  int_,
  double_,
  string,
  data,
  array,
  dict,
}

/// A read-only view into Fleece-encoded data.
///
/// Values are not materialized eagerly — they are pointers into the underlying
/// [Uint8List]. Navigation (array indexing, dict lookup) is done by arithmetic
/// on the raw bytes with zero heap allocation for scalar access.
final class FleeceDecoder implements Finalizable {
  factory FleeceDecoder(Uint8List source) {
    final length = source.length;
    final ptr = malloc<Uint8>(length);
    ptr.asTypedList(length).setAll(0, source);
    return FleeceDecoder._owned(ptr, length);
  }

  factory FleeceDecoder.fromPointer(Pointer<Uint8> ptr, int length) {
    final ownedPtr = malloc<Uint8>(length);
    ownedPtr.asTypedList(length).setAll(0, ptr.asTypedList(length));
    return FleeceDecoder._owned(ownedPtr, length);
  }

  FleeceDecoder._owned(this._ptr, int length)
    : bytes = _ptr.asTypedList(length),
      _data = ByteData.sublistView(_ptr.asTypedList(length)) {
    _finalizer.attach(this, _ptr.cast(), externalSize: length);
  }

  static final _finalizer = NativeFinalizer(malloc.nativeFree);

  final Uint8List bytes;
  final ByteData _data;
  final Pointer<Uint8> _ptr;

  /// Cache of decoded dict key strings by buffer offset. Since the encoder
  /// deduplicates strings, many dict key references point to the same offset.
  /// Caching avoids re-decoding the same key bytes repeatedly. Only used for
  /// dict keys (which repeat); value strings are decoded directly.
  final _keyCache = _IntStringCache();

  /// Returns the root value as a Pointer-based extension type.
  ///
  /// Must be called within [runWithFleeceDecoder].
  FV get rootFV {
    if (bytes.length < 2) {
      throw FormatException('Fleece data too short: ${bytes.length} bytes');
    }
    var p = _ptr + (bytes.length - 2);
    if ((p[0] & 0x80) != 0) {
      p = _resolveNarrowPtr(p);
      // coverage:ignore-start
      if ((p[0] & 0x80) != 0) {
        p = _resolveWidePtr(p);
      }
      // coverage:ignore-end
    }
    return FV._(p);
  }

  /// Returns the root value (the last 2 bytes of the data).
  FleeceValue get root {
    if (bytes.length < 2) {
      throw FormatException('Fleece data too short: ${bytes.length} bytes');
    }
    // Root is at the last 2 bytes.
    var offset = bytes.length - 2;
    // If it's a narrow pointer, dereference it.
    if (_isPointer(offset)) {
      offset = _dereferenceNarrowPointer(offset);
      // coverage:ignore-start
      // Double pointer indirection only occurs with >64KB root objects.
      if (_isPointer(offset)) {
        offset = _dereferenceWidePointer(offset);
      }
      // coverage:ignore-end
    }
    return FleeceValue._(this, offset);
  }

  bool _isPointer(int offset) => (_data.getUint8(offset) & 0x80) != 0;

  int _dereferenceNarrowPointer(int offset) {
    final raw = _data.getUint16(offset, Endian.big);
    // Pointer: 1ooooooo oooooooo — 15-bit offset in units of 2 bytes
    final backOffset = (raw & 0x7FFF) * 2;
    return offset - backOffset;
  }

  // coverage:ignore-start
  // Wide pointers only occur with >64KB data.
  int _dereferenceWidePointer(int offset) {
    final raw = _data.getUint32(offset, Endian.big);
    final backOffset = (raw & 0x7FFFFFFF) * 2;
    return offset - backOffset;
  }
  // coverage:ignore-end

  /// Resolve a value offset, following pointers as needed. [wide] indicates
  /// whether collection slots are 4 bytes (true) or 2 bytes.
  int _resolve(int offset, {required bool wide}) {
    if (_isPointer(offset)) {
      if (wide) {
        return _resolveWide(offset); // coverage:ignore-line
      } else {
        return _resolveNarrow(offset);
      }
    }
    return offset;
  }

  int _resolveNarrow(int offset) {
    var current = offset;
    while (_isPointer(current)) {
      current = _dereferenceNarrowPointer(current);
    }
    return current;
  }

  // coverage:ignore-start
  // Wide resolution only occurs with wide collections (>64KB data).
  int _resolveWide(int offset) {
    if (!_isPointer(offset)) {
      return offset;
    }
    var current = _dereferenceWidePointer(offset);
    while (_isPointer(current)) {
      current = _dereferenceNarrowPointer(current);
    }
    return current;
  }
  // coverage:ignore-end

  // --- Pointer-based resolve (for FV/FA/FD extension types) ---

  Pointer<Uint8> _resolveNarrowPtr(Pointer<Uint8> p) {
    var current = p;
    while ((current[0] & 0x80) != 0) {
      final raw = (current[0] << 8) | current[1];
      final backOffset = (raw & 0x7FFF) * 2;
      current = current + (-backOffset);
    }
    return current;
  }

  // coverage:ignore-start
  Pointer<Uint8> _resolveWidePtr(Pointer<Uint8> p) {
    final raw = (p[0] << 24) | (p[1] << 16) | (p[2] << 8) | p[3];
    final backOffset = (raw & 0x7FFFFFFF) * 2;
    var current = p + (-backOffset);
    while ((current[0] & 0x80) != 0) {
      final rawN = (current[0] << 8) | current[1];
      final backN = (rawN & 0x7FFF) * 2;
      current = current + (-backN);
    }
    return current;
  }
  // coverage:ignore-end

  Pointer<Uint8> _resolvePtr(Pointer<Uint8> p, {required bool wide}) {
    if ((p[0] & 0x80) != 0) {
      if (wide) {
        return _resolveWidePtr(p); // coverage:ignore-line
      } else {
        return _resolveNarrowPtr(p);
      }
    }
    return p;
  }

  int _tag(int offset) => _data.getUint8(offset) >> 4;

  FleeceValueType _typeAt(int offset) {
    final tag = _tag(offset);
    switch (tag) {
      case FleeceTag.smallInt:
      case FleeceTag.longInt:
        return FleeceValueType.int_;
      case FleeceTag.float:
        return FleeceValueType.double_;
      case FleeceTag.special:
        final subtype = (_data.getUint8(offset) >> 2) & 0x03;
        return switch (subtype) {
          FleeceSpecial.null_ => FleeceValueType.null_,
          FleeceSpecial.false_ || FleeceSpecial.true_ => FleeceValueType.bool_,
          FleeceSpecial.undefined => FleeceValueType.undefined,
          // coverage:ignore-start
          _ => throw FormatException('Unknown special subtype: $subtype'),
          // coverage:ignore-end
        };
      case FleeceTag.string:
        return FleeceValueType.string;
      case FleeceTag.data:
        return FleeceValueType.data;
      case FleeceTag.array:
        return FleeceValueType.array;
      case FleeceTag.dict:
        return FleeceValueType.dict;
      // coverage:ignore-start
      default:
        throw FormatException('Unexpected tag $tag at offset $offset');
      // coverage:ignore-end
    }
  }

  bool _boolAt(int offset) {
    final subtype = (_data.getUint8(offset) >> 2) & 0x03;
    return subtype == FleeceSpecial.true_;
  }

  int _intAt(int offset) {
    final tag = _tag(offset);
    if (tag == FleeceTag.smallInt) {
      // 0000iiii iiiiiiii — 12-bit signed, big-endian across the two bytes.
      final raw = _data.getUint16(offset, Endian.big) & 0x0FFF;
      // Sign-extend 12-bit value.
      return raw < 0x800 ? raw : raw - 0x1000;
    } else {
      // Long integer: 0001uccc iiiiiiii...
      // Data bytes start at offset + 1 (byte 1 is the first data byte).
      final byte0 = _data.getUint8(offset);
      final unsigned = (byte0 & 0x08) != 0;
      final byteCount = (byte0 & 0x07) + 1; // ccc + 1
      var value = 0;
      for (var i = 0; i < byteCount; i++) {
        value |= _data.getUint8(offset + 1 + i) << (8 * i);
      }
      // Sign-extend if signed.
      if (!unsigned && byteCount < 8) {
        final signBit = 1 << (byteCount * 8 - 1);
        if ((value & signBit) != 0) {
          value |= ~((1 << (byteCount * 8)) - 1);
        }
      }
      return value;
    }
  }

  double _doubleAt(int offset) {
    final byte0 = _data.getUint8(offset);
    final is64Bit = (byte0 & 0x08) != 0;
    // Floats have a 2-byte header (byte 1 is reserved/padding).
    // Float data starts at offset + 2.
    if (is64Bit) {
      return _data.getFloat64(offset + 2, Endian.little);
    } else {
      return _data.getFloat32(offset + 2, Endian.little);
    }
  }

  /// Reads the byte count and data start offset for a string or data value.
  /// Returns (dataStart, byteCount).
  ///
  /// String/data layout: Short (count < 15): byte 0 = tag|count, data starts at
  /// byte 1 Long (count == 15): byte 0 = tag|0xF, varint at byte 1, data after
  /// varint
  (int, int) _blobInfo(int offset) {
    final byte0 = _data.getUint8(offset);
    var byteCount = byte0 & 0x0F;
    if (byteCount == 0x0F) {
      // Varint count follows at byte 1.
      final (count, varintLen) = _readVarint(offset + 1);
      byteCount = count;
      return (offset + 1 + varintLen, byteCount);
    }
    return (offset + 1, byteCount);
  }

  String _stringAt(int offset) {
    // Inline _blobInfo to avoid record allocation.
    final byte0 = bytes[offset];
    int dataStart;
    var byteCount = byte0 & 0x0F;
    if (byteCount == 0x0F) {
      final (count, varintLen) = _readVarint(offset + 1);
      byteCount = count;
      dataStart = offset + 1 + varintLen;
    } else {
      dataStart = offset + 1;
    }

    // ASCII fast path: avoid Uint8List.sublistView + utf8.decode.
    final end = dataStart + byteCount;
    var isAscii = true;
    for (var i = dataStart; i < end; i++) {
      if (bytes[i] >= 0x80) {
        isAscii = false;
        break;
      }
    }
    if (isAscii) {
      return String.fromCharCodes(bytes, dataStart, end);
    }
    return utf8.decode(Uint8List.sublistView(bytes, dataStart, end));
  }

  /// Like [_stringAt] but caches results by offset. Used for dict keys which
  /// repeat frequently due to encoder string deduplication.
  String _keyStringAt(int offset) {
    final cached = _keyCache.lookup(offset);
    if (cached != null) return cached;
    final result = _stringAt(offset);
    _keyCache.insert(offset, result);
    return result;
  }

  Uint8List _dataAt(int offset) {
    final (dataStart, byteCount) = _blobInfo(offset);
    return Uint8List.sublistView(bytes, dataStart, dataStart + byteCount);
  }

  /// Reads the count and wide flag for an array or dict at [offset]. Returns
  /// (count, wide, firstItemOffset).
  (int count, bool wide, int firstItemOffset) _collectionInfo(int offset) {
    final header = _data.getUint16(offset, Endian.big);
    final wide = (header & 0x0800) != 0;
    var count = header & 0x07FF;
    var firstItem = offset + 2;
    // coverage:ignore-start
    // Overflow count only occurs with >2046 collection items.
    if (count == 0x7FF) {
      final (realCount, varintLen) = _readVarint(offset + 2);
      count = realCount;
      firstItem = offset + 2 + varintLen;
      if (firstItem.isOdd) {
        firstItem++;
      }
    }
    // coverage:ignore-end
    return (count, wide, firstItem);
  }

  /// Read a varint at [offset]. Returns (value, bytesConsumed).
  (int, int) _readVarint(int offset) {
    var value = 0;
    var shift = 0;
    var i = 0;
    while (true) {
      final byte = _data.getUint8(offset + i);
      value |= (byte & 0x7F) << shift;
      i++;
      if ((byte & 0x80) == 0) {
        break;
      }
      shift += 7;
    }
    return (value, i);
  }

  /// Returns the offset of the [index]-th element in an array.
  int _arrayElementOffset(
    int firstItemOffset, {
    required int index,
    required bool wide,
  }) {
    final slotSize = wide ? 4 : 2;
    return firstItemOffset + index * slotSize;
  }

  /// Returns the offset of the [index]-th key in a dict.
  int _dictKeyOffset(
    int firstItemOffset, {
    required int index,
    required bool wide,
  }) {
    final slotSize = wide ? 4 : 2;
    return firstItemOffset + index * slotSize * 2;
  }

  /// Returns the offset of the value for the [index]-th entry in a dict.
  int _dictValueOffset(
    int firstItemOffset, {
    required int index,
    required bool wide,
  }) {
    final slotSize = wide ? 4 : 2;
    return firstItemOffset + index * slotSize * 2 + slotSize;
  }

  /// Returns the string key at a dict key slot (after resolving pointers).
  String _dictKeyString(int keyOffset, {required bool wide}) {
    final resolved = _resolve(keyOffset, wide: wide);
    final tag = _tag(resolved);
    if (tag == FleeceTag.string) {
      return _keyStringAt(resolved);
    } else if (tag == FleeceTag.smallInt || tag == FleeceTag.longInt) {
      // Shared integer key — not supported in this prototype.
      throw UnsupportedError('Shared integer keys are not supported');
    }
    throw FormatException('Unexpected dict key tag: $tag');
  }

  /// Binary search for a string key in a dict. Returns the index or -1 if not
  /// found.
  int _dictFindKey(
    int firstItemOffset, {
    required int count,
    required bool wide,
    required String key,
  }) {
    final keyBytes = utf8.encode(key);
    var lo = 0;
    var hi = count - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >>> 1;
      final midKeyOffset = _dictKeyOffset(
        firstItemOffset,
        index: mid,
        wide: wide,
      );
      final resolved = _resolve(midKeyOffset, wide: wide);
      final cmp = _compareStringKey(resolved, keyBytes);
      if (cmp < 0) {
        lo = mid + 1;
      } else if (cmp > 0) {
        hi = mid - 1;
      } else {
        return mid;
      }
    }
    return -1;
  }

  /// Converts the value at [offset] directly to a Dart object, avoiding
  /// FleeceValue allocation and redundant type dispatch.
  Object? _toObjectAt(int offset) {
    final tag = _tag(offset);
    switch (tag) {
      case FleeceTag.smallInt:
      case FleeceTag.longInt:
        return _intAt(offset);
      case FleeceTag.float:
        return _doubleAt(offset);
      case FleeceTag.special:
        final subtype = (bytes[offset] >> 2) & 0x03;
        return switch (subtype) {
          FleeceSpecial.false_ => false,
          FleeceSpecial.true_ => true,
          _ => null,
        };
      case FleeceTag.string:
        return _stringAt(offset);
      case FleeceTag.data:
        return _dataAt(offset);
      case FleeceTag.array:
        return _arrayToObject(offset);
      case FleeceTag.dict:
        return _dictToObject(offset);
      default:
        return null;
    }
  }

  /// Converts an array at [offset] to a List, avoiding FleeceArray allocation.
  List<Object?> _arrayToObject(int offset) {
    final header = _data.getUint16(offset, Endian.big);
    final wide = (header & 0x0800) != 0;
    var count = header & 0x07FF;
    var firstItem = offset + 2;
    // coverage:ignore-start
    if (count == 0x7FF) {
      final (realCount, varintLen) = _readVarint(offset + 2);
      count = realCount;
      firstItem = offset + 2 + varintLen;
      if (firstItem.isOdd) firstItem++;
    }
    // coverage:ignore-end
    final slotSize = wide ? 4 : 2;
    final result = List<Object?>.filled(count, null);
    var slotOffset = firstItem;
    for (var i = 0; i < count; i++) {
      final resolved = _resolve(slotOffset, wide: wide);
      result[i] = _toObjectAt(resolved);
      slotOffset += slotSize;
    }
    return result;
  }

  /// Converts a dict at [offset] to a Map, avoiding FleeceDict allocation.
  Map<String, Object?> _dictToObject(int offset) {
    final header = _data.getUint16(offset, Endian.big);
    final wide = (header & 0x0800) != 0;
    var count = header & 0x07FF;
    var firstItem = offset + 2;
    // coverage:ignore-start
    if (count == 0x7FF) {
      final (realCount, varintLen) = _readVarint(offset + 2);
      count = realCount;
      firstItem = offset + 2 + varintLen;
      if (firstItem.isOdd) firstItem++;
    }
    // coverage:ignore-end
    final slotSize = wide ? 4 : 2;
    final map = <String, Object?>{};
    var keySlot = firstItem;
    for (var i = 0; i < count; i++) {
      final keyResolved = _resolve(keySlot, wide: wide);
      final key = _keyStringAt(keyResolved);
      final valueSlot = keySlot + slotSize;
      final valueResolved = _resolve(valueSlot, wide: wide);
      map[key] = _toObjectAt(valueResolved);
      keySlot += slotSize * 2;
    }
    return map;
  }

  /// Visits every value in the tree rooted at [offset] without materializing
  /// Dart objects. Returns a checksum-like int to prevent the optimizer from
  /// eliminating work. This is the Dart equivalent of the C benchmark's
  /// visit_value.
  int _visitAt(int offset) {
    final tag = _tag(offset);
    switch (tag) {
      case FleeceTag.smallInt:
      case FleeceTag.longInt:
        return _intAt(offset);
      case FleeceTag.float:
        return _doubleAt(offset).toInt();
      case FleeceTag.special:
        return (bytes[offset] >> 2) & 0x03;
      case FleeceTag.string:
        // Read the string length but don't decode it — mirrors C's
        // `sink += s.size`.
        final byte0 = bytes[offset];
        var byteCount = byte0 & 0x0F;
        if (byteCount == 0x0F) {
          final (count, _) = _readVarint(offset + 1);
          byteCount = count;
        }
        return byteCount;
      case FleeceTag.data:
        final byte0 = bytes[offset];
        return byte0 & 0x0F;
      case FleeceTag.array:
        return _visitArray(offset);
      case FleeceTag.dict:
        return _visitDict(offset);
      default:
        return 0;
    }
  }

  int _visitArray(int offset) {
    final header = _data.getUint16(offset, Endian.big);
    final wide = (header & 0x0800) != 0;
    var count = header & 0x07FF;
    var firstItem = offset + 2;
    if (count == 0x7FF) {
      final (realCount, varintLen) = _readVarint(offset + 2);
      count = realCount;
      firstItem = offset + 2 + varintLen;
      if (firstItem.isOdd) firstItem++;
    }
    final slotSize = wide ? 4 : 2;
    var sink = 0;
    var slotOffset = firstItem;
    for (var i = 0; i < count; i++) {
      final resolved = _resolve(slotOffset, wide: wide);
      sink += _visitAt(resolved);
      slotOffset += slotSize;
    }
    return sink;
  }

  int _visitDict(int offset) {
    final header = _data.getUint16(offset, Endian.big);
    final wide = (header & 0x0800) != 0;
    var count = header & 0x07FF;
    var firstItem = offset + 2;
    if (count == 0x7FF) {
      final (realCount, varintLen) = _readVarint(offset + 2);
      count = realCount;
      firstItem = offset + 2 + varintLen;
      if (firstItem.isOdd) firstItem++;
    }
    final slotSize = wide ? 4 : 2;
    var sink = 0;
    var keySlot = firstItem;
    for (var i = 0; i < count; i++) {
      // Visit key — just read length like C does.
      final keyResolved = _resolve(keySlot, wide: wide);
      final keyByte0 = bytes[keyResolved];
      sink += keyByte0 & 0x0F;
      // Visit value.
      final valueSlot = keySlot + slotSize;
      final valueResolved = _resolve(valueSlot, wide: wide);
      sink += _visitAt(valueResolved);
      keySlot += slotSize * 2;
    }
    return sink;
  }

  /// Compare the string at [offset] with [keyBytes] lexicographically.
  int _compareStringKey(int offset, List<int> keyBytes) {
    final (dataStart, byteCount) = _blobInfo(offset);
    final len = byteCount < keyBytes.length ? byteCount : keyBytes.length;
    for (var i = 0; i < len; i++) {
      final diff = bytes[dataStart + i] - keyBytes[i];
      if (diff != 0) return diff;
    }
    return byteCount - keyBytes.length;
  }
}

/// A reference to a single value within Fleece-encoded data.
final class FleeceValue {
  FleeceValue._(this._decoder, this._offset);

  final FleeceDecoder _decoder;
  final int _offset;

  FleeceValueType get type => _decoder._typeAt(_offset);

  bool get isNull => type == FleeceValueType.null_;
  bool get isUndefined => type == FleeceValueType.undefined;

  bool get asBool => _decoder._boolAt(_offset);
  int get asInt => _decoder._intAt(_offset);
  double get asDouble {
    // If the value is stored as an integer, convert it.
    final tag = _decoder._tag(_offset);
    if (tag == FleeceTag.smallInt || tag == FleeceTag.longInt) {
      return _decoder._intAt(_offset).toDouble();
    }
    return _decoder._doubleAt(_offset);
  }

  String get asString => _decoder._stringAt(_offset);
  Uint8List get asData => _decoder._dataAt(_offset);

  FleeceArray get asArray => FleeceArray._(_decoder, _offset);
  FleeceDict get asDict => FleeceDict._(_decoder, _offset);

  /// Converts this value to a Dart object.
  Object? toObject() => _decoder._toObjectAt(_offset);

  /// Visits every value in the tree without materializing Dart objects. Returns
  /// a checksum-like int (for benchmarking / preventing optimization).
  int visit() => _decoder._visitAt(_offset);
}

/// A Fleece array view.
final class FleeceArray {
  FleeceArray._(this._decoder, this._offset) {
    final (count, wide, firstItem) = _decoder._collectionInfo(_offset);
    _count = count;
    _wide = wide;
    _firstItem = firstItem;
  }

  final FleeceDecoder _decoder;
  final int _offset;
  late final int _count;
  late final bool _wide;
  late final int _firstItem;

  int get length => _count;

  FleeceValue operator [](int index) {
    RangeError.checkValidIndex(index, this, 'index', _count);
    final slotOffset = _decoder._arrayElementOffset(
      _firstItem,
      index: index,
      wide: _wide,
    );
    final resolved = _decoder._resolve(slotOffset, wide: _wide);
    return FleeceValue._(_decoder, resolved);
  }

  List<Object?> toObject() => _decoder._arrayToObject(_offset);
}

/// A Fleece dictionary view.
final class FleeceDict {
  FleeceDict._(this._decoder, this._offset) {
    final (count, wide, firstItem) = _decoder._collectionInfo(_offset);
    _count = count;
    _wide = wide;
    _firstItem = firstItem;
  }

  final FleeceDecoder _decoder;
  final int _offset;
  late final int _count;
  late final bool _wide;
  late final int _firstItem;

  int get length => _count;

  /// Look up a value by string key.
  FleeceValue? operator [](String key) {
    final index = _decoder._dictFindKey(
      _firstItem,
      count: _count,
      wide: _wide,
      key: key,
    );
    if (index < 0) return null;
    final valueOffset = _decoder._dictValueOffset(
      _firstItem,
      index: index,
      wide: _wide,
    );
    final resolved = _decoder._resolve(valueOffset, wide: _wide);
    return FleeceValue._(_decoder, resolved);
  }

  /// Returns all keys in the dict.
  List<String> get keys => List.generate(
    _count,
    (i) => _decoder._dictKeyString(
      _decoder._dictKeyOffset(_firstItem, index: i, wide: _wide),
      wide: _wide,
    ),
  );

  Map<String, Object?> toObject() => _decoder._dictToObject(_offset);
}

// ============================================================================
// Lightweight Extension Type API (zero-allocation navigation)
// ============================================================================

/// The current decoder for the FV/FA/FD extension type API. Set via
/// [runWithFleeceDecoder] so that extension types only carry a [Pointer<Uint8>]
/// instead of a (decoder, offset) tuple.
FleeceDecoder? _currentDecoder;

/// Runs [fn] with [decoder] as the current decoder for the lightweight
/// extension type API ([FV], [FA], [FD]).
T runWithFleeceDecoder<T>(FleeceDecoder decoder, T Function() fn) {
  final previous = _currentDecoder;
  _currentDecoder = decoder;
  try {
    return fn();
  } finally {
    _currentDecoder = previous;
  }
}

/// A zero-allocation reference to a Fleece value — just a pointer.
///
/// The decoder is accessed via the global [_currentDecoder], set by
/// [runWithFleeceDecoder]. This mirrors the C API where FLValue is just a
/// pointer and the document context is implicit.
extension type const FV._(Pointer<Uint8> _ptr) {
  int get _offset => _ptr.address - _currentDecoder!._ptr.address;

  FleeceValueType get type => _currentDecoder!._typeAt(_offset);

  bool get asBool => _currentDecoder!._boolAt(_offset);
  int get asInt => _currentDecoder!._intAt(_offset);
  double get asDouble {
    final decoder = _currentDecoder!;
    final offset = _offset;
    final tag = decoder._tag(offset);
    if (tag == FleeceTag.smallInt || tag == FleeceTag.longInt) {
      return decoder._intAt(offset).toDouble();
    }
    return decoder._doubleAt(offset);
  }

  String get asString => _currentDecoder!._stringAt(_offset);
  Uint8List get asData => _currentDecoder!._dataAt(_offset);

  /// Reinterpret as an array. Zero cost — same underlying pointer.
  FA get asArray => FA._(_ptr);

  /// Reinterpret as a dict. Zero cost — same underlying pointer.
  FD get asDict => FD._(_ptr);

  Object? toObject() => _currentDecoder!._toObjectAt(_offset);
  int visit() => _currentDecoder!._visitAt(_offset);
}

/// A zero-allocation Fleece array view — just a pointer.
extension type const FA._(Pointer<Uint8> _ptr) {
  int get _offset => _ptr.address - _currentDecoder!._ptr.address;

  int get length {
    final decoder = _currentDecoder!;
    final offset = _offset;
    final header = decoder._data.getUint16(offset, Endian.big);
    var count = header & 0x07FF;
    if (count == 0x7FF) {
      final (realCount, _) = decoder._readVarint(offset + 2);
      count = realCount;
    }
    return count;
  }

  FV operator [](int index) {
    final decoder = _currentDecoder!;
    final basePtr = decoder._ptr;
    final offset = _ptr.address - basePtr.address;
    final header = decoder._data.getUint16(offset, Endian.big);
    final wide = (header & 0x0800) != 0;
    var firstItem = offset + 2;
    var count = header & 0x07FF;
    // coverage:ignore-start
    if (count == 0x7FF) {
      final (realCount, varintLen) = decoder._readVarint(offset + 2);
      count = realCount;
      firstItem = offset + 2 + varintLen;
      if (firstItem.isOdd) firstItem++;
    }
    // coverage:ignore-end
    final slotSize = wide ? 4 : 2;
    final slotPtr = basePtr + (firstItem + index * slotSize);
    final resolved = decoder._resolvePtr(slotPtr, wide: wide);
    return FV._(resolved);
  }

  /// Iterates all elements, calling [fn] for each value.
  void forEach(void Function(FV value) fn) {
    final decoder = _currentDecoder!;
    final basePtr = decoder._ptr;
    final offset = _ptr.address - basePtr.address;
    final header = decoder._data.getUint16(offset, Endian.big);
    final wide = (header & 0x0800) != 0;
    var count = header & 0x07FF;
    var firstItem = offset + 2;
    // coverage:ignore-start
    if (count == 0x7FF) {
      final (realCount, varintLen) = decoder._readVarint(offset + 2);
      count = realCount;
      firstItem = offset + 2 + varintLen;
      if (firstItem.isOdd) firstItem++;
    }
    // coverage:ignore-end
    final slotSize = wide ? 4 : 2;
    var slotPtr = basePtr + firstItem;
    for (var i = 0; i < count; i++) {
      final resolved = decoder._resolvePtr(slotPtr, wide: wide);
      fn(FV._(resolved));
      slotPtr = slotPtr + slotSize;
    }
  }
}

/// A zero-allocation Fleece dict view — just a pointer.
extension type const FD._(Pointer<Uint8> _ptr) {
  int get _offset => _ptr.address - _currentDecoder!._ptr.address;

  int get length {
    final decoder = _currentDecoder!;
    final offset = _offset;
    final header = decoder._data.getUint16(offset, Endian.big);
    var count = header & 0x07FF;
    if (count == 0x7FF) {
      final (realCount, _) = decoder._readVarint(offset + 2);
      count = realCount;
    }
    return count;
  }

  /// Iterates all entries, calling [fn] for each key-value pair.
  void forEach(void Function(String key, FV value) fn) {
    final decoder = _currentDecoder!;
    final basePtr = decoder._ptr;
    final offset = _ptr.address - basePtr.address;
    final header = decoder._data.getUint16(offset, Endian.big);
    final wide = (header & 0x0800) != 0;
    var count = header & 0x07FF;
    var firstItem = offset + 2;
    // coverage:ignore-start
    if (count == 0x7FF) {
      final (realCount, varintLen) = decoder._readVarint(offset + 2);
      count = realCount;
      firstItem = offset + 2 + varintLen;
      if (firstItem.isOdd) firstItem++;
    }
    // coverage:ignore-end
    final slotSize = wide ? 4 : 2;
    var keySlotPtr = basePtr + firstItem;
    for (var i = 0; i < count; i++) {
      final keyResolved = decoder._resolvePtr(keySlotPtr, wide: wide);
      final keyOffset = keyResolved.address - basePtr.address;
      final key = decoder._keyStringAt(keyOffset);
      final valueSlotPtr = keySlotPtr + slotSize;
      final valueResolved = decoder._resolvePtr(valueSlotPtr, wide: wide);
      fn(key, FV._(valueResolved));
      keySlotPtr = keySlotPtr + (slotSize * 2);
    }
  }

  FV? operator [](String key) {
    final decoder = _currentDecoder!;
    final basePtr = decoder._ptr;
    final offset = _offset;
    final (count, wide, firstItem) = decoder._collectionInfo(offset);
    final index = decoder._dictFindKey(
      firstItem,
      count: count,
      wide: wide,
      key: key,
    );
    if (index < 0) return null;
    final slotSize = wide ? 4 : 2;
    final valueSlot = firstItem + index * slotSize * 2 + slotSize;
    final valuePtr = basePtr + valueSlot;
    final resolved = decoder._resolvePtr(valuePtr, wide: wide);
    return FV._(resolved);
  }
}

// ============================================================================
// Fleece Encoder
// ============================================================================

/// A pure Dart Fleece encoder.
///
/// Values are written bottom-up: scalars and strings are appended first, then
/// collections are written referencing them via backward pointers.
///
/// This implementation does not support shared keys or delta encoding.
final class PureFleeceEncoder {
  PureFleeceEncoder({bool uniqueStrings = true, int initialCapacity = 1024})
    : _uniqueStrings = uniqueStrings,
      _capacity = initialCapacity,
      _buf = Uint8List(initialCapacity) {
    _bd = ByteData.sublistView(_buf);
  }

  final bool _uniqueStrings;

  // Output buffer — direct write into a growable Uint8List.
  Uint8List _buf;
  late ByteData _bd;
  int _capacity;
  int _bytesWritten = 0;

  // Stack of collection frames.
  final _stack = <_CollectionFrame>[];

  // String deduplication table: string -> offset in output.
  final _stringCache = _StringCache();

  /// Encodes a Dart object tree and returns the Fleece bytes.
  Uint8List encodeDartObject(Object? value) {
    reset();
    writeDartObject(value);
    return finish();
  }

  void reset() {
    _bytesWritten = 0;
    _stack.clear();
    _stringCache.clear();
  }

  Uint8List finish() {
    if (_stack.isNotEmpty) {
      throw StateError('Unclosed collections remain on the stack.');
    }

    if (_bytesWritten < 2) {
      throw StateError('No value was encoded.');
    }
    // Return a copy trimmed to the actual size.
    return Uint8List.fromList(Uint8List.sublistView(_buf, 0, _bytesWritten));
  }

  void writeDartObject(Object? value) {
    if (value == null) {
      writeNull();
    } else if (value is bool) {
      writeBool(value);
    } else if (value is int) {
      writeInt(value);
    } else if (value is double) {
      writeDouble(value);
    } else if (value is String) {
      writeString(value);
    } else if (value is Uint8List) {
      writeData(value);
    } else if (value is List) {
      beginArray(value.length);
      for (final item in value) {
        writeDartObject(item);
      }
      endArray();
    } else if (value is Map) {
      beginDict(value.length);
      for (final entry in value.entries) {
        writeKey(entry.key as String);
        writeDartObject(entry.value);
      }
      endDict();
    } else {
      throw ArgumentError.value(
        value,
        'value',
        'Cannot encode ${value.runtimeType}',
      );
    }
  }

  void writeNull() => _writeSpecial(FleeceSpecial.null_);

  void writeBool(bool value) =>
      _writeSpecial(value ? FleeceSpecial.true_ : FleeceSpecial.false_);

  void writeInt(int value) {
    if (value >= _smallIntMin && value <= _smallIntMax) {
      _writeSmallInt(value);
    } else {
      _writeLongInt(value);
    }
  }

  void writeDouble(double value) {
    // If the value can be represented exactly as an integer, encode as int.
    if (value == value.truncateToDouble() &&
        !value.isInfinite &&
        !value.isNaN) {
      final intVal = value.toInt();
      if (intVal.toDouble() == value &&
          intVal >= -0x8000000000000000 &&
          intVal <= 0x7FFFFFFFFFFFFFFF) {
        writeInt(intVal);
        return;
      }
    }
    // Try 32-bit float first.
    if (!_writeFloat32(value)) {
      _writeFloat64(value);
    }
  }

  void writeString(String value) {
    if (_uniqueStrings) {
      final existing = _stringCache.lookup(value);
      if (existing >= 0) {
        if (_stack.isNotEmpty) {
          _stack.last.addItem(_packRef(existing));
          return;
        }
      }
    }

    final offset = _writeStringDirect(value);

    if (_uniqueStrings) {
      _stringCache.insert(value, offset);
    }
  }

  void writeData(Uint8List value) {
    _writeBlob(FleeceTag.data, value);
  }

  void beginArray(int reserveCount) {
    _stack.add(_CollectionFrame(isDict: false, capacity: reserveCount));
  }

  void endArray() {
    if (_stack.isEmpty || _stack.last.isDict) {
      throw StateError('No matching beginArray.');
    }
    _finalizeCollection();
  }

  void beginDict(int reserveCount) {
    _stack.add(_CollectionFrame(isDict: true, capacity: reserveCount * 2));
  }

  void writeKey(String key) {
    if (_stack.isEmpty || !_stack.last.isDict) {
      throw StateError('writeKey called outside a dict.');
    }
    if (_uniqueStrings) {
      final existing = _stringCache.lookup(key);
      if (existing >= 0) {
        _stack.last.addItem(_packRef(existing));
        return;
      }
    }
    final offset = _writeStringDirect(key);
    if (_uniqueStrings) {
      _stringCache.insert(key, offset);
    }
  }

  void endDict() {
    if (_stack.isEmpty || !_stack.last.isDict) {
      throw StateError('No matching beginDict.');
    }
    _finalizeCollection();
  }

  // --------------------------------------------------------------------------
  // Internal: direct-write encoding helpers (no temporary allocations)
  // --------------------------------------------------------------------------

  /// Writes a 2-byte special value (null, true, false).
  void _writeSpecial(int subtype) {
    final byte0 = (FleeceTag.special << 4) | (subtype << 2);
    if (_stack.isNotEmpty) {
      _stack.last.addItem(_packInline(byte0, 0));
    } else {
      _ensureCapacity(2);
      _buf[_bytesWritten++] = byte0;
      _buf[_bytesWritten++] = 0;
    }
  }

  /// Writes a small int (fits in 2 bytes).
  void _writeSmallInt(int value) {
    final encoded = value & 0x0FFF;
    if (_stack.isNotEmpty) {
      // Big-endian uint16: high byte first.
      _stack.last.addItem(_packInline(encoded >> 8, encoded & 0xFF));
    } else {
      _ensureCapacity(2);
      _bd.setUint16(_bytesWritten, encoded, Endian.big);
      _bytesWritten += 2;
    }
  }

  /// Writes a long int directly into the output buffer.
  void _writeLongInt(int value) {
    int byteCount;
    bool unsigned;
    if (value >= 0) {
      unsigned = value > 0x7FFFFFFFFFFFFFFF;
      if (value <= 0xFF) {
        byteCount = 1;
      } else if (value <= 0xFFFF) {
        byteCount = 2;
      } else if (value <= 0xFFFFFFFF) {
        byteCount = 4;
      } else {
        byteCount = 8;
      }
      if (!unsigned) {
        if (byteCount == 1 && value > 0x7F) byteCount = 2;
        if (byteCount == 2 && value > 0x7FFF) byteCount = 4;
        if (byteCount == 4 && value > 0x7FFFFFFF) byteCount = 8;
      }
    } else {
      unsigned = false;
      if (value >= -0x80) {
        byteCount = 1;
      } else if (value >= -0x8000) {
        byteCount = 2;
      } else if (value >= -0x80000000) {
        byteCount = 4;
      } else {
        byteCount = 8;
      }
    }

    final totalSize = 1 + byteCount;
    final paddedSize = totalSize + (totalSize & 1);

    _align();
    _ensureCapacity(paddedSize);
    final offset = _bytesWritten;

    _buf[_bytesWritten++] =
        (FleeceTag.longInt << 4) | (unsigned ? 0x08 : 0) | (byteCount - 1);

    for (var i = 0; i < byteCount; i++) {
      _buf[_bytesWritten++] = (value >> (8 * i)) & 0xFF;
    }

    if (paddedSize > totalSize) {
      _buf[_bytesWritten++] = 0;
    }

    if (_stack.isNotEmpty) {
      _stack.last.addItem(_packRef(offset));
    }
  }

  /// Tries to write a float32. Returns true if successful.
  bool _writeFloat32(double value) {
    _align();
    _ensureCapacity(6);

    // Test precision directly in the output buffer.
    final dataPos = _bytesWritten + 2;
    _bd.setFloat32(dataPos, value, Endian.little);
    if (_bd.getFloat32(dataPos, Endian.little) != value) {
      return false;
    }

    final offset = _bytesWritten;
    _buf[_bytesWritten++] = FleeceTag.float << 4;
    _buf[_bytesWritten++] = 0;
    // Float32 data already written at dataPos.
    _bytesWritten += 4;

    if (_stack.isNotEmpty) {
      _stack.last.addItem(_packRef(offset));
    }
    return true;
  }

  /// Writes a float64 directly into the output buffer.
  void _writeFloat64(double value) {
    _align();
    _ensureCapacity(10);
    final offset = _bytesWritten;

    _buf[_bytesWritten++] = (FleeceTag.float << 4) | 0x08;
    _buf[_bytesWritten++] = 0;
    _bd.setFloat64(_bytesWritten, value, Endian.little);
    _bytesWritten += 8;

    if (_stack.isNotEmpty) {
      _stack.last.addItem(_packRef(offset));
    }
  }

  /// Computes the UTF-8 byte length of a Dart string without allocating.
  static int _utf8Length(String s) {
    var length = 0;
    for (var i = 0; i < s.length; i++) {
      final codeUnit = s.codeUnitAt(i);
      if (codeUnit < 0x80) {
        length++;
      } else if (codeUnit < 0x800) {
        length += 2;
      } else if (codeUnit >= 0xD800 && codeUnit <= 0xDBFF) {
        // High surrogate — pair with next code unit for a 4-byte sequence.
        length += 4;
        i++; // Skip the low surrogate.
      } else {
        length += 3;
      }
    }
    return length;
  }

  /// Writes a Dart string as a Fleece string value directly into the buffer.
  /// Returns the offset where the string was written.
  int _writeStringDirect(String value) {
    _align();
    final strLen = value.length;

    // Fast path: check if ASCII in one pass. For ASCII strings, UTF-8 length
    // equals string length, so we can skip the separate _utf8Length call.
    var isAscii = true;
    for (var i = 0; i < strLen; i++) {
      if (value.codeUnitAt(i) >= 0x80) {
        isAscii = false;
        break;
      }
    }

    if (isAscii) {
      return _writeAsciiString(value, strLen);
    }
    return _writeNonAsciiString(value, strLen);
  }

  /// Fast path for ASCII-only strings — single pass, no branching per char.
  int _writeAsciiString(String value, int strLen) {
    // For ASCII: utf8Len == strLen.
    int headerSize;
    if (strLen < 0x0F) {
      headerSize = 1;
    } else {
      headerSize = 1 + _varintSize(strLen);
    }
    final totalSize = headerSize + strLen;
    final paddedSize = totalSize + (totalSize & 1);
    _ensureCapacity(paddedSize);
    final offset = _bytesWritten;

    // Write header.
    if (strLen < 0x0F) {
      _buf[_bytesWritten++] = (FleeceTag.string << 4) | strLen;
    } else {
      _buf[_bytesWritten++] = (FleeceTag.string << 4) | 0x0F;
      _writeVarintInline(strLen);
    }

    // Copy ASCII chars directly — each code unit IS the UTF-8 byte.
    for (var i = 0; i < strLen; i++) {
      _buf[_bytesWritten++] = value.codeUnitAt(i);
    }

    if (paddedSize > totalSize) _buf[_bytesWritten++] = 0;

    if (_stack.isNotEmpty) {
      _stack.last.addItem(_packRef(offset));
    }
    return offset;
  }

  /// Slow path for non-ASCII strings — compute UTF-8 length, then encode.
  int _writeNonAsciiString(String value, int strLen) {
    final utf8Len = _utf8Length(value);

    int headerSize;
    if (utf8Len < 0x0F) {
      headerSize = 1;
    } else {
      headerSize = 1 + _varintSize(utf8Len);
    }
    final totalSize = headerSize + utf8Len;
    final paddedSize = totalSize + (totalSize & 1);
    _ensureCapacity(paddedSize);
    final offset = _bytesWritten;

    if (utf8Len < 0x0F) {
      _buf[_bytesWritten++] = (FleeceTag.string << 4) | utf8Len;
    } else {
      _buf[_bytesWritten++] = (FleeceTag.string << 4) | 0x0F;
      _writeVarintInline(utf8Len);
    }

    for (var i = 0; i < strLen; i++) {
      final codeUnit = value.codeUnitAt(i);
      if (codeUnit < 0x80) {
        _buf[_bytesWritten++] = codeUnit;
      } else if (codeUnit < 0x800) {
        _buf[_bytesWritten++] = 0xC0 | (codeUnit >> 6);
        _buf[_bytesWritten++] = 0x80 | (codeUnit & 0x3F);
      } else if (codeUnit >= 0xD800 && codeUnit <= 0xDBFF) {
        final high = codeUnit;
        final low = value.codeUnitAt(++i);
        final codePoint = 0x10000 + ((high - 0xD800) << 10) + (low - 0xDC00);
        _buf[_bytesWritten++] = 0xF0 | (codePoint >> 18);
        _buf[_bytesWritten++] = 0x80 | ((codePoint >> 12) & 0x3F);
        _buf[_bytesWritten++] = 0x80 | ((codePoint >> 6) & 0x3F);
        _buf[_bytesWritten++] = 0x80 | (codePoint & 0x3F);
      } else {
        _buf[_bytesWritten++] = 0xE0 | (codeUnit >> 12);
        _buf[_bytesWritten++] = 0x80 | ((codeUnit >> 6) & 0x3F);
        _buf[_bytesWritten++] = 0x80 | (codeUnit & 0x3F);
      }
    }

    if (paddedSize > totalSize) _buf[_bytesWritten++] = 0;

    if (_stack.isNotEmpty) {
      _stack.last.addItem(_packRef(offset));
    }
    return offset;
  }

  /// Writes a blob (string or binary data) directly into the output buffer.
  /// Returns the offset where the blob was written.
  int _writeBlob(int tag, List<int> payload) {
    _align();

    if (payload.length < 0x0F) {
      // Short form: 1 header byte + payload, padded to 2-byte alignment.
      final totalSize = 1 + payload.length;
      final paddedSize = totalSize + (totalSize & 1);
      _ensureCapacity(paddedSize);
      final offset = _bytesWritten;

      _buf[_bytesWritten++] = (tag << 4) | payload.length;
      for (var i = 0; i < payload.length; i++) {
        _buf[_bytesWritten++] = payload[i];
      }
      if (paddedSize > totalSize) {
        _buf[_bytesWritten++] = 0;
      }

      if (_stack.isNotEmpty) {
        _stack.last.addItem(_packRef(offset));
      }
      return offset;
    } else {
      // Long form: header byte + varint length + payload, padded.
      final varintLen = _varintSize(payload.length);
      final totalSize = 1 + varintLen + payload.length;
      final paddedSize = totalSize + (totalSize & 1);
      _ensureCapacity(paddedSize);
      final offset = _bytesWritten;

      _buf[_bytesWritten++] = (tag << 4) | 0x0F;
      _writeVarintInline(payload.length);
      for (var i = 0; i < payload.length; i++) {
        _buf[_bytesWritten++] = payload[i];
      }
      if (paddedSize > totalSize) {
        _buf[_bytesWritten++] = 0;
      }

      if (_stack.isNotEmpty) {
        _stack.last.addItem(_packRef(offset));
      }
      return offset;
    }
  }

  /// Returns the number of bytes needed to encode [value] as a varint.
  int _varintSize(int value) {
    if (value == 0) return 1;
    var size = 0;
    var v = value;
    while (v > 0) {
      size++;
      v >>= 7;
    }
    return size;
  }

  /// Writes a varint directly into the buffer at \_bytesWritten.
  void _writeVarintInline(int value) {
    if (value == 0) {
      _buf[_bytesWritten++] = 0;
      return;
    }
    var v = value;
    while (v > 0) {
      var byte = v & 0x7F;
      v >>= 7;
      if (v > 0) byte |= 0x80;
      _buf[_bytesWritten++] = byte;
    }
  }

  /// Encodes a varint into a new Uint8List (used only by collection headers).
  Uint8List _encodeVarint(int value) {
    final size = _varintSize(value);
    final bytes = Uint8List(size);
    if (value == 0) return bytes;
    var v = value;
    for (var i = 0; i < size; i++) {
      var byte = v & 0x7F;
      v >>= 7;
      if (v > 0) byte |= 0x80;
      bytes[i] = byte;
    }
    return bytes;
  }

  // --------------------------------------------------------------------------
  // Internal: output management
  // --------------------------------------------------------------------------

  /// Ensure the buffer has room for [needed] more bytes, growing if necessary.
  void _ensureCapacity(int needed) {
    final required = _bytesWritten + needed;
    if (required <= _capacity) return;
    var newCapacity = _capacity;
    while (newCapacity < required) {
      newCapacity *= 2;
    }
    final newBuf = Uint8List(newCapacity);
    newBuf.setRange(0, _bytesWritten, _buf);
    _buf = newBuf;
    _bd = ByteData.sublistView(newBuf);
    _capacity = newCapacity;
  }

  /// Finalize the top collection on the stack and write it to output.
  void _finalizeCollection() {
    final frame = _stack.removeLast();

    if (frame.isDict) {
      _finalizeDictFrame(frame);
      return;
    }

    _finalizeArrayFrame(frame);
  }

  void _finalizeArrayFrame(_CollectionFrame frame) {
    final count = frame.itemCount;

    // Determine if we need wide format.
    final wide = _needsWide(frame, count);
    final slotSize = wide ? 4 : 2;

    // Write directly into the main buffer.
    final headerSize = count >= 0x7FF ? _collectionHeaderSize(count) : 2;
    final bodySize = count * slotSize;
    final totalSize = headerSize + bodySize;

    _align();
    final offset = _bytesWritten;
    _ensureCapacity(totalSize);

    // Write header directly.
    _writeCollectionHeaderDirect(offset, FleeceTag.array, count, wide);

    // Write items directly.
    var pos = offset + headerSize;
    for (var i = 0; i < count; i++) {
      _writeSlotDirect(pos, frame[i], pos, wide);
      pos += slotSize;
    }
    _bytesWritten = offset + totalSize;

    // If we're inside another collection, record a reference.
    if (_stack.isNotEmpty) {
      _stack.last.addItem(_packRef(offset));
    } else {
      // Top-level: write trailing pointer.
      _writeTrailingPointer(offset);
    }
  }

  void _finalizeDictFrame(_CollectionFrame frame) {
    final itemCount = frame.itemCount;
    // Dict items alternate key, value. Must be even count.
    if (itemCount.isOdd) {
      throw StateError(
        'Dict has mismatched keys and values ($itemCount items).',
      );
    }
    final entryCount = itemCount ~/ 2;

    // Sort dict entries in-place by key.
    _sortDictEntries(frame, entryCount);

    final sortedItemCount = entryCount * 2;

    // Check if wide format needed.
    _align();
    final collectionStart = _bytesWritten;
    // coverage:ignore-start
    final headerSize = entryCount >= 0x7FF
        ? _collectionHeaderSize(entryCount)
        : 2;
    // coverage:ignore-end
    var wide = false;
    for (var i = 0; i < sortedItemCount; i++) {
      final packed = frame[i];
      if (!_isInline(packed)) {
        final slotOffset = collectionStart + headerSize + i * 2;
        final backOffset = (slotOffset - _refOffset(packed)) ~/ 2;
        if (backOffset > _narrowPointerMax) {
          wide = true; // coverage:ignore-line
          break; // coverage:ignore-line
        }
      }
    }
    final slotSize = wide ? 4 : 2; // coverage:ignore-line

    final bodySize = sortedItemCount * slotSize;
    final totalSize = headerSize + bodySize;

    // Write directly into the main buffer.
    final offset = _bytesWritten;
    _ensureCapacity(totalSize);

    _writeCollectionHeaderDirect(offset, FleeceTag.dict, entryCount, wide);

    var pos = offset + headerSize;
    for (var i = 0; i < sortedItemCount; i++) {
      _writeSlotDirect(pos, frame[i], pos, wide);
      pos += slotSize;
    }
    _bytesWritten = offset + totalSize;

    if (_stack.isNotEmpty) {
      _stack.last.addItem(_packRef(offset));
    } else {
      _writeTrailingPointer(offset);
    }
  }

  /// Sorts dict entries (key-value pairs) in-place by key.
  void _sortDictEntries(_CollectionFrame frame, int entryCount) {
    // Insertion sort — optimal for the small dicts common in practice.
    for (var i = 1; i < entryCount; i++) {
      final keyPacked = frame[i * 2];
      final valuePacked = frame[i * 2 + 1];
      final keyOffset = _refOffset(keyPacked);
      var j = i - 1;
      while (j >= 0 &&
          _compareKeysAtOffsets(_refOffset(frame[j * 2]), keyOffset) > 0) {
        frame[(j + 1) * 2] = frame[j * 2];
        frame[(j + 1) * 2 + 1] = frame[j * 2 + 1];
        j--;
      }
      frame[(j + 1) * 2] = keyPacked;
      frame[(j + 1) * 2 + 1] = valuePacked;
    }
  }

  bool _needsWide(_CollectionFrame frame, int itemCount) {
    _align();
    final collectionStart = _bytesWritten;
    // coverage:ignore-start
    final headerSize = itemCount >= 0x7FF
        ? _collectionHeaderSize(itemCount)
        : 2;
    // coverage:ignore-end

    for (var i = 0; i < itemCount; i++) {
      final packed = frame[i];
      if (!_isInline(packed)) {
        final slotOffset = collectionStart + headerSize + i * 2;
        final backOffset = (slotOffset - _refOffset(packed)) ~/ 2;
        if (backOffset > _narrowPointerMax) {
          return true; // coverage:ignore-line
        }
      }
    }
    return false;
  }

  // coverage:ignore-start
  int _collectionHeaderSize(int count) {
    if (count < 0x7FF) return 2;
    final varint = _encodeVarint(count);
    final size = 2 + varint.length;
    return size + (size & 1);
  }
  // coverage:ignore-end

  /// Writes a collection header directly into the main buffer at [offset].
  void _writeCollectionHeaderDirect(int offset, int tag, int count, bool wide) {
    if (count < 0x7FF) {
      final header = (tag << 12) | (wide ? 0x0800 : 0) | count;
      _bd.setUint16(offset, header, Endian.big);
    } else {
      // coverage:ignore-start
      final header = (tag << 12) | (wide ? 0x0800 : 0) | 0x7FF;
      _bd.setUint16(offset, header, Endian.big);
      final varint = _encodeVarint(count);
      for (var i = 0; i < varint.length; i++) {
        _buf[offset + 2 + i] = varint[i];
      }
      // coverage:ignore-end
    }
  }

  /// Writes a slot directly into the main buffer at [bufPos].
  void _writeSlotDirect(
    int bufPos,
    int packed,
    int slotOutputOffset,
    bool wide,
  ) {
    if (_isInline(packed)) {
      _buf[bufPos] = _inlineByte0(packed);
      _buf[bufPos + 1] = _inlineByte1(packed);
      if (wide) {
        // coverage:ignore-start
        _buf[bufPos + 2] = 0;
        _buf[bufPos + 3] = 0;
        // coverage:ignore-end
      }
    } else {
      final backOffset = (slotOutputOffset - _refOffset(packed)) ~/ 2;
      if (wide) {
        // coverage:ignore-start
        _bd.setUint32(bufPos, 0x80000000 | backOffset, Endian.big);
        // coverage:ignore-end
      } else {
        _bd.setUint16(bufPos, 0x8000 | backOffset, Endian.big);
      }
    }
  }

  void _writeTrailingPointer(int targetOffset) {
    _align();
    final ptrOffset = _bytesWritten;
    final backOffset = (ptrOffset - targetOffset) ~/ 2;
    if (backOffset <= _narrowPointerMax) {
      _ensureCapacity(2);
      _bd.setUint16(_bytesWritten, 0x8000 | backOffset, Endian.big);
      _bytesWritten += 2;
    } else {
      // coverage:ignore-start
      _ensureCapacity(6);
      final wideBack = (ptrOffset - targetOffset) ~/ 2;
      _bd.setUint32(_bytesWritten, 0x80000000 | wideBack, Endian.big);
      final wideOffset = _bytesWritten;
      _bytesWritten += 4;

      final narrowBack = (_bytesWritten - wideOffset) ~/ 2;
      _bd.setUint16(_bytesWritten, 0x8000 | narrowBack, Endian.big);
      _bytesWritten += 2;
      // coverage:ignore-end
    }
  }

  void _align() {
    if (_bytesWritten.isOdd) {
      _ensureCapacity(1); // coverage:ignore-line
      _buf[_bytesWritten++] = 0; // coverage:ignore-line
    }
  }

  /// Compare two keys by their raw UTF-8 bytes directly from the buffer.
  int _compareKeysAtOffsets(int aOffset, int bOffset) {
    final aStart = _stringDataStart(aOffset);
    final aLen = _stringDataLength(aOffset);
    final bStart = _stringDataStart(bOffset);
    final bLen = _stringDataLength(bOffset);

    final minLen = aLen < bLen ? aLen : bLen;
    for (var i = 0; i < minLen; i++) {
      final diff = _buf[aStart + i] - _buf[bStart + i];
      if (diff != 0) return diff;
    }
    return aLen - bLen;
  }

  /// Returns the byte offset where the string's UTF-8 data begins.
  int _stringDataStart(int offset) {
    final byte0 = _buf[offset];
    final count = byte0 & 0x0F;
    if (count != 0x0F) return offset + 1;
    var i = offset + 1;
    while ((_buf[i] & 0x80) != 0) {
      i++;
    }
    return i + 1;
  }

  /// Returns the UTF-8 byte length of the string at the given offset.
  int _stringDataLength(int offset) {
    final byte0 = _buf[offset];
    final count = byte0 & 0x0F;
    if (count != 0x0F) return count;
    var value = 0;
    var shift = 0;
    var i = offset + 1;
    while (true) {
      final b = _buf[i];
      value |= (b & 0x7F) << shift;
      i++;
      if ((b & 0x80) == 0) break;
      shift += 7;
    }
    return value;
  }
}

// --------------------------------------------------------------------------
// Internal types for collection building
// --------------------------------------------------------------------------

/// Packed item encoding (replaces object allocations): bit 63 = 0 → ref item,
/// bits 0-62 = byte offset in output buffer bit 63 = 1 → inline item, bits 0-15
/// = big-endian uint16 value
const int _inlineFlag = 1 << 63;

int _packInline(int byte0, int byte1) => _inlineFlag | (byte0 << 8) | byte1;
int _packRef(int offset) => offset; // bit 63 is 0 for valid offsets
bool _isInline(int packed) => (packed & _inlineFlag) != 0;
int _inlineByte0(int packed) => (packed >> 8) & 0xFF;
int _inlineByte1(int packed) => packed & 0xFF;
int _refOffset(int packed) => packed & ~_inlineFlag;

final class _CollectionFrame {
  _CollectionFrame({required this.isDict, int capacity = 0})
    : _items = Int64List(capacity > 0 ? capacity : 8);

  final bool isDict;
  Int64List _items;
  int itemCount = 0;

  void addItem(int packed) {
    if (itemCount >= _items.length) {
      final newItems = Int64List(_items.length * 2);
      newItems.setRange(0, itemCount, _items);
      _items = newItems;
    }
    _items[itemCount++] = packed;
  }

  int operator [](int index) => _items[index];
  void operator []=(int index, int value) {
    _items[index] = value;
  }
}

/// Open-addressing hash table for string deduplication. Replaces LinkedHashMap
/// to avoid node allocations and rehash overhead.
final class _StringCache {
  int _size = 0;
  int _capacity = 64;
  int _mask = 63; // _capacity - 1
  var _keys = List<String?>.filled(64, null);
  var _values = Int32List(64);

  void clear() {
    _size = 0;
    if (_capacity > 256) {
      _capacity = 64;
      _mask = 63;
      _keys = List<String?>.filled(64, null);
      _values = Int32List(64);
    } else {
      _keys.fillRange(0, _capacity, null);
    }
  }

  /// Returns the offset for [key], or -1 if not found.
  int lookup(String key) {
    var idx = key.hashCode & _mask;
    while (true) {
      final k = _keys[idx];
      if (k == null) return -1;
      if (k == key) return _values[idx];
      idx = (idx + 1) & _mask;
    }
  }

  void insert(String key, int value) {
    if (_size * 2 >= _capacity) {
      _grow();
    }
    var idx = key.hashCode & _mask;
    while (true) {
      final k = _keys[idx];
      if (k == null) {
        _keys[idx] = key;
        _values[idx] = value;
        _size++;
        return;
      }
      if (k == key) {
        _values[idx] = value;
        return;
      }
      idx = (idx + 1) & _mask;
    }
  }

  void _grow() {
    final oldKeys = _keys;
    final oldValues = _values;
    final oldCapacity = _capacity;
    _capacity *= 2;
    _mask = _capacity - 1;
    _keys = List<String?>.filled(_capacity, null);
    _values = Int32List(_capacity);
    _size = 0;
    for (var i = 0; i < oldCapacity; i++) {
      final k = oldKeys[i];
      if (k != null) {
        insert(k, oldValues[i]);
      }
    }
  }
}

/// Open-addressing hash table for caching decoded strings by integer offset.
/// Used by the decoder to cache dict key strings. Keys are buffer offsets
/// (non-negative integers) which distribute well with simple masking.
final class _IntStringCache {
  int _size = 0;
  int _capacity = 64;
  int _mask = 63;
  var _keys = Int32List(64);
  var _occupied = Uint8List(64); // 0 = empty, 1 = occupied
  var _values = List<String?>.filled(64, null);

  String? lookup(int key) {
    var idx = key & _mask;
    while (true) {
      if (_occupied[idx] == 0) return null;
      if (_keys[idx] == key) return _values[idx];
      idx = (idx + 1) & _mask;
    }
  }

  void insert(int key, String value) {
    if (_size * 2 >= _capacity) _grow();
    var idx = key & _mask;
    while (true) {
      if (_occupied[idx] == 0) {
        _keys[idx] = key;
        _values[idx] = value;
        _occupied[idx] = 1;
        _size++;
        return;
      }
      if (_keys[idx] == key) {
        _values[idx] = value;
        return;
      }
      idx = (idx + 1) & _mask;
    }
  }

  void _grow() {
    final oldKeys = _keys;
    final oldOccupied = _occupied;
    final oldValues = _values;
    final oldCapacity = _capacity;
    _capacity *= 2;
    _mask = _capacity - 1;
    _keys = Int32List(_capacity);
    _occupied = Uint8List(_capacity);
    _values = List<String?>.filled(_capacity, null);
    _size = 0;
    for (var i = 0; i < oldCapacity; i++) {
      if (oldOccupied[i] != 0) {
        insert(oldKeys[i], oldValues[i]!);
      }
    }
  }
}
