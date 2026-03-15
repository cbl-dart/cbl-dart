import 'dart:async';
import 'dart:convert';

import 'package:cbl/cbl.dart' hide TypeMatcher;
import 'package:http/http.dart';

import '../test_binding.dart';

const syncGatewayHost = 'localhost';
const syncGatewayPublicPort = 4984;
const syncGatewayAdminPort = 4985;
const syncGatewayDatabase = 'db';
final syncGatewayReplicationUrl = Uri(
  scheme: 'ws',
  host: syncGatewayHost,
  port: syncGatewayPublicPort,
  path: syncGatewayDatabase,
);
final syncGatewayAdminApiUrl = Uri(
  scheme: 'http',
  host: syncGatewayHost,
  port: syncGatewayAdminPort,
);
final janeAuthenticator = BasicAuthenticator(
  username: 'Jane',
  password: 'Jane',
);
final aliceAuthenticator = BasicAuthenticator(
  username: 'Alice',
  password: 'Alice',
);

Future<String> syncGatewayRequest(
  Uri url, {
  String method = 'GET',
  Map<String, String>? headers,
  String? body,
  bool admin = false,
}) {
  final baseUrl = Uri(
    scheme: 'http',
    host: syncGatewayHost,
    port: admin ? syncGatewayAdminPort : syncGatewayPublicPort,
  );
  final fullUrl = baseUrl.resolveUri(url);

  final request = Request(method, fullUrl);

  request.headers['Content-Type'] = 'application/json';
  if (headers != null) {
    request.headers.addAll(headers);
  }

  if (body != null) {
    request.body = body;
  }

  // ignore: avoid_print
  print('SyncGateway Request: $method $url, admin: $admin');

  return _withClient((client) async {
    final response = await client.send(request);
    final body = await response.stream.bytesToString();

    final expectedStatusCode = method == 'PUT' ? 201 : 200;

    if (response.statusCode != expectedStatusCode) {
      throw StateError(
        'Got a response with status code ${response.statusCode} from '
        'SyncGateway but expected status code $expectedStatusCode: $body',
      );
    }

    return body;
  });
}

Future<T> _withClient<T>(Future<T> Function(Client) fn) async {
  final client = Client();
  try {
    return await fn(client);
  } finally {
    client.close();
  }
}

Future<void> flushDatabaseByAdmin() async {
  // Prefer purging via Sync Gateway because it is faster and preserves auth
  // metadata such as test users.
  await _purgeSyncGatewayDatabase();
}

Future<void> _purgeSyncGatewayDatabase() async {
  final response = await syncGatewayRequest(
    Uri.parse('$syncGatewayDatabase/_all_docs'),
    admin: true,
  );
  final allDocs = jsonDecode(response) as Map<String, Object?>;
  final rows = allDocs['rows']! as List<Object?>;
  if (rows.isEmpty) {
    return;
  }
  final purgeBody = {
    for (final row in rows.cast<Map<String, Object?>>())
      row['id']! as String: ['*'],
  };
  await syncGatewayRequest(
    Uri.parse('$syncGatewayDatabase/_purge'),
    method: 'POST',
    admin: true,
    body: jsonEncode(purgeBody),
  );
}

Future<void> deleteDocumentByAdmin(Document doc) async {
  await syncGatewayRequest(
    Uri.parse('$syncGatewayDatabase/${doc.id}?rev=${doc.revisionId}'),
    method: 'DELETE',
    admin: true,
  );
}

Future<void> updateDocumentByAdmin(
  Document doc,
  Map<String, Object?> properties,
) async {
  await syncGatewayRequest(
    Uri.parse('$syncGatewayDatabase/${doc.id}?rev=${doc.revisionId}'),
    method: 'PUT',
    admin: true,
    body: jsonEncode(properties),
  );
}

