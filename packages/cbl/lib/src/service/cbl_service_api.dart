// ignore: lines_longer_than_80_chars
// ignore_for_file: prefer_constructors_over_static_methods,prefer_void_to_null

import 'dart:ffi';

import 'package:meta/meta.dart';

import '../bindings.dart';
import '../database.dart';
import '../database/database_configuration.dart';
import '../errors.dart';
import '../fleece/containers.dart';
import '../replication/authenticator.dart';
import '../replication/configuration.dart';
import '../replication/document_replication.dart';
import '../replication/endpoint.dart';
import '../replication/replicator.dart';
import '../support/encoding.dart';
import '../support/ffi.dart';
import '../support/utils.dart';
import '../tracing.dart';
import 'channel.dart';
import 'serialization/serialization.dart';

// === CblService SerializationRegistry ========================================

SerializationRegistry cblServiceSerializationRegistry() =>
    SerializationRegistry()
      // Request
      ..addSerializableCodec('Ping', PingRequest.deserialize)
      ..addSerializableCodec(
        'InstallTracingDelegate',
        InstallTracingDelegate.deserialize,
      )
      ..addSerializableCodec(
        'UninstallTracingDelegate',
        UninstallTracingDelegate.deserialize,
      )
      ..addSerializableCodec('TraceData', TraceDataRequest.deserialize)
      ..addSerializableCodec('ReleaseObject', ReleaseObject.deserialize)
      ..addSerializableCodec(
        'RemoveChangeListener',
        RemoveChangeListener.deserialize,
      )
      ..addSerializableCodec(
        'EncryptionKeyFromPassword',
        EncryptionKeyFromPassword.deserialize,
      )
      ..addSerializableCodec('RemoveDatabase', RemoveDatabase.deserialize)
      ..addSerializableCodec('DatabaseExists', DatabaseExists.deserialize)
      ..addSerializableCodec('CopyDatabase', CopyDatabase.deserialize)
      ..addSerializableCodec('OpenDatabase', OpenDatabase.deserialize)
      ..addSerializableCodec('DeleteDatabase', DeleteDatabase.deserialize)
      ..addSerializableCodec('GetScope', GetScope.deserialize)
      ..addSerializableCodec('GetScopes', GetScopes.deserialize)
      ..addSerializableCodec('GetCollection', GetCollection.deserialize)
      ..addSerializableCodec('GetCollections', GetCollections.deserialize)
      ..addSerializableCodec('CreateCollection', CreateCollection.deserialize)
      ..addSerializableCodec('DeleteCollection', DeleteCollection.deserialize)
      ..addSerializableCodec(
        'GetCollectionCount',
        GetCollectionCount.deserialize,
      )
      ..addSerializableCodec(
        'GetCollectionIndexes',
        GetCollectionIndexes.deserialize,
      )
      ..addSerializableCodec('GetDocument', GetDocument.deserialize)
      ..addSerializableCodec('SaveDocument', SaveDocument.deserialize)
      ..addSerializableCodec('DeleteDocument', DeleteDocument.deserialize)
      ..addSerializableCodec('PurgeDocument', PurgeDocument.deserialize)
      ..addSerializableCodec(
        'BeginDatabaseTransaction',
        BeginDatabaseTransaction.deserialize,
      )
      ..addSerializableCodec(
        'EndDatabaseTransaction',
        EndDatabaseTransaction.deserialize,
      )
      ..addSerializableCodec(
        'SetDocumentExpiration',
        SetDocumentExpiration.deserialize,
      )
      ..addSerializableCodec(
        'GetDocumentExpiration',
        GetDocumentExpiration.deserialize,
      )
      ..addSerializableCodec(
        'AddCollectionChangeListener',
        AddCollectionChangeListener.deserialize,
      )
      ..addSerializableCodec(
        'CallCollectionChangeListener',
        CallCollectionChangeListener.deserialize,
      )
      ..addSerializableCodec(
        'AddDocumentChangeListener',
        AddDocumentChangeListener.deserialize,
      )
      ..addSerializableCodec(
        'CallDocumentChangeListener',
        CallDocumentChangeListener.deserialize,
      )
      ..addSerializableCodec(
        'PerformDatabaseMaintenance',
        PerformDatabaseMaintenance.deserialize,
      )
      ..addSerializableCodec(
        'ChangeDatabaseEncryptionKey',
        ChangeDatabaseEncryptionKey.deserialize,
      )
      ..addSerializableCodec('CreateIndex', CreateIndex.deserialize)
      ..addSerializableCodec('DeleteIndex', DeleteIndex.deserialize)
      ..addSerializableCodec('BlobExists', BlobExists.deserialize)
      ..addSerializableCodec('ReadBlob', ReadBlob.deserialize)
      ..addSerializableCodec('SaveBlob', SaveBlob.deserialize)
      ..addSerializableCodec('ReadBlobUpload', ReadBlobUpload.deserialize)
      ..addSerializableCodec('CreateQuery', CreateQuery.deserialize)
      ..addSerializableCodec(
        'SetQueryParameters',
        SetQueryParameters.deserialize,
      )
      ..addSerializableCodec('ExplainQuery', ExplainQuery.deserialize)
      ..addSerializableCodec('ExecuteQuery', ExecuteQuery.deserialize)
      ..addSerializableCodec(
        'GetQueryResultSet',
        GetQueryResultSet.deserialize,
      )
      ..addSerializableCodec(
        'AddQueryChangeListener',
        AddQueryChangeListener.deserialize,
      )
      ..addSerializableCodec(
        'CallQueryChangeListener',
        CallQueryChangeListener.deserialize,
      )
      ..addSerializableCodec('CreateReplicator', CreateReplicator.deserialize)
      ..addSerializableCodec(
        'CreateReplicatorCollection',
        CreateReplicatorCollection.deserialize,
      )
      ..addCodec<List<CreateReplicatorCollection>>(
        'List<CreateReplicatorCollection>',
        serialize: (value, context) => value.map(context.serialize).toList(),
        deserialize: (value, context) => (value as List<Object?>)
            .map((element) =>
                context.deserializeAs<CreateReplicatorCollection>(element)!)
            .toList(),
      )
      ..addSerializableCodec(
        'CallReplicationFilter',
        CallReplicationFilter.deserialize,
      )
      ..addSerializableCodec(
        'CallConflictResolver',
        CallConflictResolver.deserialize,
      )
      ..addSerializableCodec(
        'GetReplicatorStatus',
        GetReplicatorStatus.deserialize,
      )
      ..addSerializableCodec('StartReplicator', StartReplicator.deserialize)
      ..addSerializableCodec('StopReplicator', StopReplicator.deserialize)
      ..addSerializableCodec(
        'AddReplicatorChangeListener',
        AddReplicatorChangeListener.deserialize,
      )
      ..addSerializableCodec(
        'CallReplicatorChangeListener',
        CallReplicatorChangeListener.deserialize,
      )
      ..addSerializableCodec(
        'AddDocumentReplicationListener',
        AddDocumentReplicationListener.deserialize,
      )
      ..addSerializableCodec(
        'CallDocumentReplicationListener',
        CallDocumentReplicationListener.deserialize,
      )
      ..addSerializableCodec(
        'ReplicatorIsDocumentPending',
        ReplicatorIsDocumentPending.deserialize,
      )
      ..addSerializableCodec(
        'ReplicatorPendingDocumentIds',
        ReplicatorPendingDocumentIds.deserialize,
      )

      // CblService specific types
      ..addSerializableCodec('TransferableValue', TransferableValue.deserialize)
      ..addSerializableCodec('DatabaseState', DatabaseState.deserialize)
      ..addSerializableCodec('ScopeState', ScopeState.deserialize)
      ..addSerializableCodec('CollectionState', CollectionState.deserialize)
      ..addCodec<List<ScopeState>>(
        'List<ScopeState>',
        serialize: (value, context) => value.map(context.serialize).toList(),
        deserialize: (value, context) => (value as List<Object?>)
            .map((element) => context.deserializeAs<ScopeState>(element)!)
            .toList(),
      )
      ..addCodec<List<CollectionState>>(
        'List<CollectionState>',
        serialize: (value, context) => value.map(context.serialize).toList(),
        deserialize: (value, context) => (value as List<Object?>)
            .map((element) => context.deserializeAs<CollectionState>(element)!)
            .toList(),
      )
      ..addSerializableCodec('DocumentState', DocumentState.deserialize)
      ..addSerializableCodec('SaveBlobResponse', SaveBlobResponse.deserialize)
      ..addSerializableCodec('QueryState', QueryState.deserialize)
      ..addSerializableCodec(
        'DocumentReplicationEvent',
        DocumentReplicationEvent.deserialize,
      )

      // Basic types
      ..addCodec<List<String>>(
        'List<String>',
        serialize: (value, context) => value.map(context.serialize).toList(),
        deserialize: (value, context) => (value as List<Object?>)
            .map((element) => element! as String)
            .toList(),
        handleSubTypes: true,
      )
      ..addCodec<Uri>(
        'Uri',
        serialize: (value, context) => value.toString(),
        deserialize: (value, context) => Uri.parse(value as String),
      )
      ..addCodec<EncodingFormat>(
        'EncodingFormat',
        serialize: (value, context) => value.index,
        deserialize: (value, context) => EncodingFormat.values[value as int],
      )
      ..addSerializableCodec(
        'TransferableData',
        MessageData.deserialize,
      )
      ..addSerializableCodec(
        'TransferableEncodedData',
        _TransferableEncodedData.deserialize,
      )

      // Database types
      ..addCodec<CBLEncryptionAlgorithm>(
        'CBLEncryptionAlgorithm',
        serialize: (value, context) => value.index,
        deserialize: (value, context) =>
            CBLEncryptionAlgorithm.values[value as int],
      )
      ..addObjectCodec<CBLEncryptionKey>(
        'CBLEncryptionKey',
        serialize: (value, context) => {
          'algorithm': context.serialize(value.algorithm),
          'bytes': context.addData(value.bytes),
        },
        deserialize: (map, context) => CBLEncryptionKey(
          algorithm: context.deserializeAs(map['algorithm'])!,
          bytes: context.getData(map.getAs('bytes')),
        ),
      )
      ..addObjectCodec<EncryptionKeyImpl>(
        'EncryptionKeyImpl',
        serialize: (value, context) => {
          'cblKey': context.serialize(value.cblKey),
        },
        deserialize: (map, context) =>
            EncryptionKeyImpl(context.deserializeAs(map['cblKey'])!),
      )
      ..addObjectCodec<DatabaseConfiguration>(
        'DatabaseConfiguration',
        serialize: (value, context) => {
          'directory': value.directory,
          'encryptionKey':
              context.serialize(value.encryptionKey as EncryptionKeyImpl?)
        },
        deserialize: (map, context) => DatabaseConfiguration(
          directory: map.getAs('directory'),
          encryptionKey:
              context.deserializeAs<EncryptionKeyImpl>(map['encryptionKey']),
        ),
      )
      ..addCodec<ConcurrencyControl>(
        'ConcurrencyControl',
        serialize: (value, context) => value.index,
        deserialize: (value, context) =>
            ConcurrencyControl.values[value as int],
      )
      ..addCodec<MaintenanceType>(
        'MaintenanceType',
        serialize: (value, context) => value.index,
        deserialize: (value, context) => MaintenanceType.values[value as int],
      )

      // Query types
      ..addCodec<CBLQueryLanguage>(
        'CBLQueryLanguage',
        serialize: (value, context) => value.index,
        deserialize: (value, context) => CBLQueryLanguage.values[value as int],
      )
      ..addCodec<CBLIndexType>(
        'CBLIndexType',
        serialize: (value, context) => value.index,
        deserialize: (value, context) => CBLIndexType.values[value as int],
      )
      ..addObjectCodec<CBLIndexSpec>(
        'CBLIndexSpec',
        serialize: (value, context) => {
          'type': context.serialize(value.type),
          'expressionLanguage': context.serialize(value.expressionLanguage),
          'expressions': value.expressions,
          'ignoreAccents': value.ignoreAccents,
          'language': value.language,
        },
        deserialize: (map, context) => CBLIndexSpec(
          type: context.deserializeAs(map['type'])!,
          expressionLanguage: context.deserializeAs(map['expressionLanguage'])!,
          expressions: map.getAs('expressions'),
          ignoreAccents: map.getAs('ignoreAccents'),
          language: map.getAs('language'),
        ),
      )

      // Replicator types
      ..addObjectCodec<UrlEndpoint>(
        'UrlEndpoint',
        serialize: (value, context) => {'url': context.serialize(value.url)},
        deserialize: (map, context) =>
            UrlEndpoint(context.deserializeAs(map['url'])!),
      )
      ..addSerializableCodec(
        'ServiceDatabaseEndpoint',
        ServiceDatabaseEndpoint.deserialize,
      )
      ..addCodec<ReplicatorType>(
        'ReplicatorType',
        serialize: (value, context) => value.index,
        deserialize: (value, context) => ReplicatorType.values[value as int],
      )
      ..addObjectCodec<BasicAuthenticator>(
        'BasicAuthenticator',
        serialize: (value, context) => {
          'username': value.username,
          'password': value.password,
        },
        deserialize: (map, context) => BasicAuthenticator(
          username: map.getAs('username'),
          password: map.getAs('password'),
        ),
      )
      ..addObjectCodec<SessionAuthenticator>(
        'SessionAuthenticator',
        serialize: (value, context) => {
          'sessionId': value.sessionId,
          'cookieName': value.cookieName,
        },
        deserialize: (map, context) => SessionAuthenticator(
          sessionId: map.getAs('sessionId'),
          cookieName: map.getAs('cookieName'),
        ),
      )
      ..addCodec<ReplicatorActivityLevel>(
        'ReplicatorActivityLevel',
        serialize: (value, context) => value.index,
        deserialize: (value, context) =>
            ReplicatorActivityLevel.values[value as int],
      )
      ..addCodec<DocumentFlag>(
        'DocumentFlag',
        serialize: (value, context) => value.index,
        deserialize: (value, context) => DocumentFlag.values[value as int],
      )
      ..addObjectCodec<ReplicatorProgress>(
        'ReplicatorProgress',
        serialize: (value, context) => {
          'completed': value.completed,
          'progress': value.progress,
        },
        deserialize: (map, context) => ReplicatorProgress(
          map.getAs('completed'),
          map.getAs('progress'),
        ),
      )
      ..addObjectCodec<ReplicatorStatus>(
        'ReplicatorStatus',
        serialize: (value, context) => {
          'activity': context.serialize(value.activity),
          'progress': context.serialize(value.progress),
          'error': context.serializePolymorphic(value.error),
        },
        deserialize: (map, context) => ReplicatorStatus(
          context.deserializeAs(map['activity'])!,
          context.deserializeAs(map['progress'])!,
          context.deserializePolymorphic(map['error']),
        ),
      )
      ..addObjectCodec<ReplicatedDocument>(
        'ReplicatedDocument',
        serialize: (value, context) => {
          'id': value.id,
          'scope': value.scope,
          'collection': value.collection,
          'flags': value.flags.map(context.serialize).toList(),
          'error': context.serializePolymorphic(value.error),
        },
        deserialize: (map, context) => ReplicatedDocumentImpl(
          map.getAs('id'),
          map.getAs('scope'),
          map.getAs('collection'),
          map
              .getAs<List<Object?>>('flags')
              .map((value) => context.deserializeAs<DocumentFlag>(value)!)
              .toSet(),
          context.deserializePolymorphic(map['error']),
        ),
      )

      // Exceptions
      ..addSerializableCodec(
        'NotFoundException',
        NotFoundException.deserialize,
      )
      ..addObjectCodec<DatabaseException>(
        'DatabaseException',
        serialize: (value, context) => {
          'message': value.message,
          'code': context.serialize(value.code),
          'queryString': value.queryString,
          'errorPosition': value.errorPosition,
        },
        deserialize: (map, context) => DatabaseException(
          map.getAs('message'),
          context.deserializeAs(map['code'])!,
          queryString: map.getAs('queryString'),
          errorPosition: map.getAs('errorPosition'),
        ),
      )
      ..addCodec<DatabaseErrorCode>(
        'DatabaseErrorCode',
        serialize: (value, context) => value.index,
        deserialize: (value, context) => DatabaseErrorCode.values[value as int],
      )
      ..addObjectCodec<PosixException>(
        'PosixException',
        serialize: (value, context) => {
          'message': value.message,
          'code': context.serialize(value.code),
        },
        deserialize: (map, context) => PosixException(
          map.getAs('message'),
          context.deserializeAs(map['code'])!,
        ),
      )
      ..addObjectCodec<SQLiteException>(
        'SQLiteException',
        serialize: (value, context) => {
          'message': value.message,
          'code': context.serialize(value.code),
        },
        deserialize: (map, context) => SQLiteException(
          map.getAs('message'),
          context.deserializeAs(map['code'])!,
        ),
      )
      ..addObjectCodec<NetworkException>(
        'NetworkException',
        serialize: (value, context) => {
          'message': value.message,
          'code': context.serialize(value.code),
        },
        deserialize: (map, context) => NetworkException(
          map.getAs('message'),
          context.deserializeAs(map['code'])!,
        ),
      )
      ..addCodec<NetworkErrorCode>(
        'NetworkErrorCode',
        serialize: (value, context) => value.index,
        deserialize: (value, context) => NetworkErrorCode.values[value as int],
      )
      ..addObjectCodec<HttpException>(
        'HttpException',
        serialize: (value, context) => {
          'message': value.message,
          'code': context.serialize(value.code),
        },
        deserialize: (map, context) => HttpException(
          map.getAs('message'),
          context.deserializeAs(map['code']),
        ),
      )
      ..addCodec<HttpErrorCode>(
        'HttpErrorCode',
        serialize: (value, context) => value.index,
        deserialize: (value, context) => HttpErrorCode.values[value as int],
      )
      ..addObjectCodec<WebSocketException>(
        'WebSocketException',
        serialize: (value, context) => {
          'message': value.message,
          'code': context.serialize(value.code),
        },
        deserialize: (map, context) => WebSocketException(
          map.getAs('message'),
          context.deserializeAs(map['code']),
        ),
      )
      ..addCodec<WebSocketErrorCode>(
        'WebSocketErrorCode',
        serialize: (value, context) => value.index,
        deserialize: (value, context) =>
            WebSocketErrorCode.values[value as int],
      )
      ..addObjectCodec<FleeceException>(
        'FleeceException',
        serialize: (value, context) => {
          'message': value.message,
        },
        deserialize: (map, context) => FleeceException(map.getAs('message')),
      );

