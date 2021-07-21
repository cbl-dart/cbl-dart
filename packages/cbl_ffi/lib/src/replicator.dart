import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'base.dart';
import 'bindings.dart';
import 'database.dart';
import 'document.dart';
import 'fleece.dart';
import 'native_callback.dart';
import 'utils.dart';

// === ReplicatorConfiguration =================================================

class CBLEndpoint extends Opaque {}

typedef CBLDart_CBLEndpoint_CreateWithURL = Pointer<CBLEndpoint> Function(
  FLString url,
);

typedef CBLEndpoint_Free_C = Void Function(
  Pointer<CBLEndpoint> endpoint,
);
typedef CBLEndpoint_Free = void Function(
  Pointer<CBLEndpoint> endpoint,
);

class CBLAuthenticator extends Opaque {}

typedef CBLDart_CBLAuth_CreatePassword = Pointer<CBLAuthenticator> Function(
  FLString username,
  FLString password,
);

typedef CBLDart_CBLAuth_CreateSession = Pointer<CBLAuthenticator> Function(
  FLString sessionID,
  FLString cookieName,
);

typedef CBLAuth_Free_C = Void Function(
  Pointer<CBLAuthenticator> authenticator,
);
typedef CBLAuth_Free = void Function(
  Pointer<CBLAuthenticator> authenticator,
);

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

extension on int {
  CBLProxyType toProxyType() => CBLProxyType.values[this];
}

class CBLDart_CBLProxySettings extends Struct {
  @Uint8()
  external int _type;
  external FLString hostname;
  @Uint16()
  external int port;
  external FLString username;
  external FLString password;
}

// ignore: camel_case_extensions
extension CBLDart_CBLProxySettingsExt on CBLDart_CBLProxySettings {
  CBLProxyType get type => _type.toProxyType();
  set type(CBLProxyType value) => _type = value.toInt();
}

class CBLDartReplicatorConfiguration extends Struct {
  external Pointer<CBLDatabase> database;
  external Pointer<CBLEndpoint> endpoint;
  @Uint8()
  // ignore: unused_field
  external int _replicatorType;
  @Uint8()
  // ignore: unused_field
  external int _continuous;
  @Uint8()
  // ignore: unused_field
  external int _disableAutoPurge;
  @Uint32()
  external int maxAttempts;
  @Uint32()
  external int maxAttemptWaitTime;
  @Uint32()
  external int heartbeat;
  external Pointer<CBLAuthenticator> authenticator;
  external Pointer<CBLDart_CBLProxySettings> proxy;
  external Pointer<FLDict> headers;
  external Pointer<FLSlice> pinnedServerCertificate;
  external Pointer<FLSlice> trustedRootCertificates;
  external Pointer<FLArray> channels;
  external Pointer<FLArray> documentIDs;
  external Pointer<Callback> pushFilter;
  external Pointer<Callback> pullFilter;
  external Pointer<Callback> conflictResolver;
}

extension CBLDartReplicatorConfigurationExt on CBLDartReplicatorConfiguration {
  set replicatorType(CBLReplicatorType value) =>
      _replicatorType = value.toInt();
  set continuous(bool value) => _continuous = value.toInt();
  set disableAutoPurge(bool value) => _disableAutoPurge = value.toInt();
}

class ReplicationFilterCallbackMessage {
  ReplicationFilterCallbackMessage(this.document, this.flags);

  ReplicationFilterCallbackMessage.fromArguments(List<dynamic> arguments)
      : this(
          (arguments[0] as int).toPointer(),
          CBLReplicatedDocumentFlag._parseCFlags(arguments[1] as int),
        );

  final Pointer<CBLDocument> document;
  final Set<CBLReplicatedDocumentFlag> flags;
}

class ReplicationConflictResolverCallbackMessage {
  ReplicationConflictResolverCallbackMessage(
    this.documentId,
    this.localDocument,
    this.remoteDocument,
  );

  ReplicationConflictResolverCallbackMessage.fromArguments(
    List<dynamic> arguments,
  ) : this(
          utf8.decode(arguments[0] as Uint8List),
          (arguments[1] as int?)?.toPointer(),
          (arguments[2] as int?)?.toPointer(),
        );

  final String documentId;
  final Pointer<CBLDocument>? localDocument;
  final Pointer<CBLDocument>? remoteDocument;
}

// === Replicator ==============================================================

class CBLReplicator extends Opaque {}

