import 'dart:math';
import 'dart:typed_data';

import 'package:characters/characters.dart';

extension ValueExt<T> on T {
  R let<R>(R Function(T) fn) => fn(this);
}

Uint8List jointUint8Lists(List<Uint8List> lists) {
  final length = lists.fold<int>(0, (sum, it) => sum + it.lengthInBytes);
  final result = Uint8List(length);
  var offset = 0;

  for (final list in lists) {
    result.setAll(offset, list);
    offset += list.lengthInBytes;
  }

  return result;
}

String redact(String string) {
  final chars = string.characters;
  final unredactedChars = 3;
  final redactedChars =
      max(chars.length - 3, min(unredactedChars, chars.length));
  final unredactedCharsStr = chars.getRange(redactedChars);
  return ('*' * redactedChars) + unredactedCharsStr.string;
}
