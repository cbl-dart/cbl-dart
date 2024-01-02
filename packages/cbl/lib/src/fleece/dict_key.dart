import 'dart:collection';
import 'dart:ffi';
import 'dart:math';

import '../bindings.dart';
import '../support/ffi.dart';
import 'encoder.dart';

final _dictBinds = cblBindings.fleece.dict;
final _dictKeyBinds = cblBindings.fleece.dictKey;

/// A Fleece dictionary key for efficient decoding and encoding of dictionaries.
abstract class DictKey {
  /// Returns the value associated with this key in the given dictionary.
  Pointer<FLValue>? getValue(Pointer<FLDict> dict);

  /// Encodes this key into a Fleece dictionary.
  void encodeTo(FleeceEncoder encoder);
}

class _DartStringDictKey extends DictKey {
  _DartStringDictKey(this.key);

  final String key;

  @override
  Pointer<FLValue>? getValue(Pointer<FLDict> dict) => _dictBinds.get(dict, key);

  @override
  void encodeTo(FleeceEncoder encoder) {
    encoder.writeKey(key);
  }
}

class _OptimizedDictKey extends DictKey {
  factory _OptimizedDictKey(String key) {
    final utf8StringSize = nativeUtf8StringEncoder.encodedAllocationSize(key);
    final totalSize = _utf8StringStart + utf8StringSize;
    final memory = SliceResult(totalSize);

    final memoryBuffer = memory.buf;
    final flDictKey = memoryBuffer.elementAt(_flDictKeyStart).cast<FLDictKey>();
    final flString = memoryBuffer.elementAt(_flStringStart).cast<FLString>();
    final utf8String = memoryBuffer.elementAt(_utf8StringStart);

    final encodedString = nativeUtf8StringEncoder.encodeToBuffer(
      key,
      utf8String,
      allocationSize: utf8StringSize,
      end: key.length,
    );

    final flStringRef = flString.ref
      ..buf = utf8String
      ..size = encodedString.size;

    _dictKeyBinds.init(flDictKey.ref, flStringRef);

    return _OptimizedDictKey._(memory, flDictKey, flStringRef);
  }

  _OptimizedDictKey._(this._memory, this._flDictKey, this._flString);

  static const _flDictKeyStart = 0;
  static final _flDictKeySize = sizeOf<FLDictKey>();
  static final _flDictKeyPadding = _flDictKeySize % sizeOf<IntPtr>();

  static final _flStringStart =
      _flDictKeyStart + _flDictKeySize + _flDictKeyPadding;
  static final _flStringSize = sizeOf<FLString>();
  static final _flStringPadding = _flStringSize % sizeOf<IntPtr>();

  static final _utf8StringStart =
      _flStringStart + _flStringSize + _flStringPadding;

  final SliceResult _memory;
  // ignore: unused_field
  final Pointer<FLDictKey> _flDictKey;
  final FLString _flString;

  @override
  Pointer<FLValue>? getValue(Pointer<FLDict> dict) {
    // TODO(blaugold): Reenable use of `FLDictKey`s when we know how to safely
    // use them.
    // https://github.com/cbl-dart/cbl-dart/issues/329
    // https://github.com/couchbase/couchbase-lite-C/issues/287
    // final flValue = _dictKeyBinds.getWithKey(dict, _flDictKey);

    final flValue = _dictBinds.getWithFLString(dict, _flString);
    cblReachabilityFence(_memory);
    return flValue;
  }

  @override
  void encodeTo(FleeceEncoder encoder) {
    encoder.writeKeyFLString(_flString);
    cblReachabilityFence(_memory);
  }
}

/// An object which might be able to provide [DictKeys].
abstract class DictKeysProvider {
  /// The [DictKeys] associated with this object, if available.
  DictKeys? get dictKeys;
}

/// A provider of [DictKey]s.
///
/// A [DictKeys] instance must only be used for Fleece data that shares the same
/// set of shared keys.
// ignore: one_member_abstracts
abstract class DictKeys {
  const DictKeys();

