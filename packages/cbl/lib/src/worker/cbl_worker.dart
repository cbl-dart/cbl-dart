import 'dart:async';

import 'package:cbl_ffi/cbl_ffi.dart';

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
  Future<void> shutdown() async {
    CBLBindings.instance.dispose();
  }

  @override
  Future<WorkerResponse> handleRequest(WorkerRequest request) =>
      _router.handleRequest(request);
}

RequestRouter _createRouter() {
  final _router = RequestRouter();

  // Only [CBLErrorException]s are expected to be throw from handlers. Other
  // exceptions should crash the [Worker].
  _router.setErrorHandler(CBLErrorExceptionHandler());

  addDatabaseHandlersToRouter(_router);
  addQueryHandlersToRouter(_router);
  addBlobHandlersToRouter(_router);
  addReplicatorHandlersToRouter(_router);

  return _router;
}

/// Error handler which handles [CBLErrorException] by translating them to a
/// [BaseException].
ErrorHandler CBLErrorExceptionHandler() => (error, _) {
      if (error is CBLErrorException) {
        return WorkerResponse.error(translateCBLErrorException(error));
      }
    };

/// A factory of [Worker]s which use a [CblWorkerDelegate].
class CblWorkerFactory extends WorkerFactory {
  CblWorkerFactory({required Libraries libraries}) : libraries = libraries;

  /// The dynamic libraries configuration for the [Worker]s.
  final Libraries libraries;

  @override
  Future<Worker> createWorker({required String id}) async {
    final worker = _createCblWorker(id);
    await worker.start();
    return worker;
  }

  Worker _createCblWorker(String id) =>
      Worker(id: id, delegate: CblWorkerDelegate(libraries));
}
