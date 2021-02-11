import 'dart:ffi';
import 'dart:typed_data';

import 'package:collection/collection.dart';

import 'bindings/bindings.dart';
import 'database.dart';
import 'document.dart';
import 'errors.dart';
import 'ffi_utils.dart';
import 'fleece.dart';
import 'native_callbacks.dart';
import 'utils.dart';
import 'worker/handlers/replicator.dart';
import 'worker/worker.dart';

export 'bindings/bindings.dart'
    show ReplicatorType, ProxyType, ReplicatorActivityLevel, DocumentFlags;

// region Internal API

Future<Replicator> createReplicator(
  Worker worker,
  Pointer<CBLDatabase> db,
  ReplicatorConfiguration config,
) =>
    runArena(() async {
      final cblConfig = config.toCBLReplicatorConfigurationScoped(db);

      final address =
          await worker.makeRequest<int>(NewReplicator(cblConfig.address));

      return Replicator._(address.toPointer.cast(), worker);
    });

// endregion

late final _bindings = CBLBindings.instance.replicator;

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UrlEndpoint &&
          other.runtimeType == other.runtimeType &&
          url == other.url;

  @override
  int get hashCode => super.hashCode ^ url.hashCode;

  @override
  String toString() => 'UrlEndpoint(url: $url)';
}

/// An endpoint representing another local database. (Enterprise Edition only.)
class LocalDbEndpoint extends Endpoint {
  LocalDbEndpoint(this.database);

  final Database database;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalDbEndpoint &&
          other.runtimeType == other.runtimeType &&
          database == other.database;

  @override
  int get hashCode => super.hashCode ^ database.hashCode;

  @override
  String toString() => 'LocalDbEndpoint(database: $database)';
}

/// The authentication credentials for a remote server.
abstract class Authenticator {}

/// An authenticator for HTTP Basic (username/password) auth.
class BasicAuthenticator extends Authenticator {
  BasicAuthenticator({required this.username, required this.password});

  final String username;

  final String password;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BasicAuthenticator &&
          other.runtimeType == other.runtimeType &&
          username == other.password &&
          password == other.password;

  @override
  int get hashCode => super.hashCode ^ username.hashCode ^ password.hashCode;

  @override
  String toString() =>
      'BasicAuthenticator(username: $username, password: ${redact(password)})';
}

/// An authenticator using a Couchbase Sync Gateway login session identifier,
/// and optionally a cookie name (pass `null` for the default.)
class SessionAuthenticator extends Authenticator {
  SessionAuthenticator({required this.sessionID, required this.cookieName});

  final String sessionID;

  final String cookieName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionAuthenticator &&
          other.runtimeType == other.runtimeType &&
          sessionID == other.sessionID &&
          cookieName == other.cookieName;

  @override
  int get hashCode => super.hashCode ^ sessionID.hashCode ^ cookieName.hashCode;

  @override
  String toString() => 'SessionAuthenticator(sessionID: ${redact(sessionID)}, '
      'cookieName: $cookieName)';
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
typedef ConflictResolver = Document? Function(
  String documentId,
  Document? local,
  Document? remote,
);

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProxySettings &&
          other.runtimeType == other.runtimeType &&
          type == other.type &&
          hostname == other.hostname &&
          port == other.port &&
          username == other.username &&
          password == other.password;

  @override
  int get hashCode =>
      super.hashCode ^
      type.hashCode ^
      hostname.hashCode ^
      port.hashCode ^
      username.hashCode ^
      password.hashCode;

  @override
  String toString() => 'ProxySettings('
      'type: $type, '
      'hostname: $hostname, '
      'port: $port, '
      'username: $username, '
      'password: ${redact(password)}'
      ')';
}

extension on ProxySettings {
  Pointer<CBLProxySettings> toCBLProxySettingScoped() {
    final settings = scoped(malloc<CBLProxySettings>());

    settings.ref.type = type.toInt;
    settings.ref.hostname = hostname.asUtf8Scoped;
    settings.ref.port = port;
    settings.ref.username = (username?.asUtf8Scoped).orNullptr;
    settings.ref.password = password.asUtf8Scoped;

    return settings;
  }
}

