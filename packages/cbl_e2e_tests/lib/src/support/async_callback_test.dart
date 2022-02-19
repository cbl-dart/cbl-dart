import 'dart:async';

import 'package:cbl/src/support/async_callback.dart';
import 'package:cbl_ffi/cbl_ffi.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('AsyncCallback', () {
    late final bindings = CBLBindings.instance.asyncCallback;

    test('propagates error to Zone in which it was created', () {
      final callback = runZonedGuarded(
          () => AsyncCallback(
                expectAsync1((_) {
                  throw Exception();
                }),
                debugName: 'Test',
                debug: true,
              ), expectAsync2((error, stackTrace) {
        expect(error, isException);
      }))!;

      addTearDown(callback.close);

      final callbackNative = callback.native;
      bindings.callForTest(callbackNative.pointer, 0);
      cblReachabilityFence(callbackNative);
    });
  });
}
