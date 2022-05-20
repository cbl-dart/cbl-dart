import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:cbl/src/service/isolate_worker.dart';

import '../test_binding.dart';

bool _isEnabled = (Platform.environment['ENABLE_TIME_BOMB'] != null &&
        Platform.environment['ENABLE_TIME_BOMB'] != 'false') ||
    // ignore: do_not_use_environment
    const bool.fromEnvironment('enableTimeBomb');
Duration _testTimeout = const Duration(minutes: 10);

/// Sets up test hooks to start and stop a time bomb, to timeout tests in a
/// deadlock safe way.
///
/// To actually enable the time bomb, either the process environment variable
/// `ENABLE_TIME_BOMB` must be set and not `false` or the Dart environment
/// variable `enableTimeBomb` must be `true`.
///
/// See [startTimeBomb] and [stopTimeBomb] for more information.
void setupTestTimeBomb() {
  if (!_isEnabled) {
    return;
  }
  setUpAll(() => startTimeBomb(_testTimeout));
  tearDownAll(stopTimeBomb);
}

Future<IsolateWorker>? _worker;

/// Starts a time bomb which will crash the process after a [timeout].
///
/// The time bomb runs in its own isolate, so even if the current isolate
/// encounters a deadlock, the time bomb with go off.
///
/// Once the time bomb has been started it can be stopped through
/// [stopTimeBomb].
///
/// Once started, the time bomb cannot be started again, even after having been
/// stopped.
Future<void> startTimeBomb(Duration timeout) async {
  assert(_worker == null);

  _worker = Future(() async {
    final worker = _timeBombWorker(timeout);
    await worker.start();
    return worker;
  });
}

/// Stops a time bomb which has been started through [startTimeBomb].
Future<void> stopTimeBomb() async {
  assert(_worker != null);

  final worker = await _worker!;
  await worker.stop();
}

// === Time bomb worker ========================================================

IsolateWorker _timeBombWorker(Duration timeout) => IsolateWorker(
      delegate: _TimeBombWorkerDelegate(timeout),
      debugName: 'TimeBomb($timeout)',
    );

class _TimeBombWorkerDelegate extends IsolateWorkerDelegate {
  _TimeBombWorkerDelegate(this.timeout);

  final Duration timeout;
  late Timer _timer;

  @override
  FutureOr<void> initialize() {
    _timer = Timer(timeout, _abort);
  }

  @override
  FutureOr<void> dispose() {
    _timer.cancel();
  }
}

// === Abort function ==========================================================

final _stdLib = Platform.isWindows
    ? DynamicLibrary.open('ucrtbase.dll')
    : DynamicLibrary.process();

final _abort =
    _stdLib.lookupFunction<Void Function(), void Function()>('abort');
