import 'dart:ffi';

import '../ffi_utils.dart';
import 'bindings.dart';
import '../document.dart';

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

typedef CLBAuth_Free_C = Void Function(
  Pointer<CBLAuthenticator> authenticator,
);
typedef CLBAuth_Free = void Function(
  Pointer<CBLAuthenticator> authenticator,
);

/// Direction of replication: push, pull, or both.
enum ReplicatorType {
  /// Bidirectional; both push and pull
  pushAndPull,

  /// Pushing changes to the target
  push,

  /// Pulling changes from the target
  pull,
}

extension ReplicatorTypeIntExtension on ReplicatorType {
  int get toInt => ReplicatorType.values.indexOf(this);
}

extension IntReplicatorTypeExtension on int {
  ReplicatorType get toReplicatorType => ReplicatorType.values[this];
}

/// Types of proxy servers, for CBLProxySettings.
enum ProxyType {
  /// HTTP proxy; must support 'CONNECT' method
  http,

  /// HTTPS proxy; must support 'CONNECT' method
  https,
}

extension ProxyTypeIntExtension on ProxyType {
  int get toInt => ProxyType.values.indexOf(this);
}

extension IntProxyTypeExtension on int {
  ProxyType get toProxyType => ProxyType.values[this];
}

class CBLProxySettings extends Struct {
  @Uint8()
  external int type;

  external Pointer<Utf8> hostname;

  @Uint16()
  external int port;

  external Pointer<Utf8> username;

  external Pointer<Utf8> password;
}

class CBLDartReplicatorConfiguration extends Struct {
  external Pointer<CBLDatabase> database;

  external Pointer<CBLEndpoint> endpoint;

  @Uint8()
  external int replicatorType;

  @Uint8()
  external int continuous;

  external Pointer<CBLAuthenticator> authenticator;

  external Pointer<CBLProxySettings> proxy;

  external Pointer<FLDict> headers;

  external Pointer<FLSlice> pinnedServerCertificate;

  external Pointer<FLSlice> trustedRootCertificates;

  external Pointer<FLArray> channels;

  external Pointer<FLArray> documentIDS;

  @Int64()
  external int pushFilterId;

  @Int64()
  external int pullFilterId;

  @Int64()
  external int conflictResolver;
}

// === Replicator ==============================================================

class CBLReplicator extends Opaque {}

typedef CBLDart_CBLReplicator_New = Pointer<CBLReplicator> Function(
  Pointer<CBLDartReplicatorConfiguration> config,
  Pointer<CBLError> error,
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

/// The possible states a replicator can be in during its lifecycle.
enum ReplicatorActivityLevel {
  /// The replicator is unstarted, finished, or hit a fatal error.
  stopped,

  /// The replicator is offline, as the remote host is unreachable.
  offline,

  /// The replicator is connecting to the remote host.
  connecting,

  /// The replicator is inactive, waiting for changes to sync.
  idle,

  /// The replicator is actively transferring data.
  busy,
}

extension IntReplicatorActivityLevel on int {
  ReplicatorActivityLevel get toReplicatorActivityLevel =>
      ReplicatorActivityLevel.values[this];
}

class CBLReplicatorProgress extends Struct {
  @Float()
  external double fractionCompleted;

  @Uint64()
  external int documentCount;
}

class CBLReplicatorStatus extends Struct {
  @Uint8()
  external int activity;

  external CBLReplicatorProgress progress;

  external CBLError error;
}

typedef CBLReplicator_Status = CBLReplicatorStatus Function(
  Pointer<CBLReplicator> replicator,
);

typedef CBLReplicator_PendingDocumentIDs = FLDict Function(
  Pointer<CBLReplicator> replicator,
  Pointer<CBLError> error,
);

typedef CBLReplicator_IsDocumentPending_C = Uint8 Function(
  Pointer<CBLReplicator> replicator,
  FLSlice docID,
  Pointer<CBLError> error,
);
typedef CBLReplicator_IsDocumentPending = int Function(
  Pointer<CBLReplicator> replicator,
  FLSlice docID,
  Pointer<CBLError> error,
);

typedef CBLDart_CBLReplicator_AddChangeListener_C = Void Function(
  Pointer<CBLReplicator> replicator,
  Int64 listenerId,
);
typedef CBLDart_CBLReplicator_AddChangeListener = void Function(
  Pointer<CBLReplicator> replicator,
  int listenerId,
);

/// Flags describing a replicated [Document].
class DocumentFlags extends Option {
  const DocumentFlags(String debugName, int bits) : super(debugName, bits);

  /// The document has been deleted.
  static const deleted = DocumentFlags('deleted', 1);

  /// Lost access to the document on the server
  static const removed = DocumentFlags('removed', 2);
}

// === ReplicatorBindings ======================================================

class ReplicatorBindings {
  ReplicatorBindings(Libraries libs)
      : authDefaultCookieName =
            libs.cbl.lookup<Utf8>('kCBLAuthDefaultCookieName').asString,
        endpointNewWithUrl = libs.cbl
            .lookupFunction<CBLEndpoint_NewWithURL, CBLEndpoint_NewWithURL>(
          'CBLEndpoint_NewWithURL',
        ),
        endpointNewWithLocalDB = libs.cbl.lookupFunction<
            CBLEndpoint_NewWithLocalDB, CBLEndpoint_NewWithLocalDB>(
          'CBLEndpoint_NewWithLocalDB',
        ),
        endpointFree =
            libs.cbl.lookupFunction<CBLEndpoint_Free_C, CBLEndpoint_Free>(
          'CBLEndpoint_Free',
        ),
        authNewBasic =
            libs.cbl.lookupFunction<CBLAuth_NewBasic, CBLAuth_NewBasic>(
          'CBLAuth_NewBasic',
        ),
        authNewSession =
            libs.cbl.lookupFunction<CBLAuth_NewSession, CBLAuth_NewSession>(
          'CBLAuth_NewSession',
        ),
        authFree = libs.cbl.lookupFunction<CLBAuth_Free_C, CLBAuth_Free>(
          'CLBAuth_Free',
        ),
        makeNew = libs.cbl.lookupFunction<CBLDart_CBLReplicator_New,
            CBLDart_CBLReplicator_New>(
          'CBLDart_CBLReplicator_New',
        );

  final String authDefaultCookieName;
  final CBLEndpoint_NewWithURL endpointNewWithUrl;
  final CBLEndpoint_NewWithLocalDB endpointNewWithLocalDB;
  final CBLEndpoint_Free endpointFree;
  final CBLAuth_NewBasic authNewBasic;
  final CBLAuth_NewSession authNewSession;
  final CLBAuth_Free authFree;
  final CBLDart_CBLReplicator_New makeNew;
}
