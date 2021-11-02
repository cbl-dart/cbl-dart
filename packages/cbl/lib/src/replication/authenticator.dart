import '../support/utils.dart';

/// The authentication credentials for a remote server.
///
/// {@category Replication}
abstract class Authenticator {}

/// An authenticator for HTTP Basic (username/password) auth.
///
/// {@category Replication}
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
      // ignore: missing_whitespace_between_adjacent_strings
      'password: ${redact(password)}'
      ')';
}

/// An authenticator using a Couchbase Sync Gateway login session identifier,
/// and optionally a cookie name (pass `null` for the default.)
///
/// {@category Replication}
class SessionAuthenticator extends Authenticator {
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
