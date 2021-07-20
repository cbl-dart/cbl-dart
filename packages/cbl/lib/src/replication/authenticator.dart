import '../utils.dart';

/// The authentication credentials for a remote server.
abstract class Authenticator {}

/// An authenticator for HTTP Basic (username/password) auth.
class BasicAuthenticator extends Authenticator {
  /// Creates an authenticator for HTTP Basic (username/password) auth.
  BasicAuthenticator({required this.username, required this.password});

  /// The username to authenticate with.
  final String username;

  /// The password to authenticate with.
  final String password;

  @override
  String toString() => 'BasicAuthenticator('
      'username: $username, '
      'password: ${redact(password)}'
      ')';
}

/// An authenticator using a Couchbase Sync Gateway login session identifier,
/// and optionally a cookie name (pass `null` for the default.)
class SessionAuthenticator extends Authenticator {
  /// Creates an authenticator using a Couchbase Sync Gateway login session
  /// identifier, and optionally a cookie name (pass `null` for the default.)
  SessionAuthenticator({required this.sessionId, this.cookieName});

  /// The id of the session created by Sync Gateway.
  final String sessionId;

  /// The name of the session cookie to send the [sessionId] in.
  final String? cookieName;

  @override
  String toString() => 'SessionAuthenticator('
      'sessionId: ${redact(sessionId)}, '
      'cookieName: $cookieName'
      ')';
}
