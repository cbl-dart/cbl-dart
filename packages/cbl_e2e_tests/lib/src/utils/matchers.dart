import 'dart:convert';
import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/bindings.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:test/test.dart' as test;

import 'fleece_coding.dart';

// === isDirectory Matcher =====================================================

const isDirectory = _IsDirectory();

class _IsDirectory extends Matcher {
  const _IsDirectory();

  @override
  Description describe(Description description) =>
      description.add('is directory');

  @override
  bool matches(Object? item, Map matchState) {
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

/// Returns a [Matcher] wich matches plain Dart objects, JSON strings and Fleece
/// data (in [Slice]s) against [expected], which can be a JSON string or plain
/// Dart objects.
Matcher json(Object? expected) => _JsonMatcher(expected);

class _JsonMatcher extends Matcher {
  _JsonMatcher(this.expected);

  static const _actualDecodedKey = 'actualDecoded';

  final Object? expected;

  late final Object? _decodedExpected =
      // ignore: cast_nullable_to_non_nullable
      expected is String ? _tryToDecodeJson(expected as String) : expected;

  @override
  Description describe(Description description) =>
      description.add('matches JSON\n${_formatJson(_decodedExpected)}');

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
      // ignore: parameter_assignments
      item = item.toTypedList();
    }

    Object? actual;
    if (item is String) {
      actual = _tryToDecodeJson(item);
      if (item != actual) {
        matchState[_actualDecodedKey] = actual;
      }
    } else if (item is Data) {
      actual = fleeceDecode(item);
      if (actual == null) {
        return false;
      }
      matchState[_actualDecodedKey] = actual;
    }

    return const DeepCollectionEquality().equals(actual, _decodedExpected);
  }

  String _formatJson(Object? json) =>
      const JsonEncoder.withIndent('  ').convert(json);

  Object? _tryToDecodeJson(String json) {
    try {
      return jsonDecode(json);
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      return json;
    }
  }
}

// === equality ================================================================

/// Returns a matcher which checks wether the matched value implements mutual
/// equality with [expected].
///
/// Mutual equality is implemented when:
///
/// - `actual == expected`
/// - `expected == actual`
/// - `actual.hashCode == expected.hashCode`
Matcher equality(Object? expected) => _Equality(expected);

enum _EqualityFailure { expected, actual, hash }

class _Equality extends Matcher {
  _Equality(this.expected);

  final Object? expected;

  @override
  Description describe(Description description) =>
      description.add('is mutually equal to ')..addDescriptionOf(expected);

  @override
  bool matches(Object? actual, Map matchState) {
    bool failure(_EqualityFailure failure) {
      matchState['EQUALITY_FAILURE'] = failure;
      return false;
    }

    if (actual != expected) {
      return failure(_EqualityFailure.actual);
    }

    if (expected != actual) {
      return failure(_EqualityFailure.expected);
    }

    if (actual.hashCode != expected.hashCode) {
      return failure(_EqualityFailure.hash);
    }

    return true;
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    final failure = matchState['EQUALITY_FAILURE'] as _EqualityFailure;
    switch (failure) {
      case _EqualityFailure.expected:
        return mismatchDescription.add('expected == actual was not true');
      case _EqualityFailure.actual:
        return mismatchDescription.add('actual == expected was not true');
      case _EqualityFailure.hash:
        return mismatchDescription
            .add('actual.hashCode == expected.hashCode was not true');
    }
  }
}

/// === Errors =================================================================

final isDatabaseException = isA<DatabaseException>();

extension DatabaseExceptionMatcherExt on test.TypeMatcher<DatabaseException> {
  test.TypeMatcher<DatabaseException> havingMessage(String message) =>
      having((it) => it.message, 'message', message);

  test.TypeMatcher<DatabaseException> havingCode(DatabaseErrorCode code) =>
      having((it) => it.code, 'code', code);
}

final throwsNotADatabaseFile = throwsA(
  isDatabaseException.havingCode(DatabaseErrorCode.notADatabaseFile),
);

final isTypedDataException = isA<TypedDataException>();

extension TypedDataExceptionMatcherExt on test.TypeMatcher<TypedDataException> {
  test.TypeMatcher<TypedDataException> havingMessage(String message) =>
      having((it) => it.message, 'message', message);

  test.TypeMatcher<TypedDataException> havingCode(TypedDataErrorCode code) =>
      having((it) => it.code, 'code', code);
}
