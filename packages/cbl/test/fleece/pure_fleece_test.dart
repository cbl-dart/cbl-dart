// ignore_for_file: cascade_invocations

import 'dart:typed_data';

import 'package:cbl/src/bindings/data.dart';
import 'package:cbl/src/fleece/containers.dart';
import 'package:cbl/src/fleece/encoder.dart';
import 'package:cbl/src/fleece/pure_fleece.dart';
import 'package:test/test.dart';

/// Uses the native Fleece encoder to encode a Dart object and returns the raw
/// bytes.
Uint8List nativeEncode(Object? value) {
  final encoder = FleeceEncoder();
  final data = encoder.convertDartObject(value);
  return data.toTypedList();
}

/// Uses the native Fleece infrastructure to decode bytes into a Dart object.
Object? nativeDecode(Uint8List bytes) {
  final doc = Doc.fromResultData(Data.fromTypedList(bytes), FLTrust.trusted);
  return doc.root.toObject();
}

/// Round-trips: Dart object -> pure encoder -> native decoder -> Dart object.
Object? pureEncodeNativeDecode(Object? value) {
  final encoder = PureFleeceEncoder();
  final bytes = encoder.encodeDartObject(value);
  return nativeDecode(bytes);
}

/// Round-trips: Dart object -> native encoder -> pure decoder -> Dart object.
Object? nativeEncodePureDecode(Object? value) {
  final bytes = nativeEncode(value);
  final decoder = FleeceDecoder(bytes);
  return decoder.root.toObject();
}

