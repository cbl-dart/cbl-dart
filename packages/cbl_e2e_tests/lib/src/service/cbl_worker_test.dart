import 'package:cbl/src/service/cbl_service_api.dart';
import 'package:cbl/src/service/cbl_worker.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('CblWorker', () {
    test('call Ping endpoint', () async {
      final worker = CblWorker(debugName: '');

      await worker.start();
      addTearDown(worker.stop);

      expect(worker.channel.call(PingRequest()), completion(isA<DateTime>()));
    });

    test('using channel of not started worker throws', () async {
      final worker = CblWorker(debugName: '');

      expect(() => worker.channel.call(PingRequest()), throwsStateError);

      await worker.start();
      await worker.stop();

      expect(() => worker.channel.call(PingRequest()), throwsStateError);
    });
  });
}
