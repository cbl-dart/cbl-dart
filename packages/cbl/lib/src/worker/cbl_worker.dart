import 'dart:async';

import 'package:cbl_ffi/cbl_ffi.dart';
import 'package:synchronized/synchronized.dart';

import '../errors.dart';
import 'cbl_worker/blob.dart';
import 'cbl_worker/database.dart';
import 'cbl_worker/query.dart';
import 'cbl_worker/replicator.dart';
import 'request_router.dart';
import 'worker.dart';

export 'cbl_worker/blob.dart';
export 'cbl_worker/database.dart';
export 'cbl_worker/query.dart';
export 'cbl_worker/replicator.dart';
export 'worker.dart';

/// [WorkerDelegate] for CouchbaseLite workers.
class CblWorkerDelegate extends WorkerDelegate {
  CblWorkerDelegate(this.libraries);

  /// The library configuration to use with [CBLBindings] in the worker.
  final Libraries libraries;

  late final RequestRouter _router;

  @override
  Future<void> initialize() async {
    CBLBindings.initInstance(libraries);

    _router = _createRouter();
  }

  @override
  Future<WorkerResponse> handleRequest(WorkerRequest request) =>
      _router.handleRequest(request);
}

RequestRouter _createRouter() {
  final _router = RequestRouter();

  // Run every handler in a memory management [Arena].
  _router.addMiddleware(_runInArenaMiddleware());

  // Only [BaseException]s are expected to be throw from handlers. Other
  // exceptions should crash the [Worker].
  _router.setErrorHandler(rootedErrorHandler<BaseException>());

  addDatabaseHandlersToRouter(_router);
  addQueryHandlersToRouter(_router);
  addBlobHandlersToRouter(_router);
  addReplicatorHandlersToRouter(_router);

  return _router;
}

/// Returns a [WorkerRequestHandlerMiddleware] wich runs the next handler in a
/// memory management [Arena].
WorkerRequestHandlerMiddleware _runInArenaMiddleware() =>
    (request, next) => runArena(() => next(request));

/// A manager of [Worker]s which use a [CblWorkerDelegate].
class CblWorkerManager {
  CblWorkerManager({required Libraries libraries}) : libraries = libraries;

  /// The dynamic libraries configuration for the [Worker]s.
  final Libraries libraries;

  final _lock = Lock();
  final _workers = <String, Worker>{};

  /// If it does not exist creates and returns the [Worker] with given [id].
  Future<Worker> getWorker({required String id}) =>
      _lock.synchronized(() async {
        final worker = _workers.putIfAbsent(id, () => _createCblWorker(id));
        if (!worker.running) await worker.start();
        return worker;
      });

  /// Stops all the Workers.
  Future<void> dispose() => _lock.synchronized(() async {
        await Future.wait(_workers.values.map((worker) => worker.stop()));
        _workers.clear();
      });

  Worker _createCblWorker(String id) =>
      Worker(id: id, delegate: CblWorkerDelegate(libraries));
}
