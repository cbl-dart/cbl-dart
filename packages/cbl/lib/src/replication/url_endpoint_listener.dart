import 'dart:async';
import 'dart:ffi';

import '../bindings.dart';
import '../bindings/cblite.dart' hide CBLLogDomain, CBLLogLevel;
import '../bindings/cblitedart.dart' hide FLSlice, CBLCert, CBLCollection;
import '../database.dart';
import '../database/ffi_database.dart';
import '../database/proxy_database.dart';
import '../errors.dart';
import '../support/edition.dart';
import '../support/isolate.dart';
import '../support/native_object.dart';
import 'authenticator.dart';
import 'endpoint.dart';
import 'replicator.dart';
import 'tls_identity.dart';

final _bindings = CBLBindings.instance.urlEndpointListener;

/// Authenticates peer [Replicator]s connecting to a [UrlEndpointListener].
///
/// {@macro cbl.EncryptionKey.enterpriseFeature}
///
/// See also:
///
/// - [ListenerPasswordAuthenticator] for password-based authentication.
/// - [ListenerCertificateAuthenticator] for certificate-based authentication.
///
/// {@category Replication}
/// {@category Enterprise Edition}
abstract final class ListenerAuthenticator {}

final class FfiListenAuthenticator
    implements ListenerAuthenticator, Finalizable {
  FfiListenAuthenticator.fromPointer(this.pointer, {NativeCallable? callable})
    : _callable = callable {
    _callable?.keepIsolateAlive = false;
    _bindings.bindAuthenticatorToDartObject(this, pointer);
  }

  final Pointer<CBLListenerAuthenticator> pointer;
  final NativeCallable? _callable;

  int _activeListeners = 0;

  void _onListenerStarted() {
    _activeListeners++;
    if (_activeListeners == 0) {
      _callable?.keepIsolateAlive = true;
    }
  }

  void _onListenerStopped() {
    _activeListeners--;
    if (_activeListeners == 0) {
      _callable?.keepIsolateAlive = false;
    }
  }
}

/// Function that is called to authenticate a client connecting to a
/// [UrlEndpointListener] using an [username] and [password].
///
/// See also:
///
/// - [ListenerPasswordAuthenticator] for the [ListenerAuthenticator] that uses
///   this function.
///
/// {@category Replication}
/// {@category Enterprise Edition}
typedef ListenerPasswordAuthenticatorFunction =
    FutureOr<bool> Function(String username, String password);

/// A password-based [ListenerAuthenticator] for a [UrlEndpointListener].
///
/// {@macro cbl.EncryptionKey.enterpriseFeature}
///
/// {@category Replication}
/// {@category Enterprise Edition}
final class ListenerPasswordAuthenticator implements ListenerAuthenticator {
  /// Creates a new [ListenerPasswordAuthenticator] that uses the given
  /// [handler] to authenticate clients.
  factory ListenerPasswordAuthenticator(
    ListenerPasswordAuthenticatorFunction handler,
  ) = _ListenerPasswordAuthenticator;
}

final class _ListenerPasswordAuthenticator extends FfiListenAuthenticator
    implements ListenerPasswordAuthenticator {
  factory _ListenerPasswordAuthenticator(
    ListenerPasswordAuthenticatorFunction handler,
  ) {
    useEnterpriseFeature(EnterpriseFeature.peerToPeerSync);

    Future<void> trampoline(
      CBLDart_Completer completer,
      FLSlice username,
      FLSlice password,
    ) async {
      var result = false;

      try {
        result = await handler(
          username.toDartString()!,
          password.toDartString()!,
        );
        // ignore: avoid_catches_without_on_clauses
      } catch (error, stackTrace) {
        CBLBindings.instance.logging.logMessage(
          CBLLogDomain.listener,
          CBLLogLevel.error,
          'Exception in ListenerPasswordAuthenticator:\n'
          '$error\n'
          '$stackTrace',
        );
        rethrow;
      } finally {
        CBLBindings.instance.base.completeCompleterWithBool(completer, result);
      }
    }

    final callable =
        NativeCallable<CBLDartListenerPasswordAuthCallbackFunction>.listener(
          trampoline,
        );

    return _ListenerPasswordAuthenticator.fromPointer(
      _bindings.createPasswordAuthenticator(callable.nativeFunction),
      callable: callable,
    );
  }

  _ListenerPasswordAuthenticator.fromPointer(super.pointer, {super.callable})
    : super.fromPointer();

  @override
  String toString() => 'ListenerPasswordAuthenticator()';
}

