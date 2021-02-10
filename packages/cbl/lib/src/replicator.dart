import 'dart:typed_data';

import 'bindings/bindings.dart';
import 'database.dart';
import 'document.dart';
import 'errors.dart';
import 'fleece.dart';

export 'bindings/bindings.dart'
    show ReplicatorType, ProxyType, ReplicatorActivityLevel, DocumentFlags;

// TODO: equals and hash

/// The location of a database to replicate with.
abstract class Endpoint {}

/// An endpoint representing a server-based database at the given [url].
///
/// The Url's scheme must be `ws` or `wss`, it must of course have a valid
/// hostname, and its path must be the name of the database on that server.
/// The port can be omitted; it defaults to 80 for `ws` and 443 for `wss`.
/// For example: `wss://example.org/dbname`
class UrlEndpoint extends Endpoint {
  UrlEndpoint(this.url);

  final Uri url;
}

/// An endpoint representing another local database. (Enterprise Edition only.)
class LocalDbEndpoint extends Endpoint {
  LocalDbEndpoint(this.database);

  final Database database;
}

/// The authentication credentials for a remote server.
abstract class Authenticator {}

/// An authenticator for HTTP Basic (username/password) auth.
class BasicAuthenticator extends Authenticator {
  BasicAuthenticator({required this.username, required this.password});

  final String username;

  final String password;
}

/// An authenticator using a Couchbase Sync Gateway login session identifier,
/// and optionally a cookie name (pass `null` for the default.)
class SessionAuthenticator extends Authenticator {
  SessionAuthenticator({required this.sessionID, required this.cookieName});

  final String sessionID;

  final String cookieName;
}

/// A callback that can decide whether a particular document should be pushed or
/// pulled.
///
/// It should not take a long time to return, or it will slow down the
/// replicator.
///
/// The callback receives the [document] in question and whether it [isDeleted].
///
/// Return `true` if the document should be replicated, `false` to skip it.
typedef ReplicationFilter = bool Function(Document document, bool isDeleted);

/// Conflict-resolution callback for use in replications.
///
/// This callback will be invoked when the [Replicator] finds a newer
/// server-side revision of a document that also has local changes. The local
/// and remote changes must be resolved before the document can be pushed to the
/// server.
///
/// Unlike a [ReplicationFilter], it does not need to return quickly. If it
/// needs to prompt for user input, that's OK.
///
/// The callback receives the [documentId] of the conflicted document,
/// the [local] current revision of the document in the, or `null` if the
/// local document has been deleted and the the remove revision of the document
/// found on the server or `null` if the document has been deleted on the
/// server.
///
/// Return the resolved document to save locally (and push, if the replicator is
/// pushing.) This can be the same as [local] or [remote], or you can create
/// a mutable copy of either one and modify it appropriately.
/// Alternatively return `null` if the resolution is to delete the document.
typedef ConflictResolver = Document Function(
  String documentId,
  Document? local,
  Document? remote,
);

/// Default conflict resolver. This always returns `localDocument`.
Document defaultConflictResolver(
  String documentId,
  Document local,
  Document remote,
) =>
    local;

/// Proxy settings for the replicator.
class ProxySettings {
  ProxySettings({
    required this.type,
    required this.hostname,
    required this.port,
    this.username,
    required this.password,
  });

  /// Type of proxy
  final ProxyType type;

  /// Proxy server hostname or IP address
  final String hostname;

  /// Proxy server port
  final int port;

  /// Username for proxy auth (optional)
  final String? username;

  /// Password for proxy auth
  final String password;
}

/// The configuration of a replicator.
class ReplicatorConfiguration {
  ReplicatorConfiguration({
    required this.database,
    required this.endpoint,
    required this.replicatorType,
    required this.continuous,
    this.authenticator,
    this.proxy,
    this.headers,
    this.pinnedServerCertificate,
    this.trustedRootCertificates,
    this.channels,
    this.documentIDs,
    this.pushFilter,
    this.pullFilter,
    this.conflictResolver,
  });

  /// The database to replicate
  final Database database;

  /// The address of the other database to replicate with
  final Endpoint endpoint;

  /// Push, pull or both
  final ReplicatorType replicatorType;

  /// Continuous replication?
  final bool continuous;

  /// Authentication credentials, if needed
  final Authenticator? authenticator;

  /// HTTP client proxy settings
  final ProxySettings? proxy;

  /// Extra HTTP headers to add to the WebSocket request
  final Map<String, String>? headers;

  /// An X.509 cert to "pin" TLS connections to (PEM or DER)
  final Uint8List? pinnedServerCertificate;

  /// Set of anchor certs (PEM format)
  final Uint8List? trustedRootCertificates;

  /// Optional set of channels to pull from
  final List<String>? channels;

  /// Optional set of document IDs to replicate
  final List<String>? documentIDs;

  /// Optional callback to filter which docs are pushed
  final ReplicationFilter? pushFilter;

  /// Optional callback to validate incoming docs
  final ReplicationFilter? pullFilter;

  /// Optional conflict-resolver callback
  final ConflictResolver? conflictResolver;
}

