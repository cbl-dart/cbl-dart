import 'dart:collection';
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import '../bindings.dart';
import '../support/ffi.dart';
import 'containers.dart';

final _decoderBinds = cblBindings.fleece.decoder;

/// Returns a string which shows how values are encoded in the Fleece [data].
///
/// This method exists for debugging and learning purposes.
String dumpData(Data data) => _decoderBinds.dumpData(data);

// === SharedKeysTable =========================================================

/// A table which maps shared key ids to their corresponding Dart strings.
abstract class SharedKeysTable {
  factory SharedKeysTable() => _SharedKeysTable();

  const SharedKeysTable._();

  /// A pointer to the [KnownSharedKeys] object of this table, if it actually
  /// makes us of shared kes.
  Pointer<KnownSharedKeys>? get _knownSharedKeys;

  /// Decodes the string currently loaded in [globalLoadedDictKey].
  ///
  /// The given [sharedStringsTable] might be used to decode the string.
  String decode(SharedStringsTable sharedStringsTable);
}

/// A [SharedKeysTable] which does not handle shared keys specially and instead
/// decodes all keys through the [SharedStringsTable].
class NoopSharedKeysTable extends SharedKeysTable {
  const NoopSharedKeysTable() : super._();

  @override
  Pointer<KnownSharedKeys>? get _knownSharedKeys => null;

  @override
  String decode(SharedStringsTable sharedStringsTable) =>
      sharedStringsTable.decode(StringSource.dictKey);
}

class _SharedKeysTable extends SharedKeysTable implements Finalizable {
  _SharedKeysTable() : super._() {
    _knownSharedKeys = _decoderBinds.createKnownSharedKeys(this);
  }

  /// The value [CBLDart_LoadedDictKey.sharedKey] has when the key is not
  /// shared.
  static const _notSharedKey = -1;

  @override
  late final Pointer<KnownSharedKeys> _knownSharedKeys;

  final _sharedKeys = HashMap<int, String>();

  final _loadedKey = globalLoadedDictKey.ref;

  @override
  String decode(SharedStringsTable sharedStringsTable) {
    final sharedKey = _loadedKey.sharedKey;
    if (sharedKey != _notSharedKey) {
      final key = _sharedKeys[sharedKey];
      if (key != null) {
        return key;
      }

      if (_loadedKey.isKnownSharedKey) {
        assert(
          false,
          'Shared key that should have been known is not known. When you use a '
          'DictIterator with SharedKeys you need to call SharedKeys.getKey() '
          'after each DictIterator.moveNext() call.',
        );
        throw Exception();
      } else {
        return _sharedKeys[sharedKey] =
            decodeFLString(_loadedKey.stringBuf, _loadedKey.stringSize);
      }
    } else {
      return sharedStringsTable.decode(StringSource.dictKey);
    }
  }
}

// === SharedStringsTable ======================================================

/// A source to decode strings from.
enum StringSource {
  /// Decode the string currently loaded in [globalLoadedDictKey].
  dictKey,

  /// Decode the string currently loaded in [globalLoadedFLValue].
  value,
}

/// A table which maps the addresses of Fleece strings, which are used multiple
/// times within a Fleece document to corresponding Dart strings.
///
/// Every string that is decoded must be loaded through a [SharedStringsTable].
/// Strings that are not shared are decoded directly when requested.
///
/// A [SharedStringsTable] must only be used with a single instance of immutable
/// Fleece data. It is safe to use a [NoopSharedStringsTable] with mutable
/// Fleece data, though.
abstract class SharedStringsTable {
  /// Creates a new empty [SharedStringsTable].
  factory SharedStringsTable() => _SharedStringsTable();

  const SharedStringsTable._();

  /// Decodes the string currently loaded in [source].
  String decode(StringSource source);

  /// Returns whether the given [string] has been decoded as a shared string.
  bool hasString(String string);
}

/// A [SharedStringsTable] that does not try to cache shared strings and instead
/// decodes a string every time it is requested.
class NoopSharedStringsTable extends SharedStringsTable {
  const NoopSharedStringsTable() : super._();

  @override
  String decode(StringSource source) {
    final int size;
    final int address;
    switch (source) {
      case StringSource.dictKey:
        size = globalLoadedDictKey.ref.stringSize;
        address = globalLoadedDictKey.ref.stringBuf;
        break;
      case StringSource.value:
        size = globalLoadedFLValue.ref.stringSize;
        address = globalLoadedFLValue.ref.stringBuf;
        break;
    }
    return decodeFLString(address, size);
  }

