import 'dart:typed_data';

import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('Configuration', () {
    test('defaults', () {
      final config = ReplicatorConfiguration(
        database: _Database(),
        target: UrlEndpoint(Uri.parse('ws://host/db')),
      );

      expect(config.replicatorType, ReplicatorType.pushAndPull);
      expect(config.continuous, false);
      expect(config.authenticator, isNull);
      expect(config.pinnedServerCertificate, isNull);
      expect(config.headers, isNull);
      expect(config.channels, isNull);
      expect(config.documentIds, isNull);
      expect(config.pushFilter, isNull);
      expect(config.pullFilter, isNull);
      expect(config.conflictResolver, isNull);
      expect(config.enableAutoPurge, isTrue);
      expect(config.heartbeat, isNull);
      expect(config.maxAttempts, isNull);
      expect(config.maxAttemptWaitTime, isNull);
    });

    test('set validated properties', () {
      final config = ReplicatorConfiguration(
        database: _Database(),
        target: UrlEndpoint(Uri.parse('ws://host/db')),
      )..heartbeat = const Duration(seconds: 1);

      expect(config.heartbeat, const Duration(seconds: 1));
      expect(() => config.heartbeat = Duration.zero, throwsRangeError);
      expect(
        () => config.heartbeat = const Duration(seconds: -1),
        throwsRangeError,
      );

      config.maxAttempts = 1;
      expect(config.maxAttempts, 1);
      expect(() => config.maxAttempts = 0, throwsRangeError);
      expect(() => config.maxAttempts = -1, throwsRangeError);

      config.maxAttemptWaitTime = const Duration(seconds: 1);
      expect(config.maxAttemptWaitTime, const Duration(seconds: 1));
      expect(
        () => config.maxAttemptWaitTime = Duration.zero,
        throwsRangeError,
      );
    });

    test('from', () {
      final source = ReplicatorConfiguration(
        database: _Database(),
        target: UrlEndpoint(Uri.parse('ws://host/db')),
        replicatorType: ReplicatorType.pull,
        continuous: true,
        authenticator: SessionAuthenticator(sessionId: 'sessionId'),
        pinnedServerCertificate: Uint8List(0),
        headers: {'Client': 'cbl-dart', 'Authentication': 'AUTH'},
        channels: ['A'],
        documentIds: ['ID'],
        pushFilter: (document, flags) => true,
        pullFilter: (document, flags) => true,
        conflictResolver: ConflictResolver.from((_) {}),
        enableAutoPurge: false,
        heartbeat: const Duration(seconds: 1),
        maxAttempts: 1,
        maxAttemptWaitTime: const Duration(seconds: 1),
      );

      final copy = ReplicatorConfiguration.from(source);

      expect(copy.database, source.database);
      expect(copy.target, source.target);
      expect(copy.replicatorType, source.replicatorType);
      expect(copy.continuous, source.continuous);
      expect(copy.authenticator, source.authenticator);
      expect(copy.pinnedServerCertificate, source.pinnedServerCertificate);
      expect(copy.headers, source.headers);
      expect(copy.channels, source.channels);
      expect(copy.documentIds, source.documentIds);
      expect(copy.pushFilter, source.pushFilter);
      expect(copy.pullFilter, source.pullFilter);
      expect(copy.conflictResolver, source.conflictResolver);
      expect(copy.enableAutoPurge, source.enableAutoPurge);
      expect(copy.heartbeat, source.heartbeat);
      expect(copy.maxAttempts, source.maxAttempts);
      expect(copy.maxAttemptWaitTime, source.maxAttemptWaitTime);
    });

    test('toString', () {
      ReplicatorConfiguration config;

      config = ReplicatorConfiguration(
        database: _Database(),
        target: UrlEndpoint(Uri.parse('ws://host/db')),
      );
      expect(
        config.toString(),
        'ReplicatorConfiguration('
        'database: _Database, '
        'target: UrlEndpoint(ws://host/db), '
        // ignore: missing_whitespace_between_adjacent_strings
        'replicatorType: pushAndPull'
        ')',
      );

      config = ReplicatorConfiguration(
        database: _Database(),
        target: UrlEndpoint(Uri.parse('ws://host/db')),
        replicatorType: ReplicatorType.pull,
        continuous: true,
        authenticator: SessionAuthenticator(sessionId: 'sessionId'),
        pinnedServerCertificate: Uint8List(0),
        headers: {'Client': 'cbl-dart', 'Authentication': 'AUTH'},
        channels: ['A'],
        documentIds: ['ID'],
        pushFilter: (document, flags) => true,
        pullFilter: (document, flags) => true,
        conflictResolver: ConflictResolver.from((_) {}),
        enableAutoPurge: false,
        heartbeat: const Duration(seconds: 1),
        maxAttempts: 1,
        maxAttemptWaitTime: const Duration(seconds: 1),
      );

      expect(
        config.toString(),
        'ReplicatorConfiguration('
        'database: _Database, '
        'target: UrlEndpoint(ws://host/db), '
        'replicatorType: pull, '
        'CONTINUOUS, '
        'authenticator: SessionAuthenticator(sessionId: ******nId, '
        'cookieName: SyncGatewaySession), '
        'PINNED-SERVER-CERTIFICATE, '
        'headers: {Client: cbl-dart, Authentication: REDACTED}, '
        'channels: [A], '
        'documentIds: [ID], '
        'PUSH-FILTER, '
        'PULL-FILTER, '
        'CUSTOM-CONFLICT-RESOLVER, '
        'DISABLE-AUTO-PURGE, '
        'heartbeat: 1s, '
        'maxAttempts: 1, '
        // ignore: missing_whitespace_between_adjacent_strings
        'maxAttemptWaitTime: 1s'
        ')',
      );
    });
  });
}

class _Database implements Database {
  @override
  void noSuchMethod(Invocation invocation) {}

  @override
  String toString() => '_Database';
}
