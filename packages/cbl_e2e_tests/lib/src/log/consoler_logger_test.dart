import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('ConsolerLogger', () {
    late LogLevel originalLogLevel;
    setUpAll(() => originalLogLevel = Database.log.console.level);
    tearDownAll(() => Database.log.console.level = originalLogLevel);

    test('get and set level', () {
      Database.log.console.level = LogLevel.verbose;
      expect(Database.log.console.level, LogLevel.verbose);
    });
  });
}
