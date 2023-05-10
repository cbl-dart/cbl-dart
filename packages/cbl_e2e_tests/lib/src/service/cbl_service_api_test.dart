import 'package:cbl/cbl.dart';
import 'package:cbl/src/service/cbl_service_api.dart';
import 'package:cbl/src/service/serialization/serialization.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  // These tests verify serialization of objects which are not already covered
  // by other tests, because they are not typical exchanged in messages.
  group('cblServiceSerializationRegistry', () {
    final registry = cblServiceSerializationRegistry();
    final context = SerializationContext(
      registry: registry,
      target: SerializationTarget.json,
    );

    T roundTrip<T extends Object>(T value) =>
        context.deserializeAs(context.serialize<T>(value))!;

    test('de/serialize PingRequest', () {
      final exception = PingRequest();
      roundTrip(exception);
    });

    test('de/serialize PosixException', () {
      final exception = PosixException('a', 42);
      final result = roundTrip(exception);

      expect(result.message, 'a');
      expect(result.code, 42);
    });

    test('de/serialize SQLiteException', () {
      final exception = SQLiteException('a', 42);
      final result = roundTrip(exception);

      expect(result.message, 'a');
      expect(result.code, 42);
    });

    test('de/serialize NetworkException', () {
      final exception = NetworkException('a', NetworkErrorCode.dnsFailure);
      final result = roundTrip(exception);

      expect(result.message, 'a');
      expect(result.code, NetworkErrorCode.dnsFailure);
    });

    test('de/serialize HttpException', () {
      final exception = HttpException('a', HttpErrorCode.authRequired);
      final result = roundTrip(exception);

      expect(result.message, 'a');
      expect(result.code, HttpErrorCode.authRequired);
    });

    test('de/serialize WebSocketException', () {
      final exception =
          WebSocketException('a', WebSocketErrorCode.abnormalClose);
      final result = roundTrip(exception);

      expect(result.message, 'a');
      expect(result.code, WebSocketErrorCode.abnormalClose);
    });

    test('de/serialize FleeceException', () {
      final exception = FleeceException('a');
      final result = roundTrip(exception);

      expect(result.message, 'a');
    });

    test('de/serialize NotFoundException', () {
      final exception = NotFoundException(0, 'a');
      final result = roundTrip(exception);

      expect(result.id, 0);
      expect(result.type, 'a');
      expect(
        result.toString(),
        'NotFound: Could not find object of type a with id 0',
      );
    });
  });
}
