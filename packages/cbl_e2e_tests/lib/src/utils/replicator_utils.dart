// TODO(blaugold): Migrate to collection API.
// ignore_for_file: deprecated_member_use

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
final janeAuthenticator =
    BasicAuthenticator(username: 'Jane', password: 'Jane');
final aliceAuthenticator =
    BasicAuthenticator(username: 'Alice', password: 'Alice');

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
  await syncGatewayRequest(
    Uri.parse('$syncGatewayDatabase/_flush'),
    method: 'POST',
    admin: true,
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
  FutureOr<Replicator> createTestReplicator({
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
  }) =>
      Replicator.create(ReplicatorConfiguration(
        database: this,
        target: UrlEndpoint(syncGatewayReplicationUrl),
        replicatorType: replicatorType ?? ReplicatorType.pushAndPull,
        continuous: continuous ?? false,
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
        enableAutoPurge: enableAutoPurge ?? true,
        authenticator: authenticator ?? janeAuthenticator,
      ));
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
      await Future<void>.delayed(const Duration(milliseconds: 150));
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
