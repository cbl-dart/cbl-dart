import 'dart:io';

import 'package:cbl_dart/cbl_dart.dart';
import 'package:cbl_dart/src/acquire_libraries.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'merged native libraries should be stored in system-wide shared directory',
    () async {
      sharedCacheDirOverride = (await Directory.systemTemp.createTemp()).path;

      await CouchbaseLiteDart.init(edition: Edition.enterprise);

      final sharedMergeNativeLibraries =
          Directory(p.join(sharedCacheDirOverride!, 'merged_native_libraries'));

      expect(sharedMergeNativeLibraries.existsSync(), isTrue);
      expect(sharedMergeNativeLibraries.listSync(), hasLength(1));
    },
  );
}
