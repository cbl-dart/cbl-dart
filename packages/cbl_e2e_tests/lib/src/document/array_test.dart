import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('Array', () {
    test('toString returns custom String representation', () async {
      final array = MutableArray([
        'a',
        {'b': 'c'}
      ]);
      expect(array.toString(), '[a, {b: c}]');
    });
  });
}
