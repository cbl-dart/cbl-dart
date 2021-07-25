import 'dart:async';

import 'package:cbl/src/support/async_callback.dart';
import 'package:cbl/src/support/native_object.dart';
import 'package:cbl_ffi/cbl_ffi.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('AsyncCallback', () {
    late final bindings = CBLBindings.instance.asyncCallback;

    test('callbacks are invoked in the Zone where the callback was registered',
        () async {
      final zoneValues = {#test: 'asyncCallback'};
      final argument = 42;

      final callback = runZoned(
        () => AsyncCallback(
          expectAsync1(
            (arguments) {
              expect(arguments, equals([argument]));

              expect(Zone.current[#test], 'asyncCallback');
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
          .call((pointer) => bindings.callForTest(pointer, argument));
    });
  });
}
