import 'package:cbl/src/worker/worker.dart';

import 'test_bindings.dart';
import 'test_utils.dart';

void main() {
  testEnvironmentSetup();

  late final libraries = CblE2eTestBindings.instance.libraries;

  group('Worker', () {
    group('makeRequest', () {
      test('should respond to ping request with pong', () async {
        final worker = Worker('ID', libraries);
        await worker.start();

        final response = await worker.makeRequest<String>('ping');
        expect(response, equals('pong'));

        await worker.stop();
      });

      test('should throw UnhandledWorkerRequest when request cannot be handled',
          () async {
        final worker = Worker('ID', libraries);
        await worker.start();

        await expectLater(
          worker.makeRequest<void>('x'),
          throwsA(isA<UnhandledWorkerRequest>()),
        );

        await worker.stop();
      });

      test('should throw WorkerCrashedError when worker crashes', () async {
        final worker = Worker('ID', libraries);
        await worker.start();

        await expectLater(
          worker.makeRequest<void>('crash'),
          throwsA(isA<WorkerCrashedError>().having(
            (it) => it.message,
            'message',
            equals('This is a requested crash'),
          )),
        );

        await worker.stop();
      });

      test('should restart Worker when it crashes', () async {
        final worker = Worker('ID', libraries);
        await worker.start();

        await worker
            .makeRequest<void>('crash')
            .then((value) {}, onError: (dynamic _) {});

        await Future<void>.delayed(Duration(milliseconds: 200));

        expect(worker.running, isTrue);

        await worker.stop();
      });
    });
  });

  group('WorkerManager', () {
    test('getWorker should return a running Worker', () async {
      final pool = WorkerManager(libraries: libraries);

      final worker = await pool.getWorker(id: 'a');

      expect(await worker.makeRequest<String>('ping'), equals('pong'));

      await pool.dispose();
    });
  });
}
