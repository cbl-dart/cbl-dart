import 'dart:ffi';
import 'dart:typed_data';

import 'package:cbl/src/fleece/decoder.dart';
import 'package:cbl/src/fleece/encoder.dart';
import 'package:cbl_ffi/cbl_ffi.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

late final _decoderBinds = CBLBindings.instance.fleece.decoder;
late final _valueBinds = CBLBindings.instance.fleece.value;

void main() {
  setupTestBinding();

  group('Fleece Decoding', () {
    test('dumpData shows the internal structure of Fleece data', () {
      final encoder = FleeceEncoder();
      final data = encoder.convertJson('{"a": true}');

      expect(
        dumpData(data),
        '''
 0000: 70 01       : Dict {
 0002: 41 61       :   "a":
 0004: 38 00       :     true }
 0006: 80 03       : &Dict @0000
''',
      );
    });

    test('SharedStrings should only cache strings encoded as shared strings',
        () {
      final data = FleeceEncoder()
          .convertJson('[".", "..", "...............", "................"]');
      final sliceResult = data.toSliceResult();
      final sharedStrings = SharedStrings();

      final flArray =
          _valueBinds.fromData(sliceResult, FLTrust.trusted)!.cast<FLArray>();
      for (var i = 0; i < 4; i++) {
        _decoderBinds.getLoadedValueFromArray(flArray, 0);
        sharedStrings.flStringToDartString(globalLoadedFLValue.ref.asString);
      }

      expect(sharedStrings.hasString('.'), isFalse);
      expect(sharedStrings.hasString('..'), isTrue);
      expect(sharedStrings.hasString('...............'), isTrue);
      expect(sharedStrings.hasString('................'), isFalse);

      cblReachabilityFence(sliceResult);
    });

    group('FleeceDecoder', () {
      test('converts untrusted Fleece data to Dart object', () {
        final encoder = FleeceEncoder();
        const decoder = FleeceDecoder();
        final data = encoder.convertJson('''
[
  null, 41, 3.14, true, false, "a",
  {
    "a": null,
    "b": 41,
    "c": 3.14,
    "d": true,
    "e": false,
    "f":
    "a",
    "g": {},
    "h":[]
  },
  []
]
''');
        expect(decoder.convert(data), [
          null,
          41,
          3.14,
          true,
          false,
          'a',
          {
            'a': null,
            'b': 41,
            'c': 3.14,
            'd': true,
            'e': false,
            'f': 'a',
            'g': <String, Object?>{},
            'h': <Object?>[]
          },
          <Object?>[],
        ]);
      });

      test('converts trusted Fleece data to Dart object', () {
        final encoder = FleeceEncoder();
        const decoder = FleeceDecoder(trust: FLTrust.trusted);
        final data = encoder.convertJson('''
[
  null, 41, 3.14, true, false, "a",
  {
    "a": null,
    "b": 41,
    "c": 3.14,
    "d": true,
    "e": false,
    "f":
    "a",
    "g": {},
    "h":[]
  },
  []
]
''');
        expect(decoder.convert(data), [
          null,
          41,
          3.14,
          true,
          false,
          'a',
          {
            'a': null,
            'b': 41,
            'c': 3.14,
            'd': true,
            'e': false,
            'f': 'a',
            'g': <String, Object?>{},
            'h': <Object?>[]
          },
          <Object?>[],
        ]);
      });

      test('returns null when untrusted Fleece data is invalid', () {
        final data = Data.fromTypedList(Uint8List(0));

        expect(const FleeceDecoder().convert(data), isNull);
      });
    });
  });

  group('Fleece Encoding', () {
    test('convert JSON to Fleece data', () {
      final encoder = FleeceEncoder();
      const decoder = FleeceDecoder();
      final data = encoder.convertJson(
        '''
        {
          "a": true,
          "foo": [true, false, null, 43, 43, 1.3, 1.3, "foo"],
          "buz": 1.3,
          "bzz": 1.3
        }
        ''',
      );

      expect(
        decoder.convert(data),
        {
          'a': true,
          'buz': 1.3,
          'bzz': 1.3,
          'foo': [true, false, null, 43, 43, 1.3, 1.3, 'foo']
        },
      );
    });

    group('FleeceEncoder', () {
      test('writeDartObject writes Dart object to encoder', () {
        const decoder = FleeceDecoder();
        final encoder = FleeceEncoder()
          ..writeDartObject([
            null,
            true,
            false,
            41,
            3.14,
            'a',
            Uint8List.fromList([42]),
            [true],
            {'a': true},
            {true}
          ]);
        final data = encoder.finish();

        expect(decoder.convert(data), [
          null,
          true,
          false,
          41,
          3.14,
          'a',
          Uint8List.fromList([42]),
          [true],
          {'a': true},
          [true]
        ]);
      });

      test('write values', () {
        const decoder = FleeceDecoder();
        final encoder = FleeceEncoder()
          ..beginArray(0)
          ..writeNull()
          ..writeBool(true)
          ..writeBool(false)
          ..writeInt(41)
          ..writeDouble(3.14)
          ..writeString('a')
          ..writeData(Data.fromTypedList(Uint8List.fromList([42])))
          ..beginArray(0)
          ..endArray()
          ..beginDict(0)
          ..writeKey('a')
          ..writeBool(true)
          ..endDict()
          ..endArray();
        final data = encoder.finish();

        expect(
          decoder.convert(data),
          [
            null,
            true,
            false,
            41,
            3.14,
            'a',
            Uint8List.fromList([42]),
            <Object?>[],
            {'a': true}
          ],
        );
      });
    });
  });
}
