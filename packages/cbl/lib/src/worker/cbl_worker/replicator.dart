import 'package:cbl_ffi/cbl_ffi.dart';

import '../../errors.dart';
import '../../replicator.dart';
import '../request_router.dart';
import 'shared.dart';

late final _bindings = CBLBindings.instance.replicator;

class NewReplicator extends ObjectRequest<int> {
  NewReplicator(int address) : super(address);
}

int newReplicator(NewReplicator request) => _bindings
    .makeNew(request.pointer.cast(), globalError)
    .checkResultAndError()
    .address;

class ResetReplicatorCheckpoint extends ObjectRequest<void> {
  ResetReplicatorCheckpoint(int address) : super(address);
}

void resetReplicatorCheckpoint(ResetReplicatorCheckpoint request) =>
    _bindings.resetCheckpoint(request.pointer.cast());

class StartReplicator extends ObjectRequest<void> {
  StartReplicator(int address) : super(address);
}

void startReplicator(StartReplicator request) =>
    _bindings.start(request.pointer.cast());

class StopReplicator extends ObjectRequest<void> {
  StopReplicator(int address) : super(address);
}

void stopReplicator(StopReplicator request) =>
    _bindings.stop(request.pointer.cast());

class SetReplicatorHostReachable extends ObjectRequest<void> {
  SetReplicatorHostReachable(int address, this.reachable) : super(address);
  final bool reachable;
}

void setReplicatorHostReachable(SetReplicatorHostReachable request) => _bindings
    .setHostReachable(request.pointer.cast(), request.reachable.toInt());

class SetReplicatorSuspended extends ObjectRequest<void> {
  SetReplicatorSuspended(int address, this.suspended) : super(address);
  final bool suspended;
}

void setReplicatorSuspended(SetReplicatorSuspended request) =>
    _bindings.setSuspended(request.pointer.cast(), request.suspended.toInt());

class GetReplicatorStatus extends ObjectRequest<ReplicatorStatus> {
  GetReplicatorStatus(int address) : super(address);
}

ReplicatorStatus getReplicatorStatus(GetReplicatorStatus request) =>
    _bindings.status(request.pointer.cast()).toReplicatorStatus();

class GetReplicatorPendingDocumentIDs extends ObjectRequest<int> {
  GetReplicatorPendingDocumentIDs(int address) : super(address);
}

int getReplicatorPendingDocumentIDs(GetReplicatorPendingDocumentIDs request) =>
    _bindings
        .pendingDocumentIDs(request.pointer.cast(), globalError)
        .checkResultAndError()
        .address;

class GetReplicatorIsDocumentPening extends ObjectRequest<bool> {
  GetReplicatorIsDocumentPening(int address, this.docId) : super(address);
  final String docId;
}

bool getReplicatorIsDocumentPening(GetReplicatorIsDocumentPening request) =>
    _bindings
        .isDocumentPending(
          request.pointer.cast(),
          request.docId.toNativeUtf8().withScoped(),
          globalError,
        )
        .toBool()
        .checkResultAndError();

class AddReplicatorChangeListener extends ObjectRequest<void> {
  AddReplicatorChangeListener(int address, this.listenerAddress)
      : super(address);
  final int listenerAddress;
}

void addReplicatorChangeListener(AddReplicatorChangeListener request) =>
    _bindings.addChangeListener(
      request.pointer.cast(),
      request.listenerAddress.toPointer(),
    );

class AddReplicatorDocumentListener extends ObjectRequest<void> {
  AddReplicatorDocumentListener(int address, this.listenerAddress)
      : super(address);
  final int listenerAddress;
}

void addReplicatorDocumentListener(AddReplicatorDocumentListener request) =>
    _bindings.addDocumentListener(
      request.pointer.cast(),
      request.listenerAddress.toPointer(),
    );

void addReplicatorHandlersToRouter(RequestRouter router) {
  router.addHandler(newReplicator);
  router.addHandler(resetReplicatorCheckpoint);
  router.addHandler(startReplicator);
  router.addHandler(stopReplicator);
  router.addHandler(setReplicatorHostReachable);
  router.addHandler(setReplicatorSuspended);
  router.addHandler(getReplicatorStatus);
  router.addHandler(getReplicatorPendingDocumentIDs);
  router.addHandler(getReplicatorIsDocumentPening);
  router.addHandler(addReplicatorChangeListener);
  router.addHandler(addReplicatorDocumentListener);
}
