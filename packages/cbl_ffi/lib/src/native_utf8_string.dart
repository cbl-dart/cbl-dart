import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

/// A UTF-8 encoded string in external memory.
class NativeUtf8String {
  NativeUtf8String(this.allocator, this.buffer, this.size);

  final Allocator allocator;
  final Pointer<Uint8> buffer;
  final int size;

  void free() {
    allocator.free(buffer);
  }
}

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

/// A UTF-8 encoder that directly writes to external memory.
///
/// This is more efficient than encoding to Dart memory first and than copying
/// to external memory.
class NativeUtf8StringEncoder {
  const NativeUtf8StringEncoder();

  NativeUtf8String encode(
    String string,
    Allocator allocator, [
    int start = 0,
    int? end,
  ]) {
    final stringLength = string.length;

    // Create a buffer with a length that is guaranteed to be big enough.
    // A single code unit uses at most 3 bytes, a surrogate pair at most 4.
    // Note that it is not safe to allocate 0 bytes, which is why 1 byte is
    // allocated even for empty strings.
    final maxUtf8Length = max(stringLength * 3, 1);
    final buffer = allocator<Uint8>(maxUtf8Length);
    final bufferList = buffer.asTypedList(maxUtf8Length);

    // ignore: parameter_assignments
    end = RangeError.checkValidRange(start, end, stringLength);
    final length = end - start;
    if (length == 0) {
      return NativeUtf8String(allocator, buffer, 0);
    }

    final encoder = _Utf8Encoder(bufferList);
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

    return NativeUtf8String(allocator, buffer, encoder._bufferIndex);
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
  /// Returns the position in the string. The returned index points to the
  /// first code unit that hasn't been encoded.
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
