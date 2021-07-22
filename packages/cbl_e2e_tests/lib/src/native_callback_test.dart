import 'dart:async';

import 'package:cbl/src/native_callback.dart';
import 'package:cbl/src/native_object.dart';
import 'package:cbl_ffi/cbl_ffi.dart';

import '../test_binding_impl.dart';
import 'test_binding.dart';

void main() {
  setupTestBinding();

  group('NativeCallback', () {
    late final bindings = CBLBindings.instance.nativeCallback;

    test('callbacks are invoked in the Zone where the callback was registered',
        () async {
      final zoneValues = {#test: 'nativeCallback'};
      final argument = 42;

      final callback = runZoned(
        () => NativeCallback(
          expectAsync1(
            (arguments) {
              expect(arguments, equals([argument]));

              expect(Zone.current[#test], 'nativeCallback');
            },
            count: 1,
          ),
          debugName: 'Test',
          debug: true,
        ),
        zoneValues: zoneValues,
      );

      addTearDown(callback.close);

      callback.native
          .keepAlive((pointer) => bindings.callForTest(pointer, argument));
    });
  });
}
