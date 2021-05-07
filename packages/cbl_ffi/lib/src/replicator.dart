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

typedef CBLEndpoint_NewWithURL = Pointer<CBLEndpoint> Function(
  Pointer<Utf8> url,
);

typedef CBLEndpoint_NewWithLocalDB = Pointer<CBLEndpoint> Function(
  Pointer<CBLDatabase> database,
);

typedef CBLEndpoint_Free_C = Void Function(
  Pointer<CBLEndpoint> endpoint,
);
typedef CBLEndpoint_Free = void Function(
  Pointer<CBLEndpoint> endpoint,
);

class CBLAuthenticator extends Opaque {}

typedef CBLAuth_NewBasic = Pointer<CBLAuthenticator> Function(
  Pointer<Utf8> username,
  Pointer<Utf8> password,
);

typedef CBLAuth_NewSession = Pointer<CBLAuthenticator> Function(
  Pointer<Utf8> sessionID,
  Pointer<Utf8> cookieName,
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

extension on int {
  CBLReplicatorType toReplicatorType() => CBLReplicatorType.values[this];
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

class CBLProxySettings extends Struct {
  @Uint8()
  external int _type;

  external Pointer<Utf8> hostname;

  @Uint16()
  external int port;

  external Pointer<Utf8> username;

  external Pointer<Utf8> password;
}

extension CBLProxySettingsExt on CBLProxySettings {
  CBLProxyType get type => _type.toProxyType();
  set type(CBLProxyType value) => _type = value.toInt();
}

class CBLDartReplicatorConfiguration extends Struct {
  external Pointer<CBLDatabase> database;

  external Pointer<CBLEndpoint> endpoint;

  @Uint8()
  external int _replicatorType;

  @Uint8()
  external int _continuous;

  external Pointer<CBLAuthenticator> authenticator;

  external Pointer<CBLProxySettings> proxy;

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
  CBLReplicatorType get replicatorType => _replicatorType.toReplicatorType();
  set replicatorType(CBLReplicatorType value) =>
      _replicatorType = value.toInt();
  bool get continuous => _continuous.toBool();
  set continuous(bool value) => _continuous = value.toInt();
}

class ReplicationFilterCallbackMessage {
  ReplicationFilterCallbackMessage(this.document, this.isDeleted);

  ReplicationFilterCallbackMessage.fromArguments(List<dynamic> arguments)
      : this(
          (arguments[0] as int).toPointer(),
          arguments[1] as bool,
        );

  final Pointer<CBLDocument> document;
  final bool isDeleted;
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
          arguments[0] as String,
          (arguments[1] as int?)?.toPointer(),
          (arguments[2] as int?)?.toPointer(),
        );

  final String documentId;
  final Pointer<CBLDocument>? localDocument;
  final Pointer<CBLDocument>? remoteDocument;
}

// === Replicator ==============================================================

class CBLReplicator extends Opaque {}

typedef CBLDart_CBLReplicator_New = Pointer<CBLReplicator> Function(
  Pointer<CBLDartReplicatorConfiguration> config,
  Pointer<CBLError> error,
);

typedef CBLDart_BindReplicatorToDartObject_C = Void Function(
  Handle object,
  Pointer<CBLReplicator> replicator,
);
typedef CBLDart_BindReplicatorToDartObject = void Function(
  Object object,
  Pointer<CBLReplicator> replicator,
);

typedef CBLReplicator_ResetCheckpoint_C = Void Function(
  Pointer<CBLReplicator> replicator,
);
typedef CBLReplicator_ResetCheckpoint = void Function(
  Pointer<CBLReplicator> replicator,
);

typedef CBLReplicator_Start_C = Void Function(
  Pointer<CBLReplicator> replicator,
);
typedef CBLReplicator_Start = void Function(
  Pointer<CBLReplicator> replicator,
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

class CBLReplicatorProgress extends Struct {
  @Float()
  external double fractionCompleted;

  @Uint64()
  external int documentCount;
}

class CBLReplicatorStatus extends Struct {
  @Uint8()
  external int _activity;

  external CBLReplicatorProgress progress;

  external CBLError _error;
}

extension CBLReplicatorStatusExt on CBLReplicatorStatus {
  CBLReplicatorActivityLevel get activity =>
      _activity.toReplicatorActivityLevel();

  CBLErrorException? get exception {
    if (!_error.isOk) {
      _error.copyToGlobal();
      return CBLErrorException.fromCBLError(globalCBLError);
    }
  }
}

typedef CBLReplicator_Status = CBLReplicatorStatus Function(
  Pointer<CBLReplicator> replicator,
);

typedef CBLReplicator_PendingDocumentIDs = Pointer<FLDict> Function(
  Pointer<CBLReplicator> replicator,
  Pointer<CBLError> error,
);

typedef CBLDart_CBLReplicator_IsDocumentPending_C = Uint8 Function(
  Pointer<CBLReplicator> replicator,
  Pointer<Utf8> docID,
  Pointer<CBLError> error,
);
typedef CBLDart_CBLReplicator_IsDocumentPending = int Function(
  Pointer<CBLReplicator> replicator,
  Pointer<Utf8> docID,
  Pointer<CBLError> error,
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

class CBLDartReplicatedDocument extends Struct {
  external Pointer<Utf8> ID;

  @Uint32()
  external int _flags;

  external CBLError _error;
}

extension CBLDartReplicatedDocumentExt on CBLDartReplicatedDocument {
  Set<CBLReplicatedDocumentFlag> get flags =>
      CBLReplicatedDocumentFlag._parseCFlags(_flags);

  CBLErrorException? get exception {
    if (!_error.isOk) {
      _error.copyToGlobal();
      return CBLErrorException.fromCBLError(globalCBLError);
    }
  }
}

typedef CBLDart_CBLReplicator_AddDocumentListener_C = Void Function(
  Pointer<CBLReplicator> replicator,
  Pointer<Callback> listener,
);
typedef CBLDart_CBLReplicator_AddDocumentListener = void Function(
  Pointer<CBLReplicator> replicator,
  Pointer<Callback> listener,
);

class ReplicatorStatusCallbackMessage {
  ReplicatorStatusCallbackMessage(this.status);

  ReplicatorStatusCallbackMessage.fromArguments(List<dynamic> arguments)
      : this((arguments[0] as int).toPointer());

  final Pointer<CBLReplicatorStatus> status;
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
  final Pointer<CBLDartReplicatedDocument> documents;
}

// === ReplicatorBindings ======================================================

class ReplicatorBindings extends Bindings {
  ReplicatorBindings(Bindings parent) : super(parent) {
    _endpointNewWithUrl =
        libs.cbl.lookupFunction<CBLEndpoint_NewWithURL, CBLEndpoint_NewWithURL>(
      'CBLEndpoint_NewWithURL',
    );
    _endpointNewWithLocalDB = libs.cblEE?.lookupFunction<
        CBLEndpoint_NewWithLocalDB, CBLEndpoint_NewWithLocalDB>(
      'CBLEndpoint_NewWithLocalDB',
    );
    _endpointFree =
        libs.cbl.lookupFunction<CBLEndpoint_Free_C, CBLEndpoint_Free>(
      'CBLEndpoint_Free',
    );
    _authNewBasic = libs.cbl.lookupFunction<CBLAuth_NewBasic, CBLAuth_NewBasic>(
      'CBLAuth_NewBasic',
    );
    _authNewSession =
        libs.cbl.lookupFunction<CBLAuth_NewSession, CBLAuth_NewSession>(
      'CBLAuth_NewSession',
    );
    _authFree = libs.cbl.lookupFunction<CBLAuth_Free_C, CBLAuth_Free>(
      'CBLAuth_Free',
    );
    _new = libs.cblDart
        .lookupFunction<CBLDart_CBLReplicator_New, CBLDart_CBLReplicator_New>(
      'CBLDart_CBLReplicator_New',
    );
    _bindToDartObject = libs.cblDart.lookupFunction<
        CBLDart_BindReplicatorToDartObject_C,
        CBLDart_BindReplicatorToDartObject>(
      'CBLDart_BindReplicatorToDartObject',
    );
    _resetCheckpoint = libs.cbl.lookupFunction<CBLReplicator_ResetCheckpoint_C,
        CBLReplicator_ResetCheckpoint>(
      'CBLReplicator_ResetCheckpoint',
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
    _addDocumentListener = libs.cblDart.lookupFunction<
        CBLDart_CBLReplicator_AddDocumentListener_C,
        CBLDart_CBLReplicator_AddDocumentListener>(
      'CBLDart_CBLReplicator_AddDocumentListener',
    );
  }

  late final CBLEndpoint_NewWithURL _endpointNewWithUrl;
  late final CBLEndpoint_NewWithLocalDB? _endpointNewWithLocalDB;
  late final CBLEndpoint_Free _endpointFree;
  late final CBLAuth_NewBasic _authNewBasic;
  late final CBLAuth_NewSession _authNewSession;
  late final CBLAuth_Free _authFree;
  late final CBLDart_CBLReplicator_New _new;
  late final CBLDart_BindReplicatorToDartObject _bindToDartObject;
  late final CBLReplicator_ResetCheckpoint _resetCheckpoint;
  late final CBLReplicator_Start _start;
  late final CBLReplicator_Stop _stop;
  late final CBLReplicator_SetHostReachable _setHostReachable;
  late final CBLReplicator_SetSuspended _setSuspended;
  late final CBLReplicator_Status _status;
  late final CBLReplicator_PendingDocumentIDs _pendingDocumentIDs;
  late final CBLDart_CBLReplicator_IsDocumentPending _isDocumentPending;
  late final CBLDart_CBLReplicator_AddChangeListener _addChangeListener;
  late final CBLDart_CBLReplicator_AddDocumentListener _addDocumentListener;

  Pointer<CBLEndpoint> createEndpointWithUrl(String url) {
    return stringTable
        .autoFree(() => _endpointNewWithUrl(stringTable.cString(url)));
  }

  Pointer<CBLEndpoint> createEndpointWithLocalDB(
    Pointer<CBLDatabase> database,
  ) {
    return _endpointNewWithLocalDB!(database);
  }

  void freeEndpoint(Pointer<CBLEndpoint> endpoint) {
    _endpointFree(endpoint);
  }

  Pointer<CBLAuthenticator> createBasicAuthenticator(
    String username,
    String password,
  ) {
    return stringTable.autoFree(() => _authNewBasic(
          stringTable.cString(username),
          stringTable.cString(password),
        ));
  }

  Pointer<CBLAuthenticator> createSessionAuthenticator(
    String sessionID,
    String? cookieName,
  ) {
    return stringTable.autoFree(() => _authNewSession(
          stringTable.cString(sessionID),
          cookieName == null ? nullptr : stringTable.cString(cookieName),
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
    return runArena(() {
      return _new(
        _createConfig(
          database,
          endpoint,
          replicatorType,
          continuous,
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
  ) {
    _bindToDartObject(object, replicator);
  }

  void resetCheckpoint(Pointer<CBLReplicator> replicator) {
    _resetCheckpoint(replicator);
  }

  void start(Pointer<CBLReplicator> replicator) {
    _start(replicator);
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
    return _status(replicator);
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
        stringTable.cString(docID),
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

  void addDocumentListener(
    Pointer<CBLReplicator> replicator,
    Pointer<Callback> listener,
  ) {
    _addDocumentListener(replicator, listener);
  }

  Pointer<CBLDartReplicatorConfiguration> _createConfig(
    Pointer<CBLDatabase> database,
    Pointer<CBLEndpoint> endpoint,
    CBLReplicatorType replicatorType,
    bool continuous,
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
    final result = malloc<CBLDartReplicatorConfiguration>().withScoped();

    result.ref
      ..database = database
      ..endpoint = endpoint
      ..replicatorType = replicatorType
      ..continuous = continuous
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
          pinnedServerCertificate?.copyToGlobalSliceScoped() ?? nullptr
      ..trustedRootCertificates =
          trustedRootCertificates?.copyToGlobalSliceScoped() ?? nullptr
      ..channels = channels ?? nullptr
      ..documentIDs = documentIDs ?? nullptr
      ..pushFilter = pushFilter ?? nullptr
      ..pullFilter = pullFilter ?? nullptr
      ..conflictResolver = conflictResolver ?? nullptr;

    return result;
  }

  Pointer<CBLProxySettings> _createProxySettings(
    CBLProxyType? type,
    String? hostname,
    int? port,
    String? username,
    String? password,
  ) {
    if (type == null) return nullptr;

    final result = malloc<CBLProxySettings>().withScoped();

    result.ref
      ..type = type
      ..hostname = stringTable.cString(hostname!, arena: true)
      ..port = port!
      ..username = stringTable.cString(username, arena: true)
      ..password = stringTable.cString(password, arena: true, cache: false);

    return result;
  }
}
