import 'dart:collection';
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:cbl_ffi/cbl_ffi.dart';
import 'package:meta/meta.dart';

import '../support/ffi.dart';

late final _decoderBinds = cblBindings.fleece.decoder;

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

// === LoadedFLValue ===========================================================

/// A representation of an [FLValue] which can be loaded efficiently.
///
/// Subclasses represent different types of values and include data which
/// is used to efficiently read their content.
///
/// Values wich correspond to [FLValueType.undefined] are represented as `null`
/// in Dart.
@immutable
abstract class LoadedFLValue {
  const LoadedFLValue();
}

class _UndefinedFLValue extends LoadedFLValue {
  const _UndefinedFLValue._();
}

/// A [LoadedFLValue] for a value that is undefined or missing.
const undefinedFLValue = _UndefinedFLValue._();

/// A [LoadedFLValue] for `null`, `boolean` and `number` values.
class SimpleFLValue extends LoadedFLValue {
  const SimpleFLValue(this.value)
      : assert(value == null || value is bool || value is num);

  /// The Dart representation of the [FLValue].
  final Object? value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimpleFLValue &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'SimpleFLValue($value)';
}

/// A base class for [LoadedFLValue]s which contain a [Pointer] to the
/// loaded [FLValue].
abstract class ComplexFLValue extends LoadedFLValue {
  ComplexFLValue(this.value) : assert(value != nullptr);

  /// Pointer to the loaded [FLValue].
  final Pointer<FLValue> value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComplexFLValue &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// A [LoadedFLValue] for `string` and `data` values.
class SliceFLValue extends ComplexFLValue {
  SliceFLValue({
    required this.isString,
    required this.slice,
    required Pointer<FLValue> value,
  }) : super(value);

  /// Whether this value represents a `string` or `data`.
  final bool isString;

  /// The [Slice] which holds the data of this value.
  final Slice slice;

  @override
  String toString() => 'SliceFLValue('
      '${isString ? 'string' : 'data'}, '
      'length: ${slice.size}, '
      // ignore: missing_whitespace_between_adjacent_strings
      'value: $value'
      ')';
}

/// A [LoadedFLValue] for `array` and `dict` values.
class CollectionFLValue extends ComplexFLValue {
  CollectionFLValue({
    required this.isArray,
    required this.length,
    required Pointer<FLValue> value,
  })  : assert(length >= 0),
        super(value);

  /// Whether this value represents an `array` or a `dict`.
  final bool isArray;

  /// The length of the collection.
  final int length;

  @override
  String toString() => 'CollectionFLValue('
      '${isArray ? 'array' : 'dict'}, '
      'length: $length, '
      // ignore: missing_whitespace_between_adjacent_strings
      'value: $value'
      ')';
}

extension on CBLDart_LoadedFLValue {
  LoadedFLValue? toLoadedFLValue() {
    if (!exists) {
      return null;
    }

    switch (type) {
      case FLValueType.undefined:
        return undefinedFLValue;
      case FLValueType.null_:
        return const SimpleFLValue(null);
      case FLValueType.boolean:
        return SimpleFLValue(asBool);
      case FLValueType.number:
        return SimpleFLValue(isInteger ? asInt : asDouble);
      case FLValueType.string:
      case FLValueType.data:
        final isString = type == FLValueType.string;
        return SliceFLValue(
          slice: isString
              ? Slice.fromFLString(asString)!
              : Slice.fromFLSlice(asData)!,
          value: asValue,
          isString: isString,
        );
      case FLValueType.array:
      case FLValueType.dict:
        return CollectionFLValue(
          value: asValue,
          length: collectionSize,
          isArray: type == FLValueType.array,
        );
    }
  }
}

LoadedFLValue? _globalLoadedValueObject() =>
    globalLoadedFLValue.ref.toLoadedFLValue();

// === FleeceDecoder ===========================================================

/// A decoder for efficiently reading Fleece data from Dart.
///
/// You should create a new [FleeceDecoder] with a new instance of
/// [SharedStrings] for each piece of Fleece data. Unless an instance of
/// [SharedStrings] is provided when creating a [FleeceDecoder], a new one will
/// be created.
class FleeceDecoder {
  /// Creates a decoder for efficiently reading Fleece data from Dart.
  FleeceDecoder({SharedStrings? sharedStrings})
      : sharedStrings = sharedStrings ?? SharedStrings();

