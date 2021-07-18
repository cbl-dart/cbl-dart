import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/document/blob.dart';
import 'package:cbl/src/streams.dart';
import 'package:cbl/src/utils.dart';
import 'package:collection/collection.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/database_utils.dart';

final contentType = 'application/octet-stream';
final fixedTestContent = utf8.encode('content') as Uint8List;
final fixedTestContentDigest = 'sha1-BA8G/XdAkkeNRQd09bowxdp4rMg=';
Stream<Uint8List> fixedTestContentStream() => Stream.value(fixedTestContent);

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

enum WriteBlob { data, stream, file }

enum ReadTime { beforeSave, afterSave }

enum ReadMode { future, stream }

enum ReadBlob { sourceBlob, loadedBlob }

enum BlobSize { small, large }

void main() {
  setupTestBinding();

  group('Blob', () {
    late Database db;

    setUpAll(() async {
      db = await openTestDb('Blob-Common');
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

    group('from stream', () {
      test('is initialized with contentType', () {
        final blob = Blob.fromStream(contentType, fixedTestContentStream());
        expect(blob.contentType, contentType);
        expect(blob.length, isNull);
        expect(blob.digest, isNull);
        expect(blob.properties, {
          'content_type': contentType,
          'length': null,
          'digest': null,
        });
      });
    });

    group('from file', () {
      test('throws exception when file does not exist', () {
        expect(
          () =>
              Blob.fromFileUrl(contentType, Uri.parse('$tmpDir/does_no_exist')),
          throwsArgumentError,
        );
      });

      test('has the content of file as content', () async {
        final content = randomTestContent();
        final file = File('$tmpDir/blob_content');
        file.writeAsBytesSync(content);
        final blob = Blob.fromFileUrl(contentType, file.uri);
        expect(await blob.content(), content);
      });
    });

    // Blob from properties
    // is initialized with all properties
    // throws when reading content before saving
    // read content after saving
    // throws when reading content stream before saving
    // read content stream after saving
    // throws error when blob cannot be found

    test('throws error when saving blob with failed stream again', () async {
      final blob = Blob.fromStream(contentType, Stream.error('Whoops'));
      final doc = MutableDocument({'blob': blob});
      await expectLater(db.saveDocument(doc), throwsA('Whoops'));
      await expectLater(
        db.saveDocument(doc),
        throwsA(
          isA<StateError>().having(
            (it) => it.message,
            'message',
            contains(
              'A document contains a blob which previously was unable to read '
              'the stream it was created from.',
            ),
          ),
        ),
      );
    });

    test('throws error when saving blob from different database', () async {
      final otherDb = await openTestDb('Blobs-OtherDB');
      final blob = Blob.fromData(contentType, randomTestContent());
      final doc = MutableDocument({'blob': blob});
      await otherDb.saveDocument(doc);

      final docB = MutableDocument({'blob': blob});
      expect(db.saveDocument(docB), throwsStateError);
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

            Blob _writeBlob;
            switch (writeBlob) {
              case WriteBlob.data:
                _writeBlob = Blob.fromData(contentType, content);
                break;
              case WriteBlob.stream:
                _writeBlob =
                    Blob.fromStream(contentType, Stream.value(content));
                break;
              case WriteBlob.file:
                final file = File('$tmpDir/blob');
                await file.writeAsBytes(content);
                _writeBlob = Blob.fromFileUrl(contentType, file.uri);
                break;
            }

            final doc = MutableDocument({'blob': _writeBlob});

            Future<void> read() async {
              Blob _readBlob;
              switch (readBlob) {
                case ReadBlob.sourceBlob:
                  _readBlob = _writeBlob;
                  break;
                case ReadBlob.loadedBlob:
                  final loadedDoc = (await db.getDocument(doc.id))!;
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
                await db.saveDocument(doc);
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
                if (!(readTime == ReadTime.beforeSave &&
                    readBlob == ReadBlob.loadedBlob)) {
                  blobReadTest(writeBlob, readTime, readMode, readBlob, size);
                }
              }
            }
          }
        }
      }
    });

    test('remove from document', () async {
      final blob = Blob.fromData(contentType, fixedTestContent);
      final doc = MutableDocument({'blob': blob});
      await db.saveDocument(doc);
      doc.removeValue('blob');
      await db.saveDocument(doc);
      final loadedDoc = (await db.getDocument(doc.id))!;
      expect(loadedDoc.value('blob'), isNull);
    });

    test('==', () async {
      Blob a;
      Blob b;

      // Identical blobs are equal.
      a = Blob.fromData(contentType, fixedTestContent);
      expect(a, a);

      // Blobs with equal digest are equal.
      a = Blob.fromData(contentType, fixedTestContent);
      b = Blob.fromData(contentType, fixedTestContent);
      expect(a.digest, isNotNull);
      expect(a.digest, b.digest);
      expect(a, b);

      // Blobs with equal content are equal.
      a = Blob.fromStream(contentType, fixedTestContentStream());
      b = Blob.fromStream(contentType, fixedTestContentStream());

      // -> Blobs without digest and synchronously available content are not
      //    equal.
      expect(a, isNot(b));

      // -> Ensure that content is synchronously available.
      await a.content();
      await b.content();
      expect(a, b);
    });

    test('hashCode', () async {
      Blob blob;

      // Uses hashCode of digest if available.
      blob = Blob.fromData(contentType, fixedTestContent);
      expect(blob.hashCode, blob.digest.hashCode);

      // Uses hashCode of content if available.
      blob = Blob.fromStream(contentType, fixedTestContentStream());
      final content = await blob.content();
      expect(blob.hashCode, const DeepCollectionEquality().hash(content));

      // Uses hashCode of object as fallback.
      blob = Blob.fromStream(contentType, fixedTestContentStream());
      expect(blob.hashCode, isNot(null.hashCode));
    });

    test('toString provides debug representation', () {
      expect(
        Blob.fromData(contentType, Uint8List(1024)).toString(),
        'Blob($contentType; 1.5 KB)',
      );

      expect(
        Blob.fromData(contentType, Uint8List(0)).toString(),
        'Blob($contentType; 0.5 KB)',
      );

      // Blob whose length has not been determined yet.
      expect(
        Blob.fromStream(contentType, Stream.empty()).toString(),
        'Blob($contentType; ? KB)',
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
