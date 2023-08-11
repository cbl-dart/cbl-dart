// ignore: lines_longer_than_80_chars
// ignore_for_file: avoid_types_on_closure_parameters, prefer_void_to_null, prefer_constructors_over_static_methods

import 'dart:async';
import 'dart:isolate';

import 'package:stream_channel/isolate_channel.dart';

import '../support/utils.dart';
import 'channel.dart';
import 'serialization/serialization.dart';

abstract class IsolateWorkerDelegate {
  FutureOr<void> initialize();
  FutureOr<void> dispose();
}

class IsolateWorker {
  IsolateWorker({
    this.debugName,
    required this.delegate,
  });

  final String? debugName;
  final IsolateWorkerDelegate delegate;

  var _status = _WorkerStatus.initial;

  late final _onErrorCompleter = Completer<void>();
  late final Future<void> onError = _onErrorCompleter.future;
  late final StreamSubscription _onErrorSub;

  late final _onExitCompleter = Completer<void>();
  late final Future<void> _onExit = _onExitCompleter.future;
  late final StreamSubscription _onExitSub;

  late final Channel _controlChannel;
  late final Isolate _isolate;

  Future<void> start() async {
    _checkStatusIs(_WorkerStatus.initial);
    _status = _WorkerStatus.starting;

    _isolate = await Isolate.spawn(
      _main,
      _WorkerConfiguration(
        controlChannel: _setupControlChannel(),
        delegate: delegate,
      ),
      debugName: debugName,
      errorsAreFatal: true,
      onError: _setupErrorHandler(),
      onExit: _setupOnExitHandler(),
    );

    await _controlChannel.call(_InitializeDelegate());

    _status = _WorkerStatus.running;
  }

  Future<void> stop({Duration timeout = const Duration(seconds: 5)}) async {
    _checkStatusIs(_WorkerStatus.running);
    _status = _WorkerStatus.stopping;

    try {
      await Future(() async {
        // Tell the worker to clean up.
        await _controlChannel.call(_DisposeDelegate());
        // Wait for the isolate to exit normally.
        await Future.any([onError, _onExit]);
      }).timeout(timeout);
    } on TimeoutException {
      // Kill the isolate after it did not exit in time.
      _isolate.kill();
      // Wait for the isolate to finally exit.
      await Future.any([onError, _onExit]);
      rethrow;
    }

    await _close();

    _status = _WorkerStatus.stopped;
  }

  SendPort _setupControlChannel() {
    final receivePort = ReceivePort();

    _controlChannel = Channel(
      transport: IsolateChannel.connectReceive(receivePort),
      serializationRegistry: _workerSerializationRegistry(),
    );

    onError.onError(_close);

    return receivePort.sendPort;
  }

  SendPort _setupErrorHandler() {
    final receivePort = ReceivePort();

    _onErrorSub = receivePort.asyncExpand((Object? message) {
      final errorAndStackTrace = message! as List<Object?>;
      final error = errorAndStackTrace[0]!;
      final stackTrace =
          StackTrace.fromString(errorAndStackTrace[1]! as String);
      return Stream<void>.error(error, stackTrace);
    }).listen(null, onError: _onErrorCompleter.completeError);

    return receivePort.sendPort;
  }

  SendPort _setupOnExitHandler() {
    final receivePort = ReceivePort();

    _onExitSub = receivePort.listen(_onExitCompleter.complete);

    return receivePort.sendPort;
  }

  Future<void> _close([Object? error, StackTrace? stackTrace]) {
    if (error != null) {
      _status = _WorkerStatus.crashed;
    }

    return Future.wait([
      _controlChannel.close(error, stackTrace),
      _onErrorSub.cancel(),
      _onExitSub.cancel()
    ]);
  }

  void _checkStatusIs(_WorkerStatus lifecycle) {
    if (_status != lifecycle) {
      throw StateError(
        'Expected Worker to be ${lifecycle.name} but it was ${_status.name}.',
      );
    }
  }

  static void _main(_WorkerConfiguration config) {
    final delegate = config.delegate;
    final controlChannel = Channel(
      transport: IsolateChannel.connectSend(config.controlChannel),
      serializationRegistry: _workerSerializationRegistry(),
    );

    controlChannel
      ..addCallEndpoint((_InitializeDelegate _) => delegate.initialize())
      ..addCallEndpoint((_DisposeDelegate _) async {
        await delegate.dispose();
        // The close method must be called from outside the call handler because
        // it is not allowed to close a channel with pending conversations.
        // ignore: unawaited_futures
        Future.microtask(controlChannel.close);
      });
  }
}

enum _WorkerStatus {
  initial,
  starting,
  running,
  stopping,
  stopped,
  crashed,
}

class _WorkerConfiguration {
  _WorkerConfiguration({
    required this.controlChannel,
    required this.delegate,
  });

  final SendPort controlChannel;
  final IsolateWorkerDelegate delegate;
}

SerializationRegistry _workerSerializationRegistry() => SerializationRegistry()
  ..addSerializableCodec('Initialize', _InitializeDelegate.deserialize)
  ..addSerializableCodec('Dispose', _DisposeDelegate.deserialize);

class _InitializeDelegate extends Request<Null> {
  @override
  StringMap serialize(SerializationContext context) => {};

  static _InitializeDelegate deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      _InitializeDelegate();
}

class _DisposeDelegate extends Request<Null> {
  @override
  StringMap serialize(SerializationContext context) => {};

  static _DisposeDelegate deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      _DisposeDelegate();
}