  /// The [SharedStrings] this decoder is using to read strings from Fleece
  /// data.
  ///
  /// An instance of [SharedStrings] should only be used for decoding a single
  /// piece of Fleece data.
  final SharedStrings sharedStrings;

  /// Returns a string which shows how values are encoded in the Fleece [data].
  ///
  /// This method exists for debugging and learning purposes.
  String dumpData(Data data) => _decoderBinds.dumpData(data);

  // === LoadedFLValue =========================================================

  /// Loads the root value from [data] as a [LoadedFLValue].
  ///
  /// Specify whether you [trust] the source of the [data] to ensure it is valid
  /// Fleece data. If [data] is not valid, `null` is returned.
  LoadedFLValue? loadValueFromData(
    Data data, {
    FLTrust trust = FLTrust.untrusted,
  }) {
    _decoderBinds.getLoadedFLValueFromData(data.toSliceResult(), trust);
    return _globalLoadedValueObject();
  }

  /// Loads [value] as a [LoadedFLValue] or returns `null` if it is
  /// [FLValueType.undefined].
  LoadedFLValue? loadValue(Pointer<FLValue> value) {
    _decoderBinds.getLoadedValue(value);
    return _globalLoadedValueObject();
  }

  /// Loads the value at [index] from [array] as a [LoadedFLValue] or returns
  /// `null` if [index] is out of bounds.
  LoadedFLValue? loadValueFromArray(Pointer<FLArray> array, int index) {
    _decoderBinds.getLoadedValueFromArray(array, index);
    return _globalLoadedValueObject();
  }

  /// Loads the value for [key] from [dict] as a [LoadedFLValue] or returns
  /// `null` there is no entry for [key].
  LoadedFLValue? loadValueFromDict(Pointer<FLDict> dict, String key) {
    _decoderBinds.getLoadedValueFromDict(dict, key);
    return _globalLoadedValueObject();
  }

  // === Conversion to Dart ====================================================

  /// Returns a Dart representation of [data].
  ///
  /// Specify whether you [trust] the source of the [data] to ensure it is valid
  /// Fleece data. If [data] is not valid, `null` is returned.
  Object? dataToDartObject(
    Data data, {
    FLTrust trust = FLTrust.untrusted,
  }) {
    _decoderBinds.getLoadedFLValueFromData(data.toSliceResult(), trust);
    if (!globalLoadedFLValue.ref.exists) {
      return null;
    }

    return _decodeGlobalLoadedValueAsDartObject();
  }

  /// Returns a Dart representation of [data].
  ///
  /// **Note**: This method exists just for benchmarking the listener based
  /// decoder.
  ///
  /// Specify whether you [trust] the source of the [data] to ensure it is valid
  /// Fleece data. If [data] is not valid, `null` is returned.
  @Deprecated('Use dataToDartObject instead.')
  Object? dataToDartObjectRecursively(
    Data data, {
    FLTrust trust = FLTrust.untrusted,
  }) {
    _decoderBinds.getLoadedFLValueFromData(data.toSliceResult(), trust);
    if (!globalLoadedFLValue.ref.exists) {
      return null;
    }

    return _decodeGlobalLoadedValueAsDartObjectRecursively();
  }

