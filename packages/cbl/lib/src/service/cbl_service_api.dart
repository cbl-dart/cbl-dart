// ignore: lines_longer_than_80_chars
// ignore_for_file: prefer_constructors_over_static_methods,prefer_void_to_null

import 'dart:ffi';

import 'package:meta/meta.dart';

import '../bindings.dart';
import '../bindings/cblite.dart' as cblite;
import '../database.dart';
import '../database/database_configuration.dart';
import '../fleece/containers.dart';
import '../replication/authenticator.dart';
import '../replication/configuration.dart';
import '../replication/document_replication.dart';
import '../replication/endpoint.dart';
import '../replication/replicator.dart';
import '../replication/tls_identity.dart';
import '../support/utils.dart';
import '../tracing.dart';
import 'channel.dart';

// === Requests ================================================================

final class PingRequest extends Request<DateTime> {}

final class InstallTracingDelegate extends Request<void> {
  InstallTracingDelegate(this.delegate);

  final TracingDelegate delegate;
}

final class UninstallTracingDelegate extends Request<void> {
  UninstallTracingDelegate();
}

final class TraceDataRequest extends Request<void> {
  TraceDataRequest(this.data);

  final Object? data;
}

final class ReleaseObject extends Request<Null> {
  ReleaseObject(this.objectId);

  final int objectId;
}

final class RemoveChangeListener extends Request<Null> {
  RemoveChangeListener({required this.targetId, required this.listenerId});

  final int targetId;

  final int listenerId;
}

final class EncryptionKeyFromPassword extends Request<EncryptionKeyImpl> {
  EncryptionKeyFromPassword(this.password);

  final String password;
}

final class RemoveDatabase extends Request<bool> {
  RemoveDatabase(this.name, this.directory);

  final String name;
  final String? directory;
}

final class DatabaseExists extends Request<bool> {
  DatabaseExists(this.name, this.directory);

  final String name;
  final String? directory;
}

final class CopyDatabase extends Request<bool> {
  CopyDatabase(this.from, this.name, this.config);

  final String from;
  final String name;
  final DatabaseConfiguration? config;
}

final class OpenDatabase extends Request<DatabaseState> {
  OpenDatabase(this.name, this.config);

  final String name;
  final DatabaseConfiguration? config;
}

final class DeleteDatabase extends Request<Null> {
  DeleteDatabase(this.databaseId);

  final int databaseId;
}

final class GetScope extends Request<ScopeState?> {
  GetScope(this.databaseId, this.name);

  final int databaseId;
  final String name;
}

final class GetScopes extends Request<List<ScopeState>> {
  GetScopes(this.databaseId);

  final int databaseId;
}

final class GetCollection extends Request<CollectionState?> {
  GetCollection(this.scopeId, this.name);

  final int scopeId;
  final String name;
}

final class GetCollections extends Request<List<CollectionState>> {
  GetCollections(this.scopeId);

  final int scopeId;
}

final class CreateCollection extends Request<CollectionState> {
  CreateCollection(this.databaseId, this.scope, this.collection);

  final int databaseId;
  final String scope;
  final String collection;
}

final class DeleteCollection extends Request<Null> {
  DeleteCollection(this.databaseId, this.scope, this.collection);

  final int databaseId;
  final String scope;
  final String collection;
}

final class GetCollectionCount extends Request<int> {
  GetCollectionCount(this.collectionId);

  final int collectionId;
}

final class GetCollectionIndexNames extends Request<List<String>> {
  GetCollectionIndexNames(this.collectionId);

  final int collectionId;
}

final class GetCollectionIndex extends Request<int?> {
  GetCollectionIndex({required this.collectionId, required this.name});

  final int collectionId;
  final String name;
}

final class GetDocument extends Request<DocumentState?> {
  GetDocument(this.collectionId, this.documentId);

  final int collectionId;
  final String documentId;
}

final class SaveDocument extends Request<DocumentState?> implements SendAware {
  SaveDocument(this.collectionId, this.state, this.concurrencyControl);

