import 'dart:async';
import 'dart:isolate';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:synchronized/synchronized.dart';

/// Base class for all worker requests.
///
/// [T] is the type of the response to the request.
@immutable
abstract class WorkerRequest<T extends Object?> {
  const WorkerRequest();
}

/// The response to a [WorkerRequest].
class WorkerResponse<T extends Object?> {
  /// Creates a response for a request wich was successfully completed with
  /// a [result].
  WorkerResponse.success(
    T result,
  )   : error = null,
        value = result;

  /// Creates a response for a request wich failed with an [error].
  WorkerResponse.error(Object error)
      : error = error,
        value = null;

  final Object? error;

  final T? value;
}

extension _WorkerResponseExt<T> on WorkerResponse<T> {
  Future<T> toFuture() =>
      error == null ? Future.value(value) : Future.error(error!);
}

/// The Worker crashed because of an unhandled exception.
class WorkerCrashedError implements Exception {
  WorkerCrashedError(this.message);

  /// A description of the error.
  final String message;

  @override
  String toString() => 'WorkerCrashedError(message: $message)';
}

/// Interface for executing [WorkerRequest]s.
abstract class WorkerExecutor {
  /// Executes [request] on a Worker, waits for a response and returns
  /// that response.
  ///
  /// The Worker can also respond with an error if the request failed. In that
  /// case the returned Future rejects with that error.
  ///
  /// If the Worker does not understand the request the returned Future rejects
  /// with [UnsupportedError].
  ///
  /// If the Worker crashes while the request is pending the returned Future
  /// rejects with [WorkerCrashedError].
  Future<R> execute<R>(WorkerRequest<R> request);
}

/// A delegate wich implements the logic of a [Worker].
///
/// When creating a worker, you need to provide a delegate. This delegate is
/// sent to an [Isolate] through a [SendPort] and must only contain values
/// which can be sent over a `SendPort`. The worker isolate receives a copy of
/// the original delegate and calls its [initialize] method, before starting
/// to accept requests.
abstract class WorkerDelegate {
  /// Initializes this delegate in the worker isolate, before the worker starts
  /// to accept requests.
  Future<void> initialize() async {}

  /// Handles a [WorkerRequest] and returns a corresponding [WorkerResponse].
  Future<WorkerResponse> handleRequest(WorkerRequest request);
}

/// A worker executes [WorkerRequest]s in a separate [Isolate].
///
/// The logic of the worker is implemented by a [WorkerDelegate].
class Worker extends WorkerExecutor {
  /// Creates a new worker.
  factory Worker({
    required String id,
    required WorkerDelegate delegate,
  }) =>
      Worker._(id, delegate);

  Worker._(this.id, this._delegate);

  /// The id of this worker.
  final String id;

  /// The delegate of this worker.
  final WorkerDelegate _delegate;

  late final _log = Logger(_debugName);

  late final _debugName = 'Worker($id)';

  /// Lock which serializes access to this worker.
  final _lock = Lock();

  /// Whether this worker is running.
  bool get running => _running;
  var _running = false;

  /// This Isolate on which this worker executes requests.
  Isolate? _isolate;

  /// The SendPort which is connected to the worker Isolate's ReceivePort.
  SendPort? _isolateSendPort;

  StreamSubscription? _receivePortSub;

  /// Stream which emits all responses from the worker Isolate.
  Stream<_ResponseEnvelope>? _responseStream;

  /// Future which rejects with a [WorkerCrashedError] when the worker Isolate
  /// crashes.
  Future<void>? _onCrashed;

  /// Future which resolves when the worker Isolate exits.
  Future<void>? _onExited;

  void _debugIsNotRunning() {
    assert(_running != true, 'Worker is already running');
  }

  void _debugIsRunning() {
    assert(_running == true, 'Worker is not running');
  }

  /// Starts this Worker by spawning its Isolate and waiting for it to become
  /// ready.
  ///
  /// If the Worker is not able to start the returned Future rejects with
  /// [WorkerCrashedError].
  Future<void> start() => _lock.synchronized(() async {
        _debugIsNotRunning();

        final receivePort = ReceivePort();
        final sendPort = receivePort.sendPort;

        final responses = StreamController<_ResponseEnvelope>.broadcast();
        final onReady = Completer<void>();
        final onCrashed = Completer<void>();
        final onExited = Completer<void>();

        _responseStream = responses.stream;
        _onCrashed = onCrashed.future;
        _onExited = onExited.future;

        _receivePortSub = receivePort.listen((dynamic message) {
          if (message is _ResponseEnvelope) {
            responses.add(message);
          } else if (message is _WorkerReady) {
            _isolateSendPort = message.sendPort;
            onReady.complete();
          } else if (message is List) {
            final errorMessage = message.cast<String>();
            onCrashed.completeError(
              WorkerCrashedError(errorMessage[0]),
              StackTrace.fromString(errorMessage[1]),
            );
          } else if (message == 'exit') {
            onExited.complete();
          } else {
            throw StateError('Unexpected message from Worker: $message');
          }
        });

        try {
          _isolate = await Isolate.spawn(
            _main,
            _WorkerConfiguration(sendPort, _delegate),
            onError: sendPort,
            debugName: _debugName,
            errorsAreFatal: true,
            paused: true,
          );

          _isolate!.addOnExitListener(sendPort, response: 'exit');

          _isolate!.resume(_isolate!.pauseCapability!);

          await Future.any([onReady.future, _onCrashed!]);
        } catch (e) {
          _reset();
          rethrow;
        }

        // If we made it to here the worker is able to start.
        // If it crashes during a request we restart it.
        // ignore: unawaited_futures
        _onCrashed!.catchError((Object error, StackTrace stackTrace) {
          _log.severe(
            'Worker crashed. This is a bug. Restarting it...',
            error,
            stackTrace,
          );
          _reset();
          start().then((_) {
            _log.severe('Worker restarted.');
          });
        });

        _running = true;
      });

