import 'dart:ffi';
import 'dart:typed_data';

import 'package:cbl_ffi/src/string_table.dart';
import 'package:cbl_ffi/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('EncodedString', () {
    test('should store dart string', () {
      final string = testEncodedString('a');
      expect(string.string, 'a');
    });

    test('should initialize refs to 1', () {
      final string = testEncodedString('');

      expect(string.refs, 1);
    });

    test('should increment refs when retained', () {
      final string = testEncodedString('');

      string.retain();
      addTearDown(string.release);

      expect(string.refs, 2);
    });

    test('should release string when refs == 0', () {
      final string = EncodedString('');

      expect(string.isFreed, isFalse);
      string.release();
      expect(string.refs, -1);
      expect(string.isFreed, isTrue);
    });

    test('should encode string as utf8 and null terminated it', () {
      final string = testEncodedString('a❤');

      expect(
        string.asNullTerminated.cast<Uint8>().asTypedList(5),
        Uint8List.fromList([0x61, 0xE2, 0x9D, 0xA4, 0]),
      );
    });

    test('should store string in slice', () {
      final string = testEncodedString('a❤');

      expect(string.asSlice.ref.size, 4);
      expect(
        string.asSlice.ref.buf.cast<Uint8>().asTypedList(4),
        Uint8List.fromList([0x61, 0xE2, 0x9D, 0xA4]),
      );
    });

    test('should return a debug representation from toString', () {
      final string = testEncodedString('a❤');

      expect(
        string.toString(),
        'EncodedString(refs: 1, sizeEncoded: ${string.sizeEncoded}, string: a❤)',
      );
    });
  });

  // When a string is in the cache it has one additional reference. This fact
  // in addition to how many times a string has been retained is used in the
  // tests to check if a string is in the cache.
  group('StringTable', () {
    test('should reference count allocated string', () {
      final table = testStringTable(maxCacheSize: 0);
      var string = '';

      final encodedString = table.encodedString(string);
      expect(encodedString.refs, 1);

      table.encodedString(string);
      expect(encodedString.refs, 2);

      table.free(string);
      expect(encodedString.refs, 1);

      table.free(string);
      expect(encodedString.refs, -1);
    });

    test('should free strings allocated in autoFree callback', () {
      final table = testStringTable(maxCacheSize: 0);
      var string = '';

      final encodedString = table.encodedString(string);
      addTearDown(() => table.free(string));

      table.autoFree(() => expect(table.encodedString(string).refs, 2));

      expect(encodedString.refs, 1);
    });

    test('should free strings allocated in runArena', () {
      final table = testStringTable(maxCacheSize: 0);
      var string = '';

      final encodedString = table.encodedString(string);
      addTearDown(() => table.free(string));

      runArena(() => expect(table.encodedString(string, arena: true).refs, 2));

      expect(encodedString.refs, 1);
    });

    test('should cache string with encodedSize above minCachedStringSize', () {
      final table = testStringTable(maxCacheSize: 1, minCachedStringSize: 32);
      var stringBelowMinCacheSize = stringWithEncodedSizeOf(31);
      var stringAboveMinCacheSize = stringWithEncodedSizeOf(32);

      table.autoFree(() {
        expect(table.cacheSize, 0);

        expect(table.encodedString(stringBelowMinCacheSize).refs, 1);
        expect(table.cacheSize, 0);

        expect(table.encodedString(stringAboveMinCacheSize).refs, 2);
        expect(table.cacheSize, 32);
      });
    });

    test('should cache string with encodedSize below maxCachedStringSize', () {
      final table = testStringTable(maxCacheSize: 1, maxCachedStringSize: 32);
      var stringBelowMaxCacheSize = stringWithEncodedSizeOf(32);
      var stringAboveMaxCacheSize = stringWithEncodedSizeOf(33);

      table.autoFree(() {
        expect(table.cacheSize, 0);

        expect(table.encodedString(stringBelowMaxCacheSize).refs, 2);
        expect(table.cacheSize, 32);

        expect(table.encodedString(stringAboveMaxCacheSize).refs, 1);
        expect(table.cacheSize, 32);
      });
    });

    test('should cache at most maxCacheSize strings', () {
      final table = testStringTable(maxCacheSize: 2);

      table.autoFree(() {
        expect(table.cachedStrings, 0);

        final stringA = table.encodedString('a');
        expect(stringA.refs, 2);
        expect(table.cachedStrings, 1);

        final stringB = table.encodedString('b');
        expect(stringA.refs, 2);
        expect(stringB.refs, 2);
        expect(table.cachedStrings, 2);

        // The least recently used string should be removed from cache first,
        // which is stringA.
        final stringC = table.encodedString('c');
        expect(stringA.refs, 1);
        expect(stringB.refs, 2);
        expect(stringC.refs, 2);
        expect(table.cachedStrings, 2);
      });
    });

    test('should not cache string when cache: false', () {
      final table = testStringTable(maxCacheSize: 1);

      table.autoFree(() {
        final string = table.encodedString('a', cache: false);
        expect(string.refs, 1);

        table.encodedString('a');
        expect(string.refs, 3);
      });
    });

    test('should release cached strings in dispose', () {
      final table = StringTable(maxCacheSize: 1);
      final string = table.encodedString('');

      expect(string.refs, 2);
      table.free('');
      table.dispose();
      expect(string.isFreed, true);
    });

    test('should count cache hits and misses', () {
      final table = testStringTable();
      table.autoFree(() {
        expect(table.cacheHits, 0);
        expect(table.cacheMisses, 0);

        table.encodedString('');
        expect(table.cacheHits, 0);
        expect(table.cacheMisses, 1);

        table.encodedString('');
        expect(table.cacheHits, 1);
        expect(table.cacheMisses, 1);
      });
    });

    test(
        'should return the sum of the encoded size of cached strings in cacheSize',
        () {
      final table = testStringTable();
      table.autoFree(() {
        expect(table.cacheSize, 0);

        table.encodedString(stringWithEncodedSizeOf(32, 'a'));
        table.encodedString(stringWithEncodedSizeOf(32, 'b'));
        expect(table.cacheSize, 64);
      });
    });

    test('should return a debug representation from toString', () {
      final table = testStringTable(
        maxCacheSize: 0,
        minCachedStringSize: 0,
        maxCachedStringSize: 0,
      );

      expect(
        table.toString(),
        'StringCoding('
        'maxCacheSize: 0, '
        'minCachedStringSize: 0, '
        'maxCachedStringSize: 0, '
        'cachedStrings: 0, '
        'cacheSize: 0 bytes, '
        'cacheHits: 0, '
        'cacheMisses: 0'
        ')',
      );
    });
  });
}

String stringWithEncodedSizeOf(int encodeSize, [String? prefix]) {
  prefix ??= '';
  final remaining =
      encodeSize - EncodedString.sliceSizeAligned - 1 - prefix.length;
  assert(remaining >= 0);
  return prefix + List.filled(remaining, '.').join();
}

EncodedString testEncodedString(String string) {
  final result = EncodedString(string);
  addTearDown(result.release);
  return result;
}

StringTable testStringTable({
  int maxCacheSize = 512,
  int minCachedStringSize = 0,
  int maxCachedStringSize = 512,
}) {
  final result = StringTable(
    maxCacheSize: maxCacheSize,
    maxCachedStringSize: maxCachedStringSize,
    minCachedStringSize: minCachedStringSize,
  );
  addTearDown(result.dispose);
  return result;
}
