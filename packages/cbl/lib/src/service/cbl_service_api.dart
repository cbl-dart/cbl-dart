// ignore: lines_longer_than_80_chars
// ignore_for_file: prefer_constructors_over_static_methods,prefer_void_to_null

import 'package:cbl_ffi/cbl_ffi.dart';
import 'package:meta/meta.dart';

import '../database.dart';
import '../database/database_configuration.dart';
import '../errors.dart';
import '../replication/authenticator.dart';
import '../replication/configuration.dart';
import '../replication/document_replication.dart';
import '../replication/endpoint.dart';
import '../replication/replicator.dart';
import '../support/encoding.dart';
import '../support/utils.dart';
import 'channel.dart';
import 'serialization/serialization.dart';

// === CblService SerializationRegistry ========================================

SerializationRegistry cblServiceSerializationRegistry() =>
    SerializationRegistry()
      // Request
      ..addSerializableCodec('Ping', PingRequest.deserialize)
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
      ..addSerializableCodec('GetDatabaseState', GetDatabase.deserialize)
      ..addSerializableCodec('DeleteDatabase', DeleteDatabase.deserialize)
      ..addSerializableCodec(
        'GetDocument',
        GetDocument.deserialize,
        isIsolatePortSafe: false,
      )
      ..addSerializableCodec(
        'SaveDocument',
        SaveDocument.deserialize,
        isIsolatePortSafe: false,
      )
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
        'AddDatabaseChangeListener',
        AddDatabaseChangeListener.deserialize,
      )
      ..addSerializableCodec(
        'CallDatabaseChangeListener',
        CallDatabaseChangeListener.deserialize,
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
        isIsolatePortSafe: false,
      )
      ..addSerializableCodec('ExplainQuery', ExplainQuery.deserialize)
      ..addSerializableCodec('ExecuteQuery', ExecuteQuery.deserialize)
      ..addSerializableCodec(
        'AddQueryChangeListener',
        AddQueryChangeListener.deserialize,
      )
      ..addSerializableCodec(
        'CallQueryChangeListener',
        CallQueryChangeListener.deserialize,
      )
      ..addSerializableCodec(
        'QueryChangeResultSet',
        QueryChangeResultSet.deserialize,
      )
      ..addSerializableCodec(
        'CreateReplicator',
        CreateReplicator.deserialize,
        isIsolatePortSafe: false,
      )
      ..addSerializableCodec(
        'CallReplicationFilter',
        CallReplicationFilter.deserialize,
        isIsolatePortSafe: false,
      )
      ..addSerializableCodec(
        'CallConflictResolver',
        CallConflictResolver.deserialize,
        isIsolatePortSafe: false,
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
      ..addSerializableCodec('DatabaseState', DatabaseState.deserialize)
      ..addSerializableCodec(
        'DocumentState',
        DocumentState.deserialize,
        isIsolatePortSafe: false,
      )
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
      ..addObjectCodec<EncodedData>(
        'EncodedData',
        serialize: (value, context) => {
          'format': context.serialize(value.format),
          'data': context.serialize(value.data),
        },
        deserialize: (map, context) => EncodedData(
          context.deserializeAs(map['format'])!,
          context.deserializeAs(map['data'])!,
        ),
        isIsolatePortSafe: false,
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
        'CBLIndexType',
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
        'ReplicatorStatus',
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
          'flags': value.flags.map(context.serialize).toList(),
          'error': context.serializePolymorphic(value.error),
        },
        deserialize: (map, context) => ReplicatedDocumentImpl(
          map.getAs('id'),
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
      ..addObjectCodec<InvalidJsonException>(
        'InvalidJsonException',
        serialize: (value, context) => {
          'message': value.message,
        },
        deserialize: (map, context) => InvalidJsonException(
          map.getAs('message'),
        ),
      );

// === Requests ================================================================

class PingRequest extends Request<DateTime> {
  @override
  StringMap serialize(SerializationContext context) => {};

  static PingRequest deserialize(StringMap map, SerializationContext context) =>
      PingRequest();
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

class RemoveChangeListener implements Request<Null> {
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

class GetDatabase extends Request<DatabaseState> {
  GetDatabase(this.databaseId);

  final int databaseId;

  @override
  StringMap serialize(SerializationContext context) =>
      {'databaseId': databaseId};

  static GetDatabase deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      GetDatabase(map.getAs('databaseId'));
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

class GetDocument extends Request<DocumentState?> {
  GetDocument(this.databaseId, this.documentId, this.propertiesFormat);

  final int databaseId;
  final String documentId;
  final EncodingFormat propertiesFormat;

  @override
  StringMap serialize(SerializationContext context) => {
        'databaseId': databaseId,
        'documentId': documentId,
        'propertiesFormat': context.serialize(propertiesFormat),
      };

  static GetDocument deserialize(StringMap map, SerializationContext context) =>
      GetDocument(
        map.getAs('databaseId'),
        map.getAs('documentId'),
        context.deserializeAs(map['propertiesFormat'])!,
      );
}

class SaveDocument extends Request<DocumentState?> {
  SaveDocument(
    this.databaseId,
    this.state,
    this.concurrencyControl,
  );

  final int databaseId;
  final DocumentState state;
  final ConcurrencyControl concurrencyControl;

  @override
  StringMap serialize(SerializationContext context) => {
        'databaseId': databaseId,
        'state': context.serialize(state),
        'concurrencyControl': context.serialize(concurrencyControl),
      };

  static SaveDocument deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      SaveDocument(
        map.getAs('databaseId'),
        context.deserializeAs(map['state'])!,
        context.deserializeAs(map['concurrencyControl'])!,
      );
}

class DeleteDocument extends Request<DocumentState?> {
  DeleteDocument(
    this.databaseId,
    this.state,
    this.concurrencyControl,
  );

  final int databaseId;
  final DocumentState state;
  final ConcurrencyControl concurrencyControl;

  @override
  StringMap serialize(SerializationContext context) => {
        'databaseId': databaseId,
        'state': context.serialize(state),
        'concurrencyControl': context.serialize(concurrencyControl),
      };

  static DeleteDocument deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      DeleteDocument(
        map.getAs('databaseId'),
        context.deserializeAs(map['state'])!,
        context.deserializeAs(map['concurrencyControl'])!,
      );
}

class PurgeDocument implements Request<Null> {
  PurgeDocument(this.databaseId, this.documentId);

  final int databaseId;
  final String documentId;

  @override
  StringMap serialize(SerializationContext context) => {
        'databaseId': databaseId,
        'documentId': documentId,
      };

  static PurgeDocument deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      PurgeDocument(
        map.getAs('databaseId'),
        map.getAs('documentId'),
      );
}

class BeginDatabaseTransaction implements Request<Null> {
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

class EndDatabaseTransaction implements Request<Null> {
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

class SetDocumentExpiration implements Request<Null> {
  SetDocumentExpiration({
    required this.databaseId,
    required this.documentId,
    required this.expiration,
  });

  final int databaseId;
  final String documentId;
  final DateTime? expiration;

  @override
  StringMap serialize(SerializationContext context) => {
        'databaseId': databaseId,
        'documentId': documentId,
        'expiration': context.serialize(expiration),
      };

  static SetDocumentExpiration deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      SetDocumentExpiration(
        databaseId: map.getAs('databaseId'),
        documentId: map.getAs('documentId'),
        expiration: context.deserializeAs(map['expiration']),
      );
}

class GetDocumentExpiration implements Request<DateTime?> {
  GetDocumentExpiration({
    required this.databaseId,
    required this.documentId,
  });

  final int databaseId;
  final String documentId;

  @override
  StringMap serialize(SerializationContext context) => {
        'databaseId': databaseId,
        'documentId': documentId,
      };

  static GetDocumentExpiration deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      GetDocumentExpiration(
        databaseId: map.getAs('databaseId'),
        documentId: map.getAs('documentId'),
      );
}

class AddDatabaseChangeListener implements Request<Null> {
  AddDatabaseChangeListener({
    required this.databaseId,
    required this.listenerId,
  });

  final int databaseId;

  final int listenerId;

  @override
  StringMap serialize(SerializationContext context) => {
        'databaseId': databaseId,
        'listenerId': listenerId,
      };

  static AddDatabaseChangeListener deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      AddDatabaseChangeListener(
        databaseId: map.getAs('databaseId'),
        listenerId: map.getAs('listenerId'),
      );
}

class CallDatabaseChangeListener implements Request<Null> {
  CallDatabaseChangeListener({
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

  static CallDatabaseChangeListener deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      CallDatabaseChangeListener(
        listenerId: map.getAs('listenerId'),
        documentIds: context.deserializeAs(map['documentIds'])!,
      );
}

class AddDocumentChangeListener implements Request<Null> {
  AddDocumentChangeListener({
    required this.databaseId,
    required this.documentId,
    required this.listenerId,
  });

  final int databaseId;

  final String documentId;

  final int listenerId;

  @override
  StringMap serialize(SerializationContext context) => {
        'databaseId': databaseId,
        'documentId': documentId,
        'listenerId': listenerId,
      };

  static AddDocumentChangeListener deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      AddDocumentChangeListener(
        databaseId: map.getAs('databaseId'),
        documentId: map.getAs('documentId'),
        listenerId: map.getAs('listenerId'),
      );
}

class CallDocumentChangeListener implements Request<Null> {
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

class PerformDatabaseMaintenance implements Request<Null> {
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

class ChangeDatabaseEncryptionKey implements Request<Null> {
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

class CreateIndex implements Request<Null> {
  CreateIndex({
    required this.databaseId,
    required this.name,
    required this.spec,
  });

  final int databaseId;
  final String name;
  final CBLIndexSpec spec;

  @override
  StringMap serialize(SerializationContext context) => {
        'databaseId': databaseId,
        'name': name,
        'spec': context.serialize(spec),
      };

  static CreateIndex deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      CreateIndex(
        databaseId: map.getAs('databaseId'),
        name: map.getAs('name'),
        spec: context.deserializeAs(map['spec'])!,
      );
}

class DeleteIndex implements Request<Null> {
  DeleteIndex({
    required this.databaseId,
    required this.name,
  });

  final int databaseId;
  final String name;

  @override
  StringMap serialize(SerializationContext context) => {
        'databaseId': databaseId,
        'name': name,
      };

  static DeleteIndex deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      DeleteIndex(
        databaseId: map.getAs('databaseId'),
        name: map.getAs('name'),
      );
}

class BlobExists implements Request<bool> {
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

class ReadBlob implements Request<Data> {
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

class SaveBlob implements Request<SaveBlobResponse> {
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

class ReadBlobUpload implements Request<Data> {
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

class CreateQuery implements Request<QueryState> {
  CreateQuery({
    required this.databaseId,
    required this.language,
    required this.queryDefinition,
    required this.resultEncoding,
  });

  final int databaseId;
  final CBLQueryLanguage language;
  final String queryDefinition;
  final EncodingFormat resultEncoding;

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
        resultEncoding: context.deserializeAs(map['resultEncoding'])!,
      );
}

class SetQueryParameters implements Request<Null> {
  SetQueryParameters({
    required this.queryId,
    required this.parameters,
  });

  final int queryId;
  final EncodedData? parameters;

  @override
  StringMap serialize(SerializationContext context) => {
        'queryId': queryId,
        'parameters': context.serialize(parameters),
      };

  static SetQueryParameters deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      SetQueryParameters(
        queryId: map.getAs('queryId'),
        parameters: context.deserializeAs(map['parameters']),
      );
}

class ExplainQuery implements Request<String> {
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

class ExecuteQuery implements Request<EncodedData> {
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

class AddQueryChangeListener implements Request<Null> {
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

class CallQueryChangeListener implements Request<Null> {
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

class QueryChangeResultSet implements Request<EncodedData> {
  QueryChangeResultSet({
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

  static QueryChangeResultSet deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      QueryChangeResultSet(
        queryId: map.getAs('queryId'),
        resultSetId: map.getAs('resultSetId'),
      );
}

class ServiceDatabaseEndpoint extends Endpoint implements Serializable {
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
    required this.databaseId,
    required this.propertiesFormat,
    required this.target,
    this.replicatorType = ReplicatorType.pushAndPull,
    this.continuous = false,
    this.authenticator,
    this.pinnedServerCertificate,
    this.headers,
    this.channels,
    this.documentIds,
    this.pushFilterId,
    this.pullFilterId,
    this.conflictResolverId,
    this.enableAutoPurge = true,
    this.heartbeat,
    this.maxAttempts,
    this.maxAttemptWaitTime,
  });

  final int databaseId;
  final EncodingFormat propertiesFormat;
  final Endpoint target;
  final ReplicatorType replicatorType;
  final bool continuous;
  final Authenticator? authenticator;
  final Data? pinnedServerCertificate;
  final Map<String, String>? headers;
  final List<String>? channels;
  final List<String>? documentIds;
  final int? pushFilterId;
  final int? pullFilterId;
  final int? conflictResolverId;
  final bool enableAutoPurge;
  final Duration? heartbeat;
  final int? maxAttempts;
  final Duration? maxAttemptWaitTime;

  @override
  StringMap serialize(SerializationContext context) => {
        'databaseId': databaseId,
        'propertiesFormat': context.serialize(propertiesFormat),
        'target': context.serializePolymorphic(target),
        'replicatorType': context.serialize(replicatorType),
        'continuous': continuous,
        'authenticator': context.serializePolymorphic(authenticator),
        'pinnedServerCertificate': context.serialize(pinnedServerCertificate),
        'headers': headers,
        'channels': context.serialize(channels),
        'documentIds': context.serialize(documentIds),
        'pushFilterId': pushFilterId,
        'pullFilterId': pullFilterId,
        'conflictResolverId': conflictResolverId,
        'enableAutoPurge': enableAutoPurge,
        'heartbeat': context.serialize(heartbeat),
        'maxAttempts': maxAttempts,
        'maxAttemptWaitTime': context.serialize(maxAttemptWaitTime),
      };

  static CreateReplicator deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      CreateReplicator(
        databaseId: map.getAs('databaseId'),
        propertiesFormat: context.deserializeAs(map['propertiesFormat'])!,
        target: context.deserializePolymorphic(map['target'])!,
        replicatorType: context.deserializeAs(map['replicatorType'])!,
        continuous: map.getAs('continuous'),
        authenticator: context.deserializePolymorphic(map['authenticator']),
        pinnedServerCertificate:
            context.deserializeAs(map['pinnedServerCertificate']),
        headers: map.getAs<StringMap?>('headers')?.cast(),
        channels: context.deserializeAs(map['channels']),
        documentIds: context.deserializeAs(map['documentIds']),
        pushFilterId: map.getAs('pushFilterId'),
        pullFilterId: map.getAs('pullFilterId'),
        conflictResolverId: map.getAs('conflictResolverId'),
        enableAutoPurge: map.getAs('enableAutoPurge'),
        heartbeat: context.deserializeAs(map['heartbeat']),
        maxAttempts: map.getAs('maxAttempts'),
        maxAttemptWaitTime: context.deserializeAs(map['maxAttemptWaitTime']),
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

class AddReplicatorChangeListener implements Request<Null> {
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

class CallReplicatorChangeListener implements Request<Null> {
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

class AddDocumentReplicationListener implements Request<Null> {
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

class CallDocumentReplicationListener implements Request<Null> {
  CallDocumentReplicationListener(
      {required this.listenerId, required this.event});

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
}

class ReplicatorIsDocumentPending extends Request<bool> {
  ReplicatorIsDocumentPending({
    required this.replicatorId,
    required this.documentId,
  });

  final int replicatorId;
  final String documentId;

  @override
  StringMap serialize(SerializationContext context) => {
        'replicatorId': replicatorId,
        'documentId': documentId,
      };

  static ReplicatorIsDocumentPending deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      ReplicatorIsDocumentPending(
        replicatorId: map.getAs('replicatorId'),
        documentId: map.getAs('documentId'),
      );
}

class ReplicatorPendingDocumentIds extends Request<List<String>> {
  ReplicatorPendingDocumentIds({
    required this.replicatorId,
  });

  final int replicatorId;

  @override
  StringMap serialize(SerializationContext context) => {
        'replicatorId': replicatorId,
      };

  static ReplicatorPendingDocumentIds deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      ReplicatorPendingDocumentIds(
        replicatorId: map.getAs('replicatorId'),
      );
}

// === Responses ===============================================================

class DatabaseState implements Serializable {
  DatabaseState({
    required this.id,
    required this.name,
    required this.path,
    required this.count,
    required this.indexes,
  });

  final int id;
  final String name;
  final String? path;
  final int count;
  final List<String> indexes;

  @override
  StringMap serialize(SerializationContext context) => {
        'id': id,
        'name': name,
        'path': path,
        'count': count,
        'indexes': indexes,
      };

  static DatabaseState deserialize(
    StringMap map,
    SerializationContext context,
  ) =>
      DatabaseState(
        id: map.getAs('id'),
        name: map.getAs('name'),
        path: map.getAs('path'),
        count: map.getAs('count'),
        indexes: map.getAsList('indexes'),
      );
}

@immutable
class DocumentState implements Serializable {
  const DocumentState({
    required this.id,
    required this.revisionId,
    required this.sequence,
    this.properties,
  });

  final String id;
  final String? revisionId;
  final int sequence;
  final EncodedData? properties;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentState &&
          id == other.id &&
          revisionId == other.revisionId &&
          sequence == other.sequence;

  @override
  int get hashCode => id.hashCode ^ revisionId.hashCode ^ sequence.hashCode;

  @override
  StringMap serialize(SerializationContext context) => {
        'id': id,
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
        revisionId: map.getAs('revisionId'),
        sequence: map.getAs('sequence'),
        properties: context.deserializeAs(map['properties']),
      );
}

class SaveBlobResponse implements Serializable {
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

class QueryState implements Serializable {
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

class DocumentReplicationEvent implements Serializable {
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

class NotFoundException implements Exception, Serializable {
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