// === Requests ================================================================

class PingRequest extends Request<DateTime> {
  @override
  StringMap serialize(SerializationContext context) => {};

  static PingRequest deserialize(StringMap map, SerializationContext context) =>
      PingRequest();
}

class InstallTracingDelegate extends Request<void> {
  InstallTracingDelegate(this.delegate);

  final TracingDelegate delegate;

  @override
  StringMap serialize(SerializationContext context) =>
      throw UnsupportedError('TracingDelegate is not serializable');

  static InstallTracingDelegate deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      throw UnsupportedError('TracingDelegate is not serializable');
}

class UninstallTracingDelegate extends Request<void> {
  UninstallTracingDelegate();

  @override
  StringMap serialize(SerializationContext context) => {};

  static UninstallTracingDelegate deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      UninstallTracingDelegate();
}

class TraceDataRequest extends Request<void> {
  TraceDataRequest(this.data);

  final Object? data;

  @override
  StringMap serialize(SerializationContext context) => {'data': data};

  static TraceDataRequest deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      TraceDataRequest(map['data']);
}

class ReleaseObject extends Request<Null> {
  ReleaseObject(this.objectId);

  final int objectId;

  @override
  StringMap serialize(SerializationContext context) => {'objectId': objectId};

  static ReleaseObject deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      ReleaseObject(map.getAs('objectId'));
}

