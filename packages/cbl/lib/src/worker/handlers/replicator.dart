import '../../bindings/bindings.dart';
import '../../errors.dart';
import '../../ffi_utils.dart';
import '../../replicator.dart';
import '../worker.dart';
import 'shared.dart';

late final _bindings = CBLBindings.instance.replicator;

class NewReplicator extends ObjectRequest {
  NewReplicator(int address) : super(address);
}

int newReplicator(NewReplicator request) => _bindings
    .makeNew(request.pointer.cast(), globalError)
    .checkResultAndError()
    .address;

class ResetReplicatorCheckpoint extends ObjectRequest {
  ResetReplicatorCheckpoint(int address) : super(address);
}

void resetReplicatorCheckpoint(ResetReplicatorCheckpoint request) =>
    _bindings.resetCheckpoint(request.pointer.cast());

class StartReplicator extends ObjectRequest {
  StartReplicator(int address) : super(address);
}

void startReplicator(StartReplicator request) =>
    _bindings.start(request.pointer.cast());

class StopReplicator extends ObjectRequest {
  StopReplicator(int address) : super(address);
}

void stopReplicator(StopReplicator request) =>
    _bindings.stop(request.pointer.cast());

class SetReplicatorHostReachable extends ObjectRequest {
  SetReplicatorHostReachable(int address, this.reachable) : super(address);
  final bool reachable;
}

void setReplicatorHostReachable(SetReplicatorHostReachable request) =>
    _bindings.setHostReachable(request.pointer.cast(), request.reachable.toInt);

class SetReplicatorSuspended extends ObjectRequest {
  SetReplicatorSuspended(int address, this.suspended) : super(address);
  final bool suspended;
}

void setReplicatorSuspended(SetReplicatorSuspended request) =>
    _bindings.setSuspended(request.pointer.cast(), request.suspended.toInt);

class GetReplicatorStatus extends ObjectRequest {
  GetReplicatorStatus(int address) : super(address);
}

ReplicatorStatus getReplicatorStatus(GetReplicatorStatus request) =>
    _bindings.status(request.pointer.cast()).toReplicatorStatus();

class GetReplicatorPendingDocumentIDs extends ObjectRequest {
  GetReplicatorPendingDocumentIDs(int address) : super(address);
}

int getReplicatorPendingDocumentIDs(GetReplicatorPendingDocumentIDs request) =>
    _bindings
        .pendingDocumentIDs(request.pointer.cast(), globalError)
        .checkResultAndError()
        .address;

class GetReplicatorIsDocumentPening extends ObjectRequest {
  GetReplicatorIsDocumentPening(int address, this.docId) : super(address);
  final String docId;
}

bool getReplicatorIsDocumentPening(GetReplicatorIsDocumentPening request) =>
    _bindings
        .isDocumentPending(
          request.pointer.cast(),
          request.docId.asUtf8Scoped,
          globalError,
        )
        .toBool
        .checkResultAndError();

class AddReplicatorChangeListener extends ObjectRequest {
  AddReplicatorChangeListener(int address, this.listenerId) : super(address);
  final int listenerId;
}

void addReplicatorChangeListener(AddReplicatorChangeListener request) =>
    _bindings.addChangeListener(request.pointer.cast(), request.listenerId);

class AddReplicatorDocumentListener extends ObjectRequest {
  AddReplicatorDocumentListener(int address, this.listenerId) : super(address);
  final int listenerId;
}

void addReplicatorDocumentListener(AddReplicatorDocumentListener request) =>
    _bindings.addDocumentListener(request.pointer.cast(), request.listenerId);

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
