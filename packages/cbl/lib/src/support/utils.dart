import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:characters/characters.dart';

extension ValueExt<T> on T {
  R let<R>(R Function(T it) f) => f(this);
  T also(void Function(T it) f) {
    f(this);
    return this;
  }
}

/// Returns the name of a enum value.
///
/// This is different from what the `toString` method of an enum value returns,
/// in that it does not have the enum name as a prefix.
String describeEnum(Object value) => value.toString().split('.')[1];

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
  var report = '';

  var lineStart = 0;
  var previousCharWasCR = false;
  for (var i = 0; i < offset; i++) {
    var char = string.codeUnitAt(i);
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
    var char = string.codeUnitAt(i);
    if (char == 0x0a || char == 0x0d) {
      lineEnd = i;
      break;
    }
  }
  var length = lineEnd - lineStart;
  var start = lineStart;
  var end = lineEnd;
  var prefix = '';
  var postfix = '';
  if (length > 78) {
    // Can't show entire line. Try to anchor at the nearest end, if
    // one is within reach.
    var index = offset - lineStart;
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
  var slice = string.substring(start, end);
  var markOffset = offset - start + prefix.length;
  return "$report$prefix$slice$postfix\n${" " * markOffset}^\n";
}

class Once<T> {
  Once({
    this.rejectMultipleExecutions = false,
    this.debugName,
  });

  final bool rejectMultipleExecutions;

  final String? debugName;

  bool get hasExecuted => _hasExecuted;
  bool _hasExecuted = false;

  T? get result => _result;
  T? _result;

  void execute(T Function() fn) {
    if (_hasExecuted) {
      if (rejectMultipleExecutions) {
        throw StateError('$_debugName must not be executed more than once.');
      }
      return;
    }
    _result = fn();
    _hasExecuted = true;
  }

  void debugCheckHasExecuted() {
    if (!_hasExecuted) {
      throw StateError('$_debugName has not been executed.');
    }
  }

  String get _debugName => debugName ?? runtimeType.toString();
}

FutureOr<void> iterateMaybeAsync(Iterable<FutureOr<void>> iterable) {
  final iterator = iterable.iterator;
  while (iterator.moveNext()) {
    final result = iterator.current;
    if (result is Future) {
      return result.then((void _) async {
        while (iterator.moveNext()) {
          await iterator.current;
        }
      });
    }
  }
}
