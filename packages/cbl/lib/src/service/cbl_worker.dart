import 'dart:async';
import 'dart:isolate';

import 'package:stream_channel/isolate_channel.dart';

import '../errors.dart';
import '../support/isolate.dart';
import '../support/tracing.dart';
import 'cbl_service.dart';
import 'cbl_service_api.dart';
import 'channel.dart';
import 'isolate_worker.dart';
import 'serialization/serialization.dart';

class CblWorker {
  CblWorker({
    this.serializationTarget = SerializationTarget.isolatePort,
    required this.debugName,
  });

  static Future<T> executeCall<T>(
    Request<T> request, {
    required String debugName,
  }) async {
    final worker = CblWorker(debugName: debugName);
    await worker.start();
    try {
      final result = await worker.channel.call(request);
      await worker.stop();
      return result;
    } on CouchbaseLiteException {
      await worker.stop();
      rethrow;
    }
  }

  final SerializationTarget serializationTarget;
  final String debugName;

  var _status = _WorkerStatus.initial;

  Channel get channel {
    _checkStatusIs(_WorkerStatus.running);
    return _channel;
  }

  late final Channel _channel;

  late final IsolateWorker _worker;

  Future<void> start() async {
    _checkStatusIs(_WorkerStatus.initial);
    _status = _WorkerStatus.starting;

    final receivePort = ReceivePort();

    _channel = Channel(
      transport: IsolateChannel.connectReceive(receivePort),
      serializationRegistry: cblServiceSerializationRegistry(),
      captureMessageContext: () =>
          currentTracingDelegate.captureTracingContext(),
    );

    _worker = IsolateWorker(
      debugName: 'CblWorker($debugName)',
      delegate: _ServiceWorkerDelegate(
        context: IsolateContext.instance,
        serializationType: serializationTarget,
        channel: receivePort.sendPort,
      ),
    )
      // ignore: unawaited_futures, void_checks
      ..onError.onError<Object>((error, stackTrace) {
        _status = _WorkerStatus.crashed;
        _channel.close(error, stackTrace);
        // ignore: only_throw_errors
        throw error;
      });

    await _worker.start();
    _status = _WorkerStatus.running;
  }

  Future<void> stop() async {
    _checkStatusIs(_WorkerStatus.running);
    _status = _WorkerStatus.stopping;

    await _worker.stop();
    await _channel.close();

    _status = _WorkerStatus.stopped;
  }

  void _checkStatusIs(_WorkerStatus status) {
    if (_status != status) {
      throw StateError(
        'Expected CblWorker to be ${status.name} but it was ${_status.name}.',
      );
    }
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

class _ServiceWorkerDelegate extends IsolateWorkerDelegate {
  _ServiceWorkerDelegate({
    required this.context,
    required this.channel,
    required this.serializationType,
  });

  final IsolateContext context;
  final SendPort channel;
  final SerializationTarget serializationType;

  late final Channel _serviceChannel;
  late final CblService _service;

  @override
  FutureOr<void> initialize() async {
    _serviceChannel = Channel(
      transport: IsolateChannel.connectSend(channel),
      serializationRegistry: cblServiceSerializationRegistry(),
      restoreMessageContext: (context, restore) =>
          currentTracingDelegate.restoreTracingContext(context, restore),
    );

    _service = CblService(channel: _serviceChannel);

    onTraceData = (data) => _service.channel.call(TraceDataRequest(data));

    await initSecondaryIsolate(context);
  }

  @override
  FutureOr<void> dispose() => Future.wait([
        _service.dispose(),
        _serviceChannel.close(),
      ]);
}
