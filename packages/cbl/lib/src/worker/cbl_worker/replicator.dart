import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../../replicator.dart';
import '../../utils.dart';
import '../request_router.dart';
import '../worker.dart';
import 'shared.dart';

late final _bindings = CBLBindings.instance.replicator;

extension on ReplicatorType {
  CBLReplicatorType toCBLReplicatorType() => CBLReplicatorType.values[index];
}

extension on ProxyType {
  CBLProxyType toCBLProxyType() => CBLProxyType.values[index];
}

class NewReplicator extends WorkerRequest<TransferablePointer<CBLReplicator>> {
  NewReplicator(
    Pointer<CBLDatabase> database,
    Pointer<CBLEndpoint> endpoint,
    this.replicatorType,
    this.continuous,
    this.disableAutoPurge,
    this.maxAttempts,
    this.maxAttemptWaitTime,
    this.heartbeat,
    Pointer<CBLAuthenticator>? authenticator,
    this.proxyType,
    this.proxyHostname,
    this.proxyPort,
    this.proxyUsername,
    this.proxyPassword,
    Pointer<FLDict>? headers,
    Uint8List? pinnedServerCertificate,
    Uint8List? trustedRootCertificates,
    Pointer<FLArray>? channels,
    Pointer<FLArray>? documentIDs,
    Pointer<Callback>? pushFilter,
    Pointer<Callback>? pullFilter,
    Pointer<Callback>? conflictResolver,
  )   : database = database.toTransferablePointer(),
        endpoint = endpoint.toTransferablePointer(),
        authenticator = authenticator?.toTransferablePointer(),
        headers = headers?.toTransferablePointer(),
        pinnedServerCertificate = pinnedServerCertificate
            ?.let((it) => TransferableTypedData.fromList([it])),
        trustedRootCertificates = trustedRootCertificates
            ?.let((it) => TransferableTypedData.fromList([it])),
        channels = channels?.toTransferablePointer(),
        documentIDs = documentIDs?.toTransferablePointer(),
        pushFilter = pushFilter?.toTransferablePointer(),
        pullFilter = pullFilter?.toTransferablePointer(),
        conflictResolver = conflictResolver?.toTransferablePointer();

  final TransferablePointer<CBLDatabase> database;
  final TransferablePointer<CBLEndpoint> endpoint;
  final ReplicatorType replicatorType;
  final bool continuous;
  final bool? disableAutoPurge;
  final int? maxAttempts;
  final int? maxAttemptWaitTime;
  final int? heartbeat;
  final TransferablePointer<CBLAuthenticator>? authenticator;
  final ProxyType? proxyType;
  final String? proxyHostname;
  final int? proxyPort;
  final String? proxyUsername;
  final String? proxyPassword;
  final TransferablePointer<FLDict>? headers;
  final TransferableTypedData? pinnedServerCertificate;
  final TransferableTypedData? trustedRootCertificates;
  final TransferablePointer<FLArray>? channels;
  final TransferablePointer<FLArray>? documentIDs;
  final TransferablePointer<Callback>? pushFilter;
  final TransferablePointer<Callback>? pullFilter;
  final TransferablePointer<Callback>? conflictResolver;
}

TransferablePointer<CBLReplicator> newReplicator(NewReplicator request) =>
    _bindings
        .createReplicator(
          request.database.pointer,
          request.endpoint.pointer,
          request.replicatorType.toCBLReplicatorType(),
          request.continuous,
          request.disableAutoPurge,
          request.maxAttempts,
          request.maxAttemptWaitTime,
          request.heartbeat,
          request.authenticator?.pointer,
          request.proxyType?.toCBLProxyType(),
          request.proxyHostname,
          request.proxyPort,
          request.proxyUsername,
          request.proxyPassword,
          request.headers?.pointer,
          request.pinnedServerCertificate?.materialize().asUint8List(),
          request.trustedRootCertificates?.materialize().asUint8List(),
          request.channels?.pointer,
          request.documentIDs?.pointer,
          request.pushFilter?.pointer,
          request.pullFilter?.pointer,
          request.conflictResolver?.pointer,
        )
        .toTransferablePointer();

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

class GetReplicatorStatus extends WorkerRequest<ReplicatorStatus> {
  GetReplicatorStatus(Pointer<CBLReplicator> replicator)
      : replicator = replicator.toTransferablePointer();

  final TransferablePointer<CBLReplicator> replicator;
}

ReplicatorStatus getReplicatorStatus(GetReplicatorStatus request) =>
    _bindings.status(request.replicator.pointer).toReplicatorStatus();

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
  router.addHandler(newReplicator);
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
