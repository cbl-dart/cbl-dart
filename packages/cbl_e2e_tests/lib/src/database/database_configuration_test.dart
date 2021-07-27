import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('DatabaseConfiguration', () {
    test('default', () {
      final config = DatabaseConfiguration();
      // Directory is the default directory provided by the CBL C SDK.
      expect(config.directory, isNotEmpty);
    });

    test('from', () {
      final config = DatabaseConfiguration(directory: 'A');
      final copy = DatabaseConfiguration.from(config);
      expect(copy, config);
    });

    test('==', () {
      DatabaseConfiguration a;
      DatabaseConfiguration b;

      a = DatabaseConfiguration(directory: 'A');
      expect(a, a);

      b = DatabaseConfiguration(directory: 'A');
      expect(a, b);

      b = DatabaseConfiguration(directory: 'B');
      expect(b, isNot(a));
    });

    test('toString', () {
      final config = DatabaseConfiguration(directory: 'A');
      expect(config.toString(), 'DatabaseConfiguration(directory: A)');
    });
  });
}
