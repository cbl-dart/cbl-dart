import 'dart:async';

import 'package:cbl/src/native_callback.dart';
import 'package:cbl_ffi/cbl_ffi.dart';
import 'package:test/test.dart';

import '../test_binding_impl.dart';

void main() {
  setupTestBinding();

  group('NativeCallback', () {
    late final bindings = CBLBindings.instance.nativeCallback;

    test('callbacks are invoked in the Zone where the callback was registered',
        () async {
      final zoneValues = {#test: 'nativeCallback'};
      final argument = 42;

      final callback = runZoned(
        () => NativeCallback(expectAsync1(
          (arguments) {
            expect(arguments, equals([argument]));

            expect(Zone.current[#test], 'nativeCallback');
          },
          count: 1,
        )),
        zoneValues: zoneValues,
      );

      addTearDown(callback.close);

      bindings.callForTest(callback.native.pointerUnsafe, argument);
    });
  });
}