  /// Returns a Dart representation of [value].
  Object? loadedValueToDartObject(LoadedFLValue value) {
    if (value == undefinedFLValue) {
      _throwUndefinedDartRepresentation();
    } else if (value is SimpleFLValue) {
      return value.value;
    } else if (value is SliceFLValue) {
      return value.isString
          ? sharedStrings.sliceToDartString(value.slice)
          : Uint8List.fromList(value.slice.asTypedList());
    } else if (value is CollectionFLValue) {
      _decoderBinds.getLoadedValue(value.value);
      return _decodeGlobalLoadedValueAsDartObject();
    } else {
      throw UnimplementedError('Value of unknown type: $value');
    }
  }

  // === Dict Iterable =========================================================

  /// Returns an [Iterable] which iterates over the entries of [dict].
  Iterable<MapEntry<String, LoadedFLValue>> dictIterable(
    Pointer<FLDict> dict,
  ) sync* {
    final it = DictIterator(
      dict,
      keyOut: globalFLString,
      valueOut: globalLoadedFLValue,
    );

    while (it.moveNext()) {
      yield MapEntry(
        sharedStrings.flStringToDartString(globalFLString.ref),
        _globalLoadedValueObject()!,
      );
    }
  }

  /// Returns an [Iterable] which iterates over the keys of [dict].
  Iterable<String> dictKeyIterable(Pointer<FLDict> dict) sync* {
    final it = DictIterator(dict, keyOut: globalFLString);

    while (it.moveNext()) {
      yield sharedStrings.flStringToDartString(globalFLString.ref);
    }
  }

  // === Impl ==================================================================

  Object? _decodeGlobalLoadedValueAsDartObject() {
    final listener = _BuildDartObjectListener();
    _FleeceListenerDecoder(sharedStrings, listener).decodeGlobalLoadedValue();
    return listener.result;
  }

  Object? _decodeGlobalLoadedValueAsDartObjectRecursively() {
    final value = globalLoadedFLValue.ref;
    switch (value.type) {
      case FLValueType.undefined:
        _throwUndefinedDartRepresentation();
      case FLValueType.null_:
        return null;
      case FLValueType.boolean:
        return value.asBool;
      case FLValueType.number:
        return value.isInteger ? value.asInt : value.asDouble;
      case FLValueType.string:
        return sharedStrings.flStringToDartString(value.asString);
      case FLValueType.data:
        return value.asData.toData()?.toTypedList();
      case FLValueType.array:
        final array = value.asValue.cast<FLArray>();
        return List<Object?>.generate(value.collectionSize, (index) {
          _decoderBinds.getLoadedValueFromArray(array, index);
          return _decodeGlobalLoadedValueAsDartObjectRecursively();
        });
      case FLValueType.dict:
        final result = <String, Object?>{};
        final iterator = DictIterator(
          value.asValue.cast(),
          keyOut: globalFLString,
          valueOut: globalLoadedFLValue,
        );
        while (iterator.moveNext()) {
          final key = sharedStrings.flStringToDartString(globalFLString.ref);
          result[key] = _decodeGlobalLoadedValueAsDartObjectRecursively();
        }
        return result;
    }
  }
}

Never _throwUndefinedDartRepresentation() =>
    throw UnsupportedError('undefined has not Dart representation');

// === Iterators ===============================================================

// ignore: prefer_void_to_null
class DictIterator implements Iterator<Null> {
  DictIterator(
    Pointer<FLDict> dict, {
    Pointer<FLString>? keyOut,
    Pointer<CBLDart_LoadedFLValue>? valueOut,
    bool preLoad = true,
    bool partiallyConsumable = true,
  }) {
    _iterator = _decoderBinds.dictIteratorBegin(
      partiallyConsumable ? this : null,
      dict,
      keyOut ?? nullptr,
      valueOut ?? nullptr,
      preLoad: preLoad,
    );
  }

  late final Pointer<CBLDart_FLDictIterator> _iterator;

  @override
  Null get current => null;