  final int collectionId;
  final DocumentState state;
  final ConcurrencyControl concurrencyControl;

  @override
  void willSend() => state.willSend();

  @override
  void didReceive() => state.didReceive();
}

final class DeleteDocument extends Request<DocumentState?>
    implements SendAware {
  DeleteDocument(this.collectionId, this.state, this.concurrencyControl);

  final int collectionId;
  final DocumentState state;
  final ConcurrencyControl concurrencyControl;

  @override
  void willSend() => state.willSend();

  @override
  void didReceive() => state.didReceive();
}

final class PurgeDocument extends Request<Null> {
  PurgeDocument(this.collectionId, this.documentId);

  final int collectionId;
  final String documentId;
}

final class BeginDatabaseTransaction extends Request<Null> {
  BeginDatabaseTransaction({required this.databaseId});

  final int databaseId;
}

final class EndDatabaseTransaction extends Request<Null> {
  EndDatabaseTransaction({required this.databaseId, required this.commit});

  final int databaseId;
  final bool commit;
}

final class SetDocumentExpiration extends Request<Null> {
  SetDocumentExpiration({
    required this.collectionId,
    required this.documentId,
    required this.expiration,
  });

  final int collectionId;
  final String documentId;
  final DateTime? expiration;
}

final class GetDocumentExpiration extends Request<DateTime?> {
  GetDocumentExpiration({required this.collectionId, required this.documentId});

  final int collectionId;
  final String documentId;
}

final class AddCollectionChangeListener extends Request<Null> {
  AddCollectionChangeListener({
    required this.collectionId,
    required this.listenerId,
  });

  final int collectionId;
  final int listenerId;
}

final class CallCollectionChangeListener extends Request<Null> {
  CallCollectionChangeListener({
    required this.listenerId,
    required this.documentIds,
  });

  final int listenerId;
  final List<String> documentIds;
}

final class AddDocumentChangeListener extends Request<Null> {
  AddDocumentChangeListener({
    required this.collectionId,
    required this.documentId,
    required this.listenerId,
  });

  final int collectionId;
  final String documentId;
  final int listenerId;
}

final class CallDocumentChangeListener extends Request<Null> {
  CallDocumentChangeListener({required this.listenerId});

  final int listenerId;
}

final class PerformDatabaseMaintenance extends Request<Null> {
  PerformDatabaseMaintenance({required this.databaseId, required this.type});

  final int databaseId;
  final MaintenanceType type;
}

final class ChangeDatabaseEncryptionKey extends Request<Null> {
  ChangeDatabaseEncryptionKey({
    required this.databaseId,
    required this.encryptionKey,
  });

  final int databaseId;
  final EncryptionKey? encryptionKey;
}

final class CreateIndex extends Request<Null> {
  CreateIndex({
    required this.collectionId,
    required this.name,
    required this.spec,
  });

  final int collectionId;
  final String name;
  final CBLIndexSpec spec;
}

final class DeleteIndex extends Request<Null> {
  DeleteIndex({required this.collectionId, required this.name});

  final int collectionId;
  final String name;
}

final class BlobExists extends Request<bool> {
  BlobExists({required this.databaseId, required this.properties});

  final int databaseId;
  final StringMap properties;
}

final class ReadBlob extends Request<SendableData> {
  ReadBlob({required this.databaseId, required this.properties});

  final int databaseId;
  final StringMap properties;
}

final class SaveBlob extends Request<SaveBlobResponse> {
  SaveBlob({
    required this.databaseId,
    required this.contentType,
    required this.uploadId,
  });

  final int databaseId;
  final String contentType;
  final int uploadId;
}

final class ReadBlobUpload extends Request<SendableData> {
  ReadBlobUpload({required this.uploadId});

  final int uploadId;
}

final class CreateQuery extends Request<QueryState> {
  CreateQuery({
    required this.databaseId,
    required this.language,
    required this.queryDefinition,
  });

  final int databaseId;
  final CBLQueryLanguage language;
  final String queryDefinition;
}