/// The configuration of a replicator.
class ReplicatorConfiguration {
  ReplicatorConfiguration({
    required this.endpoint,
    required this.replicatorType,
    this.continuous = false,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReplicatorConfiguration &&
          other.runtimeType == other.runtimeType &&
          endpoint == other.endpoint &&
          replicatorType == other.replicatorType &&
          continuous == other.continuous &&
          authenticator == other.authenticator &&
          proxy == other.proxy &&
          headers == other.headers &&
          pinnedServerCertificate == other.pinnedServerCertificate &&
          trustedRootCertificates == other.trustedRootCertificates &&
          channels == other.channels &&
          documentIDs == other.documentIDs &&
          pushFilter == other.pushFilter &&
          pullFilter == other.pullFilter &&
          conflictResolver == other.conflictResolver;

  @override
  int get hashCode =>
      super.hashCode ^
      endpoint.hashCode ^
      replicatorType.hashCode ^
      continuous.hashCode ^
      authenticator.hashCode ^
      proxy.hashCode ^
      headers.hashCode ^
      pinnedServerCertificate.hashCode ^
      trustedRootCertificates.hashCode ^
      channels.hashCode ^
      documentIDs.hashCode ^
      pullFilter.hashCode ^
      pullFilter.hashCode ^
      conflictResolver.hashCode;

  @override
  String toString() => 'ReplicatorConfiguration('
      'endpoint: $endpoint, '
      'replicatorType: $replicatorType, '
      'continuous: $continuous, '
      'authenticator: $authenticator, '
      'proxy: $proxy, '
      'headers: $headers, '
      'pinnedServerCertificate: $pinnedServerCertificate, '
      'trustedRootCertificate: $trustedRootCertificates, '
      'channels: $channels, '
      'documentIDs: $documentIDs, '
      'pushFilter: $pullFilter, '
      'pullFilter: $pullFilter, '
      'conflictResolver: $conflictResolver'
      ')';
}

extension on ReplicatorConfiguration {
  Pointer<CBLDartReplicatorConfiguration> toCBLReplicatorConfigurationScoped(
    Pointer<CBLDatabase> db,
  ) {
    final config = scoped(malloc<CBLDartReplicatorConfiguration>());

    // database
    config.ref.database = db;

    // endpoint
    Pointer<CBLEndpoint> cblEndpoint;
    final endpoint = this.endpoint;
    if (endpoint is UrlEndpoint) {
      cblEndpoint =
          _bindings.endpointNewWithUrl(endpoint.url.toString().asUtf8Scoped);
    } else if (endpoint is LocalDbEndpoint) {
      assert(
        _bindings.endpointNewWithLocalDB != null,
        'LocalDbEndpoint is an Enterprise Edition feature',
      );
      cblEndpoint =
          _bindings.endpointNewWithLocalDB!(endpoint.database.pointer);
    } else {
      throw UnimplementedError('Endpoint type is not implemented: $endpoint');
    }

    registerFinalzier(() => _bindings.endpointFree(cblEndpoint));
    config.ref.endpoint = cblEndpoint;

    // replicatorType
    config.ref.replicatorType = replicatorType.toInt;

    // continuous
    config.ref.continuous = continuous.toInt;

    // authenticator
    final authenticator = this.authenticator;
    if (authenticator != null) {
      Pointer<CBLAuthenticator> cblAuthenticator;

      if (authenticator is BasicAuthenticator) {
        cblAuthenticator = _bindings.authNewBasic(
          authenticator.username.toString().asUtf8Scoped,
          authenticator.password.toString().asUtf8Scoped,
        );
      } else if (authenticator is SessionAuthenticator) {
        cblAuthenticator = _bindings.authNewSession(
          authenticator.sessionID.asUtf8Scoped,
          authenticator.cookieName.asUtf8Scoped,
        );
      } else {
        throw UnimplementedError(
          'Authenticator type is not implemented: $authenticator',
        );
      }

      registerFinalzier(() => _bindings.authFree(cblAuthenticator));
      config.ref.authenticator = cblAuthenticator;
    } else {
      config.ref.authenticator = nullptr;
    }

    // proxy
    final proxy = this.proxy;
    if (proxy != null) {
      config.ref.proxy = proxy.toCBLProxySettingScoped();
    } else {
      config.ref.proxy = nullptr;
    }

    // headers
    final headers = this.headers;
    if (headers != null) {
      final dict = MutableDict(headers);
      config.ref.headers = dict.ref.cast();
      // We need to ensure dict is not garbage collected until the current
      // Arena is finalized.
      registerFinalzier(() => dict.type);
    } else {
      config.ref.headers = nullptr;
    }

    // pinnedServerCertificate
    config.ref.pinnedServerCertificate =
        (pinnedServerCertificate?.toFLSliceScoped()).orNullptr;

    // trustedRootCertificates
    config.ref.trustedRootCertificates =
        (trustedRootCertificates?.toFLSliceScoped()).orNullptr;

    // channels
    final channels = this.channels;
    if (channels != null) {
      final array = MutableArray(channels);
      config.ref.channels = array.ref.cast();
      // We need to ensure array is not garbage collected until the current
      // Arena is finalized.
      registerFinalzier(() => array.type);
    } else {
      config.ref.channels = nullptr;
    }

    // documentIDs
    final documentIDs = this.documentIDs;
    if (documentIDs != null) {
      final array = MutableArray(documentIDs);
      config.ref.documentIDs = array.ref.cast();
      // We need to ensure array is not garbage collected until the current
      // Arena is finalized.
      registerFinalzier(() => array.type);
    } else {
      config.ref.documentIDs = nullptr;
    }

    int registerReplicationFilter(ReplicationFilter filter) =>
        NativeCallbacks.instance.registerCallback<ReplicationFilter>(
          filter,
          (filter, arguments, result) {
            final docAddress = arguments[0] as int;
            final doc =
                createDocument(pointer: docAddress.toPointer, retain: true);
            final isDeleted = arguments[1] as bool;

            var decision = false;
            try {
              decision = filter(doc, isDeleted);
            } finally {
              result!(decision);
            }
          },
        );

    // pushFilter
    final pushFilter = this.pushFilter;
    if (pushFilter != null) {
      config.ref.pushFilterId = registerReplicationFilter(pushFilter);
    } else {
      config.ref.pushFilterId = 0;
    }

    // pullFilter
    final pullFilter = this.pullFilter;
    if (pullFilter != null) {
      config.ref.pullFilterId = registerReplicationFilter(pullFilter);
    } else {
      config.ref.pullFilterId = 0;
    }

    int registerConflictResolver(ConflictResolver filter) =>
        NativeCallbacks.instance.registerCallback<ConflictResolver>(
          filter,
          (filter, arguments, result) {
            final docId = arguments[0] as String;
            final localAddress = arguments[1] as int?;
            final local = localAddress?.let(
                (it) => createDocument(pointer: it.toPointer, retain: true));
            final remoteAddress = arguments[2] as int?;
            final remote = remoteAddress?.let(
                (it) => createDocument(pointer: it.toPointer, retain: true));

            var decision = local ?? remote;
            try {
              decision = filter(docId, local, remote);
            } finally {
              result!(decision);
            }
          },
        );

    // conflictResolver
    final conflictResolver = this.conflictResolver;
    if (conflictResolver != null) {
      config.ref.conflictResolver = registerConflictResolver(conflictResolver);
    } else {
      config.ref.conflictResolver = 0;
    }

    return config;
  }
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReplicatorProgress &&
          other.runtimeType == other.runtimeType &&
          fractionComplete == other.fractionComplete &&
          documentCount == other.documentCount;

  @override
  int get hashCode =>
      super.hashCode ^ fractionComplete.hashCode ^ documentCount.hashCode;

  @override
  String toString() => 'ReplicatorConfiguration('
      'fractionComplete: $fractionComplete, '
      'documentCount: $documentCount'
      ')';
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReplicatorStatus &&
          other.runtimeType == other.runtimeType &&
          activity == other.activity &&
          progress == other.progress &&
          error == other.error;

  @override
  int get hashCode =>
      super.hashCode ^ activity.hashCode ^ progress.hashCode ^ error.hashCode;

  @override
  String toString() => 'ReplicatorStatus('
      'activity: $activity, '
      'progress: $progress, '
      'error: $error'
      ')';
}

extension CBLReplicatorStatusExt on CBLReplicatorStatus {
  ReplicatorStatus toReplicatorStatus() => runArena(() {
        final error = scoped(this.error.copyToPointer());
        return ReplicatorStatus(
          activity.toReplicatorActivityLevel,
          ReplicatorProgress(
            progress.fractionCompleted,
            progress.documentCount,
          ),
          error.isOk ? null : exceptionFromCBLError(error: error),
        );
      });
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReplicatedDocument &&
          other.runtimeType == other.runtimeType &&
          id == other.id &&
          const DeepCollectionEquality().equals(flags, other.flags) &&
          error == other.error;

  @override
  int get hashCode =>
      super.hashCode ^
      id.hashCode ^
      const DeepCollectionEquality().hash(flags) ^
      error.hashCode;

  @override
  String toString() => 'ReplicatedDocument('
      'id: $id, '
      'flags: $flags, '
      'error: $error'
      ')';
}

extension on CBLDartReplicatedDocument {
  ReplicatedDocument toReplicatedDocument() => runArena(() {
        final error = scoped(this.error.copyToPointer());

        return ReplicatedDocument(
          ID.asString,
          DocumentFlags.parseCFlags(flags),
          error.isOk ? null : exceptionFromCBLError(error: error),
        );
      });
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
class Replicator {
  Replicator._(this._pointer, this._worker) {
    _bindings.bindToDartObject(this, _pointer.cast());
  }

  final Pointer<CBLReplicator> _pointer;

  final Worker _worker;

  /// Instructs this replicator to ignore existing checkpoints the next time it
  /// runs.
  ///
  /// This will cause it to scan through all the [Document]s on the remote
  /// database, which takes a lot longer, but it can resolve problems with
  /// missing documents if the client and server have gotten out of sync
  /// somehow.
  Future<void> resetCheckpoint() =>
      _worker.makeRequest<void>(ResetReplicatorCheckpoint(_pointer.address));

  /// Starts this replicator, asynchronously.
  ///
  /// Does nothing if it's already started.
  Future<void> start() =>
      _worker.makeRequest<void>(StartReplicator(_pointer.address));

  /// Stops a running replicator, asynchronously.
  ///
  /// Does nothing if it's not already started.
  ///
  /// The replicator will call your [ReplicatorChangeListener] with an activity
  /// level of [ReplicatorActivityLevel.stopped] after it stops. Until then,
  /// consider it still active.
  Future<void> stop() =>
      _worker.makeRequest<void>(StopReplicator(_pointer.address));

  /// Informs this replicator whether it's considered possible to reach the
  /// remote host with the current network configuration.
  ///
  /// The default value is `true`. This only affects the [Replicator]'s behavior
  /// while it's in the Offline state:
  /// * Setting it to false will cancel any pending retry and prevent future
  ///   automatic retries.
  /// * Setting it back to true will initiate an immediate retry.
  Future<void> setHostReachable(bool reachable) =>
      _worker.makeRequest<void>(SetReplicatorHostReachable(
        _pointer.address,
        reachable,
      ));

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
  Future<void> setSuspended(bool suspended) =>
      _worker.makeRequest<void>(SetReplicatorSuspended(
        _pointer.address,
        suspended,
      ));

  /// Returns this [Replicator]'s current status.
  Future<ReplicatorStatus> status() => _worker
      .makeRequest<ReplicatorStatus>(GetReplicatorStatus(_pointer.address));

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
  Future<Dict> pendingDocumentIDs() => _worker
      .makeRequest<int>(GetReplicatorPendingDocumentIDs(_pointer.address))
      .then((address) => Dict.fromPointer(
            address.toPointer,
            bindToDoc: false,
            bindToValue: true,
          ));

  /// Indicates whether the document with the given ID has local changes that
  /// have not yet been pushed to the server by this replicator.
  ///
  /// This is equivalent to, but faster than, calling [pendingDocumentIDs] and
  /// checking whether the result contains [docID]. See that function's
  /// documentation for details.
  ///
  /// A `false` result means the document is not pending.
  Future<bool> isDocumentPending(String docID) =>
      _worker.makeRequest<bool>(GetReplicatorIsDocumentPening(
        _pointer.address,
        docID,
      ));

  /// Adds a [listener] that will be called when this [Replicator]'s status
  /// changes.
  Future<void> addChangeListener(ReplicatorChangeListener listener) {
    final listenerId =
        NativeCallbacks.instance.registerCallback<ReplicatorChangeListener>(
      listener,
      (listener, arguments, result) {
        final statusAddress = arguments[0] as int;
        final status = statusAddress.toPointer
            .cast<CBLReplicatorStatus>()
            .ref
            .toReplicatorStatus();

        // At this point we have copied the status and don't need to block
        // the replicator any more.
        result!(null);

        listener(status);
      },
    );

    return _worker
        .makeRequest(AddReplicatorChangeListener(_pointer.address, listenerId));
  }

  /// Removes a change [listener] to stop it from being notified.
  Future<void> removeChangeListener(ReplicatorChangeListener listener) async =>
      NativeCallbacks.instance.unregisterCallback(listener);

  /// Adds a [listener] that will be called when [Document]s are replicated.
  Future<void> addDocumentListener(ReplicatedDocumentListener listener) {
    final listenerId =
        NativeCallbacks.instance.registerCallback<ReplicatedDocumentListener>(
      listener,
      (listener, arguments, result) {
        final isPush = arguments[0] as bool;
        final numDocuments = arguments[1] as int;
        final documentsAddress = arguments[2] as int;
        final documentsPointer =
            Pointer<CBLDartReplicatedDocument>.fromAddress(documentsAddress);
        final documents = List.generate(
          numDocuments,
          (index) => documentsPointer.elementAt(index),
        ).map((it) => it.ref.toReplicatedDocument()).toList();

        // At this point we have copied the documents and don't need to block
        // the replicator any more.
        result!(null);

        listener(isPush, documents);
      },
    );

    return _worker.makeRequest(AddReplicatorDocumentListener(
      _pointer.address,
      listenerId,
    ));
  }

  /// Removes a document [listener] to stop it from being notified.
  Future<void> removeDocumentListener(
          ReplicatedDocumentListener listener) async =>
      NativeCallbacks.instance.unregisterCallback(listener);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Replicator &&
          other.runtimeType == other.runtimeType &&
          _pointer == other._pointer;

  @override
  int get hashCode => super.hashCode ^ _pointer.hashCode;

  @override
  String toString() => 'Replicator()';
}
