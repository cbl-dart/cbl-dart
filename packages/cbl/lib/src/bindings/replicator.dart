import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import '../errors.dart';
import 'base.dart';
import 'bindings.dart';
import 'cblite.dart' as cblite_lib;
import 'cblitedart.dart' as cblitedart_lib;
import 'data.dart';
import 'global.dart';
import 'utils.dart';

export 'cblite.dart' show CBLReplicator, CBLEndpoint, CBLAuthenticator;

// === ReplicatorConfiguration =================================================

enum CBLReplicatorType {
  pushAndPull(cblite_lib.kCBLReplicatorTypePushAndPull),
  push(cblite_lib.kCBLReplicatorTypePush),
  pull(cblite_lib.kCBLReplicatorTypePull);

  const CBLReplicatorType(this.value);

  final int value;
}

enum CBLProxyType {
  http(cblite_lib.kCBLProxyHTTP),
  https(cblite_lib.kCBLProxyHTTPS);

  const CBLProxyType(this.value);

  final int value;
}

final class CBLProxySettings {
  CBLProxySettings({
    required this.type,
    required this.hostname,
    required this.port,
    this.username,
    required this.password,
  });

  final CBLProxyType type;
  final String hostname;
  final int port;
  final String? username;
  final String password;
}

final class CBLReplicationCollection {
  CBLReplicationCollection({
    required this.collection,
    this.channels,
    this.documentIDs,
    this.pushFilter,
    this.pullFilter,
    this.conflictResolver,
  });

  final Pointer<cblite_lib.CBLCollection> collection;
  final cblite_lib.FLArray? channels;
  final cblite_lib.FLArray? documentIDs;
  final cblitedart_lib.CBLDart_AsyncCallback? pushFilter;
  final cblitedart_lib.CBLDart_AsyncCallback? pullFilter;
  final cblitedart_lib.CBLDart_AsyncCallback? conflictResolver;
}

final class CBLReplicatorConfiguration {
  CBLReplicatorConfiguration({
    required this.database,
    required this.endpoint,
    required this.replicatorType,
    required this.continuous,
    this.disableAutoPurge,
    this.maxAttempts,
    this.maxAttemptWaitTime,
    this.heartbeat,
    this.authenticator,
    this.proxy,
    this.headers,
    required this.acceptOnlySelfSignedServerCertificate,
    this.pinnedServerCertificate,
    this.trustedRootCertificates,
    required this.collections,
  });

  final Pointer<cblite_lib.CBLDatabase> database;
  final Pointer<cblite_lib.CBLEndpoint> endpoint;
  final CBLReplicatorType replicatorType;
  final bool continuous;
  final bool? disableAutoPurge;
  final int? maxAttempts;
  final int? maxAttemptWaitTime;
  final int? heartbeat;
  final Pointer<cblite_lib.CBLAuthenticator>? authenticator;
  final CBLProxySettings? proxy;
  final cblite_lib.FLDict? headers;
  final bool acceptOnlySelfSignedServerCertificate;
  final Data? pinnedServerCertificate;
  final Data? trustedRootCertificates;
  final List<CBLReplicationCollection> collections;
}

final class ReplicationFilterCallbackMessage {
  ReplicationFilterCallbackMessage(this.document, this.flags);

  ReplicationFilterCallbackMessage.fromArguments(List<Object?> arguments)
    : this(
        (arguments[0]! as int).toPointer(),
        CBLReplicatedDocumentFlag._parseCFlags(arguments[1]! as int),
      );

  final Pointer<cblite_lib.CBLDocument> document;
  final Set<CBLReplicatedDocumentFlag> flags;
}

final class ReplicationConflictResolverCallbackMessage {
  ReplicationConflictResolverCallbackMessage(
    this.documentId,
    this.localDocument,
    this.remoteDocument,
  );

  ReplicationConflictResolverCallbackMessage.fromArguments(
    List<Object?> arguments,
  ) : this(
        utf8.decode(arguments[0]! as Uint8List),
        (arguments[1] as int?)?.toPointer(),
        (arguments[2] as int?)?.toPointer(),
      );

