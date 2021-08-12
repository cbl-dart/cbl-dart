import 'package:cbl/src/support/dart_finalizer.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('DartFinalizer', () {
    test('run finalizer when object is garbage collected', () async {
      var didCallFinalizer = false;
      final memory = <String>[];

      Future<void> allocateMemory() async {
        if (didCallFinalizer) {
          return;
        }

        // This should allocate a string of ~10 MB since Dart uses UTF16
        // strings.
        memory.add('.' * 5 * 1024 * 1024);

        // The finalizer is invoked from the message queue and to allow it to
        // execute, the next execution of this function must not be scheduled on
        // the microtask queue. Otherwise the microtask never becomes empty and
        // the message queue is never processed.
        return Future(allocateMemory);
      }

      dartFinalizerRegistry.registerFinalizer(Object(), () {
        didCallFinalizer = true;
      });

      await allocateMemory();
    });
  });
}