  @override
  bool hasString(String string) => false;
}

class _SharedStringsTable extends SharedStringsTable {
  _SharedStringsTable() : super._();

  // These are the metrics which the Fleece encoder uses when considering
  // strings for sharing. Strings which are not shared must not be stored in
  // this cache.
  //
  // https://github.com/couchbaselabs/fleece/blob/f8923b7916e88551ee17727f56e599cae4dabe52/Fleece/Core/Internal.hh#L78-L79
  static const _minSharedStringSize = 2;
  static const _maxSharedStringSize = 15;

  final _sharedStrings = HashMap<int, String>();

  final _loadedKey = globalLoadedDictKey.ref;
  final _loadedValue = globalLoadedFLValue.ref;

  @override
  String decode(StringSource source) {
    final int size;
    final int address;
    switch (source) {
      case StringSource.dictKey:
        size = _loadedKey.stringSize;
        address = _loadedKey.stringBuf;
        break;
      case StringSource.value:
        size = _loadedValue.stringSize;
        address = _loadedValue.stringBuf;
        break;
    }

    if (size < _minSharedStringSize || size > _maxSharedStringSize) {
      return decodeFLString(address, size);
    }

    return _sharedStrings[address] ??= decodeFLString(address, size);
  }

  @override
  bool hasString(String string) => _sharedStrings.containsValue(string);
}

// === Iterators ===============================================================

// ignore: prefer_void_to_null
class DictIterator implements Iterator<Null>, Finalizable {
  DictIterator(
    Pointer<FLDict> dict, {
    SharedKeysTable? sharedKeysTable,
    Pointer<CBLDart_LoadedDictKey>? keyOut,
    Pointer<CBLDart_LoadedFLValue>? valueOut,
    bool preLoad = true,
    bool partiallyConsumable = true,
  }) : _sharedKeysTable = sharedKeysTable {
    _iterator = _decoderBinds.dictIteratorBegin(
      partiallyConsumable ? this : null,
      dict,
      _sharedKeysTable?._knownSharedKeys ?? nullptr,
      keyOut ?? nullptr,
      valueOut ?? nullptr,
      preLoad: preLoad,
    );
  }

  final SharedKeysTable? _sharedKeysTable;

  late final Pointer<CBLDart_FLDictIterator> _iterator;

  @override
  Null get current => null;

  @override
  bool moveNext() => _decoderBinds.dictIteratorNext(_iterator);
}

// ignore: prefer_void_to_null
class ArrayIterator implements Iterator<Null>, Finalizable {
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
  bool moveNext() => _decoderBinds.arrayIteratorNext(_iterator);
}

// === Decoder =================================================================

/// A decoder for converting Fleece data into Dart objects.
class FleeceDecoder extends Converter<Data, Object?> {
  /// Creates a decoder for converting Fleece data into Dart objects.
  const FleeceDecoder({
    this.trust = FLTrust.untrusted,
    this.sharedKeys,
    this.sharedKeysTable,
    this.sharedStringsTable,
  });

  /// Whether you [trust] the source of the data that it is valid Fleece data.
  ///
  /// If data is not valid, `null` is returned.
  final FLTrust trust;

  final SharedKeys? sharedKeys;
  final SharedKeysTable? sharedKeysTable;
  final SharedStringsTable? sharedStringsTable;

  @override
  Object? convert(Data input) {
    final doc = Doc.fromResultData(input, trust, sharedKeys: sharedKeys);
    final root = doc.root;
    if (root.type == ValueType.undefined) {
      throw ArgumentError('Invalid Fleece data');
    }

    _decoderBinds.getLoadedValue(root.pointer);

    final listener = _BuildDartObjectListener();
    _FleeceListenerDecoder(
      sharedKeysTable ?? const NoopSharedKeysTable(),
      sharedStringsTable ?? SharedStringsTable(),
      listener,
    ).decodeGlobalLoadedValue();

    return listener.result;
  }
}

/// Fleece decoder which uses a recursive algorithm to decode Fleece data.
///
/// This decoder exists only to benchmark the listener based [FleeceDecoder].
@Deprecated('Use FleeceDecoder instead.')
class RecursiveFleeceDecoder extends Converter<Data, Object?> {
  @Deprecated('Use FleeceDecoder instead.')
  RecursiveFleeceDecoder({
    this.trust = FLTrust.untrusted,
    this.sharedKeys,
    SharedKeysTable? sharedKeysTable,
    this.sharedStringsTable,
  }) : sharedKeysTable = sharedKeysTable ??
            (sharedKeys == null
                ? const NoopSharedKeysTable()
                : SharedKeysTable());