final class SetQueryParameters extends Request<Null> implements SendAware {
  SetQueryParameters({required this.queryId, required Data? parameters})
    : _parameters = parameters?.let(SendableData.new);

  final int queryId;

  Data? get parameters => _parameters?.data;
  final SendableData? _parameters;

  @override
  void willSend() => _parameters?.willSend();

  @override
  void didReceive() => _parameters?.didReceive();
}

final class ExplainQuery extends Request<String> {
  ExplainQuery({required this.queryId});

  final int queryId;
}

final class ExecuteQuery extends Request<int> {
  ExecuteQuery({required this.queryId});

  final int queryId;
}

final class GetQueryResultSet extends Request<SendableValue> {
  GetQueryResultSet({required this.queryId, required this.resultSetId});

  final int queryId;
  final int resultSetId;
}

final class AddQueryChangeListener extends Request<Null> {
  AddQueryChangeListener({required this.queryId, required this.listenerId});

  final int queryId;
  final int listenerId;
}

final class CallQueryChangeListener extends Request<Null> {
  CallQueryChangeListener({
    required this.listenerId,
    required this.resultSetId,
  });

  final int listenerId;
  final int resultSetId;
}

final class BeginQueryIndexUpdate extends Request<IndexUpdaterState?> {
  BeginQueryIndexUpdate({required this.indexId, required this.limit});

  final int indexId;
  final int limit;
}

final class IndexUpdaterGetValue extends Request<SendableValue> {
  IndexUpdaterGetValue({required this.updaterId, required this.index});

  final int updaterId;
  final int index;
}

final class IndexUpdaterSetVector extends Request<Null> {
  IndexUpdaterSetVector({
    required this.updaterId,
    required this.index,
    required this.vector,
  });

  final int updaterId;
  final int index;
  final List<double>? vector;
}

final class IndexUpdaterSkipVector extends Request<Null> {
  IndexUpdaterSkipVector({required this.updaterId, required this.index});

  final int updaterId;
  final int index;
}

final class IndexUpdaterFinish extends Request<Null> {
  IndexUpdaterFinish({required this.updaterId});

  final int updaterId;
}

final class ServiceDatabaseEndpoint implements Endpoint {
  ServiceDatabaseEndpoint(this.databaseId);

  final int databaseId;
}

final class CreateReplicator extends Request<int> implements SendAware {
  CreateReplicator({
    required this.target,
    this.replicatorType = ReplicatorType.pushAndPull,
    this.continuous = false,
    Authenticator? authenticator,
    required this.acceptOnlySelfSignedServerCertificate,
    Data? pinnedServerCertificate,
    Data? trustedRootCertificates,
    this.headers,
    this.enableAutoPurge = true,
    this.heartbeat,
    this.maxAttempts,
    this.maxAttemptWaitTime,
    required this.collections,
  }) : _authenticator = authenticator,
       _pinnedServerCertificate = pinnedServerCertificate?.let(
         SendableData.new,
       ),
       _trustedRootCertificates = trustedRootCertificates?.let(
         SendableData.new,
       );

  final Endpoint target;
  final ReplicatorType replicatorType;
  final bool continuous;

  Authenticator? get authenticator => _authenticator;
  Authenticator? _authenticator;
  Pointer<cblite.CBLTLSIdentity>? _certificateAuthenticatorIdentityPointer;

  final bool acceptOnlySelfSignedServerCertificate;
  Data? get pinnedServerCertificate => _pinnedServerCertificate?.data;

  final SendableData? _pinnedServerCertificate;
  Data? get trustedRootCertificates => _trustedRootCertificates?.data;

  final SendableData? _trustedRootCertificates;
  final Map<String, String>? headers;
  final bool enableAutoPurge;
  final Duration? heartbeat;
  final int? maxAttempts;
  final Duration? maxAttemptWaitTime;
  final List<CreateReplicatorCollection> collections;