class RemoveChangeListener extends Request<Null> {
  RemoveChangeListener({
    required this.targetId,
    required this.listenerId,
  });

  final int targetId;

  final int listenerId;

  @override
  StringMap serialize(SerializationContext context) => {
        'targetId': targetId,
        'listenerId': listenerId,
      };

  static RemoveChangeListener deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      RemoveChangeListener(
        targetId: map.getAs('targetId'),
        listenerId: map.getAs('listenerId'),
      );
}

class EncryptionKeyFromPassword extends Request<EncryptionKeyImpl> {
  EncryptionKeyFromPassword(this.password);

  final String password;

  @override
  StringMap serialize(SerializationContext context) => {'password': password};

  static EncryptionKeyFromPassword deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      EncryptionKeyFromPassword(map.getAs('password'));
}

class RemoveDatabase extends Request<bool> {
  RemoveDatabase(
    this.name,
    this.directory,
  );

  final String name;
  final String? directory;

  @override
  StringMap serialize(SerializationContext context) => {
        'name': name,
        'directory': directory,
      };

  static RemoveDatabase deserialize(
          StringMap map, SerializationContext context) =>
      RemoveDatabase(
        map.getAs('name'),
        map.getAs('directory'),
      );
}

class DatabaseExists extends Request<bool> {
  DatabaseExists(
    this.name,
    this.directory,
  );

  final String name;
  final String? directory;

  @override
  StringMap serialize(SerializationContext context) => {
        'name': name,
        'directory': directory,
      };

