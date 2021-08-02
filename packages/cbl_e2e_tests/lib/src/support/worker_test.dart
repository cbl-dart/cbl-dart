import 'package:cbl/src/support/worker/request_router.dart';
import 'package:cbl/src/support/worker/worker.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

class Pong {}

class Ping extends WorkerRequest<Pong> {}

class Exception extends WorkerRequest<Never> {}

class Unhandled extends WorkerRequest<void> {}

class Crash extends WorkerRequest<Never> {}

class WorkerTestDelegate extends WorkerDelegate {
  late final RequestRouter _router;

  @override
  Future<void> initialize() async {
    _router = RequestRouter();

    _router.addHandler((Ping request) => Pong());
    _router.addHandler(
        (Exception request) => throw 'Exception thrown from handler');
  }

  @override
  Future<WorkerResponse> handleRequest(WorkerRequest request) async {
    if (request is Crash) throw 'This is a requested crash';

    return _router.handleRequest(request);
  }
}

Worker testWorker() => Worker(id: 'test', delegate: WorkerTestDelegate());

void main() {
  setupTestBinding();

  group('Worker', () {
    group('execute', () {
      test('should respond to ping request with pong', () async {
        final worker = testWorker();
        await worker.start();

        final response = await worker.execute<Object?>(Ping());
        expect(response, isA<Pong>());

        await worker.stop();
      });

      test('should throw RequestHandlerNotFound when request cannot be handled',
          () async {
        final worker = testWorker();
        await worker.start();

        await expectLater(worker.execute(Unhandled()),
            throwsA(isA<RequestHandlerNotFound>()));

        await worker.stop();
      });

      test('should throw WorkerCrashedError when worker crashes', () async {
        final worker = testWorker();
        await worker.start();

        await expectLater(
          worker.execute(Crash()),
          throwsA(isA<WorkerCrashedError>().having(
            (it) => it.message,
            'message',
            'This is a requested crash',
          )),
        );

        await worker.stop();
      });

      test('should restart Worker when it crashes', () async {
        final worker = testWorker();
        await worker.start();

        await worker.execute(Crash()).then((value) {}, onError: (dynamic _) {});

        await Future<void>.delayed(Duration(milliseconds: 500));

        expect(worker.running, isTrue);

        await worker.stop();
      });
    });
  });

  group('RequestRouter', () {
    test('should return errors from handlers to caller', () async {
      final worker = testWorker();
      await worker.start();

      await expectLater(
        worker.execute(Exception()),
        throwsA('Exception thrown from handler'),
      );

      await worker.stop();
    });
  });
}
