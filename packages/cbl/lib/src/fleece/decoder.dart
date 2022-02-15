import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../support/ffi.dart';
import 'shared_strings.dart';

late final _decoderBinds = cblBindings.fleece.decoder;

/// Returns a string which shows how values are encoded in the Fleece [data].
///
/// This method exists for debugging and learning purposes.
String dumpData(Data data) => _decoderBinds.dumpData(data);

/// A decoder for converting Fleece data into Dart objects.
class FleeceDecoder extends Converter<Data, Object?> {
  /// Creates a decoder for converting Fleece data into Dart objects.
  const FleeceDecoder({this.trust = FLTrust.untrusted});

  /// Whether you [trust] the source of the data that it is valid Fleece data.
  ///
  /// If data is not valid, `null` is returned.
  final FLTrust trust;

  @override
  Object? convert(Data input) {
    final sliceResult = input.toSliceResult();
    _decoderBinds.getLoadedFLValueFromData(sliceResult, trust);
    if (!globalLoadedFLValue.ref.exists) {
      return null;
    }

    final listener = _BuildDartObjectListener();
    _FleeceListenerDecoder(SharedStrings(), listener).decodeGlobalLoadedValue();

    cblReachabilityFence(sliceResult);

    return listener.result;
  }
}

/// Fleece decoder which uses a recursive algorithm to decode Fleece data.
///
/// This decoder exists only to benchmark the listener based [FleeceDecoder].
@Deprecated('Use FleeceDecoder instead.')
class RecursiveFleeceDecoder extends Converter<Data, Object?> {
  @Deprecated('Use FleeceDecoder instead.')
  const RecursiveFleeceDecoder({this.trust = FLTrust.untrusted});

  final FLTrust trust;

  @override
  Object? convert(Data input) {
    final sliceResult = input.toSliceResult();

    _decoderBinds.getLoadedFLValueFromData(sliceResult, trust);
    if (!globalLoadedFLValue.ref.exists) {
      return null;
    }

    final result = _decodeGlobalLoadedValue(SharedStrings());

    cblReachabilityFence(sliceResult);

    return result;
  }

  Object? _decodeGlobalLoadedValue(SharedStrings sharedStrings) {
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
          return _decodeGlobalLoadedValue(sharedStrings);
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
          result[key] = _decodeGlobalLoadedValue(sharedStrings);
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
