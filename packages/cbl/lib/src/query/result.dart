import 'dart:collection';

import '../document.dart';
import '../document/array.dart';
import '../document/dictionary.dart';
import '../fleece/fleece.dart' as fl;
import '../fleece/integration/integration.dart';
import '../support/native_object.dart';
import 'query.dart';
import 'result_set.dart';

/// A single row in the [ResultSet] that is created when executing a [Query].
///
// TODO: explain how columns are named
abstract class Result
    implements Iterable<String>, ArrayInterface, DictionaryInterface {
  /// The number of column in this result.
  @override
  int get length;

  /// The names of the columns in this result.
  @override
  List<String> get keys;

  /// Returns the column at the given [keyOrIndex].
  ///
  /// Returns `null` if the column is `null`.
  ///
  /// Throws a [RangeError] if [keyOrIndex] is ouf of range.
  T? value<T extends Object>(Object keyOrIndex);

  /// Returns the column at the given [keyOrIndex] as a [String].
  ///
  /// {@template cbl.Result.typedNullableGetter}
  /// Returns `null` if the value is not a of the expected typ or it is
  /// `null`.
  ///
  /// Throws a [RangeError] if the [keyOrIndex] is ouf of range.
  /// {@endtemplate}
  String? string(Object keyOrIndex);

  /// Returns the column at the given [keyOrIndex] as an integer number.
  ///
  /// {@template cbl.Result.typedDefaultedGetter}
  /// Returns a default value (integer: `0`, double: `0.0`, boolean: `false`)
  /// if the column is not of the expected type or is `null`.
  ///
  /// Throws a [RangeError] if the [keyOrIndex] is ouf of range.
  /// {@endtemplate}
  int integer(Object keyOrIndex);

  /// Returns the column at the given [keyOrIndex] as an floating point number.
  ///
  /// {@macro cbl.Result.typedDefaultedGetter}
  double float(Object keyOrIndex);

  /// Returns the column at the given [keyOrIndex] as a [num].
  ///
  /// {@macro cbl.Result.typedNullableGetter}
  num? number(Object keyOrIndex);

  /// Returns the column at the given [keyOrIndex] as a [bool].
  ///
  /// {@macro cbl.Result.typedDefaultedGetter}
  bool boolean(Object keyOrIndex);

  /// Returns the column at the given [keyOrIndex] as a [DateTime].
  ///
  /// {@macro cbl.Result.typedNullableGetter}
  DateTime? date(Object keyOrIndex);

  /// Returns the column at the given [keyOrIndex] as a [Blob].
  ///
  /// {@macro cbl.Result.typedNullableGetter}
  Blob? blob(Object keyOrIndex);

  /// Returns the column at the given [keyOrIndex] as an [Array].
  ///
  /// {@macro cbl.Result.typedNullableGetter}
  Array? array(Object keyOrIndex);

  /// Returns the column at the given [keyOrIndex] as a [Dictionary].
  ///
  /// {@macro cbl.Result.typedNullableGetter}
  Dictionary? dictionary(Object keyOrIndex);

  /// Returns whether a column with the given [keyOrIndex] exists in this
  /// result.
  @override
  bool contains(Object? keyOrIndex);

  /// Returns a [Fragment] for the column at the given [keyOrIndex].
  Fragment operator [](Object keyOrIndex);

  /// Returns a JSON string which contains a dictionary of the named columns of
  /// this result.
  String toJSON();
}

class ResultImpl with IterableMixin<String> implements Result {
  ResultImpl({
    required MContext context,
    required fl.Array columnValues,
    required List<String> columnNames,
  })  : _context = context,
        _columnValues = columnValues,
        _columnNames = columnNames;

  final MContext _context;
  final fl.Array _columnValues;
  final List<String> _columnNames;

  late final ArrayImpl _array = _createArray();
  late final DictionaryImpl _dictionary = _createDictionary();

  @override
  Iterator<String> get iterator => _columnNames.iterator;

  @override
  List<String> get keys => _columnNames;

  @override
  T? value<T extends Object>(Object keyOrIndex) {
    _debugCheckKeyOrIndex(keyOrIndex);
    if (keyOrIndex is int) {
      return _array.value(keyOrIndex);
    }
    return _dictionary.value(keyOrIndex as String);
  }

