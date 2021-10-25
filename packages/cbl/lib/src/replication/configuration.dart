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
    int? maxRetries,
    Duration? maxRetryWaitTime,
  }) {
    this
      ..heartbeat = heartbeat ?? this.heartbeat
      ..maxRetries = maxRetries
      ..maxRetryWaitTime = maxRetryWaitTime ?? this.maxRetryWaitTime;
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
        _maxRetries = config.maxRetries,
        _maxRetryWaitTime = config.maxRetryWaitTime;

  static const _defaultContinuousMaxRetries = 0xFFFFFFFF - 1;
  static const _defaultSingleShotMaxRetries = 9;

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
  /// Setting the heartbeat to zero will result in an [ArgumentError] being
  /// thrown.
  Duration get heartbeat => _heartbeat;
  Duration _heartbeat = const Duration(seconds: 300);

  set heartbeat(Duration heartbeat) {
    if (heartbeat.inSeconds <= 0) {
      throw ArgumentError.value(
        heartbeat,
        'heartbeat',
        'must not be zero or negative',
      );
    }
    _heartbeat = heartbeat;
  }

  /// The maximum attempts to retry.
  ///
  /// The retry attempt will be reset when the replicator is able to connect and
  /// replicate with the remote server again.
  ///
  /// Without setting the [maxRetries] value, the default max retires of 9 times
  /// for single shot replicators and infinite times for continuous replicators
  /// will be applied and present to users.
  /// Setting the value to 0 with result in no retry attempts.
  ///
  /// Setting a negative number will result in an [ArgumentError] being thrown.
  int get maxRetries =>
      _maxRetries ??
      (continuous
          ? _defaultContinuousMaxRetries
          : _defaultSingleShotMaxRetries);
  int? _maxRetries;

  set maxRetries(int? maxRetries) {
    if (maxRetries != null && maxRetries < 0) {
      throw ArgumentError.value(
        maxRetries,
        'maxRetries',
        'must not be negative',
      );
    }
    _maxRetries = maxRetries;
  }

  /// Max wait time for the next retry.
  ///
  /// The exponential backoff for calculating the wait time will be used by
  /// default and cannot be customized.
  ///
  /// Setting the [maxRetryWaitTime] to zero or negative [Duration] will result
  /// in an [ArgumentError] being thrown.
  Duration get maxRetryWaitTime => _maxRetryWaitTime;
  Duration _maxRetryWaitTime = const Duration(seconds: 300);

  set maxRetryWaitTime(Duration maxRetryWaitTime) {
    if (maxRetryWaitTime.inSeconds <= 0) {
      throw ArgumentError.value(
        maxRetryWaitTime,
        'maxRetryWaitTime',
        'must not be zero or negative',
      );
    }
    _maxRetryWaitTime = maxRetryWaitTime;
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
        'heartbeat: ${_heartbeat.inSeconds}',
        'maxRetries: $maxRetries',
        'maxRetryWaitTime: ${_maxRetryWaitTime.inSeconds}',
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
