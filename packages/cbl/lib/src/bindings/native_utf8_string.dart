import 'dart:ffi';
import 'dart:typed_data';

/// A UTF-8 encoded string in external memory.
class NativeUtf8String {
  NativeUtf8String(this.buffer, this.size, {this.allocator});

  final Pointer<Uint8> buffer;
  final int size;
  final Allocator? allocator;

  void free() {
    allocator?.free(buffer);
  }
}

// =============================================================================
// The code below is the Utf8Encoder from the Dart standard library, adapted
// for encoding directly to external memory.

// coverage:ignore-start

// UTF-8 constants.
const int _oneByteLimit = 0x7f; // 7 bits
const int _twoByteLimit = 0x7ff; // 11 bits
const int _threeByteLimit = 0xffff; // 16 bits
const int _fourByteLimit = 0x10ffff; // 21 bits, truncated to Unicode max.

// UTF-16 constants.
const int _surrogateTagMask = 0xFC00;
const int _surrogateValueMask = 0x3FF;
const int _leadSurrogateMin = 0xD800;
const int _tailSurrogateMin = 0xDC00;

bool _isLeadSurrogate(int codeUnit) =>
    (codeUnit & _surrogateTagMask) == _leadSurrogateMin;
bool _isTailSurrogate(int codeUnit) =>
    (codeUnit & _surrogateTagMask) == _tailSurrogateMin;
int _combineSurrogatePair(int lead, int tail) =>
    0x10000 + ((lead & _surrogateValueMask) << 10) |
    (tail & _surrogateValueMask);

const nativeUtf8StringEncoder = NativeUtf8StringEncoder();

/// A UTF-8 encoder that directly writes to external memory.
///
/// This is more efficient than encoding to Dart memory first and than copying
/// to external memory.
class NativeUtf8StringEncoder {
  /// Creates a UTF-8 encoder that directly writes to external memory.
  const NativeUtf8StringEncoder();

  /// Returns the number of bytes required to encode the given string.
  int encodedAllocationSize(String string) =>
      // Create a buffer with a length that is guaranteed to be big enough.
      // A single code unit uses at most 3 bytes, a surrogate pair at most 4.
      string.length * 3;

  /// Encodes [string] into a [NativeUtf8String], after allocating the required
  /// external memory.
  NativeUtf8String encode(
    String string,
    Allocator allocator, [
    int start = 0,
    int? end,
  ]) {
    // ignore: parameter_assignments
    end = RangeError.checkValidRange(start, end, string.length);

    if (string.isEmpty) {
      return NativeUtf8String(nullptr, 0);
    }

    final allocationSize = encodedAllocationSize(string);
    final buffer = allocator<Uint8>(allocationSize);

    return encodeToBuffer(
      string,
      buffer,
      allocationSize: allocationSize,
      start: start,
      end: end,
      allocator: allocator,
    );
  }

  /// Encodes [string] into a [NativeUtf8String], writing to a pre-allocated
  /// external memory [buffer].
  ///
  /// [allocator] must be the allocator that was used to allocate [buffer].
  NativeUtf8String encodeToBuffer(
    String string,
    Pointer<Uint8> buffer, {
    required int allocationSize,
    int start = 0,
    required int end,
    Allocator? allocator,
  }) {
    final length = end - start;
    if (length == 0) {
      return NativeUtf8String(buffer, 0, allocator: allocator);
    }

    final encoder = _Utf8Encoder(buffer.asTypedList(allocationSize));
    final endPosition = encoder._fillBuffer(string, start, end);
    assert(endPosition >= end - 1);
    if (endPosition != end) {
      // Encoding skipped the last code unit.
      // That can only happen if the last code unit is a leadsurrogate.
      // Force encoding of the lead surrogate by itself.
      final lastCodeUnit = string.codeUnitAt(end - 1);
      assert(_isLeadSurrogate(lastCodeUnit));
      // Write a replacement character to represent the unpaired surrogate.
      encoder._writeReplacementCharacter();
    }

    return NativeUtf8String(buffer, encoder._bufferIndex, allocator: allocator);
  }
}

class _Utf8Encoder {
  _Utf8Encoder(this._buffer);

