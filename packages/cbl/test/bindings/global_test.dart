import 'dart:ffi';

import 'package:cbl/src/bindings/cblite.dart' as cblite;
import 'package:cbl/src/bindings/global.dart';
import 'package:test/test.dart';

void main() {
  test('zeroedGlobalArena clears reused scratch memory', () {
    late final int address;

    withGlobalArena(() {
      final slice = globalArena<cblite.FLSlice>();
      address = slice.address;
      slice.ref
        ..buf = Pointer.fromAddress(1)
        ..size = 42;
    });

    withGlobalArena(() {
      final slice = zeroedGlobalArena<cblite.FLSlice>(sizeOf<cblite.FLSlice>());

      expect(slice.address, address);
      expect(slice.ref.buf, nullptr);
      expect(slice.ref.size, 0);
    });
  });
}