/// A function that is called to authenticate a client connecting to a
/// [UrlEndpointListener] using a [certificate].
///
/// See also:
///
/// - [ListenerCertificateAuthenticator] for the [ListenerAuthenticator] that
///   uses this function.
///
/// {@category Replication}
/// {@category Enterprise Edition}
typedef ListenerCertificateAuthenticatorFunction =
    FutureOr<bool> Function(Certificate certificate);

/// A certificate-based [ListenerAuthenticator] for a [UrlEndpointListener].
///
/// {@macro cbl.EncryptionKey.enterpriseFeature}
///
/// See also:
///
/// - [ClientCertificateAuthenticator] for a client [Authenticator] that uses a
///   [Certificate] to authenticate a client to an [UrlEndpointListener].
///
/// {@category Replication}
/// {@category Enterprise Edition}
final class ListenerCertificateAuthenticator implements ListenerAuthenticator {
  /// Creates a new [ListenerCertificateAuthenticator] that uses the given
  /// [handler] to authenticate clients.
  factory ListenerCertificateAuthenticator(
    ListenerCertificateAuthenticatorFunction handler,
  ) = _ListenerCertificateAuthenticator;

  /// Creates a new [ListenerCertificateAuthenticator] that trusts the given
  /// root [certificates] when authenticating clients.
  factory ListenerCertificateAuthenticator.fromRoots(
    List<Certificate> certificates,
  ) = _ListenerCertificateAuthenticatorFromRoots;
}

final class _ListenerCertificateAuthenticator extends FfiListenAuthenticator
    implements ListenerCertificateAuthenticator {
  factory _ListenerCertificateAuthenticator(
    ListenerCertificateAuthenticatorFunction handler,
  ) {
    useEnterpriseFeature(EnterpriseFeature.peerToPeerSync);

    Future<void> trampoline(
      CBLDart_Completer completer,
      Pointer<CBLCert> certificate,
    ) async {
      var result = false;

      try {
        result = await handler(FfiCertificate.fromPointer(certificate));
        // ignore: avoid_catches_without_on_clauses
      } catch (error, stackTrace) {
        CBLBindings.instance.logging.logMessage(
          CBLLogDomain.listener,
          CBLLogLevel.error,
          'Exception in ListenerCertificateAuthenticator:\n'
          '$error\n'
          '$stackTrace',
        );
        rethrow;
      } finally {
        CBLBindings.instance.base.completeCompleterWithBool(completer, result);
      }
    }

    final callable =
        NativeCallable<CBLDartListenerCertAuthCallbackFunction>.listener(
          trampoline,
        );

    return _ListenerCertificateAuthenticator.fromPointer(
      _bindings.createCertificateAuthenticator(callable.nativeFunction),
      callable: callable,
    );
  }

  _ListenerCertificateAuthenticator.fromPointer(super.pointer, {super.callable})
    : super.fromPointer();

  @override
  String toString() => 'ListenerCertificateAuthenticator()';
}

final class _ListenerCertificateAuthenticatorFromRoots
    extends FfiListenAuthenticator
    implements ListenerCertificateAuthenticator {
  factory _ListenerCertificateAuthenticatorFromRoots(
    List<Certificate> certificates,
  ) {
    useEnterpriseFeature(EnterpriseFeature.peerToPeerSync);

    return _ListenerCertificateAuthenticatorFromRoots.fromPointer(
      _bindings.createCertificateAuthenticatorWithRoots(
        FfiCertificate.combined(certificates.cast()).pointer,
      ),
      certificates: certificates,
    );
  }

  _ListenerCertificateAuthenticatorFromRoots.fromPointer(
    super.pointer, {
    required List<Certificate> certificates,
  }) : _certificates = certificates,
       super.fromPointer();

  final List<Certificate> _certificates;

  @override
  String toString() =>
      'ListenerCertificateAuthenticator.fromRoots($_certificates)';
}

/// The configuration for an [UrlEndpointListener].
///
/// {@macro cbl.EncryptionKey.enterpriseFeature}
///
/// {@category Replication}
/// {@category Enterprise Edition}
final class UrlEndpointListenerConfiguration {
  /// Creates a new [UrlEndpointListenerConfiguration] with the specified
  /// parameters.
  ///
  /// The [collections] parameter must not be empty. All [Collection]s in the
  /// list must belong to the same [Database].
  ///
  /// If one of the [Collection]s is removed during the replication, the
  /// listener will be stopped and the connections to the connected clients
  /// closed with an error.
  UrlEndpointListenerConfiguration({
    required List<Collection> collections,
    this.port,
    this.networkInterface,
    this.disableTls = false,
    this.tlsIdentity,
    this.authenticator,
    this.enableDeltaSync = false,
    this.readOnly = false,
  }) {
    this.collections = collections;
  }

