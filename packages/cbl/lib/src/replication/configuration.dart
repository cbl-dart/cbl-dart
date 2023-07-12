// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../database.dart';
import '../database/database_base.dart';
import '../document.dart';
import '../support/utils.dart';
import '../typed_data.dart';
import '../typed_data/adapter.dart';
import 'authenticator.dart';
import 'conflict.dart';
import 'conflict_resolver.dart';
import 'document_replication.dart';
import 'endpoint.dart';
import 'replicator.dart';

/// Direction of replication: push, pull, or both.
///
/// {@category Replication}
enum ReplicatorType {
  /// Bidirectional; both push and pull
  pushAndPull,

  /// Pushing changes to the target
  push,

  /// Pulling changes from the target
  pull,
}

/// Flags describing a replicated [Document].
///
/// {@category Replication}
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
/// {@template cbl.ReplicationFilter}
/// It should not take a long time to return, or it will slow down the
/// replicator.
///
/// The function receives the [document] in question and [flags] describing the
/// document.
///
/// Return `true` if the document should be replicated, `false` to skip it.
/// {@endtemplate}
///
/// {@category Replication}
typedef ReplicationFilter = FutureOr<bool> Function(
  Document document,
  Set<DocumentFlag> flags,
);

/// A function that decides whether a particular typed document should be
/// pushed/pulled.
///
/// {@macro cbl.ReplicationFilter}
///
/// {@category Replication}
/// {@category Typed Data}
@experimental
typedef TypedReplicationFilter = FutureOr<bool> Function(
  TypedDocumentObject document,
  Set<DocumentFlag> flags,
);

/// The replication configuration for a [Collection].
class CollectionConfiguration {
  /// Creates a replication configuration for a [Collection].
  CollectionConfiguration({
    this.channels,
    this.documentIds,
    this.pushFilter,
    this.pullFilter,
    this.conflictResolver,
  });

  /// Creates a replication configuration for a [Collection] from another
  /// [config] by coping it.
  CollectionConfiguration.from(CollectionConfiguration config)
      : channels = config.channels,
        documentIds = config.documentIds,
        pushFilter = config.pushFilter,
        pullFilter = config.pullFilter,
        conflictResolver = config.conflictResolver;

  /// A set of Sync Gateway channel names to pull from.
  ///
  /// Ignored for push replication. If unset, all accessible channels will be
  /// pulled.
  ///
  /// Note: Channels that are not accessible to the user will be ignored by Sync
  /// Gateway.
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

  @override
  String toString() => [
        'CollectionConfiguration(',
        [
          if (channels != null) 'channels: $channels',
          if (documentIds != null) 'documentIds: $documentIds',
          if (pushFilter != null) 'PUSH-FILTER',
          if (pullFilter != null) 'PULL-FILTER',
          if (conflictResolver != null) 'CUSTOM-CONFLICT-RESOLVER',
        ].join(', '),
        ')'
      ].join();
}

/// Configuration for a [Replicator].
///
/// {@category Replication}
class ReplicatorConfiguration {
  /// Creates a configuration for a [Replicator].
  ReplicatorConfiguration({
    @Deprecated(
      'Add a CollectionConfiguration for the default collection instead.',
    )
    this.database,
    required this.target,
    this.replicatorType = ReplicatorType.pushAndPull,
    this.continuous = false,
    this.authenticator,
    this.pinnedServerCertificate,
    this.trustedRootCertificates,
    this.headers,
    @Deprecated('Use CollectionConfiguration.channels instead.') this.channels,
    @Deprecated('Use CollectionConfiguration.documentIds instead.')
    this.documentIds,
    @Deprecated('Use CollectionConfiguration.pushFilter instead.')
    this.pushFilter,
    this.typedPushFilter,
    @Deprecated('Use CollectionConfiguration.pullFilter instead.')
    this.pullFilter,
    this.typedPullFilter,
    @Deprecated('Use CollectionConfiguration.conflictResolver instead.')
    this.conflictResolver,
    this.typedConflictResolver,
    this.enableAutoPurge = true,
    Duration? heartbeat,
    int? maxAttempts,
    Duration? maxAttemptWaitTime,
  }) : _collections = {} {
    this
      ..heartbeat = heartbeat
      ..maxAttempts = maxAttempts
      ..maxAttemptWaitTime = maxAttemptWaitTime;

    if (typedPushFilter != null ||
        typedPullFilter != null ||
        typedConflictResolver != null) {
      (database as DatabaseBase?)?.useWithTypedData();
    }
  }