  /// Returns a [DictKey] for the given [key].
  ///
  /// The returned value should not be stored, as subsequent calls might return
  /// a different [DictKey].
  DictKey getKey(String key);
}

/// A provider of [DictKey]s that does not use optimized keys.
class UnoptimizingDictKeys extends DictKeys {
  const UnoptimizingDictKeys();

  @override
  DictKey getKey(String key) => _DartStringDictKey(key);
}

/// A provider of [DictKey]s that uses optimized keys for keys that are
/// requested multiple times.
class OptimizingDictKeys extends DictKeys {
  /// The number of times a key needs to be requested before it is optimized.
  static const _optimizationThreshold = 3;

  /// The size of the cache for optimized keys.
  ///
  /// 2048 was chosen because that is the maximum number of shared keys that can
  /// be used in Fleece dictionaries.
  static const _optimizedKeyCacheSize = 2048;

  /// The size of the table to record optimized key misses in.
  ///
  /// When the table is full entries with the least misses are removed first.
  /// Multiple entries with the same number of misses are removed in a random
  /// order.
  ///
  /// Note that even if keys are accessed in a deterministic order, there is no
  /// danger of keys never getting cached. This is mitigated by the fact that
  /// keys with the same number of misses are removed randomly.
  static const _optimizedKeyMissesTableSize = 16;

  /// The number of times a key has been requested before it has been optimized.
  final _optimizedKeyMisses = HashMap<String, int>();

  /// The cached optimized keys.
  ///
  /// This needs to be a LinkedHashMap because we want to remove the oldest keys
  /// first when the cache is full.
  final _optimizedKeyCache = <String, _OptimizedDictKey>{};

  @override
  DictKey getKey(String key) {
    final optimizedKey = _optimizedKeyCache[key];
    if (optimizedKey != null) {
      return optimizedKey;
    }

    if (_shouldOptimizeKey(key)) {
      final optimizedKey = _OptimizedDictKey(key);
      _addKeyToCache(key, optimizedKey);
      return optimizedKey;
    } else {
      return _DartStringDictKey(key);
    }
  }

  bool _shouldOptimizeKey(String key) {
    final optimizedKeyMisses = (_optimizedKeyMisses[key] ?? 0) + 1;
    if (optimizedKeyMisses < _optimizationThreshold) {
      if (_optimizedKeyMisses.length == _optimizedKeyMissesTableSize) {
        _randomlyRemoveMinValue(_optimizedKeyMisses);
      }

      _optimizedKeyMisses[key] = optimizedKeyMisses;
      return false;
    } else {
      _optimizedKeyMisses.remove(key);
      return true;
    }
  }

  void _addKeyToCache(String key, _OptimizedDictKey optimizedKey) {
    if (_optimizedKeyCache.length == _optimizedKeyCacheSize) {
      // We've reached the cache size. Remove the oldest key.
      _optimizedKeyCache.remove(_optimizedKeyCache.keys.first);
    }

    _optimizedKeyCache[key] = optimizedKey;
  }
}

final _random = Random();

void _randomlyRemoveMinValue(Map<String, int> table) {
  assert(table.isNotEmpty);

  int? minValue;
  var keysWithSameMinValue = 0;
  for (final value in table.values) {
    if (minValue == null) {
      minValue = value;
    } else if (value < minValue) {
      minValue = value;
      keysWithSameMinValue = 0;
    } else if (value == minValue) {
      keysWithSameMinValue++;
    }
  }

  final indexOfValueToRemove =
      keysWithSameMinValue == 0 ? 0 : _random.nextInt(keysWithSameMinValue);
  var i = 0;
  for (final entry in table.entries) {
    if (entry.value == minValue) {
      if (i == indexOfValueToRemove) {
        table.remove(entry.key);
        break;
      }
      i++;
    }
  }
}