  final String documentId;
  final Pointer<cblite_lib.CBLDocument>? localDocument;
  final Pointer<cblite_lib.CBLDocument>? remoteDocument;
}

// === Status and Progress =====================================================

enum CBLReplicatorActivityLevel {
  stopped,
  offline,
  connecting,
  idle,
  busy;

  factory CBLReplicatorActivityLevel.fromValue(int value) => switch (value) {
    cblite_lib.kCBLReplicatorStopped => stopped,
    cblite_lib.kCBLReplicatorOffline => offline,
    cblite_lib.kCBLReplicatorConnecting => connecting,
    cblite_lib.kCBLReplicatorIdle => idle,
    cblite_lib.kCBLReplicatorBusy => busy,
    _ => throw ArgumentError('Unknown replicator activity level: $value'),
  };
}

final class CBLReplicatorStatus {
  CBLReplicatorStatus(
    this.activity,
    this.progressComplete,
    this.progressDocumentCount,
    this.error,
  );

  final CBLReplicatorActivityLevel activity;
  final double progressComplete;
  final int progressDocumentCount;
  final CouchbaseLiteException? error;
}

extension on cblite_lib.CBLReplicatorStatus {
  CouchbaseLiteException? get exception {
    if (!error.isOk) {
      error.copyToGlobal();
      return globalCBLError.toCouchbaseLiteException();
    }
    return null;
  }

  CBLReplicatorStatus toCBLReplicatorStatus() => CBLReplicatorStatus(
    CBLReplicatorActivityLevel.fromValue(activity),
    progress.complete,
    progress.documentCount,
    exception,
  );
}

enum CBLReplicatedDocumentFlag implements Option {
  deleted(0),
  accessRemoved(1);

  const CBLReplicatedDocumentFlag(this.bit);

  @override
  final int bit;

  static Set<CBLReplicatedDocumentFlag> _parseCFlags(int flag) =>
      values.parseCFlags(flag);
}

final class ReplicatorStatusCallbackMessage {
  ReplicatorStatusCallbackMessage(this.status);

  ReplicatorStatusCallbackMessage.fromArguments(List<Object?> arguments)
    : this(parseArguments(arguments[0]! as List<Object?>));

  static CBLReplicatorStatus parseArguments(List<Object?> status) {
    CouchbaseLiteException? error;
    if (status.length > 3) {
      final domain = CBLErrorDomain.fromValue(status[3]! as int);
      final code = (status[4]! as int).toErrorCode(domain);
      final message = utf8.decode(
        status[5]! as Uint8List,
        allowMalformed: true,
      );
      error = createCouchbaseLiteException(
        domain: domain,
        code: code,
        message: message,
      );
    }

    return CBLReplicatorStatus(
      CBLReplicatorActivityLevel.fromValue(status[0]! as int),
      status[1]! as double,
      status[2]! as int,
      error,
    );
  }

  final CBLReplicatorStatus status;
}

final class CBLReplicatedDocument {
  CBLReplicatedDocument(
    this.id,
    this.flags,
    this.scope,
    this.collection,
    this.error,
  );

  final String id;
  final Set<CBLReplicatedDocumentFlag> flags;
  final String scope;
  final String collection;
  final CouchbaseLiteException? error;
}

final class DocumentReplicationsCallbackMessage {
  DocumentReplicationsCallbackMessage(
    // ignore: avoid_positional_boolean_parameters
    this.isPush,
    this.documents,
  );

  DocumentReplicationsCallbackMessage.fromArguments(List<Object?> arguments)
    : this(
        arguments[0]! as bool,
        parseDocuments(arguments[1]! as List<Object?>),
      );