typedef CBLDart_CBLReplicator_Create = Pointer<CBLReplicator> Function(
  Pointer<CBLDartReplicatorConfiguration> config,
  Pointer<CBLError> errorOut,
);

typedef CBLDart_BindReplicatorToDartObject_C = Void Function(
  Handle object,
  Pointer<CBLReplicator> replicator,
  Pointer<Utf8> debugName,
);
typedef CBLDart_BindReplicatorToDartObject = void Function(
  Object object,
  Pointer<CBLReplicator> replicator,
  Pointer<Utf8> debugName,
);

typedef CBLReplicator_ResetCheckpoint_C = Void Function(
  Pointer<CBLReplicator> replicator,
);
typedef CBLReplicator_ResetCheckpoint = void Function(
  Pointer<CBLReplicator> replicator,
);

typedef CBLReplicator_Start_C = Void Function(
  Pointer<CBLReplicator> replicator,
  Uint8 resetCheckpoint,
);
typedef CBLReplicator_Start = void Function(
  Pointer<CBLReplicator> replicator,
  int resetCheckpoint,
);

typedef CBLReplicator_Stop_C = Void Function(
  Pointer<CBLReplicator> replicator,
);
typedef CBLReplicator_Stop = void Function(
  Pointer<CBLReplicator> replicator,
);

typedef CBLReplicator_SetHostReachable_C = Void Function(
  Pointer<CBLReplicator> replicator,
  Uint8 reachable,
);
typedef CBLReplicator_SetHostReachable = void Function(
  Pointer<CBLReplicator> replicator,
  int reachable,
);

typedef CBLReplicator_SetSuspended_C = Void Function(
  Pointer<CBLReplicator> replicator,
  Uint8 suspended,
);
typedef CBLReplicator_SetSuspended = void Function(
  Pointer<CBLReplicator> replicator,
  int suspended,
);

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

class _CBLReplicatorProgress extends Struct {
  @Float()
  external double complete;

  @Uint64()
  external int documentCount;
}

class _CBLReplicatorStatus extends Struct {
  @Uint8()
  external int _activity;

  external _CBLReplicatorProgress progress;

  external CBLError _error;
}

class CBLReplicatorStatus {
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

extension on _CBLReplicatorStatus {
  CBLErrorException? get exception {
    if (!_error.isOk) {
      _error.copyToGlobal();
      return CBLErrorException.fromCBLError(globalCBLError);
    }
  }

  CBLReplicatorStatus toCBLReplicatorStatus() => CBLReplicatorStatus(
        _activity.toReplicatorActivityLevel(),
        progress.complete,
        progress.documentCount,
        exception,
      );
}

typedef CBLReplicator_Status = _CBLReplicatorStatus Function(
  Pointer<CBLReplicator> replicator,
);

typedef CBLReplicator_PendingDocumentIDs = Pointer<FLDict> Function(
  Pointer<CBLReplicator> replicator,
  Pointer<CBLError> errorOut,
);

typedef CBLDart_CBLReplicator_IsDocumentPending_C = Uint8 Function(
  Pointer<CBLReplicator> replicator,
  FLString docID,
  Pointer<CBLError> errorOut,
);
typedef CBLDart_CBLReplicator_IsDocumentPending = int Function(
  Pointer<CBLReplicator> replicator,
  FLString docID,
  Pointer<CBLError> errorOut,
);

typedef CBLDart_CBLReplicator_AddChangeListener_C = Void Function(
  Pointer<CBLReplicator> replicator,
  Pointer<Callback> listener,
);
typedef CBLDart_CBLReplicator_AddChangeListener = void Function(
  Pointer<CBLReplicator> replicator,
  Pointer<Callback> listener,
);

/// Flags describing a replicated document.
class CBLReplicatedDocumentFlag extends Option {
  const CBLReplicatedDocumentFlag(String debugName, int bits)
      : super(debugName, bits);

  static const deleted = CBLReplicatedDocumentFlag('deleted', 1 << 0);
  static const accessRemoved =
      CBLReplicatedDocumentFlag('accessRemoved', 1 << 1);

  static const values = [deleted, accessRemoved];

  static Set<CBLReplicatedDocumentFlag> _parseCFlags(int flag) =>
      values.parseCFlags(flag);
}

class CBLDart_ReplicatedDocument extends Struct {
  external FLString _ID;

  @Uint32()
  external int _flags;

  external CBLError _error;
}

extension CBLDartReplicatedDocumentExt on CBLDart_ReplicatedDocument {
  String get ID => _ID.toDartString()!;

