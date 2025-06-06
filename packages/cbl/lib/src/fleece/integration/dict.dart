import 'dart:ffi';

import '../../bindings.dart';
import '../decoder.dart';
import '../dict_key.dart';
import '../encoder.dart';
import 'collection.dart';
import 'value.dart';

final class MDict extends MCollection {
  MDict() : _dict = null, _values = {}, _length = 0, _valuesHasAllKeys = true;

  MDict.asCopy(MDict super.original, {bool? isMutable})
    : _dict = original._dict,
      _values = Map.fromEntries(
        original._values.entries.map(
          (entry) => MapEntry(entry.key, entry.value.clone()),
        ),
      ),
      _length = original._length,
      _valuesHasAllKeys = original._valuesHasAllKeys,
      super.asCopy(isMutable: isMutable ?? original.isMutable);

  MDict.asChild(super.slot, super.parent, int length, {bool? isMutable})
    : _dict = slot.value!.cast(),
      _values = {},
      _length = length,
      _valuesHasAllKeys = false,
      super.asChild(isMutable: isMutable ?? parent.hasMutableChildren);

  final FLDict? _dict;
  final Map<String, MValue> _values;
  int _length;

  /// Whether [_values] contains all the keys of [_dict].
  bool _valuesHasAllKeys;

  int get length => _length;

  bool contains(String key) => _getValue(key).isNotEmpty;

  MValue? get(String key) {
    final value = _getValue(key);
    return value.isNotEmpty ? value : null;
  }

  void set(String key, Object? native) {
    assert(isMutable);

    markMutated();
    final value = _getValue(key);
    if (value.isEmpty) {
      _length++;
    }
    value.setNative(native, this);
  }

  void remove(String key) {
    assert(isMutable);

    final value = _getValue(key);
    if (value.isNotEmpty) {
      markMutated();
      value.setEmpty();
      _length--;
    }
  }

  void clear() {
    assert(isMutable);

    if (_length == 0) {
      return;
    }

    // Clear out all entires.
    markMutated();
    for (final value in _values.values) {
      value.removeFromParent();
    }
    _values.clear();
    _length = 0;

    // Shadow all keys in _dict with empty MValue.
    if (!_valuesHasAllKeys) {
      _valuesHasAllKeys = true;
      final sharedKeysTable = context.sharedKeysTable;
      final sharedStringsTable = context.sharedStringsTable;
      final it = DictIterator(
        _dict!,
        sharedKeysTable: sharedKeysTable,
        keyOut: globalLoadedDictKey,
        partiallyConsumable: false,
      );
      while (it.moveNext()) {
        final key = sharedKeysTable.decode(sharedStringsTable);
        _values[key] = MValue.empty();
      }
      cblReachabilityFence(context);
    }
  }

  @override
  void performEncodeTo(FleeceEncoder encoder) {
    if (!isMutated) {
      encoder.writeValue(_dict!.cast());
    } else {
      final extraInfo = encoder.extraInfo;
      final dictKeys = extraInfo is DictKeysProvider
          ? extraInfo.dictKeys
          : null;
      // ignore: omit_local_variable_types
      final void Function(String) writeKey = dictKeys != null
          ? (key) => dictKeys.getKey(key).encodeTo(encoder)
          : encoder.writeKey;

      encoder.beginDict(length);
      _forEach((key, value) {
        if (value is _MValueWithKey) {
          encoder.writeKeyValue(value.key);
        } else {
          writeKey(key);
        }
        if (value.hasValue) {
          encoder.writeValue(value.value!);
        } else {
          value.encodeTo(encoder);
        }
      });
      encoder.endDict();
    }
  }

  @override
  Iterable<MValue> get values => _values.values;

  Iterable<MapEntry<String, MValue>> get iterable sync* {
    // Iterate over entries in _values.
    for (final entry in _values.entries) {
      // Empty MValues represent that the entry was removed.
      if (entry.value.isNotEmpty) {
        yield entry;
      }
    }

    // _values shadows all keys in _dict so there is no use in iterating _dict.
    if (_valuesHasAllKeys) {
      return;
    }

    // Iterate over entries in _dict.
    final sharedKeysTable = context.sharedKeysTable;
    final sharedStringsTable = context.sharedStringsTable;
    final it = DictIterator(
      _dict!,
      sharedKeysTable: sharedKeysTable,
      keyOut: globalLoadedDictKey,
      valueOut: globalLoadedFLValue,
      preLoad: false,
      partiallyConsumable: false,
    );
    final loadedKey = globalLoadedDictKey.ref;
    final loadedValue = globalLoadedFLValue.ref;
    while (it.moveNext()) {
      final key = sharedKeysTable.decode(sharedStringsTable);

      // Skip over entries which are shadowed by _values
      if (_values.containsKey(key)) {
        continue;
      }

      // Cache the value to speed up lookups later.
      final value = _values[key] = _MValueWithKey(
        loadedKey.value,
        loadedValue.value.cast(),
      );
      yield MapEntry(key, value);
    }

    _valuesHasAllKeys = true;

    cblReachabilityFence(context);
  }

  @pragma('vm:prefer-inline')
  void _forEach(void Function(String key, MValue value) action) {
    // Iterate over entries in _values.
    _values.forEach((key, value) {
      // Empty MValues represent that the entry was removed.
      if (value.isNotEmpty) {
        action(key, value);
      }
    });

    // _values shadows all keys in _dict so there is no use in iterating _dict.
    if (_valuesHasAllKeys) {
      return;
    }

    // Iterate over entries in _dict.
    final sharedKeysTable = context.sharedKeysTable;
    final sharedStringsTable = context.sharedStringsTable;
    final it = DictIterator(
      _dict!,
      sharedKeysTable: sharedKeysTable,
      keyOut: globalLoadedDictKey,
      valueOut: globalLoadedFLValue,
      preLoad: false,
      partiallyConsumable: false,
    );
    final loadedKey = globalLoadedDictKey.ref;
    final loadedValue = globalLoadedFLValue.ref;
    while (it.moveNext()) {
      final key = sharedKeysTable.decode(sharedStringsTable);

      // Skip over entries which are shadowed by _values
      if (_values.containsKey(key)) {
        continue;
      }

      // Cache the value to speed up lookups later.
      final value = _values[key] = _MValueWithKey(
        loadedKey.value,
        loadedValue.value,
      );
      action(key, value);
    }

    _valuesHasAllKeys = true;

    cblReachabilityFence(context);
  }

  MValue _getValue(String key) =>
      _values[key] ??= (_loadValue(key) ?? MValue.empty())..updateParent(this);

  MValue? _loadValue(String key) {
    final dict = _dict;
    if (dict == null) {
      return null;
    }

    final flValue = context.dictKeys.getKey(key).getValue(dict);
    cblReachabilityFence(context);
    if (flValue == null) {
      return null;
    }
    return MValue.withValue(flValue);
  }
}

final class _MValueWithKey extends MValue {
  _MValueWithKey(this.key, FLValue value) : super.withValue(value);

  final FLValue key;
}