  @override
  bool moveNext() {
    final hasCurrent = _decoderBinds.dictIteratorNext(_iterator);
    cblReachabilityFence(this);
    return hasCurrent;
  }
}

// ignore: prefer_void_to_null
class ArrayIterator implements Iterator<Null> {
  ArrayIterator(
    Pointer<FLArray> array, {
    Pointer<CBLDart_LoadedFLValue>? valueOut,
    bool partiallyConsumable = true,
  }) {
    _iterator = _decoderBinds.arrayIteratorBegin(
      partiallyConsumable ? this : null,
      array,
      valueOut ?? nullptr,
    );
  }

  late final Pointer<CBLDart_FLArrayIterator> _iterator;

  @override
  Null get current => null;

  @override
  bool moveNext() {
    final hasCurrent = _decoderBinds.arrayIteratorNext(_iterator);
    cblReachabilityFence(this);
    return hasCurrent;
  }
}

// === Listener decoder ========================================================

/// An object that is notified of Fleece decoding events while a Fleece value
/// is deeply decoded.
abstract class _FleeceListener {
  void handleString(String value) {}
  void handleData(Uint8List value) {}
  void handleNumber(num value) {}
  // ignore: avoid_positional_boolean_parameters
  void handleBool(bool value) {}
  void handleUndefined() {}
  void handleNull() {}
  void beginObject() {}
  void propertyName() {}
  void propertyValue() {}
  void endObject() {}
  void beginArray(int length) {}
  void arrayElement() {}
  void endArray() {}
}

/// A Fleece decoder which deeply decodes a value and notifies a
/// [_FleeceListener] of decoding events.
class _FleeceListenerDecoder {
  _FleeceListenerDecoder(this._sharedStrings, this._listener);

  final SharedStrings _sharedStrings;
  final _FleeceListener _listener;

  _FleeceValueLoader _currentLoader = _InitialValueLoader();

  void decodeGlobalLoadedValue() {
    try {
      final value = globalLoadedFLValue.ref;

      while (true) {
        if (!_currentLoader.loadValue()) {
          final parent = _currentLoader.parent;
          if (parent == null) {
            return;
          }
          _currentLoader = parent;
          _currentLoader.handleValue();

          continue;
        }

        switch (value.type) {
          case FLValueType.undefined:
            _listener.handleUndefined();
            _currentLoader.handleValue();
            break;
          case FLValueType.null_:
            _listener.handleNull();
            _currentLoader.handleValue();
            break;
          case FLValueType.boolean:
            _listener.handleBool(value.asBool);
            _currentLoader.handleValue();
            break;
          case FLValueType.number:
            _listener
                .handleNumber(value.isInteger ? value.asInt : value.asDouble);
            _currentLoader.handleValue();
            break;
          case FLValueType.string:
            _listener.handleString(
                _sharedStrings.flStringToDartString(value.asString));
            _currentLoader.handleValue();
            break;
          case FLValueType.data:
            _listener.handleData(value.asData.toData()!.toTypedList());
            _currentLoader.handleValue();
            break;
          case FLValueType.array:
            _currentLoader = _ArrayIndexLoader(
              value.asValue.cast(),
              value.collectionSize,
              _listener,
            )..parent = _currentLoader;
            break;
          case FLValueType.dict:
            _currentLoader = _DictIteratorLoader(
              value.asValue.cast(),
              _listener,
              _sharedStrings,
            )..parent = _currentLoader;
            break;
        }
      }
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      _drainLoaders();
      rethrow;
    }
  }

  void _drainLoaders() {
    for (_FleeceValueLoader? loader = _currentLoader;
        loader != null;
        loader = loader.parent) {
      loader.drain();
    }
  }
}

abstract class _FleeceValueLoader {
  _FleeceValueLoader? parent;

  bool loadValue();

  void handleValue() {}

  void drain() {}
}

class _InitialValueLoader extends _FleeceValueLoader {
  var _loaded = false;

  @override
  bool loadValue() {
    if (!_loaded) {
      _loaded = true;
      return true;
    } else {
      return false;
    }
  }
}

class _ArrayIndexLoader extends _FleeceValueLoader {
  _ArrayIndexLoader(this._array, this._length, this._listener) {
    _listener.beginArray(_length);
  }