  @override
  void willSend() {
    if (_authenticator
        case final ClientCertificateAuthenticator authenticator) {
      final identity = authenticator.identity as FfiTlsIdentity;
      _certificateAuthenticatorIdentityPointer = identity.pointer;
      CBLBindings.instance.base.retainRefCounted(
        _certificateAuthenticatorIdentityPointer!.cast(),
      );
      _authenticator = null;
    }

    _pinnedServerCertificate?.willSend();
    _trustedRootCertificates?.willSend();
  }

  @override
  void didReceive() {
    if (_certificateAuthenticatorIdentityPointer case final pointer?) {
      final identity = FfiTlsIdentity.fromPointer(pointer, adopt: true);
      _authenticator = ClientCertificateAuthenticator(identity);
      _certificateAuthenticatorIdentityPointer = null;
    }

    _pinnedServerCertificate?.didReceive();
    _trustedRootCertificates?.didReceive();
  }
}

final class CreateReplicatorCollection {
  CreateReplicatorCollection({
    required this.collectionId,
    this.channels,
    this.documentIds,
    this.pushFilterId,
    this.pullFilterId,
    this.conflictResolverId,
  });

  final int collectionId;
  final List<String>? channels;
  final List<String>? documentIds;
  final int? pushFilterId;
  final int? pullFilterId;
  final int? conflictResolverId;
}

final class CallReplicationFilter extends Request<bool> implements SendAware {
  CallReplicationFilter({
    required this.filterId,
    required this.state,
    required this.flags,
  });

  final int filterId;
  final DocumentState state;
  final Set<DocumentFlag> flags;

  @override
  void willSend() => state.willSend();

  @override
  void didReceive() => state.didReceive();
}

final class CallConflictResolver extends Request<DocumentState?>
    implements SendAware {
  CallConflictResolver({
    required this.resolverId,
    required this.localState,
    required this.remoteState,
  });

  final int resolverId;
  final DocumentState? localState;
  final DocumentState? remoteState;

  @override
  void willSend() {
    localState?.willSend();
    remoteState?.willSend();
  }

  @override
  void didReceive() {
    localState?.didReceive();
    remoteState?.didReceive();
  }
}

final class GetReplicatorStatus extends Request<ReplicatorStatus> {
  GetReplicatorStatus({required this.replicatorId});

  final int replicatorId;
}

final class GetReplicatorServerCertificate
    extends Request<SendableCertificate?> {
  GetReplicatorServerCertificate({required this.replicatorId});

  final int replicatorId;
}

final class StartReplicator extends Request<Null> {
  StartReplicator({required this.replicatorId, required this.reset});

  final int replicatorId;
  final bool reset;
}

final class StopReplicator extends Request<Null> {
  StopReplicator({required this.replicatorId});

  final int replicatorId;
}

final class AddReplicatorChangeListener extends Request<Null> {
  AddReplicatorChangeListener({
    required this.replicatorId,
    required this.listenerId,
  });

  final int replicatorId;
  final int listenerId;
}

final class CallReplicatorChangeListener extends Request<Null> {
  CallReplicatorChangeListener({
    required this.listenerId,
    required this.status,
  });

  final int listenerId;
  final ReplicatorStatus status;
}

final class AddDocumentReplicationListener extends Request<Null> {
  AddDocumentReplicationListener({
    required this.replicatorId,
    required this.listenerId,
  });

  final int replicatorId;
  final int listenerId;
}

final class CallDocumentReplicationListener extends Request<Null> {
  CallDocumentReplicationListener({
    required this.listenerId,
    required this.event,
  });

  final int listenerId;
  final DocumentReplicationEvent event;
}

final class ReplicatorIsDocumentPending extends Request<bool> {
  ReplicatorIsDocumentPending({
    required this.replicatorId,
    required this.documentId,
    required this.collectionId,
  });

  final int replicatorId;
  final String documentId;
  final int collectionId;
}

final class ReplicatorPendingDocumentIds extends Request<List<String>> {
  ReplicatorPendingDocumentIds({
    required this.replicatorId,
    required this.collectionId,
  });

  final int replicatorId;
  final int collectionId;
}

