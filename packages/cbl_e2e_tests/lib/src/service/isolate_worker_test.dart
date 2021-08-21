import 'dart:async';

import 'package:cbl/src/service/isolate_worker.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('IsolateWorker', () {
    test('start and stop worker', () async {
      final worker = testWorker();

      await worker.start();
      await worker.stop();
    });

    test('starting worker which is not in initial state throws', () async {
      final worker = testWorker();

      await worker.start();

      expect(worker.start, throwsStateError);

      await worker.stop();

      expect(worker.start, throwsStateError);
    });

    test('stopping worker which has not be started throws', () async {
      final worker = testWorker();

      expect(worker.stop, throwsStateError);

      await worker.start();
      await worker.stop();

      expect(worker.stop, throwsStateError);
    });
  });
}

// ignore: prefer_expression_function_bodies
IsolateWorker testWorker() {
  return IsolateWorker(delegate: TestWorkerDelegate());
}

class TestWorkerDelegate extends IsolateWorkerDelegate {
  @override
  FutureOr<void> dispose() {}

  @override
  FutureOr<void> initialize() {}
}
