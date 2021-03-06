import 'dart:typed_data';

import 'package:cbl/cbl.dart';

import 'test_binding.dart';

void main() {
  test('create Replicator smoke test', () async {
    final db = await Database.open(
      testDbName('CreateReplicatorSmoke'),
      config: DatabaseConfiguration(directory: tmpDir),
    );

    addTearDown(db.close);

    final replicator = await db.createReplicator(ReplicatorConfiguration(
      endpoint: UrlEndpoint(Uri.parse('ws://localhost:4984/db')),
      replicatorType: ReplicatorType.pushAndPull,
      continuous: true,
      authenticator: BasicAuthenticator(
        username: 'user',
        password: 'password',
      ),
      headers: {'Client': 'test'},
      proxy: ProxySettings(
        type: ProxyType.http,
        hostname: 'host',
        port: 4444,
        username: 'user',
        password: 'password',
      ),
      pinnedServerCertificate: Uint8List(0),
      trustedRootCertificates: Uint8List(0),
      channels: ['channel'],
      documentIDs: ['id'],
      pullFilter: (document, isDeleted) => true,
      pushFilter: (document, isDeleted) => true,
      conflictResolver: (documentId, local, remote) => local,
    ));

    addTearDown(replicator.close);
  });
}
