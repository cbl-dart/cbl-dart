import 'dart:io';

import 'package:cbl/src/native_libraries.dart';
import 'package:hooks/hooks.dart';
import 'package:test/test.dart';

void main() {
  group('readHookUserDefines', () {
    test('returns defaults when no pubspec can be found', () async {
      final tempDir = await Directory.systemTemp.createTemp();
      addTearDown(() => tempDir.delete(recursive: true));

      final config = readHookUserDefines(tempDir);

      expect(config.editions, {Edition.community});
      expect(config.vectorSearch, isFalse);
      expect(config.baseDirectory, isNull);
    });

    test('prefers workspace root hook defaults over package pubspec', () async {
      final tempDir = await Directory.systemTemp.createTemp();
      addTearDown(() => tempDir.delete(recursive: true));

      final workspacePubspec = File('${tempDir.path}/pubspec.yaml');
      await workspacePubspec.writeAsString('''
workspace:
  - packages/cbl
hooks:
  user_defines:
    cbl:
      edition: enterprise
      vector_search: true
''');

      final packageDir = Directory('${tempDir.path}/packages/cbl');
      await packageDir.create(recursive: true);
      await File('${packageDir.path}/pubspec.yaml').writeAsString('''
name: cbl
hooks:
  user_defines:
    cbl:
      edition: community
      vector_search: false
''');

      final config = readHookUserDefines(packageDir);

      expect(config.editions, {Edition.enterprise});
      expect(config.vectorSearch, isTrue);
      expect(config.baseDirectory?.path, tempDir.path);
    });
  });

  group('resolveNativeLibraryDefaultsFromUserDefines', () {
    test('rejects vector search without enterprise edition', () {
      expect(
        () => resolveNativeLibraryDefaultsFromUserDefines({
          'edition': 'community',
          'vector_search': true,
        }),
        throwsA(isA<BuildError>()),
      );
    });
  });
}