  int _bufferIndex = 0;
  final Uint8List _buffer;

  /// Write a replacement character (U+FFFD). Used for unpaired surrogates.
  void _writeReplacementCharacter() {
    _buffer[_bufferIndex++] = 0xEF;
    _buffer[_bufferIndex++] = 0xBF;
    _buffer[_bufferIndex++] = 0xBD;
  }

  /// Tries to combine the given [leadingSurrogate] with the [nextCodeUnit] and
  /// writes it to [_buffer].
  ///
  /// Returns true if the [nextCodeUnit] was combined with the
  /// [leadingSurrogate]. If it wasn't, then nextCodeUnit was not a trailing
  /// surrogate and has not been written yet.
  ///
  /// It is safe to pass 0 for [nextCodeUnit], in which case a replacement
  /// character is written to represent the unpaired lead surrogate.
  bool _writeSurrogate(int leadingSurrogate, int nextCodeUnit) {
    if (_isTailSurrogate(nextCodeUnit)) {
      final rune = _combineSurrogatePair(leadingSurrogate, nextCodeUnit);
      // If the rune is encoded with 2 code-units then it must be encoded
      // with 4 bytes in UTF-8.
      assert(rune > _threeByteLimit);
      assert(rune <= _fourByteLimit);
      _buffer[_bufferIndex++] = 0xF0 | (rune >> 18);
      _buffer[_bufferIndex++] = 0x80 | ((rune >> 12) & 0x3f);
      _buffer[_bufferIndex++] = 0x80 | ((rune >> 6) & 0x3f);
      _buffer[_bufferIndex++] = 0x80 | (rune & 0x3f);
      return true;
    } else {
      // Unpaired lead surrogate.
      _writeReplacementCharacter();
      return false;
    }
  }

  /// Fills the [_buffer] with as many characters as possible.
  ///
  /// Does not encode any trailing lead-surrogate. This must be done by the
  /// caller.
  ///
  /// Returns the position in the string. The returned index points to the first
  /// code unit that hasn't been encoded.
  int _fillBuffer(String str, int start, int end) {
    if (start != end && _isLeadSurrogate(str.codeUnitAt(end - 1))) {
      // Don't handle a trailing lead-surrogate in this loop. The caller has
      // to deal with those.
      // ignore: parameter_assignments
      end--;
    }
    int stringIndex;
    for (stringIndex = start; stringIndex < end; stringIndex++) {
      final codeUnit = str.codeUnitAt(stringIndex);
      // ASCII has the same representation in UTF-8 and UTF-16.
      if (codeUnit <= _oneByteLimit) {
        if (_bufferIndex >= _buffer.length) {
          break;
        }
        _buffer[_bufferIndex++] = codeUnit;
      } else if (_isLeadSurrogate(codeUnit)) {
        if (_bufferIndex + 4 > _buffer.length) {
          break;
        }
        // Note that it is safe to read the next code unit. We decremented
        // [end] above when the last valid code unit was a leading surrogate.
        final nextCodeUnit = str.codeUnitAt(stringIndex + 1);
        final wasCombined = _writeSurrogate(codeUnit, nextCodeUnit);
        if (wasCombined) {
          stringIndex++;
        }
      } else if (_isTailSurrogate(codeUnit)) {
        if (_bufferIndex + 3 > _buffer.length) {
          break;
        }
        // Unpaired tail surrogate.
        _writeReplacementCharacter();
      } else {
        final rune = codeUnit;
        if (rune <= _twoByteLimit) {
          if (_bufferIndex + 1 >= _buffer.length) {
            break;
          }
          _buffer[_bufferIndex++] = 0xC0 | (rune >> 6);
          _buffer[_bufferIndex++] = 0x80 | (rune & 0x3f);
        } else {
          assert(rune <= _threeByteLimit);
          if (_bufferIndex + 2 >= _buffer.length) {
            break;
          }
          _buffer[_bufferIndex++] = 0xE0 | (rune >> 12);
          _buffer[_bufferIndex++] = 0x80 | ((rune >> 6) & 0x3f);
          _buffer[_bufferIndex++] = 0x80 | (rune & 0x3f);
        }
      }
    }
    return stringIndex;
  }
}

// coverage:ignore-end
