import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cbl/cbl.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

/// The properties which end are the functions used to declare tests, groups
/// and lifecycle hooks. Per default these properties return the corresponding
/// functions from the `test` package.
///
/// Overriding these properties is useful to run tests with the
/// `integration_test` package, which requires that all tests are declared
/// through `widgetTest`.
abstract class CblE2eTestBinding {
  static void ensureInitialized(CblE2eTestBinding Function() createBinding) {
    if (_instance != null) return;
    _instance = createBinding();

    _instance!
      .._setupLogging()
      .._setupTestLifecycleHooks();
  }

  static CblE2eTestBinding? _instance;

  /// The global instance of [CblE2eTestBinding] by which is used by tests.
  static CblE2eTestBinding get instance => _instance!;

  /// The [Libraries] to use in tests.
  Libraries get libraries;

  /// Temporary directory for files created during tests, such as databases.
  FutureOr<String> resolveTmpDir();

  /// Temporary directory for tests.
  late final String tmpDir;

  StreamSubscription<void>? _cblTestLogger;

  Future<void> startTestLogger() async {
    _cblTestLogger = CouchbaseLite.logMessages().logToLogger();
  }

  Future<void> stopTestLogger() async {
    await _cblTestLogger!.cancel();
  }

  void _setupLogging() {
    Zone.root.run(() {
      Logger.root.onRecord.listen((record) {
        final stringBuilder = StringBuffer();

        stringBuilder.write('[${record.level.name}]'.padRight(9));
        stringBuilder.write(' | ');
        stringBuilder.write(record.loggerName.padRight(10).substring(0, 10));
        stringBuilder.write(' | ');
        stringBuilder.write(record.message);

        if (record.error != null) {
          stringBuilder.write('\nError: ${record.error}');
        }

        if (record.stackTrace != null) {
          stringBuilder.write('\n${record.stackTrace}');
        }

        print(stringBuilder.toString());
      });
    });
  }

  void _setupTestLifecycleHooks() {
    setUpAll(() async {
      tmpDir = await resolveTmpDir();
      await _cleanTestTmpDir();
      CouchbaseLite.initialize(libraries: libraries);
      await startTestLogger();
    });

    tearDownAll(() async {
      await stopTestLogger();
    });
  }

  Future _cleanTestTmpDir() async {
    final tmpDir = Directory(this.tmpDir);
    if (await tmpDir.exists()) {
      await tmpDir.delete(recursive: true);
    }
    await tmpDir.create(recursive: true);
  }
}

/// Alias of [CblE2eTestBinding.tmpDir].
late final tmpDir = CblE2eTestBinding.instance.tmpDir;

late final libraries = CblE2eTestBinding.instance.libraries;

/// Returns a unique name for a database every time it is called, which starts
/// with [testName].
String testDbName(String? testName) => [
      if (testName != null) testName,
      '${DateTime.now().millisecondsSinceEpoch}',
      '${Random().nextInt(10000)}'
    ].join('-');
