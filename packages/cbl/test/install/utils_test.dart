import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';

import 'package:cbl/src/install.dart';
import 'package:cbl/src/install/utils.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  for (final format in ArchiveFormat.values) {
    group('unpackArchive ${format.name}', () {
      Future<Directory> unpack(List<ArchiveFile> entries) async {
        final directory = tempTestDirectory();
        await unpackArchive(
          _encodeArchive(entries, format),
          format: format,
          outputDir: directory.path,
        );
        return directory;
      }

      test('extracts regular files', () async {
        final directory = await unpack([
          ArchiveFile.string('nested/file', 'content'),
        ]);
        expect(
          File('${directory.path}/nested/file').readAsStringSync(),
          'content',
        );
      });

      group('symbolic links', skip: Platform.isWindows, () {
        for (final linksFirst in [false, true]) {
          test(
            'preserves framework links (links first: $linksFirst)',
            () async {
              const framework = 'Example.framework';
              final links = [
                _link('$framework/Example', 'Versions/Current/Example'),
                _link('$framework/Resources', 'Versions/Current/Resources'),
                _link('$framework/Versions/Current', 'A'),
              ];
              final files = [
                ArchiveFile.string('$framework/Versions/A/Example', 'binary'),
                ArchiveFile.string(
                  '$framework/Versions/A/Resources/Info.plist',
                  'plist',
                ),
              ];
              final directory = await unpack([
                if (linksFirst) ...links,
                ...files,
                if (!linksFirst) ...links.reversed,
              ]);
              final root = '${directory.path}/$framework';
              expect(
                Link('$root/Example').targetSync(),
                'Versions/Current/Example',
              );
              expect(
                Link('$root/Resources').targetSync(),
                'Versions/Current/Resources',
              );
              expect(Link('$root/Versions/Current').targetSync(), 'A');
              expect(File('$root/Example').readAsStringSync(), 'binary');
              expect(
                File('$root/Resources/Info.plist').readAsStringSync(),
                'plist',
              );

              final copy = tempTestDirectory();
              await copyDirectoryContents(directory.path, copy.path);
              expect(
                File('${copy.path}/$framework/Example').readAsStringSync(),
                'binary',
              );
              expect(
                Link('${copy.path}/$framework/Example').targetSync(),
                'Versions/Current/Example',
              );
            },
          );
        }

        test('resolves multiple links independently of entry order', () async {
          final directory = await unpack([
            _link('first', 'second'),
            _link('second', 'third'),
            _link('third', 'file'),
            ArchiveFile.string('file', 'content'),
            _link('nested/relative', '../file'),
          ]);
          expect(File('${directory.path}/first').readAsStringSync(), 'content');
          expect(Link('${directory.path}/first').targetSync(), 'second');
          expect(
            File('${directory.path}/nested/relative').readAsStringSync(),
            'content',
          );
        });

        test('skips dangling and cyclic links', () async {
          final directory = await unpack([
            _link('dangling', 'missing'),
            _link('first', 'second'),
            _link('second', 'first'),
          ]);
          expect(directory.listSync(), isEmpty);
        });

        test('does not overwrite files or directories with links', () async {
          final directory = tempTestDirectory();
          File('${directory.path}/file').writeAsStringSync('content');
          await unpackArchive(
            _encodeArchive([
              ArchiveFile.string('nested/file', 'nested'),
              _link('file', 'nested/file'),
              _link('nested', 'file'),
            ], format),
            format: format,
            outputDir: directory.path,
          );
          expect(File('${directory.path}/file').readAsStringSync(), 'content');
          expect(
            File('${directory.path}/nested/file').readAsStringSync(),
            'nested',
          );
        });

        test('rejects absolute paths and targets and parent escapes', () async {
          final outside = tempTestDirectory();
          final outsideFile = File('${outside.path}/file')
            ..writeAsStringSync('outside');
          final directory = await unpack([
            ArchiveFile.string('file', 'inside'),
            _link('absolute-target', outsideFile.path),
            _link('${outside.path}/absolute-link', 'file'),
            _link('../escape', 'file'),
            _link(
              'escaping-target',
              '../${outside.uri.pathSegments.where((s) => s.isNotEmpty).last}/file',
            ),
          ]);
          expect(directory.listSync().map((e) => e.path.split('/').last), [
            'file',
          ]);
          expect(outside.listSync(), hasLength(1));
          expect(outsideFile.readAsStringSync(), 'outside');
        });

        test('does not write files through archive-created links', () async {
          final directory = await unpack([
            _link('alias', 'real'),
            ArchiveFile.string('real/file', 'original'),
            ArchiveFile.string('alias/file', 'separate'),
          ]);
          expect(
            File('${directory.path}/real/file').readAsStringSync(),
            'original',
          );
          expect(
            File('${directory.path}/alias/file').readAsStringSync(),
            'separate',
          );
          expect(
            FileSystemEntity.isLinkSync('${directory.path}/alias'),
            isFalse,
          );
        });

        test(
          'checks actual targets before resolving parent traversals',
          () async {
            final directory = tempTestDirectory();
            // Lexically top/dir/alias/../../outside is inside directory, but
            // alias -> .. makes it resolve to directory.parent/outside.
            final outside = File('${directory.path}-outside')
              ..writeAsStringSync('outside');
            addTearDown(outside.deleteSync);
            final outsideName = outside.uri.pathSegments.last;
            await unpackArchive(
              _encodeArchive([
                ArchiveFile.string('top/dir/file', 'inside'),
                ArchiveFile.string('top/$outsideName', 'decoy'),
                _link('escape', 'top/dir/alias/../../$outsideName'),
                _link('top/dir/alias', '..'),
              ], format),
              format: format,
              outputDir: directory.path,
            );
            expect(
              FileSystemEntity.typeSync(
                '${directory.path}/escape',
                followLinks: false,
              ),
              FileSystemEntityType.notFound,
            );
            expect(Link('${directory.path}/top/dir/alias').targetSync(), '..');
            expect(outside.readAsStringSync(), 'outside');
          },
        );

        test('does not create links through existing parent links', () async {
          final directory = tempTestDirectory();
          final outside = tempTestDirectory();
          Link('${directory.path}/parent').createSync(outside.path);
          await unpackArchive(
            _encodeArchive([
              ArchiveFile.string('file', 'inside'),
              _link('parent/link', '../file'),
              _link('escape', 'parent'),
            ], format),
            format: format,
            outputDir: directory.path,
          );
          expect(outside.listSync(), isEmpty);
          expect(
            FileSystemEntity.typeSync(
              '${directory.path}/escape',
              followLinks: false,
            ),
            FileSystemEntityType.notFound,
          );
        });
      });
    });
  }

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