  /// Creates a configuration for a [Replicator] from another [config] by coping
  /// it.
  ReplicatorConfiguration.from(ReplicatorConfiguration config)
      : _collections = {...config._collections},
        database = config.database,
        target = config.target,
        replicatorType = config.replicatorType,
        continuous = config.continuous,
        authenticator = config.authenticator,
        pinnedServerCertificate = config.pinnedServerCertificate,
        trustedRootCertificates = config.trustedRootCertificates,
        headers = config.headers,
        channels = config.channels,
        documentIds = config.documentIds,
        pushFilter = config.pushFilter,
        typedPushFilter = config.typedPushFilter,
        pullFilter = config.pullFilter,
        typedPullFilter = config.typedPullFilter,
        conflictResolver = config.conflictResolver,
        typedConflictResolver = config.typedConflictResolver,
        enableAutoPurge = config.enableAutoPurge,
        _heartbeat = config.heartbeat,
        _maxAttempts = config.maxAttempts,
        _maxAttemptWaitTime = config.maxAttemptWaitTime;

  final Map<Collection, CollectionConfiguration> _collections;

  /// The local [Database] to replicate with the replication [target].
  @Deprecated(
    'Add a CollectionConfiguration for the default collection instead.',
  )
  final Database? database;

  /// The replication target to replicate with.
  final Endpoint target;

  /// Replicator type indication the direction of the replicator.
  ReplicatorType replicatorType;

  /// The continuous flag indicating whether the replicator should stay active
  /// indefinitely to replicate changed documents.
  bool continuous;

  /// The [Authenticator] to authenticate with a remote target.
  Authenticator? authenticator;

  /// The remote target's SSL certificate (PEM or DER).
  Uint8List? pinnedServerCertificate;

  /// A set of trusted root certificates to use for verifying the SSL
  /// certificate of the remote target (PEM).
  Uint8List? trustedRootCertificates;

  /// Extra HTTP headers to send in all requests to the remote target.
  Map<String, String>? headers;

  /// A set of Sync Gateway channel names to pull from.
  ///
  /// Ignored for push replication. If unset, all accessible channels will be
  /// pulled.
  ///
  /// Note: channels that are not accessible to the user will be ignored by Sync
  /// Gateway.
  @Deprecated('Use CollectionConfiguration.channels instead.')
  List<String>? channels;

  /// A set of document IDs to filter by.
  ///
  /// If given, only documents with these ids will be pushed and/or pulled.
  @Deprecated('Use CollectionConfiguration.documentIds instead.')
  List<String>? documentIds;

  /// Filter for validating whether the [Document]s can be pushed to the remote
  /// endpoint.
  ///
  /// Only documents for which the function returns `true` are replicated.
  @Deprecated('Use CollectionConfiguration.pushFilter instead.')
  ReplicationFilter? pushFilter;

  /// Filter for validating whether the documents can be pushed to the remote
  /// endpoint, which receives typed document instances.
  ///
  /// Only documents for which the function returns `true` are replicated.
  @experimental
  TypedReplicationFilter? typedPushFilter;

  /// Filter for validating whether the [Document]s can be pulled from the
  /// remote endpoint.
  ///
  /// Only documents for which the function returns `true` are replicated.
  @Deprecated('Use CollectionConfiguration.pullFilter instead.')
  ReplicationFilter? pullFilter;

  /// Filter for validating whether the documents can be pulled from the remote
  /// endpoint, which receives typed document instances.
  ///
  /// Only documents for which the function returns `true` are replicated.
  @experimental
  TypedReplicationFilter? typedPullFilter;

  /// A custom conflict resolver.
  ///
  /// If this value is not set, or set to `null`, the default conflict resolver
  /// will be applied.
  @Deprecated('Use CollectionConfiguration.conflictResolver instead.')
  ConflictResolver? conflictResolver;

  /// A custom conflict resolver, which receives typed document instances.
  ///
  /// If this value is not set, or set to `null`, the default conflict resolver
  /// will be applied.
  @experimental
  TypedConflictResolver? typedConflictResolver;

