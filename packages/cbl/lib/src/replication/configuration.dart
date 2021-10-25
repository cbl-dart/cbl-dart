import 'dart:async';
import 'dart:typed_data';

import '../database.dart';
import '../document.dart';
import '../support/utils.dart';
import 'authenticator.dart';
import 'conflict_resolver.dart';
import 'endpoint.dart';
import 'replicator.dart';

/// Direction of replication: push, pull, or both.
enum ReplicatorType {
  /// Bidirectional; both push and pull
  pushAndPull,

  /// Pushing changes to the target
  push,

  /// Pulling changes from the target
  pull,
}

/// Flags describing a replicated [Document].
enum DocumentFlag {
  /// The document has been deleted.
  deleted,

  /// The document was removed from all the Sync Gateway channels the user has
  /// access to.
  accessRemoved,
}

/// A function that decides whether a particular [Document] should be
/// pushed/pulled.
///
/// It should not take a long time to return, or it will slow down the
/// replicator.
///
/// The function receives the [document] in question and [flags] describing
/// the document.
///
/// Return `true` if the document should be replicated, `false` to skip it.
typedef ReplicationFilter = FutureOr<bool> Function(
  Document document,
  Set<DocumentFlag> flags,
);

/// Configuration for a [Replicator].
class ReplicatorConfiguration {
  /// Creates a configuration for a [Replicator].
  ReplicatorConfiguration({
    required this.database,
    required this.target,
    this.replicatorType = ReplicatorType.pushAndPull,
    this.continuous = false,
    this.authenticator,
    this.pinnedServerCertificate,
    this.headers,
    this.channels,
    this.documentIds,
    this.pushFilter,
    this.pullFilter,
    this.conflictResolver,
    this.enableAutoPurge = true,
    Duration? heartbeat,
    int? maxAttempts,
    Duration? maxAttemptWaitTime,
  }) {
    this
      ..heartbeat = heartbeat
      ..maxAttempts = maxAttempts
      ..maxAttemptWaitTime = maxAttemptWaitTime;
  }

  /// Creates a configuration for a [Replicator] from another [config] by coping
  /// it.
  ReplicatorConfiguration.from(ReplicatorConfiguration config)
      : database = config.database,
        target = config.target,
        replicatorType = config.replicatorType,
        continuous = config.continuous,
        authenticator = config.authenticator,
        pinnedServerCertificate = config.pinnedServerCertificate,
        headers = config.headers,
        channels = config.channels,
        documentIds = config.documentIds,
        pushFilter = config.pushFilter,
        pullFilter = config.pullFilter,
        conflictResolver = config.conflictResolver,
        enableAutoPurge = config.enableAutoPurge,
        _heartbeat = config.heartbeat,
        _maxAttempts = config.maxAttempts,
        _maxAttemptWaitTime = config.maxAttemptWaitTime;

  /// The local [Database] to replicate with the replication [target].
  final Database database;

  /// The replication target to replicate with.
  final Endpoint target;

  /// Replicator type indication the direction of the replicator.
  ReplicatorType replicatorType;

  /// The continuous flag indicating whether the replicator should stay active
  /// indefinitely to replicate changed documents.
  bool continuous;

  /// The [Authenticator] to authenticate with a remote target.
  Authenticator? authenticator;

  /// The remote target's SSL certificate.
  Uint8List? pinnedServerCertificate;

  /// Extra HTTP headers to send in all requests to the remote target.
  Map<String, String>? headers;

  /// A set of Sync Gateway channel names to pull from.
  ///
  /// Ignored for push replication. If unset, all accessible channels will be
  /// pulled.
  ///
  /// Note: channels that are not accessible to the user will be ignored by
  /// Sync Gateway.
  List<String>? channels;

  /// A set of document IDs to filter by.
  ///
  /// If given, only documents with these ids will be pushed and/or pulled.
  List<String>? documentIds;

  /// Filter for validating whether the [Document]s can be pushed to the remote
  /// endpoint.
  ///
  /// Only documents for which the function returns `true` are replicated.
  ReplicationFilter? pushFilter;

  /// Filter for validating whether the [Document]s can be pulled from the
  /// remote endpoint.
  ///
  /// Only documents for which the function returns `true` are replicated.
  ReplicationFilter? pullFilter;

  /// A custom conflict resolver.
  ///
  /// If this value is not set, or set to `null`, the default conflict resolver
  /// will be applied.
  ConflictResolver? conflictResolver;

