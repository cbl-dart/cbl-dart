import 'dart:io';

import 'package:cbl_dart/cbl_dart.dart';
import 'package:test/test.dart';

void main() {
  test(
    'merged native libraries should be stored in provided directory',
    () async {
      final nativeLibrariesDir = await Directory.systemTemp.createTemp();

      await CouchbaseLiteDart.init(
        edition: Edition.enterprise,
        nativeLibrariesDir: nativeLibrariesDir.path,
      );

      expect(nativeLibrariesDir.existsSync(), isTrue);
      expect(nativeLibrariesDir.listSync(), hasLength(1));
    },
  );
}
