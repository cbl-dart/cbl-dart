import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/api_variant.dart';
import '../utils/database_utils.dart';
import '../utils/matchers.dart';
import '../utils/replicator_utils.dart';

// TODO(blaugold): fix tests on macOS + Flutter + CI
// ignore: do_not_use_environment
const String? skipPeerSyncTest = bool.fromEnvironment('skipPeerSyncTest')
    ? 'Skipping test on macOS + Flutter + CI'
    : null;

void main() {
  setupTestBinding();

  group('UrlEndpointListenerConfiguration', () {
    test('defaults', () async {
      final db = await openAsyncTestDatabase();
      final config = UrlEndpointListenerConfiguration(
        collections: [await db.defaultCollection],
      );
      expect(config.port, isNull);
      expect(config.networkInterface, isNull);
      expect(config.disableTls, isFalse);
      expect(config.tlsIdentity, isNull);
      expect(config.authenticator, isNull);
      expect(config.enableDeltaSync, isFalse);
    });

    test('from', () async {
      final db = await openAsyncTestDatabase();
      final config = UrlEndpointListenerConfiguration(
        collections: [await db.defaultCollection],
        port: 1234,
        networkInterface: 'en2',
        disableTls: true,
        tlsIdentity: await TlsIdentity.createIdentity(
          keyUsages: {KeyUsage.serverAuth},
          attributes: const CertificateAttributes(commonName: 'test'),
          expiration: DateTime(2100),
        ),
        authenticator: ListenerPasswordAuthenticator((_, __) => true),
        enableDeltaSync: true,
      );
      final configCopy = UrlEndpointListenerConfiguration.from(config);
      expect(configCopy.collections, config.collections);
      expect(configCopy.port, config.port);
      expect(configCopy.networkInterface, config.networkInterface);
      expect(configCopy.disableTls, config.disableTls);
      expect(configCopy.tlsIdentity, config.tlsIdentity);
      expect(configCopy.authenticator, config.authenticator);
      expect(configCopy.enableDeltaSync, config.enableDeltaSync);
    });

    group('collections', () {
      test('is unmodifiable', () async {
        final db = await openAsyncTestDatabase();
        final config = UrlEndpointListenerConfiguration(
          collections: [await db.defaultCollection],
        );
        expect(
          () => config.collections.add(config.collections.first),
          throwsUnsupportedError,
        );
      });

      test('throws when trying to set empty list', () async {
        expect(
          () => UrlEndpointListenerConfiguration(
            collections: [],
          ),
          throwsA(isDatabaseException.havingCode(
            DatabaseErrorCode.invalidParameter,
          )),
        );

        final db = await openAsyncTestDatabase();
        final config = UrlEndpointListenerConfiguration(
          collections: [await db.defaultCollection],
        );

        expect(
          () => config.collections = [],
          throwsA(isDatabaseException.havingCode(
            DatabaseErrorCode.invalidParameter,
          )),
        );
      });
    });

    test('toString', () async {
      final db = await openAsyncTestDatabase();
      final tlsIdentity = await TlsIdentity.createIdentity(
        keyUsages: {KeyUsage.serverAuth},
        attributes: const CertificateAttributes(commonName: 'test'),
        expiration: DateTime(2100),
      );
      final authenticator = ListenerPasswordAuthenticator((_, __) => true);
      final config = UrlEndpointListenerConfiguration(
        collections: [await db.defaultCollection],
        port: 1234,
        networkInterface: 'en2',
        disableTls: true,
        tlsIdentity: tlsIdentity,
        authenticator: authenticator,
        enableDeltaSync: true,
      );
      expect(
        config.toString(),
        'URLEndpointListenerConfiguration('
        'collections: ${config.collections}, '
        'port: ${config.port}, '
        'networkInterface: ${config.networkInterface}, '
        'DISABLE-TLS, '
        'tlsIdentity: ${config.tlsIdentity}, '
        'authenticator: ${config.authenticator}, '
        'ENABLE-DELTA-SYNC'
        ')',
      );
    });
  });

  group('ConnectionStatus', () {
    test('toString', () {
      expect(
        ConnectionStatus(connectionCount: 1, activeConnectionCount: 2)
            .toString(),
        'ConnectionStatus(connectionCount: 1, activeConnectionCount: 2)',
      );
    });
  });

  group('UrlEndpointListener', () {
    apiTest('create', () async {
      final db = await openTestDatabase();
      final config = UrlEndpointListenerConfiguration(collections: [
        await db.defaultCollection,
      ]);
      await UrlEndpointListener.create(config);
    });

    test('create TlsIdentity if not configured but tls enabled', () async {
      final db = await openAsyncTestDatabase();
      final config = UrlEndpointListenerConfiguration(
        collections: [await db.defaultCollection],
        disableTls: false,
      );
      final listener = await UrlEndpointListener.create(config);
      expect(listener.tlsIdentity, isNotNull);
    });

    test('port & urls', () async {
      final db = await openAsyncTestDatabase();
      final config = UrlEndpointListenerConfiguration(collections: [
        await db.defaultCollection,
      ]);
      final listener = await UrlEndpointListener.create(config);
      expect(listener.port, isNull);
      expect(listener.urls, isNull);
      await listener.start();
      expect(listener.port, isNotNull);
      expect(listener.urls, isNotNull);
      expect(listener.urls, isNotEmpty);
    });

    test('toString', () async {
      final db = await openAsyncTestDatabase();
      final tlsIdentity = await TlsIdentity.createIdentity(
        keyUsages: {KeyUsage.serverAuth},
        attributes: const CertificateAttributes(commonName: 'test'),
        expiration: DateTime(2100),
      );
      final config = UrlEndpointListenerConfiguration(
        collections: [await db.defaultCollection],
        tlsIdentity: tlsIdentity,
      );
      final listener = await UrlEndpointListener.create(config);
      expect(
        listener.toString(),
        'UrlEndpointListener('
        'config: ${listener.config}, '
        'tlsIdentity: ${listener.config.tlsIdentity}, '
        'connectionStatus: ${listener.connectionStatus}'
        ')',
      );

      await listener.start();

      expect(
        listener.toString(),
        'UrlEndpointListener('
        'config: ${listener.config}, '
        'port: ${listener.port}, '
        'urls: ${listener.urls}, '
        'tlsIdentity: ${listener.config.tlsIdentity}, '
        'connectionStatus: ${listener.connectionStatus}'
        ')',
      );

      await listener.stop();
    });

    test('replicate document', skip: skipPeerSyncTest, () async {
      final listenerDb = await openAsyncTestDatabase(name: 'listener');
      final clientDb = await openAsyncTestDatabase(name: 'client');

      var listenerDoc = MutableDocument({'value': 'listener'});
      await (await listenerDb.defaultCollection).saveDocument(listenerDoc);

      final listenerConfig = UrlEndpointListenerConfiguration(
        collections: [await listenerDb.defaultCollection],
      );
      final listener = await UrlEndpointListener.create(listenerConfig);
      await listener.start();
      addTearDown(listener.stop);

      final replicatorConfig = ReplicatorConfiguration(
        target: UrlEndpoint(listener.urls!.first),
        acceptOnlySelfSignedServerCertificate: true,
      )..addCollection(await clientDb.defaultCollection);
      final replicator = await Replicator.create(replicatorConfig);

      // Pull document from listener to client.
      await replicator.replicateOneShot();
      final clientDoc =
          (await (await clientDb.defaultCollection).document(listenerDoc.id))
              ?.toMutable();
      expect(clientDoc, isNotNull);
      expect(clientDoc!.id, listenerDoc.id);
      expect(clientDoc, listenerDoc);

      // Update document in client and push to listener.
      clientDoc.setValue('client', key: 'value');
      await (await clientDb.defaultCollection).saveDocument(clientDoc);
      await replicator.replicateOneShot();
      listenerDoc =
          (await (await listenerDb.defaultCollection).document(listenerDoc.id))!
              .toMutable();
      expect(listenerDoc, clientDoc);
    });
  });

  apiTest('ListenerPasswordAuthenticator', skip: skipPeerSyncTest, () async {
    final clientAuthenticatorA =
        BasicAuthenticator(username: 'a', password: 'aa');
    final clientAuthenticatorB =
        BasicAuthenticator(username: 'b', password: 'bb');

    final listenerDb = await openTestDatabase(name: 'listener');
    final clientDb = await openTestDatabase(name: 'client');

    var authenticatorCall = 0;
    final listenerAuthenticator = ListenerPasswordAuthenticator(
      expectAsync2(
        count: 2,
        (username, password) {
          final expectedAuthenticator = switch (authenticatorCall++) {
            0 => clientAuthenticatorA,
            1 => clientAuthenticatorB,
            _ => throw Exception('Unexpected call'),
          };
          expect(username, expectedAuthenticator.username);
          return password == clientAuthenticatorB.password;
        },
      ),
    );
    final listenerConfig = UrlEndpointListenerConfiguration(
      collections: [await listenerDb.defaultCollection],
      authenticator: listenerAuthenticator,
    );
    final listener = await UrlEndpointListener.create(listenerConfig);
    await listener.start();
    addTearDown(listener.stop);

    // Connect to listener without client certificate.
    var replicatorConfig = ReplicatorConfiguration(
      target: UrlEndpoint(listener.urls!.first),
      acceptOnlySelfSignedServerCertificate: true,
    )..addCollection(await clientDb.defaultCollection);
    var replicator = await Replicator.create(replicatorConfig);
    await replicator.replicateOneShot();
    var replicatorStatus = await replicator.status;
    expect(
      replicatorStatus.error,
      isHttpException.havingCode(HttpErrorCode.authRequired),
    );

    // Connect to listener with untrusted client certificate.
    replicatorConfig = ReplicatorConfiguration(
      target: UrlEndpoint(listener.urls!.first),
      authenticator: clientAuthenticatorA,
      acceptOnlySelfSignedServerCertificate: true,
    )..addCollection(await clientDb.defaultCollection);
    replicator = await Replicator.create(replicatorConfig);
    await replicator.replicateOneShot();
    replicatorStatus = await replicator.status;
    expect(
      replicatorStatus.error,
      isHttpException.havingCode(HttpErrorCode.authRequired),
    );

    // Connect to listener with trusted client certificate.
    replicatorConfig = ReplicatorConfiguration(
      target: UrlEndpoint(listener.urls!.first),
      authenticator: clientAuthenticatorB,
      acceptOnlySelfSignedServerCertificate: true,
    )..addCollection(await clientDb.defaultCollection);
    replicator = await Replicator.create(replicatorConfig);
    await replicator.replicateOneShot();
    replicatorStatus = await replicator.status;
    expect(replicatorStatus.error, isNull);
  });

  group('ListenerCertificateAuthenticator', () {
    apiTest('with handler', skip: skipPeerSyncTest, () async {
      final clientAuthenticatorA =
          ClientCertificateAuthenticator(await TlsIdentity.createIdentity(
        keyUsages: {KeyUsage.clientAuth},
        attributes: const CertificateAttributes(commonName: 'Client A'),
        expiration: DateTime(2100),
      ));
      final clientAuthenticatorB =
          ClientCertificateAuthenticator(await TlsIdentity.createIdentity(
        keyUsages: {KeyUsage.clientAuth},
        attributes: const CertificateAttributes(commonName: 'Client B'),
        expiration: DateTime(2100),
      ));

      final listenerDb = await openTestDatabase(name: 'listener');
      final clientDb = await openTestDatabase(name: 'client');

      var authenticatorCall = 0;
      final listenerAuthenticator = ListenerCertificateAuthenticator(
        expectAsync1(
          count: 2,
          (certificate) {
            final expectedAuthenticator = switch (authenticatorCall++) {
              0 => clientAuthenticatorA,
              1 => clientAuthenticatorB,
              _ => throw Exception('Unexpected call'),
            };
            expect(
              certificate.toPem(),
              expectedAuthenticator.identity.certificates.single.toPem(),
            );
            return certificate.toPem() ==
                clientAuthenticatorB.identity.certificates.single.toPem();
          },
        ),
      );
      final listenerConfig = UrlEndpointListenerConfiguration(
        collections: [await listenerDb.defaultCollection],
        authenticator: listenerAuthenticator,
      );
      final listener = await UrlEndpointListener.create(listenerConfig);
      await listener.start();
      addTearDown(listener.stop);

      // Connect to listener without client certificate.
      var replicatorConfig = ReplicatorConfiguration(
        target: UrlEndpoint(listener.urls!.first),
        acceptOnlySelfSignedServerCertificate: true,
      )..addCollection(await clientDb.defaultCollection);
      var replicator = await Replicator.create(replicatorConfig);
      await replicator.replicateOneShot();
      var replicatorStatus = await replicator.status;
      expect(
        replicatorStatus.error,
        isNetworkException.havingCode(NetworkErrorCode.tlsHandshakeFailed),
      );

      // Connect to listener with untrusted client certificate.
      replicatorConfig = ReplicatorConfiguration(
        target: UrlEndpoint(listener.urls!.first),
        authenticator: clientAuthenticatorA,
        acceptOnlySelfSignedServerCertificate: true,
      )..addCollection(await clientDb.defaultCollection);
      replicator = await Replicator.create(replicatorConfig);
      await replicator.replicateOneShot();
      replicatorStatus = await replicator.status;
      expect(
        replicatorStatus.error,
        isNetworkException.havingCode(NetworkErrorCode.tlsClientCertRejected),
      );

      // Connect to listener with trusted client certificate.
      replicatorConfig = ReplicatorConfiguration(
        target: UrlEndpoint(listener.urls!.first),
        authenticator: clientAuthenticatorB,
        acceptOnlySelfSignedServerCertificate: true,
      )..addCollection(await clientDb.defaultCollection);
      replicator = await Replicator.create(replicatorConfig);
      await replicator.replicateOneShot();
      replicatorStatus = await replicator.status;
      expect(replicatorStatus.error, isNull);
    });

    apiTest('with trusted roots', skip: skipPeerSyncTest, () async {
      final clientAuthenticatorA =
          ClientCertificateAuthenticator(await TlsIdentity.createIdentity(
        keyUsages: {KeyUsage.clientAuth},
        attributes: const CertificateAttributes(commonName: 'Client A'),
        expiration: DateTime(2100),
      ));
      final clientAuthenticatorB =
          ClientCertificateAuthenticator(await TlsIdentity.createIdentity(
        keyUsages: {KeyUsage.clientAuth},
        attributes: const CertificateAttributes(commonName: 'Client B'),
        expiration: DateTime(2100),
      ));

      final listenerDb = await openTestDatabase(name: 'listener');
      final clientDb = await openTestDatabase(name: 'client');

      final listenerAuthenticator = ListenerCertificateAuthenticator.fromRoots(
        clientAuthenticatorB.identity.certificates,
      );
      final listenerConfig = UrlEndpointListenerConfiguration(
        collections: [await listenerDb.defaultCollection],
        authenticator: listenerAuthenticator,
      );
      final listener = await UrlEndpointListener.create(listenerConfig);
      await listener.start();
      addTearDown(listener.stop);

      // Connect to listener without client certificate.
      var replicatorConfig = ReplicatorConfiguration(
        target: UrlEndpoint(listener.urls!.first),
        acceptOnlySelfSignedServerCertificate: true,
      )..addCollection(await clientDb.defaultCollection);
      var replicator = await Replicator.create(replicatorConfig);
      await replicator.replicateOneShot();
      var replicatorStatus = await replicator.status;
      expect(
        replicatorStatus.error,
        isNetworkException.havingCode(NetworkErrorCode.tlsHandshakeFailed),
      );

      // Connect to listener with untrusted client certificate.
      replicatorConfig = ReplicatorConfiguration(
        target: UrlEndpoint(listener.urls!.first),
        authenticator: clientAuthenticatorA,
        acceptOnlySelfSignedServerCertificate: true,
      )..addCollection(await clientDb.defaultCollection);
      replicator = await Replicator.create(replicatorConfig);
      await replicator.replicateOneShot();
      replicatorStatus = await replicator.status;
      expect(
        replicatorStatus.error,
        isNetworkException.havingCode(NetworkErrorCode.tlsClientCertRejected),
      );

      // Connect to listener with trusted client certificate.
      replicatorConfig = ReplicatorConfiguration(
        target: UrlEndpoint(listener.urls!.first),
        authenticator: clientAuthenticatorB,
        acceptOnlySelfSignedServerCertificate: true,
      )..addCollection(await clientDb.defaultCollection);
      replicator = await Replicator.create(replicatorConfig);
      await replicator.replicateOneShot();
      replicatorStatus = await replicator.status;
      expect(replicatorStatus.error, isNull);
    });
  });
}
