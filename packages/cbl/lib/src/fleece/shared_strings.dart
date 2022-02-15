import 'dart:collection';
import 'dart:convert';
import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

/// A cache for strings which are encoded as unique shared strings in Fleece
/// data.
class SharedStrings {
  // These are the metrics which the Fleece encoder uses when considering
  // strings for sharing. Strings which are not shared must not be stored in
  // this cache.
  //
  // https://github.com/couchbaselabs/fleece/blob/f8923b7916e88551ee17727f56e599cae4dabe52/Fleece/Core/Internal.hh#L78-L79
  static const _minSharedStringSize = 2;
  static const _maxSharedStringSize = 15;

  final _addressToDartString = HashMap<int, String?>();

  String sliceToDartString(Slice slice) =>
      _toDartString(slice.size, slice.buf.cast());

  String flStringToDartString(FLString slice) =>
      _toDartString(slice.size, slice.buf);

  String _toDartString(int size, Pointer<Uint8> buf) {
    assert(buf != nullptr);

    if (size < _minSharedStringSize || size > _maxSharedStringSize) {
      return utf8.decode(buf.asTypedList(size));
    }

    return _addressToDartString[buf.address] ??=
        utf8.decode(buf.asTypedList(size));
  }

  bool hasString(String string) => _addressToDartString.containsValue(string);
}