  /// Whether to automatically purge a document when the user looses access to
  /// it, on the server.
  ///
  /// The default value is `true` which means that the document will be
  /// automatically purged by the pull replicator when the user loses access to
  /// the document.
  ///
  /// When the property is set to `false`, documents for which the user has
  /// lost access remain in the database.
  ///
  /// Regardless of value of this option, when the user looses access to a
  /// document, an access removed event will be sent to any document change
  /// streams that are active on the replicator.
  ///
  /// {@macro cbl.Replicator.documentReplications.listening}
  bool enableAutoPurge;

  /// The heartbeat interval.
  ///
  /// The interval when the [Replicator] sends the ping message to check whether
  /// the other peer is still alive.
  ///
  /// Setting this value to [Duration.zero] or a negative [Duration] will
  /// result in an [ArgumentError] being thrown.
  ///
  /// To use the default of 300 seconds, set this property to `null`.
  Duration? get heartbeat => _heartbeat;
  Duration? _heartbeat;

  set heartbeat(Duration? heartbeat) {
    if (heartbeat != null && heartbeat.inSeconds <= 0) {
      throw ArgumentError.value(
        heartbeat,
        'heartbeat',
        'must not be zero or negative',
      );
    }
    _heartbeat = heartbeat;
  }

  /// The maximum attempts to connect.
  ///
  /// The attempts will be reset when the replicator is able to connect and
  /// replicate with the remote server again.
  ///
  /// Setting the [maxAttempts] value to `null`, the default max attempts of 10
  /// times for single shot replicators and infinite times for continuous
  /// replicators will be applied.
  /// Setting the value to `1` with result in no retry attempts.
  ///
  /// Setting `0` a negative number will result in an [ArgumentError] being
  /// thrown.
  int? get maxAttempts => _maxAttempts;
  int? _maxAttempts;

  set maxAttempts(int? maxAttempts) {
    if (maxAttempts != null && maxAttempts <= 0) {
      throw ArgumentError.value(
        maxAttempts,
        'maxAttempts',
        'must not be zero or negative',
      );
    }
    _maxAttempts = maxAttempts;
  }

  /// Max wait time between attempts.
  ///
  /// Exponential backoff is used for calculating the wait time and cannot be
  /// customized.
  ///
  /// Setting this value to [Duration.zero] or a negative [Duration] will
  /// result in an [ArgumentError] being thrown.
  ///
  /// To use the default of 300 seconds, set this property to `null`.
  Duration? get maxAttemptWaitTime => _maxAttemptWaitTime;
  Duration? _maxAttemptWaitTime;

  set maxAttemptWaitTime(Duration? maxAttemptWaitTime) {
    if (maxAttemptWaitTime != null && maxAttemptWaitTime.inSeconds <= 0) {
      throw ArgumentError.value(
        maxAttemptWaitTime,
        'maxAttemptWaitTime',
        'must not be zero or negative',
      );
    }
    _maxAttemptWaitTime = maxAttemptWaitTime;
  }

  @override
  String toString() {
    final headers = this.headers?.let(_redactHeaders);

    return [
      'ReplicatorConfiguration(',
      [
        'database: $database',
        'target: $target',
        'replicatorType: ${describeEnum(replicatorType)}',
        if (continuous) 'CONTINUOUS',
        if (authenticator != null) 'authenticator: $authenticator',
        if (pinnedServerCertificate != null) 'PINNED-SERVER-CERTIFICATE',
        if (headers != null) 'headers: $headers',
        if (channels != null) 'channels: $channels',
        if (documentIds != null) 'documentIds: $documentIds',
        if (pushFilter != null) 'PUSH-FILTER',
        if (pushFilter != null) 'PULL-FILTER',
        if (conflictResolver != null) 'CUSTOM-CONFLICT-RESOLVER',
        if (!enableAutoPurge) 'DISABLE-AUTO-PURGE',
        if (heartbeat != null) 'heartbeat: ${_heartbeat!.inSeconds}s',
        if (maxAttempts != null) 'maxAttempts: $maxAttempts',
        if (maxAttemptWaitTime != null)
          'maxAttemptWaitTime: ${_maxAttemptWaitTime!.inSeconds}s',
      ].join(', '),
      ')'
    ].join();
  }
}

Map<String, String> _redactHeaders(Map<String, String> headers) {
  final redactedHeaders = ['authentication'];

  return {
    for (final entry in headers.entries)
      entry.key: redactedHeaders.contains(entry.key.toLowerCase())
          ? 'REDACTED'
          : entry.value
  };
}
