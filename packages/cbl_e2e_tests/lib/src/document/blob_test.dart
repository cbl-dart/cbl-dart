import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/document/blob.dart';
import 'package:cbl/src/support/streams.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/api_variant.dart';
import '../utils/database_utils.dart';
import '../utils/test_variant.dart';

void main() {
  setupTestBinding();

  group('Blob', () {
    group('from data', () {
      test('initial properties', () {
        final blob = Blob.fromData(contentType, fixedTestContent);
        expect(blob.contentType, contentType);
        expect(blob.length, fixedTestContent.length);
        expect(blob.digest, isNull);
        expect(blob.properties, {
          'content_type': contentType,
          'length': fixedTestContent.length,
          'digest': null,
        });
      });
    });

    group('from properties', () {
      test('initial properties', () {
        final blob = BlobImpl.fromProperties({
          '@type': 'blob',
          'digest': 'digest',
          'length': 0,
          'content_type': contentType,
        });

        expect(blob.digest, 'digest');
        expect(blob.length, 0);
        expect(blob.contentType, contentType);
      });

      test('throws when reading content before saving', () {
        final blob = BlobImpl.fromProperties({
          '@type': 'blob',
          'digest': 'digest',
          'length': 0,
          'content_type': contentType,
        });
        expect(
          blob.content,
          throwsA(isStateError.having(
            (it) => it.message,
            'message',
            contains('Blob has no data available.'),
          )),
        );
        expect(
          blob.contentStream,
          throwsA(isStateError.having(
            (it) => it.message,
            'message',
            contains('Blob has no data available.'),
          )),
        );
      });
    });

    apiTest('throws error when saving blob from different database', () async {
      final db = await openTestDatabase();
      final otherDb = await openTestDatabase(name: 'other');
      final blob = Blob.fromData(contentType, randomTestContent());
      final doc = MutableDocument({'blob': blob});
      await otherDb.saveDocument(doc);

      final docB = MutableDocument({'blob': blob});
      expect(() => db.saveDocument(docB), throwsStateError);
    });

    apiTest(
      'read',
      () async {
        final db = await openTestDatabase();

        final content =
            randomTestContent(large: blobSize.value == BlobSize.large);

        Blob? _writeBlob;
        final doc = MutableDocument();

        switch (writeBlob.value) {
          case WriteBlob.data:
            _writeBlob = Blob.fromData(contentType, content);
            break;
          case WriteBlob.properties:
            final blob = Blob.fromData(contentType, content);
            await db.saveDocument(MutableDocument({'blob': blob}));
            doc['blob'].value = <String, Object?>{
              '@type': 'blob',
              'digest': blob.digest,
              'length': blob.length,
              'content_type': blob.contentType,
            };
            break;
          case WriteBlob.stream:
            _writeBlob = await Blob.fromStream(
              contentType,
              Stream.value(content),
              db,
            );
            break;
        }

        if (_writeBlob != null) {
          doc['blob'].value = _writeBlob;
        }

        Future<void> read() async {
          Blob _readBlob;
          switch (readBlob.value) {
            case ReadBlob.sourceBlob:
              _readBlob = _writeBlob!;
              break;
            case ReadBlob.loadedBlob:
              final loadedDoc = (await db.document(doc.id))!;
              _readBlob = loadedDoc.blob('blob')!;
              break;
          }

          switch (readMode.value) {
            case ReadMode.future:
              expect(await _readBlob.content(), content);
              break;
            case ReadMode.stream:
              expect(
                await byteStreamToFuture(_readBlob.contentStream()),
                content,
              );
              break;
          }
        }

        switch (readTime.value) {
          case ReadTime.beforeSave:
            await read();
            break;
          case ReadTime.afterSave:
            await db.saveDocument(doc);
            await read();
            break;
        }
      },
      variants: [writeBlob, readTime, readMode, readBlob, blobSize],
    );

    apiTest('remove from document', () async {
      final db = await openTestDatabase();
      final blob = Blob.fromData(contentType, fixedTestContent);
      final doc = MutableDocument({'blob': blob});
      await db.saveDocument(doc);
      doc.removeValue('blob');
      await db.saveDocument(doc);
      final loadedDoc = (await db.document(doc.id))!;
      expect(loadedDoc.value('blob'), isNull);
    });

    test('==', () {
      Blob a;
      Blob b;

      // Identical blobs are equal.
      a = Blob.fromData(contentType, fixedTestContent);
      expect(a, a);

      // Blobs from data with equal content are equal.
      a = Blob.fromData(contentType, fixedTestContent);
      b = Blob.fromData(contentType, fixedTestContent);
      expect(a, b);

      // Blobs from data with equal content but different content type are
      // equal.
      a = Blob.fromData('A', fixedTestContent);
      b = Blob.fromData('B', fixedTestContent);
      expect(a, b);
    });

    test('hashCode', () {
      Blob blob;

      // Uses hashCode of digest if available.
      blob = BlobImpl.fromProperties({
        '@type': 'blob',
        'digest': 'A',
        'length': 0,
      });

      expect(blob.hashCode, blob.digest.hashCode);

      // Uses hashCode of object as fallback.
      blob = BlobImpl.fromProperties({
        '@type': 'blob',
        'digest': '',
        'length': 0,
      });
      expect(blob.hashCode, isNot(null.hashCode));
    });

    test('toString', () {
      expect(
        Blob.fromData(contentType, Uint8List(1024)).toString(),
        'Blob($contentType; 1.5 KB)',
      );

      expect(
        Blob.fromData(contentType, Uint8List(0)).toString(),
        'Blob($contentType; 0.5 KB)',
      );

      // Blob without content type.
      expect(
        BlobImpl.fromProperties({
          '@type': 'blob',
          'length': 0,
          'digest': '',
        }).toString(),
        'Blob(0.5 KB)',
      );
    });
  });
}

const contentType = 'application/octet-stream';
final fixedTestContent = utf8.encode('content') as Uint8List;
const fixedTestContentDigest = 'sha1-BA8G/XdAkkeNRQd09bowxdp4rMg=';

/// Returns random bytes for blob.
///
/// When [large] is true the content is to large to be cached and results in
/// multiple chunks when streamed.
Uint8List randomTestContent({bool large = false}) =>
    randomBytes(large ? 8 * 1024 * 2 : 16);

final random = Random(0);

Uint8List randomBytes(int size) {
  final data = Uint32List(size ~/ 4);
  for (var i = 0; i < data.length; i++) {
    data[i] = random.nextInt(1 << 32);
  }
  return data.buffer.asUint8List(0, size);
}

enum WriteBlob { data, properties, stream }
enum ReadTime { beforeSave, afterSave }
enum ReadMode { future, stream }
enum ReadBlob { sourceBlob, loadedBlob }
enum BlobSize { small, large }

final writeBlob = EnumVariant<WriteBlob>(
  WriteBlob.values,
  isCompatible: (value, other, otherValue) {
    if (value == WriteBlob.properties) {
      if (other == readBlob) {
        return otherValue == ReadBlob.loadedBlob;
      }
    }

    return true;
  },
  order: 100,
);
final readTime = EnumVariant(ReadTime.values, order: 90);
final readMode = EnumVariant(ReadMode.values, order: 80);
final readBlob = EnumVariant<ReadBlob>(
  ReadBlob.values,
  isCompatible: (value, other, otherValue) {
    if (value == ReadBlob.loadedBlob && other == readTime) {
      return otherValue == ReadTime.afterSave;
    }
    return true;
  },
  order: 70,
);
final blobSize = EnumVariant(BlobSize.values, order: 60);
