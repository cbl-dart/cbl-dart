import 'dart:io';

import 'package:cbl/src/install.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('copyDirectoryContents', () {
    test('override link', () async {
      final sourceDir = tempTestDirectory();
      final targetDir = tempTestDirectory();

      File('${sourceDir.path}/file').writeAsStringSync('content');
      Link('${sourceDir.path}/link').createSync('file');

      await copyDirectoryContents(sourceDir.path, targetDir.path);
      expect(File('${targetDir.path}/file').readAsStringSync(), 'content');
      expect(Link('${targetDir.path}/link').targetSync(), 'file');

      await copyDirectoryContents(sourceDir.path, targetDir.path);
      expect(File('${targetDir.path}/file').readAsStringSync(), 'content');
      expect(Link('${targetDir.path}/link').targetSync(), 'file');
    });
  });
}