  static DatabaseExists deserialize(
          StringMap map, SerializationContext context) =>
      DatabaseExists(
        map.getAs('name'),
        map.getAs('directory'),
      );
}

class CopyDatabase extends Request<bool> {
  CopyDatabase(
    this.from,
    this.name,
    this.config,
  );

  final String from;
  final String name;
  final DatabaseConfiguration? config;

  @override
  StringMap serialize(SerializationContext context) => {
        'from': from,
        'name': name,
        'config': context.serialize(config),
      };

  static CopyDatabase deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      CopyDatabase(
        map.getAs('from'),
        map.getAs('name'),
        context.deserializeAs(map['config']),
      );
}

class OpenDatabase extends Request<DatabaseState> {
  OpenDatabase(
    this.name,
    this.config,
  );

  final String name;
  final DatabaseConfiguration? config;

  @override
  StringMap serialize(SerializationContext context) => {
        'name': name,
        'config': context.serialize(config),
      };

  static OpenDatabase deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      OpenDatabase(
        map.getAs('name'),
        context.deserializeAs(map['config']),
      );
}

class DeleteDatabase extends Request<Null> {
  DeleteDatabase(this.databaseId);

  final int databaseId;

  @override
  StringMap serialize(SerializationContext context) =>
      {'databaseId': databaseId};

  static DeleteDatabase deserialize(
          StringMap map, SerializationContext context) =>
      DeleteDatabase(map.getAs('databaseId'));
}

class GetScope extends Request<ScopeState?> {
  GetScope(this.databaseId, this.name);

  final int databaseId;
  final String name;

  @override
  StringMap serialize(SerializationContext context) => {
        'databaseId': databaseId,
        'name': name,
      };

  static GetScope deserialize(StringMap map, SerializationContext context) =>
      GetScope(
        map.getAs('databaseId'),
        map.getAs('name'),
      );
}

class GetScopes extends Request<List<ScopeState>> {
  GetScopes(this.databaseId);

  final int databaseId;

  @override
  StringMap serialize(SerializationContext context) =>
      {'databaseId': databaseId};

  static GetScopes deserialize(StringMap map, SerializationContext context) =>
      GetScopes(map.getAs('databaseId'));
}

class GetCollection extends Request<CollectionState?> {
  GetCollection(this.scopeId, this.name);

  final int scopeId;
  final String name;

  @override
  StringMap serialize(SerializationContext context) => {
        'scopeId': scopeId,
        'name': name,
      };

  static GetCollection deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      GetCollection(
        map.getAs('scopeId'),
        map.getAs('name'),
      );
}

class GetCollections extends Request<List<CollectionState>> {
  GetCollections(this.scopeId);

  final int scopeId;

  @override
  StringMap serialize(SerializationContext context) => {'scopeId': scopeId};

  static GetCollections deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      GetCollections(map.getAs('scopeId'));
}

class CreateCollection extends Request<CollectionState> {
  CreateCollection(this.databaseId, this.scope, this.collection);

  final int databaseId;
  final String scope;
  final String collection;

  @override
  StringMap serialize(SerializationContext context) => {
        'databaseId': databaseId,
        'scope': scope,
        'collection': collection,
      };

  static CreateCollection deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      CreateCollection(
        map.getAs('databaseId'),
        map.getAs('scope'),
        map.getAs('collection'),
      );
}

class DeleteCollection extends Request<Null> {
  DeleteCollection(this.databaseId, this.scope, this.collection);

  final int databaseId;
  final String scope;
  final String collection;

  @override
  StringMap serialize(SerializationContext context) => {
        'databaseId': databaseId,
        'scope': scope,
        'collection': collection,
      };

  static DeleteCollection deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      DeleteCollection(
        map.getAs('databaseId'),
        map.getAs('scope'),
        map.getAs('collection'),
      );
}

class GetCollectionCount extends Request<int> {
  GetCollectionCount(this.collectionId);

  final int collectionId;

  @override
  StringMap serialize(SerializationContext context) =>
      {'collectionId': collectionId};

  static GetCollectionCount deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      GetCollectionCount(map.getAs('collectionId'));
}

class GetCollectionIndexes extends Request<List<String>> {
  GetCollectionIndexes(this.collectionId);

  final int collectionId;

  @override
  StringMap serialize(SerializationContext context) =>
      {'collectionId': collectionId};

  static GetCollectionIndexes deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      GetCollectionIndexes(map.getAs('collectionId'));
}

class GetDocument extends Request<DocumentState?> {
  GetDocument(this.collectionId, this.documentId, this.propertiesFormat);

  final int collectionId;
  final String documentId;
  final EncodingFormat? propertiesFormat;

  @override
  StringMap serialize(SerializationContext context) => {
        'collectionId': collectionId,
        'documentId': documentId,
        'propertiesFormat': context.serialize(propertiesFormat),
      };

  static GetDocument deserialize(StringMap map, SerializationContext context) =>
      GetDocument(
        map.getAs('collectionId'),
        map.getAs('documentId'),
        context.deserializeAs(map['propertiesFormat']),
      );
}

class SaveDocument extends Request<DocumentState?> {
  SaveDocument(
    this.collectionId,
    this.state,
    this.concurrencyControl,
  );

  final int collectionId;
  final DocumentState state;
  final ConcurrencyControl concurrencyControl;

  @override
  StringMap serialize(SerializationContext context) => {
        'collectionId': collectionId,
        'state': context.serialize(state),
        'concurrencyControl': context.serialize(concurrencyControl),
      };

  static SaveDocument deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      SaveDocument(
        map.getAs('collectionId'),
        context.deserializeAs(map['state'])!,
        context.deserializeAs(map['concurrencyControl'])!,
      );

  @override
  void willSend() => state.willSend();

  @override
  void didReceive() => state.didReceive();
}

class DeleteDocument extends Request<DocumentState?> {
  DeleteDocument(
    this.collectionId,
    this.state,
    this.concurrencyControl,
  );

  final int collectionId;
  final DocumentState state;
  final ConcurrencyControl concurrencyControl;

  @override
  StringMap serialize(SerializationContext context) => {
        'collectionId': collectionId,
        'state': context.serialize(state),
        'concurrencyControl': context.serialize(concurrencyControl),
      };

  static DeleteDocument deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      DeleteDocument(
        map.getAs('collectionId'),
        context.deserializeAs(map['state'])!,
        context.deserializeAs(map['concurrencyControl'])!,
      );

  @override
  void willSend() => state.willSend();

  @override
  void didReceive() => state.didReceive();
}

class PurgeDocument extends Request<Null> {
  PurgeDocument(this.collectionId, this.documentId);

  final int collectionId;
  final String documentId;

  @override
  StringMap serialize(SerializationContext context) => {
        'collectionId': collectionId,
        'documentId': documentId,
      };

  static PurgeDocument deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      PurgeDocument(
        map.getAs('collectionId'),
        map.getAs('documentId'),
      );
}

class BeginDatabaseTransaction extends Request<Null> {
  BeginDatabaseTransaction({required this.databaseId});

  final int databaseId;

  @override
  StringMap serialize(SerializationContext context) => {
        'databaseId': databaseId,
      };

  static BeginDatabaseTransaction deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      BeginDatabaseTransaction(databaseId: map.getAs('databaseId'));
}