  Set<CBLReplicatedDocumentFlag> get flags =>
      CBLReplicatedDocumentFlag._parseCFlags(_flags);

  CBLErrorException? get exception {
    if (!_error.isOk) {
      _error.copyToGlobal();
      return CBLErrorException.fromCBLError(globalCBLError);
    }
  }
}

typedef CBLDart_CBLReplicator_AddDocumentReplicationListener_C = Void Function(
  Pointer<CBLReplicator> replicator,
  Pointer<Callback> listener,
);
typedef CBLDart_CBLReplicator_AddDocumentReplicationListener = void Function(
  Pointer<CBLReplicator> replicator,
  Pointer<Callback> listener,
);

class ReplicatorStatusCallbackMessage {
  ReplicatorStatusCallbackMessage(this.status);

  ReplicatorStatusCallbackMessage.fromArguments(List<dynamic> arguments)
      : this((arguments[0] as int)
            .toPointer<_CBLReplicatorStatus>()
            .ref
            .toCBLReplicatorStatus());

  final CBLReplicatorStatus status;
}

class DocumentReplicationsCallbackMessage {
  DocumentReplicationsCallbackMessage(
    this.isPush,
    this.documentCount,
    this.documents,
  );

  DocumentReplicationsCallbackMessage.fromArguments(List<dynamic> arguments)
      : this(
          arguments[0] as bool,
          arguments[1] as int,
          (arguments[2] as int).toPointer(),
        );

  final bool isPush;
  final int documentCount;
  final Pointer<CBLDart_ReplicatedDocument> documents;
}

// === ReplicatorBindings ======================================================

class ReplicatorBindings extends Bindings {
  ReplicatorBindings(Bindings parent) : super(parent) {
    _endpointCreateWithUrl = libs.cblDart.lookupFunction<
        CBLDart_CBLEndpoint_CreateWithURL, CBLDart_CBLEndpoint_CreateWithURL>(
      'CBLDart_CBLEndpoint_CreateWithURL',
    );
    _endpointFree =
        libs.cbl.lookupFunction<CBLEndpoint_Free_C, CBLEndpoint_Free>(
      'CBLEndpoint_Free',
    );
    _authCreatePassword = libs.cblDart.lookupFunction<
        CBLDart_CBLAuth_CreatePassword, CBLDart_CBLAuth_CreatePassword>(
      'CBLDart_CBLAuth_CreatePassword',
    );
    _authCreateSession = libs.cblDart.lookupFunction<
        CBLDart_CBLAuth_CreateSession, CBLDart_CBLAuth_CreateSession>(
      'CBLDart_CBLAuth_CreateSession',
    );
    _authFree = libs.cbl.lookupFunction<CBLAuth_Free_C, CBLAuth_Free>(
      'CBLAuth_Free',
    );
    _create = libs.cblDart.lookupFunction<CBLDart_CBLReplicator_Create,
        CBLDart_CBLReplicator_Create>(
      'CBLDart_CBLReplicator_Create',
    );
    _bindToDartObject = libs.cblDart.lookupFunction<
        CBLDart_BindReplicatorToDartObject_C,
        CBLDart_BindReplicatorToDartObject>(
      'CBLDart_BindReplicatorToDartObject',
    );
    _start =
        libs.cbl.lookupFunction<CBLReplicator_Start_C, CBLReplicator_Start>(
      'CBLReplicator_Start',
    );
    _stop = libs.cbl.lookupFunction<CBLReplicator_Stop_C, CBLReplicator_Stop>(
      'CBLReplicator_Stop',
    );
    _setHostReachable = libs.cbl.lookupFunction<
        CBLReplicator_SetHostReachable_C, CBLReplicator_SetHostReachable>(
      'CBLReplicator_SetHostReachable',
    );
    _setSuspended = libs.cbl.lookupFunction<CBLReplicator_SetSuspended_C,
        CBLReplicator_SetSuspended>(
      'CBLReplicator_SetSuspended',
    );
    _status =
        libs.cbl.lookupFunction<CBLReplicator_Status, CBLReplicator_Status>(
      'CBLReplicator_Status',
    );
    _pendingDocumentIDs = libs.cbl.lookupFunction<
        CBLReplicator_PendingDocumentIDs, CBLReplicator_PendingDocumentIDs>(
      'CBLReplicator_PendingDocumentIDs',
    );
    _isDocumentPending = libs.cblDart.lookupFunction<
        CBLDart_CBLReplicator_IsDocumentPending_C,
        CBLDart_CBLReplicator_IsDocumentPending>(
      'CBLDart_CBLReplicator_IsDocumentPending',
    );
    _addChangeListener = libs.cblDart.lookupFunction<
        CBLDart_CBLReplicator_AddChangeListener_C,
        CBLDart_CBLReplicator_AddChangeListener>(
      'CBLDart_CBLReplicator_AddChangeListener',
    );
    _addDocumentReplicationListener = libs.cblDart.lookupFunction<
        CBLDart_CBLReplicator_AddDocumentReplicationListener_C,
        CBLDart_CBLReplicator_AddDocumentReplicationListener>(
      'CBLDart_CBLReplicator_AddDocumentReplicationListener',
    );
  }