  final FLTrust trust;
  final SharedKeys? sharedKeys;
  final SharedKeysTable sharedKeysTable;
  final SharedStringsTable? sharedStringsTable;

  @override
  Object? convert(Data input) {
    final doc = Doc.fromResultData(input, trust, sharedKeys: sharedKeys);
    final root = doc.root;
    if (root.type == ValueType.undefined) {
      throw ArgumentError('Invalid Fleece data');
    }

    _decoderBinds.getLoadedValue(root.pointer);

    return _decodeGlobalLoadedValue(sharedStringsTable ?? SharedStringsTable());
  }

  Object? _decodeGlobalLoadedValue(SharedStringsTable sharedStringsTable) {
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
        return sharedStringsTable.decode(StringSource.value);
      case FLValueType.data:
        return value.asData.toData()?.toTypedList();
      case FLValueType.array:
        final array = Pointer<FLArray>.fromAddress(value.value);
        return List<Object?>.generate(value.collectionSize, (index) {
          _decoderBinds.getLoadedValueFromArray(array, index);
          return _decodeGlobalLoadedValue(sharedStringsTable);
        });
      case FLValueType.dict:
        final result = <String, Object?>{};
        final iterator = DictIterator(
          Pointer<FLDict>.fromAddress(value.value),
          sharedKeysTable: sharedKeysTable,
          keyOut: globalLoadedDictKey,
          valueOut: globalLoadedFLValue,
        );
        while (iterator.moveNext()) {
          final key = sharedKeysTable.decode(sharedStringsTable);
          result[key] = _decodeGlobalLoadedValue(sharedStringsTable);
        }
        return result;
    }
  }
}

Never _throwUndefinedDartRepresentation() =>
    throw UnsupportedError('undefined has not Dart representation');

/// An object that is notified of Fleece decoding events while a Fleece value is
/// deeply decoded.
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
  _FleeceListenerDecoder(
    this._sharedKeysTable,
    this._sharedStringsTable,
    this._listener,
  );

  final SharedKeysTable _sharedKeysTable;
  final SharedStringsTable _sharedStringsTable;
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
              _sharedStringsTable.decode(StringSource.value),
            );
            _currentLoader.handleValue();
            break;
          case FLValueType.data:
            _listener.handleData(value.asData.toData()!.toTypedList());
            _currentLoader.handleValue();
            break;
          case FLValueType.array:
            _currentLoader = _ArrayIndexLoader(
              Pointer<FLArray>.fromAddress(value.value),
              value.collectionSize,
              _listener,
            )..parent = _currentLoader;
            break;
          case FLValueType.dict:
            _currentLoader = _DictIteratorLoader(
              Pointer<FLDict>.fromAddress(value.value),
              _listener,
              _sharedKeysTable,
              _sharedStringsTable,
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
    Pointer<FLDict> dict,
    this._listener,
    this._sharedKeysTable,
    this._sharedStringsTable,
  ) : _it = DictIterator(
          dict,
          sharedKeysTable: _sharedKeysTable,
          keyOut: globalLoadedDictKey,
          valueOut: globalLoadedFLValue,
          partiallyConsumable: false,
        ) {
    _listener.beginObject();
  }

  final _FleeceListener _listener;
  final SharedStringsTable _sharedStringsTable;
  final SharedKeysTable _sharedKeysTable;
  final DictIterator _it;

  @override
  bool loadValue() {
    if (_it.moveNext()) {
      _listener
        ..handleString(_sharedKeysTable.decode(_sharedStringsTable))
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
/// This is a simple stack-based object builder. It keeps the most recently seen
/// value in a variable, and uses it depending on the following event.
class _BuildDartObjectListener extends _FleeceListener {
  /// Read out the final result of parsing a JSON string.
  Object? get result {
    assert(_currentContainer == null);
    return _value;
  }

  /// Stack used to handle nested containers.
  ///
  /// The current container is pushed on the stack when a new one is started. If
  /// the container is a [Map], there is also a current [_key] which is also
  /// stored on the stack.
  final List<Object?> _stack = [];

  /// The current [Map] or [List] being built.
  Object? _currentContainer;

  /// The most recently read property key.
  String _key = '';

  /// The most recently read value.
  Object? _value;

  /// Pushes the currently active container (and key, if a [Map]).
  void _pushContainer() {
    if (_currentContainer is Map) {
      _stack.add(_key);
    }
    _stack.add(_currentContainer);
  }

  /// Pops the top container from the [_stack], including a key if applicable.
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
