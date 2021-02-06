import 'dart:async';
import 'dart:isolate';

import 'package:logging/logging.dart';
import 'package:synchronized/synchronized.dart';

import '../bindings/bindings.dart';
import '../errors.dart';
import '../ffi_utils.dart';
import 'handlers.dart';

/// The Worker crashed because of an internal error.
class WorkerCrashedError implements Exception {
  WorkerCrashedError(this.message, this.stackTrace);

  /// A description of the error.
  final String message;

  /// A stack trace of the error.
  final StackTrace stackTrace;

  @override
  String toString() => 'WorkerCrashedError(message: $message)';
}

/// A worker which executes requests on a separate worker Isolate.
class Worker {
  Worker(this.id, Libraries libraries) : _libraries = libraries;

  /// The id of this worker.
  final String id;

  final Libraries _libraries;

  late final _log = Logger(_debugName);

  late final _debugName = 'CouchbaseLiteWorker($id)';

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
  Future<void>? _error;

  /// Future which resolves when the worker Isolate exits.
  Future<void>? _exit;

  void _debugIsNotRunning() {
    assert(_running != true, 'Worker is already running');
  }

  void _debugIsRunning() {
    assert(_running == true, 'Worker is not running');
  }

  /// Starts this Worker by spawning it's Isolate and waiting for it to become
  /// ready.
  ///
  /// If the Worker is not able to start the returned Future rejects with
  /// [WorkerCrashedError].
  Future<void> start() => _lock.synchronized(() async {
        _debugIsNotRunning();

        final receivePort = ReceivePort();
        final sendPort = receivePort.sendPort;

        final responses = StreamController<_ResponseEnvelope>.broadcast();
        final ready = Completer<void>();
        final error = Completer<void>();
        final exit = Completer<void>();

        _responseStream = responses.stream;
        _error = error.future;
        _exit = exit.future;

        _receivePortSub = receivePort.listen((dynamic message) {
          if (message is _ResponseEnvelope) {
            responses.add(message);
          } else if (message is _WorkerReady) {
            _isolateSendPort = message.sendPort;
            ready.complete();
          } else if (message is List) {
            final errorMessage = message.cast<String>();
            error.completeError(WorkerCrashedError(
              errorMessage[0],
              StackTrace.fromString(errorMessage[1]),
            ));
          } else if (message == 'exit') {
            exit.complete();
          } else {
            throw StateError('Unexpected message from Worker: $message');
          }
        });

        try {
          _isolate = await Isolate.spawn(
            _main,
            _WorkerConfiguration(sendPort, _libraries),
            onError: sendPort,
            debugName: _debugName,
            errorsAreFatal: true,
            paused: true,
          );

          _isolate!.addOnExitListener(sendPort, response: 'exit');

          _isolate!.resume(_isolate!.pauseCapability!);

          await ready.future;
        } catch (e) {
          _reset();
          rethrow;
        }

        // If we made it to here the worker is able to start.
        // If it crashes during a request we restart it.
        // ignore: unawaited_futures
        _error!.catchError((Object error) {
          error = error as WorkerCrashedError;

          _log.severe(
            'Worker crashed. This is a bug. Restarting it...',
            error.message,
            error.stackTrace,
          );
          _reset();
          start().then((_) {
            _log.severe('Worker restarted.');
          });
        });

        _running = true;
      });

  /// Stops this Worker by killing it's Isolate and waiting for it to exit.
  Future<void> stop() => _lock.synchronized(() async {
        _debugIsRunning();

        _isolate!.kill();

        await _exit;

        _reset();
      });

  /// Sends [request] to the Worker Isolate, waits for a response and returns
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
  Future<T> makeRequest<T>(Object request) => _lock.synchronized(() async {
        _debugIsRunning();

        final requestEnvelope = _RequestEnvelope(request);

        final response = _responseStream!
            .cast<_ResponseEnvelope>()
            .where((it) => it.requestId == requestEnvelope.id)
            .asyncExpand<T>((it) => it.error != null
                ? Stream.error(it.error!)
                : Stream.value(it.result as T))
            .first;

        _isolateSendPort!.send(requestEnvelope);

        await Future.any([response, _error!]);

        return response;
      });

  void _reset() {
    _receivePortSub!.cancel();

    _running = false;
    _isolate = null;
    _isolateSendPort = null;
    _receivePortSub = null;
    _responseStream = null;
    _error = null;
    _exit = null;
  }

  @override
  String toString() => 'CouchbaseLiteWorker($id, running: $running)';