  /// Creates a new [UrlEndpointListenerConfiguration] that is initialized with
  /// the state of the given [config].
  UrlEndpointListenerConfiguration.from(UrlEndpointListenerConfiguration config)
    : _collections = List.unmodifiable(config.collections),
      port = config.port,
      networkInterface = config.networkInterface,
      disableTls = config.disableTls,
      tlsIdentity = config.tlsIdentity,
      authenticator = config.authenticator,
      enableDeltaSync = config.enableDeltaSync,
      readOnly = config.readOnly;

  /// The [Collection]s available for replication.
  ///
  /// This list must not be empty.
  List<Collection> get collections => _collections;
  List<Collection> _collections = const [];

  set collections(List<Collection> value) {
    if (value.isEmpty) {
      throw DatabaseException(
        'URLEndpointListenerConfiguration.collections must not be empty.',
        DatabaseErrorCode.invalidParameter,
      );
    }
    _collections = List.unmodifiable(value);
  }

  /// The port that the listener will listen to.
  ///
  /// If not specified, the listener will automatically select an available port
  /// to listen to when the listener is started.
  int? port;

  /// The network interface in the form of an IP Address or network interface
  /// name such as `en0` that the listener will listen to.
  ///
  /// If not specified, the listener will listen to all network interfaces.
  String? networkInterface;

  /// Whether to disable TLS communication.
  ///
  /// The default is `false`, which means TLS is enabled.
  bool disableTls;

  /// The [TlsIdentity] to use for TLS communication.
  ///
  /// If not specified, a generated anonymous self-signed identity will be used,
  /// unless [disableTls] is set to `true`.
  TlsIdentity? tlsIdentity;

  /// The [ListenerAuthenticator] to authenticate clients connecting to the
  /// listener.
  ///
  /// If not specified, no authentication will be performed and all clients will
  /// be allowed to connect.
  ListenerAuthenticator? authenticator;

  /// Whether to allow delta sync when replicating with the listener.
  ///
  /// The default is `false`, which means delta sync is not allowed.
  bool enableDeltaSync;

  /// Whether to only allow pull replication with the listener.
  ///
  /// The default is `false`, which means both pull and push replication are
  /// allowed.
  bool readOnly;

  @override
  String toString() => [
    'URLEndpointListenerConfiguration(',
    [
      'collections: $collections',
      if (port != null) 'port: $port',
      if (networkInterface != null) 'networkInterface: $networkInterface',
      if (disableTls) 'DISABLE-TLS',
      if (tlsIdentity != null) 'tlsIdentity: $tlsIdentity',
      if (authenticator != null) 'authenticator: $authenticator',
      if (enableDeltaSync) 'ENABLE-DELTA-SYNC',
      if (readOnly) 'READ-ONLY',
    ].join(', '),
    ')',
  ].join();
}

/// The connection status of an [UrlEndpointListener].
///
/// {@macro cbl.EncryptionKey.enterpriseFeature}
///
/// {@category Replication}
/// {@category Enterprise Edition}
final class ConnectionStatus {
  /// Creates a new [ConnectionStatus] with the specified parameters.
  ConnectionStatus({
    required this.connectionCount,
    required this.activeConnectionCount,
  });

  /// The number of clients currently connected to the listener.
  final int connectionCount;

  /// The number of clients currently replicating with the listener.
  final int activeConnectionCount;

  @override
  String toString() =>
      'ConnectionStatus('
      'connectionCount: $connectionCount, '
      'activeConnectionCount: $activeConnectionCount'
      ')';
}

/// A listener to provide a Web-Socket based endpoint for peer-to-peer
/// replication.
///
/// {@macro cbl.EncryptionKey.enterpriseFeature}
///
/// Once the listener is [start]ed, peer [Replicator]s can connect to the
/// listener by using an [UrlEndpoint].
///
/// A started listener will keep the current isolate from exiting until the
/// listener is stopped.
///
/// {@category Replication}
/// {@category Enterprise Edition}
abstract final class UrlEndpointListener {
  /// Creates a new [UrlEndpointListener] with the specified configuration.
  static Future<UrlEndpointListener> create(
    UrlEndpointListenerConfiguration config,
  ) => FfiUrlEndpointListener.create(config);

  /// The configuration of this listener.
  UrlEndpointListenerConfiguration get config;

  /// The port this listener is listening on.
  ///
  /// If this listener has not been started yet, this will be `null`.
  int? get port;