  static List<CBLReplicatedDocument> parseDocuments(List<Object?> documents) =>
      documents.cast<List<Object?>>().map((document) {
        CouchbaseLiteException? error;
        if (document.length > 4) {
          final domain = CBLErrorDomain.fromValue(document[4]! as int);
          final code = (document[5]! as int).toErrorCode(domain);
          final message = utf8.decode(
            document[6]! as Uint8List,
            allowMalformed: true,
          );
          error = createCouchbaseLiteException(
            domain: domain,
            code: code,
            message: message,
          );
        }

        return CBLReplicatedDocument(
          utf8.decode(document[0]! as Uint8List),
          CBLReplicatedDocumentFlag._parseCFlags(document[1]! as int),
          utf8.decode(document[2]! as Uint8List),
          utf8.decode(document[3]! as Uint8List),
          error,
        );
      }).toList();

  final bool isPush;
  final List<CBLReplicatedDocument> documents;
}

// === ReplicatorBindings ======================================================

final class ReplicatorBindings extends Bindings {
  ReplicatorBindings(super.libraries);

  late final _finalizer = NativeFinalizer(
    cblitedart.addresses.CBLDart_CBLReplicator_Release.cast(),
  );

  Pointer<cblite_lib.CBLEndpoint> createEndpointWithUrl(String url) =>
      runWithSingleFLString(
        url,
        (flUrl) => cblite.CBLEndpoint_CreateWithURL(
          flUrl,
          globalCBLError,
        ).checkError(),
      );

  Pointer<cblite_lib.CBLEndpoint> createEndpointWithLocalDB(
    Pointer<cblite_lib.CBLDatabase> database,
  ) => cblite.CBLEndpoint_CreateWithLocalDB(database);

  void freeEndpoint(Pointer<cblite_lib.CBLEndpoint> endpoint) {
    cblite.CBLEndpoint_Free(endpoint);
  }

  Pointer<cblite_lib.CBLAuthenticator> createPasswordAuthenticator(
    String username,
    String password,
  ) => withGlobalArena(
    () => cblite.CBLAuth_CreatePassword(
      username.toFLString(),
      password.toFLString(),
    ),
  );

  Pointer<cblite_lib.CBLAuthenticator> createSessionAuthenticator(
    String sessionID,
    String? cookieName,
  ) => withGlobalArena(
    () => cblite.CBLAuth_CreateSession(
      sessionID.toFLString(),
      cookieName.toFLString(),
    ),
  );

  Pointer<cblite_lib.CBLAuthenticator> createClientCertificateAuthenticator(
    Pointer<cblite_lib.CBLTLSIdentity> pointer,
  ) => cblite.CBLAuth_CreateCertificate(pointer);

  void freeAuthenticator(Pointer<cblite_lib.CBLAuthenticator> authenticator) {
    cblite.CBLAuth_Free(authenticator);
  }

  Pointer<cblite_lib.CBLReplicator> createReplicator(
    CBLReplicatorConfiguration config,
  ) => withGlobalArena(
    () => cblitedart.CBLDart_CBLReplicator_Create(
      _createConfigurationStruct(config),
      globalCBLError,
    ).checkError(),
  );

  void bindToDartObject(
    Finalizable object,
    Pointer<cblite_lib.CBLReplicator> replicator,
  ) {
    _finalizer.attach(object, replicator.cast());
  }

  void start(
    Pointer<cblite_lib.CBLReplicator> replicator, {
    required bool resetCheckpoint,
  }) {
    cblite.CBLReplicator_Start(replicator, resetCheckpoint);
  }

  void stop(Pointer<cblite_lib.CBLReplicator> replicator) {
    cblite.CBLReplicator_Stop(replicator);
  }

  void setHostReachable(
    Pointer<cblite_lib.CBLReplicator> replicator, {
    required bool reachable,
  }) {
    cblite.CBLReplicator_SetHostReachable(replicator, reachable);
  }

  void setSuspended(
    Pointer<cblite_lib.CBLReplicator> replicator, {
    required bool suspended,
  }) {
    cblite.CBLReplicator_SetSuspended(replicator, suspended);
  }

  CBLReplicatorStatus status(Pointer<cblite_lib.CBLReplicator> replicator) =>
      cblite.CBLReplicator_Status(replicator).toCBLReplicatorStatus();

  Pointer<cblite_lib.CBLCert>? serverCertificate(
    Pointer<cblite_lib.CBLReplicator> replicator,
  ) => cblite.CBLReplicator_ServerCertificate(replicator).toNullable();