class EndDatabaseTransaction extends Request<Null> {
  EndDatabaseTransaction({required this.databaseId, required this.commit});

  final int databaseId;
  final bool commit;

  @override
  StringMap serialize(SerializationContext context) => {
        'databaseId': databaseId,
        'commit': commit,
      };

  static EndDatabaseTransaction deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      EndDatabaseTransaction(
        databaseId: map.getAs('databaseId'),
        commit: map.getAs('commit'),
      );
}

class SetDocumentExpiration extends Request<Null> {
  SetDocumentExpiration({
    required this.collectionId,
    required this.documentId,
    required this.expiration,
  });

  final int collectionId;
  final String documentId;
  final DateTime? expiration;

  @override
  StringMap serialize(SerializationContext context) => {
        'collectionId': collectionId,
        'documentId': documentId,
        'expiration': context.serialize(expiration),
      };

  static SetDocumentExpiration deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      SetDocumentExpiration(
        collectionId: map.getAs('collectionId'),
        documentId: map.getAs('documentId'),
        expiration: context.deserializeAs(map['expiration']),
      );
}

class GetDocumentExpiration extends Request<DateTime?> {
  GetDocumentExpiration({
    required this.collectionId,
    required this.documentId,
  });

  final int collectionId;
  final String documentId;

  @override
  StringMap serialize(SerializationContext context) => {
        'collectionId': collectionId,
        'documentId': documentId,
      };

  static GetDocumentExpiration deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      GetDocumentExpiration(
        collectionId: map.getAs('collectionId'),
        documentId: map.getAs('documentId'),
      );
}

class AddCollectionChangeListener extends Request<Null> {
  AddCollectionChangeListener({
    required this.collectionId,
    required this.listenerId,
  });

  final int collectionId;
  final int listenerId;

  @override
  StringMap serialize(SerializationContext context) => {
        'collectionId': collectionId,
        'listenerId': listenerId,
      };

  static AddCollectionChangeListener deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      AddCollectionChangeListener(
        collectionId: map.getAs('collectionId'),
        listenerId: map.getAs('listenerId'),
      );
}

class CallCollectionChangeListener extends Request<Null> {
  CallCollectionChangeListener({
    required this.listenerId,
    required this.documentIds,
  });

  final int listenerId;
  final List<String> documentIds;

  @override
  StringMap serialize(SerializationContext context) => {
        'listenerId': listenerId,
        'documentIds': context.serialize(documentIds),
      };

  static CallCollectionChangeListener deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      CallCollectionChangeListener(
        listenerId: map.getAs('listenerId'),
        documentIds: context.deserializeAs(map['documentIds'])!,
      );
}

class AddDocumentChangeListener extends Request<Null> {
  AddDocumentChangeListener({
    required this.collectionId,
    required this.documentId,
    required this.listenerId,
  });

  final int collectionId;
  final String documentId;
  final int listenerId;

  @override
  StringMap serialize(SerializationContext context) => {
        'collectionId': collectionId,
        'documentId': documentId,
        'listenerId': listenerId,
      };

  static AddDocumentChangeListener deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      AddDocumentChangeListener(
        collectionId: map.getAs('collectionId'),
        documentId: map.getAs('documentId'),
        listenerId: map.getAs('listenerId'),
      );
}

class CallDocumentChangeListener extends Request<Null> {
  CallDocumentChangeListener({required this.listenerId});

  final int listenerId;

  @override
  StringMap serialize(SerializationContext context) =>
      {'listenerId': listenerId};

  static CallDocumentChangeListener deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      CallDocumentChangeListener(listenerId: map.getAs('listenerId'));
}

class PerformDatabaseMaintenance extends Request<Null> {
  PerformDatabaseMaintenance({
    required this.databaseId,
    required this.type,
  });

  final int databaseId;
  final MaintenanceType type;

  @override
  StringMap serialize(SerializationContext context) => {
        'databaseId': databaseId,
        'type': context.serialize(type),
      };

  static PerformDatabaseMaintenance deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      PerformDatabaseMaintenance(
        databaseId: map.getAs('databaseId'),
        type: context.deserializeAs(map['type'])!,
      );
}

class ChangeDatabaseEncryptionKey extends Request<Null> {
  ChangeDatabaseEncryptionKey({
    required this.databaseId,
    required this.encryptionKey,
  });

  final int databaseId;
  final EncryptionKey? encryptionKey;

  @override
  StringMap serialize(SerializationContext context) => {
        'databaseId': databaseId,
        'encryptionKey': context.serialize(encryptionKey as EncryptionKeyImpl?),
      };

  static ChangeDatabaseEncryptionKey deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      ChangeDatabaseEncryptionKey(
        databaseId: map.getAs('databaseId'),
        encryptionKey:
            context.deserializeAs<EncryptionKeyImpl>(map['encryptionKey']),
      );
}

class CreateIndex extends Request<Null> {
  CreateIndex({
    required this.collectionId,
    required this.name,
    required this.spec,
  });

  final int collectionId;
  final String name;
  final CBLIndexSpec spec;

  @override
  StringMap serialize(SerializationContext context) => {
        'collectionId': collectionId,
        'name': name,
        'spec': context.serialize(spec),
      };

  static CreateIndex deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      CreateIndex(
        collectionId: map.getAs('collectionId'),
        name: map.getAs('name'),
        spec: context.deserializeAs(map['spec'])!,
      );
}

class DeleteIndex extends Request<Null> {
  DeleteIndex({
    required this.collectionId,
    required this.name,
  });

  final int collectionId;
  final String name;

  @override
  StringMap serialize(SerializationContext context) => {
        'collectionId': collectionId,
        'name': name,
      };

  static DeleteIndex deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      DeleteIndex(
        collectionId: map.getAs('collectionId'),
        name: map.getAs('name'),
      );
}

class BlobExists extends Request<bool> {
  BlobExists({
    required this.databaseId,
    required this.properties,
  });

  final int databaseId;
  final StringMap properties;

  @override
  StringMap serialize(SerializationContext context) => {
        'databaseId': databaseId,
        'properties': properties,
      };

  static BlobExists deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      BlobExists(
        databaseId: map.getAs('databaseId'),
        properties: map.getAs('properties'),
      );
}

class ReadBlob extends Request<MessageData> {
  ReadBlob({
    required this.databaseId,
    required this.properties,
  });

  final int databaseId;
  final StringMap properties;

  @override
  StringMap serialize(SerializationContext context) => {
        'databaseId': databaseId,
        'properties': properties,
      };

  static ReadBlob deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      ReadBlob(
        databaseId: map.getAs('databaseId'),
        properties: map.getAs('properties'),
      );
}

class SaveBlob extends Request<SaveBlobResponse> {
  SaveBlob({
    required this.databaseId,
    required this.contentType,
    required this.uploadId,
  });

  final int databaseId;
  final String contentType;
  final int uploadId;

  @override
  StringMap serialize(SerializationContext context) => {
        'databaseId': databaseId,
        'contentType': contentType,
        'uploadId': uploadId,
      };

  static SaveBlob deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      SaveBlob(
        databaseId: map.getAs('databaseId'),
        contentType: map.getAs('contentType'),
        uploadId: map.getAs('uploadId'),
      );
}

