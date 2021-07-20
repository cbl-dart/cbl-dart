/// The location of a database to replicate with.
abstract class Endpoint {}

/// An endpoint representing a server-based database at the given [url].
///
/// The Url's scheme must be `ws` or `wss`, it must of course have a valid
/// hostname, and its path must be the name of the database on that server.
/// The port can be omitted; it defaults to 80 for `ws` and 443 for `wss`.
/// For example: `wss://example.org/dbname`
class UrlEndpoint extends Endpoint {
  /// Creates an endpoint representing a server-based database at the given
  /// [url].
  UrlEndpoint(this.url);

  /// The url of the database to replicate with.
  final Uri url;

  @override
  String toString() => 'UrlEndpoint($url)';
}
