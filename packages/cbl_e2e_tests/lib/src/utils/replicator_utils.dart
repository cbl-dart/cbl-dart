import 'dart:async';

import 'package:cbl/cbl.dart';

import '../test_binding.dart';

final testSyncGatewayUrl = Uri.parse('ws://localhost:4984/db');

/// Delay to wait before stopping a [Replicator] to prevent it from crashing.
///
/// If a [Replicator] is stopped shortly after starting it is possible that
/// it makes a connection to the server after it was stopped, causing a crash.
/// This is a bug in Couchbase Lite.
Future<void> preReplicatorStopDelay() =>
    Future<void>.delayed(Duration(milliseconds: 500));

extension ReplicatorUtilsDatabaseExtension on Database {
  /// Creates a replicator which is configured with the test sync gateway
  /// endpoint.
  Replicator createTestReplicator({
    ReplicatorType? replicatorType,
    bool? continuous,
    List<String>? channels,
    List<String>? documentIds,
    ReplicationFilter? pushFilter,
    ReplicationFilter? pullFilter,
    ConflictResolverFunction? conflictResolver,
  }) {
    final replicator = Replicator(ReplicatorConfiguration(
      database: this,
      target: UrlEndpoint(testSyncGatewayUrl),
      replicatorType: replicatorType ?? ReplicatorType.pushAndPull,
      continuous: continuous ?? false,
      channels: channels,
      documentIds: documentIds,
      pushFilter: pushFilter,
      pullFilter: pullFilter,
      conflictResolver: conflictResolver != null
          ? ConflictResolver.from(conflictResolver)
          : null,
    ));

    /// Ensures that when the replicator is closed as part of closing the
    /// database it wont be stopped to quickly.
    addTearDown(preReplicatorStopDelay);

    return replicator;
  }
}

final isReplicatorStatus = isA<ReplicatorStatus>();

extension ReplicatorStatusMatcherExtension on TypeMatcher<ReplicatorStatus> {
  Matcher havingActivity(Object? activity) =>
      having((it) => it.activity, 'activity', activity);

  Matcher havingError(Object? error) =>
      having((it) => it.error, 'error', error);
}

final isErrorReplicatorStatus = isReplicatorStatus.havingError(isNotNull);

Matcher hasActivityLevel(
  ReplicatorActivityLevel activityLevel,
) =>
    isReplicatorStatus.having((it) => it.activity, 'activity', activityLevel);

extension ReplicatorUtilsExtension on Replicator {
  Stream<ReplicatorStatus> statusStartingWithCurrent() async* {
    yield status;
    yield* changes().map((change) => change.status);
  }

  /// Calls [fn] and waits until the replicator's status matches
  /// [statusMatcher].
  ///
  /// If [matchInitialStatus] is `true` the initial status of the replicator
  /// also has to match [statusMatcher].
  ///
  /// [validStatusMatcher] is a matcher which every status must match. The
  /// default matcher requires that the status does not have an error.
  Future<void> doAndWaitForStatus(
    Object statusMatcher,
    FutureOr<void> Function() fn, {
    Object? validStatusMatcher,
    bool matchInitialStatus = false,
  }) async {
    validStatusMatcher ??= isNot(isErrorReplicatorStatus);
    var isInitialStatus = true;

    await statusStartingWithCurrent().asyncMap((status) async {
      expect(status, validStatusMatcher);

      if (isInitialStatus) {
        isInitialStatus = false;

        if (matchInitialStatus) {
          expect(status, statusMatcher);
        }

        await fn();
        return false;
      }

      return _matches(status, statusMatcher);
    }).firstWhere((isMatch) => isMatch);
  }

  /// Drives the status of this replicator to match [statusMatcher].
  ///
  /// If the current status does not mach, this method calls [fn] and waits
  /// until the status matches [statusMatcher].
  ///
  /// [validStatusMatcher] is a matcher which every status must match. The
  /// default matcher requires that the status does not have an error.
  Future<void> driveToStatus(
    Object statusMatcher,
    FutureOr<void> Function() fn, {
    Object? validStatusMatcher,
  }) async {
    validStatusMatcher ??= isNot(isErrorReplicatorStatus);
    var calledDriveFn = false;

    await statusStartingWithCurrent().asyncMap((status) async {
      expect(status, validStatusMatcher);

      var isMatch = _matches(status, statusMatcher);
      if (!calledDriveFn && !isMatch) {
        calledDriveFn = true;
        await fn();
      }

      return isMatch;
    }).firstWhere((isMatch) => isMatch);
  }

  /// Calls [fn] once the status of this replicator matches [statusMatcher].
  ///
  /// [validStatusMatcher] is a matcher which every status must match. The
  /// default matcher requires that the status does not have an error.
  Future<void> whenStatusDo(
    Object statusMatcher,
    FutureOr<void> Function() fn, {
    Object? validStatusMatcher,
  }) async {
    validStatusMatcher ??= isNot(isErrorReplicatorStatus);

    await statusStartingWithCurrent().asyncMap((status) async {
      expect(status, validStatusMatcher);

      var isMatch = _matches(status, statusMatcher);
      if (isMatch) {
        await fn();
      }

      return isMatch;
    }).firstWhere((isMatch) => isMatch);
  }

  /// Starts a one shot replicator and completes when it has stopped.
  Future<void> replicateOneShot() {
    assert(!config.continuous);
    return doAndWaitForStatus(
      hasActivityLevel(ReplicatorActivityLevel.stopped),
      start,
      matchInitialStatus: true,
      validStatusMatcher: anything,
    );
  }
}

bool _matches(Object actual, Object expected) =>
    wrapMatcher(expected).matches(actual, <dynamic, dynamic>{});