  final Pointer<FLArray> _array;
  final int _length;
  final _FleeceListener _listener;
  var _i = 0;

  @override
  bool loadValue() {
    if (_i < _length) {
      _decoderBinds.getLoadedValueFromArray(_array, _i);
      _i++;
      return true;
    } else {
      _listener.endArray();
      return false;
    }
  }

  @override
  void handleValue() {
    _listener.arrayElement();
  }
}

class _DictIteratorLoader extends _FleeceValueLoader {
  _DictIteratorLoader(
    Pointer<FLDict> _dict,
    this._listener,
    this._sharedStrings,
  ) : _it = DictIterator(
          _dict,
          keyOut: globalFLString,
          valueOut: globalLoadedFLValue,
          partiallyConsumable: false,
        ) {
    _listener.beginObject();
  }

  final _FleeceListener _listener;
  final SharedStrings _sharedStrings;
  final DictIterator _it;
  final _globalFLString = globalFLString.ref;

  @override
  bool loadValue() {
    if (_it.moveNext()) {
      _listener
        ..handleString(_sharedStrings.flStringToDartString(_globalFLString))
        ..propertyName();
      return true;
    } else {
      _listener.endObject();
      return false;
    }
  }

  @override
  void handleValue() {
    _listener.propertyValue();
  }

  @override
  void drain() {
    while (_it.moveNext()) {}
  }
}

/// A [_FleeceListener] that builds data objects from the decoder events.
///
/// This is a simple stack-based object builder. It keeps the most recently
/// seen value in a variable, and uses it depending on the following event.
class _BuildDartObjectListener extends _FleeceListener {
  /// Read out the final result of parsing a JSON string. */
  Object? get result {
    assert(_currentContainer == null);
    return _value;
  }

  /// Stack used to handle nested containers.
  ///
  /// The current container is pushed on the stack when a new one is
  /// started. If the container is a [Map], there is also a current [_key]
  /// which is also stored on the stack.
  final List<Object?> _stack = [];

  /// The current [Map] or [List] being built. */
  Object? _currentContainer;

  /// The most recently read property key. */
  String _key = '';

  /// The most recently read value. */
  Object? _value;

  /// Pushes the currently active container (and key, if a [Map]). */
  void _pushContainer() {
    if (_currentContainer is Map) {
      _stack.add(_key);
    }
    _stack.add(_currentContainer);
  }

  /// Pops the top container from the [_stack], including a key if applicable. */
  void _popContainer() {
    _value = _currentContainer;
    _currentContainer = _stack.removeLast();
    if (_currentContainer is Map) {
      // ignore: cast_nullable_to_non_nullable
      _key = _stack.removeLast() as String;
    }
  }

  @override
  void handleString(String value) {
    _value = value;
  }

  @override
  void handleData(Uint8List value) {
    _value = value;
  }

  @override
  void handleNumber(num value) {
    _value = value;
  }

  @override
  void handleBool(bool value) {
    _value = value;
  }

  @override
  void handleUndefined() {
    _throwUndefinedDartRepresentation();
  }

  @override
  void handleNull() {
    _value = null;
  }

  @override
  void beginObject() {
    _pushContainer();
    _currentContainer = <String, Object?>{};
  }

  @override
  void propertyName() {
    _key = _value! as String;
    _value = null;
  }

  @override
  void propertyValue() {
    final map = _currentContainer! as Map;
    map[_key] = _value;
    _key = '';
    _value = null;
  }

  @override
  void endObject() {
    _popContainer();
  }

  @override
  void beginArray(int length) {
    _pushContainer();
    _currentContainer = <Object?>[];
  }

  @override
  void arrayElement() {
    (_currentContainer! as List).add(_value);
    _value = null;
  }

  @override
  void endArray() {
    _popContainer();
  }
}
