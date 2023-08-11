import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:characters/characters.dart';

typedef StringMap = Map<String, Object?>;

extension StringMapExt on StringMap {
  T getAs<T>(String key) => this[key] as T;
  List<T> getAsList<T>(String key) => (this[key]! as List).cast();
}

extension ValueExt<T> on T {
  R let<R>(R Function(T it) f) => f(this);
  T also(void Function(T it) f) {
    f(this);
    return this;
  }
}

String enumName(Enum value) => value.toString().split('.').first;

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
  const unredactedChars = 3;
  final chars = string.characters;
  final redactedChars =
      max(chars.length - unredactedChars, min(unredactedChars, chars.length));
  final unredactedCharsStr = chars.getRange(redactedChars);
  return ('*' * redactedChars) + unredactedCharsStr.string;
}

/// Highlights a position in a string at the given [offset].
///
/// Adapted from [FormatException.toString].
String highlightPosition(String string, {required int offset}) {
  var lineStart = 0;
  var previousCharWasCR = false;
  for (var i = 0; i < offset; i++) {
    final char = string.codeUnitAt(i);
    if (char == 0x0a) {
      if (lineStart != i || !previousCharWasCR) {}
      lineStart = i + 1;
      previousCharWasCR = false;
    } else if (char == 0x0d) {
      lineStart = i + 1;
      previousCharWasCR = true;
    }
  }
  var lineEnd = string.length;
  for (var i = offset; i < string.length; i++) {
    final char = string.codeUnitAt(i);
    if (char == 0x0a || char == 0x0d) {
      lineEnd = i;
      break;
    }
  }
  final length = lineEnd - lineStart;
  var start = lineStart;
  var end = lineEnd;
  var prefix = '';
  var postfix = '';
  if (length > 78) {
    // Can't show entire line. Try to anchor at the nearest end, if
    // one is within reach.
    final index = offset - lineStart;
    if (index < 75) {
      end = start + 75;
      postfix = '...';
    } else if (end - offset < 75) {
      start = end - 75;
      prefix = '...';
    } else {
      // Neither end is near, just pick an area around the offset.
      start = offset - 36;
      end = offset + 36;
      prefix = postfix = '...';
    }
  }
  final slice = string.substring(start, end);
  final markOffset = offset - start + prefix.length;
  return "$prefix$slice$postfix\n${" " * markOffset}^\n";
}

FutureOr<void> syncOrAsync(Iterable<FutureOr<void>> iterable) {
  final iterator = iterable.iterator;
  while (iterator.moveNext()) {
    final result = iterator.current;
    if (result is Future) {
      // ignore: avoid_types_on_closure_parameters
      return result.then((void _) async {
        while (iterator.moveNext()) {
          await iterator.current;
        }
      });
    }
  }
}

extension FutureOrExt<T> on FutureOr<T> {
  FutureOr<R> then<R>(FutureOr<R> Function(T value) then) {
    final self = this;
    if (self is Future<T>) {
      return self.then(then);
    } else {
      return then(self);
    }
  }

  Future<T> toFuture() => Future.value(this);
}

final _secureRandom = Random.secure();

String createUuid() {
  // Ported from:
  // https://github.com/couchbase/couchbase-lite-ios/blob/c93864c93ab0e2c98e73866502b2f4a6f4c97bfb/Objective-C/Internal/CBLMisc.m#L23
  final bytes = ByteData(17);
  for (var offset = 0; offset < 16; offset += 4) {
    bytes.setUint32(offset, _secureRandom.nextInt(1 << 32));
  }
  bytes.setUint8(16, _secureRandom.nextInt(0xFF));

  var uuid = base64Encode(Uint8List.sublistView(bytes));
  uuid = uuid
      .substring(0, uuid.length - 2)
      .replaceAll('/', '_')
      .replaceAll('+', '-');

  return '-$uuid';
}