// === Responses ===============================================================

final class SendableData implements SendAware {
  SendableData(Data data) : _data = data;

  Data get data => _data!;
  Data? _data;

  TransferableData? _transferableData;

  @override
  void willSend() {
    _transferableData = TransferableData(_data!);
    _data = null;
  }

  @override
  void didReceive() {
    _data = _transferableData!.materialize();
    _transferableData = null;
  }
}

final class SendableValue implements SendAware {
  SendableValue.fromEncodedValue(Data encodedValue)
    : _encodedValue = SendableData(encodedValue);

  SendableValue.fromValue(Value value) : _encodedValue = null, _value = value;

  Data? get encodedValue => _encodedValue?.data;
  final SendableData? _encodedValue;

  Value? _value;
  FLValue? _valuePointer;

  Value get value {
    if (_encodedValue case final encodedValue?) {
      return Doc.fromResultData(encodedValue.data, FLTrust.trusted).root;
    }

    return _value!;
  }

  @override
  void willSend() {
    _encodedValue?.willSend();

    if (_value case final value?) {
      CBLBindings.instance.fleece.value.retain(value.pointer);
      _valuePointer = value.pointer;
      _value = null;
    }
  }

  @override
  void didReceive() {
    _encodedValue?.didReceive();

    if (_valuePointer case final pointer?) {
      _value = Value.fromPointer(pointer, adopt: true);
      _valuePointer = null;
    }
  }
}

final class DatabaseState {
  DatabaseState({required this.id, required this.name, required this.path});

  final int id;
  final String name;
  final String? path;
}

final class ScopeState {
  ScopeState({required this.id, required this.name});

  final int id;
  final String name;
}

final class CollectionState {
  CollectionState({
    required this.id,
    required this.pointer,
    required this.name,
  });

  final int id;
  final Pointer<CBLCollection> pointer;
  final String name;
}

@immutable
final class DocumentState implements SendAware {
  const DocumentState({
    this.id,
    this.sourceId,
    required this.docId,
    required this.revisionId,
    required this.sequence,
    this.properties,
  });

  final int? id;
  final int? sourceId;
  final String docId;
  final String? revisionId;
  final int sequence;
  final SendableValue? properties;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentState &&
          id == other.id &&
          sourceId == other.sourceId &&
          docId == other.docId &&
          revisionId == other.revisionId &&
          sequence == other.sequence;

  @override
  int get hashCode =>
      id.hashCode ^
      sourceId.hashCode ^
      docId.hashCode ^
      revisionId.hashCode ^
      sequence.hashCode;

  @override
  void willSend() => properties?.willSend();

  @override
  void didReceive() => properties?.didReceive();
}

final class SaveBlobResponse {
  SaveBlobResponse(this.properties);

  final StringMap properties;
}

final class QueryState {
  QueryState({required this.id, required this.columnNames});

  final int id;
  final List<String> columnNames;
}

final class IndexUpdaterState {
  IndexUpdaterState({required this.id, required this.length});

  final int id;
  final int length;
}

final class DocumentReplicationEvent {
  DocumentReplicationEvent({required this.isPush, required this.documents});

  final bool isPush;
  final List<ReplicatedDocument> documents;
}

final class SendableCertificate implements SendAware {
  SendableCertificate(this._certificate);

  Certificate get certificate => _certificate!;
  Certificate? _certificate;
  Pointer<cblite.CBLCert>? _pointer;

  @override
  void willSend() {
    _pointer = (_certificate! as FfiCertificate).pointer;
    CBLBindings.instance.base.retainRefCounted(_pointer!.cast());
    _certificate = null;
  }

  @override
  void didReceive() {
    _certificate = FfiCertificate.fromPointer(_pointer!, adopt: true);
    _pointer = null;
  }
}

// === Exceptions ==============================================================

final class NotFoundException implements Exception {
  NotFoundException(this.id, this.type)
    : message = 'Could not find $type with id $id';

  final String message;
  final String type;
  final int id;

  @override
  String toString() => 'NotFound: $message';
}
