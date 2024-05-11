import 'dart:async';

import 'package:cbl_native_assets/src/bindings.dart';
import 'package:cbl_native_assets/src/support/async_callback.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('AsyncCallback', () {
    const bindings = AsyncCallbackBindings();

    test('propagates error to Zone in which it was created', () {
      final callback = runZonedGuarded(
        () => AsyncCallback(
          expectAsync1((_) => Future.error(Exception())),
          debugName: 'Test',
          debug: true,
        ),
        expectAsync2((error, stackTrace) {
          expect(error, isException);
        }),
      )!;

      addTearDown(callback.close);

      bindings.callForTest(callback.pointer, 0);
    });
  });
}
