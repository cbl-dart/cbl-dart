import 'dart:collection';
import 'dart:convert';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../document.dart';
import '../document/array.dart';
import '../document/dictionary.dart';
import '../fleece/fleece.dart' as fl;
import '../fleece/integration/integration.dart';
import '../support/native_object.dart';
import 'result_set.dart';

/// A single row in a [ResultSet].
///
/// The name of a column is determined by the first applicable rule of the
/// following rules:
///
/// 1. The alias name of an aliased column.
/// 2. The last component of a property expression. Functions for example,
///    are __not__ property expressions.
/// 3. A generated key of the format `$1`, `$2`, `$3`, ...
///    The number after `$` corresponds to the position of the column among the
///    rest of the unnamed columns and starts at `1`.
abstract class Result
    implements Iterable<String>, ArrayInterface, DictionaryInterface {
  /// The number of column in this result.
  @override
  int get length;

  /// The names of the columns in this result.
  @override
  List<String> get keys;

  /// Returns the column at the given [nameOrIndex].
  ///
  /// Returns `null` if the column is `null`.
  ///
  /// Throws a [RangeError] if [nameOrIndex] is ouf of range.
  T? value<T extends Object>(Object nameOrIndex);

  /// Returns the column at the given [nameOrIndex] as a [String].
  ///
  /// {@template cbl.Result.typedNullableGetter}
  /// Returns `null` if the value is not a of the expected typ or it is
  /// `null`.
  ///
  /// Throws a [RangeError] if the [nameOrIndex] is ouf of range.
  /// {@endtemplate}
  String? string(Object nameOrIndex);

  /// Returns the column at the given [nameOrIndex] as an integer number.
  ///
  /// {@template cbl.Result.typedDefaultedGetter}
  /// Returns a default value (integer: `0`, double: `0.0`, boolean: `false`)
  /// if the column is not of the expected type or is `null`.
  ///
  /// Throws a [RangeError] if the [nameOrIndex] is ouf of range.
  /// {@endtemplate}
  int integer(Object nameOrIndex);

  /// Returns the column at the given [nameOrIndex] as an floating point number.
  ///
  /// {@macro cbl.Result.typedDefaultedGetter}
  double float(Object nameOrIndex);

  /// Returns the column at the given [nameOrIndex] as a [num].
  ///
  /// {@macro cbl.Result.typedNullableGetter}
  num? number(Object nameOrIndex);

  /// Returns the column at the given [nameOrIndex] as a [bool].
  ///
  /// {@macro cbl.Result.typedDefaultedGetter}
  bool boolean(Object nameOrIndex);

  /// Returns the column at the given [nameOrIndex] as a [DateTime].
  ///
  /// {@macro cbl.Result.typedNullableGetter}
  DateTime? date(Object nameOrIndex);

  /// Returns the column at the given [nameOrIndex] as a [Blob].
  ///
  /// {@macro cbl.Result.typedNullableGetter}
  Blob? blob(Object nameOrIndex);

  /// Returns the column at the given [nameOrIndex] as an [Array].
  ///
  /// {@macro cbl.Result.typedNullableGetter}
  Array? array(Object nameOrIndex);

  /// Returns the column at the given [nameOrIndex] as a [Dictionary].
  ///
  /// {@macro cbl.Result.typedNullableGetter}
  Dictionary? dictionary(Object nameOrIndex);

  /// Returns whether a column with the given [nameOrIndex] exists in this
  /// result.
  @override
  bool contains(Object? nameOrIndex);

  /// Returns a [Fragment] for the column at the given [nameOrIndex].
  Fragment operator [](Object nameOrIndex);

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
  T? value<T extends Object>(Object nameOrIndex) {
    _checknameOrIndex(nameOrIndex);
    if (nameOrIndex is int) {
      return _array.value(nameOrIndex);
    }
    return _dictionary.value(nameOrIndex as String);
  }

  @override
  String? string(Object nameOrIndex) {
    _checknameOrIndex(nameOrIndex);
    if (nameOrIndex is int) {
      return _array.string(nameOrIndex);
    }
    return _dictionary.string(nameOrIndex as String);
  }

  @override
  int integer(Object nameOrIndex) {
    _checknameOrIndex(nameOrIndex);
    if (nameOrIndex is int) {
      return _array.integer(nameOrIndex);
    }
    return _dictionary.integer(nameOrIndex as String);
  }

  @override
  double float(Object nameOrIndex) {
    _checknameOrIndex(nameOrIndex);
    if (nameOrIndex is int) {
      return _array.float(nameOrIndex);
    }
    return _dictionary.float(nameOrIndex as String);
  }

  @override
  num? number(Object nameOrIndex) {
    _checknameOrIndex(nameOrIndex);
    if (nameOrIndex is int) {
      return _array.number(nameOrIndex);
    }
    return _dictionary.number(nameOrIndex as String);
  }

  @override
  bool boolean(Object nameOrIndex) {
    _checknameOrIndex(nameOrIndex);
    if (nameOrIndex is int) {
      return _array.boolean(nameOrIndex);
    }
    return _dictionary.boolean(nameOrIndex as String);
  }

  @override
  DateTime? date(Object nameOrIndex) {
    _checknameOrIndex(nameOrIndex);
    if (nameOrIndex is int) {
      return _array.date(nameOrIndex);
    }
    return _dictionary.date(nameOrIndex as String);
  }

  @override
  Blob? blob(Object nameOrIndex) {
    _checknameOrIndex(nameOrIndex);
    if (nameOrIndex is int) {
      return _array.blob(nameOrIndex);
    }
    return _dictionary.blob(nameOrIndex as String);
  }

  @override
  Array? array(Object nameOrIndex) {
    _checknameOrIndex(nameOrIndex);
    if (nameOrIndex is int) {
      return _array.array(nameOrIndex);
    }
    return _dictionary.array(nameOrIndex as String);
  }

  @override
  Dictionary? dictionary(Object nameOrIndex) {
    _checknameOrIndex(nameOrIndex);
    if (nameOrIndex is int) {
      return _array.dictionary(nameOrIndex);
    }
    return _dictionary.dictionary(nameOrIndex as String);
  }

  @override
  bool contains(Object? nameOrIndex) {
    _checknameOrIndex(nameOrIndex);
    if (nameOrIndex is int) {
      return nameOrIndex >= 0 && nameOrIndex < _columnNames.length;
    }
    return _columnNames.contains(nameOrIndex as String);
  }

  @override
  Fragment operator [](Object nameOrIndex) {
    _checknameOrIndex(nameOrIndex);
    if (nameOrIndex is int) {
      return _array[nameOrIndex];
    }
    return _dictionary[nameOrIndex as String];
  }

  @override
  List<Object?> toPlainList() => _array.toPlainList();

  @override
  Map<String, Object?> toPlainMap() => _dictionary.toPlainMap();

  @override
  String toJSON() {
    final encoder = fl.FleeceEncoder(format: FLEncoderFormat.json);
    final encodeResult = _dictionary.encodeTo(encoder);
    assert(encodeResult is! Future);
    return utf8.decode(encoder.finish().asUint8List());
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

  void _checknameOrIndex(Object? nameOrIndex) {
    if (!(nameOrIndex is int || nameOrIndex is String)) {
      throw ArgumentError.value(
        nameOrIndex,
        'nameOrIndex',
        'must be a String or int',
      );
    }
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