  @override
  String? string(Object keyOrIndex) {
    _debugCheckKeyOrIndex(keyOrIndex);
    if (keyOrIndex is int) {
      return _array.string(keyOrIndex);
    }
    return _dictionary.string(keyOrIndex as String);
  }

  @override
  int integer(Object keyOrIndex) {
    _debugCheckKeyOrIndex(keyOrIndex);
    if (keyOrIndex is int) {
      return _array.integer(keyOrIndex);
    }
    return _dictionary.integer(keyOrIndex as String);
  }

  @override
  double float(Object keyOrIndex) {
    _debugCheckKeyOrIndex(keyOrIndex);
    if (keyOrIndex is int) {
      return _array.float(keyOrIndex);
    }
    return _dictionary.float(keyOrIndex as String);
  }

  @override
  num? number(Object keyOrIndex) {
    _debugCheckKeyOrIndex(keyOrIndex);
    if (keyOrIndex is int) {
      return _array.number(keyOrIndex);
    }
    return _dictionary.number(keyOrIndex as String);
  }

  @override
  bool boolean(Object keyOrIndex) {
    _debugCheckKeyOrIndex(keyOrIndex);
    if (keyOrIndex is int) {
      return _array.boolean(keyOrIndex);
    }
    return _dictionary.boolean(keyOrIndex as String);
  }

  @override
  DateTime? date(Object keyOrIndex) {
    _debugCheckKeyOrIndex(keyOrIndex);
    if (keyOrIndex is int) {
      return _array.date(keyOrIndex);
    }
    return _dictionary.date(keyOrIndex as String);
  }

  @override
  Blob? blob(Object keyOrIndex) {
    _debugCheckKeyOrIndex(keyOrIndex);
    if (keyOrIndex is int) {
      return _array.blob(keyOrIndex);
    }
    return _dictionary.blob(keyOrIndex as String);
  }

  @override
  Array? array(Object keyOrIndex) {
    _debugCheckKeyOrIndex(keyOrIndex);
    if (keyOrIndex is int) {
      return _array.array(keyOrIndex);
    }
    return _dictionary.array(keyOrIndex as String);
  }

  @override
  Dictionary? dictionary(Object keyOrIndex) {
    _debugCheckKeyOrIndex(keyOrIndex);
    if (keyOrIndex is int) {
      return _array.dictionary(keyOrIndex);
    }
    return _dictionary.dictionary(keyOrIndex as String);
  }

  @override
  bool contains(Object? keyOrIndex) {
    _debugCheckKeyOrIndex(keyOrIndex);
    if (keyOrIndex is int) {
      return keyOrIndex >= 0 && keyOrIndex < _columnNames.length;
    }
    return _columnNames.contains(keyOrIndex as String);
  }

  @override
  Fragment operator [](Object keyOrIndex) {
    _debugCheckKeyOrIndex(keyOrIndex);
    if (keyOrIndex is int) {
      return _array[keyOrIndex];
    }
    return _dictionary[keyOrIndex as String];
  }

  @override
  List<Object?> toPlainList() => _array.toPlainList();

  @override
  Map<String, dynamic> toPlainMap() => _dictionary.toPlainMap();

  @override
  String toJSON() {
    final encoder = fl.FleeceEncoder();
    final encodeResult = _dictionary.encodeTo(encoder);
    assert(encodeResult is! Future);
    return encoder.finish().toDartString();
  }

  ArrayImpl _createArray() {
    final root = _columnValues.native.call((pointer) => MRoot.fromValue(
          pointer,
          context: _context,
          isMutable: false,
        ));
    return root.asNative as ArrayImpl;
  }

  DictionaryImpl _createDictionary() {
    final dictionary = MutableDictionary() as MutableDictionaryImpl;
    for (var i = 0; i < _columnNames.length; i++) {
      dictionary.setValue(_array.value(i), key: _columnNames[i]);
    }
    return dictionary;
  }

  void _debugCheckKeyOrIndex(Object? keyOrIndex) {
    assert(keyOrIndex is int || keyOrIndex is String);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResultImpl &&
          runtimeType == other.runtimeType &&
          _dictionary == other._dictionary;

  @override
  int get hashCode => _dictionary.hashCode;

  @override
  String toString() => [
        'Result(',
        [
          for (final columnName in this)
            '$columnName: ${_dictionary.value(columnName)}'
        ].join(', '),
        ')'
      ].join();
}
