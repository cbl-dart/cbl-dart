import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/document/blob.dart';
import 'package:cbl/src/support/streams.dart';
import 'package:cbl/src/support/utils.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/database_utils.dart';

final contentType = 'application/octet-stream';
final fixedTestContent = utf8.encode('content') as Uint8List;
final fixedTestContentDigest = 'sha1-BA8G/XdAkkeNRQd09bowxdp4rMg=';

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

enum WriteBlob { data, properties }
enum ReadTime { beforeSave, afterSave }
enum ReadMode { future, stream }
enum ReadBlob { sourceBlob, loadedBlob }
enum BlobSize { small, large }

void main() {
  setupTestBinding();

  group('Blob', () {
    late Database db;

    setUpAll(() {
      db = openTestDb('Blob-Common');
    });

    group('from data', () {
      test('is initialized with all properties', () {
        final blob = Blob.fromData(contentType, fixedTestContent);
        expect(blob.contentType, contentType);
        expect(blob.length, fixedTestContent.length);
        expect(blob.digest, fixedTestContentDigest);
        expect(blob.properties, {
          'content_type': contentType,
          'length': fixedTestContent.length,
          'digest': fixedTestContentDigest,
        });
      });
    });

    group('from properties', () {
      test('is initialized with all properties', () {
        final blob = BlobImpl.fromProperties(<String, dynamic>{
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
        final blob = BlobImpl.fromProperties(<String, dynamic>{
          '@type': 'blob',
          'digest': 'digest',
          'length': 0,
          'content_type': contentType,
        });
        expect(
          blob.content(),
          throwsA(isStateError.having(
            (it) => it.message,
            'message',
            contains('Blob has no data available.'),
          )),
        );
        expect(
          blob.contentStream().first,
          throwsA(isStateError.having(
            (it) => it.message,
            'message',
            contains('Blob has no data available.'),
          )),
        );
      });
    });

    test('throws error when saving blob from different database', () {
      final otherDb = openTestDb('Blobs-OtherDB');
      final blob = Blob.fromData(contentType, randomTestContent());
      final doc = MutableDocument({'blob': blob});
      otherDb.saveDocument(doc);

      final docB = MutableDocument({'blob': blob});
      expect(() => db.saveDocument(docB), throwsStateError);
    });

    group('read', () {
      void blobReadTest(
        WriteBlob writeBlob,
        ReadTime readTime,
        ReadMode readMode,
        ReadBlob readBlob,
        BlobSize size,
      ) {
        test(
          'created from ${describeEnum(writeBlob)} '
          'read ${describeEnum(readMode)} '
          'from ${describeEnum(readBlob)} '
          '${describeEnum(readTime)} '
          '(${describeEnum(size)})',
          () async {
            final content = randomTestContent(large: size == BlobSize.large);

            Blob? _writeBlob;
            final doc = MutableDocument();

            switch (writeBlob) {
              case WriteBlob.data:
                _writeBlob = Blob.fromData(contentType, content);
                break;
              case WriteBlob.properties:
                final blob = Blob.fromData(contentType, content);
                db.saveDocument(MutableDocument({'blob': blob}));
                doc['blob'].value = <String, Object?>{
                  '@type': 'blob',
                  'digest': blob.digest,
                  'length': blob.length,
                  'content_type': blob.contentType,
                };
                break;
            }

            if (_writeBlob != null) {
              doc['blob'].value = _writeBlob;
            }

            Future<void> read() async {
              Blob _readBlob;
              switch (readBlob) {
                case ReadBlob.sourceBlob:
                  _readBlob = _writeBlob!;
                  break;
                case ReadBlob.loadedBlob:
                  final loadedDoc = (db.getDocument(doc.id))!;
                  _readBlob = loadedDoc.blob('blob')!;
                  break;
              }

              switch (readMode) {
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

            switch (readTime) {
              case ReadTime.beforeSave:
                await read();
                break;
              case ReadTime.afterSave:
                db.saveDocument(doc);
                await read();
                break;
            }
          },
        );
      }

      for (final writeBlob in WriteBlob.values) {
        for (final readTime in ReadTime.values) {
          for (final readMode in ReadMode.values) {
            for (final readBlob in ReadBlob.values) {
              for (final size in BlobSize.values) {
                // Condition for [ReadBlob.loadedBlob].
                if (readBlob != ReadBlob.loadedBlob ||
                    readTime == ReadTime.afterSave) {
                  // Conditions for [WriteBlob.properties].
                  if (writeBlob != WriteBlob.properties ||
                      (readTime == ReadTime.afterSave &&
                          readBlob == ReadBlob.loadedBlob)) {
                    blobReadTest(writeBlob, readTime, readMode, readBlob, size);
                  }
                }
              }
            }
          }
        }
      }
    });

    test('remove from document', () {
      final blob = Blob.fromData(contentType, fixedTestContent);
      final doc = MutableDocument({'blob': blob});
      db.saveDocument(doc);
      doc.removeValue('blob');
      db.saveDocument(doc);
      final loadedDoc = (db.getDocument(doc.id))!;
      expect(loadedDoc.value('blob'), isNull);
    });

    test('==', () async {
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

    test('hashCode', () async {
      Blob blob;

      // Uses hashCode of digest if available.
      blob = Blob.fromData(contentType, fixedTestContent);
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
        BlobImpl.fromProperties(<String, dynamic>{
          '@type': 'blob',
          'length': 0,
          'digest': '',
        }).toString(),
        'Blob(0.5 KB)',
      );
    });
  });
}
