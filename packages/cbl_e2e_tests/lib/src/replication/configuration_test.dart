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
      expect(config.heartbeat, Duration(seconds: 300));
      expect(config.maxRetries, 9);
      expect(config.maxRetryWaitTime, Duration(seconds: 300));
    });

    test('set validated properties', () {
      final config = ReplicatorConfiguration(
        database: _Database(),
        target: UrlEndpoint(Uri.parse('ws://host/db')),
      );

      config.heartbeat = Duration(seconds: 1);
      expect(config.heartbeat, Duration(seconds: 1));
      expect(() => config.heartbeat = Duration(), throwsArgumentError);

      config.maxRetries = 0;
      expect(config.maxRetries, 0);

      // Setting maxRetries to null restores default values which depend on
      // continuous.
      config.maxRetries = null;
      expect(config.maxRetries, 9);
      config.continuous = true;
      expect(config.maxRetries, 1 << 64);

      expect(() => config.maxRetries = -1, throwsArgumentError);

      config.maxRetryWaitTime = Duration(seconds: 1);
      expect(config.maxRetryWaitTime, Duration(seconds: 1));
      expect(() => config.maxRetryWaitTime = Duration(), throwsArgumentError);
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
        heartbeat: Duration(seconds: 1),
        maxRetries: 0,
        maxRetryWaitTime: Duration(seconds: 1),
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
      expect(copy.heartbeat, source.heartbeat);
      expect(copy.maxRetries, source.maxRetries);
      expect(copy.maxRetryWaitTime, source.maxRetryWaitTime);
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
        'replicatorType: pushAndPull, '
        'heartbeat: 300, '
        'maxRetries: 9, '
        'maxRetryWaitTime: 300'
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
        heartbeat: Duration(seconds: 1),
        maxRetries: 0,
        maxRetryWaitTime: Duration(seconds: 1),
      );

      expect(
        config.toString(),
        'ReplicatorConfiguration('
        'database: _Database, '
        'target: UrlEndpoint(ws://host/db), '
        'replicatorType: pull, '
        'CONTINUOUS, '
        'authenticator: SessionAuthenticator(sessionId: ******nId, cookieName: SyncGatewaySession), '
        'PINNED-SERVER-CERTIFICATE, '
        'headers: {Client: cbl-dart, Authentication: REDACTED}, '
        'channels: [A], '
        'documentIds: [ID], '
        'PUSH-FILTER, '
        'PULL-FILTER, '
        'CUSTOM-CONFLICT-RESOLVER, '
        'heartbeat: 1, '
        'maxRetries: 0, '
        'maxRetryWaitTime: 1'
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
