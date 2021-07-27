import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('ConsolerLogger', () {
    test('get and set level', () {
      final initialLogLevel = Database.log.console.level;
      addTearDown(() => Database.log.console.level = initialLogLevel);

      // The initial log level.
      expect(Database.log.console.level, LogLevel.info);

      Database.log.console.level = LogLevel.verbose;
      expect(Database.log.console.level, LogLevel.verbose);
    });
  });
}