ArchiveFile _link(String name, String target) {
  final entry = ArchiveFile.string(name, target)..mode = 0xa1ff;
  try {
    // ignore: avoid_dynamic_calls
    (entry as dynamic).symbolicLink = target;
    // ignore: avoid_catching_errors
  } on NoSuchMethodError {
    // ignore: avoid_dynamic_calls
    (entry as dynamic).isSymbolicLink = true;
    // ignore: avoid_dynamic_calls
    (entry as dynamic).nameOfLinkedFile = target;
  }
  return entry;
}

Uint8List _encodeArchive(List<ArchiveFile> entries, ArchiveFormat format) {
  final archive = Archive();
  entries.forEach(archive.addFile);
  final bytes = Uint8List.fromList(_encode(archive, format)!);
  if (format == ArchiveFormat.zip) {
    // ZipEncoder writes MS-DOS as the creator OS, even for Unix symlink modes.
    // Mark the central directory entries as Unix so ZipDecoder sees the links.
    final data = ByteData.sublistView(bytes);
    final end = bytes.length - 22;
    var offset = data.getUint32(end + 16, Endian.little);
    final count = data.getUint16(end + 10, Endian.little);
    for (var i = 0; i < count; i++) {
      bytes[offset + 5] = 3;
      offset +=
          46 +
          data.getUint16(offset + 28, Endian.little) +
          data.getUint16(offset + 30, Endian.little) +
          data.getUint16(offset + 32, Endian.little);
    }
  }
  return bytes;
}

// archive 3 encoders return nullable bytes; archive 4 encoders do not.
List<int>? _encode(Archive archive, ArchiveFormat format) => switch (format) {
  ArchiveFormat.zip => ZipEncoder().encode(archive),
  // ignore: prefer_const_constructors
  ArchiveFormat.tarGz => GZipEncoder().encode(TarEncoder().encode(archive)),
};
