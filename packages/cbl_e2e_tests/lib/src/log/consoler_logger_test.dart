import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('ConsolerLogger', () {
    test('get and set level', () {
      final initialLogLevel = Log.console.level;
      addTearDown(() => Log.console.level = initialLogLevel);

      // The initial log level.
      expect(Log.console.level, LogLevel.info);

      Log.console.level = LogLevel.verbose;
      expect(Log.console.level, LogLevel.verbose);
    });
  });
}