  /// Whether to automatically purge a document when the user looses access to
  /// it, on the server.
  ///
  /// The default value is `true` which means that the document will be
  /// automatically purged by the pull replicator when the user loses access to
  /// the document.
  ///
  /// When the property is set to `false`, documents for which the user has lost
  /// access remain in the database.
  ///
  /// Regardless of value of this option, when the user looses access to a
  /// document, an access removed event will be sent to any document change
  /// streams that are active on the replicator.
  ///
  /// {@macro cbl.Replicator.addDocumentReplicationListener.listening}
  ///
  /// See also:
  ///
  /// - [Replicator.addDocumentReplicationListener] for listening to
  ///   [DocumentReplication]s performed by a [Replicator].
  bool enableAutoPurge;

  /// The heartbeat interval.
  ///
  /// The interval when the [Replicator] sends the ping message to check whether
  /// the other peer is still alive.
  ///
  /// Setting this value to [Duration.zero] or a negative [Duration] will result
  /// in an [RangeError] being thrown.
  ///
  /// To use the default of 300 seconds, set this property to `null`.
  Duration? get heartbeat => _heartbeat;
  Duration? _heartbeat;

  set heartbeat(Duration? heartbeat) {
    if (heartbeat != null && heartbeat.inSeconds <= 0) {
      throw RangeError.range(
        heartbeat.inSeconds,
        1,
        null,
        'heartbeat.inSeconds',
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
  /// replicators will be applied. Setting the value to `1` with result in no
  /// retry attempts.
  ///
  /// Setting `0` a negative number will result in an [RangeError] being thrown.
  int? get maxAttempts => _maxAttempts;
  int? _maxAttempts;

  set maxAttempts(int? maxAttempts) {
    if (maxAttempts != null && maxAttempts <= 0) {
      throw RangeError.range(maxAttempts, 1, null, 'maxAttempts');
    }
    _maxAttempts = maxAttempts;
  }

  /// Max wait time between attempts.
  ///
  /// Exponential backoff is used for calculating the wait time and cannot be
  /// customized.
  ///
  /// Setting this value to [Duration.zero] or a negative [Duration] will result
  /// in an [RangeError] being thrown.
  ///
  /// To use the default of 300 seconds, set this property to `null`.
  Duration? get maxAttemptWaitTime => _maxAttemptWaitTime;
  Duration? _maxAttemptWaitTime;

  set maxAttemptWaitTime(Duration? maxAttemptWaitTime) {
    if (maxAttemptWaitTime != null && maxAttemptWaitTime.inSeconds <= 0) {
      throw RangeError.range(
        maxAttemptWaitTime.inSeconds,
        1,
        null,
        'maxAttemptWaitTime.inSeconds',
      );
    }
    _maxAttemptWaitTime = maxAttemptWaitTime;
  }

  /// Configures a [Collection] for replication.
  ///
  /// If no [CollectionConfiguration] is given, the default configuration will
  /// be used.
  ///
  /// If the collection has already been configured for replication, it's
  /// configuration will be overwritten.
  void addCollection(
    Collection collection, [
    CollectionConfiguration? config,
  ]) {
    if (database != null) {
      throw StateError(
        'Cannot add a collection to a replicator configuration that uses the '
        'deprecated database property.',
      );
    }
    _collections[collection] =
        config?.let(CollectionConfiguration.from) ?? CollectionConfiguration();
  }

  /// Configures multiple [Collection]s for replication.
  ///
  /// All collections will use the same [config].
  ///
  /// If no [CollectionConfiguration] is given, the default configuration will
  /// be used.
  ///
  /// If one of the collections has already been configured for replication,
  /// it's configuration will be overwritten.
  void addCollections(
    Iterable<Collection> collections, [
    CollectionConfiguration? config,
  ]) {
    for (final collection in collections) {
      addCollection(collection, config);
    }
  }

  /// Removes the [CollectionConfiguration] for a [Collection] from this
  /// configuration.
  ///
  /// If the collection has not been configured for replication, this method is
  /// a no-op.
  void removeCollection(Collection collection) {
    _collections.remove(collection);
  }

  /// Returns the [CollectionConfiguration] for a [Collection] in this
  /// configuration.
  ///
  /// Returns `null` if the collection has not been configured for replication.
  CollectionConfiguration? collectionConfiguration(Collection collection) =>
      _collections[collection]?.let(CollectionConfiguration.from);

  @override
  String toString() {
    final headers = this.headers?.let(_redactHeaders);
    final collections = _collections.map((collection, config) =>
        MapEntry((collection as CollectionBase).fullName, config));

    return [
      'ReplicatorConfiguration(',
      [
        'database: $database',
        'target: $target',
        'replicatorType: ${replicatorType.name}',
        if (continuous) 'CONTINUOUS',
        if (authenticator != null) 'authenticator: $authenticator',
        if (pinnedServerCertificate != null) 'PINNED-SERVER-CERTIFICATE',
        if (trustedRootCertificates != null) 'TRUSTED-ROOT-CERTIFICATES',
        if (headers != null) 'headers: $headers',
        if (_collections.isNotEmpty) 'collections: $collections',
        if (channels != null) 'channels: $channels',
        if (documentIds != null) 'documentIds: $documentIds',
        if (pushFilter != null) 'PUSH-FILTER',
        if (typedPushFilter != null) 'TYPED-PUSH-FILTER',
        if (pullFilter != null) 'PULL-FILTER',
        if (typedPullFilter != null) 'TYPED-PULL-FILTER',
        if (conflictResolver != null) 'CUSTOM-CONFLICT-RESOLVER',
        if (typedConflictResolver != null) 'TYPED-CUSTOM-CONFLICT-RESOLVER',
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

extension InternalReplicatorConfiguration on ReplicatorConfiguration {
  ReplicationFilter? get combinedPushFilter => combineReplicationFilters(
        pushFilter,
        typedPushFilter,
        (database as DatabaseBase?)?.typedDataAdapter,
      );

  ReplicationFilter? get combinedPullFilter => combineReplicationFilters(
        pullFilter,
        typedPullFilter,
        (database as DatabaseBase?)?.typedDataAdapter,
      );

  ConflictResolver? get combinedConflictResolver => combineConflictResolvers(
        conflictResolver,
        typedConflictResolver,
        (database as DatabaseBase?)?.typedDataAdapter,
      );

  CollectionConfiguration get legacyCollectionConfiguration =>
      CollectionConfiguration(
        channels: channels,
        documentIds: documentIds,
        pushFilter: combinedPushFilter,
        pullFilter: combinedPullFilter,
        conflictResolver: combinedConflictResolver,
      );

  Map<Collection, CollectionConfiguration> get collections => _collections;

  void validate() {
    if (database == null && collections.isEmpty) {
      throw ArgumentError.value(
        this,
        'config',
        'A ReplicatorConfiguration must have a database or at least one '
            'CollectionConfiguration.',
      );
    }
  }
}

ReplicationFilter? combineReplicationFilters(
  ReplicationFilter? filter,
  TypedReplicationFilter? typedFilter,
  TypedDataAdapter? adapter,
) {
  if (typedFilter == null) {
    return filter;
  }

  final factory = adapter!
      .dynamicDocumentFactoryForType(allowUnmatchedDocument: filter != null);

  return (document, flags) {
    final typedDocument = factory(document);
    if (typedDocument != null) {
      return typedFilter(typedDocument, flags);
    }

    // There is no typed data type that can be resolved for this document, so
    // we fallback to the untyped filter. We can assert that `filter` is not
    // null here because we created the factory with `allowUnmatchedDocument`
    // based on the presence of `filter` and if `filter` is null the
    // factory throws an exception instead of returning null.
    return filter!(document, flags);
  };
}

ConflictResolver? combineConflictResolvers(
  ConflictResolver? conflictResolver,
  TypedConflictResolver? typedConflictResolver,
  TypedDataAdapter? adapter,
) {
  if (typedConflictResolver == null) {
    return conflictResolver;
  }

  final factory = adapter!.dynamicDocumentFactoryForType(
    allowUnmatchedDocument: conflictResolver != null,
  );

  return ConflictResolver.from((conflict) {
    final localTypedDocument = conflict.localDocument?.let(factory);
    final remoteTypedDocument = conflict.remoteDocument?.let(factory);
    if (_equalNullability(conflict.localDocument, localTypedDocument) &&
        _equalNullability(conflict.remoteDocument, remoteTypedDocument)) {
      return typedConflictResolver
          .resolve(TypedConflictImpl(
            conflict.documentId,
            localTypedDocument,
            remoteTypedDocument,
          ))
          .then((result) => result?.internal as Document?);
    }

    // There is no typed data type that can be resolved for at least one of the
    // documents, so we fallback to the untyped resolver. We can assert that
    // `conflictResolver` is not null here because we created the factory with
    // `allowUnmatchedDocument` based on the presence of `conflictResolver` and
    // if `conflictResolver` is null the factory throws an exception instead of
    // returning null.
    return conflictResolver!.resolve(conflict);
  });
}

bool _equalNullability(Object? a, Object? b) =>
    a == null ? b == null : b != null;
