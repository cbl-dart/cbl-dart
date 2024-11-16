import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'base.dart';
import 'bindings.dart';
import 'cblite.dart' as cblite;
import 'cblitedart.dart' as cblitedart;
import 'data.dart';
import 'global.dart';
import 'utils.dart';

// === ReplicatorConfiguration =================================================

enum CBLReplicatorType {
  pushAndPull,
  push,
  pull,
}

extension on CBLReplicatorType {
  int toInt() => CBLReplicatorType.values.indexOf(this);
}

enum CBLProxyType {
  http,
  https,
}

extension on CBLProxyType {
  int toInt() => CBLProxyType.values.indexOf(this);
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

  final Pointer<cblite.CBLCollection> collection;
  final cblite.FLArray? channels;
  final cblite.FLArray? documentIDs;
  final cblitedart.CBLDart_AsyncCallback? pushFilter;
  final cblitedart.CBLDart_AsyncCallback? pullFilter;
  final cblitedart.CBLDart_AsyncCallback? conflictResolver;
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
    this.pinnedServerCertificate,
    this.trustedRootCertificates,
    required this.collections,
  });

  final Pointer<cblite.CBLDatabase> database;
  final Pointer<cblite.CBLEndpoint> endpoint;
  final CBLReplicatorType replicatorType;
  final bool continuous;
  final bool? disableAutoPurge;
  final int? maxAttempts;
  final int? maxAttemptWaitTime;
  final int? heartbeat;
  final Pointer<cblite.CBLAuthenticator>? authenticator;
  final CBLProxySettings? proxy;
  final cblite.FLDict? headers;
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

  final Pointer<cblite.CBLDocument> document;
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
  final Pointer<cblite.CBLDocument>? localDocument;
  final Pointer<cblite.CBLDocument>? remoteDocument;
}

// === Status and Progress =====================================================

enum CBLReplicatorActivityLevel {
  stopped,
  offline,
  connecting,
  idle,
  busy,
}

extension on int {
  CBLReplicatorActivityLevel toReplicatorActivityLevel() =>
      CBLReplicatorActivityLevel.values[this];
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
  final CBLErrorException? error;
}

extension on cblite.CBLReplicatorStatus {
  CBLErrorException? get exception {
    if (!error.isOk) {
      error.copyToGlobal();
      return CBLErrorException.fromCBLError(globalCBLError);
    }
    return null;
  }

