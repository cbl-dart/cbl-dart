import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cbl_ffi/cbl_ffi.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';

import 'fleece_coding.dart';

// === isDirectory Matcher =====================================================

final isDirectory = const _IsDirectory();

class _IsDirectory extends Matcher {
  const _IsDirectory();

  @override
  Description describe(Description description) =>
      description.add('is directory');

  @override
  bool matches(final Object? item, Map matchState) {
    final String path;
    if (item is FileSystemEntity) {
      path = item.path;
    } else if (item is Uri) {
      path = item.path;
    } else {
      path = item.toString();
    }

    return FileSystemEntity.isDirectorySync(path);
  }
}

// === JSON Matcher ============================================================

/// Returns a [Matcher] wich matches plain Dart objects, JSON strings and
/// Fleece data (in [Slice]s) against [expected], which can be a JSON string or
/// plain Dart objects.
Matcher json(Object? expected) => _JsonMatcher(expected);

class _JsonMatcher extends Matcher {
  static const _actualDecodedKey = 'actualDecoded';

  _JsonMatcher(this.expected);

  final Object? expected;

  late final Object? _decodedExpected =
      expected is String ? _tryToDecodeJson(expected as String) : expected;

  @override
  Description describe(Description description) {
    return description.add('matches JSON\n${_formatJson(_decodedExpected)}');
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (!matchState.containsKey(_actualDecodedKey)) {
      return mismatchDescription;
    }
    final Object? actualDecoded = matchState[_actualDecodedKey];
    return mismatchDescription
        .add('was decoded as\n${_formatJson(actualDecoded)}');
  }

  @override
  bool matches(Object? item, Map matchState) {
    if (item is SliceResult) {
      item = item.asUint8List();
    }

    Object? actual;
    if (item is String) {
      actual = _tryToDecodeJson(item);
      if (item != actual) {
        matchState[_actualDecodedKey] = actual;
      }
    } else if (item is Uint8List) {
      actual = fleeceDecode(item);
      if (actual == null) return false;
      matchState[_actualDecodedKey] = actual;
    }

    return const DeepCollectionEquality().equals(actual, _decodedExpected);
  }

  String _formatJson(Object? json) {
    return const JsonEncoder.withIndent('  ').convert(json);
  }

  Object? _tryToDecodeJson(String json) {
    try {
      return jsonDecode(json);
    } catch (e) {
      return json;
    }
  }
}
