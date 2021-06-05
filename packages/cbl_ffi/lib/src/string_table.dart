import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';

import 'fleece.dart';

class StringTable {
  StringTable({
    this.maxCacheSize = 1024,
    this.minCachedStringSize = 0,
    this.maxCachedStringSize = 1024,
  });

  // Config

  final int maxCacheSize;
  final int minCachedStringSize;
  final int maxCachedStringSize;

  // Stats

  int get cachedStrings => _lruList.length;

  int get cacheSize =>
      _lruList.fold(0, (sum, string) => sum + string.sizeEncoded);

  int get cacheHits => _cacheHits;
  int _cacheHits = 0;

  int get cacheMisses => _cacheMisses;
  int _cacheMisses = 0;

  // Allocation

  // TODO: Avoid passing C strings to native methods where possible, to avoid
  // iterating over string to find length. Instead use FLStrings which include
  // the string length.
  Pointer<Utf8> cString(
    String? string, {
    bool cache = true,
    bool arena = false,
  }) =>
      string == null
          ? nullptr
          : encodedString(string, cache: cache, arena: arena).asNullTerminated;

  Pointer<FLSlice> flString(
    String string, {
    bool cache = true,
    bool arena = false,
  }) =>
      encodedString(string, cache: cache, arena: arena).asSlice;

  EncodedString encodedString(
    String string, {
    bool cache = true,
    bool arena = false,
  }) {
    assert(!_debugIsDisposed);

    EncodedString result;
    if (_map.containsKey(string)) {
      result = _map[string]!;
      result.retain();
      _cacheHits++;
    } else {
      result = _map[string] = EncodedString(string);
      _cacheMisses++;
    }

    if (cache) {
      _recordUse(result);
    }

    if (!arena) {
      _autoFree?.add(string);
    } else {
      zoneArena.onReleaseAll(() => free(string));
    }

    return result;
  }

  // Deallocation

  void free(String string) {
    assert(!_debugIsDisposed);

    _release(_map[string]!);
  }

  List<String>? _autoFree;

  T autoFree<T>(T Function() f) {
    _autoFree = [];
    try {
      return f();
    } finally {
      _autoFree!.forEach(free);
      _autoFree = null;
    }
  }

  // Admin

  void dispose() {
    assert(!_debugIsDisposed);
    _debugIsDisposed = true;

    assert((() {
      _map.values.forEach((string) {
        assert(
          string.refs == 1,
          'string has not been freed: $string',
        );
      });
      return true;
    })());

    _map.clear();
    _lruList.forEach(_release);
  }

  // Object

  @override
  String toString() => 'StringCoding('
      'maxCacheSize: $maxCacheSize, '
      'minCachedStringSize: $minCachedStringSize, '
      'maxCachedStringSize: $maxCachedStringSize, '
      'cachedStrings: $cachedStrings, '
      'cacheSize: $cacheSize bytes, '
      'cacheHits: $cacheHits, '
      'cacheMisses: $cacheMisses'
      ')';

  // Debugging

  var _debugIsDisposed = false;

  // Impl

  final _map = <String, EncodedString>{};
  final _lruList = <EncodedString>[];

  void _recordUse(EncodedString string) {
    // Caching is disabled.
    if (maxCacheSize == 0) return;

    // Filter out strings which are not cached because of their size.
    final sizeEncoded = string.sizeEncoded;
    if (sizeEncoded < minCachedStringSize ||
        sizeEncoded > maxCachedStringSize) {
      return;
    }

    // Move the string to the front of the lru list and retain it if it is being
    // added to the cache.
    if (!_lruList.remove(string)) {
      string.retain();
    }
    _lruList.insert(0, string);

    // Remove the least recently used string if the cache is full.
    if (_lruList.length > maxCacheSize) {
      _release(_lruList.removeLast());
    }
  }

  void _release(EncodedString string) {
    string.release();
    if (string.isFreed) {
      _map.remove(string.string);
    }
  }
}

class EncodedString {
  static final sliceSize = sizeOf<FLSlice>();
  static final sliceSizeAligned = sliceSize + (sliceSize % 8);

  EncodedString(String string) : string = string {
    final encoded = utf8.encode(string);

    // The length of the encoded string plus the null terminator.
    final bufLength = encoded.length + 1;
    sizeEncoded = sliceSizeAligned + bufLength;

    // Pointer to all the memory allocated for this string.
    _memory = malloc(sizeEncoded);

    // Pointer to the encoded string.
    final buf = _memory.elementAt(sliceSizeAligned);

    // Write null terminated string to memory.
    final bufList = buf.asTypedList(bufLength);
    bufList.setAll(0, encoded);
    bufList[encoded.length] = 0x0;

    // Init slice.
    asSlice.ref
      ..size = encoded.length
      ..buf = buf;
  }

  var _refs = 1;

  bool get isFreed => _refs == -1;

  int get refs => _refs;

  late final int sizeEncoded;

  final String string;

  late final Pointer<Uint8> _memory;

  late final Pointer<FLSlice> asSlice = _memory.cast();

  late final Pointer<Utf8> asNullTerminated =
      _memory.elementAt(sliceSizeAligned).cast();

  @visibleForTesting
  EncodedString retain() {
    assert(_refs != -1);
    _refs++;
    return this;
  }

  @visibleForTesting
  void release() {
    assert(refs > 0);
    _refs--;
    if (refs == 0) {
      _refs = -1;
      malloc.free(_memory);
    }
  }

  @override
  String toString() => 'EncodedString('
      'refs: $refs, '
      'sizeEncoded: $sizeEncoded, '
      'string: $string'
      ')';
}