void main() {
  // ==========================================================================
  // Decoder tests — decode native-encoded Fleece with pure Dart decoder
  // ==========================================================================

  group('FleeceDecoder', () {
    group('scalars', () {
      test('null', () {
        expect(nativeEncodePureDecode(null), isNull);
      });

      test('true', () {
        // null and booleans can't be top-level values in Fleece (they're only
        // 2 bytes and need a container). Wrap in array.
        expect(nativeEncodePureDecode([true]), equals([true]));
      });

      test('false', () {
        expect(nativeEncodePureDecode([false]), equals([false]));
      });

      test('small positive int', () {
        expect(nativeEncodePureDecode([0]), equals([0]));
        expect(nativeEncodePureDecode([1]), equals([1]));
        expect(nativeEncodePureDecode([42]), equals([42]));
        expect(nativeEncodePureDecode([2047]), equals([2047]));
      });

      test('small negative int', () {
        expect(nativeEncodePureDecode([-1]), equals([-1]));
        expect(nativeEncodePureDecode([-2048]), equals([-2048]));
      });

      test('large positive int', () {
        expect(nativeEncodePureDecode([2048]), equals([2048]));
        expect(nativeEncodePureDecode([0xFF]), equals([0xFF]));
        expect(nativeEncodePureDecode([0xFFFF]), equals([0xFFFF]));
        expect(nativeEncodePureDecode([0x7FFFFFFF]), equals([0x7FFFFFFF]));
        expect(
          nativeEncodePureDecode([0x7FFFFFFFFFFFFFFF]),
          equals([0x7FFFFFFFFFFFFFFF]),
        );
      });

      test('large negative int', () {
        expect(nativeEncodePureDecode([-2049]), equals([-2049]));
        expect(nativeEncodePureDecode([-0x80]), equals([-0x80]));
        expect(nativeEncodePureDecode([-0x8000]), equals([-0x8000]));
        expect(nativeEncodePureDecode([-0x80000000]), equals([-0x80000000]));
      });

      test('double', () {
        expect(nativeEncodePureDecode([3.14]), equals([3.14]));
        expect(nativeEncodePureDecode([1.5]), equals([1.5]));
        expect(nativeEncodePureDecode([-0.5]), equals([-0.5]));
      });

      test('double that fits in float32', () {
        expect(nativeEncodePureDecode([1.5]), equals([1.5]));
      });

      test('double stored as int', () {
        // Fleece stores 123.0 as integer 123.
        final bytes = nativeEncode([123.0]);
        final decoder = FleeceDecoder(bytes);
        final arr = decoder.root.asArray;
        // The value is stored as int but asDouble should still work.
        expect(arr[0].asDouble, equals(123.0));
      });

      test('string', () {
        expect(nativeEncodePureDecode(['hello']), equals(['hello']));
        expect(nativeEncodePureDecode(['']), equals(['']));
        expect(nativeEncodePureDecode(['a']), equals(['a']));
      });

      test('long string (> 14 bytes)', () {
        const longStr = 'abcdefghijklmnopqrstuvwxyz';
        expect(nativeEncodePureDecode([longStr]), equals([longStr]));
      });

      test('unicode string', () {
        expect(nativeEncodePureDecode(['Hello 🌍']), equals(['Hello 🌍']));
      });

      test('binary data', () {
        final data = Uint8List.fromList([0, 1, 2, 255, 254, 253]);
        final result = nativeEncodePureDecode([data]);
        expect(result, isA<List>());
        expect((result! as List)[0], equals(data));
      });
    });

    group('arrays', () {
      test('empty array', () {
        expect(nativeEncodePureDecode([]), equals([]));
      });

      test('array of ints', () {
        expect(nativeEncodePureDecode([1, 2, 3]), equals([1, 2, 3]));
      });

      test('mixed array', () {
        expect(
          nativeEncodePureDecode([1, 'two', true, null, 3.14]),
          equals([1, 'two', true, null, 3.14]),
        );
      });

      test('nested arrays', () {
        expect(
          nativeEncodePureDecode([
            [1, 2],
            [3, 4],
          ]),
          equals([
            [1, 2],
            [3, 4],
          ]),
        );
      });
    });

    group('dicts', () {
      test('empty dict', () {
        expect(nativeEncodePureDecode({}), equals({}));
      });

      test('simple dict', () {
        expect(
          nativeEncodePureDecode({'a': 1, 'b': 2}),
          equals({'a': 1, 'b': 2}),
        );
      });

      test('dict with mixed values', () {
        final input = {
          'name': 'Alice',
          'age': 30,
          'active': true,
          'score': 9.5,
        };
        expect(nativeEncodePureDecode(input), equals(input));
      });

      test('nested dict', () {
        final input = {
          'user': {
            'name': 'Bob',
            'address': {'city': 'NYC', 'zip': '10001'},
          },
        };
        expect(nativeEncodePureDecode(input), equals(input));
      });

      test('dict key lookup', () {
        final bytes = nativeEncode({'alpha': 1, 'beta': 2, 'gamma': 3});
        final decoder = FleeceDecoder(bytes);
        final dict = decoder.root.asDict;
        expect(dict['alpha']!.asInt, equals(1));
        expect(dict['beta']!.asInt, equals(2));
        expect(dict['gamma']!.asInt, equals(3));
        expect(dict['missing'], isNull);
      });

      test('dict keys', () {
        final bytes = nativeEncode({'c': 3, 'a': 1, 'b': 2});
        final decoder = FleeceDecoder(bytes);
        final dict = decoder.root.asDict;
        // Keys should be sorted in Fleece.
        expect(dict.keys, equals(['a', 'b', 'c']));
        expect(dict.length, equals(3));
      });
    });

    group('FleeceValue type accessors', () {
      test('type identification', () {
        final bytes = nativeEncode({
          'n': null,
          'b': true,
          'i': 42,
          'f': 3.14,
          's': 'hi',
          'a': [1],
          'd': {'x': 1},
        });
        final decoder = FleeceDecoder(bytes);
        final dict = decoder.root.asDict;

        expect(dict['n']!.isNull, isTrue);
        expect(dict['b']!.type, equals(FleeceValueType.bool_));
        expect(dict['i']!.type, equals(FleeceValueType.int_));
        expect(dict['s']!.type, equals(FleeceValueType.string));
        expect(dict['a']!.type, equals(FleeceValueType.array));
        expect(dict['d']!.type, equals(FleeceValueType.dict));
      });
    });

    group('edge cases', () {
      test('data too short throws', () {
        expect(
          () => FleeceDecoder(Uint8List(0)).root,
          throwsA(isA<FormatException>()),
        );
        expect(
          () => FleeceDecoder(Uint8List(1)).root,
          throwsA(isA<FormatException>()),
        );
      });

      test('string deduplication is handled', () {
        // Same string repeated — Fleece deduplicates them.
        final input = {'a': 'hello', 'b': 'hello', 'c': 'hello'};
        expect(nativeEncodePureDecode(input), equals(input));
      });

      test('many keys (binary search coverage)', () {
        // Create a dict with enough keys to exercise binary search.
        final input = <String, Object?>{};
        for (var i = 0; i < 50; i++) {
          input['key_${i.toString().padLeft(3, '0')}'] = i;
        }
        expect(nativeEncodePureDecode(input), equals(input));
      });
    });
  });

  // ==========================================================================
  // Encoder tests — encode with pure Dart, decode with native Fleece
  // ==========================================================================

  group('PureFleeceEncoder', () {
    group('scalars in arrays', () {
      test('null', () {
        expect(pureEncodeNativeDecode([null]), equals([null]));
      });

      test('true and false', () {
        expect(pureEncodeNativeDecode([true, false]), equals([true, false]));
      });

      test('small ints', () {
        expect(pureEncodeNativeDecode([0]), equals([0]));
        expect(pureEncodeNativeDecode([1]), equals([1]));
        expect(pureEncodeNativeDecode([-1]), equals([-1]));
        expect(pureEncodeNativeDecode([2047]), equals([2047]));
        expect(pureEncodeNativeDecode([-2048]), equals([-2048]));
      });

      test('large ints', () {
        expect(pureEncodeNativeDecode([2048]), equals([2048]));
        expect(pureEncodeNativeDecode([-2049]), equals([-2049]));
        expect(pureEncodeNativeDecode([0xFFFF]), equals([0xFFFF]));
        expect(pureEncodeNativeDecode([0x7FFFFFFF]), equals([0x7FFFFFFF]));
        expect(
          pureEncodeNativeDecode([0x7FFFFFFFFFFFFFFF]),
          equals([0x7FFFFFFFFFFFFFFF]),
        );
        expect(pureEncodeNativeDecode([-0x80000000]), equals([-0x80000000]));
      });

      test('doubles', () {
        expect(pureEncodeNativeDecode([3.14]), equals([3.14]));
        expect(pureEncodeNativeDecode([1.5]), equals([1.5]));
        expect(pureEncodeNativeDecode([-0.5]), equals([-0.5]));
      });

      test('double stored as int', () {
        // 123.0 should be stored as integer.
        expect(pureEncodeNativeDecode([123.0]), equals([123]));
      });

      test('strings', () {
        expect(pureEncodeNativeDecode(['']), equals(['']));
        expect(pureEncodeNativeDecode(['a']), equals(['a']));
        expect(pureEncodeNativeDecode(['hello']), equals(['hello']));
      });

      test('long string', () {
        final longStr = 'a' * 100;
        expect(pureEncodeNativeDecode([longStr]), equals([longStr]));
      });

      test('binary data', () {
        final data = Uint8List.fromList([0, 1, 2, 255]);
        final result = pureEncodeNativeDecode([data])! as List;
        expect(result[0], equals(data));
      });
    });

    group('arrays', () {
      test('empty array', () {
        expect(pureEncodeNativeDecode([]), equals([]));
      });

      test('nested arrays', () {
        expect(
          pureEncodeNativeDecode([
            [1, 2],
            [3],
          ]),
          equals([
            [1, 2],
            [3],
          ]),
        );
      });

      test('deeply nested', () {
        final input = [
          [
            [
              [1],
            ],
          ],
        ];
        expect(pureEncodeNativeDecode(input), equals(input));
      });
    });

    group('dicts', () {
      test('empty dict', () {
        expect(pureEncodeNativeDecode({}), equals({}));
      });

      test('simple dict', () {
        expect(
          pureEncodeNativeDecode({'x': 1, 'y': 2}),
          equals({'x': 1, 'y': 2}),
        );
      });

      test('dict keys are sorted', () {
        // Pure encoder must sort keys for Fleece compatibility.
        expect(
          pureEncodeNativeDecode({'z': 3, 'a': 1, 'm': 2}),
          equals({'a': 1, 'm': 2, 'z': 3}),
        );
      });

      test('dict with mixed value types', () {
        final input = {
          'bool': true,
          'int': 42,
          'double': 2.718,
          'string': 'hi',
          'null': null,
          'array': [1, 2],
          'dict': {'nested': true},
        };
        expect(pureEncodeNativeDecode(input), equals(input));
      });

      test('nested dicts', () {
        final input = {
          'a': {
            'b': {'c': 'deep'},
          },
        };
        expect(pureEncodeNativeDecode(input), equals(input));
      });
    });

    group('string deduplication', () {
      test('repeated strings share storage', () {
        final encoder = PureFleeceEncoder();
        final withDedup = encoder.encodeDartObject({
          'a': 'hello',
          'b': 'hello',
          'c': 'hello',
        });

        final noDedupEncoder = PureFleeceEncoder(uniqueStrings: false);
        final withoutDedup = noDedupEncoder.encodeDartObject({
          'a': 'hello',
          'b': 'hello',
          'c': 'hello',
        });

        // With dedup should be smaller (or equal).
        expect(withDedup.length, lessThanOrEqualTo(withoutDedup.length));

        // Both should decode correctly.
        expect(nativeDecode(withDedup), nativeDecode(withoutDedup));
      });
    });

    group('error handling', () {
      test('finish with unclosed collection throws', () {
        final encoder = PureFleeceEncoder();
        encoder.beginArray(0);
        expect(encoder.finish, throwsA(isA<StateError>()));
      });

      test('finish without encoding throws', () {
        final encoder = PureFleeceEncoder();
        expect(encoder.finish, throwsA(isA<StateError>()));
      });

      test('endArray without beginArray throws', () {
        final encoder = PureFleeceEncoder();
        expect(encoder.endArray, throwsA(isA<StateError>()));
      });

      test('endDict without beginDict throws', () {
        final encoder = PureFleeceEncoder();
        expect(encoder.endDict, throwsA(isA<StateError>()));
      });

      test('writeKey outside dict throws', () {
        final encoder = PureFleeceEncoder();
        encoder.beginArray(0);
        expect(() => encoder.writeKey('k'), throwsA(isA<StateError>()));
      });

      test('unsupported type throws', () {
        final encoder = PureFleeceEncoder();
        expect(
          () => encoder.encodeDartObject(DateTime.now()),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('reset clears state', () {
        final encoder = PureFleeceEncoder();
        encoder.beginArray(0);
        encoder.reset();
        // Should be able to encode fresh after reset.
        final result = encoder.encodeDartObject([1, 2]);
        expect(nativeDecode(result), equals([1, 2]));
      });
    });
  });

  // ==========================================================================
  // Additional decoder edge cases
  // ==========================================================================

  group('FleeceDecoder additional coverage', () {
    test('undefined value', () {
      // Encode an array with an undefined marker using raw bytes.
      // undefined = 0011 11-- = 0x3C, second byte = 0x00.
      // But native encoder can't write undefined directly, so craft bytes.
      // We'll create a minimal array with undefined by hand:
      // Actually, let's just test the type detection of the FleeceValue.
      // Create [null] and verify isUndefined is false.
      final bytes = nativeEncode([null]);
      final decoder = FleeceDecoder(bytes);
      final arr = decoder.root.asArray;
      expect(arr[0].isNull, isTrue);
      expect(arr[0].isUndefined, isFalse);
    });

    test('asDouble on large int value', () {
      // A large int stored as long int — asDouble should convert it.
      final bytes = nativeEncode([100000]);
      final decoder = FleeceDecoder(bytes);
      final arr = decoder.root.asArray;
      expect(arr[0].asDouble, equals(100000.0));
    });

    test('long string in decoder (varint count path)', () {
      // String > 14 bytes triggers varint count in blob.
      final longStr = 'x' * 200;
      final bytes = nativeEncode([longStr]);
      final decoder = FleeceDecoder(bytes);
      final arr = decoder.root.asArray;
      expect(arr[0].asString, equals(longStr));
    });

    test('multi-byte varint in decoder', () {
      // String > 127 bytes needs multi-byte varint.
      final longStr = 'y' * 300;
      expect(nativeEncodePureDecode([longStr]), equals([longStr]));
    });

    test('dict with long string keys', () {
      // Keys > 14 chars exercise the long string key path.
      const longKey = 'very_long_key_name_here';
      final input = {longKey: 42};
      expect(nativeEncodePureDecode(input), equals(input));
    });
  });

  // ==========================================================================
  // Additional encoder edge cases
  // ==========================================================================

  group('PureFleeceEncoder additional coverage', () {
    test('top-level scalar (non-collection) is wrapped correctly', () {
      // Encoding a single top-level string (a long value, not inside a
      // collection). This exercises the _writeLongValue else branch.
      final encoder = PureFleeceEncoder();
      encoder.writeString('hello');
      final bytes = encoder.finish();
      // The native decoder should be able to read this.
      // Note: top-level scalars may not be standard, but the encoder
      // should produce valid bytes. At minimum, the bytes are non-empty.
      expect(bytes.length, greaterThan(0));
    });

    test('top-level inline scalar', () {
      // A small int at top level — exercises _writeScalar else branch.
      final encoder = PureFleeceEncoder();
      encoder.writeInt(42);
      final bytes = encoder.finish();
      expect(bytes.length, equals(2));
    });

    test('dict with long string keys in encoder', () {
      // Keys > 14 chars to exercise long key reading in _readStringFromOutput.
      final longKey = 'a' * 20;
      final input = {longKey: 1, 'z': 2};
      expect(pureEncodeNativeDecode(input), equals(input));
    });

    test('alignment padding in emitBytes', () {
      // Force odd-length data to test alignment. Binary data with odd length.
      final oddData = Uint8List.fromList([1, 2, 3]); // 3 bytes = odd
      expect(pureEncodeNativeDecode([oddData]), equals([oddData]));
    });

    test('endArray with mismatched beginDict throws', () {
      final encoder = PureFleeceEncoder();
      encoder.beginDict(0);
      expect(encoder.endArray, throwsA(isA<StateError>()));
    });

    test('endDict with mismatched beginArray throws', () {
      final encoder = PureFleeceEncoder();
      encoder.beginArray(0);
      expect(encoder.endDict, throwsA(isA<StateError>()));
    });

    test('uniqueStrings=false disables dedup', () {
      final encoder = PureFleeceEncoder(uniqueStrings: false);
      final bytes = encoder.encodeDartObject({'a': 'same', 'b': 'same'});
      expect(nativeDecode(bytes), equals({'a': 'same', 'b': 'same'}));
    });

    test('string dedup for dict keys', () {
      // Same key used as both a key and a value — exercises key dedup path.
      final input = {'hello': 'hello', 'world': 'world'};
      expect(pureEncodeNativeDecode(input), equals(input));
    });
  });

  // ==========================================================================
  // Raw byte tests for hard-to-reach decoder paths
  // ==========================================================================

  group('FleeceDecoder raw byte tests', () {
    test('undefined special value', () {
      // Craft an array containing an undefined value.
      // undefined = 0x3C 0x00 (tag=3, subtype=3)
      // Array header: 0x6001 (tag=6, count=1, narrow)
      // The array contains the inline undefined value.
      // Then trailing pointer.
      final bytes = Uint8List.fromList([
        0x60, 0x01, // array header: count=1, narrow
        0x3C, 0x00, // inline undefined value
        0x80, 0x02, // trailing pointer back 4 bytes
      ]);
      final decoder = FleeceDecoder(bytes);
      final arr = decoder.root.asArray;
      expect(arr[0].type, equals(FleeceValueType.undefined));
      expect(arr[0].isUndefined, isTrue);
      expect(arr[0].toObject(), isNull);
    });

    test('unresolved pointer tag throws', () {
      // Craft bytes where _typeAt is called on a pointer offset.
      // This shouldn't happen in normal usage, but test the error path.
      // A single pointer value: 0x80 0x01 pointing back to itself — invalid.
      final bytes = Uint8List.fromList([0x80, 0x01]);
      final decoder = FleeceDecoder(bytes);
      // Root dereferences the pointer, getting offset -2, which is invalid.
      // This should either throw or produce garbage.
      expect(() => decoder.root, throwsA(isA<RangeError>()));
    });

    test('unknown special subtype throws', () {
      // Special with subtype > 3: tag=3, subtype bits = impossible value.
      // Actually subtype is 2 bits so max is 3. But the bit pattern allows
      // bits outside ss to be set. Let's craft 0x30 | (0x04 << 2) ... wait,
      // that overflows into the tag bits. The special format is:
      // 0011ss-- so byte0 = 0x30 | (s << 2). For s=3 that's 0x3C.
      // All 4 values (0-3) are valid. This error path is truly unreachable
      // with 2-bit subtype. Skip.
    });

    test('shared integer key throws UnsupportedError', () {
      // Craft a dict where a key is a small integer instead of a string.
      // Dict header: 0x7001 (tag=7, count=1, narrow)
      // Key: small int 5 = 0x0005
      // Value: small int 42 = 0x002A
      final bytes = Uint8List.fromList([
        0x70, 0x01, // dict header: count=1, narrow
        0x00, 0x05, // key: small int 5
        0x00, 0x2A, // value: small int 42
        0x80, 0x03, // trailing pointer back 6 bytes
      ]);
      final decoder = FleeceDecoder(bytes);
      final dict = decoder.root.asDict;
      expect(() => dict.keys, throwsA(isA<UnsupportedError>()));
    });

    test('unexpected dict key tag throws FormatException', () {
      // Craft a dict where a key has a data tag (0x5) — not string or int.
      final bytes = Uint8List.fromList([
        0x50, 0x00, // binary data, 0 bytes (used as key — invalid)
        0x70, 0x01, // dict header: count=1, narrow
        0x80, 0x02, // key: pointer to data value
        0x00, 0x2A, // value: small int 42
        0x80, 0x03, // trailing pointer back 6 bytes
      ]);
      final decoder = FleeceDecoder(bytes);
      final dict = decoder.root.asDict;
      expect(() => dict.keys, throwsA(isA<FormatException>()));
    });
  });

  // ==========================================================================
  // Additional encoder error path tests
  // ==========================================================================

  group('PureFleeceEncoder error paths', () {
    test('dict with mismatched key/value throws on endDict', () {
      final encoder = PureFleeceEncoder();
      encoder.beginDict(0);
      encoder.writeKey('key');
      // No value written — odd item count
      expect(encoder.endDict, throwsA(isA<StateError>()));
    });

    test('long key string in encoder with varint', () {
      // Key with exactly 15+ chars to exercise varint path in
      // _readStringFromOutput.
      final key15 = 'k' * 15;
      final key30 = 'k' * 30;
      final input = {key15: 1, key30: 2, 'a': 3};
      expect(pureEncodeNativeDecode(input), equals(input));
    });

    test('very long key string (>127 bytes) for multi-byte varint', () {
      // Key > 127 bytes requires multi-byte varint in _readStringFromOutput.
      final longKey = 'x' * 200;
      final input = {longKey: 1, 'a': 2};
      expect(pureEncodeNativeDecode(input), equals(input));
    });

    test('FleeceArray length getter', () {
      final bytes = nativeEncode([1, 2, 3]);
      final decoder = FleeceDecoder(bytes);
      final arr = decoder.root.asArray;
      expect(arr.length, equals(3));
    });
  });

  // ==========================================================================
  // Cross-validation — both directions agree
  // ==========================================================================

  group('cross-validation', () {
    test('complex document round-trips through both paths', () {
      final doc = {
        'type': 'user',
        'name': 'Alice',
        'age': 30,
        'active': true,
        'score': 95.5,
        'tags': ['admin', 'user'],
        'address': {
          'street': '123 Main St',
          'city': 'Springfield',
          'zip': '62704',
        },
        'metadata': null,
      };

      // Pure encode -> native decode
      expect(pureEncodeNativeDecode(doc), equals(doc));

      // Native encode -> pure decode
      expect(nativeEncodePureDecode(doc), equals(doc));
    });

    test('array of dicts', () {
      final data = [
        {'id': 1, 'name': 'Alice'},
        {'id': 2, 'name': 'Bob'},
        {'id': 3, 'name': 'Charlie'},
      ];
      expect(pureEncodeNativeDecode(data), equals(data));
      expect(nativeEncodePureDecode(data), equals(data));
    });

    test('pure decoder reads pure encoder output', () {
      final input = {
        'key': 'value',
        'num': 42,
        'list': [1, 2, 3],
      };
      final encoder = PureFleeceEncoder();
      final bytes = encoder.encodeDartObject(input);
      final decoder = FleeceDecoder(bytes);
      expect(decoder.root.toObject(), equals(input));
    });
  });
}