  /// Stops this Worker by killing its Isolate and waiting for it to exit.
  Future<void> stop() => _lock.synchronized(() async {
        _debugIsRunning();

        _isolate!.kill();

        await _onExited;

        _reset();
      });

  @override
  Future<R> execute<R>(WorkerRequest<R> request) =>
      _lock.synchronized(() async {
        _debugIsRunning();

        final requestEnvelope = _RequestEnvelope(request);

        final response = _responseStream!
            .cast<_ResponseEnvelope>()
            .where((it) => it.requestId == requestEnvelope.id)
            .map((it) => it.response)
            .asyncExpand((it) => it.toFuture().asStream())
            .first;

        _isolateSendPort!.send(requestEnvelope);

        await Future.any([response, _onCrashed!]);

        return response.then((it) => it as R);
      });

  void _reset() {
    _receivePortSub!.cancel();

    _running = false;
    _isolate = null;
    _isolateSendPort = null;
    _receivePortSub = null;
    _responseStream = null;
    _onCrashed = null;
    _onExited = null;
  }

  @override
  String toString() => 'Worker($id, running: $running)';

  static void _main(_WorkerConfiguration configuration) async {
    final receivePort = ReceivePort();
    final sendPort = configuration.sendPort;

    final delegate = configuration.delegate;

    await delegate.initialize();

    void handleRequest(_RequestEnvelope requestEnvelope) async {
      final response = await delegate.handleRequest(requestEnvelope.request);
      final responseEnvelope = _ResponseEnvelope(
        requestId: requestEnvelope.id,
        response: response,
      );
      sendPort.send(responseEnvelope);
    }

    receivePort.cast<_RequestEnvelope>().listen(handleRequest);

    // Sending ready message should be the last thing we do during
    // initialization.
    sendPort.send(_WorkerReady(receivePort.sendPort));
  }
}

class _WorkerConfiguration {
  _WorkerConfiguration(this.sendPort, this.delegate);

  final SendPort sendPort;
  final WorkerDelegate delegate;
}

class _WorkerReady {
  _WorkerReady(this.sendPort);

  final SendPort sendPort;
}

class _RequestEnvelope<T> {
  _RequestEnvelope(this.request);

  static var _nextId = 0;

  final int id = _nextId++;

  final WorkerRequest<T> request;
}

class _ResponseEnvelope {
  _ResponseEnvelope({required this.requestId, required this.response});

  final int requestId;

  final WorkerResponse response;
}

/// Interface for creating [Worker]s.
abstract class WorkerFactory {
  /// Creates and starts a [Worker] with given [id].
  Future<Worker> createWorker({required String id});
}

/// A [WorkerExecutor] which manages an inner [Worker], which is kept running
/// wile there are pending requests.
///
/// When [execute] is called, the worker is created if necessary. While there
/// are other requests pending the same worker is used to execute subsequent
/// requests. After the last pending request completes the worker is destroyed.
///
/// Worker cleanup is scheduled in a microtask so that the worker is not
/// destroyed between sequential requests.
class TransientWorkerExecutor extends WorkerExecutor {
  /// Creates a [WorkerExecutor] which manages an inner [Worker], which is kept
  /// running wile there are pending requests.
  TransientWorkerExecutor(this.debugName, this.workerFactory);

  /// The name of this executor for debugging purposes.
  final String debugName;

  /// The worker factory used to create the inner worker.
  final WorkerFactory workerFactory;

  int _workerLeases = 0;

  Worker? _worker;

  final _lock = Lock();

  @override
  Future<R> execute<R>(WorkerRequest<R> request) async {
    final worker = await _leaseWorker();

    try {
      return worker.execute(request);
    } finally {
      scheduleMicrotask(() => _returnWorker(worker));
    }
  }

  Future<Worker> _leaseWorker() async {
    _workerLeases++;
    await _updateWorker();
    return _worker!;
  }

  Future<void> _returnWorker(Worker worker) async {
    _workerLeases--;
    await _updateWorker();
  }

  Future<void> _updateWorker() => _lock.synchronized(() async {
        if (_workerLeases > 0 && _worker == null) {
          _worker = await workerFactory.createWorker(
            id: 'TransientWorker($debugName)',
          );
        }

        if (_workerLeases == 0 && _worker != null) {
          await _worker!.stop();
          _worker = null;
        }
      });

  @override
  String toString() => 'TransientWorkerExecutor($debugName)';
}
