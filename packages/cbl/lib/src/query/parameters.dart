import 'dart:async';

import '../document.dart';
import '../document/common.dart';
import '../document/dictionary.dart';
import '../fleece/encoder.dart';

/// Query parameters used for setting values to the query parameters defined in
/// the query.
abstract class Parameters {
  /// Creates new [Parameters], optionally initialized with other [parameters].
  factory Parameters([Parameters? parameters]) =>
      ParametersImpl._(source: parameters);

  /// Gets the value of the parameter referenced by the given [name].
  Object? value(String name);

  /// Set a value to the query parameter referenced by the given [name].
  ///
  /// {@template cbl.Parameters.parameterDefinition}
  /// TODO: describe how query parameters are defined.
  /// {@endtemplate}
  void setValue(Object? value, {required String name});

  /// Set a [String] to the query parameter referenced by the given
  /// [name].
  ///
  /// {@macro cbl.Parameters.parameterDefinition}
  void setString(String? value, {required String name});

  /// Set an integer number to the query parameter referenced by the given
  /// [name].
  ///
  /// {@macro cbl.Parameters.parameterDefinition};
  void setInteger(int? value, {required String name});

  /// Set a floating point number to the query parameter referenced by the given
  /// [name].
  ///
  /// {@macro cbl.Parameters.parameterDefinition}
  void setFloat(double? value, {required String name});

  /// Set a [num] to the query parameter referenced by the given [name].
  ///
  /// {@macro cbl.Parameters.parameterDefinition}
  void setNumber(num? value, {required String name});

  /// Set a [bool] to the query parameter referenced by the given [name].
  ///
  /// {@macro cbl.Parameters.parameterDefinition}
  void setBoolean(bool? value, {required String name});

  /// Set a [DateTime] to the query parameter referenced by the given [name].
  ///
  /// {@macro cbl.Parameters.parameterDefinition}
  void setDate(DateTime? value, {required String name});

  /// Set a [Blob] to the query parameter referenced by the given [name].
  ///
  /// {@macro cbl.Parameters.parameterDefinition}
  void setBlob(Blob? value, {required String name});

  /// Set an [Array]  to the query parameter referenced by the given [name].
  ///
  /// {@macro cbl.Parameters.parameterDefinition}
  void setArray(Array? value, {required String name});

  /// Set a [Dictionary] to the query parameter referenced by the given [name].
  ///
  /// {@macro cbl.Parameters.parameterDefinition}
  void setDictionary(Dictionary? value, {required String name});
}

class ParametersImpl implements Parameters, FleeceEncodable {
  ParametersImpl({bool readonly = false}) : this._(readonly: readonly);

  ParametersImpl.from(Parameters source, {bool readonly = false})
      : this._(source: source, readonly: readonly);

  ParametersImpl._({Parameters? source, bool readonly = false})
      : _readonly = readonly {
    if (source != null) {
      final data = (source as ParametersImpl)._data;
      for (final key in data) {
        _data.setValue(data[key], key: key);
      }
    }
  }

  final bool _readonly;
  late final _data = MutableDictionary() as MutableDictionaryImpl;

  @override
  Object? value(String name) => _data[name];

  @override
  void setValue(Object? value, {required String name}) {
    _checkReadonly();
    _data.setValue(value, key: name);
  }

  @override
  void setString(String? value, {required String name}) =>
      setValue(value, name: name);

  @override
  void setInteger(int? value, {required String name}) =>
      setValue(value, name: name);

  @override
  void setFloat(double? value, {required String name}) =>
      setValue(value, name: name);

  @override
  void setNumber(num? value, {required String name}) =>
      setValue(value, name: name);

  @override
  void setBoolean(bool? value, {required String name}) =>
      setValue(value, name: name);

  @override
  void setDate(DateTime? value, {required String name}) =>
      setValue(value, name: name);

  @override
  void setBlob(Blob? value, {required String name}) =>
      setValue(value, name: name);

  @override
  void setArray(Array? value, {required String name}) =>
      setValue(value, name: name);

  @override
  void setDictionary(Dictionary? value, {required String name}) =>
      setValue(value, name: name);

  @override
  FutureOr<void> encodeTo(FleeceEncoder encoder) => _data.encodeTo(encoder);

  void _checkReadonly() {
    if (_readonly) {
      throw StateError('This parameters object is readonly.');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParametersImpl &&
          runtimeType == other.runtimeType &&
          _data == other._data;

  @override
  int get hashCode => _data.hashCode;

  @override
  String toString() => [
        'Parameters(',
        [
          for (final columnName in _data.keys)
            '$columnName: ${_data.value(columnName)}'
        ].join(', '),
        ')'
      ].join();
}
