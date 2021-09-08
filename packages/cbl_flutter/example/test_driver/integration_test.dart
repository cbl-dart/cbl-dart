import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
      // The timeout is chosen to be shortly after the time bomb test timeout in
      // `utils/time_bomb.dart` in `cbl_e2e_tests`.
      timeout: const Duration(minutes: 12),
    );