extension ReplicatorUtilsDatabaseExtension on Database {
  /// Creates a replicator which is configured with the test sync gateway
  /// endpoint.
  Future<Replicator> createTestReplicator({
    ReplicatorType? replicatorType,
    bool? continuous,
    List<String>? channels,
    List<String>? documentIds,
    ReplicationFilter? pushFilter,
    TypedReplicationFilter? typedPushFilter,
    ReplicationFilter? pullFilter,
    TypedReplicationFilter? typedPullFilter,
    ConflictResolverFunction? conflictResolver,
    TypedConflictResolverFunction? typedConflictResolver,
    bool? enableAutoPurge,
    Authenticator? authenticator,
  }) async {
    final collectionConfig = CollectionConfiguration(
      channels: channels,
      documentIds: documentIds,
      pushFilter: pushFilter,
      typedPushFilter: typedPushFilter,
      pullFilter: pullFilter,
      typedPullFilter: typedPullFilter,
      conflictResolver: conflictResolver != null
          ? ConflictResolver.from(conflictResolver)
          : null,
      typedConflictResolver: typedConflictResolver != null
          ? TypedConflictResolver.from(typedConflictResolver)
          : null,
    );
    final config = ReplicatorConfiguration(
      target: UrlEndpoint(syncGatewayReplicationUrl),
      replicatorType: replicatorType ?? ReplicatorType.pushAndPull,
      continuous: continuous ?? false,
      enableAutoPurge: enableAutoPurge ?? true,
      authenticator: authenticator ?? janeAuthenticator,
    )..addCollection(await defaultCollection, collectionConfig);
    return Replicator.create(config);
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

Matcher hasActivityLevel(ReplicatorActivityLevel activityLevel) =>
    isReplicatorStatus.having((it) => it.activity, 'activity', activityLevel);

const _replicatorStatusPollInterval = Duration(milliseconds: 150);
const _replicateOneShotTimeout = Duration(seconds: 10);
const _replicateOneShotStopTimeout = Duration(seconds: 5);

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
    while (true) {
      final currentStatus = await _readStatusOrNull();
      if (currentStatus == null) {
        return;
      }

      yield currentStatus;
      await Future<void>.delayed(_replicatorStatusPollInterval);
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

    try {
      await pollStatus()
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
          })
          .firstWhere((isMatch) => isMatch);
    } catch (error) {
      if (!_isPollStreamCompletedError(error)) {
        rethrow;
      }
    }
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

    try {
      await pollStatus()
          .asyncMap((status) async {
            expect(status, validStatusMatcher);

            final isMatch = _matches(status, statusMatcher);
            if (!calledDriveFn && !isMatch) {
              calledDriveFn = true;
              await fn();
            }

            return isMatch;
          })
          .firstWhere((isMatch) => isMatch);
    } catch (error) {
      if (!_isPollStreamCompletedError(error)) {
        rethrow;
      }
    }
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

    try {
      await pollStatus()
          .asyncMap((status) async {
            expect(status, validStatusMatcher);

            final isMatch = _matches(status, statusMatcher);
            if (isMatch) {
              await fn();
            }

            return isMatch;
          })
          .firstWhere((isMatch) => isMatch);
    } catch (error) {
      if (!_isPollStreamCompletedError(error)) {
        rethrow;
      }
    }
  }

  /// Starts a one shot replicator and completes when it has stopped.
  Future<void> replicateOneShot({
    Duration timeout = _replicateOneShotTimeout,
    Duration stopTimeout = _replicateOneShotStopTimeout,
  }) async {
    assert(!config.continuous);

    ReplicatorStatus? lastStatus;

    try {
      await doAndWaitForStatus(
        hasActivityLevel(ReplicatorActivityLevel.stopped),
        start,
        matchInitialStatus: true,
        validStatusMatcher: anything,
      ).timeout(timeout);
    } on TimeoutException {
      lastStatus = await _readStatusOrNull();
      await _stopAfterTimeout(stopTimeout);

      throw TimeoutException(
        'One-shot replication did not stop within ${timeout.inSeconds}s. '
        'Last status: ${_describeReplicatorStatus(lastStatus)}.',
      );
    } catch (error) {
      if (!_isClosedResourceError(error)) {
        rethrow;
      }
    }
  }

  Future<ReplicatorStatus?> _readStatusOrNull() async {
    try {
      return await Future<ReplicatorStatus>.sync(() => status);
    } catch (error) {
      if (_isClosedResourceError(error)) {
        return null;
      }

      rethrow;
    }
  }

  Future<void> _stopAfterTimeout(Duration stopTimeout) async {
    try {
      await Future<void>.sync(stop);
    } catch (error) {
      if (!_isClosedResourceError(error)) {
        rethrow;
      }
      return;
    }

    try {
      await doAndWaitForStatus(
        hasActivityLevel(ReplicatorActivityLevel.stopped),
        () {},
        validStatusMatcher: anything,
      ).timeout(stopTimeout);
    } on TimeoutException {
      // The test has already failed with a timeout. Leave teardown to finish
      // closing the replicator in the background.
    } catch (error) {
      if (!_isClosedResourceError(error)) {
        rethrow;
      }
    }
  }
}

bool _matches(Object actual, Object expected) =>
    wrapMatcher(expected).matches(actual, <Object?, Object?>{});

bool _isClosedResourceError(Object error) {
  final message = _stateErrorMessage(error);
  return message != null &&
      message.startsWith('Resource has already been closed:');
}

bool _isPollStreamCompletedError(Object error) =>
    _stateErrorMessage(error) == 'No element';

String? _stateErrorMessage(Object error) =>
    error is StateError ? error.message as String? : null;

String _describeReplicatorStatus(ReplicatorStatus? status) {
  if (status == null) {
    return 'unavailable (replicator closed during teardown)';
  }

  final errorDescription = status.error?.toString() ?? 'none';
  return 'activity=${status.activity.name}, '
      'progress=${status.progress.progress}, '
      'documents=${status.progress.completed}, '
      'error=$errorDescription';
}