  static void _main(_WorkerConfiguration configuration) {
    final receivePort = ReceivePort();
    final sendPort = configuration.sendPort;

    CBLBindings.initInstance(configuration.libraries);

    final router = _configureRouter();

    receivePort
        .cast<_RequestEnvelope>()
        .listen((request) => router._handleRequest(sendPort, request));

    // Sending ready message should be the last thing we do during
    // initialization.
    sendPort.send(_WorkerReady(receivePort.sendPort));
  }
}

class _WorkerConfiguration {
  _WorkerConfiguration(this.sendPort, this.libraries);

  final SendPort sendPort;
  final Libraries libraries;
}

class _WorkerReady {
  _WorkerReady(this.sendPort);

  final SendPort sendPort;
}

class _RequestEnvelope {
  _RequestEnvelope(this.request);

  static var _nextId = 0;

  final int id = _nextId++;
  final Object request;

  _ResponseEnvelope successAnswer(Object? result) =>
      _ResponseEnvelope.success(requestId: id, result: result);

  _ResponseEnvelope errorAnswer(Object error) =>
      _ResponseEnvelope.error(requestId: id, error: error);
}

class _ResponseEnvelope {
  _ResponseEnvelope.success({
    required this.requestId,
    required Object? result,
  })   : error = null,
        result = result;

  _ResponseEnvelope.error({
    required this.requestId,
    required Object error,
  })   : error = error,
        result = null;

  final int requestId;
  final Object? error;
  final Object? result;
}

/// The error which is returned to the originator of a [Worker] request if it
/// cannot be handled.
class UnhandledWorkerRequest extends BaseException {
  UnhandledWorkerRequest([String message = 'Worker cannot handle this request'])
      : super(message);
}

/// A handler which responds to requests which have been sent to a [Worker].
///
/// The handler receives the [request] as it's argument and returns the
/// response. Exceptions thrown by the handler that extend [BaseException] are
/// signal an exceptional result and are forwarded to the caller. All other
/// exceptions crash the Worker.
///
/// Every call of this handler will be wrapped in [runArena]. You can just use
/// [scoped] in your implementation.
typedef WorkerRequestHandler<T> = dynamic Function(T request);

/// Router which handles requests to a [Worker] by dispatching them to
/// a [WorkerRequestHandler].
class RequestRouter {
  final _requestHandlers = <Object, WorkerRequestHandler<dynamic>>{};

  /// Adds [handler] to the set of registered handlers.
  void addHandler<T>(WorkerRequestHandler<T> handler) {
    assert(
      !_requestHandlers.containsKey(handler.runtimeType),
      'a handler for the same request type (${handler.runtimeType}) has '
      'already been added',
    );
    _requestHandlers[T] = (dynamic request) => handler(request as T);
  }

  void _handleRequest(SendPort sendPort, _RequestEnvelope envelope) {
    final request = envelope.request;
    final handler = _requestHandlers[request.runtimeType];
    if (handler != null) {
      _invokeHandler(sendPort, handler, envelope);
    } else {
      sendPort.send((envelope.errorAnswer(UnhandledWorkerRequest())));
    }
  }

  void _invokeHandler(
    SendPort sendPort,
    WorkerRequestHandler<Object> handler,
    _RequestEnvelope envelope,
  ) {
    runArena(() {
      try {
        sendPort.send(envelope.successAnswer(handler(envelope.request)));
      } on BaseException catch (e) {
        sendPort.send(envelope.errorAnswer(e));
      }
    });
  }
}

Object _internalRequestHandler(String method) {
  switch (method) {
    case 'ping':
      return 'pong';
    case 'crash':
      throw 'This is a requested crash';
    default:
      throw UnhandledWorkerRequest();
  }
}

RequestRouter _configureRouter() {
  final router = RequestRouter();

  router.addHandler(_internalRequestHandler);

  addDatabaseHandlersToRouter(router);
  addQueryHandlersToRouter(router);

  return router;
}

/// A manager of [Worker]s.
class WorkerManager {
  WorkerManager({required Libraries libraries}) : libraries = libraries;

  /// The dynamic libraries configuration for the [Worker]s.
  final Libraries libraries;

  final _lock = Lock();
  final _workers = <String, Worker>{};

  /// If it does not exist creates and returns the [Worker] with given [id].
  Future<Worker> getWorker({required String id}) =>
      _lock.synchronized(() async {
        final worker = _workers.putIfAbsent(id, () => Worker(id, libraries));
        if (!worker.running) await worker.start();
        return worker;
      });

  /// Stops all the Workers.
  Future<void> dispose() => _lock.synchronized(() async {
        await Future.wait(_workers.values.map((worker) => worker.stop()));
        _workers.clear();
      });
}
