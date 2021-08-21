import 'dart:async';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/support/utils.dart';

import '../test_binding.dart';

final testSyncGatewayUrl = Uri.parse('ws://localhost:4984/db');

/// Delay to wait before stopping a [Replicator] to prevent it from crashing.
///
/// If a [Replicator] is stopped shortly after starting it is possible that
/// it makes a connection to the server after it was stopped, causing a crash.
/// This is a bug in Couchbase Lite.
Future<void> preReplicatorStopDelay() =>
    Future<void>.delayed(const Duration(milliseconds: 500));

extension ReplicatorUtilsDatabaseExtension on Database {
  /// Creates a replicator which is configured with the test sync gateway
  /// endpoint.
  FutureOr<Replicator> createTestReplicator({
    ReplicatorType? replicatorType,
    bool? continuous,
    List<String>? channels,
    List<String>? documentIds,
    ReplicationFilter? pushFilter,
    ReplicationFilter? pullFilter,
    ConflictResolverFunction? conflictResolver,
  }) =>
      Replicator.create(ReplicatorConfiguration(
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
      )).then((replicator) {
        addTearDown(() async {
          /// Ensures that when the replicator is closed as part of closing the
          /// database it wont be stopped to quickly.
          await preReplicatorStopDelay();
          return replicator.stop();
        });
        return replicator;
      });
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
  /// Returns a stream of the [status]se of this replicator by polling it.
  ///
  /// Polling can be more reliable when it is not possible to listen to
  /// [changes] before the replicator has been started.
  ///
  /// If the replicator has already been started it is difficult to obtain a
  /// stream of status changes which begins with the current status.
  ///
  /// If you get the current status and then start to listen for changes you
  /// might miss changes in between.
  ///
  /// If you start to listen for changes first and than get the current status
  /// you can receive status changes from before the current status and wont be
  /// able to put them and the current status into the correct order.
  Stream<ReplicatorStatus> pollStatus() async* {
    // ignore: literal_only_boolean_expressions
    while (true) {
      yield await status;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
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

    await pollStatus().asyncMap((status) async {
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

    await pollStatus().asyncMap((status) async {
      expect(status, validStatusMatcher);

      final isMatch = _matches(status, statusMatcher);
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

    await pollStatus().asyncMap((status) async {
      expect(status, validStatusMatcher);

      final isMatch = _matches(status, statusMatcher);
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
    wrapMatcher(expected).matches(actual, <Object?, Object?>{});
