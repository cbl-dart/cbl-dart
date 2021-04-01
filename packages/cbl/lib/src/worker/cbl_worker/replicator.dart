import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../../errors.dart';
import '../../replicator.dart';
import '../request_router.dart';
import 'shared.dart';

late final _bindings = CBLBindings.instance.replicator;

class NewReplicator extends ObjectRequest<CBLDartReplicatorConfiguration, int> {
  NewReplicator(Pointer<CBLDartReplicatorConfiguration> config) : super(config);
}

int newReplicator(NewReplicator request) => _bindings
    .makeNew(request.object, globalError)
    .checkResultAndError()
    .address;

class ResetReplicatorCheckpoint extends ObjectRequest<CBLReplicator, void> {
  ResetReplicatorCheckpoint(Pointer<CBLReplicator> replicator)
      : super(replicator);
}

void resetReplicatorCheckpoint(ResetReplicatorCheckpoint request) =>
    _bindings.resetCheckpoint(request.object);

class StartReplicator extends ObjectRequest<CBLReplicator, void> {
  StartReplicator(Pointer<CBLReplicator> replicator) : super(replicator);
}

void startReplicator(StartReplicator request) =>
    _bindings.start(request.object);

class StopReplicator extends ObjectRequest<CBLReplicator, void> {
  StopReplicator(Pointer<CBLReplicator> replicator) : super(replicator);
}

void stopReplicator(StopReplicator request) => _bindings.stop(request.object);

class SetReplicatorHostReachable extends ObjectRequest<CBLReplicator, void> {
  SetReplicatorHostReachable(Pointer<CBLReplicator> replicator, this.reachable)
      : super(replicator);
  final bool reachable;
}

void setReplicatorHostReachable(SetReplicatorHostReachable request) =>
    _bindings.setHostReachable(request.object, request.reachable.toInt());

class SetReplicatorSuspended extends ObjectRequest<CBLReplicator, void> {
  SetReplicatorSuspended(Pointer<CBLReplicator> replicator, this.suspended)
      : super(replicator);
  final bool suspended;
}

void setReplicatorSuspended(SetReplicatorSuspended request) =>
    _bindings.setSuspended(request.object, request.suspended.toInt());

class GetReplicatorStatus
    extends ObjectRequest<CBLReplicator, ReplicatorStatus> {
  GetReplicatorStatus(Pointer<CBLReplicator> replicator) : super(replicator);
}

ReplicatorStatus getReplicatorStatus(GetReplicatorStatus request) =>
    _bindings.status(request.object).toReplicatorStatus();

class GetReplicatorPendingDocumentIDs
    extends ObjectRequest<CBLReplicator, int> {
  GetReplicatorPendingDocumentIDs(Pointer<CBLReplicator> replicator)
      : super(replicator);
}

int getReplicatorPendingDocumentIDs(GetReplicatorPendingDocumentIDs request) =>
    _bindings
        .pendingDocumentIDs(request.object, globalError)
        .checkResultAndError()
        .address;

class GetReplicatorIsDocumentPening extends ObjectRequest<CBLReplicator, bool> {
  GetReplicatorIsDocumentPening(Pointer<CBLReplicator> replicator, this.docId)
      : super(replicator);
  final String docId;
}

bool getReplicatorIsDocumentPening(GetReplicatorIsDocumentPening request) =>
    _bindings
        .isDocumentPending(
          request.object,
          request.docId.toNativeUtf8().withScoped(),
          globalError,
        )
        .toBool()
        .checkResultAndError();

class AddReplicatorChangeListener extends ObjectRequest<CBLReplicator, void> {
  AddReplicatorChangeListener(
      Pointer<CBLReplicator> replicator, this.listenerAddress)
      : super(replicator);
  final int listenerAddress;
}

void addReplicatorChangeListener(AddReplicatorChangeListener request) =>
    _bindings.addChangeListener(
      request.object,
      request.listenerAddress.toPointer(),
    );

class AddReplicatorDocumentListener extends ObjectRequest<CBLReplicator, void> {
  AddReplicatorDocumentListener(
      Pointer<CBLReplicator> replicator, this.listenerAddress)
      : super(replicator);
  final int listenerAddress;
}

void addReplicatorDocumentListener(AddReplicatorDocumentListener request) =>
    _bindings.addDocumentListener(
      request.object,
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
