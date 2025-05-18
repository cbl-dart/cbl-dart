import '../support/utils.dart';
import 'tls_identity.dart';
import 'url_endpoint_listener.dart';

/// The authentication credentials for a remote server.
///
/// {@category Replication}
abstract interface class Authenticator {}

/// An authenticator for HTTP Basic (username/password) auth.
///
/// {@category Replication}
final class BasicAuthenticator extends Authenticator {
  /// Creates an authenticator for HTTP Basic (username/password) auth.
  BasicAuthenticator({required this.username, required this.password});

  /// The username to authenticate with.
  final String username;

  /// The password to authenticate with.
  final String password;

  @override
  String toString() => 'BasicAuthenticator('
      'username: $username, '
      // ignore: missing_whitespace_between_adjacent_strings
      'password: ${redact(password)}'
      ')';
}

/// An authenticator using a Couchbase Sync Gateway login session identifier,
/// and optionally a cookie name (pass `null` for the default.)
///
/// {@category Replication}
final class SessionAuthenticator extends Authenticator {
  /// Creates an authenticator using a Couchbase Sync Gateway login session
  /// identifier, and optionally a cookie name (pass `null` for the default.)
  SessionAuthenticator({
    required this.sessionId,
    String? cookieName,
  }) : cookieName = cookieName ?? _defaultCookieName;

  static const _defaultCookieName = 'SyncGatewaySession';

  /// The id of the session created by Sync Gateway.
  final String sessionId;

  /// The name of the session cookie to send the [sessionId] in.
  final String cookieName;

  @override
  String toString() => 'SessionAuthenticator('
      'sessionId: ${redact(sessionId)}, '
      // ignore: missing_whitespace_between_adjacent_strings
      'cookieName: $cookieName'
      ')';
}

/// An [Authenticator] that presents a client certificate to the server during
/// the initial SSL/TLS handshake.
///
/// {@macro cbl.EncryptionKey.enterpriseFeature}
///
/// This is currently only supported for authenticating with an
/// [UrlEndpointListener].
///
/// See also:
///
/// - [ListenerCertificateAuthenticator] for a [ListenerAuthenticator] that
///   authenticates clients using a [Certificate].
final class ClientCertificateAuthenticator extends Authenticator {
  /// Creates a new [ClientCertificateAuthenticator] that uses the [Certificate]
  /// and [KeyPair] of the given [identity] to authenticate the client to the
  /// server.
  ClientCertificateAuthenticator(this.identity);

  /// The [TlsIdentity] that contains the [Certificate] and [KeyPair] to use for
  /// authentication with the server.
  final TlsIdentity identity;

  @override
  String toString() => 'ClientCertificateAuthenticator(identity: $identity)';
}