  late final CBLDart_CBLEndpoint_CreateWithURL _endpointCreateWithUrl;
  late final CBLEndpoint_Free _endpointFree;
  late final CBLDart_CBLAuth_CreatePassword _authCreatePassword;
  late final CBLDart_CBLAuth_CreateSession _authCreateSession;
  late final CBLAuth_Free _authFree;
  late final CBLDart_CBLReplicator_Create _create;
  late final CBLDart_BindReplicatorToDartObject _bindToDartObject;
  late final CBLReplicator_Start _start;
  late final CBLReplicator_Stop _stop;
  late final CBLReplicator_SetHostReachable _setHostReachable;
  late final CBLReplicator_SetSuspended _setSuspended;
  late final CBLReplicator_Status _status;
  late final CBLReplicator_PendingDocumentIDs _pendingDocumentIDs;
  late final CBLDart_CBLReplicator_IsDocumentPending _isDocumentPending;
  late final CBLDart_CBLReplicator_AddChangeListener _addChangeListener;
  late final CBLDart_CBLReplicator_AddDocumentReplicationListener
      _addDocumentReplicationListener;

  Pointer<CBLEndpoint> createEndpointWithUrl(String url) {
    return stringTable
        .autoFree(() => _endpointCreateWithUrl(stringTable.flString(url).ref));
  }

  void freeEndpoint(Pointer<CBLEndpoint> endpoint) {
    _endpointFree(endpoint);
  }

  Pointer<CBLAuthenticator> createPasswordAuthenticator(
    String username,
    String password,
  ) {
    return stringTable.autoFree(() => _authCreatePassword(
          stringTable.flString(username).ref,
          stringTable.flString(password).ref,
        ));
  }

  Pointer<CBLAuthenticator> createSessionAuthenticator(
    String sessionID,
    String? cookieName,
  ) {
    return stringTable.autoFree(() => _authCreateSession(
          stringTable.flString(sessionID).ref,
          stringTable.flString(cookieName).ref,
        ));
  }

  void freeAuthenticator(Pointer<CBLAuthenticator> authenticator) {
    _authFree(authenticator);
  }

  Pointer<CBLReplicator> createReplicator(
    Pointer<CBLDatabase> database,
    Pointer<CBLEndpoint> endpoint,
    CBLReplicatorType replicatorType,
    bool continuous,
    bool? disableAutoPurge,
    int? maxAttempts,
    int? maxAttemptWaitTime,
    int? heartbeat,
    Pointer<CBLAuthenticator>? authenticator,
    CBLProxyType? proxyType,
    String? proxyHostname,
    int? proxyPort,
    String? proxyUsername,
    String? proxyPassword,
    Pointer<FLDict>? headers,
    Uint8List? pinnedServerCertificate,
    Uint8List? trustedRootCertificates,
    Pointer<FLArray>? channels,
    Pointer<FLArray>? documentIDs,
    Pointer<Callback>? pushFilter,
    Pointer<Callback>? pullFilter,
    Pointer<Callback>? conflictResolver,
  ) {
    return withZoneArena(() {
      return _create(
        _createConfig(
          database,
          endpoint,
          replicatorType,
          continuous,
          disableAutoPurge,
          maxAttempts,
          maxAttemptWaitTime,
          heartbeat,
          authenticator,
          proxyType,
          proxyHostname,
          proxyPort,
          proxyUsername,
          proxyPassword,
          headers,
          pinnedServerCertificate,
          trustedRootCertificates,
          channels,
          documentIDs,
          pushFilter,
          pullFilter,
          conflictResolver,
        ),
        globalCBLError,
      ).checkCBLError();
    });
  }

