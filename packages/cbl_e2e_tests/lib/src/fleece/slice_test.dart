import 'dart:ffi';

import 'package:cbl/src/bindings.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('Fleece Slice', () {
    test('create Slice from other Slice', () {
      final source = SliceResult.fromString('source');
      final slice = Slice.fromSlice(source);

      expect(slice.buf, source.buf);
      expect(slice.size, source.size);
      expect(slice, source);
    });

    test('create Slice from FLSlice', () {
      final source = SliceResult.fromString('source');
      final slice = Slice.fromFLSlice(source.makeGlobal().ref);

      expect(slice, source);

      globalFLSlice.ref
        ..buf = nullptr
        ..size = 0;
      expect(Slice.fromFLSlice(globalFLSlice.ref), isNull);
    });

    test('toDartString decodes the slice data as UTF-8 and returns a String',
        () {
      final slice = SliceResult.fromString('a❤');

      expect(slice.toDartString(), 'a❤');
    });

    test('compareTo returns correct result', () {
      final a = SliceResult.fromString('a');
      final b = SliceResult.fromString('b');

      expect(a.compareTo(b), -1);
      expect(a.compareTo(a), 0);
      expect(b.compareTo(a), 1);
    });

    test('== returns correct result', () {
      final a = SliceResult.fromString('a');
      final b = SliceResult.fromString('b');
      final c = SliceResult.fromString('a');

      expect(a == a, isTrue);
      expect(a == b, isFalse);
      expect(a == c, isTrue);
    });

    test('hashCode returns address of buf', () {
      final s = SliceResult.fromString('a');

      expect(s.hashCode, s.buf.address);
    });

    test('empty string SliceResult', () {
      final s = SliceResult.fromString('');

      expect(s.size, 0);
      expect(s.toDartString(), '');
    });

    test('create a new SliceResult of given size', () {
      final slice = SliceResult(2);

      expect(slice.size, 2);

      slice.asTypedList().setAll(0, [1, 2]);

      expect(slice.asTypedList(), [1, 2]);
    });

    test('create SliceResult from FLSliceResult', () {
      final source = SliceResult.fromString('source');
      final slice = SliceResult.fromFLSliceResult(
        source.makeGlobal().cast<FLSliceResult>().ref,
        retain: true,
      );

      expect(slice, source);

      globalFLSliceResult.ref
        ..buf = nullptr
        ..size = 0;
      expect(SliceResult.fromFLSliceResult(globalFLSliceResult.ref), isNull);
    });
  });
}