class ReadBlobUpload extends Request<MessageData> {
  ReadBlobUpload({
    required this.uploadId,
  });

  final int uploadId;

  @override
  StringMap serialize(SerializationContext context) => {'uploadId': uploadId};

  static ReadBlobUpload deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      ReadBlobUpload(uploadId: map.getAs('uploadId'));
}

class CreateQuery extends Request<QueryState> {
  CreateQuery({
    required this.databaseId,
    required this.language,
    required this.queryDefinition,
    required this.resultEncoding,
  });

  final int databaseId;
  final CBLQueryLanguage language;
  final String queryDefinition;
  final EncodingFormat? resultEncoding;

  @override
  StringMap serialize(SerializationContext context) => {
        'databaseId': databaseId,
        'language': context.serialize(language),
        'queryDefinition': queryDefinition,
        'resultEncoding': context.serialize(resultEncoding),
      };

  static CreateQuery deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      CreateQuery(
        databaseId: map.getAs('databaseId'),
        language: context.deserializeAs(map['language'])!,
        queryDefinition: map.getAs('queryDefinition'),
        resultEncoding: context.deserializeAs(map['resultEncoding']),
      );
}

class SetQueryParameters extends Request<Null> {
  SetQueryParameters({
    required this.queryId,
    required EncodedData? parameters,
  }) : _parameters = parameters?.let(_TransferableEncodedData.new);

  SetQueryParameters._({
    required this.queryId,
    required _TransferableEncodedData? parameters,
  }) : _parameters = parameters;

  final int queryId;

  EncodedData? get parameters => _parameters?.encodedData;
  final _TransferableEncodedData? _parameters;

  @override
  StringMap serialize(SerializationContext context) => {
        'queryId': queryId,
        'parameters': context.serialize(_parameters),
      };

  static SetQueryParameters deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      SetQueryParameters._(
        queryId: map.getAs('queryId'),
        parameters: context.deserializeAs(map['parameters']),
      );

  @override
  void willSend() => _parameters?.willSend();

  @override
  void didReceive() => _parameters?.didReceive();
}

class ExplainQuery extends Request<String> {
  ExplainQuery({
    required this.queryId,
  });

  final int queryId;

  @override
  StringMap serialize(SerializationContext context) => {'queryId': queryId};

  static ExplainQuery deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      ExplainQuery(queryId: map.getAs('queryId'));
}

class ExecuteQuery extends Request<int> {
  ExecuteQuery({
    required this.queryId,
  });

  final int queryId;

  @override
  StringMap serialize(SerializationContext context) => {'queryId': queryId};

  static ExecuteQuery deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      ExecuteQuery(queryId: map.getAs('queryId'));
}

class GetQueryResultSet extends Request<TransferableValue> {
  GetQueryResultSet({
    required this.queryId,
    required this.resultSetId,
  });

  final int queryId;
  final int resultSetId;

  @override
  StringMap serialize(SerializationContext context) => {
        'queryId': queryId,
        'resultSetId': resultSetId,
      };

  static GetQueryResultSet deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      GetQueryResultSet(
        queryId: map.getAs('queryId'),
        resultSetId: map.getAs('resultSetId'),
      );
}

class AddQueryChangeListener extends Request<Null> {
  AddQueryChangeListener({
    required this.queryId,
    required this.listenerId,
  });

  final int queryId;
  final int listenerId;

  @override
  StringMap serialize(SerializationContext context) => {
        'queryId': queryId,
        'listenerId': listenerId,
      };

  static AddQueryChangeListener deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      AddQueryChangeListener(
        queryId: map.getAs('queryId'),
        listenerId: map.getAs('listenerId'),
      );
}

class CallQueryChangeListener extends Request<Null> {
  CallQueryChangeListener({
    required this.listenerId,
    required this.resultSetId,
  });

  final int listenerId;
  final int resultSetId;

  @override
  StringMap serialize(SerializationContext context) => {
        'listenerId': listenerId,
        'resultSetId': resultSetId,
      };

  static CallQueryChangeListener deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      CallQueryChangeListener(
        listenerId: map.getAs('listenerId'),
        resultSetId: map.getAs('resultSetId'),
      );
}

class ServiceDatabaseEndpoint extends Serializable implements Endpoint {
  ServiceDatabaseEndpoint(this.databaseId);

  final int databaseId;

  @override
  StringMap serialize(SerializationContext context) =>
      {'databaseId': databaseId};

  static ServiceDatabaseEndpoint deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      ServiceDatabaseEndpoint(map.getAs('databaseId'));
}

class CreateReplicator extends Request<int> {
  CreateReplicator({
    required this.propertiesFormat,
    required this.target,
    this.replicatorType = ReplicatorType.pushAndPull,
    this.continuous = false,
    this.authenticator,
    Data? pinnedServerCertificate,
    Data? trustedRootCertificates,
    this.headers,
    this.enableAutoPurge = true,
    this.heartbeat,
    this.maxAttempts,
    this.maxAttemptWaitTime,
    required this.collections,
  })  : _pinnedServerCertificate =
            pinnedServerCertificate?.let(MessageData.new),
        _trustedRootCertificates =
            trustedRootCertificates?.let(MessageData.new);

  CreateReplicator._({
    required this.propertiesFormat,
    required this.target,
    required this.replicatorType,
    required this.continuous,
    this.authenticator,
    MessageData? pinnedServerCertificate,
    MessageData? trustedRootCertificates,
    this.headers,
    required this.enableAutoPurge,
    this.heartbeat,
    this.maxAttempts,
    this.maxAttemptWaitTime,
    required this.collections,
  })  : _pinnedServerCertificate = pinnedServerCertificate,
        _trustedRootCertificates = trustedRootCertificates;

  final EncodingFormat? propertiesFormat;
  final Endpoint target;
  final ReplicatorType replicatorType;
  final bool continuous;
  final Authenticator? authenticator;
  Data? get pinnedServerCertificate => _pinnedServerCertificate?.data;
  final MessageData? _pinnedServerCertificate;
  Data? get trustedRootCertificates => _trustedRootCertificates?.data;
  final MessageData? _trustedRootCertificates;
  final Map<String, String>? headers;
  final bool enableAutoPurge;
  final Duration? heartbeat;
  final int? maxAttempts;
  final Duration? maxAttemptWaitTime;
  final List<CreateReplicatorCollection> collections;

  @override
  StringMap serialize(SerializationContext context) => {
        'propertiesFormat': context.serialize(propertiesFormat),
        'target': context.serializePolymorphic(target),
        'replicatorType': context.serialize(replicatorType),
        'continuous': continuous,
        'authenticator': context.serializePolymorphic(authenticator),
        'pinnedServerCertificate': context.serialize(_pinnedServerCertificate),
        'trustedRootCertificates': context.serialize(_trustedRootCertificates),
        'headers': headers,
        'enableAutoPurge': enableAutoPurge,
        'heartbeat': context.serialize(heartbeat),
        'maxAttempts': maxAttempts,
        'maxAttemptWaitTime': context.serialize(maxAttemptWaitTime),
        'collections': context.serialize(collections),
      };

