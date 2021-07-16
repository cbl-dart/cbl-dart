import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('Dictionary', () {
    test('toString returns custom String representation', () async {
      final dictionary = MutableDictionary({
        'a': 'b',
        'c': ['d']
      });
      expect(dictionary.toString(), '{a: b, c: [d]}');
    });
  });
}