  /// The URLs this listener is listening on.
  ///
  /// If [UrlEndpointListenerConfiguration.networkInterface] has been provided,
  /// this list will contain a single URL that reflects the network interface
  /// address.
  ///
  /// If this listener has not been started yet, this will be `null`.
  List<Uri>? get urls;

  /// The [TlsIdentity] used for TLS communication by this listener.
  TlsIdentity? get tlsIdentity;

  /// The current [ConnectionStatus] of this listener.
  ConnectionStatus get connectionStatus;

  /// Starts this listener.
  Future<void> start();

  /// Stops this listener.
  Future<void> stop();
}

final class FfiUrlEndpointListener implements UrlEndpointListener, Finalizable {
  FfiUrlEndpointListener.fromPointer(
    this._pointer, {
    required UrlEndpointListenerConfiguration config,
    required this.tlsIdentity,
    required bool adopt,
  }) : _config = UrlEndpointListenerConfiguration.from(config) {
    bindCBLRefCountedToDartObject(this, pointer: _pointer, adopt: adopt);
  }

  static Future<FfiUrlEndpointListener> create(
    UrlEndpointListenerConfiguration config,
  ) async {
    useEnterpriseFeature(EnterpriseFeature.peerToPeerSync);

    var tlsIdentity = config.tlsIdentity as FfiTlsIdentity?;
    if (tlsIdentity == null && !config.disableTls) {
      tlsIdentity = await FfiTlsIdentity.createIdentity(
        keyUsages: {KeyUsage.serverAuth},
        attributes: const CertificateAttributes(commonName: 'anonymous'),
        expiration: DateTime.now().add(const Duration(days: 30)),
      );
    }

    final pointer = await _create(
      collections: config.collections
          .map(
            (collection) => switch (collection) {
              FfiCollection() => collection.pointer,
              ProxyCollection() => collection.state.pointer,
              _ => throw UnimplementedError(),
            },
          )
          .toList(),
      port: config.port,
      networkInterface: config.networkInterface,
      disableTls: config.disableTls,
      tlsIdentityPointer: tlsIdentity?.pointer,
      authenticatorPointer:
          (config.authenticator as FfiListenAuthenticator?)?.pointer,
      enableDeltaSync: config.enableDeltaSync,
      readOnly: config.readOnly,
    );

    return FfiUrlEndpointListener.fromPointer(
      pointer,
      config: config,
      tlsIdentity: tlsIdentity,
      adopt: true,
    );
  }

  static Future<Pointer<CBLURLEndpointListener>> _create({
    required List<Pointer<CBLCollection>> collections,
    required int? port,
    required String? networkInterface,
    required bool disableTls,
    required Pointer<CBLTLSIdentity>? tlsIdentityPointer,
    required Pointer<CBLListenerAuthenticator>? authenticatorPointer,
    required bool enableDeltaSync,
    required bool readOnly,
  }) async => runInSecondaryIsolate(
    () => _bindings.create(
      collections: collections,
      port: port,
      networkInterface: networkInterface,
      disableTls: disableTls,
      tlsIdentity: tlsIdentityPointer,
      authenticator: authenticatorPointer,
      enableDeltaSync: enableDeltaSync,
      readOnly: readOnly,
    ),
  );

  final Pointer<CBLURLEndpointListener> _pointer;
  final UrlEndpointListenerConfiguration _config;

  @override
  final TlsIdentity? tlsIdentity;

  FfiListenAuthenticator? get _authenticator =>
      _config.authenticator as FfiListenAuthenticator?;

  @override
  UrlEndpointListenerConfiguration get config =>
      UrlEndpointListenerConfiguration.from(_config);

  @override
  int? get port => _bindings.port(_pointer);

  @override
  List<Uri>? get urls => _bindings.urls(_pointer);

  @override
  ConnectionStatus get connectionStatus {
    final status = _bindings.connectionStatus(_pointer);
    return ConnectionStatus(
      connectionCount: status.connectionCount,
      activeConnectionCount: status.activeConnectionCount,
    );
  }

  @override
  Future<void> start() async {
    final pointer = _pointer;
    await runInSecondaryIsolate(() => _bindings.start(pointer));
    _authenticator?._onListenerStarted();
  }

  @override
  Future<void> stop() async {
    final pointer = _pointer;
    await runInSecondaryIsolate(() => _bindings.stop(pointer));
    _authenticator?._onListenerStopped();
  }

  @override
  String toString() => [
    'UrlEndpointListener(',
    [
      'config: $config',
      if (port != null) 'port: $port',
      if (urls != null) 'urls: $urls',
      if (tlsIdentity != null) 'tlsIdentity: $tlsIdentity',
      'connectionStatus: $connectionStatus',
    ].join(', '),
    ')',
  ].join();
}
