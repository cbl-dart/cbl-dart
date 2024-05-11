import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:cbl_native_assets/cbl.dart';
import 'package:cbl_native_assets/src/service/cbl_service_api.dart';

import 'api_variant.dart';
import 'database_utils.dart';

Uint8List randomRawEncryptionKey() {
  final random = Random.secure();
  return Uint8List.fromList(
    List.generate(32, (_) => random.nextInt(256)),
  );
}

FutureOr<EncryptionKey> createTestEncryptionKeyWithPassword(String password) =>
    runWithApi(
      sync: () => EncryptionKey.passwordSync(password),
      async: () => runWithIsolate(
        main: () => sharedMainIsolateClient.channel
            .call(EncryptionKeyFromPassword(password)),
        worker: () => EncryptionKey.passwordAsync(password),
      ),
    );
