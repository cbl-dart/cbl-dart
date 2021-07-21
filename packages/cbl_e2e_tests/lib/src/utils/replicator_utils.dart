import 'dart:async';

import 'package:cbl/cbl.dart';

import '../test_binding.dart';

final testSyncGatewayUrl = Uri.parse('ws://localhost:4984/db');

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

    addTearDown(() => replicator.whenStatusDo(
          isNot(anyOf(
            hasActivityLevel(ReplicatorActivityLevel.connecting),
            hasActivityLevel(ReplicatorActivityLevel.busy),
          )),
          replicator.stop,
        ));

    return replicator;
  }
}

final isReplicatorStatus = isA<ReplicatorStatus>();

final isErrorReplicatorStatus =
    isReplicatorStatus.having((it) => it.error, 'error', isNotNull);

Matcher hasActivityLevel(
  ReplicatorActivityLevel activityLevel,
) =>
    isReplicatorStatus.having((it) => it.activity, 'activity', activityLevel);

extension ReplicatorUtilsExtension on Replicator {
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

    await changes(startWithCurrentStatus: true)
        .map((change) => change.status)
        .asyncMap((status) async {
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

    await changes(startWithCurrentStatus: true)
        .map((change) => change.status)
        .asyncMap((status) async {
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

    await changes(startWithCurrentStatus: true)
        .map((change) => change.status)
        .asyncMap((status) async {
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
    );
  }
}

bool _matches(Object actual, Object expected) =>
    wrapMatcher(expected).matches(actual, <dynamic, dynamic>{});