  cblite_lib.FLDict pendingDocumentIDs(
    Pointer<cblite_lib.CBLReplicator> replicator,
    Pointer<cblite_lib.CBLCollection> collection,
  ) => cblite.CBLReplicator_PendingDocumentIDs2(
    replicator,
    collection,
    globalCBLError,
  ).checkError();

  bool isDocumentPending(
    Pointer<cblite_lib.CBLReplicator> replicator,
    String docID,
    Pointer<cblite_lib.CBLCollection> collection,
  ) => runWithSingleFLString(
    docID,
    (flDocID) => cblite.CBLReplicator_IsDocumentPending2(
      replicator,
      flDocID,
      collection,
      globalCBLError,
    ).checkError(),
  );

  void addChangeListener(
    Pointer<cblite_lib.CBLDatabase> db,
    Pointer<cblite_lib.CBLReplicator> replicator,
    cblitedart_lib.CBLDart_AsyncCallback listener,
  ) {
    cblitedart.CBLDart_CBLReplicator_AddChangeListener(
      db,
      replicator,
      listener,
    );
  }

  void addDocumentReplicationListener(
    Pointer<cblite_lib.CBLDatabase> db,
    Pointer<cblite_lib.CBLReplicator> replicator,
    cblitedart_lib.CBLDart_AsyncCallback listener,
  ) {
    cblitedart.CBLDart_CBLReplicator_AddDocumentReplicationListener(
      db,
      replicator,
      listener,
    );
  }

  Pointer<cblitedart_lib.CBLDart_ReplicatorConfiguration>
  _createConfigurationStruct(CBLReplicatorConfiguration config) {
    final configStruct =
        globalArena<cblitedart_lib.CBLDart_ReplicatorConfiguration>();

    configStruct.ref
      ..database = config.database
      ..endpoint = config.endpoint
      ..replicatorType = config.replicatorType.value
      ..continuous = config.continuous
      ..disableAutoPurge = config.disableAutoPurge ?? false
      ..maxAttempts = config.maxAttempts ?? 0
      ..maxAttemptWaitTime = config.maxAttemptWaitTime ?? 0
      ..heartbeat = config.heartbeat ?? 0
      ..authenticator = config.authenticator ?? nullptr
      ..proxy = _createProxySettingsStruct(config.proxy)
      ..headers = config.headers ?? nullptr
      ..acceptOnlySelfSignedServerCertificate =
          config.acceptOnlySelfSignedServerCertificate
      ..pinnedServerCertificate =
          config.pinnedServerCertificate?.toSliceResult().flSlice(
            globalArena,
          ) ??
          nullptr
      ..trustedRootCertificates =
          config.trustedRootCertificates?.toSliceResult().flSlice(
            globalArena,
          ) ??
          nullptr;

    final collectionStructs =
        globalArena<cblitedart_lib.CBLDart_ReplicationCollection>(
          config.collections.length,
        );

    configStruct.ref
      ..collections = collectionStructs
      ..collectionsCount = config.collections.length;

    for (final (i, collection) in config.collections.indexed) {
      collectionStructs[i]
        ..collection = collection.collection
        ..channels = collection.channels ?? nullptr
        ..documentIDs = collection.documentIDs ?? nullptr
        ..pushFilter = collection.pushFilter ?? nullptr
        ..pullFilter = collection.pullFilter ?? nullptr
        ..conflictResolver = collection.conflictResolver ?? nullptr;
    }

    return configStruct;
  }

  Pointer<cblite_lib.CBLProxySettings> _createProxySettingsStruct(
    CBLProxySettings? settings,
  ) {
    if (settings == null) {
      return nullptr;
    }

    final settingsStruct = globalArena<cblite_lib.CBLProxySettings>();

    settingsStruct.ref
      ..type = settings.type.value
      ..hostname = settings.hostname.toFLString()
      ..port = settings.port
      ..username = settings.username.toFLString()
      ..password = settings.password.toFLString();

    return settingsStruct;
  }
}
