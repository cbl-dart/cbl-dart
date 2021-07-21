import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../request_router.dart';
import '../worker.dart';
import 'shared.dart';

late final _bindings = CBLBindings.instance.replicator;

class StartReplicator extends WorkerRequest<void> {
  StartReplicator(Pointer<CBLReplicator> replicator, this.resetCheckpoint)
      : replicator = replicator.toTransferablePointer();

  final TransferablePointer<CBLReplicator> replicator;
  final bool resetCheckpoint;
}

void startReplicator(StartReplicator request) =>
    _bindings.start(request.replicator.pointer, request.resetCheckpoint);

class StopReplicator extends WorkerRequest<void> {
  StopReplicator(Pointer<CBLReplicator> replicator)
      : replicator = replicator.toTransferablePointer();

  final TransferablePointer<CBLReplicator> replicator;
}

void stopReplicator(StopReplicator request) =>
    _bindings.stop(request.replicator.pointer);

class SetReplicatorHostReachable extends WorkerRequest<void> {
  SetReplicatorHostReachable(Pointer<CBLReplicator> replicator, this.reachable)
      : replicator = replicator.toTransferablePointer();

  final TransferablePointer<CBLReplicator> replicator;
  final bool reachable;
}

void setReplicatorHostReachable(SetReplicatorHostReachable request) =>
    _bindings.setHostReachable(request.replicator.pointer, request.reachable);

class SetReplicatorSuspended extends WorkerRequest<void> {
  SetReplicatorSuspended(Pointer<CBLReplicator> replicator, this.suspended)
      : replicator = replicator.toTransferablePointer();

  final TransferablePointer<CBLReplicator> replicator;
  final bool suspended;
}

void setReplicatorSuspended(SetReplicatorSuspended request) =>
    _bindings.setSuspended(request.replicator.pointer, request.suspended);

class GetReplicatorStatus extends WorkerRequest<CBLReplicatorStatus> {
  GetReplicatorStatus(Pointer<CBLReplicator> replicator)
      : replicator = replicator.toTransferablePointer();

  final TransferablePointer<CBLReplicator> replicator;
}

CBLReplicatorStatus getReplicatorStatus(GetReplicatorStatus request) =>
    _bindings.status(request.replicator.pointer);

class GetReplicatorPendingDocumentIds
    extends WorkerRequest<TransferablePointer<FLDict>> {
  GetReplicatorPendingDocumentIds(Pointer<CBLReplicator> replicator)
      : replicator = replicator.toTransferablePointer();

  final TransferablePointer<CBLReplicator> replicator;
}

TransferablePointer<FLDict> getReplicatorPendingDocumentIds(
        GetReplicatorPendingDocumentIds request) =>
    _bindings
        .pendingDocumentIDs(request.replicator.pointer)
        .toTransferablePointer();

class GetReplicatorIsDocumentPening extends WorkerRequest<bool> {
  GetReplicatorIsDocumentPening(Pointer<CBLReplicator> replicator, this.docId)
      : replicator = replicator.toTransferablePointer();

  final TransferablePointer<CBLReplicator> replicator;
  final String docId;
}

bool getReplicatorIsDocumentPening(GetReplicatorIsDocumentPening request) =>
    _bindings.isDocumentPending(request.replicator.pointer, request.docId);

class AddReplicatorChangeListener extends WorkerRequest<void> {
  AddReplicatorChangeListener(
      Pointer<CBLReplicator> replicator, Pointer<Callback> listener)
      : replicator = replicator.toTransferablePointer(),
        listener = listener.toTransferablePointer();

  final TransferablePointer<CBLReplicator> replicator;
  final TransferablePointer<Callback> listener;
}

void addReplicatorChangeListener(AddReplicatorChangeListener request) =>
    _bindings.addChangeListener(
      request.replicator.pointer,
      request.listener.pointer,
    );

class AddReplicatorDocumentListener extends WorkerRequest<void> {
  AddReplicatorDocumentListener(
      Pointer<CBLReplicator> replicator, Pointer<Callback> listener)
      : replicator = replicator.toTransferablePointer(),
        listener = listener.toTransferablePointer();

  final TransferablePointer<CBLReplicator> replicator;
  final TransferablePointer<Callback> listener;
}

void addReplicatorDocumentListener(AddReplicatorDocumentListener request) =>
    _bindings.addDocumentReplicationListener(
      request.replicator.pointer,
      request.listener.pointer,
    );

void addReplicatorHandlersToRouter(RequestRouter router) {
  router.addHandler(startReplicator);
  router.addHandler(stopReplicator);
  router.addHandler(setReplicatorHostReachable);
  router.addHandler(setReplicatorSuspended);
  router.addHandler(getReplicatorStatus);
  router.addHandler(getReplicatorPendingDocumentIds);
  router.addHandler(getReplicatorIsDocumentPening);
  router.addHandler(addReplicatorChangeListener);
  router.addHandler(addReplicatorDocumentListener);
}