/// A fractional progress value, ranging from 0.0 to 1.0 as replication
/// progresses.
///
/// The value is very approximate and may bounce around during replication;
/// making it more accurate would require slowing down the replicator and
/// incurring more load on the server. It's fine to use in a progress bar,
/// though.
class ReplicatorProgress {
  ReplicatorProgress(this.fractionComplete, this.documentCount);

  /// Very-approximate completion, from 0.0 to 1.0
  final double fractionComplete;

  /// Number of documents transferred so far
  final int documentCount;
}

/// A [Replicator]'s current status
class ReplicatorStatus {
  ReplicatorStatus(this.activity, this.progress, this.error);

  /// Current state
  final ReplicatorActivityLevel activity;

  /// Approximate fraction complete
  final ReplicatorProgress progress;

  /// Error, if any
  final BaseException? error;
}

/// A callback that notifies you when the [Replicator]'s status changes.
///
/// It should not take a long time to return, or it will slow down the
/// replicator.
///
/// The callback receives the [Replicator]'s [status].
typedef ReplicatorChangeListener = void Function(ReplicatorStatus status);

/// Information about a [Document] that's been pushed or pulled.
class ReplicatedDocument {
  ReplicatedDocument(this.id, this.flags, this.error);

  /// The document ID
  final String id;

  /// Indicates whether the document was deleted or removed
  final Set<DocumentFlags> flags;

  /// If the code is nonzero, the document failed to replicate.
  final BaseException? error;
}

/// A callback that notifies you when [Document]s are replicated.
///
/// It should not take a long time to return, or it will slow down the
/// replicator.
///
/// [isPush] is `true` if the document(s) were pushed, `false` if pulled.
///
/// [documents] is a list with information about each document.
typedef ReplicatedDocumentListener = void Function(
  bool isPush,
  List<ReplicatedDocument> documents,
);

/// A replicator is a background task that synchronizes changes between a local
/// database and another database on a remote server (or on a peer device, or
/// even another local database.)
abstract class Replicator {
  Replicator._(this.config);

  final ReplicatorConfiguration config;

  /// Instructs this replicator to ignore existing checkpoints the next time it
  /// runs. This will cause it to scan through all the [Document]s on the remote
  /// database, which takes a lot longer, but it can resolve problems with
  /// missing documents if the client and server have gotten out of sync
  /// somehow.
  Future<void> resetCheckpoint();

  /// Starts this replicator, asynchronously.
  ///
  /// Does nothing if it's already started.
  Future<void> start();

  /// Stops a running replicator, asynchronously.
  ///
  /// Does nothing if it's not already started.
  ///
  /// The replicator will call your [ReplicatorChangeListener] with an activity
  /// level of [ReplicatorActivityLevel.stopped] after it stops. Until then,
  /// consider it still active.
  Future<void> stop();

  /// Informs this replicator whether it's considered possible to reach the
  /// remote host with the current network configuration.
  ///
  /// The default value is `true`. This only affects the [Replicator]'s behavior
  /// while it's in the Offline state:
  /// * Setting it to false will cancel any pending retry and prevent future
  ///   automatic retries.
  /// * Setting it back to true will initiate an immediate retry.
  Future<void> setHostReachable(bool reachable);

  /// Puts this replicator in or out of "suspended" state.
  ///
  /// The default is false.
  ///
  /// * Setting [suspended] to `true` causes the replicator to disconnect and
  ///   enter Offline state; it will not attempt to reconnect while it's
  ///   suspended.
  /// * Setting [suspended] ot `false` causes the replicator to attempt to
  ///   reconnect, _if_ it was connected when suspended, and is still in Offline
  ///   state.
  Future<void> setSuspended(bool suspended);

  /// Returns this [Replicator]'s current status.
  Future<ReplicatorStatus> status();

  /// Indicates which documents have local changes that have not yet been pushed
  /// to the server by this replicator.
  ///
  /// This is of course a snapshot, that will go out of date as the replicator
  /// makes progress and/or documents are saved locally.
  ///
  /// The result is, effectively, a set of document IDs: a dictionary whose keys
  /// are the IDs and values are `true`.
  ///
  /// If there are no pending documents, the dictionary is empty.
  /// On error, `null` is returned.
  ///
  /// This function can be called on a stopped or un-started replicator.
  ///
  /// Documents that would never be pushed by this replicator, due to its
  /// configuration's `pushFilter` or `docIDs`, are ignored.
  Future<Dict> pendingDocumentIDs();

  /// Indicates whether the document with the given ID has local changes that
  /// have not yet been pushed to the server by this replicator.
  ///
  /// This is equivalent to, but faster than, calling [pendingDocumentIDs] and
  /// checking whether the result contains [docID]. See that function's
  /// documentation for details.
  ///
  /// A `false` result means the document is not pending.
  Future<bool> isDocumentPending(String docID);

  /// Adds a [listener] that will be called when this [Replicator]'s status
  /// changes.
  Future<void> addChangeListener(ReplicatorChangeListener listener);

  /// Removes a change [listener] to stop it from being notified.
  Future<void> removeChangeListener(ReplicatorChangeListener listener);

  /// Adds a [listener] that will be called when [Document]s are replicated.
  Future<void> addDocumentListener(ReplicatedDocumentListener listener);

  /// Removes a document [listener] to stop it from being notified.
  Future<void> removeDocumentListener(ReplicatedDocumentListener listener);
}
