import 'dart:async';

import 'package:cbl/src/native_callbacks.dart';
import 'package:cbl_ffi/cbl_ffi.dart';

import 'test_binding.dart';

void main() {
  late final bindings = CBLBindings.instance.nativeCallbacks;
  late final callbacks = NativeCallbacks.instance;

  test('callbacks are invoked in the Zone where the callback was registered',
      () async {
    final zoneValues = {#test: 'nativeCallback'};
    final argument = 42;

    final callbackId = runZoned(
      () => callbacks.registerCallback<void Function(int)>(
        expectAsync1(
          (int arg) {
            expect(arg, argument);

            expect(Zone.current[#test], 'nativeCallback');
          },
          count: 1,
        ),
        (callback, arguments, result) {
          // Test caller is not requesting a result.
          expect(result, isNull);

          callback(arguments[0] as int);
        },
      ),
      zoneValues: zoneValues,
    );

    bindings.callForTest(callbackId, argument);
  });
}