  void bindReplicatorToDartObject(
    Object object,
    Pointer<CBLReplicator> replicator,
    String? debugName,
  ) {
    _bindToDartObject(
      object,
      replicator,
      debugName?.toNativeUtf8() ?? nullptr,
    );
  }

  void start(Pointer<CBLReplicator> replicator, bool resetCheckpoint) {
    _start(replicator, resetCheckpoint.toInt());
  }

  void stop(Pointer<CBLReplicator> replicator) {
    _stop(replicator);
  }

  void setHostReachable(Pointer<CBLReplicator> replicator, bool reachable) {
    _setHostReachable(replicator, reachable.toInt());
  }

  void setSuspended(Pointer<CBLReplicator> replicator, bool reachable) {
    _setSuspended(replicator, reachable.toInt());
  }

  CBLReplicatorStatus status(Pointer<CBLReplicator> replicator) {
    return _status(replicator).toCBLReplicatorStatus();
  }

  Pointer<FLDict> pendingDocumentIDs(Pointer<CBLReplicator> replicator) {
    return _pendingDocumentIDs(replicator, globalCBLError).checkCBLError();
  }

  bool isDocumentPending(
    Pointer<CBLReplicator> replicator,
    String docID,
  ) {
    return stringTable.autoFree(() {
      return _isDocumentPending(
        replicator,
        stringTable.flString(docID).ref,
        globalCBLError,
      ).checkCBLError().toBool();
    });
  }

  void addChangeListener(
    Pointer<CBLReplicator> replicator,
    Pointer<Callback> listener,
  ) {
    _addChangeListener(replicator, listener);
  }

  void addDocumentReplicationListener(
    Pointer<CBLReplicator> replicator,
    Pointer<Callback> listener,
  ) {
    _addDocumentReplicationListener(replicator, listener);
  }

  Pointer<CBLDartReplicatorConfiguration> _createConfig(
    Pointer<CBLDatabase> database,
    Pointer<CBLEndpoint> endpoint,
    CBLReplicatorType replicatorType,
    bool continuous,
    bool? disableAutoPurge,
    int? maxAttempts,
    int? maxAttemptWaitTime,
    int? heartbeat,
    Pointer<CBLAuthenticator>? authenticator,
    CBLProxyType? proxyType,
    String? proxyHostname,
    int? proxyPort,
    String? proxyUsername,
    String? proxyPassword,
    Pointer<FLDict>? headers,
    Uint8List? pinnedServerCertificate,
    Uint8List? trustedRootCertificates,
    Pointer<FLArray>? channels,
    Pointer<FLArray>? documentIDs,
    Pointer<Callback>? pushFilter,
    Pointer<Callback>? pullFilter,
    Pointer<Callback>? conflictResolver,
  ) {
    final result = zoneArena<CBLDartReplicatorConfiguration>();

    result.ref
      ..database = database
      ..endpoint = endpoint
      ..replicatorType = replicatorType
      ..continuous = continuous
      ..disableAutoPurge = disableAutoPurge ?? false
      ..maxAttempts = maxAttempts ?? 0
      ..maxAttemptWaitTime = maxAttemptWaitTime ?? 0
      ..heartbeat = heartbeat ?? 0
      ..authenticator = authenticator ?? nullptr
      ..proxy = _createProxySettings(
        proxyType,
        proxyHostname,
        proxyPort,
        proxyUsername,
        proxyPassword,
      )
      ..headers = headers ?? nullptr
      ..pinnedServerCertificate =
          pinnedServerCertificate?.copyToGlobalSliceInArena() ?? nullptr
      ..trustedRootCertificates =
          trustedRootCertificates?.copyToGlobalSliceInArena() ?? nullptr
      ..channels = channels ?? nullptr
      ..documentIDs = documentIDs ?? nullptr
      ..pushFilter = pushFilter ?? nullptr
      ..pullFilter = pullFilter ?? nullptr
      ..conflictResolver = conflictResolver ?? nullptr;

    return result;
  }

  Pointer<CBLDart_CBLProxySettings> _createProxySettings(
    CBLProxyType? type,
    String? hostname,
    int? port,
    String? username,
    String? password,
  ) {
    if (type == null) return nullptr;

    final result = zoneArena<CBLDart_CBLProxySettings>();

    result.ref
      ..type = type
      ..hostname = stringTable.flString(hostname!, arena: true).ref
      ..port = port!
      ..username = stringTable.flString(username, arena: true).ref
      ..password =
          stringTable.flString(password, arena: true, cache: false).ref;

    return result;
  }
}