  static CreateReplicator deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      CreateReplicator._(
        propertiesFormat: context.deserializeAs(map['propertiesFormat']),
        target: context.deserializePolymorphic(map['target'])!,
        replicatorType: context.deserializeAs(map['replicatorType'])!,
        continuous: map.getAs('continuous'),
        authenticator: context.deserializePolymorphic(map['authenticator']),
        pinnedServerCertificate:
            context.deserializeAs(map['pinnedServerCertificate']),
        trustedRootCertificates:
            context.deserializeAs(map['trustedRootCertificates']),
        headers: map.getAs<StringMap?>('headers')?.cast(),
        enableAutoPurge: map.getAs('enableAutoPurge'),
        heartbeat: context.deserializeAs(map['heartbeat']),
        maxAttempts: map.getAs('maxAttempts'),
        maxAttemptWaitTime: context.deserializeAs(map['maxAttemptWaitTime']),
        collections: context.deserializeAs(map['collections'])!,
      );

  @override
  void willSend() {
    _pinnedServerCertificate?.willSend();
    _trustedRootCertificates?.willSend();
  }

  @override
  void didReceive() {
    _pinnedServerCertificate?.didReceive();
    _trustedRootCertificates?.didReceive();
  }
}

class CreateReplicatorCollection extends Serializable {
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

  @override
  StringMap serialize(SerializationContext context) => {
        'collectionId': collectionId,
        'channels': context.serialize(channels),
        'documentIds': context.serialize(documentIds),
        'pushFilterId': pushFilterId,
        'pullFilterId': pullFilterId,
        'conflictResolverId': conflictResolverId,
      };

  static CreateReplicatorCollection deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      CreateReplicatorCollection(
        collectionId: map.getAs('collectionId'),
        channels: context.deserializeAs(map['channels']),
        documentIds: context.deserializeAs(map['documentIds']),
        pushFilterId: map.getAs('pushFilterId'),
        pullFilterId: map.getAs('pullFilterId'),
        conflictResolverId: map.getAs('conflictResolverId'),
      );
}

class CallReplicationFilter extends Request<bool> {
  CallReplicationFilter({
    required this.filterId,
    required this.state,
    required this.flags,
  });

  final int filterId;
  final DocumentState state;
  final Set<DocumentFlag> flags;

  @override
  StringMap serialize(SerializationContext context) => {
        'filterId': filterId,
        'state': context.serialize(state),
        'flags': flags.toList(),
      };

  static CallReplicationFilter deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      CallReplicationFilter(
        filterId: map.getAs('filterId'),
        state: context.deserializeAs(map['state'])!,
        flags: map
            .getAs<List<Object?>>('flags')
            .map((it) => context.deserializeAs<DocumentFlag>(it)!)
            .toSet(),
      );

  @override
  void willSend() => state.willSend();

  @override
  void didReceive() => state.didReceive();
}

class CallConflictResolver extends Request<DocumentState?> {
  CallConflictResolver({
    required this.resolverId,
    required this.localState,
    required this.remoteState,
  });

  final int resolverId;
  final DocumentState? localState;
  final DocumentState? remoteState;

  @override
  StringMap serialize(SerializationContext context) => {
        'resolverId': resolverId,
        'localState': context.serialize(localState),
        'remoteState': context.serialize(remoteState),
      };

  static CallConflictResolver deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      CallConflictResolver(
        resolverId: map.getAs('resolverId'),
        localState: context.deserializeAs(map['localState']),
        remoteState: context.deserializeAs(map['remoteState']),
      );

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

class GetReplicatorStatus extends Request<ReplicatorStatus> {
  GetReplicatorStatus({required this.replicatorId});

  final int replicatorId;

  @override
  StringMap serialize(SerializationContext context) => {
        'replicatorId': replicatorId,
      };

  static GetReplicatorStatus deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      GetReplicatorStatus(
        replicatorId: map.getAs('replicatorId'),
      );
}

class StartReplicator extends Request<Null> {
  StartReplicator({
    required this.replicatorId,
    required this.reset,
  });

  final int replicatorId;
  final bool reset;

  @override
  StringMap serialize(SerializationContext context) => {
        'replicatorId': replicatorId,
        'reset': reset,
      };

  static StartReplicator deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      StartReplicator(
        replicatorId: map.getAs('replicatorId'),
        reset: map.getAs('reset'),
      );
}

class StopReplicator extends Request<Null> {
  StopReplicator({
    required this.replicatorId,
  });

  final int replicatorId;

  @override
  StringMap serialize(SerializationContext context) => {
        'replicatorId': replicatorId,
      };

  static StopReplicator deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      StopReplicator(
        replicatorId: map.getAs('replicatorId'),
      );
}

class AddReplicatorChangeListener extends Request<Null> {
  AddReplicatorChangeListener({
    required this.replicatorId,
    required this.listenerId,
  });

  final int replicatorId;
  final int listenerId;

  @override
  StringMap serialize(SerializationContext context) => {
        'replicatorId': replicatorId,
        'listenerId': listenerId,
      };

  static AddReplicatorChangeListener deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      AddReplicatorChangeListener(
        replicatorId: map.getAs('replicatorId'),
        listenerId: map.getAs('listenerId'),
      );
}

class CallReplicatorChangeListener extends Request<Null> {
  CallReplicatorChangeListener({
    required this.listenerId,
    required this.status,
  });

  final int listenerId;
  final ReplicatorStatus status;

  @override
  StringMap serialize(SerializationContext context) => {
        'listenerId': listenerId,
        'status': context.serialize(status),
      };

  static CallReplicatorChangeListener deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      CallReplicatorChangeListener(
        listenerId: map.getAs('listenerId'),
        status: context.deserializeAs(map['status'])!,
      );
}

class AddDocumentReplicationListener extends Request<Null> {
  AddDocumentReplicationListener({
    required this.replicatorId,
    required this.listenerId,
  });

  final int replicatorId;
  final int listenerId;

  @override
  StringMap serialize(SerializationContext context) => {
        'replicatorId': replicatorId,
        'listenerId': listenerId,
      };

  static AddDocumentReplicationListener deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      AddDocumentReplicationListener(
        replicatorId: map.getAs('replicatorId'),
        listenerId: map.getAs('listenerId'),
      );
}

class CallDocumentReplicationListener extends Request<Null> {
  CallDocumentReplicationListener({
    required this.listenerId,
    required this.event,
  });

  final int listenerId;
  final DocumentReplicationEvent event;

  @override
  StringMap serialize(SerializationContext context) => {
        'listenerId': listenerId,
        'event': context.serialize(event),
      };

  static CallDocumentReplicationListener deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      CallDocumentReplicationListener(
        listenerId: map.getAs('listenerId'),
        event: context.deserializeAs(map['event'])!,
      );

  @override
  void willSend() => event.willSend();

  @override
  void didReceive() => event.didReceive();
}

class ReplicatorIsDocumentPending extends Request<bool> {
  ReplicatorIsDocumentPending({
    required this.replicatorId,
    required this.documentId,
    required this.collectionId,
  });

  final int replicatorId;
  final String documentId;
  final int collectionId;

  @override
  StringMap serialize(SerializationContext context) => {
        'replicatorId': replicatorId,
        'documentId': documentId,
        'collectionId': collectionId,
      };