  CBLReplicatorStatus toCBLReplicatorStatus() => CBLReplicatorStatus(
        activity.toReplicatorActivityLevel(),
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
    CBLErrorException? error;
    if (status.length > 3) {
      final domain = (status[3]! as int).toErrorDomain();
      final errorCode = (status[4]! as int).toErrorCode(domain);
      final message =
          utf8.decode(status[5]! as Uint8List, allowMalformed: true);
      error = CBLErrorException(domain, errorCode, message);
    }

    return CBLReplicatorStatus(
      (status[0]! as int).toReplicatorActivityLevel(),
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
  final CBLErrorException? error;
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
        CBLErrorException? error;
        if (document.length > 4) {
          final domain = (document[4]! as int).toErrorDomain();
          final code = (document[5]! as int).toErrorCode(domain);
          final message =
              utf8.decode(document[6]! as Uint8List, allowMalformed: true);
          error = CBLErrorException(domain, code, message);
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
  ReplicatorBindings(super.parent);

  late final _finalizer =
      NativeFinalizer(cblDart.addresses.CBLDart_CBLReplicator_Release.cast());

  Pointer<cblite.CBLEndpoint> createEndpointWithUrl(String url) =>
      runWithSingleFLString(
        url,
        (flUrl) => cbl.CBLEndpoint_CreateWithURL(flUrl, globalCBLError)
            .checkCBLError(),
      );

  Pointer<cblite.CBLEndpoint> createEndpointWithLocalDB(
    Pointer<cblite.CBLDatabase> database,
  ) =>
      cbl.CBLEndpoint_CreateWithLocalDB(database);

  void freeEndpoint(Pointer<cblite.CBLEndpoint> endpoint) {
    cbl.CBLEndpoint_Free(endpoint);
  }

  Pointer<cblite.CBLAuthenticator> createPasswordAuthenticator(
    String username,
    String password,
  ) =>
      withGlobalArena(() => cbl.CBLAuth_CreatePassword(
            username.toFLString(),
            password.toFLString(),
          ));

  Pointer<cblite.CBLAuthenticator> createSessionAuthenticator(
    String sessionID,
    String? cookieName,
  ) =>
      withGlobalArena(() => cbl.CBLAuth_CreateSession(
            sessionID.toFLString(),
            cookieName.toFLString(),
          ));

  void freeAuthenticator(Pointer<cblite.CBLAuthenticator> authenticator) {
    cbl.CBLAuth_Free(authenticator);
  }

  Pointer<cblite.CBLReplicator> createReplicator(
          CBLReplicatorConfiguration config) =>
      withGlobalArena(() => cblDart.CBLDart_CBLReplicator_Create(
            _createConfigurationStruct(config),
            globalCBLError,
          ).checkCBLError());

  void bindToDartObject(
    Finalizable object,
    Pointer<cblite.CBLReplicator> replicator,
  ) {
    _finalizer.attach(object, replicator.cast());
  }

  void start(
    Pointer<cblite.CBLReplicator> replicator, {
    required bool resetCheckpoint,
  }) {
    cbl.CBLReplicator_Start(replicator, resetCheckpoint);
  }

  void stop(Pointer<cblite.CBLReplicator> replicator) {
    cbl.CBLReplicator_Stop(replicator);
  }

  void setHostReachable(
    Pointer<cblite.CBLReplicator> replicator, {
    required bool reachable,
  }) {
    cbl.CBLReplicator_SetHostReachable(replicator, reachable);
  }

  void setSuspended(
    Pointer<cblite.CBLReplicator> replicator, {
    required bool suspended,
  }) {
    cbl.CBLReplicator_SetSuspended(replicator, suspended);
  }

  CBLReplicatorStatus status(Pointer<cblite.CBLReplicator> replicator) =>
      cbl.CBLReplicator_Status(replicator).toCBLReplicatorStatus();

  cblite.FLDict pendingDocumentIDs(
    Pointer<cblite.CBLReplicator> replicator,
    Pointer<cblite.CBLCollection> collection,
  ) =>
      cbl.CBLReplicator_PendingDocumentIDs2(
              replicator, collection, globalCBLError)
          .checkCBLError();

  bool isDocumentPending(
    Pointer<cblite.CBLReplicator> replicator,
    String docID,
    Pointer<cblite.CBLCollection> collection,
  ) =>
      runWithSingleFLString(
        docID,
        (flDocID) => cbl.CBLReplicator_IsDocumentPending2(
                replicator, flDocID, collection, globalCBLError)
            .checkCBLError(),
      );

  void addChangeListener(
    Pointer<cblite.CBLDatabase> db,
    Pointer<cblite.CBLReplicator> replicator,
    cblitedart.CBLDart_AsyncCallback listener,
  ) {
    cblDart.CBLDart_CBLReplicator_AddChangeListener(db, replicator, listener);
  }

  void addDocumentReplicationListener(
    Pointer<cblite.CBLDatabase> db,
    Pointer<cblite.CBLReplicator> replicator,
    cblitedart.CBLDart_AsyncCallback listener,
  ) {
    cblDart.CBLDart_CBLReplicator_AddDocumentReplicationListener(
      db,
      replicator,
      listener,
    );
  }

  Pointer<cblitedart.CBLDart_ReplicatorConfiguration>
      _createConfigurationStruct(
    CBLReplicatorConfiguration config,
  ) {
    final configStruct =
        globalArena<cblitedart.CBLDart_ReplicatorConfiguration>();

    configStruct.ref
      ..database = config.database
      ..endpoint = config.endpoint
      ..replicatorType = config.replicatorType.toInt()
      ..continuous = config.continuous
      ..disableAutoPurge = config.disableAutoPurge ?? false
      ..maxAttempts = config.maxAttempts ?? 0
      ..maxAttemptWaitTime = config.maxAttemptWaitTime ?? 0
      ..heartbeat = config.heartbeat ?? 0
      ..authenticator = config.authenticator ?? nullptr
      ..proxy = _createProxySettingsStruct(config.proxy)
      ..headers = config.headers ?? nullptr
      ..pinnedServerCertificate = config.pinnedServerCertificate
              ?.toSliceResult()
              .flSlice(globalArena) ??
          nullptr
      ..trustedRootCertificates = config.trustedRootCertificates
              ?.toSliceResult()
              .flSlice(globalArena) ??
          nullptr;

    final collectionStructs =
        globalArena<cblitedart.CBLDart_ReplicationCollection>(
            config.collections.length);

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

  Pointer<cblite.CBLProxySettings> _createProxySettingsStruct(
    CBLProxySettings? settings,
  ) {
    if (settings == null) {
      return nullptr;
    }

    final settingsStruct = globalArena<cblite.CBLProxySettings>();

    settingsStruct.ref
      ..type = settings.type.toInt()
      ..hostname = settings.hostname.toFLString()
      ..port = settings.port
      ..username = settings.username.toFLString()
      ..password = settings.password.toFLString();

    return settingsStruct;
  }
}
