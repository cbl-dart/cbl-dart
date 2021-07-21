import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('Endpoint', () {
    test('toString', () {
      expect(
        UrlEndpoint(Uri.parse('ws://host/db')).toString(),
        'UrlEndpoint(ws://host/db)',
      );
    });
  });
}