  static ReplicatorIsDocumentPending deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      ReplicatorIsDocumentPending(
        replicatorId: map.getAs('replicatorId'),
        documentId: map.getAs('documentId'),
        collectionId: map.getAs('collectionId'),
      );
}

class ReplicatorPendingDocumentIds extends Request<List<String>> {
  ReplicatorPendingDocumentIds({
    required this.replicatorId,
    required this.collectionId,
  });

  final int replicatorId;
  final int collectionId;

  @override
  StringMap serialize(SerializationContext context) => {
        'replicatorId': replicatorId,
        'collectionId': collectionId,
      };

  static ReplicatorPendingDocumentIds deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      ReplicatorPendingDocumentIds(
        replicatorId: map.getAs('replicatorId'),
        collectionId: map.getAs('collectionId'),
      );
}

// === Responses ===============================================================

class MessageData extends Serializable {
  MessageData(Data data) : _data = data;

  Data get data => _data!;
  Data? _data;

  TransferableData? _transferableData;

  @override
  StringMap serialize(SerializationContext context) =>
      {'data': context.addData(_data!)};

  static MessageData deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      MessageData(context.getData(map['data']! as int));

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

class _TransferableEncodedData extends Serializable {
  _TransferableEncodedData(EncodedData data)
      : _format = data.format,
        _data = MessageData(data.data);

  _TransferableEncodedData._(this._format, this._data);

  final EncodingFormat _format;
  final MessageData _data;

  EncodedData get encodedData => EncodedData(_format, _data.data);

  @override
  StringMap serialize(SerializationContext context) => {
        'format': context.serialize(_format),
        'data': context.serialize(_data),
      };

  static _TransferableEncodedData deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      _TransferableEncodedData._(
        context.deserializeAs(map['format'])!,
        context.deserializeAs(map['data'])!,
      );

  @override
  void willSend() => _data.willSend();

  @override
  void didReceive() => _data.didReceive();
}

class TransferableValue extends Serializable {
  TransferableValue._(this._encodedData, this._value) : _valueAddress = null;

  TransferableValue.fromEncodedData(EncodedData encodedData)
      : _encodedData = _TransferableEncodedData(encodedData);

  TransferableValue.fromValue(Value value)
      : _encodedData = null,
        _value = value;

  EncodedData? get encodedData => _encodedData?.encodedData;
  final _TransferableEncodedData? _encodedData;

  Value? get value => _value;
  Value? _value;

  int? _valueAddress;

  @override
  StringMap serialize(SerializationContext context) {
    final value = _value;
    if (value != null) {
      cblBindings.fleece.value.retain(value.pointer);
      _valueAddress = value.pointer.address;
      _value = null;
    }

    return {
      'encodedData': context.serialize(_encodedData),
      'valueAddress': _valueAddress,
    };
  }

  static TransferableValue deserialize(
    StringMap map,
    SerializationContext context,
  ) {
    final encodedData =
        context.deserializeAs<_TransferableEncodedData>(map['encodedData']);

    Value? value;
    final valueAddress = map.getAs<int?>('valueAddress');
    if (valueAddress != null) {
      value = Value.fromPointer(Pointer.fromAddress(valueAddress), adopt: true);
    }

    return TransferableValue._(encodedData, value);
  }

  @override
  void willSend() {
    _encodedData?.willSend();

    final value = _value;
    if (value != null) {
      cblBindings.fleece.value.retain(value.pointer);
      _valueAddress = value.pointer.address;
      _value = null;
    }
  }

  @override
  void didReceive() {
    _encodedData?.didReceive();

    final valueAddress = _valueAddress;
    if (valueAddress != null) {
      _value =
          Value.fromPointer(Pointer.fromAddress(valueAddress), adopt: true);
      _valueAddress = null;
    }
  }
}

class DatabaseState extends Serializable {
  DatabaseState({
    required this.id,
    required this.name,
    required this.path,
  });

  final int id;
  final String name;
  final String? path;

  @override
  StringMap serialize(SerializationContext context) => {
        'id': id,
        'name': name,
        'path': path,
      };

  static DatabaseState deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      DatabaseState(
        id: map.getAs('id'),
        name: map.getAs('name'),
        path: map.getAs('path'),
      );
}

class ScopeState extends Serializable {
  ScopeState({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  @override
  StringMap serialize(SerializationContext context) => {
        'id': id,
        'name': name,
      };

  static ScopeState deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      ScopeState(
        id: map.getAs('id'),
        name: map.getAs('name'),
      );
}

class CollectionState extends Serializable {
  CollectionState({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  @override
  StringMap serialize(SerializationContext context) => {
        'id': id,
        'name': name,
      };

  static CollectionState deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      CollectionState(
        id: map.getAs('id'),
        name: map.getAs('name'),
      );
}

@immutable
class DocumentState extends Serializable {
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
  final TransferableValue? properties;

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
  StringMap serialize(SerializationContext context) => {
        'id': id,
        'sourceId': sourceId,
        'docId': docId,
        'revisionId': revisionId,
        'sequence': sequence,
        'properties': context.serialize(properties),
      };

  static DocumentState deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      DocumentState(
        id: map.getAs('id'),
        sourceId: map.getAs('sourceId'),
        docId: map.getAs('docId'),
        revisionId: map.getAs('revisionId'),
        sequence: map.getAs('sequence'),
        properties: context.deserializeAs(map['properties']),
      );

  @override
  void willSend() => properties?.willSend();

  @override
  void didReceive() => properties?.didReceive();
}

class SaveBlobResponse extends Serializable {
  SaveBlobResponse(this.properties);

  final StringMap properties;

  @override
  StringMap serialize(SerializationContext context) =>
      {'properties': properties};

  static SaveBlobResponse deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      SaveBlobResponse(map.getAs('properties'));
}

class QueryState extends Serializable {
  QueryState({
    required this.id,
    required this.columnNames,
  });

  final int id;
  final List<String> columnNames;

  @override
  StringMap serialize(SerializationContext context) => {
        'id': id,
        'columnNames': context.serialize(columnNames),
      };

  static QueryState deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      QueryState(
        id: map.getAs('id'),
        columnNames: context.deserializeAs(map['columnNames'])!,
      );
}

class DocumentReplicationEvent extends Serializable {
  DocumentReplicationEvent({
    required this.isPush,
    required this.documents,
  });

  final bool isPush;
  final List<ReplicatedDocument> documents;

  @override
  StringMap serialize(SerializationContext context) => {
        'isPush': isPush,
        'documents': documents.map(context.serialize).toList(),
      };

  static DocumentReplicationEvent deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      DocumentReplicationEvent(
        isPush: map.getAs('isPush'),
        documents: map
            .getAs<List<Object?>>('documents')
            .map((value) => context.deserializeAs<ReplicatedDocument>(value)!)
            .toList(),
      );
}

// === Exceptions ==============================================================

class NotFoundException extends Serializable implements Exception {
  NotFoundException(this.id, this.type)
      : message = 'Could not find object of type $type with id $id';

  final String message;
  final String type;
  final int id;

  @override
  String toString() => 'NotFound: $message';

  @override
  StringMap serialize(SerializationContext context) => {
        'id': id,
        'type': type,
      };

  static NotFoundException deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      NotFoundException(
        map.getAs('id'),
        map.getAs('type'),
      );
}
